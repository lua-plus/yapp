local pack         = require("src.table.pack")
local unpack       = require("src.table.unpack")
local flatten_2d   = require("src.table.list.flatten_2d")
local traceback    = require("src.debug.traceback")
local defer        = require("src.__internal.defer")
local bindargs     = require("src.class.Promise.bindargs")
local op_index     = require("src.op.index")
local class        = require("lib.30log")

-- TODO list A+ specs that were skipped.

-- TODO FIXME fix traces

-- TODO lua-language-server generics are broken :(
-- cannot instantiate generic class/alias with a generic input.

---@class Yapp.Promise.State
---@field FULFILLED "fulfilled"
---@field REJECTED "rejected"
---@field PENDING "pending"

---@alias Yapp.Promise.Settler<T> fun(...: T)

---@alias Yapp.Promise.Callback<Res, Rej> fun(res: Yapp.Promise.Settler<Res>, rej: Yapp.Promise.Settler<Rej>)
---@alias Yapp.Promise.InternalCallback fun(p: Yapp.Promise)

---@generic R
---@alias Yapp.Promise.Then<T> fun(self: Yapp.Promise, on_fulfilled?: (fun(...: T): `R`), on_rejected?: (fun(...: any): `R`)): Yapp.Promise<R>

---@generic A, B, C, D, Ret
---@alias Yapp.Promise.AsyncFn fun(fn: (fun(a: A, b: B, c: C, d: D): Ret | Yapp.Promise<Ret>)): (fun(a: A, b: B, c: C, d: D): Yapp.Promise<Ret>)

---@generic NewRes
---@class Yapp.Promise<Res> : Log.BaseFunctions, { after: fun(self: Yapp.Promise<Res>, on_res: (fun(value: Res): NewRes?), on_rej: (fun(value: Res): NewRes?)): Yapp.Promise<NewRes> }, { catch: fun(self: Yapp.Promise<Res>, on_rej: fun(value: Res): NewRes?): Yapp.Promise<NewRes> }, { await: fun(self: Yapp.Promise<Res>): Res }
--- Class-wide data
---@field private _instances table
---@field private _autotick boolean
---@field private _then_names table<string, true>
---@field protected _states Yapp.Promise.State
---
--- Instance data
---@field protected _state string
---@field protected _handlers table<string, { [1]: function, [number]: any }[]>
---@field protected _queue {}
---@field protected _callback Yapp.Promise.InternalCallback
---
--- Helper methods
---@field protected _ch_autotick fun(self: self, cb: function, ...: any): boolean
---@field protected _then Yapp.Promise.Then<any>
---@field protected _settle fun(self: self, state: string, ...: any)
---@field protected _get_potential_thenable fun(potential: any): function?
---
--- Methods
---@field after Yapp.Promise.Then<any>
---
--- Class functions
---@field is fun(potential: any): boolean
---@field tick fun(): boolean
---@field async_fn Yapp.Promise.AsyncFn
---@field resolve fun(...: any): Yapp.Promise<any>
---@field reject fun(...: any): Yapp.Promise<nil>
---@field all fun(list: Yapp.Promise<any>[]): Yapp.Promise<any[]>
---
---@overload fun(callback: fun(res: function, rej: function)): Yapp.Promise
local Promise      = class("Yapp.Promise", {
    _autotick = true,
    _then_names = {},

    ---@type Yapp.Promise.State
    _states = {
        FULFILLED = "fulfilled",
        REJECTED = "rejected",
        PENDING = "pending",
    }
})
-- 30log wipes the metatable if this is in the class body.
Promise._instances = setmetatable({}, { __mode = "k" })

---@private
---@param callback Yapp.Promise.Callback<any, any>
---@return Yapp.Promise.InternalCallback
function Promise._wrap_user_callback(callback)
    return function(promise)
        local res = function(...)
            ---@diagnostic disable-next-line:invisible
            promise:_settle(Promise._states.FULFILLED, ...)
        end
        local rej = function(...)
            ---@diagnostic disable-next-line:invisible
            promise:_settle(Promise._states.REJECTED, ...)
        end

        callback(res, rej)
    end
end

---@param callback Yapp.Promise.Callback<any, any>
---@overload fun(self: self)
function Promise:init(callback)
    Promise._instances[self] = true

    self._handlers = {}
    self._queue = {}

    self._state = Promise._states.PENDING

    -- TODO can we make a separate constructor for this?
    if callback then
        local cb = self._wrap_user_callback(callback)

        self:_ch_autotick(cb, self)
    end
end

---@param value any
---@return boolean
function Promise.is(value)
    return Promise._instances[value] or false
end

---@param autotick_enabled boolean
function Promise.set_autotick(autotick_enabled)
    -- if we're currently not auto-ticking
    if not Promise._autotick then
        -- tick until there's no more work to do.
        while Promise.tick() do end
    end

    Promise._autotick = autotick_enabled

    return Promise
end

function Promise.get_autotick()
    return Promise._autotick
end

---@param name string?
---@param ... string
function Promise.set_then_name(name, ...)
    -- Pull old names
    for name in pairs(Promise._then_names) do
        Promise[name] = nil

        Promise._then_names[name] = nil
    end

    local names = pack(name, ...)

    -- Push new names
    for k, name in pairs(names) do
        if k ~= "n" then
            assert(Promise[name] == nil, string.format(
                "%q is a method already exposed by the Promise class.",
                name
            ))

            Promise[name] = Promise._then

            Promise._then_names[name] = true
        end
    end

    return Promise
end

---@protected
function Promise:_then(on_fulfilled, on_rejected)
    ---@diagnostic disable-next-line:missing-parameter
    local p = Promise()

    self:_add_handler(function(state, p, callbacks, ...)
        local idx =
            state == Promise._states.FULFILLED and 1 or
            state == Promise._states.REJECTED and 2 or
            nil

        local cb = callbacks[idx]
        if cb then
            -- TODO xpcall with yapp.debug.traceback
            local ret = pack(pcall(cb, ...))
            local ok = ret[1]

            p:_settle(
                ok and Promise._states.FULFILLED or Promise._states.REJECTED,
                unpack(ret, 2)
            )
        else
            p:_settle(state, ...)
        end
    end, p, { on_fulfilled, on_rejected })

    return p
end

---@protected
---@generic T
---@param cb fun(state: string, ...: T, ...: any): nil
---@param ... T
function Promise:_add_handler(cb, ...)
    local handler = bindargs.create(cb, ...)
    table.insert(self._handlers, handler)

    if self._state ~= Promise._states.PENDING then
        self:_call_handler(handler, self._values)
    end
end

---@private
---@param handler table
---@param values any[]
function Promise:_call_handler(handler, values)
    self:_ch_autotick(bindargs.call_transcend, handler, { self._state }, values)
end

function Promise.tick()
    ---@type Yapp.Promise[]
    local promises = {}
    for p in pairs(Promise._instances) do
        table.insert(promises, p)
    end

    local has_done_work = false
    for _, p in pairs(promises) do
        if p:_tick_self() then
            has_done_work = true
        end
    end

    return has_done_work
end

---@private
function Promise:_tick_self()
    local bound = table.remove(self._queue, 1)

    if not bound then
        return false
    end

    bindargs.call(bound)

    return true
end

---@protected
---@param cb function
---@param ... any
function Promise:_ch_defer(cb, ...)
    if self._autotick then
        defer(cb, ...)
    else
        table.insert(self._queue, bindargs.create(cb, ...))
    end
end

---@protected
---@param cb function
---@param ... any
---@return boolean
function Promise:_ch_autotick(cb, ...)
    if cb then
        if self._autotick then
            cb(...)
        else
            table.insert(self._queue, bindargs.create(cb, ...))
        end
    end

    return self._autotick
end

---@protected
---@param state string
---@param values any[]
function Promise:_set_state(state, values)
    self._state = state
    self._values = values

    local handlers = self._handlers

    for _, handler in ipairs(handlers) do
        self:_call_handler(handler, values)
    end

    if #handlers == 0 and state == Promise._states.REJECTED then
        local trace = traceback(string.format("Uncaught error in promise: %s", tostring(values and values[1])), 3)

        self:_ch_defer(function(handlers, trace)
            -- this check is run again, as a handler could've been added synchronously.
            if #handlers == 0 then
                print(trace)
            end
        end, handlers, trace)
    end
end

--- Check a potential value for .then, and any other names in
--- Promise._then_names
---@protected
---@param potential table|userdata|any
---@return function?
function Promise._get_potential_thenable(potential)
    local t = type(potential)
    if t == "table" or t == "userdata" then
        local names = { "then", unpack(Promise._then_names) }
        for _, name in ipairs(names) do
            -- pcall here because some userdata types might cause errors
            -- with invalid reads (looking at you LGI)
            local ok, ret = pcall(op_index, potential, name)

            if ok and ret and type(ret) == "function" then
                return ret
            end
        end
    end
end

--- Performs the Promise Resolution Procedure for one value
---@protected
---@param state string
---@param value any
---@param control table
---@param index integer
---@return boolean ok
function Promise:_handle_settle_value(state, value, control, index)
    if self == value then
        local err = traceback("Promise may not be a member of" ..
            " its own settled values")

        self:_set_state(Promise._states.REJECTED, { err })
        return false
    end

    if Promise.is(value) then
        local p = value --[[ @as Yapp.Promise ]]

        control.pending = control.pending + 1
        control.has_pendable = true

        p:_add_handler(function(state, self, control, index, ...)
            if state == Promise._states.FULFILLED then
                control.buckets[index] = pack(...)

                control.pending = control.pending - 1

                if control.pending == 0 and self._state == Promise._states.PENDING then
                    local ret = flatten_2d(control.buckets)
                    self:_settle(control.state, unpack(ret))
                end
            elseif state ~= Promise._states.PENDING and self._state == Promise._states.PENDING then
                -- TODO should I flatten stuff here?
                self:_set_state(state, pack(...))
            end
        end, self, control, index)

        return true
    end

    -- try to work with any generic thenable.
    local then_method = self._get_potential_thenable(value)
    if then_method then
        local call_lock = false

        control.pending = control.pending + 1
        control.has_pendable = true

        -- call value:then(ok, err)
        local ok, ret = pcall(then_method, value,
            function(...)
                if call_lock then
                    return
                end
                call_lock = true

                control.buckets[index] = pack(...)

                control.pending = control.pending - 1

                if control.pending == 0 and self._state == Promise._states.PENDING then
                    local ret = flatten_2d(control.buckets)
                    self:_settle(state, unpack(ret))
                end
            end,
            function(err)
                if call_lock then
                    return
                end
                call_lock = true

                self:_set_state(Promise._states.REJECTED, { err })
            end
        )
        if not ok then
            if call_lock then
                return true
            end

            control.pending = control.pending - 1

            self:_set_state(Promise._states.REJECTED, { ret })
            return false
        end

        return true
    end

    -- Insert the value as a primitive in case we need to do async value folding
    control.buckets[index] = { value }

    return true
end

---@protected
---@generic Values
---@param state string
---@param ... Values
function Promise:_settle(state, ...)
    if self._state ~= Promise._states.PENDING then
        error("Promise has already settled")
    end

    local values = pack(...)

    local control = {
        buckets = {},
        pending = 1,
        has_pendable = false,
        state = state
    }

    for i, value in ipairs(values) do
        local ok = self:_handle_settle_value(state, value, control, i)

        if not ok then
            return
        end
    end

    control.pending = control.pending - 1

    if control.pending == 0 then
        local flat = flatten_2d(control.buckets)

        if control.has_pendable then
            self:_settle(state, unpack(flat))
        else
            self:_set_state(state, flat)
        end
    end
end

-- End user API
do
    ---@generic T
    ---@param ... Yapp.Promise<`T`> | `T`
    ---@return Yapp.Promise<T>
    function Promise.resolve(...)
        ---@diagnostic disable-next-line:missing-parameter
        local p = Promise()

        p:_settle(Promise._states.FULFILLED, ...)

        return p
    end

    ---@return Yapp.Promise
    function Promise.reject(...)
        ---@diagnostic disable-next-line:missing-parameter
        local p = Promise()

        p:_settle(Promise._states.REJECTED, ...)

        return p
    end

    function Promise:catch(cb)
        return self:_then(nil, cb)
    end

    ---@param values any[]
    function Promise.all(values)
        return Promise.resolve(unpack(values))
    end

    ---@param values Yapp.Promise[]
    function Promise.race(values)
        for _, v in pairs(values) do
            if not Promise.is(v) then
                error("Promise.race() expects only Promises as arguments", 2)
            end
        end

        ---@diagnostic disable-next-line:missing-parameter
        local p = Promise()

        for _, v in ipairs(values) do
            ---@param p Yapp.Promise
            v:_add_handler(function(state, p, ...)
                ---@diagnostic disable-next-line:invisible
                if p._state == Promise._states.PENDING then
                    ---@diagnostic disable-next-line:invisible
                    p:_settle(state, ...)
                end
            end, p)
        end

        return p
    end

    ---@param values Yapp.Promise[]
    function Promise.any(values)
        for _, v in pairs(values) do
            if not Promise.is(v) then
                error("Promise.any() expects only Promises as arguments", 2)
            end
        end

        ---@diagnostic disable-next-line:missing-parameter
        local p = Promise()

        if #values == 0 then
            p:_settle(Promise._states.REJECTED, "No Promises passed")

            return p
        end

        local control = {
            rejections = #values,
        }

        for _, v in pairs(values) do
            ---@param p Yapp.Promise
            v:_add_handler(function(state, p, control, ...)
                ---@diagnostic disable-next-line:invisible
                if state == Promise._states.FULFILLED and p._state == Promise._states.PENDING then
                    ---@diagnostic disable-next-line:invisible
                    p:_settle(state, ...)
                else
                    control.rejections = control.rejections - 1

                    if control.rejections == 0 then
                        ---@diagnostic disable-next-line:invisible
                        p:_settle(Promise._states.REJECTED, "No promise of any fulfilled")
                    end
                end
            end, p, control)
        end
    end

    --- Table of active coroutines.
    ---@type table<thread, true>
    local Promise_threads = setmetatable({}, { __mode = "k" })

    ---@protected
    ---@generic Args, Ret
    ---@param cb fun(...: Args): Ret
    ---@param promise Yapp.Promise<Ret>
    ---@param ... Args
    function Promise._async_inner(cb, promise, ...)
        -- TODO xpcall here
        local ret_vals = pack(pcall(cb, ...))
        local ok = ret_vals[1]

        if ok then
            promise:_settle(Promise._states.FULFILLED, unpack(ret_vals, 2))
        else
            promise:_settle(Promise._states.REJECTED, unpack(ret_vals, 2))
        end
    end

    ---@generic Args, Ret
    ---@param cb fun(...: Args): Ret
    ---@return fun(...: Args): Yapp.Promise<Ret>
    function Promise.async_fn(cb)
        return function(...)
            ---@diagnostic disable-next-line:missing-parameter
            local promise = Promise()

            local co = coroutine.create(Promise._async_inner)
            Promise_threads[co] = true

            coroutine.resume(co, cb, promise, ...)

            return promise
        end
    end

    ---@generic T
    ---@param self Yapp.Promise<T>
    ---@return T
    function Promise:await()
        local co = coroutine.running()

        assert(
            Promise_threads[co],
            "Promise:await() must be called from within a Promise.async_fn"
        )

        local state = self._state
        local values
        if state == Promise._states.PENDING then
            self:_add_handler(function(state, ...)
                coroutine.resume(co, state, pack(...))
            end)

            local ret_vals = pack(coroutine.yield())
            state = ret_vals[1]
            values = ret_vals[2]
        else
            -- add a no-op handler to hide uncaught error messages
            self:_add_handler(pack)

            values = self._values
        end

        if state == Promise._states.FULFILLED then
            ---@diagnostic disable-next-line:redundant-return-value
            return unpack(values)
        elseif state == Promise._states.REJECTED then
            error(unpack(values))
        else
            error("Unexpected promise state " .. state)
        end
    end
end

Promise.set_then_name("after")

return Promise
