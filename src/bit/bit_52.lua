local bit32 = assert(package.loaded["bit32"])

---@type Yapp.Bit
local bit_52 = {
    band = function(a, b)
        return bit32.band(a, b)
    end,
    bor = function(a, b)
        return bit32.bor(a, b)
    end,
    bxor = function(a, b)
        return bit32.bxor(a, b)
    end,
    bnot = function(a)
        return bit32.bnot(a)
    end,
    lshift = function(a, b)
        assert(a >= 0 and b >= 0, "arguments must be non-negative")
        return bit32.lshift(a, b)
    end,
    rshift = function(a, b)
        assert(a >= 0 and b >= 0, "arguments must be non-negative")
        return bit32.rshift(a, b)
    end,

    _is_native = true,
    _implementation_name = "bit_52"
}

return bit_52
