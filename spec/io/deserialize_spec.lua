
local deserialize = require("src.io.deserialize")

describe("io.deserialize", function ()
    it("deserializes tables", function ()
        local t = deserialize("{}")

        assert.table(t)
    end)
end)