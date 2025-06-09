local get_name = require("src.debug.fn.get_name")

describe("get_name", function()
    it("gets name of function <name>", function()
        local function f()
            print("Hello World!")
        end

        assert.equal("f", get_name(f))
    end)

    it("gets name of <name> = function", function()
        local f = function()
            print("Hello World!")
        end

        assert.equal("f", get_name(f))
    end)

    it("gets name of redefined function", function()
        local f
        f = function()
            print("Hello World!")
        end

        assert.equal("f", get_name(f))
    end)

    it("gets name of later-keyed fields", function()
        local m = {}
        m.f = function()
            print("Hello world!")
        end

        assert.equal("m.f", get_name(m.f))
    end)

    it("gets name of later-keyed fields in the other format", function()
        local m = {}
        function m.f ()
            print("Hello world!")
        end

        assert.equal("m.f", get_name(m.f))
    end)

    it("gets name of class fields", function()
        local m = {}
        function m:f ()
            print("Hello world!")
        end

        assert.equal("m:f", get_name(m.f))
    end)
end)
