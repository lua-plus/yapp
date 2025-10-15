local crush     = require("src.table.crush")
local pack      = require("src.table.pack")
local support   = require("src.term.chalk.util.support")
local colors    = require("src.term.chalk.util.colors")

---@alias Yapp.Chalk.Getter fun(...: any): string
---@alias Yapp.Chalk.Field Yapp.Chalk.Getter | Yapp.Chalk.SubChalk

---@class Yapp.Chalk.Chalk : Yapp.Chalk.SubChalk
---@field strip fun(str: string): string Return a copy of the input string with colors removed.

---@class Yapp.Chalk.SubChalk
---@field protected _styles Yapp.Chalk.Style[] The current chalk's style list
---@field protected _level Yapp.Chalk.SupportLevel The terminal's ANSI color support level
---
--- Multicolor
---@field rgb fun(r: integer, g: integer, b: integer): Yapp.Chalk.Field
---@field bgRgb fun(r: integer, g: integer, b: integer): Yapp.Chalk.Field
---@field hex fun(hex: string): Yapp.Chalk.Field
---@field bgHex fun(hex: string): Yapp.Chalk.Field
---
--- modifier
---@field reset Yapp.Chalk.Field
---@field bold Yapp.Chalk.Field
---@field dim Yapp.Chalk.Field
---@field italic Yapp.Chalk.Field
---@field underline Yapp.Chalk.Field
---@field overline Yapp.Chalk.Field
---@field inverse Yapp.Chalk.Field
---@field hidden Yapp.Chalk.Field
---@field strikethrough Yapp.Chalk.Field
---
--- color
---@field black Yapp.Chalk.Field
---@field red Yapp.Chalk.Field
---@field green Yapp.Chalk.Field
---@field yellow Yapp.Chalk.Field
---@field blue Yapp.Chalk.Field
---@field magenta Yapp.Chalk.Field
---@field cyan Yapp.Chalk.Field
---@field white Yapp.Chalk.Field
---@field blackBright Yapp.Chalk.Field
---@field gray Yapp.Chalk.Field
---@field grey Yapp.Chalk.Field
---@field redBright Yapp.Chalk.Field
---@field greenBright Yapp.Chalk.Field
---@field yellowBright Yapp.Chalk.Field
---@field blueBright Yapp.Chalk.Field
---@field magentaBright Yapp.Chalk.Field
---@field cyanBright Yapp.Chalk.Field
---@field whiteBright Yapp.Chalk.Field
---
--- bgColor
---@field bgBlack Yapp.Chalk.Field
---@field bgRed Yapp.Chalk.Field
---@field bgGreen Yapp.Chalk.Field
---@field bgYellow Yapp.Chalk.Field
---@field bgBlue Yapp.Chalk.Field
---@field bgMagenta Yapp.Chalk.Field
---@field bgCyan Yapp.Chalk.Field
---@field bgWhite Yapp.Chalk.Field
---@field bgBlackBright Yapp.Chalk.Field
---@field bgGray Yapp.Chalk.Field
---@field bgGrey Yapp.Chalk.Field
---@field bgRedBright Yapp.Chalk.Field
---@field bgGreenBright Yapp.Chalk.Field
---@field bgYellowBright Yapp.Chalk.Field
---@field bgBlueBright Yapp.Chalk.Field
---@field bgMagentaBright Yapp.Chalk.Field
---@field bgCyanBright Yapp.Chalk.Field
---@field bgWhiteBright Yapp.Chalk.Field

---@class Yapp.Chalk.Lib : Yapp.Chalk.SubChalk
local chalk_lib = {}

--- Return a new Chalk that has the styles of the input Chalk,
--- but with new_style added to the list.
---@param chalk Yapp.Chalk.SubChalk
---@param new_style Yapp.Chalk.Style
function chalk_lib.clone_with_style(chalk, new_style)
    local level = chalk._level
    -- make a copy, then add the style
    local styles = crush(chalk._styles)
    table.insert(styles, new_style)

    return setmetatable({
        _level = level,
        _styles = styles
    }, chalk_lib.sub_mt)
end

--- Return a function that consumes an RGB or hex value and returns a Chalk.
---@param chalk Yapp.Chalk.SubChalk
---@param is_bg boolean
---@param is_rgb boolean
---@return fun(...: any): Yapp.Chalk.SubChalk
function chalk_lib.make_true_color_getter(chalk, is_bg, is_rgb)
    local transform = is_rgb and
        pack or
        colors.transform.hex_to_rgb

    local reset = is_bg and 49 or 39

    return function(...)
        local color = transform(...)

        return chalk_lib.clone_with_style(chalk, {
            color, reset, support.level.ANSI_16m
        })
    end
end

local rgb_names = {
    ["rgb"] = { false, true },
    ["bgRgb"] = { true, true },
    ["hex"] = { false, false },
    ["bgHex"] = { true, false }
}
rgb_names.bg_rgb = rgb_names["bgRgb"]
rgb_names.bg_hex = rgb_names["bgHex"]

---@param chalk Yapp.Chalk.SubChalk
---@param name string
function chalk_lib.mt_index(chalk, name)
    local rgb_flags = rgb_names[name]
    if rgb_flags then
        local is_bg = rgb_flags[1]
        local is_rgb = rgb_flags[2]

        return chalk_lib.make_true_color_getter(chalk, is_bg, is_rgb)
    end

    local style = colors.get_style_by_name(name)
    if style then
        return chalk_lib.clone_with_style(chalk, style)
    end

    return nil
end

--- Iterator for pairs
---@param chalk Yapp.Chalk.SubChalk
---@param key string
local function chalk_pairs_iter(chalk, key)
    local new_key = next(colors.styles.all, key)

    local value
    if new_key then
        local style = colors.get_style_by_name(new_key)

        if style then
            value = chalk_lib.clone_with_style(chalk, style)
        end
    end

    return new_key, value
end

--- Chalk items don't contain any 'real' keys, so we mock iterate them
--- to get all ANSI styles.
---@param chalk Yapp.Chalk.SubChalk
function chalk_lib.mt_pairs(chalk)
    return chalk_pairs_iter, chalk, nil
end

--- Turn the given Chalk's styles list into prefix and suffix strings
---@param chalk Yapp.Chalk.SubChalk
---@return string s_in, string s_out
function chalk_lib.compute_styles(chalk)
    local s_in = ""
    local s_out = ""

    for _, style in ipairs(chalk._styles) do
        local escapes = colors.wrap_for_level(chalk._level, style)

        s_in = s_in .. escapes[1]
        s_out = s_out .. escapes[2]
    end

    return s_in, s_out
end

---@param chalk Yapp.Chalk.SubChalk
---@param ... any
---@return string
function chalk_lib.mt_call(chalk, ...)
    local s_in, s_out = chalk_lib.compute_styles(chalk)

    local ret = s_in

    local argv = select("#", ...)
    local args = { ... }
    for i = 1, argv do
        local s = tostring(args[i])

        if s ~= "" then
            -- Put spaces between arguments
            if i ~= 1 then
                ret = ret .. " "
            end
            ret = ret .. s

            -- any escape is a good indicator this is a chalk substring
            if s:match("\27") then
                -- so we re-escape to this current style
                ret = ret .. s_in
            end
        end
    end

    -- now reset styles.
    ret = ret .. s_out

    return ret
end

-- Metatable for the root Chalk object.
chalk_lib.chalk_mt = {
    __index = chalk_lib.mt_index,
    __pairs = chalk_lib.mt_pairs,
}

-- Metatable for sub-Chalks, which contain actual styles and can be called.
chalk_lib.sub_mt = {
    __index = chalk_lib.mt_index,
    __pairs = chalk_lib.mt_pairs,
    __call = chalk_lib.mt_call,
}

--- Strip any ANSI color codes from the string
---@param str string
---@return string
function chalk_lib.strip(str)
    local ret = str
        -- ANSI
        :gsub("\27%[%d+m", "")
        -- ANSI 256
        :gsub("\27%[%d+;5;%d+m", "")
        -- ANSI 16m
        :gsub("\27%[%d+;2;%d+;%d+;%d+m", "")

    return ret
end

---@return Yapp.Chalk.Chalk
function chalk_lib.make_chalk()
    local level = support.get()

    return setmetatable({
        _level = level,
        _styles = {},

        strip = chalk_lib.strip
    }, chalk_lib.chalk_mt)
end

return chalk_lib
