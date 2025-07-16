local has_lfs = pcall(require, "lfs")

---@param insulate function I couldn't find a way to get busted to play nice
---@param block function
local function with_and_without_lfs(insulate, block)
    insulate("without lfs", function()
        package.preload["lfs"] = function()
            error("lfs disabled for parity checks.")
        end

        package.loaded["lfs"] = nil
        block()
        package.loaded["lfs"] = nil

        package.preload["lfs"] = nil
    end)

    if has_lfs then
        insulate("with lfs", function()
            package.loaded["lfs"] = nil
            block()
            package.loaded["lfs"] = nil
        end)
    end
end

return with_and_without_lfs
