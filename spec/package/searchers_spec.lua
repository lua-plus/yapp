
local searchers = require("src.package.searchers")

describe("package.searchers", function ()
    it("is a table", function ()
        assert.table(searchers)
    end)
end)