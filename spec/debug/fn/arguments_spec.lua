local arguments = require("src.debug.fn.arguments")
local _, lfs = pcall(require, "lfs")

if debug then
    describe("arguments", function()
        it("works for zero arguments", function()
            local fn = function() end

            local description = arguments(fn)

            assert.equal("function like ()", description)
        end)

        it("works for one argument", function()
            local fn = function(a) end

            local description = arguments(fn)

            assert.equal("function like (a)", description)
        end)

        it("works for two arguments", function()
            local fn = function(a, b) end

            local description = arguments(fn)

            assert.equal("function like (a, b)", description)
        end)

        it("works for variadic arguments", function()
            local fn = function(a, b, ...) end

            local description = arguments(fn)

            assert.equal("function like (a, b, ...)", description)
        end)

        if lfs then
            it("works for C functions", function()
                local fn = lfs.attributes

                local description = arguments(fn)

                assert.equal("function like (?)", description)
            end)
        end
    end)
end
