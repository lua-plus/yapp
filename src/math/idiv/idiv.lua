local floor = math.floor

--- Perform integer division.
---@param a integer
---@param b integer
return function(a, b)
    return floor(a / b)
end
