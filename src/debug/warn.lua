
if warn then
    return warn
end

local warn_on = false

local function warn(...)
    local msg = table.concat({...}, "\t")

    if msg == "@on" then
        warn_on = true
        return
    elseif msg == "@off" then
        warn_on = false
        return
    end

    if not warn_on then
        return
    end

    -- TODO this but better with colors
    print("WARNING", msg)
end

return warn