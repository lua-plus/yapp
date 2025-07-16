---@nospec

-- Load bit library without wrapping any callbacks in mod32

do
    ---@diagnostic disable-next-line:deprecated
    local load = loadstring or load
    local has_bit_operators = load("return 1 << 2")

    if has_bit_operators then
        return require("src.op.bit.impl.bit_53")
    end
end

do
    if package.loaded['bit32'] then
        return require("src.op.bit.impl.bit_52")
    end
end

do
    -- LuaJIT bit operators
    if package.loaded['bit'] then
        return require("src.op.bit.impl.bit_jit")
    end
end

return require("src.op.bit.impl.vanilla")
