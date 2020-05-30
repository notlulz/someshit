local detours = {}
local function Detour(tbl,key,newfunc)
	if (tbl[key] == nil) then return end
	local oldfunc = tbl[key]
	if (!isfunction(oldfunc)) then return end
	detours[key] = {tbl = tbl,oldfunc = oldfunc}
	tbl[key] = function(...) newfunc(...) return oldfunc(...) end
end

local msg = ""
Detour(net,"SendToServer",function()
	print("NetLogger:End Message:",tostring(msg))
	msg = nil
end)

Detour(net,"Start",function(m)
	msg = m
	if (msg != nil) then 
		print("NetLogger:Start New Message:",tostring(msg))
	end	
end)

Detour(net,"WriteAngle",function(ang)
	if (msg != nil) then 
		print("NetLogger:Writing Angle ",tostring(ang))
	end
end)

Detour(net,"WriteBit",function(b)
	if (msg != nil) then 
		print("NetLogger:Writing bit ",tostring(b))
	end
end)

Detour(net,"WriteBool",function(bo)
	if (msg != nil) then 
		print("NetLogger:Writing bool ",tostring(bo))
	end
end)

Detour(net,"WriteColor",function(c)
	if (msg != nil) then 
		print("NetLogger:Writing Color ",tostring(c))
	end
end)

Detour(net,"WriteData",function(data)
	if (msg != nil) then 
		print("NetLogger:Writing Data, see wow_data.txt in /data/")
		file.Write("wow_data.txt",data)
	end
end)

Detour(net,"WriteDouble",function(d)
	if (msg != nil) then 
		print("NetLogger:Writing Double ",tostring(d))
	end
end)

Detour(net,"WriteEntity",function(e)
	if (msg != nil) then 
		print("NetLogger:Writing Entity ",tostring(e))
	end
end)

Detour(net,"WriteFloat",function(f)
	if (msg != nil) then 
		print("NetLogger:Writing Float ",tostring(f))
	end
end)

Detour(net,"WriteInt",function(i,b)
	if (msg != nil) then 
		print("NetLogger:Writing Int ",tostring(i),tostring(b))
	end
end)

Detour(net,"WriteMatrix",function(m)
	if (msg != nil) then 
		print("NetLogger:Writing Matrix ",tostring(m))
	end
end)

Detour(net,"WriteNormal",function(n)
	if (msg != nil) then 
		print("NetLogger:Writing Normal ",tostring(n))
	end
end)

Detour(net,"WriteString",function(s)
	if (msg != nil) then 
		print("NetLogger:Writing String ",tostring(s))
	end
end)

Detour(net,"WriteTable",function()
	if (msg != nil) then 
		print("NetLogger:Writing Table")
	end
end)

Detour(net,"WriteUInt",function(un,b)
	if (msg != nil) then 
		print("NetLogger:Writing UInt ",tostring(un),tostring(b))
	end
end)

Detour(net,"WriteVector",function(v)
	if (msg != nil) then 
		print("NetLogger:Writing Vector ",tostring(v))
	end
end)