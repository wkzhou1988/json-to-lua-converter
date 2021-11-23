-- input Global JsonString
-- output Global LuaString

local json = require("rapidjson")
local json_null = json.null
local TAB = "    "
local FormatCode = true

local function table_length(table)
	local count = 0
	for k, v in pairs(table) do
		count = count + 1
	end
	return count
end

local function is_array(table)
	if type(table) ~= 'table' then return false end
	return #table == table_length(table)
end

local function add_buffer(buffer, str, indent)
	if FormatCode then
		table.insert(buffer, indent .. str)
	else
		table.insert(buffer, str)
	end
end

local function get_table_sorted_keys(tab)
	local ret = {}
	for k, v in pairs(tab) do
		table.insert(ret, k)
	end
	table.sort(ret, function(v1, v2)
		return tostring(v1) < tostring(v2)
	end)
	return ret
end

local function traverse(key, value, buffer, is_array_value, indent)

	local keyStr
	if is_array_value then
		keyStr = ""
	elseif type(key) == 'number' or tonumber(key) ~= nil then
		keyStr = string.format("[%d]=", key)
	else
		keyStr = tostring(key) .. "="
	end

	local value_type = type(value)
	if value == json_null then
		-- do not export nil entries
		--add_buffer(buffer, keyStr .. "nil,", indent)
	elseif value_type == "string" then
		add_buffer(buffer, string.format('%s"%s",', keyStr, value), indent)
	elseif  value_type == "number" or value_type == "boolean" or value == "nil" then
		add_buffer(buffer, string.format('%s%s,', keyStr, value), indent)
	elseif value_type == "table" then
		local length = table_length(value)
		if length == 0 then
			-- do not export empty table
			--add_buffer(buffer, string.format("%snil,", keyStr), indent)
		else
			if not is_array_value then
				add_buffer(buffer, string.format("%s", keyStr), indent)
			end
			add_buffer(buffer, "{", indent)
			if length == #value then
				for i, v in ipairs(value) do
					traverse(i, v, buffer, true, indent .. TAB)
				end
			else
				local sortedKeys = get_table_sorted_keys(value)
				for i, key in ipairs(sortedKeys) do
					traverse(key, value[key], buffer, false, indent .. TAB)
				end
			end
			add_buffer(buffer, "},", indent)
		end
	else
		error(string.format("type %s is wrong", value_type))
	end
end

return function()
	local jsonObj = json.decode(JsonString)
	if jsonObj == nil then return end
	local buffer = {}
	traverse("local ret", jsonObj, buffer, is_array(jsonObj), "")
	if FormatCode then
		LuaString = table.concat(buffer, "\n")
	else
		LuaString = table.concat(buffer)
	end
	LuaString = string.sub(LuaString, 0,  string.len(LuaString) - 1) .. "\nreturn ret"
end
