--- Integer bitwise operations equivalent to lua 5.3. You should assume this ignores metatables,
--- because integers.
---@class Yapp.Bit
---@field band fun(a: integer, b: integer): integer Logical AND two inputs
---@field bor fun(a: integer, b:integer): integer logical OR two inputs
---@field bxor fun(a: integer, b: integer): integer logical XOR two inputs
---@field bnot fun(a: integer): integer logical NOT two inputs
---@field bshl fun(a: integer, b:integer): integer shift a left by b
---@field bshr fun(a: integer, b: integer): integer shift a right by b
---
---@field _is_native true?
---@field _implementation_name string?

do
    ---@diagnostic disable-next-line:deprecated
    local load = loadstring or load
    local has_bit_operators = load("return 1 << 2")

    if has_bit_operators then
        return require("src.bit.bit_53")
    end
end

do
    if package.loaded['bit32'] then
        return require("src.bit.bit_52")
    end
end

do
    -- LuaJIT bit operators
    if package.loaded['bit'] then
        return require("src.bit.bit_jit")
    end
end

return require("src.bit.vanilla")
