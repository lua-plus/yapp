
local basename = require("src.fs.path.basename")

describe("fs.path.basename", function ()
    it("works well for a path", function ()
        assert.equal("map.lua", basename("src/table/map.lua"))
    end)

    it("works for a trailing directory", function ()
        assert.equal("table", basename("src/table/"))
    end)

    it("works for just a path", function ()
        assert.equal("map.lua", basename("map.lua"))
    end)
end)