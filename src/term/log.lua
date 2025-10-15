local chalk = require("src.term.chalk")

local map = require("src.table.map")

--[[
Logging API:
    log:tag(tag: any) -> sub-logger w/ that tag

    log:format(fmt) -> custom format sub-logger
        fmt: table<string, formatter>

    (log or sublog).level -> set level for that logger. defaults to master level

    TODO deferred task: log outfile (no chalk)

Formats
    if a format name exists, it is usable as log:<format>(message)
    a formatter can be:
        a function (self, ...) -> string? I guess?
        TODO format strings
]]

---@class Yapp.Term.Log
---
---@field protected _tag string | nil
---@field protected _levels table<string, integer>
---@field protected _formatters table<string, function>
---
---@field level string
---
-- ---@field format fun (self: self, formatters: { string: (fun(self: self, ...: string): string) }): Yapp.Term.Log
---@field tag fun(self: self, tag: any): Yapp.Term.Log
---
---@field trace fun(self: self, ...: string)
---@field debug fun(self: self, ...: string)
---@field info fun(self: self, ...: string)
---@field warn fun(self: self, ...: string)
---@field error fun(self: self, ...: string)
---@field fatal fun(self: self, ...: string)
local log = {}

log._by_tag = {}

---@protected
---@return Yapp.Term.Log
function log:_clone()
    return setmetatable({
        _tag = self._tag,

        _levels = self._levels,
        _formatters = self._formatters,
    }, { __index = self })
end

---@param ... string
---@return Yapp.Term.Log
function log:tag(...)
    -- TODO store tags in a smarter way. strings are bad!
    
    local tag = table.concat({...}, ":")

    if self._tag then
        tag = self._tag .. ":" .. tag
    end

    local cached = log._by_tag[tag]
    if cached then
        return cached
    end

    local sub_log = self:_clone()
    sub_log._tag = tag

    log._by_tag[tag] = sub_log

    return sub_log
end

function log:get_tag()
    return self._tag
end

---@param offset integer?
---@return string
function log:get_source(offset)
    offset = offset or 0

    local info = debug.getinfo(3 + offset, "Sl")

    local source = info.source
    if source == "=[C]" then
        return "[C]"
    end

    source = source .. ":" .. tostring(info.currentline)

    if source:sub(1, 1) == "@" then
        return source:sub(2)
    end

    return source
end

---@param offset integer?
---@return string?
function log:try_get_source(offset)
    offset = offset or 0
    offset = offset + 1

    if not debug.getinfo then
        return nil
    end

    return self:get_source(offset)
end

function log:get_date()
    return os.date("%X", os.time())
end

---@protected
---@param levels [string, fun(logger: Yapp.Term.Log, ...: string): string][]
function log:_set_format(levels)
    -- remove existing loggers
    for name in pairs(self._levels or {}) do
        self[name] = nil
    end

    self._levels = {}
    self._formatters = {}

    for i, info in pairs(levels) do
        local level = info[1]
        local formatter = info[2]

        self._levels[level] = i
        self._formatters[level] = formatter

        self[level] = function(self, ...)
            return self:_log(level, ...)
        end
    end
end

---@param levels [string, fun(logger: Yapp.Term.Log, ...: string): string][]
---@return Yapp.Term.Log
function log:format(levels)
    local logger = rawget(self, "_format") and 
        self:_clone() or self

    logger:_set_format(levels)

    return logger
end

---@protected
function log:_log(level, ...)
    if self._levels[level] < self._levels[self.level] then
        return
    end

    local formatter = self._formatters[level]

    print(formatter(self, ...))
end

---@param level string
local function make_formatter(level, color)
    return { level, function(log, ...)
        ---@diagnostic disable-next-line:param-type-mismatch
        local args_string = map({ ... }, tostring)

        local tag = log:get_tag()
        tag = tag and "(" .. tag .. ") " or ""

        local source = log:try_get_source()
        source = source and source .. " " or ""

        return color("[" .. level:upper() .. "\t" .. log:get_date() .. "] ") .. tag .. source ..
        table.concat(args_string, " ")
    end }
end

--[[
TODO yet another reworked format API:

log:format({
    { "trace", "[TRACE]\t", "{date}", "{message}" }

    -- functions that consume the logger as self and return some string.
    -- defaults exist, so fear not.
    getters = {},
    -- function that concatenates ... from message
    concatenator = function (level, ...)
    
    end
})

the numeric portion of the table represents levels, in order. any
"{<getter-name>}" is replaced w/ the actual getter. this is stored keyed by
level name. then, when a log is made, the arguments are assembled and called w/
self as argument. Then, we concatenate. Nil values should be ignored by the
format's given concatenator, but that's up to users.

TODO allow truncating tags in format strings
]]

-- TODO this API feels shitty.
log:_set_format({
    -- TODO what color does rxi/log.lua use? https://github.com/rxi/log.lua
    make_formatter("trace", chalk.dim.blue),
    make_formatter("debug", chalk.blue),
    make_formatter("info", chalk.green),
    make_formatter("warn", chalk.yellow),
    make_formatter("error", chalk.redBright),
    make_formatter("fatal", chalk.red),
})

log.level = "trace"

return log
