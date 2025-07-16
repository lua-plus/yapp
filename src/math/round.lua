local floor = math.floor

--- Round a number at the 1/2 split.
---@param num number
---@return integer
local function round(num)
    return floor(num + 0.5)
end

return round
