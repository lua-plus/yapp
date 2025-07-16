local join = require("src.fs.path.join")
local sep = require("src.fs.path.sep")

describe("fs.path.join", function()
    describe("ignores", function()
        describe("leading", function()
            it("nil", function()
                local p = join(nil, "testing")

                assert.equal("testing", p)
            end)

            it("empty string", function()
                local p = join("", "testing")

                assert.equal("testing", p)
            end)
        end)

        describe("trailing", function()
            it("nil", function()
                local p = join("testing", nil)

                assert.equal("testing", p)
            end)

            it("empty string", function()
                local p = join("testing", "")

                assert.equal("testing", p)
            end)
        end)

        describe("in-between", function()
            it("nil", function()
                local p = join("testing", nil, "testing")

                assert.equal("testing" .. sep .. "testing", p)
            end)

            it("empty string", function()
                local p = join("testing", "", "testing")

                assert.equal("testing" .. sep .. "testing", p)
            end)
        end)
    end)
end)
