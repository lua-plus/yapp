local idiv = require("src.math.idiv")
local idiv_compat = require("src.math.idiv.idiv")
local at_least_lua_53 = require("spec.helper.at_least_lua_53")

if idiv == idiv_compat and not at_least_lua_53 then
    return
end

describe("math.idiv", function()
    it("loads the native-operator version", function()
        assert.are_not_equal(idiv, idiv_compat)
    end)

    it("is accurate for a bunch of terms", function()
        local bounds = 32

        for i = -bounds, bounds do
            for j = -bounds, bounds do
                if j ~= 0 then 
                    assert.equal(idiv(i, j), idiv_compat(i, j))
                end
            end
        end
    end)
end)
