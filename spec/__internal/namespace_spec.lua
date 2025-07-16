describe("namespace", function()
    it("loads on demand", function()
        local yapp = require("src")

        local key = nil
        repeat
            key = next(yapp, key)

            if key then
                -- check that we only have keys like _NAME
                assert.match("^_[%d_A-Z]*$", key)
            end
        until not key
    end)

    it("is indexable", function()
        local yapp = require("src")

        assert.Not.Nil(yapp.table)
    end)

    it("implements pairs", function()
        local yapp = require("src")

        local keys = {}
        for k in pairs(yapp) do
            table.insert(keys, k)
        end

        assert.are_not_equal(0, #keys)
    end)
end)
