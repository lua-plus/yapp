
-- Globals table built when yapp loads.
local globals = {
    _entries = nil
}

---@param G table
function globals.init (G)
    if globals._entries then
        return
    end

    globals._entries = {}
    for k, v in pairs(G) do
        globals._entries[k] = v
    end
end

---@return table
function globals.get ()
    globals.init(_G)

    return globals._entries
end

function globals.get_names ()
    globals.init(_G)

    if globals._names then
        return globals._names
    end
    
    globals._names = {}

    local traversed = {
        [package.loaded] = true,
        [_G] = true
    }

    local recurse
    ---@param t table
    ---@param prefix string|nil
    recurse = function (t, prefix)
        if traversed[t] then
            return
        end
        traversed[t] = true

        local type_t = type(t)

        if type_t == "table" or type_t == "function" then
            -- throw this item in the global name table
            globals._names[t] = prefix
        end

        -- recurse into tables
        if type_t == "table" then
            for k, v in pairs(t) do
                -- And create lua-valid strings to index them
                local type_k = type(k)
                if type_k == "string" or type_k == "number" then
                    local name = k
                    if prefix then
                        if type_k == "number" then
                            name = string.format("%s[%d]", prefix, name)
                        elseif not name:match("[%a_][%w_]+") then
                            name = string.format("%s[%q]", prefix, name)
                        else    
                            name = prefix .. "." .. name
                        end
                    end

                    recurse(v, name --[[@as string]])                        
                end
            end
        end
    end

    recurse(globals.get())

    return globals._names
end

return globals