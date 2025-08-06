local class             = require("lib.30log")
local list_to_keys      = require("src.table.list.to_keys")
local unpack            = require("src.table.unpack")
local max               = math.max
local min               = math.min

---@class Yapp.VirtualFileHandle.Tree
---@field branches table<integer, string | Yapp.VirtualFileHandle.Tree>
---@field len integer
---@field root Yapp.VirtualFileHandle.Tree?

-- TODO what does this mean? https://en.cppreference.com/w/c/io/fopen
-- File access mode flag "b" can optionally be specified to open a file in binary mode.
-- This flag has no effect on POSIX systems, but on Windows it disables special handling of '\n' and '\x1A'.

---@alias Yapp.VirtualFileHandle.Mode
---| "r" Read mode.
---| "w" Write mode.
---| "a" Append mode.
---| "r+" Update mode, all previous data is preserved.
---| "w+" Update mode, all previous data is erased.
---| "a+" Append update mode, previous data is preserved, writing is only allowed at the end of file.
---| "rb" Read mode. (in binary mode.)
---| "wb" Write mode. (in binary mode.)
---| "ab" Append mode. (in binary mode.)
---| "r+b" Update mode, all previous data is preserved. (in binary mode.)
---| "w+b" Update mode, all previous data is erased. (in binary mode.)
---| "a+b" Append update mode, previous data is preserved, writing is only allowed at the end of file. (in binary mode.)

--- A class that mocks file operations efficiently.
---@class Yapp.VirtualFileHandle : Log.BaseFunctions
---
---@field protected _str string
---@field protected _is_open boolean
---@field protected _position integer
--- Mode string is stored for getter but we compare against the flags.
---@field protected _mode Yapp.VirtualFileHandle.Mode | nil
---@field protected _mode_flags ["r"|"w"|nil, boolean] rw_lock, is_binary
---
---@overload fun(): Yapp.VirtualFileHandle
local VirtualFileHandle = class("Yapp.VirtualFileHandle")

function VirtualFileHandle:init()
    self._str = ""

    self._is_open = true

    -- File position is 0-indexed even under Lua's API
    self._position = 0

    self:set_mode(nil)
end

---@protected
VirtualFileHandle._valid_readmodes = list_to_keys({
    "r", "w", "a", "r+", "w+", "a+", "rb", "wb", "ab", "r+b", "w+b", "a+b",
})

---@param mode Yapp.VirtualFileHandle.Mode?
---@return Yapp.VirtualFileHandle
function VirtualFileHandle:set_mode(mode)
    assert(
        not mode or VirtualFileHandle._valid_readmodes[mode],
        "invalid mode"
    )

    self._mode = mode

    if mode then
        local rw_lock, is_binary, is_append
        do
            local ty, plus, binary = mode:match("([rwa])(%+?)(b?)")
            is_append = ty == "a"
            is_binary = binary == "b"

            rw_lock =
                plus == "" and (
                    ty == "a" and "w" or ty
                ) or nil
        end

        self._mode_flags = {
            rw_lock, is_binary
        }

        if is_append then
            self:seek("end", 0)
        end
    else
        self._mode_flags = { nil, false }
    end

    return self
end

--- Get the file's current mode string
---@return Yapp.VirtualFileHandle.Mode | nil
function VirtualFileHandle:get_mode()
    -- TODO this is kinda a moot getter because why do we care if we set up the
    -- file
    return self._mode
end

--- Set the VirtualFileHandle's internal string to some value. Does not modify
--- the position.
---@param str string
---@return Yapp.VirtualFileHandle
function VirtualFileHandle:set_string(str)
    self._str = str

    return self
end

--- Get the VirtualFileHandle's internal string
---@return string
function VirtualFileHandle:get_string()
    return self._str
end

--- Throw an error if the file handle isn't open
---@protected
function VirtualFileHandle:_ch_open()
    if not self._is_open then
        error("attempt to use a closed file", 2)
    end
end

--- Check if the file handle is open and set to the given mode,
--- returning the error as a table of return values
---@protected
---@param mode "w" | "r"
---@return nil | [ nil, string, integer ] err_ret
function VirtualFileHandle:_ch_mode(mode)
    local rw_lock = self._mode_flags[1]
    if not rw_lock or rw_lock == mode then
        return nil
    end

    return { nil, "Bad file descriptor", 9 }
end

---@return boolean ok
function VirtualFileHandle:close()
    self._is_open = false

    return true
end

---@return boolean ok
function VirtualFileHandle:flush()
    self:_ch_open()

    return true
end

---@return fun(): string?
function VirtualFileHandle:lines(...)
    self:_ch_open()

    local modes = { ... }
    if #modes == 0 then
        modes = { "l" }
    end

    return function()
        return self:read(unpack(modes))
    end
end

---@alias Yapp.VirtualFileHandle.ReadMode
---| "a" Reads the whole file.
---| "l" Reads the next line skipping the end of line.
---| "L" Reads the next line keeping the end of line.

--- Read from the VirtualFileHandle
---@nodiscard
---@overload fun(self: self): string
---@overload fun(self: self, count: integer): string Read `count` characters
---@overload fun(self: self, read_mode: "n"): number Reads a numeral and returns it as a number
---@param ... Yapp.VirtualFileHandle.ReadMode
---@return string? ...
function VirtualFileHandle:read(...)
    self:_ch_open()

    local errs = self:_ch_mode("r")
    if errs then
        ---@diagnostic disable-next-line
        return unpack(errs)
    end

    local str = self._str

    local modes = { ... }
    local argv = select("#", ...)

    if argv == 0 then
        modes = { "l" }
        argv = 1
    end

    local rets = {}
    for i = 1, argv do
        local read_mode = modes[i]

        local position = self._position

        if type(read_mode) == "number" then
            local s_end = position + read_mode
            ---@type string | nil
            local slice = str:sub(position + 1, s_end)

            self._position = min(#str, s_end)

            if slice == "" then
                slice = nil
            end

            rets[i] = slice
        elseif read_mode == "a" then
            local slice = str:sub(position + 1)

            self._position = position + #slice

            rets[i] = slice
        elseif read_mode == "l" or read_mode == "L" then
            local match =
                str:match("^([^\n\r]*[\n\r])", position + 1) or
                str:match("^([^\n\r])$", position + 1)

            if match then
                self._position = position + #match

                -- Remove trailing newline
                if read_mode == "l" and match:sub(-2):match("[\n\r]") then
                    match = match:sub(1, -2)
                end

                rets[i] = match
            else
                rets[i] = nil
            end
        elseif read_mode == "n" then
            local match = str:match("^(%-?%d*.?%d*)")
            local num = tonumber(match)
            if num then
                self._position = position + #match

                rets[i] = num
            else
                rets[i] = nil
            end
        else
            local t = type(read_mode)

            error(string.format(
                "bad argument #%d to 'read' (%s)",
                -- the file* API considers 'self' argument 1.
                i + 1,
                t == "string" and
                "invalid format" or
                ("string expected, got " .. t)
            ))
        end
    end

    return unpack(rets)
end

---@alias Yapp.VirtualFileHandle.Whence
---| "set" Base is beginning of the file.
---| "cur" Base is current position.
---| "end" Base is end of file.


--- Get and optionally set the position of the VirtualFileHandle cursor
---@overload fun(self: self): integer
---@param whence Yapp.VirtualFileHandle.Whence
---@param offset integer
---@return integer position
function VirtualFileHandle:seek(whence, offset)
    self:_ch_open()

    if whence and offset then
        local position = self._position
        local str_len = #self._str

        local new_pos = offset
        if whence == "cur" then
            new_pos = position + offset
        elseif whence == "end" then
            new_pos = str_len + offset
        end

        -- check if offset is illegal
        if new_pos < 0 then
            ---@diagnostic disable-next-line
            return nil, "Invalid argument", 22
        end

        self._position = new_pos
        return new_pos
    end

    return self._position
end

---@alias Yapp.VirtualFileHandle.Bufmode
---| "no" no buffering.
---| "full" full buffering.
---| "line" line buffering.

--- Set vbuf mode. This function doesn't do anything.
---@param mode Yapp.VirtualFileHandle.Bufmode
---@param size integer? a size hint.
function VirtualFileHandle:setvbuf(mode, size)
    self:_ch_open()

    local _, _ = mode, size
end

--- Write the given content to the VirtualFileHandle
---@param ... string
---@return Yapp.VirtualFileHandle
function VirtualFileHandle:write(...)
    self:_ch_open()

    local argv = select("#", ...)
    -- The vanilla API actually doesn't return a mode error if you write nothing
    -- on a read-only file.
    if argv == 0 then
        return self
    end

    local err = self:_ch_mode("w")
    if err then
        ---@diagnostic disable-next-line
        return unpack(err)
    end

    local position = self._position
    local null_count = max(0, position - #self._str)
    self._str = self._str .. string.rep("\0", null_count)
    self._position = position + null_count

    -- Collect items as a table of entries
    local items = {}

    local args = { ... }
    -- we want to see nils as arguments
    for i = 1, argv do
        local item = args[i]

        local t = type(item)

        -- TODO this may be moot, table.concat seems to support numbers
        -- file.write secretly supports writing numbers for whatever reason
        if t == "number" then
            item = tostring(item)
            t = "string"
        end

        if t ~= "string" then
            error(string.format(
                "bad argument #%d to 'write' (string expected, got %s)",
                -- the file* API considers 'self' argument 1.
                i + 1,
                t
            ))
        end

        table.insert(items, item)
    end

    local s_items = table.concat(items)
    local offset = #s_items

    self._str =
        self._str:sub(1, position) ..
        s_items ..
        self._str:sub(position + 1 + offset)

    self._position = self._position + offset

    return self
end

return VirtualFileHandle
