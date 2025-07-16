
---@diagnostic disable-next-line:deprecated
local load = loadstring or load
local has_pow_op = load("return 2 ^ 2")

if has_pow_op then
    return require("src.math.pow.pow_53")
else
    return require("src.math.pow.pow")
end