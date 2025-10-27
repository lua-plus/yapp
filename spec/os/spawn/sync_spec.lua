
local spawn_sync = require("src.os.spawn.sync")

describe("os.spawn.sync", function ()
    it("returns the command's output", function ()
        local res = spawn_sync("echo \"test\"")

        assert.equal("test", res)
    end)
end)