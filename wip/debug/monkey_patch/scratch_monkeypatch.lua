--[[
for name, value, index in upvalues(fn) do
    print(name)
    local t = type(value)
    if t == "function" then
        debug.upvaluejoin(fn, index, (function ()
            return trap
        end), 1)
    elseif t == "table" then
        debug.upvaluejoin(fn, index, (function ()
            return trap_t
        end), 1)
    end
end

test()
]]

local upvalues  = require("src.debug.fn.upvalues")
local locals    = require("src.debug.fn.locals")
local serialize = require("src.io.serialize")
local globals   = require("src.__internal.globals")

---@param fn function
---@param replacement function
---@param rce_args any[]?
---@return boolean ok
local function monkey_patch_fn(fn, replacement, rce_args)
    -- TODO check if we can even monkey patch by setting upvalues and checking for error
end


local function test()
    return "test"
end

--[[
to use the _IS_MONKEY_PATCH API to allow your function to be arbitrarily monkey-patched, use:

-- Setting it here to lose a global indexing per call is OK,
-- because upvalues
local _IS_MONKEY_PATCH = false

local my_function ()
    if _IS_MONKEY_PATCH then
        -- We don't care about the cost of indexing a global here, and the monkey patch throws trap in _ENV
        return trap()
    end

    -- my complex logic here..
end

what monkey_patch_fn should do is:
    save shallow copy of upvalues

    set air-gapped upvalues (use SelfAwareTable to trap any mt events, and mock functions)
    
    pcall function
    
    if pcall ok and any upvalue mt event occurred then
        (monkey patch by passing no args)
        (hope and pray the function is atomic)
    elseif _ENV._IS_MONKEY_PATCH queried then
        (monkey patch by setting _ENV)
    elseif upvalue named _IS_MONKEY_PATCH queried then
        (monkey patch by setting upvalue)
    else
        return false, "Cannot monkey patch this function."
    end

    setfenv or upvalues or whatever


what trap(...) needs to do:
    caller = debug.getinfo(2).func

    local behavior = monkey_patches[caller]
    if not behavior then
        error("trap() called from non-monkey-patched function")
    end
    get mode + 'ditto' object from behavior

    check -> enable hook
    increase hook refcount

    return the value that the ditto object does
    

In a return hook, overriding the first temporary local results in a changed return value
    get caller
    if not behavior[caller] then
        return
    end

    for name, value, index in upvalues(fn) do
        if name == "(temporary)" then
            debug.setlocal(2, index, "bruh")
            debug.sethook()

            break
        end
    end

    decrease hook refcount

    if hook refcount == 0 then
        debug.sethook(last hook)
    end
]]

local function inner_logic (i)
    local a = 3000 % i
end

local function my_function ()
    for i=1,1000 do
        inner_logic(i)
    end
end

local hooked = {
    [my_function] = true
}

local debug_getinfo = debug.getinfo
local hook = function ()
    local caller = debug_getinfo(2).func
    
    if hooked[caller] then
        -- That's interesting!
        local name = tostring(caller)
    end
end

local t_start = os.clock()

for i=1,1000 do
    my_function()
end

local t_end = os.clock()
local t_plain = t_end - t_start

debug.sethook(hook, "r")

local t_start_= os.clock()

for i=1,1000 do
    my_function()
end

local t_end = os.clock()
local t_hooked = t_end - t_start

print(t_hooked / t_plain)