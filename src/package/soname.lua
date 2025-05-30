local soname = assert(package.cpath:match("%.[^%.]+$"), "cannot determine the extension C libraries use.")

return soname