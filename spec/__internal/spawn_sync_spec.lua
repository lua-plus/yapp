
local spawn_sync = require("src.__internal.spawn_sync")

describe("__internal.spawn_sync", function ()
    it("returns the command's output", function ()
        local res = spawn_sync("echo \"test\"")

        assert.equal("test", res)
    end)
end)