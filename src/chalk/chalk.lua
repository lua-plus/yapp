local crush   = require("src.table.crush")
local pack    = require("src.table.pack")
local support = require("src.chalk.util.support")
local colors  = require("src.chalk.util.colors")

---@alias Yapp.Chalk.Getter fun(...: any): string

---@alias Yapp.Chalk.Field Yapp.Chalk.Getter | Yapp.Chalk.SubChalk

---@class Yapp.Chalk.Chalk
---@field protected styles Yapp.Chalk.Style[]
---@field protected level Yapp.Chalk.SupportLevel
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

---@class Yapp.Chalk.SubChalk : Yapp.Chalk.Chalk

local make_sub_chalk

---@param chalk Yapp.Chalk.Chalk
---@param is_bg boolean
---@param color [ integer, integer, integer ]
local function make_rgb_sub_chalk(chalk, is_bg, color)
    local reset = is_bg and 49 or 39

    return make_sub_chalk(chalk, { color, reset, support.level.ANSI_16m })
end

---@param chalk Yapp.Chalk.Chalk
---@param is_bg boolean
---@param is_rgb boolean
local function make_rgb_getter(chalk, is_bg, is_rgb)
    local transform = is_rgb and pack or colors.transform.hex_to_rgb

    return function (...)
        local rgb = transform(...)

        return make_rgb_sub_chalk(chalk, is_bg, rgb)
    end
end

--[[
We use these enum-esque values for bitfield information.

NAME    BG?     RGB?    VALUE
rgb     0       1       1
bgRgb   1       1       3
hex     0       0       0
bgHex   1       0       2
]]
local rgb_names = {    
    ["rgb"] = 1,
    ["bgRgb"] = 3,
    ["hex"] = 0,
    ["bgHex"] = 2,
}

local chalk_mt = {
    ---@param t Yapp.Chalk.Chalk
    ---@param name string
    __index = function(t, name)
        local is_named = rgb_names[name]
        if is_named then
            -- TODO i didn't wanna think about bit ops yet.
            local is_bg = (math.floor(is_named / 2) % 2) == 1
            local is_rgb = (is_named % 2) == 1

            return make_rgb_getter(t, is_bg, is_rgb)
        end

        local style = colors.get_style_by_name(name)
        if not style then
            return nil
        end
        return make_sub_chalk(t, style)
    end,
    __pairs = function(t)
        local virtual = {}

        for name in pairs(colors.styles.all) do
            virtual[name] = make_sub_chalk(t, name)
        end

        return next, virtual, nil
    end
}

local sub_chalk_mt = crush(chalk_mt, {
    --- Wrap input objects as strings in a color
    ---@param t Yapp.Chalk.SubChalk
    ---@param ... any
    __call = function(t, ...)
        local ins = {}
        local outs = {}
        ---@diagnostic disable-next-line:invisible
        for _, style in ipairs(t.styles) do
            ---@diagnostic disable-next-line:invisible
            local escapes = colors.wrap_for_level(t.level, style)

            table.insert(ins, escapes[1])
            table.insert(outs, escapes[2])
        end

        local s_in = table.concat(ins)
        local s_out = table.concat(outs)

        local args = {}
        for i, arg in ipairs({ ... }) do
            local s = tostring(arg)
            -- any escape is a good indicator this is an escaped substring
            if s:match("\27") then
                -- so we re-escape to this current chalk
                s = s .. s_in
            end

            args[i] = s
        end
        local msg = table.concat(args, " ")

        return s_in .. msg .. s_out
    end
})

---@param chalk table
---@param new_style Yapp.Chalk.Style
make_sub_chalk = function(chalk, new_style)
    local styles = crush(chalk.styles)
    table.insert(styles, new_style)

    return setmetatable({
        level = chalk.level,
        styles = styles
    }, sub_chalk_mt)
end

---@return Yapp.Chalk.Chalk
local function make_chalk()
    local level = support.get()

    return setmetatable({
        level = level,
        styles = {},
    }, chalk_mt)
end

local chalk = make_chalk()

return chalk
