-- https://leafo.net/guides/setfenv-in-lua52-and-above.html

---@diagnostic disable-next-line:deprecated
return getfenv or (debug or {}).getfenv or (function()
    local debug_getupvalue = (debug or {}).getupvalue
    
    assert(debug_getupvalue, "debug.getupvalue must exist")
    
    local function getfenv(fn)
        local i = 1
        while true do
            local name, val = debug_getupvalue(fn, i)
            if name == "_ENV" then
                return val
            elseif not name then
                break
            end
            i = i + 1
        end
    end

    return getfenv
end)()