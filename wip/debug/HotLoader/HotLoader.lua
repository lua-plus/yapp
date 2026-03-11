local mtime           = require("src.fs.stat.mtime")
local class           = require("lib.30log")
local soft_get_source = require("wip.debug.HotLoader.soft_get_source")
local shim            = require("wip.debug.HotLoader.shim")
local debug_repo      = require("wip.debug.HotLoader.debug_repo")

local traceback       = require("src.debug.traceback")

-- TODO FIXME should this be a loader utility?

-- TODO consolidate file.

-- TODO Heuristic: the most recently modified file is 'most likely' to change again

--- TODO metadata should contain module so it can be manipulated by handlers if need be.
---@class Yapp.Debug.HotLoader.Metadata
---
---@field path string
---@field name string
---
---@field mtime integer
---
---@field dependencies table<string, true> A list of paths
---@field dependents table<string, true> A list of paths


---@alias Yapp.Debug.HotLoader.Filter
---| fun(modname: string, path: string, module: any): boolean


---@alias Yapp.Debug.HotLoader.Handler
---| fun(modname: string, all_names: string[])


---@class Yapp.Debug.HotLoader : Log.BaseFunctions
---@field protected _vanilla_require function
---
---@field protected _recent Yapp.Debug.HotLoader.Metadata[]
---
---@field protected _paths table<string, Yapp.Debug.HotLoader.Metadata> weak path-to-metadata
---@field protected _names table<string, Yapp.Debug.HotLoader.Metadata> weak name-to-metadata
---@field protected _metadata table<Yapp.Debug.HotLoader.Metadata, true> strong metadata-to-true
---
---@field protected _filters table<function, true>
---
---@field protected _change_handlers table<function, true>
---
---@overload fun(require: function?): Yapp.Debug.HotLoader
local HotLoader = class("Yapp.Debug.HotLoader")

---@param require function?
function HotLoader:init(require)
    local require = require or (_ENV or _G).require
    self._vanilla_require = require

    -- set up metadata
    self._names = setmetatable({}, { __mode = "v" })
    self._paths = setmetatable({}, { __mode = "v" })
    self._metadata = {}


    self._filters = {}

    self._change_handlers = {}

    self._recent = {}

    -- TODO warning for getinfo
end

---@param cb Yapp.Debug.HotLoader.Handler
function HotLoader:add_handler(cb)
    self._change_handlers[cb] = true

    return self
end

---@param cb Yapp.Debug.HotLoader.Handler
function HotLoader:remove_handler(cb)
    self._change_handlers[cb] = nil

    return self
end

---@param cb Yapp.Debug.HotLoader.Filter
function HotLoader:add_filter(cb)
    self._filters[cb] = true

    return self
end

---@param cb Yapp.Debug.HotLoader.Filter
function HotLoader:remove_filter(cb)
    self._filters[cb] = nil

    return self
end

---@protected 
---@param metadata Yapp.Debug.HotLoader.Metadata
function HotLoader:_recent_add (metadata)
    table.insert(self._recent, 1, metadata)
end

---@protected
function HotLoader:_recent_trim ()
    local max_count = 5 

    if #self._recent > max_count then
        table.remove(self._recent, max_count + 1)
    end
end

---@protected
---@param name string
---@param queue string[]
---@return boolean ok
function HotLoader:_reload (name, queue)
    local metadata = self:_get_metadata_by_name(name)
    if not metadata then
        return false
    end

    local existing = package.loaded[name]
    package.loaded[name] = nil

    local ok, mod = xpcall(self._vanilla_require, traceback, name)
    if not ok then
        package.loaded[name] = existing

        local err = mod

        -- TODO allow modifying this behavior
        print(err)

        return false
    end

    if shim.reshim(existing, mod) then
        package.loaded[name] = existing

        return true
    end

    -- overwrite package.loaded w/ a new shim if possible
    package.loaded[name] = shim.create(mod)

    for dependent in pairs(metadata.dependents) do
        local dep_metadata = self:_get_metadata_by_path(dependent)

        if dep_metadata then
            local dep_name = dep_metadata.name

            -- TODO FIXME make sure queue entries are unique
            table.insert(queue, dep_name)
        end
    end

    return true
end

---@protected
---@param metadata Yapp.Debug.HotLoader.Metadata
---@return boolean had_event
function HotLoader:_poll_one (metadata)
    local path = metadata.path
    local name = metadata.name

    local handle = io.open(path, "r")
    -- asserts path exists
    if not handle then
        -- TODO allow modifying this behavior
        print("file", path, "removed")

        self:_unregister_metadata(metadata)

        return true
    end

    -- we check mtime here because a newly created file will be empty but its
    -- mtime won't change
    local f_mtime = mtime(path)
    if f_mtime <= metadata.mtime then
        return false
    end

    -- sometimes, mid-save handles will have empty content
    local content = handle:read(1)
    handle:close()
    if not content or #content == 0 then
        return false
    end

    -- TODO allow modifying this behavior
    print(path, "changed")

    metadata.mtime = mtime(path)

    local queue = { name }
    local all_names = {}
    while next(queue) do
        local name = table.remove(queue, 1)

        -- TODO allow modifying this behavior
        print("Reloading", name)

        local ok = self:_reload(name, queue)

        if ok then
            table.insert(all_names, name)
        end
    end

    -- TODO maybe if any failure occurs we ignore the reload.
    if #all_names ~= 0 then
        for cb in pairs(self._change_handlers) do
            cb(name, all_names)
        end
    end

    return true
end

---@protected
function HotLoader:_poll_self ()
    -- TODO custom iterator - check N files or all
    -- recents is useless if we're checking all files
    --[[
    self:_recent_trim()
    for _, metadata in ipairs(self._recent) do
        if self:_poll_one(metadata) then
            -- TODO perform an in-place swap
            self:_recent_add(metadata)

            return
        end
    end

    for metadata in pairs(self._metadata) do
        if self:_poll_one(metadata) then
            self:_recent_add(metadata)
            
            return
        end
    end
    ]]

    for metadata in pairs(self._metadata) do
        if self:_poll_one(metadata) then            
            return
        end
    end
end

--- Poll all HotLoaders or the given HotLoader
---@param self Yapp.Debug.HotLoader?
function HotLoader.poll(self)
    if self then
        self:_poll_self()
    else
        for _, hot in ipairs(HotLoader:instances()) do
            ---@diagnostic disable-next-line:undefined-field
            hot:_poll_self()
        end
    end
end

function HotLoader:get_require_shim()
    return function(...)
        return self:_require(...)
    end
end

--- Unregister an existing metadata value
---@protected
---@param metadata Yapp.Debug.HotLoader.Metadata
function HotLoader:_unregister_metadata(metadata)
    local name = metadata.name
    local path = metadata.path

    self._metadata[metadata] = nil
    self._names[name] = nil
    self._paths[path] = nil

    for i, md in ipairs(self._recent) do
        if md == metadata then
            table.remove(self._recent, i)

            break
        end
    end
end

--- Check if we should register a module for hot-reloading
---@protected
---@param name string
---@param path string | nil
---@param mod any
---@return boolean ok
function HotLoader:_check_should_register(name, path, mod)
    if not path then
        return false
    end

    for filter in pairs(self._filters) do
        if not filter(name, path, mod) then
            return false
        end
    end

    return true
end

--- Check if a given module's metadata should be registered, and then do so.
---@protected
---@param name string
---@param path string
---@param mod any
---@return Yapp.Debug.HotLoader.Metadata | nil metadata
function HotLoader:_register_metadata(name, path, mod)
    ---@type Yapp.Debug.HotLoader.Metadata
    local metadata = {
        module = mod,

        path = path,
        name = name,

        mtime = mtime(path),

        dependencies = {},
        dependents = {},
    }

    self._metadata[metadata] = true
    self._names[name] = metadata
    self._paths[path] = metadata

    return metadata
end

---@protected
---@param name string
---@return any mod
---@return string? path
function HotLoader:_require(name)
    ---@type Yapp.Debug.HotLoader.Metadata | nil
    local metadata = nil
    ---@type any
    local out_mod = nil
    ---@type string | nil
    local out_path = nil

    if package.loaded[name] then
        out_mod = package.loaded[name]

        metadata = self:_get_metadata_by_name(name)
    else
        local mod, path = self._vanilla_require(name)
        out_mod = mod
        out_path = path

        if self:_check_should_register(name, path, mod) then
            metadata = self:_register_metadata(name, path, mod)

            out_mod = shim.create(out_mod)
            package.loaded[name] = out_mod
        end
    end

    if metadata then
        local source = soft_get_source(2)
        if source then
            -- add source as dependency
            metadata.dependents[source] = true

            local call_metadata = self:_get_metadata_by_path(source)
            if call_metadata then
                call_metadata.dependents[metadata.path] = true
            end
        end
    end

    return out_mod, out_path
end

---@protected
---@param path string
---@return Yapp.Debug.HotLoader.Metadata?
function HotLoader:_get_metadata_by_path(path)
    return self._paths[path]
end

---@protected
---@param name string
---@return Yapp.Debug.HotLoader.Metadata?
function HotLoader:_get_metadata_by_name(name)
    return self._names[name]
end

--- Set debug.getinfo for all HotLoader instances
---@param getinfo function
function HotLoader.static_set_debug_getinfo(getinfo)
    debug_repo.getinfo = getinfo
end

--- Set debug.setupvalue for all HotLoader instances
---@param setupvalue function
function HotLoader.static_set_debug_setupvalue(setupvalue)
    debug_repo.setupvalue = setupvalue
end

--- Using LGI, create a GLib MainLoop and run it
---@overload fun(timeout: integer)
---@param self Yapp.Debug.HotLoader?
---@param timeout integer?
function HotLoader:glib_poll_loop(self, timeout)
    if type(self) == "number" then
        timeout = self
        self = nil
    end

    timeout = timeout or 250

    local lgi = require("lgi")
    local GLib = lgi.require("GLib", "2.0")
    local MainLoop = GLib.MainLoop
    local MainContext = GLib.MainContext

    local context = MainContext.default()
    local loop = MainLoop()

    local source = GLib.timeout_source_new(timeout)
    source:set_callback(function()
        local ok, err = xpcall(HotLoader.poll, traceback, self)

        if not ok then error(err) end

        return true
    end)
    source:attach(context)

    loop:run()

    source:destroy()
end

-- TODO HotLoader:inject

return HotLoader