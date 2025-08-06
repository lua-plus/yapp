local VirtualFileHandle = require("src.class.VirtualFileHandle")
local string_escape     = require("src.string.escape")
local table_map         = require("src.table.map")
local table_keys        = require("src.table.keys")
local pack              = require("src.table.pack")

-- The lyrics to Jockstrap's excellent song "Acid", from
-- https://genius.com/Jockstrap-acid-lyrics
local acid              = [[
Smash a pretty vase of acid
And I'll smash it if you need someone to blame
Pull, pull pull from my neck and my eyes
If it means you don't hurt anymore

Just twice we've spoken since
But what have I to give you - what am I to you?
Gas and blood, and blood, and blood
It is love you are full of
And you know who you hate

I sent you my heart

Since then we've spoken twice
But what if you were to kill me off or worse, yourself?
Stop and wound him; do what you have to do to him
But not me and you, cause it's me and you

I sent you my heart

Brother, mother lover
Brother, mother, lover
Together, lover, brother
]]

--- Get a temporary file handle and its path
---@param name string?
---@param mode Yapp.VirtualFileHandle.Mode?
---@return file* file, string name
local function file_get(name, mode)
    name = name or os.tmpname()

    local f, err = io.open(name, mode)
    if not f then
        error(err)
    end

    return f, name
end

--- Get a file handle for writing, and a file handle for reading
---@return file* write, file* read
local function file_write_and_read()
    local writer, name = file_get(nil, "w")
    local reader = file_get(name, "r")

    return writer, reader
end


--- Dump a string into a temporary file and return a handle that allows read
--- operations on it.
---@param content string
---@return file* file
local function file_dump(content)
    local writer, reader = file_write_and_read()

    writer:write(content)
    writer:flush()
    writer:close()

    return reader
end

---@type string[]
local methods
do
    local ok, ret = pcall(function()
        local f = file_get()

        local methods = table_keys(getmetatable(f).__index)

        f:close()

        return methods
    end)
    if not ok then
        error("Could not construct file method list: " .. ret)
    end
    methods = ret
end

---@param f file*
---@param v Yapp.VirtualFileHandle
---@param method string
---@param ... any
local function check_method_parity(f, v, method, ...)
    local f_rets = pack(pcall(f[method], f, ...))
    local v_rets = pack(pcall(v[method], v, ...))

    assert.equal(f_rets[1], v_rets[1])

    if f_rets[1] then
        for i, f_ret in ipairs(f_rets) do
            local v_ret = v_rets[i]

            -- we get the file* back
            if type(f_ret) == "userdata" then
                assert.table(v_ret)
                assert.Equal(VirtualFileHandle, v_ret.class)
            else
                assert.equal(f_ret, v_ret)
            end
        end
    else
        ---@type string
        local f_err = f_rets[2]

        f_err = f_err:gsub("'%?'", "'" .. method .. "'")
        f_err = string_escape(f_err)

        assert.match(f_err, v_rets[2])
    end
end

describe("class.VirtualFileHandle", function()
    it("provides all file operations", function()
        local v = VirtualFileHandle()
        local f = file_get()

        for _, method_name in ipairs(methods) do
            local v_i = v[method_name]
            local f_i = f[method_name]

            assert.equal(type(f_i), type(v_i))
        end

        f:close()
        v:close()
    end)

    describe("throws file closed errors", function()
        for _, method_name in ipairs(methods) do
            if method_name ~= "close" then
                local f = file_get()
                f:close()

                local ok, f_err = pcall(f[method_name], f)

                if not ok then
                    it("for method " .. method_name, function()
                        local v = VirtualFileHandle()
                        v:close()

                        local ok, v_err = pcall(v[method_name], v)

                        assert.False(ok)
                        assert.match(f_err, v_err)
                    end)
                end
            end
        end
    end)

    describe("fails to write", function()
        local objects = {
            ["nil"]      = { nil },
            ["number"]   = { 1.0 },
            ["string"]   = { "Testing" },
            ["boolean"]  = { true },
            ["table"]    = { {} },
            ["function"] = { function() end },
            ["thread"]   = { coroutine.create(function() end) },
            -- TODO userdata
        }

        local f = file_get()
        local v = VirtualFileHandle()
        for t_name, obj_l in pairs(objects) do
            -- Objects are stored in lists to allow nil value
            local object = obj_l[1]

            local ok, f_err = pcall(f.write, f, object)

            if not ok then
                -- The pcall on f.write seems to 'forget' its method name.
                -- Additionally, I know that f_err is a string by now but lua-LS
                -- doesn't.
                ---@diagnostic disable-next-line
                f_err = f_err:gsub("'%?'", "'write'")
                ---@diagnostic disable-next-line
                f_err = string_escape(f_err)

                it("for " .. t_name .. "s", function()
                    local ok, v_err = pcall(v.write, v, object)

                    assert.False(ok)
                    ---@diagnostic disable-next-line:param-type-mismatch
                    assert.match(f_err, v_err)
                end)
            end
        end

        teardown(function()
            v:close()
            f:close()
        end)
    end)

    describe("checks mode correctly for", function()
        local modes = table_map(
        ---@diagnostic disable-next-line:invisible
            table_keys(VirtualFileHandle._valid_readmodes),
            function(mode)
                return { mode }
            end
        )
        table.insert(modes, { nil })

        for _, mode_l in ipairs(modes) do
            local readmode = mode_l[1]

            describe("mode " .. tostring(readmode), function()
                local f = file_get(nil, readmode)
                local v = VirtualFileHandle():set_mode(readmode)

                it("while reading", function()
                    check_method_parity(f, v, "read")
                end)

                it("while writing nothing", function()
                    check_method_parity(f, v, "write")
                end)

                it("while writing something", function()
                    check_method_parity(f, v, "write", "test")
                end)

                teardown(function()
                    f:close()
                    v:close()
                end)
            end)
        end
    end)

    describe("reads", function()
        it("with no specified mode", function()
            local f = file_dump(acid)
            local v = VirtualFileHandle():set_string(acid)

            local f_read = f:read()
            local v_read = v:read()

            assert.equal(f_read, v_read)
            assert.equal(f:seek(), v:seek())

            f:close()
            v:close()
        end)

        it("refuses mode nil", function()
            local f = file_dump(acid)
            local v = VirtualFileHandle():set_string(acid)

            check_method_parity(f, v, "read", nil)

            f:close()
            v:close()
        end)

        describe("numerals", function()
            local numerals = {
                "not a number",
                "NaN",
                "nan",
                "inf",
                "0",
                "1",
                "1.0",
                "-1.0",
                ".1",
                "-.1",
            }

            for _, numeral in ipairs(numerals) do
                it("with input " .. numeral, function()
                    local f = file_dump(numeral)
                    local v = VirtualFileHandle():set_string(numeral)

                    local f_read = f:read("n")
                    local v_read = v:read("n")

                    assert.equal(f_read, v_read)
                    assert.equal(f:seek(), v:seek())

                    f:close()
                    v:close()
                end)
            end
        end)

        -- I'm skipping "n" here because Acid doesn't contain numerals.
        describe("from a single mode", function()
            local readmodes = { "l", "L", "a", 3 }

            for _, mode in ipairs(readmodes) do
                it("in mode " .. mode, function()
                    local f = file_dump(acid)
                    local v = VirtualFileHandle():set_string(acid)

                    local f_read = f:read(mode)
                    local v_read = v:read(mode)

                    assert.equal(f_read, v_read)
                    assert.equal(f:seek(), v:seek())

                    f:close()
                    v:close()
                end)
            end
        end)

        describe("from two modes", function()
            local readmodes = { "l", "L", "a", 3 }

            for _, mode1 in ipairs(readmodes) do
                for _, mode2 in ipairs(readmodes) do
                    it("in mode " .. mode1 .. " and " .. mode2, function()
                        local f = file_dump(acid)
                        local v = VirtualFileHandle():set_string(acid)

                        local f_read = f:read(mode1, mode2)
                        local v_read = v:read(mode1, mode2)

                        assert.equal(f_read, v_read)
                        assert.equal(f:seek(), v:seek())

                        f:close()
                        v:close()
                    end)
                end
            end
        end)
    end)

    describe("writes", function()
        ---@param ... any
        local function write_parity(...)
            local w, r = file_write_and_read()
            local v = VirtualFileHandle()

            w:write(...)
            v:write(...)

            assert.equal(w:seek(), v:seek())

            w:flush()
            w:close()

            assert.equal(r:read("a"), v:get_string())

            r:close()
            v:close()
        end

        it("a string", function()
            write_parity("Testing")
        end)

        it("strings", function()
            write_parity("Testing", "123")
        end)

        it("a number", function()
            write_parity(123)
        end)

        it("numbers", function()
            write_parity(123, 456)
        end)

        it("strings and numbers", function()
            write_parity("Testing", 123)
        end)

        it("and returns itself", function()
            local v = VirtualFileHandle()

            assert.equal(v, v:write("Testing"))

            v:close()
        end)
    end)

    describe("seeks", function()
        ---@param whence Yapp.VirtualFileHandle.Whence
        ---@param offset integer
        local function test_seek(whence, offset)
            local w, r = file_write_and_read()
            w:write(acid)
            local v = VirtualFileHandle():set_string(acid)
            ---@diagnostic disable-next-line:invisible
            v._position = #acid

            assert.equal(
                w:seek(whence, offset),
                v:seek(whence, offset)
            )

            w:write("Testing")
            v:write("Testing")

            w:flush()
            w:close()

            assert.equal(r:read("a"), v:get_string())

            r:close()
            v:close()
        end

        it("set", function()
            test_seek("set", 12)
        end)

        it("cur", function()
            test_seek("cur", -12)
        end)

        it("end", function()
            test_seek("end", -80)
        end)

        it("past current content", function()
            test_seek("end", 12)
        end)

        it("but not before the start of the file", function()
            local f = file_dump(acid)
            f:seek("set", 0)
            local v = VirtualFileHandle():set_string(acid)

            check_method_parity(f, v, "seek", "set", -1)
            check_method_parity(f, v, "seek", "cur", -1)
            check_method_parity(f, v, "seek", "end", -(#acid + 1))
        end)
    end)
end)
