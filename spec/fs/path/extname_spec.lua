local extname = require("src.fs.path.extname")

describe("fs.path.extname", function()
    it("gets the extension of just a file", function()
        local path = "test.lua"

        assert.equal(".lua", extname(path))
    end)

    it("gets an empty string for a file with no path", function()
        local path = "test"

        assert.equal("", extname(path))
    end)

    it("gets the extension of a full unix path", function()
        local path = "/usr/bin/test.lua"

        assert.equal(".lua", extname(path))
    end)

    it("gets the extension of a relative unix path", function()
        local path = "bin/test.lua"

        assert.equal(".lua", extname(path))
    end)

    it("gets the extension of a full windows path", function()
        local path = "C:\\windows\\test.lua"

        assert.equal(".lua", extname(path))
    end)

    it("gets the extension of a relative windows path", function()
        local path = "windows\\test.lua"

        assert.equal(".lua", extname(path))
    end)
end)
