local filename = require("src.fs.path.filename")

describe("fs.path.filename", function()
    it("gets the file name of just a file", function()
        local path = "test.lua"

        assert.equal("test", filename(path))
    end)

    it("gets the file name for a file with no path", function()
        local path = "test"

        assert.equal("test", filename(path))
    end)

    it("gets the file name of a full unix path", function()
        local path = "/usr/bin/test.lua"

        assert.equal("test", filename(path))
    end)

    it("gets the file name of a relative unix path", function()
        local path = "bin/test.lua"

        assert.equal("test", filename(path))
    end)

    it("gets the file name of a full windows path", function()
        local path = "C:\\windows\\test.lua"

        assert.equal("test", filename(path))
    end)

    it("gets the file name of a relative windows path", function()
        local path = "windows\\test.lua"

        assert.equal("test", filename(path))
    end)
end)
