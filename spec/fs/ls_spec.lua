local sep = require("src.fs.path.sep")
local with_and_without_lfs = require("spec.helper.with_and_without_lfs")

-- Assumes we're in the yapp directory
describe("fs.ls", function()
    with_and_without_lfs(insulate, function()
        local ls = require("src.fs.ls")

        it("returns hidden files", function()
            local has_hidden = false
            for _, file in ipairs(ls("." .. sep)) do
                if file:match("^%.") then
                    has_hidden = true
                    break
                end
            end

            assert.True(has_hidden)
        end)
    end)
end)
