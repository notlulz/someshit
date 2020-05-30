local me = player.GetBySteamID("")
local this = me:GetEyeTrace().Entity
//npc/metropolice/vo/allrightyoucango.wav

local function DoEnd(ply)
	if (ply.IsDoingHug == nil) then return end
	for _,cp in pairs(ply.IsDoingHug.cps) do 
		if (!IsValid(cp)) then continue end
		cp:AddEntityRelationship(ply,D_LI,100)
		cp:SetSaveValue( "m_vecLastPosition", VectorRand() )
		cp:SetSchedule( SCHED_FORCED_GO )
		cp:EmitSound("npc/metropolice/vo/allrightyoucango.wav")
		timer.Simple(5,function()
			cp:Remove()
		end)
	end
	ply:SetRunSpeed(ply.IsDoingHug.ma)
	ply:SetWalkSpeed(ply.IsDoingHug.mi)
	ply.IsDoingHug = nil
end

hook.Add("EntityTakeDamage","AwFack",function(ent,dmg)
	if (ent:IsNPC()) then 
		return ent.IsDoingHug != nil
	elseif (ent:IsPlayer()) then
		if (ent.IsDoingHug != nil) then 
			local att = dmg:GetAttacker()
			if (IsValid(att)) then 
				if (att.IsDoingHug && att:GetClass() == "npc_metropolice") then
					local c = ent.IsDoingHug.count
					if (c >= 5) then DoEnd(ent) return end
					ent.IsDoingHug.count = c + 1
					att:EmitSound("npc/metropolice/vo/chuckle.wav")
					ent:ViewPunch(Angle(math.random(-5,5),math.random(-1,1),0))
					ent:ScreenFade( SCREENFADE.IN, color_white, 3, 0 )
				end
			end
		end
	end
end)

local function SpawnCP(ply)
	local inf = {}
	local pos = ply:GetPos()
	for i=1,4 do
		local cp = ents.Create("npc_metropolice")
		for i=1,360 do 
			local rad = math.rad(i)
			local rand = Vector(math.cos(i),math.sin(i),0) * 88
			local tr = util.TraceEntity({start = rand+pos,endpos = rand+pos,filter = {ply,cp}},cp)
			if (!tr.Hit) then 
				cp:SetPos(tr.HitPos)
				break
			end
		end
		for _,p in ipairs(player.GetAll()) do 
			if (ply == p) then cp:AddEntityRelationship(p,D_HT,91) continue end
			cp:AddEntityRelationship(p,D_LI,90)
		end
		cp:Spawn()
		cp:Give("weapon_stunstick")
		if (cp:GetPos() == Vector()) then  cp:Remove() continue end
		cp:EmitSound("npc/metropolice/vo/holditrightthere.wav")
		cp.IsDoingHug = true
		table.insert(inf,cp)
	end
	return inf
end

local function DoHug(ply)
	if (!ply:IsPlayer()) then return end
	local cps = SpawnCP(ply)
	if (table.Count(cps) == 0) then print("Aws:с") return end
	ply.IsDoingHug = {cps = cps,mi = ply:GetWalkSpeed(),ma = ply:GetRunSpeed(),count = 0}
	ply:SetRunSpeed(100)
	ply:SetWalkSpeed(100)
end

hook.Add("Think","AwYis",function()
	for _,p in ipairs(player.GetAll()) do 
		if (p.IsDoingHug) then
			if (p.IsDoingHug.count >= 5) then continue end
			local cps = p.IsDoingHug.cps
			if (table.Count(cps) == 0) then DoEnd(p) return end
			if (p:GetMoveType() == MOVETYPE_NOCLIP) then p:SetMoveType(MOVETYPE_WALK) end
			for i,cp in pairs(cps) do 
				if (!IsValid(cp)) then p.IsDoingHug.cps[i] = nil continue end
				local d = cp:GetPos():Distance(p:GetPos())
				local pos = p:GetPos()
				local tr = util.TraceLine({start = cp:GetPos(),endpos = p:GetPos(),filter = p})
				if (tr.Hit) then 
					for i=1,360 do 
						local rad = math.rad(i)
						local rand = Vector(math.cos(i),math.sin(i),0) * 88
						local tr = util.TraceEntity({start = rand+pos,endpos = rand+pos,filter = {p,cp}},cp)
						if (!tr.Hit) then 
							cp:SetPos(tr.HitPos)
							break
						end
					end
				end
			end
		end
	end
end)

hook.Add("PlayerDisconnected","suck",function(ply)
	if (ply.IsDoingHug) then 
		for _,cp in pairs(ply.IsDoingHug.cps) do 
			if (IsValid(cp)) then 
				cp:Remove()
			end
		end
	end
end)

concommand.Add("dohug",function(ply)
	if (ply == me) then 
		local e = ply:GetEyeTrace().Entity
		if (e:IsPlayer()) then 
			DoHug(e)
		end
	end
end)