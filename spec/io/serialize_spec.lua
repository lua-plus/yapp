local serialize = require("io.serialize")

describe("io.serialize", function()
    describe("serializes", function()
        it("nil", function()
            local ser = serialize(nil)
            assert.equal("nil", ser)
        end)

        it("numbers", function()
            local ser = serialize(-0.9)
            assert.equal("-0.9", ser)
        end)

        it("strings", function()
            local ser = serialize("testing")
            assert.equal("\"testing\"", ser)
        end)

        it("booleans", function()
            local ser = serialize(true)
            assert.equal("true", ser)
        end)

        describe("tables", function()
            it("that are empty", function ()
                local ser = serialize({})

                assert.equal("{}", ser)
            end)

            it("with single values", function()
                local ser = serialize({ "a" })

                assert.equal("{\n\t\"a\"\n}", ser)
            end)

            it("with numeric keys", function()
                local ser = serialize({ "a", "b" })

                assert.equal("{\n\t\"a\",\n\t\"b\"\n}", ser)
            end)

            it("with skipped numeric keys", function()
                local ser = serialize({ "a", nil, "c" })

                assert.equal("{\n\t\"a\",\n\t[3] = \"c\"\n}", ser)
            end)

            it("with name-like string keys", function()
                local ser = serialize({ a = true })

                assert.equal("{\n\ta = true\n}", ser)
            end)

            it("with non-name-like string keys", function()
                local ser = serialize({ ["nil"] = true })

                assert.equal("{\n\t[\"nil\"] = true\n}", ser)
            end)

            it("with non-string keys", function()
                local ser = serialize({ [{}] = {} })

                assert.equal("{\n\t[{}] = {}\n}", ser)
            end)
        end)

        it("functions", function()
            local ser = serialize(function() end)

            assert.match("^%-%-%[%[ %(Serialized function", ser)
        end)
    end)

    describe("refuses to serialize", function()
        it("threads", function()
            assert.error(function()
                serialize(coroutine.create(function()

                end))
            end, "Cannot serialize thread")
        end)

        pending("userdata", function()

        end)

        it("recursive tables", function()
            local recursive = {}
            recursive[1] = recursive

            assert.error(function()
                serialize(recursive)
            end, "Cannot serialize recursive values")
        end)

        it("for self-generating tables", function()
            local mt = {}
            mt.__index = function(t, k)
                return setmetatable({}, mt)
            end

            local init = setmetatable({}, mt)

            assert.error(function()
                serialize(init)
            end, "Cannot serialize deep self-generating tables")
        end)
    end)

    describe("uses global names", function()
        it("when serializing just a global", function()
            local ser = serialize(table.concat)

            assert.equal("table.concat", ser)
        end)

        it("when serializing a global as a child", function()
            local ser = serialize({ table.concat })

            assert.equal("{\n\ttable.concat\n}", ser)
        end)
    end)

    describe("is backwards-compatible with the 'soft' flag", function()
        local recursive = {}
        recursive[1] = recursive

        it("set to false", function()
            assert.error(function()
                serialize(recursive, false)
            end, "Cannot serialize recursive values")
        end)

        it("for recursive table", function()
            local ser = serialize(recursive, true)

            assert.equal("{\n\t(recursive table)\n}", ser)
        end)

        it("for self-generating tables", function()
            local mt = {}
            mt.__index = function(t, k)
                return setmetatable({}, mt)
            end

            local init = setmetatable({}, mt)

            local ser = serialize(init, true)

            assert.equal("(deep self-generating table)", ser)
        end)

        it("for functions", function ()
            local func = function ()
                
            end

            local ser = serialize(func, true)

            assert.match("^%[function", ser)
        end)

        it("for tables with __tostring in metatable", function()
            local clazz = setmetatable({}, {
                __tostring = function()
                    return "Instance of my class"
                end
            })

            local ser = serialize(clazz, true)

            assert.equal("Instance of my class", ser)
        end)
    end)
end)
