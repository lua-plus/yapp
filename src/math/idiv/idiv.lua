---@nospec tested in spec/math/idiv_spec.lua

local floor = math.floor

--- Perform integer division.
---@param a number
---@param b number
---@return integer
return function(a, b)
    return floor(a / b)
end
