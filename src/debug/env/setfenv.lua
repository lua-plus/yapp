-- https://leafo.net/guides/setfenv-in-lua52-and-above.html

---@diagnostic disable-next-line:deprecated
return setfenv or (debug or {}).setfenv or (function ()
    local debug_getupvalue = (debug or {}).getupvalue
    local debug_upvaluejoin = (debug or {}).upvaluejoin

    assert(debug_getupvalue and debug_upvaluejoin, "debug.getupvalue and debug.upvaluejoin must exist")

    local function setfenv(fn, env)
        if type(fn) == "number" then
            fn = debug.getinfo(fn, "f").func
        end
        
        local i = 1
        while true do
            local name = debug_getupvalue(fn, i)
            if name == "_ENV" then
                debug_upvaluejoin(fn, i, (function()
                    return env
                end), 1)
                break
            elseif not name then
                break
            end
    
            i = i + 1
        end
    
        return fn
    end
    
    return setfenv
end)()