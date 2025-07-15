---@type Yapp.Bit
local bit_53 = {
    band = function(a, b)
        return a & b
    end,
    bor = function(a, b)
        return a | b
    end,
    bxor = function(a, b)
        return a ~ b
    end,
    bnot = function(a)
        return ~a
    end,
    lshift = function(a, b)
        return a << b
    end,
    rshift = function(a, b)
        return a >> b
    end,

    _is_native = true,
    _implementation_name = "bit_53"
}

return bit_53
