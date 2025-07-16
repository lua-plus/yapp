
local is_windows = require("src.os.is_windows")

describe("os.is_windows", function ()
    it("is a boolean", function ()
        assert.boolean(is_windows)
    end)
end)