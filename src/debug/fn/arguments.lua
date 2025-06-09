local debug_getinfo = assert((debug or {}).getinfo, "debug.getinfo must exist.")

-- TODO FIXME get argument names.

---@param fn function
local function describe(fn)
    local info = debug_getinfo(fn, "uS")

    local letter_offset = string.byte('a') - 1
    local args = {}
    if info.what == "Lua" then
        for i = 1, info.nparams do
            local char = string.char(letter_offset + i)

            table.insert(args, char)
        end
        if info.isvararg then
            table.insert(args, "...")
        end
    elseif info.what == "C" then
        args = { "?" }
    end

    return string.format("function like (%s)", table.concat(args, ", "))
end

return describe
