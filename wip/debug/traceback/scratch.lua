-- TODO I can't figure out why getinfo responds so weirdly in threads.

local main = coroutine.running()

local co = coroutine.create(function()
    local thr = coroutine.running()
    print(debug.traceback(thr, "from coroutine", 1))

    local index = 1
    while true do
        local info = debug.getinfo(thr, index, 'Sfl')

        if not info then
            break
        end

        print(info.what, info.source, info.linedefined)

        index = index + 1
    end
end)

coroutine.resume(co)


print()
;(function()
    print(debug.traceback("bruh", 1))
end)()
