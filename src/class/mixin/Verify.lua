
local get_stringifier = require("src.__internal.class.mixin.get_stringifer")

--- The Verify mixin allows all other mixins to verify their values are OK
local Verify = {
    verification = {}
}

local no_op = function() end

-- TODO FIXME verification only applies when a class is returned
local Verify_mt = {
    __pairs = function(t)
        -- VerifyLazy contains the true logic of verification, lazy-loaded to
        -- avoid mutexes loading the code weight of the verification logic
        local VerifyLazy = require("src.__internal.class.mixin.VerifyLazy")

        VerifyLazy.ace(t)

        return no_op
    end,

    -- TODO do I need a call signature?
    -- The idea is to be able to create 'Verifiers':
    --   Verify(Clonable, { ...properties }) -> crush(Clonable, { [Verify] = { ...properties } })
    --[[
    __call = function (...)
        local argc = select("#", ...)
        if argc == 1 then
            -- we have a key-value mixin table
        elseif argc == 2 then
            -- we have mixin and verification arguments
        end
    end
    ]]

    __tostring = get_stringifier(Verify, "Verify")
}

return setmetatable(Verify, Verify_mt)
