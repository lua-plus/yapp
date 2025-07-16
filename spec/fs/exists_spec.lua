local exists = require("src.fs.exists")
local sep = require("src.fs.path.sep")

-- Assumes we're in the yapp directory
describe("fs.exists", function()
    it("returns true for directories", function()
        assert.True(exists("." .. sep))
    end)

    it("returns true for files", function ()
        assert.True(exists("bundle.js"))
    end)

    it("returns false for paths that don't exist", function ()
        assert.False(exists("some-arbitrary-nonexistent-path"))
    end)
end)
