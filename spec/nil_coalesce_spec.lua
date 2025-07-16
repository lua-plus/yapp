local nil_coalesce = require("src.nil_coalesce")

describe("nil_coalesce", function()
    describe("returns non-nil", function()
        describe("with first argument of", function()
            it("1", function()
                assert.Not.Nil(nil_coalesce(1))
            end)
            it("0", function()
                assert.Not.Nil(nil_coalesce(0))
            end)

            it("true", function()
                assert.Not.Nil(nil_coalesce(true))
            end)
            it("false", function()
                assert.Not.Nil(nil_coalesce(false))
            end)

            it("table", function()
                assert.Not.Nil(nil_coalesce({}))
            end)

            it("string", function()
                assert.Not.Nil(nil_coalesce("test"))
            end)

            it("function", function()
                assert.Not.Nil(nil_coalesce(function()

                end))
            end)
        end)

        describe("with second argument of", function()
            it("1", function()
                assert.Not.Nil(nil_coalesce(nil, 1))
            end)
            it("0", function()
                assert.Not.Nil(nil_coalesce(nil, 0))
            end)

            it("true", function()
                assert.Not.Nil(nil_coalesce(nil, true))
            end)
            it("false", function()
                assert.Not.Nil(nil_coalesce(nil, false))
            end)

            it("table", function()
                assert.Not.Nil(nil_coalesce(nil, {}))
            end)

            it("string", function()
                assert.Not.Nil(nil_coalesce(nil, "test"))
            end)

            it("function", function()
                assert.Not.Nil(nil_coalesce(nil, function()

                end))
            end)
        end)

        it("with an unreasonable number of nils", function()
            assert.Not.Nil(nil_coalesce(
                nil, nil, nil, nil, nil, nil, nil, nil,
                ---@diagnostic disable-next-line:redundant-parameter
                nil, nil, nil, nil, nil, nil, nil, nil,
                ---@diagnostic disable-next-line:redundant-parameter
                nil, nil, nil, nil, nil, nil, nil, nil,
                ---@diagnostic disable-next-line:redundant-parameter
                nil, nil, nil, nil, nil, nil, nil, nil,
                ---@diagnostic disable-next-line:redundant-parameter
                nil, nil, nil, nil, nil, nil, nil, nil,
                ---@diagnostic disable-next-line:redundant-parameter
                nil, nil, nil, nil, nil, nil, nil, nil,
                ---@diagnostic disable-next-line:redundant-parameter
                nil, nil, nil, nil, nil, nil, nil, nil,
                ---@diagnostic disable-next-line:redundant-parameter
                nil, nil, nil, nil, nil, nil, nil, nil,
                ---@diagnostic disable-next-line:redundant-parameter
                true
            ))
        end)
    end)
end)
