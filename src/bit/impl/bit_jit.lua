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
    band = bit.band,
    bor = bit.bor,
    bxor = bit.bxor,
    bnot = bit.bnot,
    lshift = bit.lshift,
    rshift = bit.rshift,

    _is_native = true,
    _implementation_name = "bit_jit"
}

return bit_jit
