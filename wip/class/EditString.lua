
--[[

! THIS FILE IS A MESS !

I wrote what I thought was a decent file* API mock, but turns out to just be a
really well optimized string concatenation/editing API.

]]

local class = require("lib.30log")
local list_to_keys = require("src.table.list.to_keys")
local iter_stack = require("src.iter.stack")

---@class Yapp.EditString.Tree
---@field branches table<integer, string | Yapp.EditString.Tree>
---@field len integer
---@field root Yapp.EditString.Tree?

-- TODO what does this mean? https://en.cppreference.com/w/c/io/fopen
-- File access mode flag "b" can optionally be specified to open a file in binary mode.
-- This flag has no effect on POSIX systems, but on Windows it disables special handling of '\n' and '\x1A'.

---@alias Yapp.EditString.Mode
---| "r" Read mode.
---| "w" Write mode.
---| "a" Append mode.
---| "r+" Update mode, all previous data is preserved.
---| "w+" Update mode, all previous data is erased.
---| "a+" Append update mode, previous data is preserved, writing is only allowed at the end of file.
---| "rb" Read mode. (in binary mode.)
---| "wb" Write mode. (in binary mode.)
---| "ab" Append mode. (in binary mode.)
---| "r+b" Update mode, all previous data is preserved. (in binary mode.)
---| "w+b" Update mode, all previous data is erased. (in binary mode.)
---| "a+b" Append update mode, previous data is preserved, writing is only allowed at the end of file. (in binary mode.)

--- A class that mocks file operations efficiently.
---@class Yapp.EditString : Log.BaseFunctions
---
---@field protected _tree Yapp.EditString.Tree
---@field protected _leaf_key integer[] Which bucket we currently point to
---@field protected _leaf_char integer The char position inside that bucket
---
--- TODO FIXME use this field!!
---@field protected _is_open boolean
---
---@field protected _position integer | nil
---
--- Mode string is stored but we compare against the flags.
---@field protected _mode Yapp.EditString.Mode?
---@field protected _mode_flags ["r"|"w"|nil, boolean] rw_lock, is_binary
---
--- TODO FIXME use this field!!
---@field protected _cached_content string | nil
---
---@overload fun(): Yapp.EditString
local EditString = class("Yapp.EditString")

function EditString:init()
    self._tree = {
        branches = {},
        len = 0,
        root = nil
    }
    self._leaf_key = { 1 }
    self._leaf_char = 0 -- I'm going 0-based because it makes seek() easier.

    self._is_open = true

    -- File position is 0-indexed even under Lua's API
    self._position = 0

    self:set_mode(nil)
end

local EditString_set_mode_valid_mode = list_to_keys({
    "r", "w", "a", "r+", "w+", "a+", "rb", "wb", "ab", "r+b", "w+b", "a+b",
})

---@param mode Yapp.EditString.Mode?
---@return self
function EditString:set_mode(mode)
    assert(
        not mode or EditString_set_mode_valid_mode[mode],
        "invalid mode"
    )

    self._mode = mode

    if mode then
        local rw_lock, is_binary, is_append
        do
            local ty, plus, binary = mode:match("([rwa])(%+?)(b?)")
            is_append = ty == "a"
            is_binary = binary == "b"

            rw_lock =
                plus == "" and (
                    ty == "a" and "w" or ty
                ) or nil
        end

        self._mode_flags = {
            rw_lock, is_binary
        }

        if is_append then
            self:seek("end", 0)
        end
    else
        self._mode_flags = { nil, false }
    end

    return self
end

---@protected
---@return Yapp.EditString.Tree branch
---@return integer leaf_index
function EditString:_cur_branch_get()
    local leaf_key = self._leaf_key

    local branch = self._tree
    for i = 1, #leaf_key - 1 do
        local idx = leaf_key[i]
        branch = branch.branches[idx] --[[ @as Yapp.EditString.Tree ]]
    end

    local index = leaf_key[#leaf_key]

    return branch, index
end

---@protected
---@return string leaf
---@return Yapp.EditString.Tree branch
---@return integer leaf_index
function EditString:_cur_leaf_get()
    local branch, index = self:_cur_branch_get()
    local leaf = branch.branches[index] --[[ @as string ]]

    return leaf, branch, index
end

--- Splits the current leaf into a branch, modifying the leaf_key
---@protected
function EditString:_cur_leaf_split()
    local leaf, branch, index = self:_cur_leaf_get()

    local leaf_char = self._leaf_char

    local a = leaf:sub(1, leaf_char)
    local b = leaf:sub(leaf_char + 1)

    branch.branches[index] = {
        branches = { a, b },
        len = #leaf,
        root = branch,
    }

    table.insert(self._leaf_key, 2)
    self._leaf_char = 0
end

--- Insert a value into the tree optimally.
---@protected
---@param str string
---@param no_advance boolean?
--- TODO FIXME this just isn't how files work apparently. seeking & then writing doesn't insert, it overwrites
function EditString:_cur_leaf_insert(str, no_advance)
    if self._leaf_char ~= 0 then
        self:_cur_leaf_split()
    end

    -- we don't care about the leaf here as we just want the branch and an
    -- insert index.
    local _, branch, index = self:_cur_leaf_get()
    table.insert(branch.branches, index, str)

    local len = #str
    local root = branch
    while root do
        root.len = root.len + len

        root = root.root
    end

    local leaf_key = self._leaf_key
    leaf_key[#leaf_key] = leaf_key[#leaf_key] + 1

    if not no_advance then
        self._position = self._position + len
    end
end

---@return boolean ok
function EditString:close()
    self._is_open = false

    return true
end

---@return boolean ok
function EditString:flush()
    return true
end

---@return fun(): string
function EditString:lines()

end

---@alias Yapp.EditString.Readmode
---| "a" Reads the whole file.
---| "l" Reads the next line skipping the end of line.
---| "L" Reads the next line keeping the end of line.

--- Read from the EditString
---@nodiscard
---@overload fun(count: integer): string Read `count` characters
---@overload fun(readmode: "n"): number Reads a numeral and returns it as a number
---@param read_mode Yapp.EditString.Readmode
---@return string content
function EditString:read(read_mode)
end

---@alias Yapp.EditString.Whence
---| "set" Base is beginning of the file.
---| "cur" Base is current position.
---| "end" Base is end of file.


--- Modify the leaf_key to point to the next branch, or a new insert index.
---@protected
---@param branch Yapp.EditString.Tree
---@param index integer?
---@return string? leaf
---@return Yapp.EditString.Tree branch
---@return integer index
function EditString:_branch_next(branch, index)
    local leaf_key = self._leaf_key

    -- if self._branch_key is empty, index is nil.
    index = index or 0

    local curr = branch.branches[index]
    if type(curr) == "table" then
        index = index - 1
    end

    while true do
        local leaf = branch.branches[index + 1]

        local t_leaf = type(leaf)

        if t_leaf == "string" then
            -- If we already have a valid leaf here, just set the index to one
            -- higher
            index = index + 1
            leaf_key[#leaf_key] = index

            return leaf, branch, index
        elseif t_leaf == "table" then
            -- We can get a 'leaf' that is actually a branch so we act on that.
            branch = leaf --[[ @as Yapp.EditString.Tree ]]
            table.insert(leaf_key, index + 1)
            table.insert(leaf_key, 0) -- will be overwritten

            index = 0
        else
            -- Otherwise, remove the last key and recurse through the next
            table.remove(leaf_key)

            local last = leaf_key[#leaf_key]
            -- we're at root, so set the key to the root + 1 for inserting.
            if not last then
                local tree = self._tree

                index = #tree.branches + 1
                table.insert(leaf_key, index)
                
                return nil, tree, index
            end

            index = last
            -- The existence of last ensures that root exists
            branch = branch.root --[[ @as Yapp.EditString.Tree ]]
        end
    end
end

--- Modify the leaf_key to point to the previous branch
---@protected
---@param branch Yapp.EditString.Tree
---@param index integer
---@return string? leaf
---@return Yapp.EditString.Tree branch
---@return integer index
function EditString:_branch_prev(branch, index)
    local leaf_key = self._leaf_key

    if index == nil then
        return nil, branch, 1
    end

    while true do
        local leaf = branch.branches[index - 1]

        local t_leaf = type(leaf)

        if t_leaf == "string" then
            -- If we already have a valid leaf here, just set the index to one
            -- higher
            index = index - 1
            leaf_key[#leaf_key] = index
            
            return leaf, branch, index
        elseif t_leaf == "table" then
            -- We can get a 'leaf' that is actually a branch so we act on that.
            branch = leaf --[[ @as Yapp.EditString.Tree ]]
            leaf_key[#leaf_key] = index - 1
            table.insert(leaf_key, 0) -- will be overwritten

            index = #branch.branches + 1
        else
            -- Otherwise, remove the last key and recurse through the next
            table.remove(leaf_key)

            local last = leaf_key[#leaf_key]
            -- we've reached root, so set the key to 1 for inserting.
            if not last then
                table.insert(leaf_key, 1)
                return nil, self._tree, 1
            end

            index = last - 1
            -- The existence of last ensures that root exists
            branch = branch.root --[[ @as Yapp.EditString.Tree ]]
        end
    end
end

--- Get and optionally set the position of the EditString cursor
---@overload fun(): integer
---@param whence Yapp.EditString.Whence
---@param offset integer
---@return integer position
function EditString:seek(whence, offset)
    if whence and offset then
        local position = self._position

        local newpos = offset
        -- Make offset absolute
        if whence == "cur" then
            newpos = position + newpos
        elseif whence == "end" then
            newpos = self._tree.len + newpos
        end

        -- check if offset is a special value
        if newpos == 0 then
            self._leaf_key = { }
            self._position = 0
            
            return 0
        elseif newpos < 0 then
            ---@diagnostic disable-next-line
            return nil, "Invalid argument", 22
        elseif newpos >= self._tree.len then
            self._leaf_key = { #self._tree.branches + 1 }
            self._position = newpos
            
            -- return a virtual positions
            return newpos
        end

        -- see how much the cursor position needs to change
        local amt = newpos - position
        
        ---@type string|nil, Yapp.EditString.Tree, integer
        local leaf, branch, index = self:_cur_leaf_get()

        -- Navigate to the correct branch
        while true do
            local abs_amt = math.abs(amt)

            local leaf_len = type(leaf) == "string" and #leaf or 0

            if abs_amt <= leaf_len then
                break
            elseif abs_amt > leaf_len then
                if amt > 0 then
                    amt = amt - leaf_len
                    
                    leaf, branch, index = self:_branch_next(branch, index)
                else
                    amt = amt + leaf_len

                    leaf, branch, index = self:_branch_prev(branch, index)
                end
            end
        end

        if amt > 0 then
            self._leaf_char = amt
        else
            self._leaf_char = #leaf + amt
        end

        self._position = newpos
        return newpos
    end

    return self._position
end

---@alias Yapp.EditString.Bufmode
---| "no" no buffering.
---| "full" full buffering.
---| "line" line buffering.

--- Set vbuf mode. This function currently doesn't do anything.
---@param mode Yapp.EditString.Bufmode
---@param size integer? a size hint.
function EditString:setvbuf(mode, size)
    -- TODO modify tree to match mode? probably wasteful.
end

local null_byte = string.char(0)

--- Write the given content to the EditString
---@param ... string
---@return self
function EditString:write(...)
    if self._mode_flags[1] == "r" then
        ---@diagnostic disable-next-line
        return nil, "Bad file descriptor", 9
    end

    if self._position > self._tree.len then
        local rep = self._position - self._tree.len
        local nulls = string.rep(null_byte, rep)

        self:_cur_leaf_insert(nulls, true)
    end

    for i, value in ipairs({ ... }) do
        local t = type(value)
        -- Lua secretly supports numbers
        if t == "number" then
            value = tostring(value)
            t = "string"
        end

        if t == "string" then
            self:_cur_leaf_insert(value)
        else
            error(string.format(
                "bad argument #%d to 'write', (string expected, got %s)",
                i, t
            ))
        end
    end

    return self
end

---@return string
function EditString:to_string()
    local acc = ""

    for item, push in iter_stack(self._tree) do
        if type(item) == "table" then
            local branches = item.branches
            for i = #branches, 1, -1 do
                local branch = branches[i]
                push(branch)
            end
        else
            acc = acc .. item
        end
    end

    return acc
end

return EditString
