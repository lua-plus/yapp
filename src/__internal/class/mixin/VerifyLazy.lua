
---@type table<function, boolean>
local flags = setmetatable({}, { __mode = "k" })

local VerifyLazy = {}

--- This is set during the call to ace()
---@module "src.class.mixin.Verify"
local Verify = nil

---@param class Log.Class
function VerifyLazy.verify(class)
    if not Verify then
        error("Verify was not set during ACE")
    end

    -- Allows either class[Verify] or mixin[Verify] for all mixins on class

    -- TODO custom verifiers per-class

    local verifiers = {}

    for mixin in pairs(class.mixins) do
        local arg = mixin[Verify]
        if arg then
            verifiers[mixin] = arg
        end
    end

    for mixin, arg in pairs(class[Verify] or {}) do
        verifiers[mixin] = arg
    end

    if next(verifiers) == nil then
        error("Expected the class to have a property keyed by the Verify mixin")
    end

    local errors = {}

    for mixin, args in pairs(verifiers) do
        assert(class.mixins[mixin], "Expected class to have mixin")
        
        local verifier = mixin[Verify.verification]
        
        if verifier then
            local ok, err = verifier(class, args)
            if not ok then
                err = err or "Verification error"

                local full_err = ("%s: %s"):format(tostring(mixin), err)

                table.insert(errors, full_err)
            end
        end
    end

    if #errors ~= 0 then
        local err_msg = ("%s failed verification:\n\t%s"):format(class, table.concat(errors, "\n\t"))

        error(err_msg)
    end
end

function VerifyLazy.hook()
    local info = debug.getinfo(3, "Sf")
    if info.what ~= "main" then
        info = debug.getinfo(4, "f")
    end

    if not info then
        return
    end

    local flag = flags[info.func]
    if flag == false then
        flags[info.func] = true
    elseif flag == true then
        local _, verify_class = debug.getlocal(2, 5)

        VerifyLazy.verify(verify_class)

        debug.sethook()
    end
end

function VerifyLazy.ace(Verify_t)
    Verify = Verify_t

    local requirer = debug.getinfo(8, "f").func

    local old_hook = debug.gethook()
    if old_hook then
        -- TODO use the logger module
        print("Verify: existing debug hook. Refusing to overwrite.")
        return
    end

    flags[requirer] = false

    debug.sethook(VerifyLazy.hook, "r")

    return nil
end

return VerifyLazy