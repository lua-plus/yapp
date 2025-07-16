local pow = require("src.math.pow")
local pow_compat = require("src.math.pow.pow")
local at_least_lua_53 = require("spec.helper.at_least_lua_53")

if pow == pow_compat and not at_least_lua_53 then
    return
end

describe("math.pow", function()
    it("loads the native-operator version", function()
        assert.are_not_equal(pow, pow_compat)
    end)

    it("is accurate for a bunch of terms", function()
        local bounds = 32

        for i = -bounds, bounds do
            for j = -bounds, bounds do
                assert.equal(pow(i, j), pow_compat(i, j))
            end
        end
    end)
end)
