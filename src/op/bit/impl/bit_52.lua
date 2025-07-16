---@nospec Can only be tested against impl/vanilla in lua 5.2

if false then
    bit32 = {}
end

---@type Yapp.Bit
local bit_52 = {
    band = bit32.band,
    bor = bit32.bor,
    bxor = bit32.bxor,
    bnot = bit32.bnot,
    lshift = bit32.lshift,
    rshift = bit32.rshift,

    _is_native = true,
    _implementation_name = "bit_52"
}

return bit_52
