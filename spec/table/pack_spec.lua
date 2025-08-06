local pack = require("src.table.pack")
local getn = require("src.table.getn")

describe("table.pack", function()
    it("packs multiple values", function()
        local t = pack(1, 2, 3)

        for i = 1, 3 do
            assert.equal(i, t[i])
        end
    end)

    it("correctly packs with leading nil", function()
        local t = pack(nil, 2, 3)

        assert.equal(3, getn(t))

        assert.Nil(t[1])
        assert.equal(2, t[2])
        assert.equal(3, t[3])
    end)
    
    it("correctly packs with middle nil", function()
        local t = pack(1, nil, 3)

        assert.equal(3, getn(t))

        assert.equal(1, t[1])
        assert.Nil(t[2])
        assert.equal(3, t[3])
    end)

    it("correctly packs with trailing nil", function()
        local t = pack(1, 2, nil)

        assert.equal(3, getn(t))

        assert.equal(1, t[1])
        assert.equal(2, t[2])
        assert.Nil(t[3])
    end)
end)
