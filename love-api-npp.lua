--[[
  This file is part of love-api-npp.

  Copyright (C)2016 Justin Dailey <dail8859@yahoo.com>
  
  love-api-npp is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either
  version 2 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
--]]

local love = require("love-api.love_api")

local function reflow(str, limit)
	local function wrap(str, limit)
		local ws = string.match(str, "^(%s+)") or " "
		local indent = ws .. "    "
		limit = limit or 100
		local here = 1
		return str:gsub("(%s+)()(%S+)()",
			function(sp, st, word, fi)
				if fi-here > limit then
					here = st - #indent
					return "\n" .. indent .. word
				end
			end)
	end
	return (str:gsub("[^\n]+",
			 function(line)
				 return wrap(line, limit)
			 end))
end

local function escape(s)
	s = string.gsub(s, "&", "&amp;")
	s = string.gsub(s, "<", "&lt;")
	s = string.gsub(s, ">", "&gt;")
	s = string.gsub(s, "'", "&apos;")
	s = string.gsub(s, '"', "&quot;")
	return s
end

local keywords = {}

local function add_keyword(kw)
	keywords[#keywords + 1] = {name = kw, text = "\t\t<KeyWord name=\"" .. kw .. "\" />"}
end

local function format_table(t, name)
	local indent = "    "
	local keys = {}
	for _, key in ipairs(t) do
		keys[#keys + 1] = indent .. indent .. "- " .. name .. "." .. key.name .. " " .. key.type .. ": " .. key.description
	end
	return table.concat(keys, "\n")
end

local function format_type(t)
	local indent = "  * "
	local s

	if t.description then
		s = indent .. t.type .. " " .. t.name .. ": " .. t.description
	else
		s = indent .. t.type .. " " .. t.name
	end

	if t.type == "table" and t.table then
		s = s .. "\n" .. format_table(t.table, t.name)
	end
	return s
end

function parse_function(func, prefix)
	local xml = ""
	xml = xml .. "\t\t<KeyWord name=\"" .. prefix .. func.name .. "\" func=\"yes\">\n"
	for _, variant in ipairs(func.variants) do
		local desc = variant.description or func.description

		local args = {}
		if variant.arguments then
			for _, argument in ipairs(variant.arguments) do
				args[#args + 1] = format_type(argument)
			end
			desc = desc .. "\n\nParameters:\n" .. table.concat(args, "\n")
		end

		args = {}
		if variant.returns then
			for _, ret in ipairs(variant.returns) do
				args[#args + 1] = format_type(ret)
			end
			desc = desc .. "\n\nReturns:\n" .. table.concat(args, "\n")
		end
		xml = xml .. "\t\t\t<Overload retVal=\"\" descr=\"\n" .. reflow(escape(desc)) .. "\">\n"

		args = {}
		if variant.arguments then
			for _, argument in ipairs(variant.arguments) do
				local s = argument.type .. " " .. argument.name
				if argument.default then
					s = s .. " = " .. argument.default
				end
				xml = xml .. "\t\t\t\t<Param name=\"" .. escape(s) .. "\" />\n"
			end
		end
		xml = xml .. "\t\t\t</Overload>\n"
	end

	xml = xml .. "\t\t</KeyWord>"

	keywords[#keywords + 1] = {name = prefix .. func.name, text = xml}
end


add_keyword("love")
for _, func in ipairs(love.functions) do
	parse_function(func, "love.")
end
for _, mod in ipairs(love.modules) do
	add_keyword("love." .. mod.name)
	for _, func in ipairs(mod.functions) do
		parse_function(func, "love." .. mod.name .. ".")
	end
end

for _, cb in ipairs(love.callbacks) do
	parse_function(cb, "love.")
end


-- Now do it
print("<?xml version=\"1.0\" encoding=\"Windows-1252\" ?>")
print("<NotepadPlus>")
print("\t<!-- Love API v" .. love.version .. " -->")
print("\t<AutoComplete language=\"Lua\">")
print("\t\t<Environment ignoreCase=\"yes\" startFunc=\"(\" stopFunc=\")\" paramSeparator=\",\" terminal=\";\" additionalWordChar=\".\" />")

table.sort(keywords, function(a, b) return a.name < b.name end)
for _, keyword in ipairs(keywords) do
	print(keyword.text)
end

print("\t</AutoComplete>")
print("</NotepadPlus>")
