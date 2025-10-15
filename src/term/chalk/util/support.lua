local is_windows = require("src.os.is_windows")
local release    = require("src.os.release")

local support    = {}

---@enum Yapp.Chalk.SupportLevel
support.level    = {
    NONE = 1,
    ANSI = 2,
    ANSI_256 = 3,
    ANSI_16m = 4
}

-- TODO this check is not NEARLY as exhaustive as chalk js
function support.get()
    -- From https://github.com/chalk/chalk/blob/main/source/vendor/supports-color/index.js
    -- Windows 10 build 10586 is the first Windows release that supports 256 colors.
    -- Windows 10 build 14931 is the first release that supports 16m/TrueColor.
    if is_windows then
        local release = release()
        if release then
            local ver, patch, build = release:match("(%d+)%.(%d+)%.(%d+)")
            if ver > "10" then
                return support.level.ANSI_16m
            elseif ver == "10" then
                if build >= "14931" then
                    return support.level.ANSI_16m
                elseif build >= "10586" then
                    return support.level.ANSI_256
                end
            end
        end

        return support.level.ANSI
    end

    local term = os.getenv("TERM")
    if not term or term == "dumb" then
        return support.level.NONE
    end

    if term:match("%-256color$") then
        return support.level.ANSI_256
    end

    if term == "xterm-kitty" then
        return support.level.ANSI_16m
    end

    if os.getenv("COLORTERM") == "truecolor" then
        return support.level.ANSI_16m
    end

    return support.level.ANSI
end

return support
