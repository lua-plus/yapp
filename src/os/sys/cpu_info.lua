local has_cmd    = require("src.os.sys.has_cmd")
local spawn_sync = require("src.os.spawn.sync")
local uname      = require("src.os.sys.uname")

if uname == nil then
    return nil
end

---@param str string
local function assert_parse_cores(str)
    return assert(tonumber(str), "Could not parse number of cores.")
end

---@param str string
local function assert_parse_threads(str)
    return assert(tonumber(str), "Could not parse number of logical processors.")
end

---@class Yapp.Os.CpuInfo
---@field cores integer
---@field threads integer

if uname == "windows" then
    -- Wmic is deprecated as of Win11 (fuckers) so we ask the user to install.
    assert(has_cmd("wmic"), "the wmic tool must be installed.")

    ---@return Yapp.Os.CpuInfo
    local function cpu_info()
        local info = {}

        -- Cores
        local ret = spawn_sync("wmic cpu get NumberOfCores")
        local cores = ret:match("NumberOfCores%s+(%d+)")
        info.cores = assert_parse_cores(cores)

        -- Threads
        local ret = spawn_sync("echo %NUMBER_OF_PROCESSORS%")
        info.threads = assert_parse_threads(ret)

        return info
    end

    return cpu_info
end

---@return Yapp.Os.CpuInfo
local function cpu_info()
    local info = {}

    -- https://stackoverflow.com/a/23378780/19891380
    -- Cores
    local ret
    if uname == "darwin" then
        ret = spawn_sync("sysctl -n hw.logicalcpu_max")
    elseif uname == "linux" then
        ret = spawn_sync("/bin/sh -c \"lscpu -p | grep -Ev '^#' | wc -l\"")
    else
        error("Not able to ascertain core count for this system.")
    end
    info.cores = assert_parse_cores(ret)

    -- getconf is POSIX standard, and _NPROCESSORS_ONLN is unofficial but
    -- supported on Linux, MacOS, FreeBSD
    -- https://stackoverflow.com/a/23569003/19891380
    -- Threads
    local ret = spawn_sync("getconf _NPROCESSORS_ONLN")
    info.threads = assert_parse_threads(ret)


    return info
end

return cpu_info
