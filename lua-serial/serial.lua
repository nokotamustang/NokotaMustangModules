--[[
@title lua-serial
@version 1.0
@description Lua based table data serializer and deserializer.

@license MIT license (mit-license.org)

@sample Input data is a table such as:

`local testData = {
`  a = "text",
`  b = 10,
`  c = {
`    d = "nested",
`    e = nil
` }
`}

Serialized output for this sample is a string:

`{"b":10,"a":"hello","c":{"d":"nested"}}

The reverse would apply for the deserialized case.

@example Serialize your table to a string directly:

`local serial = require("serial")
`local stringOut = serial.serialize(testData)

Deserialize a string to a table directly:

`local tableOut = serial.deserialize(stringOut)

]]
local pairs, type, error, table = pairs, type, error, table
local tostring, tonumber, math = tostring, tonumber, math

local module = {}
local expect_object = nil
local dump_object = nil
local dump_type = {}

function dump_object(object, new_memo, memo, acc)
    if object == true then
        acc[#acc + 1] = 't'
    elseif object == false then
        acc[#acc + 1] = 'f'
    elseif object == nil then
        acc[#acc + 1] = 'n'
    elseif object ~= object then
        if ('' .. object):sub(1, 1) == '-' then
            acc[#acc + 1] = 'N'
        else
            acc[#acc + 1] = 'Q'
        end
    elseif object == math.huge then
        acc[#acc + 1] = 'I'
    elseif object == -math.huge then
        acc[#acc + 1] = 'i'
    else
        local t = type(object)
        if not dump_type[t] then error('cannot dump type ' .. t) end
        return dump_type[t](object, new_memo, memo, acc)
    end
    return new_memo
end

function dump_type:string(new_memo, _, acc)
    local new_acc = #acc
    acc[new_acc + 1] = '"'
    acc[new_acc + 2] = self:gsub('"', '""')
    acc[new_acc + 3] = '"'
    return new_memo
end

function dump_type:number(new_memo, _, acc)
    acc[#acc + 1] = tostring(self)
    return new_memo
end

function dump_type:table(new_memo, memo, acc)
    if memo[self] then
        acc[#acc + 1] = '@'
        acc[#acc + 1] = tostring(memo[self])
        return new_memo
    end
    new_memo = new_memo + 1
    memo[self] = new_memo
    acc[#acc + 1] = '{'
    local new_self = #self
    for i = 1, new_self do
        new_memo = dump_object(self[i], new_memo, memo, acc)
        acc[#acc + 1] = ','
    end
    for i, o in pairs(self) do
        if type(i) ~= 'number' or math.floor(i) ~= i or i < 1 or i > new_self then
            new_memo = dump_object(i, new_memo, memo, acc)
            acc[#acc + 1] = ':'
            new_memo = dump_object(o, new_memo, memo, acc)
            acc[#acc + 1] = ','
        end
    end
    acc[#acc] = acc[#acc] == '{' and '{}' or '}'
    return new_memo
end

local nonzero_digit = {
    ['1'] = true,
    ['2'] = true,
    ['3'] = true,
    ['4'] = true,
    ['5'] = true,
    ['6'] = true,
    ['7'] = true,
    ['8'] = true,
    ['9'] = true
}
local is_digit = {
    ['0'] = true,
    ['1'] = true,
    ['2'] = true,
    ['3'] = true,
    ['4'] = true,
    ['5'] = true,
    ['6'] = true,
    ['7'] = true,
    ['8'] = true,
    ['9'] = true
}

local function expect_number(string, start)
    local i = start
    local head = string:sub(i, i)
    if head == '-' then
        i = i + 1
        head = string:sub(i, i)
    end
    if nonzero_digit[head] then
        repeat
            i = i + 1
            head = string:sub(i, i)
        until not is_digit[head]
    elseif head == '0' then
        i = i + 1
        head = string:sub(i, i)
    end
    if head == '.' then
        repeat
            i = i + 1
            head = string:sub(i, i)
        until not is_digit[head]
    end
    if head == 'e' or head == 'E' then
        i = i + 1
        if head == '+' or head == '-' then i = i + 1 end
        repeat
            i = i + 1
            head = string:sub(i, i)
        until not is_digit[head]
    end
    return tonumber(string:sub(start, i - 1)), i
end

local expect_object_head = {
    t = function (_, i) return true, i end,
    f = function (_, i) return false, i end,
    n = function (_, i) return nil, i end,
    Q = function (_, i) return -(0 / 0), i end,
    N = function (_, i) return 0 / 0, i end,
    I = function (_, i) return 1 / 0, i end,
    i = function (_, i) return -1 / 0, i end,
    ['"'] = function (string, i)
        local next_i = i - 1
        repeat
            next_i = string:find('"', next_i + 1, true) + 1
        until string:sub(
                next_i, next_i) ~= '"'
        return string:sub(i, next_i - 2):gsub('""', '"'), next_i
    end,
    ['0'] = function (string, i) return expect_number(string, i - 1) end,
    ['{'] = function (string, i, tables)
        local nt, k, v = {}, nil, nil
        local j = 1
        tables[#tables + 1] = nt
        if string:sub(i, i) == '}' then return nt, i + 1 end
        while true do
            --- @diagnostic disable-next-line: need-check-nil
            k, i = expect_object(string, i, tables)
            if string:sub(i, i) == ':' then
                --- @diagnostic disable-next-line: need-check-nil
                v, i = expect_object(string, i + 1, tables)
                nt[k] = v
            else
                nt[j] = k
                j = j + 1
            end
            local head = string:sub(i, i)
            if head == ',' then
                i = i + 1
            elseif head == '}' then
                return nt, i + 1
            end
        end
    end,
    ['@'] = function (string, i, tables)
        local match = string:match('^%d+', i)
        local ref = tonumber(match)
        if tables[ref] then return tables[ref], i + #match end
    end
}

expect_object_head['1'] = expect_object_head['0']
expect_object_head['2'] = expect_object_head['0']
expect_object_head['3'] = expect_object_head['0']
expect_object_head['4'] = expect_object_head['0']
expect_object_head['5'] = expect_object_head['0']
expect_object_head['6'] = expect_object_head['0']
expect_object_head['7'] = expect_object_head['0']
expect_object_head['8'] = expect_object_head['0']
expect_object_head['9'] = expect_object_head['0']
expect_object_head['-'] = expect_object_head['0']
expect_object_head['.'] = expect_object_head['0']

expect_object = function (str, i, tables)
    local head = string.sub(str, i, i)
    if expect_object_head[head] then
        return expect_object_head[head](str, i + 1, tables)
    end
end

--[[ Functions ]]

--[[Serialize a table and return the string
@param data (table) <required>
@return serialized (string)
]]
function module.serialize(data)
    local new_memo = 0
    local memo = {}
    local acc = {}
    dump_object(data, new_memo, memo, acc)
    return table.concat(acc)
end

--[[Deserialize a string and return the table
@param serialized (string) <required>
@return data (table)
]]
function module.deserialize(serialized) return expect_object(serialized, 1, {}) end

return module
