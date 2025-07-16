local getn = require("src.table.getn")

--- from my (unfinished-ish) requiratron project - acts as ?? does in javascript

---@generic T
---@alias Yapp.NilCoalesce.1 fun(a: `T`): T
---@generic T
---@alias Yapp.NilCoalesce.2 fun(a: nil, b: T): T
---@generic T
---@alias Yapp.NilCoalesce.3 fun(a: nil, b: nil, c: T): T
---@generic T
---@alias Yapp.NilCoalesce.4 fun(a: nil, b: nil, c: nil, d: T): T
---@generic T
---@alias Yapp.NilCoalesce.5 fun(a: nil, b: nil, c: nil, d: nil, e: T): T
---@generic T
---@alias Yapp.NilCoalesce.6 fun(a: nil, b: nil, c: nil, d: nil, e: nil, f: T): T
---@generic T
---@alias Yapp.NilCoalesce.7 fun(a: nil, b: nil, c: nil, d: nil, e: nil, f: nil, g: T): T
---@generic T
---@alias Yapp.NilCoalesce.8 fun(a: nil, b: nil, c: nil, d: nil, e: nil, f: nil, g: nil, h:   T): T

---@alias Yapp.NilCoalesce Yapp.NilCoalesce.1 | Yapp.NilCoalesce.2 | Yapp.NilCoalesce.3 | Yapp.NilCoalesce.4 | Yapp.NilCoalesce.5 | Yapp.NilCoalesce.6 | Yapp.NilCoalesce.7 | Yapp.NilCoalesce.8

-- ---@param ... any
---@type Yapp.NilCoalesce
local nil_coalesce = function (...)
    local args = table.pack(...)
    
    for i=0,getn(args) do
        local element = args[i]

        if element ~= nil then
            return element
        end
    end

    return nil
end

return nil_coalesce