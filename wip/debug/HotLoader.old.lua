local mtime = require("src.fs.stat.mtime")
local class = require("lib.30log")

local traceback = require("src.debug.traceback")
local debug_getinfo = (debug or {}).getinfo
local debug_setupvalue = (debug or {}).setupvalue

-- TODO FIXME rewrite again

-- Heuristic: the most recently modified file is 'most likely' to change again

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
---@param name string
---@param queue string[]
---@return boolean ok
function HotLoader:_reload(name, queue)
    local ok, mod, _, dependents = pcall(self._load, self, name)

    if not ok then
        local err = mod

        -- TODO colorize or something
        print(err)
        return false
    end

    for dependent in pairs(dependents) do
        local dep_metadata = self:_get_metadata_by_path(dependent)

        if dep_metadata then
            local name = dep_metadata.name

            -- TODO FIXME make sure queue entries are unique
            table.insert(queue, name)
        end
    end

    return true
end

---@protected
---@param all boolean?
function HotLoader:_poll_paths(all)
    if all then
        return pairs(self._paths)
    end

    -- TODO return iterator for single path
end

--- Poll this HotLoader's files for changes
---@protected
function HotLoader:_poll_self()
    local key = self._poll_key
    -- the path at key might have died
    if key and not self._paths[key] then
        key = nil
    end
    key = next(self._paths, key)
    self._poll_key = key

    local path = key
    if not path then
        return
    end

    local metadata = self:_get_metadata_by_path(path)

    local handle = io.open(path, "r")
    if not handle then
        -- can't open file.

        print("file", path, "removed")

        self._metadata[metadata] = nil
        self._paths[path] = nil
        self._names[metadata.name] = nil

        return
    end

    local f_mtime = mtime(path)
    if f_mtime <= metadata.mtime then
        return
    end

    local content = handle:read(1)
    -- Just throw away this result if the file hasn't been written to yet.
    if not content or #content == 0 then
        return
    end

    -- TODO FIXME this is bad and ugly
    print(path, "changed")

    -- update metadata mtime
    metadata.mtime = mtime(metadata.path)

    local name = metadata.name

    local queue = { name }
    local all_names = {}

    -- iterate all items in the queue
    while next(queue) do
        local name = table.remove(queue, 1)

        print("Reloading " .. name)

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

--- Get the Lua source path for a given call level
---@param level integer
---@return string|nil
local function get_source(level)
    if not debug_getinfo then
        return nil
    end

    local info = debug_getinfo(level + 1, "S")

    local source = info.source
    if source == "=[C]" then
        return nil
    end

    return source:sub(2)
end

---@protected
---@param path string
---@return Yapp.Debug.HotLoader.Metadata
function HotLoader:_get_metadata_by_path(path)
    return self._paths[path]
end

---@protected
---@param name string
---@return Yapp.Debug.HotLoader.Metadata
function HotLoader:_get_metadata_by_name(name)
    return self._names[name]
end

---@protected
---@type metatable
HotLoader._func_shim_mt = {
    __call = function(t, ...)
        return t[1](...)
    end,
    __tostring = function(t)
        return tostring(t[1])
    end
}

--- If the conditions are right, shim the existing value and return true
---@protected
---@param existing any
---@param new any
---@return boolean ok
function HotLoader._try_reshim(existing, new)
    local t_existing = type(existing)
    local t_new = type(new)

    if t_existing == "function" then
        if t_new ~= "function" then
            return false
        end

        debug_setupvalue(existing, 1, new)

        return true
    end

    if t_existing ~= "table" then
        return false
    end

    if t_new == "function" then
        -- we want a function shim, but we have some other table
        if getmetatable(existing) ~= HotLoader._func_shim_mt then
            -- vacuum entries
            for k in pairs(existing) do
                existing[k] = nil
            end

            setmetatable(existing, HotLoader._func_shim_mt)
        end

        existing[1] = new

        return true
    elseif t_new == "table" then
        local mt = getmetatable(new)
        setmetatable(new, nil)

        setmetatable(existing, nil)

        -- vacuum entries
        for k in pairs(existing) do
            existing[k] = new[k]
            new[k] = nil
        end
        -- and insert new ones
        for k, v in pairs(new) do
            existing[k] = v
        end

        setmetatable(existing, mt)

        return true
    end

    return false
end

---@protected
---@param name string
---@return any mod
---@return string? path
---@return table<string, true> to_reload
function HotLoader:_load(name)
    -- TODO FIXME how do i handle builtins?
    -- TODO FIXME optional filter functions - skip eg. lgi, root packages

    local existing = package.loaded[name]
    -- drop the package from package.loaded so it can be force-reloaded.
    package.loaded[name] = nil

    local ok, mod, path = xpcall(self._vanilla_require, traceback, name)

    -- loading failed.
    if not ok then
        -- restore existing to package.loaded
        package.loaded[name] = existing

        if not self._names[name] and existing then
            return existing, nil, {}
        end

        local err = mod
        error(string.format(
            "Failed to load module %q: %s",
            name, err
        ))
    end

    -- we can't do hot reloading on C modules for instance
    if not path then
        -- restore package.loaded
        package.loaded[name] = existing

        return mod, nil, {}
    end

    for filter in pairs(self._filters) do
        if not filter(name, path, mod) then
            package.loaded[name] = mod

            return mod, path, {}
        end
    end

    local metadata = self:_get_metadata_by_name(name)
    if metadata then
        -- this is an existing module, try to shim it

        local shim_ok = self._try_reshim(metadata.module, mod)

        if shim_ok then
            return metadata.module, nil, {}
        else
            metadata.module = mod

            return mod, nil, metadata.dependents
        end
    else
        -- this is a fresh module, register its metadata

        if type(mod) == "function" then
            -- create a new function shim...
            if debug_setupvalue then
                -- ...that is a closure
                local inner = mod

                mod = function(...)
                    return inner(...)
                end
            else
                -- ...that is a callable table
                mod = setmetatable({ mod }, HotLoader._func_shim_mt)
            end
        end

        metadata = {
            module = mod,

            path = path,
            name = name,

            mtime = mtime(path),

            dependents = {},
            dependencies = {},
        }

        self._metadata[metadata] = true
        self._names[name] = metadata
        self._paths[path] = metadata
    end

    return mod, path, {}
end

---@protected
---@param name string
function HotLoader:_resolve_module(name)
    local loaded = self:_get_metadata_by_name(name)
    if loaded then
        return loaded.module
    end

    local mod, path = self:_load(name)
    return mod, path
end

---@protected
---@param name string
function HotLoader:_require(name)
    local mod, path = self:_resolve_module(name)

    local source = get_source(2)
    local mod_metadata = self:_get_metadata_by_name(name)

    if not mod_metadata then
        -- This isn't a hot module
        return mod, path
    end

    if source then
        local mod_path = mod_metadata.path

        -- Add the caller as a module dependent
        mod_metadata.dependents[source] = true

        local call_metadata = self:_get_metadata_by_path(source)
        if call_metadata then
            -- Add the module as a caller dependency
            call_metadata.dependencies[mod_path] = true
        end
    end

    -- On first load, warn about primitive modules
    local t_mod = type(mod)
    if t_mod ~= "table" and t_mod ~= "function" and path then
        print(
            string.format("Module %q (%s) cannot be hot-reloaded directly. ", name, path) ..
            (debug_getinfo and
                "Dependent modules will be reloaded instead." or
                "Restart the server when this file changes"
            )
        )
    end

    return mod, path
end

function HotLoader:get_require_shim()
    return function(...)
        return self:_require(...)
    end
end

-- TODO FIXME setfenv of caller to replace require and use luaplus.loader to propagate that env
--[[
function HotLoader:inject ()

end
]]

--- Using LGI, create a GLib MainLoop and run it
---@overload fun(timeout: integer)
---@param self Yapp.Debug.HotLoader?
---@param timeout integer?
function HotLoader:glib_poll_loop(self, timeout)
    if type(self) == "number" then
        timeout = self
        self = nil
    end

    timeout = timeout or 50

    local lgi = require("lgi")
    local GLib = lgi.require("GLib", "2.0")
    local MainLoop = GLib.MainLoop
    local MainContext = GLib.MainContext

    -- TODO FIXME wtf?
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

--- Set debug.getinfo for all HotLoader instances
---@param getinfo function
function HotLoader.static_set_debug_getinfo(getinfo)
    debug_getinfo = getinfo
end

--- Set debug.setupvalue for all HotLoader instances
---@param setupvalue function
function HotLoader.static_set_debug_setupvalue(setupvalue)
    debug_setupvalue = setupvalue
end

return HotLoader
