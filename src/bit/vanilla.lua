local floor = math.floor
local pow = require("src.math.pow")

local mod_32 = floor(pow(2, 33))
--- Safely perform signed modulo on the value given
---@param value integer
---@return integer
local function bit_mod32(value)
    if value >= 0 then
        return floor(value % mod_32)
    end

    return -floor(-value % mod_32)
end

--- Similar to https://github.com/AlberTajuelo/bitop-lua, but
--- this approach is more efficient to index and supports negatives.
--- Construct a binary operator from the per-bit results of
---  [ [0, 0], [0, 1], [1, 0], [1, 1] ]
---@param op [integer, integer, integer, integer]
---@return fun(a: integer, b: integer): integer
local function make_bitop(op)
    return function(a, b)
        local sign_a = 0
        a = floor(a)
        if a < 0 then
            sign_a = 1
            a = mod_32 + a
        end

        local sign_b = 0
        b = floor(b)
        if b < 0 then
            sign_b = 1
            b = mod_32 + b
        end

        local sign_idx = sign_a * 2 + sign_b + 1
        local sign = 1 - 2 * op[sign_idx]

        local out = 0
        local out_mult = 1

        while a ~= 0 or b ~= 0 do
            local b_a = a % 2
            local b_b = b % 2

            local op_idx = (b_a * 2) + b_b + 1
            local bit_res = op[op_idx]
            out = out + (bit_res * out_mult)

            a = (a - b_a) / 2
            b = (b - b_b) / 2

            out_mult = out_mult * 2
        end

        if sign == -1 then
            out = out - mod_32
        end

        return bit_mod32(out)
    end
end

local inf = 1/0

---@param a integer
---@param b integer
local function lshift(a, b)
    assert(a >= 0 and b >= 0, "arguments must be non-negative")
    a = floor(a)
    b = floor(b)

    local shifted = floor(a * pow(2, b))

    -- This number isn't representable.
    if shifted == inf then
        return 0
    end

    return bit_mod32(shifted)
end

---@param a integer
---@param b integer
local function rshift(a, b)
    assert(a >= 0 and b >= 0, "arguments must be non-negative")
    a = floor(a)
    b = floor(b)

    local shifted = a / pow(2, b)

    return bit_mod32(shifted)
end

---@param a integer
local function bnot(a)
    return bit_mod32(-a) - 1
end

---@type Yapp.Bit
local bit_vanilla = {
    band = make_bitop({ 0, 0, 0, 1 }),
    bor = make_bitop({ 0, 1, 1, 1 }),
    bxor = make_bitop({ 0, 1, 1, 0 }),
    bnot = bnot,
    lshift = lshift,
    rshift = rshift,

    _implementation_name = "bit_lua"
}

return bit_vanilla
