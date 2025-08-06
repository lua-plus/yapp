local crush_deep = require("src.table.crush_deep")

describe("table.crush_deep", function()
    it("creates a copy of a table", function()
        local t_in = {
            "a",
            b = "c"
        }

        local t_out = crush_deep(t_in)

        assert.Not.equal(t_in, t_out)

        for k, v in pairs(t_in) do
            assert.equal(v, t_out[k])
        end
    end)

    it("copies sub-tables", function()
        local t_in = {
            "a",
            {
                "b"
            }
        }

        local t_out = crush_deep(t_in)

        assert.Not.equal(t_in, t_out)

        for k, v in pairs(t_in) do
            if type(v) == "table" then
                for k2, v2 in pairs(v) do
                    assert.equal(v2, t_out[k][k2])
                end
            else
                assert.equal(v, t_out[k])
            end
        end
    end)

    describe("uses the last provided value", function()
        it("against primitives", function()
            local t1 = {
                "a",
                "b"
            }

            local t2 = {
                [2] = "c"
            }

            local t_out = crush_deep(t1, t2)

            assert.equal("a", t_out[1])
            assert.equal("c", t_out[2])
        end)

        it("against tables", function()
            local t1 = { "a", {} }
            local t2 = { [2] = "b" }

            local t_out = crush_deep(t1, t2)

            assert.equal("a", t_out[1])
            assert.equal("b", t_out[2])
        end)
    end)

    it("replaces values", function()
        local t1 = { a = true, c = true }
        local t2 = { b = false, c = false }

        local t_out = crush_deep(t1, t2)

        assert.equal(true, t_out.a)
        assert.equal(false, t_out.b)
        assert.equal(false, t_out.c)
    end)

    it("crushes subtables", function()
        local t1 = { { a = true, c = true } }
        local t2 = { { b = false, c = false } }

        local t_out = crush_deep(t1, t2)

        assert.table(t_out[1])
        local inner = t_out[1]

        assert.equal(true, inner.a)
        assert.equal(false, inner.b)
        assert.equal(false, inner.c)
    end)

    it("crushes sub-tables ignoring non-tables", function()
        local t1 = { { a = true, c = true } }
        local t2 = { "bruh" }
        local t3 = { { b = false, c = false } }

        local t_out = crush_deep(t1, t2, t3)

        assert.table(t_out[1])
        local inner = t_out[1]

        assert.equal(true, inner.a)
        assert.equal(false, inner.b)
        assert.equal(false, inner.c)
    end)

    it("crushes sub-sub-tables", function()
        local t1 = { { { a = true, c = true } } }
        local t2 = { { { b = false, c = false } } }

        local t_out = crush_deep(t1, t2)

        assert.table(t_out[1])
        local inner_1 = t_out[1]

        assert.table(inner_1[1])
        local inner_2 = inner_1[1]

        assert.equal(true, inner_2.a)
        assert.equal(false, inner_2.b)
        assert.equal(false, inner_2.c)
    end)
end)
