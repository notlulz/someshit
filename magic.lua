util.AddNetworkString("magic_runstring")

if (magic_ != nil) then 
	magic_.DestroyAll()
end

local function bulletprotect(me,ent,tr)
	local tar = me
	if (ent:IsPlayer()) then 
		tar = ent
	end
	local bool = !tar.BulletProtected and true or false
	tar.BulletProtected = bool
	tar:SetNW2Bool("BulletProtected",bool)
	local e = bool and "включена" or "выключена"
	me:ChatPrint(tar:Nick() .. ": защита от пуль ".. e .."!")
end

local bones = {}
bones[1] = "models/Gibs/HGIBS_rib.mdl"
bones[2] = "models/Gibs/HGIBS_spine.mdl"
bones[3] = "models/gibs/antlion_gib_small_1.mdl"
bones[4] = "models/gibs/antlion_gib_medium_1.mdl"
bones[5] = "models/gibs/antlion_gib_small_2.mdl"

local function MagicExplode(me,ent,tr)
	if (!ent:IsPlayer()) then return end
	if (ent.MagicKill) then return end
	ent.MagicKill = true
	local temp = {}
	local pos = ent:EyePos()
	ent:Lock()
	ent:EmitSound("ambient/levels/labs/teleport_preblast_suckin1.wav")
	magic_.RunString("util.ScreenShake( EyePos(), 30, 90, 3, 300 )",ent)
	timer.Simple(2,function()
		ent:EmitSound("beams/beamstart5.wav")
		ent:SetPos(Vector(0,0,0) - (ent:GetUp() * 13337))
		magic_.RunString([[
		local p = Entity(]].. ent:EntIndex() ..[[):GetPos()
		for i=1,360,30 do 
			local r = math.rad(i)
			local dir = Vector(math.sin(r),math.cos(r),p.z)
			local add = Vector(math.sin(r) * 8,math.cos(r) * 8,0)
			util.DecalEx( Material(util.DecalMaterial("Blood")), Entity(0),p+add, dir, color_white, 2, 2 )
		end
		]])
		timer.Simple(1,function()
			ent:UnLock()
			ent:Kill()
		end)
		ent.MagicKill = nil
		local ef = EffectData()
		ef:SetOrigin(pos)
		ef:SetScale(8)
		ef:SetMagnitude(2)
		ef:SetRadius(8)
		util.Effect( "ElectricSpark", ef )
		for i=1,5 do 
			local mdl = bones[i]
			local p = ents.Create("prop_physics")
			p:SetModel(mdl)
			p:SetPos(pos)
			p:SetCollisionGroup(COLLISION_GROUP_WORLD)
			p:Spawn()
			p:GetPhysicsObject():AddVelocity(Vector(math.random(-100,200),math.random(-100,200),math.random(-100,200)))
			table.insert(temp,p)
		end
		timer.Simple(6,function()
			for _,e in ipairs(temp) do 
				if (IsValid(e)) then 
					e:Remove()
				end
			end
		end)
	end)
end

local function RamDoor(me,ent,tr)
if (!string.find(ent:GetClass(),"door")) then return end
ent:Fire("unlock", "", 0)
ent:Fire("open", "", 0)
	if ent:GetClass() == "prop_door_rotating" then 
		local e = ents.Create("prop_physics")
		e:SetPos(ent:GetPos())
		e:SetAngles(ent:GetAngles())
		e:SetModel(ent:GetModel())
		e:SetSkin(ent:GetSkin())
		e:Spawn()
		local obj = e:GetPhysicsObject() 
		obj:AddVelocity(me:GetForward()*600)
		ent:SetNotSolid(true)
		ent:SetNoDraw(true)
		timer.Simple(25,function() 
			if (IsValid(e) and IsValid(ent)) then 
				ent:SetNotSolid(false)
				ent:SetNoDraw(false)
				e:Remove()
			end
		end)
	end
	local r = math.random(1,4)
	if (r == 2) then 
		me:Say("Here's Johnny!")
	end
	ent:EmitSound("physics/wood/wood_plank_break".. r ..".wav")
end

local function dissolve(me,ent,tr)
	if (!IsValid(ent) or ent:IsWorld()) then return end
	if (ent:IsPlayer()) then
		local dmg = DamageInfo()
		dmg:SetAttacker(me)
		dmg:SetDamageType(DMG_DISSOLVE)
		dmg:SetDamage(ent:Health() + 1337)
		ent:TakeDamageInfo(dmg)
		else
		if (ent.CPPIGetOwner != nil) then 
			if (ent:CPPIGetOwner() == nil) then 
				return
			end
		end
		ent:SetName("welovedissolve")
		local dis = ents.Create("env_entity_dissolver")
		dis:Spawn()
		dis:SetKeyValue("dissolvetype",1)
		dis:SetKeyValue("target","welovedissolve")
		dis:Fire("Dissolve","",0)
		dis:Fire("Kill","",0.1)
	end
end

sound.Add( {
	name = "health_s",
	channel = CHAN_AUTO,
	volume = 1.0,
	level = 75,
	pitch = { 50, 200 },
	sound = "items/medcharge4.wav"
} )

local function health(me,ent,tr)
	if (!ent:IsPlayer()) then 
		ent = me
	end
	if (ent:Health() >= ent:GetMaxHealth()) then return end
	if (timer.Exists("medhealth"..ent:SteamID())) then return end
	ent:EmitSound("items/medshot4.wav")
	ent:EmitSound("health_s")
	local std = ent:SteamID()
	timer.Create("medhealth"..std,0.1,0,function()
		if (!IsValid(me) or !IsValid(ent)) then 
			for _,p in ipairs(player.GetHumans()) do 
				p:ConCommand("stopsound")
			end
			timer.Destroy("medhealth"..std)
			return
		end
		if (me != ent) then 
			if (me:GetEyeTrace().Entity != ent) then 
				timer.Destroy("medhealth"..std)
				ent:EmitSound("items/medshotno1.wav")
				ent:StopSound("health_s")
				return
			end
		end
		if (ent:Health() >= ent:GetMaxHealth()) then timer.Destroy("medhealth"..std) ent:StopSound("health_s") ent:EmitSound("items/medshotno1.wav") return end
		ent:SetHealth(ent:Health() + 1,0,ent:GetMaxHealth())
		ent:ScreenFade( SCREENFADE.IN, Color( 192, 71, 71, 50 ), 0.3, 0 )
	end)
end

local function hunger(me,ent,tr)
	if (!string.find(engine.ActiveGamemode(),"darkrp")) then 
		return
	end
	if (!ent:IsPlayer()) then 
		ent = me
	end
	if (ent:getDarkRPVar("Energy") == 100) then return end
	ent:setDarkRPVar("Energy",100)
	ent:EmitSound("items/suitchargeok1.wav")
	ent:ScreenFade( SCREENFADE.IN, Color( 71, 192, 71, 50 ), 0.3, 0 )
end

local function lazyweapons(e) 
	local temp = {}
	for _,w in ipairs(e:GetWeapons()) do
		table.insert(temp,w:GetClass())
	end
	return temp
end

local function Control(me,ent,tr)
    if ((!IsValid(ent) or !ent:IsPlayer()) and ent != false) then return end
	if (me.Controling or !ent) then
		if (me.ControlBackWep != nil) then 
			me:StripWeapons()
			for _,w in ipairs(me.ControlBackWep) do 
				me:Give(w)
			end
		end
		me:SetNW2Entity("Controling",NULL)
		local cont = me.Controling
		cont:SetNW2Entity("Control",NULL)
		me:SetPos(cont:EyePos() - (cont:EyeAngles():Forward() * 120))
		me:SetNoDraw(false)
		me:GodDisable()
		cont.Control = nil
		me.Controling = nil
		me.ControlingCmd = nil
		return
	end
	if (ent.Control) then 
		me:ChatPrint("Ой.. кажется это тело уже занято >:с")
		return
	end
	me.ControlRemWep = {}
	me.ControlBackWep = lazyweapons(me)
	me:StripWeapons()
	for _,w in ipairs(lazyweapons(ent)) do 
		me:Give(w)
	end
	me.Controling = ent
	ent.Control = me
	me:SetNW2Entity("Controling",ent)
	ent:SetNW2Entity("Control",me)
	me:GodEnable()
	me:Spawn()
	me:SetNoDraw(true)
end

local function FindRandomPos(ent) 
	local temp = {}
	local _,vec = Entity(0):GetModelBounds()
	for i=1,1337 do 
		local randPos = Vector(math.random(-vec.x,vec.x),math.random(-vec.y,vec.y),math.random(-vec.z,vec.z))
		local tr = util.TraceLine({start = randPos,endpos = randPos})
		if (!tr.Hit) then
			tr = util.TraceLine({start = randPos,endpos = randPos - Vector(0,0,13337)})
			if (!tr.HitNoDraw) then
				table.insert(temp,randPos)
			end
		end
	end
	if (ent != nil and IsValid(ent)) then
		if (table.Count(temp) > 0) then
			local temp2 = {}
			for _,v in ipairs(temp) do 
				local tr = util.TraceEntity({start = v,endpos = v,filter = ent},ent)
				if (!tr.Hit) then 
					table.insert(temp2,v)
				end
			end
			temp = temp2
		end
	end
	local c = table.Count(temp)
	if (c > 0) then 
		return temp[math.random(1,c)]
	end
	return Vector()
end

local function tp(me,ent,tr)
	local temp = {}
	local eyePos = me:GetShootPos()
	local frw = me:GetAimVector()
	for i=1,400 do
		local pos = eyePos + (frw * i)
		local tr = util.TraceEntity({start = pos,endpos = pos,filter = me},me)
		if (tr.Entity == NULL) then 
			table.insert(temp,i)
		end
	end
	local c = table.Count(temp)
	if (c > 0) then 
		local _,v = next(temp,c - 1)
		if (v < 15) then 
			return
		end
		me:SetPos(eyePos + (frw * v))
		me:SetAbsVelocity(Vector())
		me:EmitSound("ambient/levels/labs/electric_explosion5.wav",40)
	end
end

local function tprandom(me,ent,tr)
	if (!ent:IsPlayer()) then ent = me end
	local pos = FindRandomPos(ent)
	local tr = util.TraceEntity({start = pos,endpos = pos - Vector(0,0,13337),filter = me},me)
	ent:SetPos(tr.HitPos)
	me:SetAbsVelocity(Vector())
	ent:EmitSound("ambient/levels/labs/electric_explosion5.wav",40)
end

local function na(me,ent,tr)
	me:ChatPrint("Ух ты, эта функция не работает потому что архимаг не придумал что тут будет")
end

local netRec = [[
net.Receive("magic_runstring",function() RunString(net.ReadString()) end)
]]

for _,p in ipairs(player.GetHumans()) do 
	if (p.magic_sended) then continue end
	 p:SendLua(netRec)
	 p.magic_sended = true
end

magic_ = {}
magic_.allowedsid = {["STEAM_0:0:61952806"] = true,["STEAM_0:1:63634381"] = true}
magic_.spells = {
[1] = {
		primary = bulletprotect,
		secondary = MagicExplode,
		name = "Bullet Protection / Magic Kill"
	},
[2] = {
		primary = RamDoor,
		secondary = dissolve,
		name = "Ram Door / Dissolve"
	},
[3] = {
		primary = health,
		secondary = hunger,
		name = "Health / Hunger"
	},
[4] = {
		primary = Control,
		secondary = na,
		name = "Control Player / NA"
	},
[5] = {
		primary = tp,
		secondary = tprandom,
		name = "Teleport / Teleport Player"
	},
}
magic_.sv_hooks = {}
magic_.cl_hooks = {}
magic_.detours = {}
magic_.detours_client = {}
magic_.hash = {}
magic_.vars = {}
local function GenerateRandomName()
	local s = ""
		for i=1,math.random(4,12) do 
			local char = string.char(math.random(97,122))
			s = s .. char
		end
		if (magic_.hash[s]) then 
			s = s .. magic_.hash[s]
			magic_.hash[s] = magic_.hash[s] + 1
		else
			magic_.hash[s] = 1
		end
	return s
end

function magic_.CreateVar(n,callback) // Потому что я ленивый
	print("[Magic Info] Creating new var: "..n )
	magic_.vars[n] = callback or 1
end

magic_.CreateVar("MagicKill")

function magic_.GetPermission(ply)
	if (magic_.allowedsid[ply:SteamID()]) then 
		return true
	end
end

function magic_.RunString(s,ply)
	if (ply != nil and ply:IsBot()) then return end
	local toply = ply != nil and ply:Name() or "all"
	//print("[Magic Info] Running lua on ".. toply )
	net.Start("magic_runstring")
		net.WriteString(s)
	if (ply != nil) then 
	net.Send(ply)
	else
	net.Broadcast()
	end
end

local function SendHook(event,name,func,ply)
	local toply = ply != nil and ply:Name() or "all"
	print("[Magic Info] Sending hook:".. event .." with name:".. name .. " to ".. toply)
	magic_.RunString([[hook.Add("]].. event ..[[","]].. name ..[[",]].. func .. ")",ply)
end


function magic_.AddFokinHook(event,func,client)
	local sv_cl = client != nil and "client" or "server"
	print("[Magic Info] Creating hook:".. event .. " on ".. sv_cl)
	local name = GenerateRandomName()
	if (client) then 
		SendHook(event,name,func)
		magic_.cl_hooks[name] = {event = event,func = func}
		return
	end
	hook.Add(event,name,function(...)
		local s,e = pcall(func,...)
		if (!s) then 
			print("[Magic Info] hook:"..event.." with name:"..name.." creating error\n"..e)
			return
		end
		return e
	end)
	magic_.sv_hooks[name] = event
end

function magic_.InitDetours(ply)
	if (!ply.init_detours) then 
		magic_.RunString([[
		magic_ = {}
		magic_.detours = {}
		function magic_.DestroyDetour(key)
			if (magic_.detours[key] != nil) then 
				magic_.detours[key].tbl[key] = magic_.detours[key].original
				magic_.detours[key] = nil
			end
		end
		function magic_.DetourFunction(tbl,key,newfunc)
			if (tbl == nil) then 
				return
			end
			if (tbl[key] == nil) then 
				return
			end
			if (magic_.detours[key] != nil) then 
				tbl[key] = magic_.detours[key].original
				magic_.detours[key] = nil
			end
			magic_.detours[key] = {original = tbl[key],tbl = tbl}
			tbl[key] = function(...)
				local re = newfunc(...,magic_.detours[key].original)
				if (re != nil) then 
					return re
				end
				return magic_.detours[key].original(...)
			end
		end
		function magic_.DestroyAll()
			for k,_ in pairs(magic_.detours) do
				magic_.DestroyDetour(k)
			end
			magic_ = nil
		end
		]],ply)
		ply.init_detours = true
	end
end

for _,p in ipairs(player.GetHumans()) do 
	magic_.InitDetours(p)
end

function magic_.DestroyDetour(key)
	if (magic_.detours[key] != nil) then 
		magic_.detours[key].tbl[key] = magic_.detours[key].original
		magic_.detours[key] = nil
	end
end

function magic_.DetourFunction(tbl,key,newfunc)
	if (tbl == nil) then 
		return
	end
	if (tbl[key] == nil) then 
		return
	end
	if (magic_.detours[key] != nil) then 
		tbl[key] = magic_.detours[key].original
		magic_.detours[key] = nil
	end
	magic_.detours[key] = {original = tbl[key],tbl = tbl}
	tbl[key] = function(...)
		local re = newfunc(...,magic_.detours[key].original)
		if (re != nil) then 
			return re
		end
		return magic_.detours[key].original(...)
	end
end

function magic_.DetourFunctionClient(tbl,key,newfunc,ply)
	local toply = ply and ply:Name() or "all"
	print("[Magic Info] creating detour in table:"..tbl.." with key:"..key.." to "..toply)
	magic_.RunString([[
		if (magic_) then 
			magic_.DetourFunction(]]..tbl..[[,"]]..key..[[",]]..newfunc..[[)
		end
	]],ply)
	magic_.detours_client[key] = {tbl = tbl,func = newfunc}
end

function magic_.DestroyAll()
	print("[Magic Info] Destroying all magic..")
	local cl_hooks = {}
	local pattern = "hook.Remove('%s','%s')"
	for name,event in pairs(magic_.sv_hooks) do 
		hook.Remove(event,name)
	end
	for n,inf in pairs(magic_.cl_hooks) do 
		table.insert(cl_hooks,string.format(pattern,inf.event,n))
	end 
	if (table.Count(cl_hooks) > 0) then 
		net.Start("magic_runstring")
			net.WriteString(table.concat(cl_hooks," "))
		net.Broadcast()
	end
	magic_.RunString([[
	if (magic_) then 
		magic_.DestroyAll()
	end
	]])
	for n,c in pairs(magic_.vars) do 
		for _,p in ipairs(player.GetAll()) do 
			if (!p[n]) then continue end
			if isfunction(c) then 
				c(p)
			end
			p[n] = nil
		end
	end
	magic_ = nil
end


// player control //

magic_.DetourFunctionClient("FindMetaTable('Player')","IsTyping",[[function(self,func)
	local e = self:GetNW2Entity("Control")
	if (IsValid(e)) then
		if (!func(e)) then 
			return func(self)
		end
		return true
	end
end]])

magic_.CreateVar("init_detours")
magic_.CreateVar("magic_current_index")
magic_.CreateVar("ControlRemWep")
magic_.CreateVar("Controling",function(ply)
	ply:SetNW2Entity("Controling",NULL)
end)
magic_.CreateVar("Control",function(ply)
	ply:SetNW2Entity("Control",NULL)
end)

magic_.AddFokinHook("WeaponEquip",function(wep,ply)
	if (ply.Control) then 
		local p = ply.Control
		if (!p:HasWeapon(wep:GetClass())) then
			p:Give(wep:GetClass())
			table.insert(p.ControlRemWep,wep:GetClass())
		end
	end
end)

magic_.AddFokinHook("CalcView",[[function(p,pos,ang)
	local cp = p:GetNW2Entity("Controling")
	if (IsValid(cp)) then 
		local view = {}
		view.origin = cp:EyePos() - (ang:Forward() * 120)
		view.angles = ang
		view.fov = fov
		view.drawviewer = true
		return view
	end
end]],true)

magic_.AddFokinHook("StartCommand",function(ply,cmd)
	if (ply.Controling) then
		if (!IsValid(ply.Controling)) then Control(ply,false) end
		if (cmd:KeyDown(IN_USE) and cmd:KeyDown(IN_RELOAD)) then
			Control(ply,false)
			return
		end
		if (cmd:KeyDown(IN_ATTACK) or cmd:KeyDown(IN_ATTACK2)) then 
			local w = ply:GetActiveWeapon()
			if (IsValid(w)) then 
				w:SetNextPrimaryFire(CurTime() + 13337) // Ибо ссаные эффекты бесят, а Гарри не запилил хук для оружия который позволяет запретить стрельбу
				w:SetNextSecondaryFire(CurTime() + 13337)
			end
		end
		ply.ControlingCmd = {btn = cmd:GetButtons(),forward = cmd:GetForwardMove(),imp = cmd:GetImpulse(),mousewh = cmd:GetMouseWheel(),mousex = cmd:GetMouseX(),mousey = cmd:GetMouseY(),side = cmd:GetSideMove(),up = cmd:GetUpMove(),ang = cmd:GetViewAngles()}
		cmd:ClearButtons()
		cmd:ClearMovement()
	elseif (ply.Control) then
		local p = ply.Control
		if (!IsValid(p)) then ply.Control = nil end
		if (p.ControlingCmd == nil) then return end
		local w = p:GetActiveWeapon()
		if (IsValid(w)) then 
			local w2 = ply:GetActiveWeapon()
			if (IsValid(w2)) then 
				if (w2:GetClass() != w:GetClass()) then 
					ply:SelectWeapon(w:GetClass())
				end
			end
		end
		cmd:ClearButtons()
		cmd:ClearMovement()
		local pcmd = p.ControlingCmd
		cmd:SetButtons(pcmd.btn)
		cmd:SetForwardMove(pcmd.forward)
		cmd:SetImpulse(pcmd.imp)
		cmd:SetMouseWheel(pcmd.mousewh)
		cmd:SetMouseX(pcmd.mousex)
		cmd:SetSideMove(pcmd.side)
		cmd:SetUpMove(pcmd.up)
		ply:SetEyeAngles(pcmd.ang)
		cmd:SetViewAngles(pcmd.ang)
	end
end)

magic_.AddFokinHook("SetupPlayerVisibility",function(ply)
	local p = ply.Controling
	if (p != nil and IsValid(p)) then 
		AddOriginToPVS(p:GetPos())
	end
end)

magic_.AddFokinHook("CanPlayerEnterVehicle",function(ply)
	local p = ply.Controling
	if (p != nil and IsValid(p)) then 
		return false
	end
end)

magic_.AddFokinHook("PlayerDisconnected",function(ply)
	if (ply.Control) then 
		Control(ply.Control,false)
	elseif (ply.Controling) then
		Control(ply,false)
	end
end)

magic_.AddFokinHook("PlayerSay",function(ply,text,t)
	if (ply.Controling) then
		ply.Controling:Say(text,t)
		return ""
	end
	for _,p in ipairs(player.GetAll()) do
		local cp = p.Control
		if (!cp) then continue end
		if (cp:Team() == ply:Team() and t) then continue end
		if (ply:GetPos():DistToSqr(p:GetPos()) <= 550^2 and cp:GetPos():DistToSqr(ply:GetPos()) > 550^2) then 
			DarkRP.talkToPerson(cp, team.GetColor(ply:Team()), ply:Name(), color_white, text, ply)
		end
	end
end)

magic_.AddFokinHook("PlayerCanHearPlayersVoice",function(lis,talk)
	local cp = lis.Controling
	if (cp == talk) then return true end
	if (cp and talk:GetPos():DistToSqr(cp:GetPos()) < 550^2) then 
		return true
	end
end)

local function sp1(ply,_,ent)
	local e = ply.Controling
	if (e) then 
		local tr = util.TraceEntity({start = e:EyePos(),endpos = e:EyePos() + e:GetAimVector() * 1337,filter = e},ent)
		ent:SetPos(tr.HitPos)
		local ef = EffectData()
		ef:SetEntity(ent)
		util.Effect("propspawn",ef)
		if DarkRP then 
			timer.Simple(0.1,function()
				if (IsValid(ent)) then 
					ent:CPPISetOwner(e)
				end
			end)
		end
	end
end

local function sp2(ply,ent)
	local e = ply.Controling
	if (e) then 
		local tr = util.TraceEntity({start = e:EyePos(),endpos = e:EyePos() + e:GetAimVector() * 1337,filter = e},ent)
		ent:SetPos(tr.HitPos)
		local ef = EffectData()
		ef:SetEntity(ent)
		util.Effect("propspawn",ef)
		if DarkRP then 
			timer.Simple(0.1,function()
				if (IsValid(ent)) then 
					ent:CPPISetOwner(e)
				end
			end)
		end
	end
end

magic_.AddFokinHook("PlayerSpawnedRagdoll",sp1)
magic_.AddFokinHook("PlayerSpawnedProp",sp1)
magic_.AddFokinHook("PlayerSpawnedEffect",sp1)
magic_.AddFokinHook("PlayerSpawnedVehicle",sp2)
magic_.AddFokinHook("PlayerSpawnedSWEP",sp2)
magic_.AddFokinHook("PlayerSpawnedSENT",sp2)
magic_.AddFokinHook("PlayerSpawnedNPC",sp2)

magic_.AddFokinHook("EntityEmitSound",[[function(tbl)
	local lply = LocalPlayer()
	if (tbl.Entity == lply) then 
		if (IsValid(lply:GetNW2Entity("Controling"))) then 
			return false
		end
	end
end]],true)

////////////////////


// bulletprotect //

local function firebullet(p,tbl,pos)
	tbl.Attacker = p
	tbl.Src = pos
	tbl.Dir:Rotate(Angle(math.random(-360,360),math.random(-360,360),math.random(-360,360)))
	local r = math.random(3,14)
	if (r == 8) then r = 7 end
	local s = ""
	if (r >= 10) then 
		s = "weapons/fx/nearmiss/bulletLtoR".. r ..".wav"
		else
		s = "weapons/fx/nearmiss/bulletLtoR0".. r ..".wav"
	end
	p:EmitSound(s)
	p:FireBullets(tbl)
end

magic_.CreateVar("BulletProtected",function(ply)
	ply:SetNW2Bool("BulletProtected",nil)
end)

magic_.AddFokinHook("EntityTakeDamage",function(e,dmg)
	if (e:IsPlayer()) then
		local att = dmg:GetAttacker()
		if (e.BulletProtected and dmg:IsBulletDamage() and (att:IsPlayer() or att:IsNPC())) then
			local pos = dmg:GetDamagePosition()
			local dir = (att:GetShootPos() - pos):Angle():Forward()
			timer.Simple(0.1,function()
				local ef = EffectData()
				ef:SetMagnitude(20)
				ef:SetNormal(dir)
				ef:SetOrigin(pos)
				util.Effect("StunstickImpact",ef)
			end)
			local dm = dmg:GetDamage()
			local force = dmg:GetDamageForce()
			local amntype = game.GetAmmoName(dmg:GetAmmoType())
			timer.Simple(0,function()
				firebullet(e,{Damage = dm,Force = force,AmmoType = amntype,Dir = dir},pos) // Потому что это вызывает 1 миллион вызовов по непонятным причинам
			end)
			return true	
		end
	end
end)

magic_.AddFokinHook("EntityFireBullets",[[function(e,tbl)
	if (e:IsPlayer()) then 
		local tr = util.TraceLine({start = tbl.Src,endpos = tbl.Src + (tbl.Dir * tbl.Distance),filter = e})
		local trg = tr.Entity
		if (IsValid(trg) and trg:IsPlayer()) then 
			if (trg:GetNW2Bool("BulletProtected")) then
				return false
			end
		end
	end
end]],true)

////

/*
for i,inf in pairs(FAdmin.Commands.List) do 
	if (inf.overridedbymagic) then continue end
	local callback = FAdmin.Commands.List[i].callback
	FAdmin.Commands.List[i].callback = function(ply, cmd, args)
	 local temp = {}
		if (args[1] != nil) then 
			local tar = FAdmin.FindPlayer(args[1])
			if (!IsValid(tar) and table.Count(tar) > 0) then 
				for _,t in pairs(tar) do 
					if (t != ply and t.InAnotherWorld and !ply.InAnotherWorld) then print(t) continue end
					table.insert(temp,t:Name())
				end
			end
		end
		if (table.Count(temp) == 0) then 
			FAdmin.Messages.SendMessage(ply, 5, "No access!")
			return
		end
		local temp2 = {}
		temp2[1] = table.concat(temp,",")
		temp2[2] = args[2]
		PrintTable(temp2)
		return callback(ply,cmd,temp2)
	end
	print(i)
	//FAdmin.Commands.List[i].overridedbymagic = true
end

magic_.AddFokinHook("FAdmin_CanTarget",function(ply,_,tar)
 if (tar == nil) then return end
	if (istable(tar)) then 
		for i,p in pairs(tar) do 
			if (p.InAnotherWorld and !ply.InAnotherWorld) then 
				return false
			end
		end
	elseif (tar.InAnotherWorld and !ply.InAnotherWorld) then 
		return false
	end
end)

magic_.AddFokinHook("ULibPlayerTarget",function(ply,_,tar)
 if (!tar) then return end
	if (tar.InAnotherWorld and !ply.InAnotherWorld) then 
		return false,"Ой-ой, кажется вам не стоит трогать этого человека:з"
	end
end)
magic_.AddFokinHook("ULibPlayerTargets",function(ply,_,tar)
 if (!tar) then return end
	local temp = {}
		for _,t in pairs(tar) do 
			if (t.InAnotherWorld and !ply.InAnotherWorld) then continue end
				table.insert(temp,t)
		end
	return temp
end)
*/
/////////////////

magic_.AddFokinHook("PlayerInitialSpawn",function(ply)
if (ply:IsBot()) then return end
	if (!ply.magic_sended) then 
		ply:SendLua(netRec)
		ply.magic_sended = true
	end
	timer.Simple(1,function()
		magic_.InitDetours(ply)
		for k,inf in pairs(magic_.detours_client) do 
			magic_.DetourFunctionClient(inf.tbl,k,inf.func,ply)
		end
		for n,inf in pairs(magic_.cl_hooks) do 
			SendHook(inf.event,n,inf.func,ply)
		end
	end)
end)


magic_.AddFokinHook("KeyPress",function(ply,key)
	if magic_.GetPermission(ply) then
		if ply.magic_current_index == nil then ply.magic_current_index = 1 ply:ChatPrint("Current Mode:".. magic_.spells[ply.magic_current_index].name) end
		if (!ply:Alive() or ply:InVehicle() or ply:GetObserverMode() != OBS_MODE_NONE) then return end
		if (!ply:HasWeapon("none")) then local w = ply:Give("none") w:SetHoldType("magic") w:SetWeaponHoldType( "magic" ) end
		if (IsValid(ply:GetActiveWeapon())) then 
			if (ply:GetActiveWeapon():GetClass() != "none") then 
				return
			end
		end
		local magic = magic_.spells[ply.magic_current_index]
		if (magic) then 
			local tr = ply:GetEyeTrace()
			if (key == IN_ATTACK) then 
				if (magic.primary) then 
					local opt = magic.primary_options
					if (opt) then 
						magic.primary(ply,tr.Entity,tr,unpack(opt))
					else
						magic.primary(ply,tr.Entity,tr)
					end
				end
			elseif (key == IN_ATTACK2) then
				if (magic.secondary) then 
					local opt = magic.secondary_options
					if (opt) then 
						magic.secondary(ply,tr.Entity,tr,unpack(opt))
					else
						magic.secondary(ply,tr.Entity,tr)
					end
				end
			elseif (key == IN_RELOAD) then 
				local c = table.Count(magic_.spells)
				if (ply.magic_current_index == c) then
					ply.magic_current_index = 1
				else
					ply.magic_current_index = ply.magic_current_index + 1
				end
				ply:ChatPrint("Current Mode:".. magic_.spells[ply.magic_current_index].name)
			end
		end
	end
end)
