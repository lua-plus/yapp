local bit = require("src.op.bit")
local bit_compat = require("src.op.bit.impl.bit_compat")

local pow = require("src.math.pow")
local list_to_keys = require("src.table.list.to_keys")

if bit_compat._implementation_name == bit._implementation_name then
    -- cannot test under Lua 5.1 as no native bitop library exists.
    return
end

describe("op.bit.impl.bit_compat", function()
    local neg_ok = list_to_keys({ "band", "bor", "bxor", "bnot" })

    it("has the same fields as native", function()
        for k, v in pairs(bit) do
            if type(v) == "function" then
                local vanilla = bit_compat[k]

                assert.Function(vanilla)
            end
        end

        for k, v in pairs(bit_compat) do
            if type(v) == "function" then
                local native = bit[k]

                assert.Function(native)
            end
        end
    end)

    describe("is generally accurate", function()
        local bounds = pow(2, 4)
        for op_name, native_op in pairs(bit) do
            if type(native_op) == "function" then
                it("with operator " .. op_name, function()
                    local vanilla_op = bit_compat[op_name]

                    -- lower bound for second argument.
                    -- some operators, like left/right shift have undefined behavior
                    -- with a negative operand.
                    -- lua 5.4: bit.bshl(-1, -1) == math.maxinteger
                    -- luajit: bit.bshl(-1, -1) == -2 ^ 31
                    local lower_bound = neg_ok[op_name] and -bounds or 0

                    for i = -lower_bound, bounds do
                        for j = lower_bound, bounds do
                            local native_res = native_op(i, j)
                            local vanilla_res = vanilla_op(i, j)

                            assert.equal(native_res, vanilla_res)
                        end
                    end
                end)
            end
        end
    end)

    describe("handles extreme values", function()
        local very_large_value = pow(2, 32)

        for op_name, native_op in pairs(bit) do
            if type(native_op) == "function" then
                describe("with operator " .. op_name, function()
                    local vanilla_op = bit_compat[op_name]

                    if neg_ok[op_name] then
                        it("and two very small values", function()
                            assert.equal(
                                native_op(-very_large_value, -very_large_value),
                                vanilla_op(-very_large_value, -very_large_value)
                            )
                        end)

                        it("and one large and one small value", function()
                            assert.equal(
                                native_op(very_large_value, -very_large_value),
                                vanilla_op(very_large_value, -very_large_value)
                            )
                        end)

                        it("and one small and one large value", function()
                            assert.equal(
                                native_op(-very_large_value, very_large_value),
                                vanilla_op(-very_large_value, very_large_value)
                            )
                        end)
                    end

                    it("and two very large values", function()
                        assert.equal(
                            native_op(very_large_value, very_large_value),
                            vanilla_op(very_large_value, very_large_value)
                        )
                    end)
                end)
            end
        end
    end)

    it("rounds to 32 bit", function()

    end)
end)
