local mod32 = require("src.bit.common.mod32")
local bit_unsafe = require("src.bit.unsafe")

--- Integer bitwise operations equivalent to lua 5.3. You should assume this ignores metatables,
--- because integers.
---@class Yapp.Bit
---@field band fun(a: integer, b: integer): integer Logical AND two inputs
---@field bor fun(a: integer, b:integer): integer logical OR two inputs
---@field bxor fun(a: integer, b: integer): integer logical XOR two inputs
---@field bnot fun(a: integer): integer logical NOT two inputs
---@field lshift fun(a: integer, b:integer): integer shift a left by b
---@field rshift fun(a: integer, b: integer): integer shift a right by b
---
---@field _is_native true?
---@field _implementation_name string?

---@class Yapp.Bit.Entrypoint : Yapp.Bit
---@field unsafe Yapp.Bit
-- ---@field mt Yapp.Bit

--- Throw some checks around the given implementation
---@param lib Yapp.Bit
---@return Yapp.Bit.Entrypoint
local function wrap_bit(lib)
    local band = lib.band
    local bor = lib.bor
    local bxor = lib.bxor
    local bnot = lib.bnot
    local lshift = lib.lshift
    local rshift = lib.rshift

    ---@type Yapp.Bit.Entrypoint
    local out = {
        band = function(a, b)
            a = mod32(a)
            b = mod32(b)

            return mod32(band(a, b))
        end,
        bor = function(a, b)
            a = mod32(a)
            b = mod32(b)

            return mod32(bor(a, b))
        end,

        bxor = function(a, b)
            a = mod32(a)
            b = mod32(b)

            return mod32(bxor(a, b))
        end,

        bnot = function(a)
            a = mod32(a)

            return mod32(bnot(a))
        end,

        lshift = function(a, b)
            assert(a >= 0 and b >= 0, "arguments must be non-negative")

            a = mod32(a)
            b = mod32(b)

            return mod32(lshift(a, b))
        end,

        rshift = function(a, b)
            assert(a >= 0 and b >= 0, "arguments must be non-negative")

            a = mod32(a)
            b = mod32(b)

            return mod32(rshift(a, b))
        end,

        _is_native = lib._is_native,
        _implementation_name = lib._implementation_name,

        unsafe = lib
    }

    return out
end

return wrap_bit(bit_unsafe)
