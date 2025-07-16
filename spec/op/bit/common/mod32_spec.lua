
local pow = require("src.math.pow")

local mod32 = require("src.op.bit.common.mod32")

describe("mod32", function ()
    it("wraps 2^32", function ()
        local big = pow(2, 32)

        assert.equal(0, mod32(big))
    end)

    it("doesn't wrap 2^32 - 1", function ()
        local big = pow(2, 32) - 1

        assert.equal(big, mod32(big))
    end)

    it("wraps -2^32", function ()
        local big = -pow(2, 32)

        assert.equal(0, mod32(big))
    end)

    it("doesn't wrap 1 - 2^32", function ()
        local big = 1 - pow(2, 32)

        assert.equal(big, mod32(big))
    end)
end)