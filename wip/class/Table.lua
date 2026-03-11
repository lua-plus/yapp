local table_ns = require("src.table")

-- 'chainable'
--  - crush
--  - filter
--  - map

local Table = {}

-- TODO FIXME finish this.

local Table_chainable = {
    crush = table_ns.crush,
    filter = table_ns.filter,
    map = table_ns.map,
}

local Table_mt
Table_mt = {
    __index = function(t, k)
        local chainable = Table_chainable[k]
        if chainable then
            return function(self, ...)
                return Table(chainable(self.entries, ...))
            end
        end

        local method = table_ns[k]
        if method then
            return function (self, ...)
                return method(self.entries, ...)
            end
        end

        return t.entries[k]
    end,
    __call = function(_, t)
        local instance = { entries = t }

        setmetatable(instance, Table_mt)

        return instance
    end,
    __pairs = function(t)
        return pairs(t.entries)
    end,
    __len = function(t)
        return #t.entries
    end,
    __name = "Table"
}

setmetatable(Table, Table_mt)

---@type fun(t: table): Yapp.Types.Table
return Table