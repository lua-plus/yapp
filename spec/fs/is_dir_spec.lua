local is_dir = require("src.fs.is_dir")
local sep = require("src.fs.path.sep")

-- Assumes we're in the yapp directory
describe("fs.is_dir", function()
    it("returns true for directories", function()
        assert.True(is_dir("." .. sep))
    end)

    it("returns false for files", function ()
        assert.False(is_dir("." .. sep .. "bundle.js"))
    end)

    it("returns false for paths that don't exist", function ()
        assert.False(is_dir("some-arbitrary-nonexistent-path"))
    end)
end)
