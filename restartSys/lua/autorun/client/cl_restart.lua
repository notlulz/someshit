surface.CreateFont( "TermFont", {
	font = "Courier New",
	extended = true,
	size = 18,
} )


local stopFunc;
local events = {
	["startEvent"] = function(inf)
		local event = restartEvents[inf.event]
		if (!event) then return end
		local time = inf.time
		stopFunc = event.onStart(time)
	end,		
	["stopEvent"] = function(inf)
		if (isfunction(stopFunc)) then 
			stopFunc()
		end
	end,	
	["TermEvent"] = function(inf)
		if (IsValid(TerminalBfrm) && TerminalBfrm.AddText != nil) then 
			TerminalBfrm.AddText(inf.message)
		end
	end
}


net.Receive("restartMsg",function()
	local event = events[net.ReadString()]
	if (event == nil) then return end
	event(net.ReadTable())
end)