local bindargs = require("src.class.Promise.bindargs")
local pack     = require("src.table.pack")
local unpack   = require("src.table.unpack")

local function closure_wrap(cb, ...)
    local args = pack(...)

    return function(...)
        return cb(unpack(args), ...)
    end
end

describe("class.Promise.bindargs", function()
    it("uses less memory than closures", function()
        local my_func = function(name)
            print("Hello " .. name .. "!")
        end

        -- dry run
        local i = 0
        local c = closure_wrap(my_func, "busted")
        local b = bindargs.create(my_func, "busted")

        local closures = {}
        local bindings = {}

        collectgarbage("stop")

        local mem_init = collectgarbage("count")

        for i=1,1000 do
            closures[i] = closure_wrap(my_func, "busted")
        end

        local mem_mid = collectgarbage("count")

        for i=1,1000 do
            bindings[i] = bindargs.create(my_func, "busted")
        end

        local mem_end = collectgarbage("count")

        local mem_closures = mem_mid - mem_init
        local mem_bindargs = mem_end - mem_mid

        assert.True(mem_bindargs < mem_closures)

        collectgarbage("restart")
    end)
end)
