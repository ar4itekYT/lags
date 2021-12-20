-- Net for message sending
util.AddNetworkString( "lags_sendmsg" )

-- Vars
local lags = {}
-- Table vars
lags.interval = 1 / engine.TickInterval()
lags.maxLag = lags.interval * .2
lags.prevTime = SysTime()
lags.maxDiff = lags.interval * 3
lags.lags = 0
lags.lastMsgTime = 0
lags.lastMsg = ""
lags.lastNotify = ""
lags.lastNotifyTime = 0
lags.lvl = 0
lags.lastLag = SysTime()

lags.critPlayers = 12 -- Это значение игроков, при котором ваш сервер начинает подлагивать и зачастую при этом происходит ложное срабатывание 1 уровня защиты. При этом значении игроков 1 уровень защиты пропускается для стабильной игры. 999, чтобы выключить

-- Function for freeze conflict ents on the server
function lags.FreezeConflict ()
	for _,e in ipairs(ents.GetAll()) do
		local phys = e:GetPhysicsObject()

		if ( IsValid(phys) ) then
			if ( phys:GetStress() >= 2 or phys:IsPenetrating() ) then 
				local owner = e:CPPIGetOwner()
				if ( owner != nil ) then
					local name = owner:Name()
					lags.sendNotify(owner, "Твои лагающие пропы заморожены.", false)
					lags.sendMsg( Format("%s, твои конфликтующие пропы заморожены!", name) )
				end
				phys:EnableMotion(false)
			end
		end
	end
end

-- Function for clean conflict ents on the server
function lags.ClearConflict () 
	for _,e in ipairs(ents.GetAll()) do
		local phys = e:GetPhysicsObject()

		if ( IsValid(phys) ) then
			if ( phys:GetStress() >= 2 or phys:IsPenetrating() ) then 
				local owner = e:CPPIGetOwner()
				if ( owner != nil ) then
					local name = owner:Name()
					lags.sendNotify(owner, "Твои лагающие пропы удалены.", false)
					lags.sendMsg( Format("%s, твои конфликтующие пропы удалены", name) )
				end
				e:Remove()
			end
		end
	end
end
--

-- For timescale control
function lags.SetTimeScale ( scale ) 
	if ( game.GetTimeScale() > scale ) then 
		local percent = (1 - scale) * 100
		lags.sendMsg("замедление времени на " .. percent .. "%")
		game.SetTimeScale( scale )
	end
end
--

-- Kill E2s ()
function lags.StopE2s () 
	lags.sendMsg("остановка E2 чипов...")

	local chips = ents.FindByClass("gmod_wire_expression2")
	for k,e2 in pairs(chips) do
		e2:PCallHook( "destruct" )
	end
end
--

-- Cleanup map (use this if your server is too weak)
function lags.cleanUp ()
	lags.sendMsg("Внимание! Критическое состояние! Полная отчистка карты!")
	lags.sendNotify(nil, "Полная отчистка карты.", true)
	game.CleanUpMap(false, {})
end

-- Function for send Msg to player and server console
function lags.sendMsg (str)
	-- anti-flood
	if ( lags.lastMsgTime > SysTime() or str == lags.lastMsg ) then return end

	print("[Lags]:", str)

	-- send msg to players
	net.Start("lags_sendmsg")
		net.WriteString(str)
	net.Broadcast()

	lags.lastMsg = str
	lags.lastMsgTime = SysTime()
end
--

-- Sends a notification to the player
-- If you want to send a message to all players, set the value "all" to true
function lags.sendNotify (ply, str, all)
	if ( lags.lastNotifyTime > SysTime() or str == lags.lastNotify ) then return end

	net.Start( "lags_sendnotify" )
		net.WriteString( str )
	if all == true then
		net.Broadcast()
	else
		net.Send( ply )
	end

	lags.lastNotify = str
	lags.lastNotifyTime = SysTime()
end

-- Lags checkcer
hook.Add("Think", "lags", function ()
	--if (game.GetTimeScale() != 1) then return end

	lags.tickDiff = lags.interval - ( 1 / ( SysTime() - lags.prevTime ) )
	lags.prevTime = SysTime()

	if( lags.tickDiff < 0 ) then return end
	if (game.GetTimeScale() != 1) then 
		lags.tickDiff = lags.tickDiff - (lags.interval / ( game.GetTimeScale() * 5 ) )
	end

	-- if server lagged
	if ( lags.tickDiff*lags.interval >= lags.maxLag ) then 
		if ( lags.lags < lags.maxDiff ) then 
			lags.lags = lags.lags + lags.tickDiff

			if ( lags.lags < lags.maxDiff) then return end

			lags.lastLag = SysTime()
			lags.lvl = math.Clamp( lags.lvl + 1 , 0, 5)

			if (lags.tickDiff > 25) then lags.lvl = lags.lvl+1 end

			lags.sendMsg("уровень лагов " .. lags.lvl)
			if ( lags.lvl == 1 and player.GetCount() <= lags.critPlayers ) then 
				lags.SetTimeScale(0.9)
			end
			if ( lags.lvl >= 2 ) then 
				lags.SetTimeScale(0.8)
			end 
			if ( lags.lvl >= 3 ) then 
				lags.FreezeConflict() 
				lags.SetTimeScale(0.7)
				lags.StopE2s()
			end 
			if ( lags.lvl >= 4 ) then 
				lags.SetTimeScale(0.6)
				lags.StopE2s()
				lags.ClearConflict()
			end
			if ( lags.lvl >= 5 ) then 
				lags.SetTimeScale(0.4)
				lags.StopE2s
				lags.cleanUp()
			end
		end
	end 

	lags.lags = 0

	if ( lags.lastLag + 15 < SysTime() and lags.lvl != 0 ) then
		lags.sendMsg("уровень лагов сброшен!")

		game.SetTimeScale(1)
		lags.lvl = 0
	end
	--
end)
--

print("------------------------\n\n", "Lags LOADED", "\n\n------------------------" )
lags.sendMsg( "скрипт инициализирован" )
