---@diagnostic disable:invisible

--[[
This test suite shows that the YAPP implementation of Promises holds to the A+
specification. A very small number of sections in the specification have been 
skipped: 
 - Section 2.2.4
 - Section 2.2.5
 - Section 2.3.3.1
 - Section 2.3.3.2

These sections are all marked in the test file, with a "-- SKIPPED" comment
below. Justifications are provided there.
]]

local Promise = require("src.class.Promise")
local crush   = require("src.table.crush")
local unpack  = require("src.table.unpack")
local pack = require("src.table.pack")

--- Give a Promise a handler so a rejection doesn't throw a deferred error.
---@param promise Yapp.Promise
local function promise_mute_errmsg(promise)
    promise:_add_handler(pack)
end

local TICK_MAX = 16
--- If autotick is disabled, tick all Promises.
local function promise_ch_tick()
    if Promise._autotick then
        return
    end

    local ticks_left = TICK_MAX
    while Promise.tick() do
        ticks_left = ticks_left - 1
        if ticks_left == 0 then
            error("Promise ticked over " .. TICK_MAX .. " times")
        end
    end
end

---@param allow_recursion boolean
---@param depth integer
local function promise_suite(allow_recursion, depth)
    if not allow_recursion and depth ~= 0 then
        return
    end

    --[[
    TODO "Full" Promise test suite
      - Monkey patch utils in src/debug (see note.md)
      - test helper that calls tests in the given block without
        describe() and it() defining tests:
            describe = function (_, block) block() end
        general overview:
            early return if caller env._IS_RECURSIVE_SUITE
            get block env
            new_env = {
                ...stubbed functions,
                _IS_RECURSIVE_SUITE = true
            }
            set block env
            call block
            reset block env
      - now, whenever possible, define a test that monkey-patches
        Promise to prove whatever requirement is fulfilled at runtime.
    ]]

    describe("is A+", function()
        -- Section 2.1
        describe("Promise States:", function()
            -- (Body text)
            it("A promise must be in one of three states: pending, fulfilled, or rejected", function()
                local missing_states = {
                    ["pending"] = true,
                    ["fulfilled"] = true,
                    ["rejected"] = true
                }

                local extra_states = {}

                for _, state in pairs(Promise._states) do
                    if missing_states[state] then
                        missing_states[state] = nil
                    else
                        extra_states[state] = true
                    end
                end

                assert.Nil(next(missing_states))
                assert.Nil(next(extra_states))
            end)

            -- Section 2.1.1
            it("When pending, a promise may transition to either the fulfilled or rejected state", function()
                ---@diagnostic disable-next-line:missing-parameter
                local p = Promise()
                assert.equal(Promise._states.PENDING, p._state)

                p:_settle(Promise._states.FULFILLED)
                assert.equal(Promise._states.FULFILLED, p._state)

                ---@diagnostic disable-next-line:missing-parameter
                local p = Promise()
                assert.equal(Promise._states.PENDING, p._state)
                promise_mute_errmsg(p)

                p:_settle(Promise._states.REJECTED)
                assert.equal(Promise._states.REJECTED, p._state)
            end)

            -- Section 2.1.2
            describe("When fulfilled, a promise", function()
                -- Section 2.1.2.1
                it("must not transition to any other state", function()
                    ---@diagnostic disable-next-line:missing-parameter
                    local p = Promise()
                    assert.equal(Promise._states.PENDING, p._state)

                    p:_settle(Promise._states.FULFILLED)
                    assert.equal(Promise._states.FULFILLED, p._state)

                    assert.has_error(function()
                        p:_settle(Promise._states.REJECTED)
                    end, "Promise has already settled")
                    assert.has_error(function()
                        p:_settle(Promise._states.PENDING)
                    end, "Promise has already settled")
                end)

                -- Section 2.1.2.2
                it("must have a value, which must not change", function()
                    ---@diagnostic disable-next-line:missing-parameter
                    local p = Promise()
                    assert.equal(Promise._states.PENDING, p._state)

                    p:_settle(Promise._states.FULFILLED, {})
                    local val_1 = p._values[1]

                    assert.has_error(function()
                        p:_settle(Promise._states.REJECTED)
                    end, "Promise has already settled")

                    assert.equal(val_1, p._values[1])
                end)
            end)

            -- Section 2.1.3
            describe("When rejected, a promise", function()
                -- Section 2.1.3.1
                it("must not transition to any other state", function()
                    ---@diagnostic disable-next-line:missing-parameter
                    local p = Promise()
                    assert.equal(Promise._states.PENDING, p._state)
                    promise_mute_errmsg(p)

                    p:_settle(Promise._states.REJECTED)
                    assert.equal(Promise._states.REJECTED, p._state)

                    assert.has_error(function()
                        p:_settle(Promise._states.FULFILLED)
                    end, "Promise has already settled")
                    assert.has_error(function()
                        p:_settle(Promise._states.PENDING)
                    end, "Promise has already settled")
                end)

                -- Section 2.1.3.2
                it("must have a reason, which must not change", function()
                    ---@diagnostic disable-next-line:missing-parameter
                    local p = Promise()
                    assert.equal(Promise._states.PENDING, p._state)
                    promise_mute_errmsg(p)

                    p:_settle(Promise._states.REJECTED, {})
                    local val_1 = p._values[1]

                    assert.has_error(function()
                        p:_settle(Promise._states.REJECTED)
                    end, "Promise has already settled")

                    assert.equal(val_1, p._values[1])
                end)
            end)
        end)

        -- Section 2.2
        describe("The then method:", function()
            it("A promise must provide a then method to access its current " ..
                "or eventual value or reason", function()
                    for name in pairs(Promise._then_names) do
                        assert.equal(Promise._then, Promise[name])
                    end
                end)

            -- Section 2.2.1
            describe("both onFulfilled and onRejected are optional arguments", function()
                it("passes fulfillment through", function()
                    ---@diagnostic disable-next-line:missing-parameter
                    local p = Promise()

                    local then_values = {}
                    p:_then():_then(function(...)
                        then_values = { ... }

                        return nil
                    end)

                    local val = "Hello World!"
                    p:_settle(Promise._states.FULFILLED, val)

                    promise_ch_tick()

                    assert.equal(val, then_values[1])
                end)

                it("passes rejection through", function()
                    ---@diagnostic disable-next-line:missing-parameter
                    local p = Promise()

                    local then_values = {}
                    p:_then():_then(nil, function(...)
                        then_values = { ... }

                        return nil
                    end)

                    local val = "Hello World!"
                    p:_settle(Promise._states.REJECTED, val)

                    promise_ch_tick()

                    assert.equal(val, then_values[1])
                end)
            end)

            -- Section 2.2.2
            describe("if onFulfilled is a function", function()
                -- Section 2.2.2.1
                it("must be called after promise is fulfilled, with " ..
                    "promise's value as its first argument",
                    function()
                        local msg = "Hello World!"
                        local out = nil

                        ---@diagnostic disable-next-line:missing-parameter
                        local p = Promise()
                        p:_then(function(input)
                            out = input

                            return nil
                        end)
                        p:_settle(Promise._states.FULFILLED, msg)

                        promise_ch_tick()

                        assert.equal(msg, out)
                    end)

                -- Section 2.2.2.2
                it("must not be called before promise is fulfilled", function()
                    local called = false

                    ---@diagnostic disable-next-line:missing-parameter
                    local p = Promise()
                    p:_then(function()
                        called = true

                        return nil
                    end)
                    assert.False(called)
                    p:_settle(Promise._states.FULFILLED)

                    promise_ch_tick()

                    assert.True(called)
                end)

                -- Section 2.2.2.3
                it("must not be called more than once", function()
                    local called = 0

                    ---@diagnostic disable-next-line:missing-parameter
                    local p = Promise()
                    p:_then(function()
                        called = called + 1

                        return nil
                    end)
                    assert.equal(0, called)
                    p:_settle(Promise._states.FULFILLED)
                    assert.has_error(function()
                        p:_settle(Promise._states.FULFILLED)
                    end)

                    promise_ch_tick()

                    assert.equal(1, called)
                end)
            end)

            -- Section 2.2.3
            describe("if onRejected is a function", function()
                -- Section 2.2.3.1
                it("must be called after promise is rejected, with promise's " ..
                    "reason as its first argument",
                    function()
                        local msg = "Hello World!"
                        local out = nil

                        ---@diagnostic disable-next-line:missing-parameter
                        local p = Promise()
                        p:_then(nil, function(input)
                            out = input

                            return nil
                        end)
                        promise_mute_errmsg(p)

                        p:_settle(Promise._states.REJECTED, msg)

                        promise_ch_tick()

                        assert.equal(msg, out)
                    end)

                -- Section 2.2.3.2
                it("must not be called before promise is rejected", function()
                    local called = false

                    ---@diagnostic disable-next-line:missing-parameter
                    local p = Promise()
                    p:_then(nil, function()
                        called = true

                        return nil
                    end)
                    promise_mute_errmsg(p)

                    assert.False(called)
                    p:_settle(Promise._states.REJECTED)

                    promise_ch_tick()

                    assert.True(called)
                end)

                it("must not be called more than once", function()
                    local called = 0

                    ---@diagnostic disable-next-line:missing-parameter
                    local p = Promise()
                    p:_then(nil, function()
                        called = called + 1

                        return nil
                    end)
                    assert.equal(0, called)
                    p:_settle(Promise._states.REJECTED)
                    assert.has_error(function()
                        p:_settle(Promise._states.REJECTED)
                    end)

                    promise_ch_tick()

                    assert.equal(1, called)
                end)
            end)

            -- Section 2.2.4 - skipped due to Lua not having a native event loop
            -- SKIPPED

            -- Section 2.2.5 - skipped because `this` does not exist in Lua
            -- SKIPPED

            -- Section 2.2.6
            describe("may be called multiple times on the same promise", function()
                -- Section 2.2.6.1
                it(
                    "when promise is fulfilled, all respective onFulfilled " ..
                    "callbacks execute in the order of their originating calls to then",
                    function()
                        ---@diagnostic disable-next-line:missing-parameter
                        local p = Promise()

                        local calls = {}

                        for i = 1, 10 do
                            p:_then(function()
                                table.insert(calls, i)
                                return nil
                            end)
                        end

                        p:_settle(Promise._states.FULFILLED)

                        promise_ch_tick()

                        for i = 1, 10 do
                            assert.equal(i, calls[i])
                        end
                    end)

                it(
                    "when promise is rejected, all respective onRejected " ..
                    "callbacks execute in the order of their originating calls to then",
                    function()
                        ---@diagnostic disable-next-line:missing-parameter
                        local p = Promise()
                        promise_mute_errmsg(p)

                        local calls = {}

                        for i = 1, 10 do
                            p:_then(nil, function()
                                table.insert(calls, i)
                                return nil
                            end)
                        end

                        p:_settle(Promise._states.REJECTED)

                        promise_ch_tick()

                        for i = 1, 10 do
                            assert.equal(i, calls[i])
                        end
                    end)
            end)

            -- Section 2.2.7
            describe("must return a promise", function()
                -- Section 2.2.7.1
                it("if either onFulfilled or onRejected returns a value x, "
                    .. "run the Promise Resolution Procedure [[Resolve]](promise2, x)",
                    function()
                        local msg = "Hello World!"
                        local inner = Promise.resolve(msg)

                        ---@diagnostic disable-next-line:missing-parameter
                        local outer = Promise()

                        local ret = "Unset"
                        outer
                            :_then(function()
                                return inner
                            end)
                            :_then(function(value)
                                ret = value
                                return nil
                            end)

                        outer:_settle(Promise._states.FULFILLED)

                        promise_ch_tick()

                        assert.equal(msg, ret)
                    end)

                -- Section 2.2.7.2
                it("if either onFulfilled or onRejected throws an error e, " ..
                    "promise2 must be rejected with e as the reason", function()
                        local msg = "An error!"

                        -- Fulfilled
                        ---@diagnostic disable-next-line:missing-parameter
                        local p1 = Promise()

                        local p2 = p1:_then(function()
                            error(msg)
                        end)
                        promise_mute_errmsg(p2)

                        p1:_settle(Promise._states.FULFILLED)

                        promise_ch_tick()

                        assert.equal(Promise._states.REJECTED, p2._state)
                        -- We don't get exact errors because a location gets prepended.
                        assert.match(msg .. "$", p2._values[1])

                        -- Rejected
                        ---@diagnostic disable-next-line:missing-parameter
                        local p1 = Promise()

                        local p2 = p1:_then(nil, function()
                            error(msg)
                        end)
                        promise_mute_errmsg(p2)

                        p1:_settle(Promise._states.REJECTED)

                        promise_ch_tick()

                        assert.equal(Promise._states.REJECTED, p2._state)
                        -- We don't get exact errors because a location gets prepended.
                        assert.match(msg .. "$", p2._values[1])
                    end)

                -- Section 2.2.7.3
                it("if onFulfilled is not a function and promise1 is " ..
                    "fulfilled, promise2 must be fulfilled with the same " ..
                    "value as promise1", function()
                        ---@diagnostic disable-next-line:missing-parameter
                        local p1 = Promise()

                        local p2 = p1:_then()

                        local msg = "Hello World!"
                        p1:_settle(Promise._states.FULFILLED, msg)

                        promise_ch_tick()

                        assert.equal(p1._state, p2._state)
                        assert.equal(p1._values[1], p2._values[1])
                    end)

                -- Section 2.2.7.4
                it("if onRejected is not a function and promise1 is " ..
                    "rejected, promise2 must be rejected with the same " ..
                    "reason as promise1", function()
                        ---@diagnostic disable-next-line:missing-parameter
                        local p1 = Promise()

                        local p2 = p1:_then()
                        promise_mute_errmsg(p2)

                        local msg = "Hello World!"
                        p1:_settle(Promise._states.REJECTED, msg)

                        promise_ch_tick()

                        assert.equal(p1._state, p2._state)
                        assert.equal(p1._values[1], p2._values[1])
                    end)
            end)
        end)

        -- Section 2.3
        describe("The Promise Resolution Procedure:", function()
            -- Section 2.3.1
            it("if promise and x refer to the same object, reject promise", function()
                ---@diagnostic disable-next-line:missing-parameter
                local p = Promise()
                promise_mute_errmsg(p)

                p:_settle(Promise._states.FULFILLED, p)

                assert.equal(Promise._states.REJECTED, p._state)
            end)

            -- Section 2.3.2
            describe("if x is a promise, adopt its state:", function()
                -- Section 2.3.2.1
                it("if x is pending, promise must remain pending until x " ..
                    "is fulfilled or rejected", function()
                        ---@diagnostic disable-next-line:missing-parameter
                        local x = Promise()

                        ---@diagnostic disable-next-line:missing-parameter
                        local promise = Promise()

                        promise:_settle(Promise._states.FULFILLED, x)

                        assert.equal(Promise._states.PENDING, promise._state)
                    end)

                -- Section 2.3.2.2
                it("when x is fulfilled, fulfill promise with the same " ..
                    "value", function()
                        ---@diagnostic disable-next-line:missing-parameter
                        local x = Promise()

                        ---@diagnostic disable-next-line:missing-parameter
                        local promise = Promise()

                        promise:_settle(Promise._states.FULFILLED, x)

                        assert.equal(Promise._states.PENDING, promise._state)

                        local msg = "Hello World!"
                        x:_settle(Promise._states.FULFILLED, msg)

                        promise_ch_tick()

                        assert.equal(x._state, promise._state)
                        assert.equal(x._values[1], promise._values[1])
                    end)

                -- Section 2.3.2.3
                it("when x is rejected, reject promise with the same " ..
                    "value", function()
                        ---@diagnostic disable-next-line:missing-parameter
                        local x = Promise()
                        promise_mute_errmsg(x)

                        ---@diagnostic disable-next-line:missing-parameter
                        local promise = Promise()
                        promise_mute_errmsg(promise)

                        promise:_settle(Promise._states.FULFILLED, x)

                        assert.equal(Promise._states.PENDING, promise._state)

                        local msg = "Hello World!"
                        x:_settle(Promise._states.REJECTED, msg)

                        promise_ch_tick()

                        assert.equal(x._state, promise._state)
                        assert.equal(x._values[1], promise._values[1])
                    end)

                -- TODO addendum - lua has tuples so run tests for multiple Promises
            end)

            -- Section 2.3.3
            describe("if x is a table or userdata:", function()
                local mock_promise_err = "Evil mock_promise"

                ---@param val any
                ---@param ok boolean
                ---@param options table<"busy"|"evil"|"evil_late", true>?
                local function mock_promise(val, ok, options)
                    return {
                        ["then"] = function(self, on_res, on_rej)
                            options = options or {}

                            if options.evil then
                                error(mock_promise_err)
                            end

                            if ok then
                                on_res(val)
                            else
                                on_rej(val)
                            end

                            if options.busy then
                                on_rej("BRUH")

                                on_res("BRUH")
                            end

                            if options.evil_late then
                                error("Late evil mock_promise")
                            end
                        end
                    }
                end

                -- Section 2.3.3.1 - skipped because it's just 'let then be x.then'
                -- SKIPPED

                -- Section 2.3.3.2 - skipped because userdata indexing commonly results in errors.
                -- SKIPPED

                -- Section 2.3.3.3
                describe("if x.then is a function, call it with x as self, " ..
                    "second argument resolvePromise, and third argument " ..
                    "rejectPromise, where:", function()
                        -- Section 2.3.3.3.1
                        it("when resolvePromise is called with a " ..
                            "value y, run [[Resolve]](promise, y)", function()
                                local msg = "Hello World!"
                                local y = Promise.resolve(msg)
                                local x = mock_promise(y, true)

                                ---@diagnostic disable-next-line:missing-parameter
                                local promise = Promise()
                                promise:_settle(Promise._states.FULFILLED, x)

                                promise_ch_tick()

                                assert.equal(Promise._states.FULFILLED, promise._state)
                                assert.equal(msg, promise._values[1])
                            end)

                        -- Section 2.3.3.3.2
                        it("when rejectPromise is called with a " ..
                            "reason r, reject promise with r", function()
                                local msg = "Hello World!"
                                local x = mock_promise(msg, false)

                                ---@diagnostic disable-next-line:missing-parameter
                                local promise = Promise()
                                promise_mute_errmsg(promise)
                                promise:_settle(Promise._states.FULFILLED, x)

                                promise_ch_tick()

                                assert.equal(Promise._states.REJECTED, promise._state)
                                assert.equal(msg, promise._values[1])
                            end)

                        -- Section 2.3.3.3.3
                        it("if both resolvePromise and rejectPromise are " ..
                            "called, or multiple calls to the same argument " ..
                            "are made, the first call takes precedence, and " ..
                            "any further calls are ignored.", function()
                                local msg = "Hello World!"
                                local y = Promise.resolve(msg)
                                -- busy mock_promise does this for us
                                local x = mock_promise(y, true, {
                                    busy = true
                                })

                                ---@diagnostic disable-next-line:missing-parameter
                                local promise = Promise()
                                promise:_settle(Promise._states.FULFILLED, x)

                                promise_ch_tick()

                                assert.equal(Promise._states.FULFILLED, promise._state)
                                assert.equal(msg, promise._values[1])
                            end)

                        -- Section 2.3.3.3.4
                        describe("If calling then throws an error:", function()
                            -- Section 2.3.3.3.4.1
                            it("if resolvePromise or rejectPromise have " ..
                                "been called, ignore it.", function()
                                    local msg = "Hello World!"
                                    local x = mock_promise(msg, true, {
                                        evil_late = true
                                    })

                                    ---@diagnostic disable-next-line:missing-parameter
                                    local promise = Promise()
                                    promise_mute_errmsg(promise)
                                    promise:_settle(Promise._states.FULFILLED, x)

                                    promise_ch_tick()

                                    assert.equal(Promise._states.FULFILLED, promise._state)
                                    assert.equal(msg, promise._values[1])
                                end)

                            -- Section 2.3.3.3.4.2
                            it("otherwise, reject promise with e as the reason", function()
                                local x = mock_promise(nil, true, {
                                    evil = true
                                })

                                ---@diagnostic disable-next-line:missing-parameter
                                local promise = Promise()
                                promise_mute_errmsg(promise)
                                promise:_settle(Promise._states.FULFILLED, x)

                                promise_ch_tick()

                                assert.equal(Promise._states.REJECTED, promise._state)
                                assert.match(mock_promise_err .. "$", promise._values[1])
                            end)
                        end)
                    end)

                -- Section 2.3.3.4
                describe("if x.then is not a function, fulfill promise " ..
                    "with x", function()
                        local x = { ["then"] = true }

                        ---@diagnostic disable-next-line:missing-parameter
                        local promise = Promise()
                        promise:_settle(Promise._states.FULFILLED, x)

                        assert.equal(Promise._states.FULFILLED, promise._state)
                        assert.equal(x, promise._values[1])
                    end)
            end)

            -- Section 2.3.4
            it("if x is not a table or userdata, fulfill promise with x", function()
                local x = true

                ---@diagnostic disable-next-line:missing-parameter
                local promise = Promise()
                promise:_settle(Promise._states.FULFILLED, x)

                assert.equal(Promise._states.FULFILLED, promise._state)
                assert.equal(x, promise._values[1])
            end)
        end)
    end)

    describe("API", function()
        describe("Promise.resolve()", function()
            it("produces a fulfilled Promise", function()
                local p = Promise.resolve()

                assert.equal(Promise._states.FULFILLED, p._state)
            end)

            it("produces a Promise with the given values", function()
                local p = Promise.resolve(1, 2)

                assert.equal(Promise._states.FULFILLED, p._state)
                assert.equal(1, p._values[1])
                assert.equal(2, p._values[2])
            end)

            it("fulfills from pending sub-Promise", function()
                ---@diagnostic disable-next-line:missing-parameter
                local inner = Promise()

                local p = Promise.resolve(inner)

                inner:_settle(Promise._states.FULFILLED, 1)

                promise_ch_tick()

                assert.equal(Promise._states.FULFILLED, p._state)
                assert.equal(1, p._values[1])
            end)

            it("rejects from pending sub-Promise", function()
                ---@diagnostic disable-next-line:missing-parameter
                local inner = Promise()

                local p = Promise.resolve(inner)
                promise_mute_errmsg(p)

                inner:_settle(Promise._states.REJECTED, 1)

                promise_ch_tick()

                assert.equal(Promise._states.REJECTED, p._state)
                assert.equal(1, p._values[1])
            end)

            it("fulfills from settled sub-Promise", function()
                local inner = Promise.resolve(1)
                local p = Promise.resolve(inner)

                promise_ch_tick()

                assert.equal(Promise._states.FULFILLED, p._state)
                assert.equal(1, p._values[1])
            end)
        end)

        describe("Promise.reject()", function()
            it("produces a rejected Promise", function()
                local p = Promise.reject()
                promise_mute_errmsg(p)

                assert.equal(Promise._states.REJECTED, p._state)
            end)

            it("produces a Promise with the given values", function()
                local p = Promise.reject(1, 2)
                promise_mute_errmsg(p)

                assert.equal(Promise._states.REJECTED, p._state)
                assert.equal(1, p._values[1])
                assert.equal(2, p._values[2])
            end)

            it("rejects from pending to-be-fulfilled sub-Promise", function()
                ---@diagnostic disable-next-line:missing-parameter
                local inner = Promise()

                local p = Promise.reject(inner)
                promise_mute_errmsg(p)

                inner:_settle(Promise._states.FULFILLED, 1)

                promise_ch_tick()

                assert.equal(Promise._states.REJECTED, p._state)
                assert.equal(1, p._values[1])
            end)

            it("rejects from pending to-be-rejected sub-Promise", function()
                ---@diagnostic disable-next-line:missing-parameter
                local inner = Promise()

                local p = Promise.reject(inner)
                promise_mute_errmsg(p)

                inner:_settle(Promise._states.REJECTED, 1)

                promise_ch_tick()

                assert.equal(Promise._states.REJECTED, p._state)
                assert.equal(1, p._values[1])
            end)

            it("rejects from settled sub-Promise", function()
                local inner = Promise.resolve(1)
                local p = Promise.reject(inner)
                promise_mute_errmsg(p)

                promise_ch_tick()

                assert.equal(Promise._states.REJECTED, p._state)
                assert.equal(1, p._values[1])
            end)
        end)

        describe("Promise:catch()", function()
            it("captures error values from a rejected Promise", function()
                local p = Promise.reject(1, 2)
                    :catch(function(a, b)
                        return a, b
                    end)

                promise_ch_tick()

                assert.equal(Promise._states.FULFILLED, p._state)
                assert.equal(1, p._values[1])
                assert.equal(2, p._values[2])
            end)
        end)

        -- Promise.all() gets no tests because it's secretly Promise.resolve()

        -- TODO FIXME Promise.race()

        -- TODO FIXME Promise.any()

        describe("async-await", function()
            it("disallows await outside of Promise.async_fn", function()
                assert.has_error(function()
                    Promise.resolve("Testing"):await()
                end)
            end)

            it("returns promise values through await", function()
                local get_promise = Promise.async_fn(function()
                    local a, b = Promise.resolve(1, 2):await()

                    ---@diagnostic disable-next-line:redundant-return-value
                    return a, b
                end)

                local p = get_promise()

                assert.equal(Promise._states.FULFILLED, p._state)
                assert.equal(1, p._values[1])
                assert.equal(2, p._values[2])
            end)

            it("throws errors through await", function()
                local err = "Screw you!"

                local get_promise = Promise.async_fn(function()
                    Promise.reject(err):await()

                    local a, b = Promise.resolve(1, 2):await()

                    ---@diagnostic disable-next-line:redundant-return-value
                    return a, b
                end)

                local p = get_promise()
                promise_mute_errmsg(p)

                promise_ch_tick()

                assert.equal(Promise._states.REJECTED, p._state)
                assert.match(err .. "$", p._values[1])
            end)
        end)
    end)
end

describe("class.Promise", function()
    describe("autotick=true", function()
        promise_suite(false, 0)
    end)

    describe("autotick=false", function()
        before_each(function()
            Promise.set_autotick(false)
        end)

        promise_suite(false, 0)
    end)

    -- Make sure Promise doesn't rely on its flexible API
    describe("no then names", function()
        -- save a copy
        local then_names = crush(Promise._then_names)

        before_each(function()
            Promise.set_then_name()
        end)

        promise_suite(false, 0)

        Promise.set_then_name(unpack(then_names))
    end)
end)

-- TODO test with .set_then_name
