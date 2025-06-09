local get_source = require("src.debug.fn.get_source")
local _, lfs = pcall(require, "lfs")

if debug then
    describe("get_source", function()
        it("works for lua functions", function()
            local fn = function() end

            local source = get_source(fn)

            -- This better look like a location
            assert.match("[%w/\\_-%. ]:%d+", source)
        end)

        if lfs then
            it("works for C functions", function()
                local fn = lfs.attributes

                local source = get_source(fn)

                assert.equal("(C function)", source)
            end)
        end
    end)
end
