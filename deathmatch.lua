--  MAP ISSUES 
--crab has wall sticking out
--Stairs need deleted in parking


store = require("plugins.persistantStorage.persistantStorage")
---@diagnostic disable-next-line: missing-parameter
store.init()

speaker = require("plugins.speaker")

mode:addEnableHandler(function(isReload)
	if not isReload then
		server:reset()
	end
end)

mode:addHook("ResetGame", function()
	actualMap = "dm_maps"
	server.type = enum.gamemode.round + 16
	server.levelToLoad = actualMap
	Init()
end)

mode:addHook("PostResetGame",function ()
	server.state = enum.state.ingame
	server.time = 60
end)

mode:addHook("CollideBodies",function (bodyA, bodyB)
	if not startGame or postGame then
		if bodyA.type == 0 and bodyB.type == 0 then
			return hook.override
		end
	end
end)

mode:addHook("ServerSend",function ()
	if grabs then
		for _,grab in ipairs(grabs) do
			grab.pos = Vector()
		end
	end
end)

mode:addHook("PostServerSend",function ()
	if grabs then
		for i=1,#grabs do
			if i == 1 then
				pos = Vector(1578.16,25.16+2.5,1458.10-.25)
			elseif i == 2 then
				pos = Vector(1579.16,25.16+2.5-.6,1458.10-.25)
			else
				pos = Vector(1577.16,25.16+2.5-1.1,1458.10-.25)
			end
			grabs[i].pos = pos
		end
	end
end)

mode:addHook("PostPlayerCreate",function (ply)
	messagePlayerWrap(ply,"Welcome to FFA to ready walk past the line!")
end)

mode:addHook("PlayerDelete", function (ply)
        if ply.human then
            ply.human:remove()
        end
end)

mode:addHook("Logic",function ()
	Players = players.getAll()

	if #Players == 0 then
		resetGame = true
	end

	if #Players == 1 and resetGame then
		resetGame = false
		server:reset()
	end

	for _,ply in ipairs(Players) do
		Taunt(ply)
		if store.get(ply,"hasMap") ~= "true" and ply.account then
			ply.data.deathsRound = -999
			if server.ticksSinceReset % tickRate*20 == 0 then
				messagePlayerWrap(ply,"Map Has Changed! Download: https://tinyurl.com/rosa-dm-maps\n    /havemap To Stop Seeing")
			end
		end
	end

	if not prevMap then
		prevMap = map
	end

	if rtv >= math.ceil(#Players*2/4) then
		ChangeMap(nil)

		if mapChanged then
			for _,ply in ipairs(Players) do
				messagePlayerWrap(ply,"Map has been changed to "..map.."!")
				if ply.human then
					hook.run("TeleportHuman",ply.human)
					ply.human:remove()
				end
				ply.data.killsRound = 0
				ply.data.deathsRound = 0
				ply.data.spawnTimer = 0
				server.time = 60*60*5 + 60*3

				DeleteItemsNow()
			end
			rtv = -1
		end
	end

	if not startGame then
		Lobby()
	elseif not postGame then
		Game()
	else
		PostGame()
	end
end)

--Logic--

function shuffle(tbl,tbl2)
	for i = #tbl, 2, -1 do
	  local j = math.random(i)
	  tbl[i], tbl[j] = tbl[j], tbl[i]
	  if tbl2 then
	  	tbl2[i], tbl2[j] = tbl2[j], tbl2[i]
	  end
	end
	return tbl, tbl2
end

function Init()
	initGame = false
	startGame = false
	postGame = false
	blocked = false
	spawnedWinners = false
	tickRate = 62.5
	dt = 1/tickRate
	queueCount = 0
	modified = false
	alertState = 0
	mapChanged = false
	rtv = 0
	startSoundPlay = 0
	playEndSound = 0

	resetGame = false

	for _,ply in ipairs(players.getAll()) do
		ply.data.queued = false
	end

	ChangeMap("first")
end

function ChangeMap(first)
	local maps = {"dm_smallcity","dm_northpark"}
	newMap = maps[math.random(1,#maps)]

	if map ~= newMap then
		map = newMap

		if not first then
			mapChanged = true
		end

		if map == "dm_smallcity" then
			spawnPoints = {Vector(1407.84,48.9,1612), Vector(1408.02,48.9,1467.98), Vector(1684.64,48.84,1468.04), Vector(1631.96,48.9,1612.05), Vector(1600.63,56.84,1557.6), Vector(1599.94,57.15,1507.56), Vector(1599.35,49.08,1508.86), Vector(1455.98,49.15,1496.63), Vector(1434.83,49.09,1491.65), Vector(1436.02,49.09,1536.93), Vector(1479.33,49.09,1583.98), Vector(1570.49,49.15,1579.19), Vector(1569.7,45.09,1578.58), Vector(1440.23,49.09,1583.08), Vector(1513.9,48.9,1516.39), Vector(1553.09,49.09,1539.07), Vector(1566.1,52.83,1542.87), Vector(1566.41,52.84,1498.89), Vector(1604.6,49.15,1570.12), Vector(1602.84,49.09,1547.81)}
		elseif map == "dm_northpark" then
			spawnPoints = {Vector(1524.46,49.09,1339.87), Vector(1527.25,49.08,1312.68), Vector(1576.08,49.09,1309.3), Vector(1575.5,49.09,1367.2), Vector(1545.95,53.19,1368.16), Vector(1515.05,65.08,1368.01), Vector(1472.5,65.09,1364.87), Vector(1476.87,65.08,1336.61), Vector(1499.96,65.09,1318.67), Vector(1488.13,65.08,1298.99), Vector(1502.38,65.07,1261.94), Vector(1526.56,49.09,1254.84), Vector(1575.14,50.75,1262.81), Vector(1548.77,49.16,1295.32), Vector(1523.49,49.08,1306.11), Vector(1501.02,53.08,1258.84), Vector(1497.6,53.07,1288.11), Vector(1484.62,53.07,1305.9), Vector(1502.55,53.08,1325.23), Vector(1478.63,53.08,1367.22)}
		end
	end
end

function Lobby()
	ModificationsToMap()
	PlayMusic()
	DeleteItems()

	for _,ply in ipairs(Players) do
		if store.get(ply,"hasMap") == "true" or not ply.account then
			LobbySpawn(ply)
		end

		if ply.account and ply.name ~= ply.account.name then
			ply.name = ply.account.name
			ply:update()
		end

		if ply.human then
			hook.run("TeleportHuman",ply.human)
		end

		QueueCheck(ply)

		ply.data.won = false
		ply.data.killsRound = 0
		ply.data.deathsRound = 0
	end

	if queueCount >= math.ceil((#players*3/4)) then
		startGame = true
	end
end

	function CreateMusic()
		---@type Item
		---@diagnostic disable-next-line: assign-type-mismatch
		local item = items.create(itemTypes[enum.item.disk_black],Vector(),orientations.n)
		music = speaker.create(item)
		music._baseItem.pos = Vector(1577.63,28.34,1491.95)
		music._baseItem.isStatic = true
		music._baseItem.parentHuman = humans[255]
		local path = "/home/container/modes/deathmatch/sounds/music/"
		list = {"mario2.pcm","racist.pcm","fuck.pcm","smash.pcm"}
		local tempList = {}
		for _,song in ipairs(list) do
			table.insert(tempList,path..song)
		end
		list = tempList

		listName = {"Mario Bros 2 Main Theme","Professional Racist by Oranjate","No More Fucks To Give by Thomas B. Esq.","Super Smash Bros. Main Theme (Wii)"}
		list, listName = shuffle(list,listName)
		music:loadAudioFile(list[1])
		i = 1

		local table = items.create(itemTypes[enum.item.table],Vector(1578.23,24.59,1492),orientations.e)
		table.isStatic = true
		table.physicsSettled = true
		table.hasPhysics = true
		table.parentHuman = humans[255]
		pc = items.create(itemTypes[enum.item.computer],Vector(1578.23,25.39,1492),orientations.e)
		pc.hasPhysics = true
		pc.parentHuman = humans[255]
		pc.computerCursor = -1
		pc:computerSetLine(0,"                      MOOSIC MAKER 3000                         ")
		pc:computerSetLineColors(0,"FFFFFFFFFFFFFFFFFFFFFF                 FFFFFFFFFFFFFFFFFFFFFFF")
		pc:computerTransmitLine(0)
		pc:computerSetLine(2,"")
		pc:computerTransmitLine(2)

		pc:computerSetLine(10,"         Now Playing: "..listName[1])
		pc:computerTransmitLine(10)

		pc:computerSetLine(22,"Up Next: "..listName[2])
		pc:computerSetLineColors(22,"                                                                                                        ")
		pc:computerTransmitLine(22)
	end

	function PlayMusic()
		if not musicMinutes then
			musicMinutes = 0
		end

		music:play()

		local x,yaw = rotMatrixToEulerAngles(music._baseItem.rot)
		music._baseItem.rot = eulerAnglesToRotMatrix(0,yaw+.02,80)

		if music.errorFrames == 1 then
			--chat.announce("Next Song")
			i = i + 1
			if i > #list then
				music:loadAudioFile(list[1])
				nowPlaying = listName[1]
				i = 1
			else
				music:loadAudioFile(list[i])
				nowPlaying = listName[i]
			end

			pc:computerSetLine(10,"         Now Playing: "..listName[i])
			pc:computerTransmitLine(10)
			seconds = 0
			musicMinutes = 0

			if listName[i+1] then
				pc:computerSetLine(22,"Up Next: "..listName[i+1])
			else
				pc:computerSetLine(22,"Up Next: "..listName[1])
			end

			pc:computerSetLineColors(22,"                                                                                                        ")
			pc:computerTransmitLine(22)
		end

		if not seconds then
			seconds = 0
		end

		seconds = seconds + dt

		local showSeconds
		if math.floor(seconds) <= 9 then
			showSeconds = "0"..math.floor(seconds)
		else
			showSeconds = math.floor(seconds)
		end

		if math.floor(seconds) >= 60  then
			seconds = 0
			musicMinutes = musicMinutes + 1
		end

		pc:computerSetLine(11,"         Time Elapsed: "..musicMinutes..":"..(showSeconds))
		pc:computerTransmitLine(11)
	end

	function DestroyMusic()
		music:destroy()
		---@diagnostic disable-next-line: assign-type-mismatch
		music = nil
	end

	function Taunt(ply)
		if ply.data.taunt then
			if startGame and not postGame then
				if not ply.data.tauntSound then
					local item = items.create(itemTypes[enum.item.disk_black],ply.human.pos,orientations.n)
					---@diagnostic disable-next-line: param-type-mismatch
					ply.data.tauntSound = speaker.create(item)
					local path = "/home/container/modes/deathmatch/sounds/taunts/"..ply.data.taunt
					ply.data.tauntSound:loadAudioFile(path)

					ply.data.tauntSound._baseItem.isStatic = true
					ply.data.tauntSound._baseItem.physicsSettled = true
					ply.data.tauntSound._baseItem.hasPhysics = false
					ply.data.tauntSound._baseItem.parentHuman = humans[255]
					ply.data.tauntSound.earShot = ply.index % 8
				else
					ply.data.tauntSound:play()
				end

				if ply.human then
					ply.data.tauntSound._baseItem.pos = ply.human.pos+Vector(0,1.5,0)
					local pitch, yaw, roll = rotMatrixToEulerAngles(ply.data.tauntSound._baseItem.rot)
					ply.data.tauntSound._baseItem.rot = eulerAnglesToRotMatrix(0,yaw+.01,0)
				end

				if ply.data.tauntSound.errorFrames == 1 or not ply.human then
					ply.data.taunt = nil
					ply.data.tauntSound:destroy()
					ply.data.tauntSound = nil
				end
			else
				ply.data.taunt = nil
			end
		end
	end

	function ModificationsToMap()
		if not modified then
			CreateMusic()

			local memo = {pos = Vector(1565.0,25.8,1484.24), text = "\n ===================Welcome to Kevys FFA!====================\n\n\n  Current Map: "..map.."\n\n  Controls:\n    About: /about\n      Get this paper\n\n    Change Weapon: /w [number]\n      1 - M-16\n      2 - AK-47\n      3 - MP5\n      4 - Uzi\n      5 - Pistol (2)\n\n    Rock The Vote: /rtv\n      Changes map mid game\n\n    Check Score: H\n      Score = Kills - Deaths\n      Money = Scores\n\n    Taunts: /t [\"list\" or tauntName] \n\n    Lobby/Game: Walk past line to queue up\n      3/4 of players must queue to start\n      Players can join mid-game"}
			for i=1,18 do
				local currMemo = items.create(itemTypes[enum.item.memo],Vector(memo.pos.x+i-1,memo.pos.y,memo.pos.z),eulerAnglesToRotMatrix(80.1,0,0))
				currMemo.memoText = memo.text
				currMemo.isStatic = true
				currMemo.hasPhysics = false
				currMemo.parentHuman = humans[255]
				currMemo.despawnTime = tickRate*60*60*99
			end
			
			memo = {pos = Vector(1565,25.8,1499.75), text = "\n ==========================ChangeLog==========================\n\n      -----------------------v0.9-----------------------\n\n  - Changed Spawn Locations\n  - Players no longer spawn near each other\n  - Minor map changes\n  - Hopefully fixed issue with equipping players\n  - Added music to lobby\n\n  TAUNTS ARE NEXT UPDATE!!\n\n      ----------------------v0.9.1----------------------\n\n - Taunts added! Use with /t \"tauntName\" or \"list\"\n - Bots added for 1 player gameplay\n - Fixed weapons spawning on ground\n   (lets see if you still get ur weapon)"}
			for i=1,18 do
				local currMemo = items.create(itemTypes[enum.item.memo],Vector(memo.pos.x+i-1,memo.pos.y,memo.pos.z),eulerAnglesToRotMatrix(80.1,34.6,0))
				currMemo.memoText = memo.text
				currMemo.isStatic = true
				currMemo.hasPhysics = false
				currMemo.parentHuman = humans[255]
				currMemo.despawnTime = tickRate*60*60*99
			end

			local blockPos = {Vector(1564.17,25,1498.11),Vector(1564.17,26,1498.2),Vector(1587.84,25,1493.97),Vector(1587.84,26,1493.97)}
			--chat.announce("ran")
			for _,pos in ipairs(blockPos) do
				local item = items.create(itemTypes[enum.item.wall],pos,orientations.e)
				item.isStatic = true
				item.hasPhysics = true
				item.despawnTime = tickRate*60*60*99
				item.parentHuman = humans[255]
			end
			modified = true

			local y = 23.51
			local z = 1482.45
			for i=1,5 do
				local boxPos = Vector(1584,y,z+i*3.5)
				local item = items.create(itemTypes[enum.item.wall],boxPos,orientations.e)
				item.despawnTime = tickRate*60*60*99
			end

			--dm_smallcity
				local walls = {Vector(1569.88,44.9,1572.18),Vector(1569.88,46.05,1572.18),Vector(1574.2,49,1572.18),Vector(1574.2,50,1572.18)}
				for _,pos in ipairs(walls) do
					local item = items.create(itemTypes[enum.item.wall],pos,orientations.n)
					item.isStatic = true
					item.hasPhysics = true
					item.despawnTime = tickRate*60*60*99
					item.parentHuman = humans[255]
				end
			--end

			--dm_northpark
				local walls = {
					Vector(1519.98,53.05,1364.34+.5),Vector(1519.98,54.55,1364.34+.5),Vector(1519.98,55.55,1364.34+.5),
					Vector(1519.98,53.05,1364.34+.5+3),Vector(1519.98,54.55,1364.34+.5+3),Vector(1519.98,55.55,1364.34+.5+3),
					Vector(1519.98,53.05,1364.34+.5+6),Vector(1519.98,54.55,1364.34+.5+6),Vector(1519.98,55.55,1364.34+.5+6),}
				for _,pos in ipairs(walls) do
					local item = items.create(itemTypes[enum.item.wall],pos,orientations.e)
					item.isStatic = true
					item.hasPhysics = true
					item.despawnTime = tickRate*60*60*99
					item.parentHuman = humans[255]
				end

				for i=1,18 do
					local vec = Vector(1547.94,52.02,1364.3+i*.5-.55)
					local item = items.create(itemTypes[enum.item.box],vec,orientations.n)
					item.isStatic = true
					item.hasPhysics = true
					item.despawnTime = tickRate*60*60*99
					item.parentHuman = humans[255]
				end
			--end
		end
	end

	--Lobby Functions--
	function LobbySpawn(ply)
		if not ply.human then
			ply.money = 0
			local x = (math.random()*2) - 1
			local z = (math.random()*2) - 1
			local spawn = Vector(1565.92+x,25.09,1491.30-z)
			humans.create(spawn,eulerAnglesToRotMatrix(0,20,0),ply)
		end
	end

	function QueueCheck(ply)
		if ply.human then
			local cornerA = Vector(1589,20,1482)
			local cornerB = Vector(1584,40,1500)

			if isVectorInCuboid(ply.human.pos,cornerA,cornerB) then
				if not ply.data.queued then
					queueCount = queueCount + 1
					for _,play in ipairs(Players) do
						messagePlayerWrap(play,string.format("%s is Ready! [%s/%s]",ply.name,queueCount,math.ceil(#players*3/4)))
					end
				end
				ply.data.queued = true
			else
				if ply.data.queued then
					queueCount = queueCount - 1
					for _,play in ipairs(Players) do
						messagePlayerWrap(play,string.format("%s is NOT Ready! [%s/%s]",ply.name,queueCount,math.ceil(#players*3/4)))
					end
				end
				ply.data.queued = false
			end
		else
			ply.data.queued = false
		end
	end

mode:addHook("BulletHitHuman",function (human, bullet)
	if human.isAlive and human.player then
		human.player.data.lastHitBy = bullet.player
	end
end)

function Game()
	if not initGame then
		if #Players == 1 then
			messagePlayerWrap(players[0],"One player found! Spawning bots!")

			for i=1,5 do
				local bot = players.createBot()
				if bot then
					bot.gender = math.random(0, 1)
					local botNames = {"Adyox0 Hater","Stealth Slim","Jimmy","Sally","Tony The Terroriser","Tobias","Lethal Lingerer","Smith","Mad Man"}
					local randomName = math.random(1,#botNames)
					bot.name = "[BOT] "..botNames[randomName]
					table.remove(botNames,randomName)
					bot.isReady = true
					---@diagnostic disable-next-line: assign-type-mismatch
					bot.team = i+4
					bot:update()
				end
			end
		end

		DestroyMusic()
		server.time = 60*60*5
		initGame = true

		local i = 0
		for _,ply in ipairs(Players) do
			ply.data.respawnTime = 3

			i = i + 1

			if ply.data.killsRound ~= 0 or not ply.data.killsRound then
				ply.data.killsRound = 0
			end

			if ply.data.deathsRound ~= 0 or not ply.data.deathsRound then
				ply.data.deathsRound = 0
			end

			if ply.human then
				local randomPoint = spawnPoints[i]
					
				teleportHumanWithItems(ply.human,randomPoint)

				local wep = store.get(ply,"weapon")+0
				ply.human:arm(wep,1)
				ply.human:getInventorySlot(0).primaryItem.data.isWeapon = true
				--ply.human:getInventorySlot(0).primaryItem.type.bulletSpread = 0
				ply.human:getInventorySlot(1).primaryItem.data.isMag = true
				
				local mm = items.create(itemTypes[enum.item.pistol],ply.human.pos:clone(),orientations.n)
				assert(mm)
				ply.human:mountItem(mm,2)
				mm.data.isWeapon = true
				mm.type.bulletSpread = 0
			end
		end
	end

	if startSoundPlay >= .05 then
		for _,ply in ipairs(Players) do
			if ply.human then
				events.createSound(enum.sound.phone.buttons[5],ply.human.pos,1,1)
			end
		end
		startSoundPlay = -1
	else
		if startSoundPlay ~= -1 then
			startSoundPlay = startSoundPlay + dt
		end
	end
	
	server.time = server.time - 62.5/tickRate

	if server.time <= 60 then
		postGame = true
	end

	for _,ply in ipairs(Players) do
		--LobbySpawn(ply)
		PointLogic(ply)
		RespawnPlayers(ply)
		GiveAmmo(ply)
		BotLogic(ply)

		if not ply.data.killsRound then
			ply.data.killsRound = 0
		end

		if not ply.data.deathsRound then
			ply.data.deathsRound = 0
		end
	end

	for i=1,#Players do
		for c=1,#Players do
			if Players[c].data.killsRound < Players[i].data.killsRound then
				local temp = Players[i]
				Players[i] = Players[c]
				Players[c] = temp
			end
		end
	end

	Announcments()

	DeleteItems()
end

	function PointLogic(ply)
		if not ply.data.lastHitCooldown then
			ply.data.lastHitCooldown = 5
		end

		if ply.human then
			if not ply.human.isAlive then
				ply.human.despawnTime = tickRate*3
			end

			if not ply.human.isAlive and ply.data.lastHitBy then
				local killer = ply.data.lastHitBy

				killer.data.killsRound = killer.data.killsRound + 1
				killer.money = killer.data.killsRound
				killer:updateFinance()

				ply.data.deathsRound = ply.data.deathsRound + 1
				ply.money = ply.data.killsRound
				ply:updateFinance()

				local phrases = {"whacked","killed","creamed","'s bullet hugged","may have killed","made it hard to breathe for","made a knuckle sandwich for","forgot how a gun works... Poor"}
				local phrase = phrases[math.random(1,#phrases)]

				local suicidePhrases = {"shot himself in the foot","somehow killed himself","blew out his brains","ate his own bullet","is a little special","performed unalive"}
				local suicidePhrase = suicidePhrases[math.random(1,#suicidePhrases)]

				if ply.name ~= killer.name then
					chat.announce(killer.name.." "..phrase.." "..string.sub(ply.name,1,1))
				else
					chat.announce(ply.name.." "..suicidePhrase)
				end

				ply.data.lastHitBy = nil
			else
				if ply.data.lastHitBy then
					if ply.data.lastHitCooldown > 0 then
						ply.data.lastHitCooldown = ply.data.lastHitCooldown - 1*dt
					else
						ply.data.lastHitBy = nil
						ply.data.lastHitCooldown = 5
					end
				end
			end
		end

	end

	function RespawnPlayers(ply)
		if store.get(ply,"hasMap") == "true" or not ply.account then
			if not ply.human then
				if not ply.data.respawnTime then 
					ply.data.respawnTime = 3
				end

				ply.data.respawnTime = ply.data.respawnTime + dt

				if ply.data.respawnTime >= 3 then
					local randomPoint = spawnPoints[math.random(1,#spawnPoints)]
					local x = (math.random()*2) - 1
					local z = (math.random()*2) - 1
					randomPoint = Vector(randomPoint.x,randomPoint.y,randomPoint.z)

					local blocked = false
					for _,ply in ipairs(Players) do
						if ply.human then
							if randomPoint:dist(ply.human.pos) < 5 then
								blocked = true
								return
							end
						end
					end

					if not blocked then
						local human = humans.create(randomPoint,orientations.n,ply)
						assert(human)

						human:arm(store.get(ply,"weapon")+0,1)

						human:getInventorySlot(0).primaryItem.data.isWeapon = true
						human:getInventorySlot(0).primaryItem.type.bulletSpread = 0
						human:getInventorySlot(1).primaryItem.data.isMag = true

						local mm = items.create(itemTypes[enum.item.pistol],randomPoint,orientations.n)
						assert(mm)
						human:mountItem(mm,2)
						mm.data.isWeapon = true
						mm.type.bulletSpread = 0
					end
				end
			else
				ply.data.respawnTime = 0
			end
		end
	end

	function GiveAmmo(ply)
		if ply.human then
			if ply.human.isAlive then
				local slot = ply.human:getInventorySlot(3)

				local slot0 = ply.human:getInventorySlot(0)
				local slot1 = ply.human:getInventorySlot(1)

				local weapon = slot0.primaryItem or slot1.primaryItem
				if weapon then
					weapon = weapon.type.name
				else
					weapon = nil
				end

					for i=1,2 do
						if slot.primaryItem then
							slot.primaryItem:remove()
						end
					end

				prevWeapon = weapon

				for i=1,2 do
						local called = pcall(function ()
							---@diagnostic disable-next-line: param-type-mismatch
							local mag = items.create(itemTypes.getByName(weapon.." Magazine"),ply.human.pos:clone(),orientations.n)
							assert(mag)
							mag.data.isMag = true
							ply.human:mountItem(mag,3)
						end)

						if not called then
							local disk = items.create(itemTypes[enum.item.disk_black],ply.human.pos:clone(),orientations.n)
							assert(disk)
							disk.data.isDisk = true
							ply.human:mountItem(disk,3)
						end
				end
			end
		end
	end

	function BotLogic(ply)
		if not ply.account then
			local distance
			local closest = {math.huge,nil}

			if ply.human then
				for _,human in ipairs(humans.getAll()) do
					if human.isAlive and human.index ~= 255 and human.isActive then
						if ply.human.pos:dist(human.pos) < closest[1] then
							closest[1] = ply.human.pos:dist(human.pos)
							closest[2] = human.pos
						end
					end
				end
			end

			ply.botDestination = closest[2]
		end
	end

	function Announcments()
		if server.time <= 60*60 and alertState == 0 then
			for _,ply in ipairs(Players) do
				messagePlayerWrap(ply,string.format("%s is in the Lead with %s Kills and %s Deaths! (1 Min Left)",Players[1].name,Players[1].data.killsRound,Players[1].data.deathsRound))
			end
			alertState = 1
		elseif server.time <= 60*10 and alertState == 1 then
			for _,ply in ipairs(Players) do
				messagePlayerWrap(ply,"10 Seconds Left!")
			end
			alertState = 2
		end
	end

	function DeleteItems()
		for _,item in ipairs(items.getAll()) do
			if not item.parentHuman or item.physicsSettled then
				if item.data.isMag then
					if not item.data.despawnSet then
						item.despawnTime = tickRate*10
						item.data.despawnSet = true
					end
				end

				if item.data.isDisk then
					if not item.data.despawnTime then
						item.data.despawnTime = 0
					else
						item.data.despawnTime = item.data.despawnTime + dt
						if item.data.despawnTime >= 5 then
							item:remove()
						end
					end
				end

				if item.data.isWeapon then
					if not item.data.despawnSet then
						item.despawnTime = tickRate*20
						item.data.despawnSet = true
					end
				end

				if item.data.isMemo then
					if not item.data.despawnSet then
						item.despawnTime = tickRate*5
						item.data.despawnSet = true
					end
				end
			else
				if item.data.isWeapon or item.data.isMag or item.data.isMemo then
					item.data.despawnSet = false
				end
			end
		end
	end

	function DeleteItemsNow()
		for _,item in ipairs(items.getAll()) do
			if item.data.isWeapon or item.data.isMag or item.data.isDisk or item.data.isMemo then
				item:remove()
			end
		end
	end

function PostGame()
	for i=1,#Players do
		for c=1,#Players do
			if Players[c].data.killsRound < Players[i].data.killsRound then
				local temp = Players[i]
				Players[i] = Players[c]
				Players[c] = temp
			end
		end
	end

	if not spawnedWinners then
		server.time = 60*30
		for i=1,3 do
			if Players[i] then
				Players[i].data.won = true
				if Players[i].human then
					Players[i].human:remove()
				end
				local rank = ""
				for n=1,i do
					rank = rank.."I"
				end

				for _,ply in ipairs(Players) do
					messagePlayerWrap(ply,rank..". "..Players[i].name)
				end
			end
		end

		for _,ply in ipairs(Players) do
			if not ply.data.won then
				if ply.human then
					hook.run("TeleportHuman",ply.human)
					ply.human:remove()
					humans.create(Vector(0,0,0),orientations.n,ply)
				else
					humans.create(Vector(0,0,0),orientations.n,ply)
				end
			end

		end

		local pod2x,pod2y = 1, -.6
		local pod3x,pod3y = -1, -1.1
		local podium = {
			Vector(1578.16-.25,25.16+.5,1458.10),Vector(1578.16+.25,25.16+.5,1458.10),Vector(1578.16-.25,25.16+.5,1458.10-.5),Vector(1578.16+.25,25.16+.5,1458.10-.5),  Vector(1578.16-.25,25.16,1458.10),Vector(1578.16+.25,25.16,1458.10),Vector(1578.16-.25,25.16,1458.10-.5),Vector(1578.16+.25,25.16,1458.10-.5),  Vector(1578.16-.25,25.16-.5,1458.10),Vector(1578.16+.25,25.16-.5,1458.10),Vector(1578.16-.25,25.16-.5,1458.10-.5),Vector(1578.16+.25,25.16-.5,1458.10-.5),  Vector(1578.16-.25,25.16-1,1458.10),Vector(1578.16+.25,25.16-1,1458.10),Vector(1578.16-.25,25.16-1,1458.10-.5),Vector(1578.16+.25,25.16-1,1458.10-.5),
			Vector(1578.16-.25+pod2x,25.16+pod2y+.5,1458.10),Vector(1578.16+.25+pod2x,25.16+.5+pod2y,1458.10),Vector(1578.16-.25+pod2x,25.16+.5+pod2y,1458.10-.5),Vector(1578.16+.25+pod2x,25.16+.5+pod2y,1458.10-.5),  Vector(1578.16-.25+pod2x,25.16+pod2y,1458.10),Vector(1578.16+.25+pod2x,25.16+pod2y,1458.10),Vector(1578.16-.25+pod2x,25.16+pod2y,1458.10-.5),Vector(1578.16+.25+pod2x,25.16+pod2y,1458.10-.5),  Vector(1578.16-.25+pod2x,25.16-.5+pod2y,1458.10),Vector(1578.16+.25+pod2x,25.16-.5+pod2y,1458.10),Vector(1578.16-.25+pod2x,25.16-.5+pod2y,1458.10-.5),Vector(1578.16+.25+pod2x,25.16-.5+pod2y,1458.10-.5),  Vector(1578.16-.25+pod2x,25.16-1+pod2y,1458.10),Vector(1578.16+.25+pod2x,25.16-1+pod2y,1458.10),Vector(1578.16-.25+pod2x,25.16-1+pod2y,1458.10-.5),Vector(1578.16+.25+pod2x,25.16-1+pod2y,1458.10-.5),
			Vector(1578.16-.25+pod3x,25.16+pod3y+.5,1458.10),Vector(1578.16+.25+pod3x,25.16+.5+pod3y,1458.10),Vector(1578.16-.25+pod3x,25.16+.5+pod3y,1458.10-.5),Vector(1578.16+.25+pod3x,25.16+.5+pod3y,1458.10-.5),  Vector(1578.16-.25+pod3x,25.16+pod3y,1458.10),Vector(1578.16+.25+pod3x,25.16+pod3y,1458.10),Vector(1578.16-.25+pod3x,25.16+pod3y,1458.10-.5),Vector(1578.16+.25+pod3x,25.16+pod3y,1458.10-.5),  Vector(1578.16-.25+pod3x,25.16-.5+pod3y,1458.10),Vector(1578.16+.25+pod3x,25.16-.5+pod3y,1458.10),Vector(1578.16-.25+pod3x,25.16-.5+pod3y,1458.10-.5),Vector(1578.16+.25+pod3x,25.16-.5+pod3y,1458.10-.5),  Vector(1578.16-.25+pod3x,25.16-1+pod3y,1458.10),Vector(1578.16+.25+pod3x,25.16-1+pod3y,1458.10),Vector(1578.16-.25+pod3x,25.16-1+pod3y,1458.10-.5),Vector(1578.16+.25+pod3x,25.16-1+pod3y,1458.10-.5)
			}

		grabs = {}

		for i=1,3 do
			if i == 1 then
				pos = Vector(1578.16,25.16+2.5,1458.10-.25)
			elseif i == 2 then
				pos = Vector(1579.16,25.16+2.5-.6,1458.10-.25)
			else
				pos = Vector(1577.16,25.16+2.5-1.1,1458.10-.25)
			end

			local grab = items.create(itemTypes[enum.item.box],pos,orientations.s)
			assert(grab)
			grab.type.numHands = 2
			grab.isStatic = true
			grab.hasPhysics = true
			grab.physicsSettled = true
			grab.despawnTime = 9999
			table.insert(grabs,grab)
		end

		for _,pod in ipairs(podium) do
			local item = items.create(itemTypes[enum.item.box],pod,orientations.n)	
			item.isStatic = true
			item.hasPhysics = true
			item.physicsSettled = true
			item.despawnTime = 9999
		end

		local pos = Vector(1578.46,26.76,1458.01)
		local pos2 = Vector(1579.46,26.76-.6,1458.01)
		local pos3 = Vector(1577.46,26.76-1.1,1458.01)
		if Players[1] then
			humans.create(pos,orientations.s,Players[1])
			Players[1].human:mountItem(grabs[1],0)
			Players[1].name = "I. "..Players[1].name
			Players[1]:update()
		end

		if Players[2] then
			humans.create(pos2,orientations.s,Players[2])
			Players[2].human:mountItem(grabs[2],0)
			Players[2].name = "II. "..Players[2].name
			Players[2]:update()
		end

		if Players[3] then
			humans.create(pos3,orientations.s,Players[3])
			Players[3].human:mountItem(grabs[3],0)
			Players[3].name = "III. "..Players[3].name
			Players[3]:update()
		end
	end

	for i=1,#Players do
		local ply = Players[i]
		if i > 3 and ply.human then
			teleportHumanWithItems(ply.human,Vector(1578.38,25.25,1465.69))
			if not spawnedWinners then
				ply.name = "Fucking Losers"
				ply:update()
			end
			ply.human.viewPitch = 0
			ply.human.isImmortal = true
			local bodyParts = {
				ply.human:getRigidBody(enum.body.head), ply.human:getRigidBody(enum.body.torso), ply.human:getRigidBody(enum.body.stomach),
				ply.human:getRigidBody(enum.body.pelvis), ply.human:getRigidBody(enum.body.shoulder_left), ply.human:getRigidBody(enum.body.shoulder_right),
				ply.human:getRigidBody(enum.body.forearm_left), ply.human:getRigidBody(enum.body.forearm_right), ply.human:getRigidBody(enum.body.hand_left),
				ply.human:getRigidBody(enum.body.hand_right), ply.human:getRigidBody(enum.body.thigh_left), ply.human:getRigidBody(enum.body.thigh_right),
				ply.human:getRigidBody(enum.body.shin_left), ply.human:getRigidBody(enum.body.shin_right), ply.human:getRigidBody(enum.body.foot_left),
				ply.human:getRigidBody(enum.body.foot_right)
			}
			
			for _,part in ipairs(bodyParts) do
				part.isSettled = true
				part.rotVel = eulerAnglesToRotMatrix(0,0,0)
				part.vel = Vector()
				part.rot = pitchToRotMatrix(ply.human.viewPitch)
			end
		end
	end
	spawnedWinners = true

	if playEndSound ~= -1 then
		if playEndSound >= .05 then
			for _,ply in ipairs(Players) do
				events.createSound(enum.sound.misc.whistle,ply.human.pos,.4,1)
			end
			playEndSound = -1
		else
			playEndSound = playEndSound + dt
		end
	end

	server.time = server.time - 62.5/tickRate

	if server.time <= 2 then
		server:reset()
	end
end

mode.commands["/endgame"] = {
	alias={"/eg"},
	info = "",
	canCall = function (ply)
		return ply.isAdmin
	end,
	call = function ()
		server.time = 62.5
	end,
}

mode.commands["/fs"] = {
	alias={"/fs"},
	info = "",
	canCall = function (ply)
		return ply.isAdmin
	end,
	call = function ()
		startGame = true
	end,
}

mode.commands["/about"] = {
	alias={"/a"},
	info = "See basic server info",
	call = function (ply)
		
		if ply.human then
			if ply.human.isAlive then
				local memo = {pos = Vector(1565.0,25.8,1484.24), text = "\n ===================Welcome to Kevys FFA!====================\n\n\n  Current Map: "..map.."\n\n  Controls:\n    Change Weapon: /w [number]\n      1 - M-16\n      2 - AK-47\n      3 - MP5\n      4 - Uzi\n      5 - Pistol (2)\n\n    Rock The Vote: /rtv\n      Changes map mid game\n\n    Check Score: H\n      Score = Kills - Deaths\n      Money = Scores\n\n    Taunts: /t [\"list\" or tauntName]\n\n    Lobby/Game: Walk past line to queue up\n      3/4 of players must queue to start\n      Players can join mid-game"}				memoO = items.create(itemTypes[enum.item.memo],ply.human.pos+(ply.human:getRigidBody(enum.body.head).rot:forwardUnit())*2+Vector(0,1,0),yawToRotMatrix(ply.human.viewYaw))
				memoO.memoText = memo.text
				memoO.despawnTime = tickRate*5
				memoO.data.isMemo = true
			end
		end
	end,
}

mode.commands["/rtv"] = {
	info = "Rock The Vote / Change The Map",
	call = function (ply)
		if not ply.data.rtv and rtv ~= -1 then
			if startGame and not postGame then
				ply.data.rtv = true
				rtv = rtv + 1

				for _,play in ipairs(Players) do
					messagePlayerWrap(play,string.format("%s Rocked The Vote! [%s/%s]",ply.name,rtv,math.ceil(#players*(1/2))))
				end
			end
		end
	end
}

mode.commands["/w"] = {
	info = "change primary weapon",
	usage = "[Number]",
	call = function (ply,hum,args)
		assert(tonumber(args[1]),"usage")
		if tonumber(args[1]) >= 1 and tonumber(args[1]) <= 5 then
		else
			args[1] = nil
			assert(args[1],"usage")
		end

		weaponNum = tonumber(args[1])

		if weaponNum == 1 then
			messagePlayerWrap(ply,"Weapon changed to M-16")
			store.set(ply,"weapon",tostring(enum.item.m16))
		elseif weaponNum == 2 then
			messagePlayerWrap(ply,"Weapon changed to AK-47")
			store.set(ply,"weapon",tostring(enum.item.ak47))
		elseif weaponNum == 3 then
			messagePlayerWrap(ply,"Weapon changed to MP5")
			store.set(ply,"weapon",tostring(enum.item.mp5))
		elseif weaponNum == 4 then
			messagePlayerWrap(ply,"Weapon changed to Uzi")
			store.set(ply,"weapon",tostring(enum.item.uzi))
		elseif weaponNum == 5 then
			messagePlayerWrap(ply,"Weapon changed to Pistol (2)")
			store.set(ply,"weapon",tostring(enum.item.pistol))
		end
	end
}

mode.commands["/havemap"] = {
	info = "spawn in since you have the map",
	usage = "[Number]",
	call = function (ply,hum,args)
		store.set(ply,"hasMap","true")
		messagePlayerWrap(ply,"Restart the game and rejoin server!")
		ply.data.deathsRound = 0
	end
}

mode.commands["/donthavemap"] = {
	info = "see the url again",
	usage = "[Number]",
	call = function (ply,hum,args)
		store.set(ply,"hasMap","false")
		ply.data.deathsRound = 0
	end
}

mode.commands["/resetstorage"] ={
	info = "",

	canCall = function (ply)
		return ply.isAdmin
	end,
	
	call = function ()
		store.reset()
	end,
}

mode.commands["/t"] ={
	info = "choose a taunt (/t list)",
	alias = {"/t"},
	usage = "[Taunt/List]",
	
	call = function (ply,man,args)
		local isTaunt = false
		local taunts = {"bomb","cheese","conductor","hi","kys","mario","scream"}

		if args[1] == "" then
			args[1] = nil
		end

		assert(args[1],"usage")

		if string.lower(args[1]) == "list" then
			local tauntsString = ""
			for i=1,#taunts do
				local taunt = taunts[i]

				if i~= #taunts then
					tauntsString = tauntsString..taunt..", "
				else
					tauntsString = tauntsString..taunt
				end
			end
			messagePlayerWrap(ply,tauntsString)
		end

		if startGame and not postGame then
			for _,taunt in ipairs(taunts) do
				if string.lower(args[1]) == taunt then
					local taunt = string.lower(taunt)..".pcm"
					ply.data.taunt = taunt
					isTaunt = true
				end
			end

			if not isTaunt and string.lower(args[1]) ~= "list" then
				messagePlayerWrap(ply,args[1].." is not a taunt!")
			end
		elseif string.lower(args[1]) ~= "list" then
			messagePlayerWrap(ply,"Cannot Taunt in Lobby!")
		end
	end,
}