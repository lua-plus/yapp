
local soname = require("package.soname")

describe("package.soname", function ()
    it("is an extension", function ()
        assert.string(soname)

        assert.match("^%.[%w_]+$", soname)
    end)
end)