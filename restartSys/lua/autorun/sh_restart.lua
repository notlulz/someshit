restartEvents = {
	["terminal"] = {
		onStart = function(time)
			if (SERVER) then 
				//
			else
				surface.PlaySound("ambient/machines/combine_terminal_idle4.wav")

				local phases = {
				[1] = "Загружаем крупы поней...",
				[2] = "Баним мингов...",
				[3] = "Разбаниваем Гарри...",
				[4] = "Удаляем весь транспорт...",
				[5] = "Клопаем на крупы поней...",
				[6] = "Выключаем звуки...",
				[7] = "Общаемся со своей шизой...",
				[8] = "Крашим Поняра...",
				[9] = "Удаляем все паки...",
				[10] = "Кусаем сервер...",
				[11] = "Ставим пароль на сервер...",
				[12] = "Няшимся под пледиком...",
				[13] = "Воруем паки у Аришки...",
				[14] = "Критикуем карты Шермана...",
				[15] = "Уменьшаем ЧСВ Местимы...",
				[16] = "Кидаем обиду на ПониЁБа...",
				[17] = "Разговариваем с SpaceDragon...",
				[18] = "Выделяем память для артиков...",
				[19] = "Лапаем миленьких лолек...",
				[20] = "Убегаем от Товарища Майора...",
				[21] = "А вот этого ты не увидишь<3",
				}


				local function DoAnimateText(lbl,baseText,toAddText,animTime,onEnd)
					if (IsValid(lbl)) then 
						baseText = baseText || lbl:GetText()
						local len = utf8.len(toAddText)
						if (len == 0) then return end
						lbl:SetText(baseText)
						lbl:SizeToContents()
						local cTime = 0
						for i = 1,len do 
							timer.Simple(cTime,function()
								if(IsValid(lbl)) then 
									lbl:SetText(lbl:GetText() .. toAddText[i])
									lbl:SizeToContents()
								end
								if (i == len) then 
									if (onEnd) then
										onEnd()
									end
								end
							end)
							cTime = cTime + animTime
						end
					end
				end


				local cmd = engine.ActiveGamemode():lower() .. "@" .. LocalPlayer():Name().. ":~$ "

				TerminalBfrm = vgui.Create("DFrame")
				TerminalBfrm:SetSize(ScrW(),ScrH())
				TerminalBfrm:SetTitle("")
				TerminalBfrm:ShowCloseButton(false)
				TerminalBfrm:SetDraggable(false)
				TerminalBfrm:MakePopup()
				TerminalBfrm.Paint = function(s,w,h)
					draw.RoundedBox(0,0,0,w,h,color_black)
				end

				local textentry = vgui.Create("DTextEntry",TerminalBfrm)
				textentry:SetEditable(false)
				textentry:Hide()


				local txts = {}
				local session;
				local function AddText(txt)
					local dtxt = vgui.Create("DLabel",TerminalBfrm)
					dtxt:SetFont("TermFont")
					dtxt:SetText(txt)
					dtxt:SizeToContents()
					if (session) then 
							dtxt:SetPos(0,(dtxt:GetTall() + 4) * table.Count(txts))
							table.insert(txts,dtxt)
							local count = table.Count(txts)
							local h = session:GetTall() + 4
							if (h * (count + 1) >= ScrH()) then
								for i=1,1 do
									if (txts[i]) then 
										txts[i]:Remove()
										txts[i] = nil
									end
								end
								for i=1,count do 
									txts[i] = txts[i + 1]
									local text = txts[i]
									if (text == nil) then continue end
									text:SetPos(0,(h * i) - h)
								end
								session:SetPos(0,h * table.Count(txts))
							else
								session:SetPos(0,h * count)
							end
							
							
						else
							local h = dtxt:GetTall() + 4
							local count = table.Count(txts)
							if (h * (count+1) >= ScrH()) then 
								for i=1,1 do
									if (txts[i]) then 
										txts[i]:Remove()
										txts[i] = nil
									end
								end
								for i=1,count do 
									txts[i] = txts[i + 1]
									local text = txts[i]
									if (text == nil) then continue end
									text:SetPos(0,(h * i) - h)
								end
								dtxt:SetPos(0,h * table.Count(txts))
								table.insert(txts,dtxt)
							else
								dtxt:SetPos(0,h * table.Count(txts))
								table.insert(txts,dtxt)
							end
					end
					return dtxt
				end
				
				local function TimedAddText(useTime,tbl,time,onEnd)
					local cTime = 0
					local count = table.Count(tbl)
					for i,s in ipairs(tbl) do 
						timer.Simple(cTime,function()
							local text = useTime && "<".. os.date("%H:%M:%S",os.time()) .."> " .. s || s
							AddText(text)
							if (i == count) then
								if (onEnd) then 
									onEnd()
								end
							end
						end)
						cTime = cTime + time
					end
				end
				local oldkeyCode = textentry.OnKeyCodeTyped
				textentry.OnKeyCodeTyped = function(self,code)
					local len = utf8.len(self:GetText())
					if (len > 32) then
						if (code ~= KEY_BACKSPACE) then
							if (session) then 
								self:SetText(string.Explode(" ",session:GetText())[2])
								self:SetCaretPos(33)
								return
							end
						end
					end
					oldkeyCode(self,code)
				end
				
				textentry.OnChange = function(self)
					if (session) then
						local len = utf8.len(self:GetText())
						if (len < 32) then
							session:SetText("Session> " .. self:GetText())
							session:SizeToContents()
							surface.PlaySound("ambient/machines/keyboard".. math.random(1,7) .."_clicks.wav")
						end
					end
				end

				textentry.OnValueChange = function(self,str)
					if (session) then
						local text = (string.Explode(" ",session:GetText())[2] || ""):Trim()
						session:SetText("Session> ")
						session:SizeToContents()
						self:SetText("")
						local len = utf8.len(text)
						if (len == 0 || len > 32) then return end
						net.Start("restartMsg")
							net.WriteString("TermEvent")
							net.WriteTable({message = text})
						net.SendToServer()
					end
				end

				local function ClearText()
					for i,dtxt in ipairs(txts) do 
						if (IsValid(dtxt)) then dtxt:Remove() end
						txts[i] = nil
					end
				end

				local function MakeRandomCrap()
					local temp = {}
					for i=1,math.random(20,50) do
						table.insert(temp,"ERROR: can't read function pointer at address:" .. string.format("0x%x",math.random(100000000,200000000)))
					end
					return temp
				end


				local function StartAnim()
					TimedAddText(true,phases,0.1,function()
						if (!IsValid(TerminalBfrm)) then return end
						ClearText()
						timer.Simple(0.5,function()
							local tx = AddText(cmd)
							DoAnimateText(tx,nil,"StartSession -s -f -ip ".. string.Explode(":",game.GetIPAddress())[1] .. ":1337",0.08,function()
								if (!IsValid(TerminalBfrm)) then return end
								AddText("Connecting...")
								timer.Simple(1,function() 
									AddText("Connected.")
									session = AddText("Session> ")
									session.isSession = true
									session.Think = function(self)
										if (vgui.GetKeyboardFocus() != textentry) then 
											textentry:RequestFocus()
										end
									end
									textentry:SetEditable(true)
									TerminalBfrm.AddText = AddText
									local temp = {}
									local found = false
									for i,txt in ipairs(txts) do 
										if (txt.isSession) then 
											found = true
											continue
										end
										if (found) then 
											temp[i - 1] = txt
										else
											temp[i] = txt
										end
									end
									txts = temp
									for i,txt in ipairs(txts) do 
										local h = txt:GetTall() + 4
										txt:SetPos(0,(h * i) - h)
									end
								end)
							end)	
						end)
					end)
				end
				TimedAddText(false,MakeRandomCrap(),0.02,function() ClearText() StartAnim()  end)
				
				return function()
					if (IsValid(TerminalBfrm)) then 
						TerminalBfrm:Remove()
					end
				end
			end
		end
	}
}