
local pack = require("src.table.pack")
local unpack = require("src.table.unpack")

-- TODO move to yapp.fn?

local bindargs = {}

---@alias Yapp.Promise.Bindargs { [1]: function, [number]: any }

--- Create a table that stores a function and multiple arguments.
---@generic F : function, T
---@param cb F
---@param ... T
---@return Yapp.Promise.Bindargs
function bindargs.create (cb, ...)
    return pack(cb, ...)
end

--- Call a binding with post-binding arguments
---@param bound Yapp.Promise.Bindargs
function bindargs.call (bound, ...)
    return bindargs.call_transcend(bound, {}, pack(...))
end

--- Call a binding, with pre-and-post-binding arguments
---@param bound Yapp.Promise.Bindargs
function bindargs.call_transcend(bound, pre, post)
    local cb = bound[1]
    
    local args = { unpack(pre) }
    for _, v in ipairs({ unpack(bound, 2) }) do
        args[#args+1] = v
    end
    for _, v in ipairs(post) do
        args[#args+1]=v
    end

    return cb(unpack(args))
end

return bindargs