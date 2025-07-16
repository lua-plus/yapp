
local replace = require("src.fs.path.replace")
local is_windows = require("src.os.is_windows")

describe("fs.path.replace", function ()
    it("modifies the path for the system OS", function ()
        if is_windows then
            assert.equal(
                "some\\path\\name",
                replace("some/path/name")
            )
        else
            assert.equal(
                "some/path/name",
                replace("some\\path\\name")
            )
        end
    end)
end)