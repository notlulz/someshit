module("SaveSystem",package.seeall)

local localData = {}
local init = false

local function BuildTable(t)
	local temp = {}
	if (t == nil) then return temp end
	local function searchTable(tbl,t)
		for k,v in pairs(t) do 
			if (isstring(k) && k:StartWith("__")) then continue end
			if (istable(v)) then tbl[k] = {} searchTable(tbl[k],debug.getmetatable(v)) continue end
			tbl[k] = v
		end
	end
	searchTable(temp,debug.getmetatable(t))
	return temp
end

local function SaveTable(key)
	if (!init) then return end
	if (!localData[key]) then return end
	if (!sql.TableExists("SaveSystem")) then return end
	if (!sql.Query("SELECT 1 FROM SaveSystem WHERE key = '".. key .. "'")) then return end
	sql.Query("UPDATE SaveSystem SET data = '" .. util.TableToJSON(BuildTable(localData[key])) .. "' WHERE key = '".. key .. "'")
end

local function newindx(v,key)
	if (istable(v)) then 
		local mt = {}
		local info = {}
		mt.__index = mt
		mt.__newindex = function(t,k,_v)
			rawset(mt,k,newindx(_v,key))
			SaveTable(key)
		end
		setmetatable(info,mt)
		table.CopyFromTo(v,info)
		return info
	end
	return v
end


local function Load()
	if (!sql.TableExists("SaveSystem")) then
		sql.Query("CREATE TABLE SaveSystem (key VARCHAR(255), data TEXT)")
	end
	local data = sql.Query("SELECT * FROM SaveSystem")
	if (data) then
		for _,inf in ipairs(data) do 
			local key = inf.key
			local data = inf.data
			if (data == "nf") then CreateTable(key) continue end
			data = util.JSONToTable(data)
			if (!data) then CreateTable(key) continue end
			table.CopyFromTo(data,CreateTable(key))
		end
	end
	init = true
end


function CreateTable(key)
	if (localData[key]) then 
		return localData[key]
	end
	
	if (!localData[key]) then
		if (!sql.Query("SELECT 1 FROM SaveSystem WHERE key = '".. key .. "'")) then
			sql.Query("INSERT INTO SaveSystem(key,data) VALUES('".. key .."', 'nf')")
		end
	end
	
	local mt = {}
	local info = {}
	mt.__index = mt
	mt.__newindex = function(t,k,v)
		rawset(mt,k,newindx(v,key))
		SaveTable(key)
	end
	mt.__tostring = function()
		if (localData[key]) then 
			PrintTable(BuildTable(localData[key]))
		end
		return ""
	end
	setmetatable(info,mt)
	
	localData[key] = info
	return info
end

function DropSaves() // Очень много строк нипанятно!1!
	sql.Query("DROP TABLE IF EXISTS SaveSystem")
end

Load()