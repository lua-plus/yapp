
local floor = math.floor
local round = require("src.math.round")

describe("math.round", function ()
    it("rounds up when floor doesn't.", function ()
        local r = round(1.5)
        local f = floor(1.5)

        assert.equal(2, r)
        assert.are_not_equal(f, r)
    end)

    it("still rounds down", function ()
        local r = round(1.3)
        local f = floor(1.3)

        assert.equal(1, r)
        assert.equal(f, r)
    end)
end)