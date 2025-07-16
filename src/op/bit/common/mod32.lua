local pow = require("src.math.pow")
local floor = math.floor

local cap = floor(pow(2, 32))
--- Safely perform signed modulo on the value given
---@param value integer
---@return integer
local function mod32(value)
    if value >= 0 then
        return floor(value % cap)
    end

    return -floor(-value % cap)
end

return mod32