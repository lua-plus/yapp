---@type ".so" | ".dll" | ".lib" | string
local soname = assert(_G.package.cpath:match("%.[^%.]+$"),
    "cannot determine the extension C libraries use.")

return soname