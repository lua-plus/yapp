local HotLoader = require("wip.debug.HotLoader")

local hot = HotLoader()
    :add_filter(function(_, path)
        -- TODO this is bad!
        if path:sub(1,1) == "/" then
            return false
        end

        return true
    end)

require = hot:get_require_shim()

local func = require("hotbed")
func()

hot:add_handler(function ()
    func()
end)

hot:glib_poll_loop()