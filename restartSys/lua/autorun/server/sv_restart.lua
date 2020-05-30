util.AddNetworkString("restartMsg")

local events = {
	["TermEvent"] = function(ply,inf)
		local msg = inf.message:Trim()
		local len = utf8.len(msg)
		if (len == 0 || len > 32) then return end
		msg = "<".. os.date("%H:%M:%S",os.time()) .."> " .. ply:Name() .. ": " .. msg
		net.Start("restartMsg")
			net.WriteString("TermEvent")
			net.WriteTable({message = msg})
		net.Broadcast()
	end
}

local function printEvents()
	local temp = {}
	for k in pairs(restartEvents) do
		table.insert(temp,k)
	end
	return table.concat(temp,"\n") || ""
end


local function denyJoin()
	return false,"Restart<3\nRestart<3\nRestart<3\nRestart<3\nRestart<3\nRestart<3\nRestart<3\nRestart<3\nRestart<3\nRestart<3\nRestart<3"
end

local stopFunc;
concommand.Add("restart_start",function(ply,_,args)
	if (IsValid(ply) && !ply:IsSuperAdmin()) then return end
	local time = args[1]
	local eventType = args[2]
	if (time == nil) then time = 120 end
	if (tonumber(time) == nil) then time = 120 end
	if (eventType == nil) then 
		ply:ChatPrint("Restart event is nil. Available events:\n".. printEvents())
		return
	end
	if (restartEvents[eventType] == nil) then 
		ply:ChatPrint("Restart event not found. Available events:\n".. printEvents())
		return
	end
	net.Start("restartMsg")
		net.WriteString("startEvent")
		net.WriteTable({event = eventType,time = time})
	net.Broadcast()
	stopFunc = restartEvents[eventType].onStart(time)
	timer.Create("fockServer",time,1,function() 
		RunConsoleCommand("_restart") 
	end)
	hook.Add("CheckPassword","fockServer",denyJoin)
end)


concommand.Add("restart_stop",function(ply)
	if (IsValid(ply) && !ply:IsSuperAdmin()) then return end
	timer.Destroy("fockServer")
	net.Start("restartMsg")
		net.WriteString("stopEvent")
	net.Broadcast()
	if (isfunction(stopFunc)) then 
		stopFunc()
	end
	hook.Remove("CheckPassword","fockServer")
end)

net.Receive("restartMsg",function(_,ply)
	if (!timer.Exists("fockServer")) then return end
	local event = events[net.ReadString()]
	if (event == nil) then return end
	event(ply,net.ReadTable())
end)