
local dirname = require("src.fs.path.dirname")

describe("fs.path.dirname", function ()
    it("returns an empty string if given a path", function ()
        local path = "test.lua"

        assert.equal("", dirname(path))
    end)

    it("returns absolute unix directories", function ()
        local path = "/usr/bin/test.lua"

        assert.equal("/usr/bin", dirname(path))
    end)

    it("returns relative unix directories", function ()
        local path = "bin/test.lua"

        assert.equal("bin", dirname(path))
    end)

    it("returns absolute windows directories", function ()
        local path = "C:\\windows\\test.lua"

        assert.equal("C:\\windows", dirname(path))
    end)

    it("returns relative unix directories", function ()
        local path = "bin\\test.lua"

        assert.equal("bin", dirname(path))
    end)
end)