local with_and_without_lfs = require("spec.helper.with_and_without_lfs")

describe("fs.cwd", function()
    with_and_without_lfs(insulate, function()
        package.loaded["lfs"] = nil
        local cwd = require("src.fs.cwd")

        it("doesn't throw an error", function()
            cwd()
        end)

        package.loaded["lfs"] = nil
    end)
end)
