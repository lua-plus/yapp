local bit = assert(package.loaded["bit"])

-- bit.tobit,
-- bit.tohex,
-- bit.bnot,
-- bit.band,
-- bit.bor,
-- bit.bxor,
-- bit.lshift,
-- bit.rshift,
-- bit.arshift,
-- bit.rol,
-- bit.ror,
-- bit.bswap

---@type Yapp.Bit
local bit_jit = {
    band = function(a, b)
        return bit.band(a, b)
    end,
    bor = function(a, b)
        return bit.bor(a, b)
    end,
    bxor = function(a, b)
        return bit.bxor(a, b)
    end,
    bnot = function(a)
        return bit.bnot(a)
    end,
    lshift = function(a, b)
        assert(a >= 0 and b >= 0, "arguments must be non-negative")
        return bit.lshift(a, b)
    end,
    rshift = function(a, b)
        assert(a >= 0 and b >= 0, "arguments must be non-negative")
        return bit.rshift(a, b)
    end,

    _is_native = true,
    _implementation_name = "bit_jit"
}

return bit_jit
