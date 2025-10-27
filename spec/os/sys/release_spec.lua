
local release = require("src.os.sys.release")

describe("os.release", function ()
    it("returns a string", function ()
        assert.string(release())
    end)
end)