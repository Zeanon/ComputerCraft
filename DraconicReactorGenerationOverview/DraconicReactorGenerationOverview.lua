-- configure colors
local numberColor = colors.red
local unitColor = colors.gray
local buttonColor = colors.lightGray
local textColor = colors.white

-- lower number means higher refresh rate but also increases server load
local refresh = 1

-- program
local version = "1.15.1"
os.loadAPI("lib/gui")
os.loadAPI("lib/color")


local generation, drainback
local reactorGeneration = {}

local monitorData = {}

local reactorCount = 0
local gateCount = 0
local monitorCount = 0
local connectedReactorNames = {}
local connectedReactorPeripherals = {}
local connectedGateNames = {}
local connectedGatePeripherals = {}
local connectedMonitorNames = {}
local connectedMonitorPeripherals ={}
local periList = peripheral.getNames()
local validPeripherals = {
	"draconic_reactor",
	"flux_gate",
	"monitor"
}


-- get all connected peripherals
function checkValidity(periName)
	for n,b in pairs(validPeripherals) do
		if periName:find(b) then return b end
	end
	return false
end	

-- write settings to config file
function save_config()
	local sw = fs.open("config.txt", "w")
	sw.writeLine("-- Config for Draconig Reactor Generation Overview")
	sw.writeLine("version: " .. version	)
	sw.writeLine(" ")
	sw.writeLine("-- configure the display numberColors")
	sw.writeLine("numberColor: " .. color.toString(numberColor))
	sw.writeLine("unitColor: " .. color.toString(unitColor))
	sw.writeLine("buttonColor: " ..  color.toString(buttonColor))
	sw.writeLine("textColor: " ..  color.toString(textColor))
	sw.writeLine(" ")
	sw.writeLine("-- lower number means higher refresh rate but also increases server load")
	sw.writeLine("refresh: " ..  refresh)
	sw.writeLine(" ")
	sw.writeLine("-- small font means a font size of 0.5 instead of 1")
	for i = 1, monitorCount do
		if monitorData[connectedMonitorNames[i] .. ":smallFont"] then
			sw.writeLine(connectedMonitorNames[i] .. ": smallFont: true")
		else
			sw.writeLine(connectedMonitorNames[i] .. ": smallFont: false")
		end
	end
	sw.writeLine(" ")
	sw.writeLine("-- draw buttons defines whether the monitor will use the scroll buttons")
	for i = 1, monitorCount do
		if monitorData[connectedMonitorNames[i] .. ":drawButtons"] then
			sw.writeLine(connectedMonitorNames[i] .. ": drawButtons: true")
		else
			sw.writeLine(connectedMonitorNames[i] .. ": drawButtons: false")
		end
	end
	sw.writeLine(" ")
	sw.writeLine(" ")
	sw.writeLine("---------- Saved Data ----------")
	sw.writeLine("-- reactors")
	sw.writeLine("reactorCount: " .. reactorCount)
	sw.writeLine(" ")
	for i = 1, reactorCount do
		sw.writeLine("reactor" .. i .. ": " .. connectedReactorNames[i])
	end
	sw.writeLine(" ")
	sw.writeLine(" ")
	sw.writeLine("-- monitors")
	sw.writeLine("monitorCount: " .. monitorCount)
	for i = 1, monitorCount do
		sw.writeLine(" ")
		sw.writeLine("-- monitor: " .. connectedMonitorNames[i])
		for count = 1, 10 do
			sw.writeLine(connectedMonitorNames[i] .. ": line" .. count .. ": " .. monitorData[connectedMonitorNames[i] .. ":line" .. count])
		end
	end
	sw.close()
end

-- read settings from file
function load_config()
	local sr = fs.open("config.txt", "r")
	local curVersion
	local line = sr.readLine()
	while line do
		if gui.split(line, ": ")[1] == "version" then
            		curVersion = gui.split(line, ": ")[2]
		elseif gui.split(line, ": ")[1] == "numberColor" then
			numberColor = color.getColor(gui.split(line, ": ")[2])
		elseif gui.split(line, ": ")[1] == "unitColor" then
			unitColor = color.getColor(gui.split(line, ": ")[2])
		elseif gui.split(line, ": ")[1] == "buttonColor" then
			buttonColor = color.getColor(gui.split(line, ": ")[2])
		elseif gui.split(line, ": ")[1] == "textColor" then
			textColor = color.getColor(gui.split(line, ": ")[2])
		elseif gui.split(line, ": ")[1] == "refresh" then
			refresh = tonumber(gui.split(line, ": ")[2])
		else
			if string.find(gui.split(line, ": ")[1], "monitor_")
					or gui.split(line, ": ")[1] == "top"
					or gui.split(line, ": ")[1] == "bottom"
					or gui.split(line, ": ")[1] == "right"
					or gui.split(line, ": ")[1] == "left"
					or gui.split(line, ": ")[1] == "front"
					or gui.split(line, ": ")[1] == "back" then
				for i = 1, monitorCount do
					if connectedMonitorNames[i] == gui.split(line, ": ")[1] then
						if gui.split(line, ": ")[2] == "smallFont" then
							if gui.split(line, ": ")[3] == "true" then
								monitorData[connectedMonitorNames[i] .. ":smallFont"] = true
							else
								monitorData[connectedMonitorNames[i] .. ":smallFont"] = false
							end
						elseif gui.split(line, ": ")[2] == "drawButtons" then
							if gui.split(line, ": ")[3] == "true" then
								monitorData[connectedMonitorNames[i] .. ":drawButtons"] = true
							else
								monitorData[connectedMonitorNames[i] .. ":drawButtons"] = false
							end
						else
							for count = 1, 10 do
								if gui.split(line, ": ")[2] == "line" .. count then
									monitorData[connectedMonitorNames[i] .. ":line" .. count] = tonumber(gui.split(line, ": ")[3])
								end
							end
						end
					end
				end
			end
		end
		line = sr.readLine()
	end
	sr.close()
   	if curVersion ~= version then
        	save_config()
    	end
end

-- initialize Config
function initConfig()
	-- 1st time? save our settings, if not, load our settings
	if fs.exists("config.txt") == false then
		save_config()
	else
		load_config()
	end
end

function initPeripherals()
	for i,v in ipairs(periList) do
		local periFunctions = {
			["draconic_reactor"] = function()
				reactorCount = reactorCount + 1
				connectedReactorNames[reactorCount] = periList[i]
				connectedReactorPeripherals[reactorCount] = peripheral.wrap(periList[i])
			end,
			["flux_gate"] = function()
				gateCount = gateCount + 1
				connectedGateNames[gateCount] = periList[i]
				connectedGatePeripherals[gateCount] = peripheral.wrap(periList[i])
			end,
			["monitor"] = function()
				monitorCount = monitorCount + 1
				connectedMonitorNames[monitorCount] = periList[i]
				connectedMonitorPeripherals[monitorCount] = peripheral.wrap(periList[i])
				monitorData[periList[i] .. ":smallFont"] = false
				monitorData[periList[i] .. ":drawButtons"] = true
				monitorData[periList[i] .. ":amount"] = 0
				monitorData[periList[i] .. ":x"] = 0
				monitorData[periList[i] .. ":y"] = 0
				for count = 1, 10 do
					monitorData[periList[i] .. ":line" .. count] = count
				end
			end
		}

		local isValid = checkValidity(peripheral.getType(v))
		if isValid then periFunctions[isValid]()
		end
	end
end

-- Check for reactor, fluxgates and monitorData before continuing
function checkPeripherals()
	if reactorCount == 0 then
		error("No valid reactor was found")
	end
	if reactorCount ~= gateCount then
		error("Not same amount of flux gates as reactors")
	end

	if monitorCount == 0 then
		error("No valid monitor was found")
	end
end	

-- basic initialization
function init()
	initPeripherals()

	checkPeripherals()
	
	initConfig()
	
	checkLines()

	initValues()
end


-- handle the monitor touch inputs
function buttons()
	while true do
		-- button handler
		local event, side, xPos, yPos = os.pullEvent("monitor_touch")
		if monitorData[side .. ":drawButtons"] then
			local mon, monitor, monX, monY
			monitor = peripheral.wrap(side)
			monX, monY = monitor.getSize()
			mon = {}
			mon.monitor,mon.X, mon.Y = monitor, monX, monY
			if monitorData[side .. ":amount"] >= 1 and yPos >= monitorData[side .. ":y"] and yPos <= monitorData[side .. ":y"] + 4 then
				if xPos >= 1 and xPos <= 5 then
					monitorData[side .. ":line1"] = monitorData[side .. ":line1"] - 1
					if monitorData[side .. ":line1"] < 1 then
						monitorData[side .. ":line1"] = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitorData[side .. ":line1"] = monitorData[side .. ":line1"] + 1
					if monitorData[side .. ":line1"] > reactorCount + 3 then
						monitorData[side .. ":line1"] = 1
					end
				end
				drawLines()
				save_config()
			elseif monitorData[side .. ":amount"] >= 2 and yPos >= monitorData[side .. ":y"] + 10 and yPos <= monitorData[side .. ":y"] + 14 then
				if xPos >= 1 and xPos <= 5 then
					monitorData[side .. ":line2"] = monitorData[side .. ":line2"] - 1
					if monitorData[side .. ":line2"] < 1 then
						monitorData[side .. ":line2"] = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitorData[side .. ":line2"] = monitorData[side .. ":line2"] + 1
					if monitorData[side .. ":line2"] > reactorCount + 3 then
						monitorData[side .. ":line2"] = 1
					end
				end
				drawLines()
				save_config()
			elseif monitorData[side .. ":amount"] >= 3 and yPos >= monitorData[side .. ":y"] + 18 and yPos <= monitorData[side .. ":y"] + 22 then
				if xPos >= 1 and xPos <= 5 then
					monitorData[side .. ":line3"] = monitorData[side .. ":line3"] - 1
					if monitorData[side .. ":line3"] < 1 then
						monitorData[side .. ":line3"] = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitorData[side .. ":line3"] = monitorData[side .. ":line3"] + 1
					if monitorData[side .. ":line3"] > reactorCount + 3 then
						monitorData[side .. ":line3"] = 1
					end
				end
				drawLines()
				save_config()
			elseif monitorData[side .. ":amount"] >= 4 and yPos >= monitorData[side .. ":y"] + 26 and yPos <= monitorData[side .. ":y"] + 30 then
				if xPos >= 1 and xPos <= 5 then
					monitorData[side .. ":line4"] = monitorData[side .. ":line4"] - 1
					if monitorData[side .. ":line4"] < 1 then
						monitorData[side .. ":line4"] = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitorData[side .. ":line4"] = monitorData[side .. ":line4"] + 1
					if monitorData[side .. ":line4"] > reactorCount + 3 then
						monitorData[side .. ":line4"] = 1
					end
				end
				drawLines()
				save_config()
			elseif monitorData[side .. ":amount"] >= 5 and yPos >= monitorData[side .. ":y"] + 34 and yPos <= monitorData[side .. ":y"] + 38 then
				if xPos >= 1 and xPos <= 5 then
					monitorData[side .. ":line5"] = monitorData[side .. ":line5"] - 1
					if monitorData[side .. ":line5"] < 1 then
						monitorData[side .. ":line5"] = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitorData[side .. ":line5"] = monitorData[side .. ":line5"] + 1
					if monitorData[side .. ":line5"] > reactorCount + 3 then
						monitorData[side .. ":line5"] = 1
					end
				end
				drawLines()
				save_config()
			elseif monitorData[side .. ":amount"] >= 6 and yPos >= monitorData[side .. ":y"] + 42 and yPos <= monitorData[side .. ":y"] + 46 then
				if xPos >= 1 and xPos <= 5 then
					monitorData[side .. ":line6"] = monitorData[side .. ":line6"] - 1
					if monitorData[side .. ":line6"] < 1 then
						monitorData[side .. ":line6"] = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitorData[side .. ":line6"] = monitorData[side .. ":line6"] + 1
					if monitorData[side .. ":line6"] > reactorCount + 3 then
						monitorData[side .. ":line6"] = 1
					end
				end
				drawLines()
				save_config()
			elseif monitorData[side .. ":amount"] >= 7 and yPos >= monitorData[side .. ":y"] + 50 and yPos <= monitorData[side .. ":y"] + 54 then
				if xPos >= 1 and xPos <= 5 then
					monitorData[side .. ":line7"] = monitorData[side .. ":line7"] - 1
					if monitorData[side .. ":line7"] < 1 then
						monitorData[side .. ":line7"] = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitorData[side .. ":line7"] = monitorData[side .. ":line7"] + 1
					if monitorData[side .. ":line7"] > reactorCount + 3 then
						monitorData[side .. ":line7"] = 1
					end
				end
				drawLines()
				save_config()
			elseif monitorData[side .. ":amount"] >= 8 and yPos >= monitorData[side .. ":y"] + 58 and yPos <= monitorData[side .. ":y"] + 62 then
				if xPos >= 1 and xPos <= 5 then
					monitorData[side .. ":line8"] = monitorData[side .. ":line8"] - 1
					if monitorData[side .. ":line8"] < 1 then
						monitorData[side .. ":line8"] = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitorData[side .. ":line8"] = monitorData[side .. ":line8"] + 1
					if monitorData[side .. ":line8"] > reactorCount + 3 then
						monitorData[side .. ":line8"] = 1
					end
				end
				drawLines()
				save_config()
			elseif monitorData[side .. ":amount"] >= 9 and yPos >= monitorData[side .. ":y"] + 66 and yPos <= monitorData[side .. ":y"] + 70 then
				if xPos >= 1 and xPos <= 5 then
					monitorData[side .. ":line9"] = monitorData[side .. ":line9"] - 1
					if monitorData[side .. ":line9"] < 1 then
						monitorData[side .. ":line9"] = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitorData[side .. ":line9"] = monitorData[side .. ":line9"] + 1
					if monitorData[side .. ":line9"] > reactorCount + 3 then
						monitorData[side .. ":line9"] = 1
					end
				end
				drawLines()
				save_config()
			elseif monitorData[side .. ":amount"] >= 10 and yPos >= monitorData[side .. ":y"] + 74 and yPos <= monitorData[side .. ":y"] + 78 then
				if xPos >= 1 and xPos <= 5 then
					monitorData[side .. ":line10"] = monitorData[side .. ":line10"] - 1
					if monitorData[side .. ":line10"] < 1 then
						monitorData[side .. ":line10"] = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitorData[side .. ":line10"] = monitorData[side .. ":line10"] + 1
					if monitorData[side .. ":line10"] > reactorCount + 3 then
						monitorData[side .. ":line10"] = 1
					end
				end
				drawLines()
				save_config()
			else
				monitorData[side .. ":drawButtons"] = false;
			end
		else
			monitorData[side .. ":drawButtons"] = true;
		end
	end
end


-- update the monitor
function update()
	while true do
		drawLines()
		sleep(refresh)
	end
end

-- draw the different lines on the screen
function drawLines()
	for i = 1, monitorCount do
		local mon, monitor, monX, monY
		monitor = connectedMonitorPeripherals[i]
		monX, monY = monitor.getSize()
		mon = {}
		mon.monitor,mon.X, mon.Y = monitor, monX, monY

		generation = getGeneration()
		drainback = getDrainback()
		gui.clear(mon)
		print("|# -------------Reactor Information------------- #|")
		print("|# Total Reactor Output: " .. gui.format_int(generation - drainback) .. " RF/t")
		print("|# Total Generation: " .. gui.format_int(generation) .. " RF/t")
		for i = 1, reactorCount do
			reactorGeneration[i] = getReactorGeneration(i)
			print("|# Reactor " .. i .. " Generation: " .. gui.format_int(reactorGeneration[i]) .. " RF/t")
		end

		print("|# Total Drainback: " .. gui.format_int(drainback) .. " RF/t")

		local amount = monitorData[connectedMonitorNames[i] .. ":amount"]
		local drawButtons = monitorData[connectedMonitorNames[i] .. ":drawButtons"]
		local y = monitorData[connectedMonitorNames[i] .. ":y"]

		if amount >= 1 then
			drawLine(mon, y, monitorData[connectedMonitorNames[i] .. ":line1"], drawButtons, connectedMonitorNames[i])
		end
		if amount >= 2 then
			gui.draw_line(mon, 0, y+7, mon.X+1, colors.gray)
			drawLine(mon, y + 10, monitorData[connectedMonitorNames[i] .. ":line2"], drawButtons, connectedMonitorNames[i])
		end
		if amount >= 3 then
			drawLine(mon, y + 18, monitorData[connectedMonitorNames[i] .. ":line3"], drawButtons, connectedMonitorNames[i])
		end
		if amount >= 4 then
			drawLine(mon, y + 26, monitorData[connectedMonitorNames[i] .. ":line4"], drawButtons, connectedMonitorNames[i])
		end
		if amount >= 5 then
			drawLine(mon, y + 34, monitorData[connectedMonitorNames[i] .. ":line5"], drawButtons, connectedMonitorNames[i])
		end
		if amount >= 6 then
			drawLine(mon, y + 42, monitorData[connectedMonitorNames[i] .. ":line6"], drawButtons, connectedMonitorNames[i])
		end
		if amount >= 7 then
			drawLine(mon, y + 50, monitorData[connectedMonitorNames[i] .. ":line7"], drawButtons, connectedMonitorNames[i])
		end
		if amount >= 8 then
			drawLine(mon, y + 58, monitorData[connectedMonitorNames[i] .. ":line8"], drawButtons, connectedMonitorNames[i])
		end
		if amount >= 9 then
			drawLine(mon, y + 66, monitorData[connectedMonitorNames[i] .. ":line9"], drawButtons, connectedMonitorNames[i])
		end
		if amount >= 10 then
			drawLine(mon, y + 74, monitorData[connectedMonitorNames[i] .. ":line10"], drawButtons, connectedMonitorNames[i])
		end
	end
end

-- draw line with information on the monitor
function drawLine(mon, localY, line, drawButtons, side)
	if line == 1 then
		local length = string.len(tostring(generation - drainback))
		local offset = (length * 4) + (2 * math.floor((length - 1) / 3)) + 18
		local x = ((mon.X - offset) / 2) - 1
		gui.draw_number(mon, generation - drainback, x + 17, localY, numberColor)
		gui.draw_rft(mon, x, localY, unitColor)
		if drawButtons then
			gui.drawSideButtons(mon, localY, buttonColor)
			gui.draw_text_lr(mon, 2, localY + 2, 0, "DR" .. reactorCount .. " ", " Gen", textColor, textColor, buttonColor)
		end
	elseif line == 2 then
		local length = string.len(tostring(generation))
		local offset = (length * 4) + (2 * math.floor((length - 1) / 3)) + 18
		local x = ((mon.X - offset) / 2) - 1
		gui.draw_number(mon, generation, x + 17, localY, numberColor)
		gui.draw_rft(mon, x, localY, unitColor)
		if drawButtons then
			gui.drawSideButtons(mon, localY, buttonColor)
			gui.draw_text_lr(mon, 2, localY + 2, 0, "Out ", "Back", textColor, textColor, buttonColor)
		end
	elseif line == 3 then
		local length = string.len(tostring(drainback))
		local offset = (length * 4) + (2 * math.floor((length - 1) / 3)) + 18
		local x = ((mon.X - offset) / 2) - 1
		gui.draw_number(mon, drainback, x + 17, localY, numberColor)
		gui.draw_rft(mon, x, localY, unitColor)
		if drawButtons then
			gui.drawSideButtons(mon, localY, buttonColor)
			gui.draw_text_lr(mon, 2, localY + 2, 0, "Gen ", " DR1", textColor, textColor, buttonColor)
		end
	else
		local length = string.len(tostring(reactorGeneration[line - 3]))
		local offset = (length * 4) + (2 * math.floor((length - 1) / 3)) + 18
		local x = ((mon.X - offset) / 2) - 1
		gui.draw_number(mon, reactorGeneration[line - 3], x + 17, localY, numberColor)
		gui.draw_rft(mon, x, localY, unitColor)
		if drawButtons then
			gui.drawSideButtons(mon, localY, buttonColor)
			if line == 4 and line == reactorCount + 3 then
				gui.draw_text_lr(mon, 2, localY + 2, 0, "Back", " Out", textColor, textColor, buttonColor)
			elseif line == 4 then
				gui.draw_text_lr(mon, 2, localY + 2, 0, "Back", "DR" .. line - 2 .. " ", textColor, textColor, buttonColor)
			elseif line == reactorCount + 3 then
				gui.draw_text_lr(mon, 2, localY + 2, 0, "DR" .. line - 4 .. " ", " Out", textColor, textColor, buttonColor)
			else
				gui.draw_text_lr(mon, 2, localY + 2, 0, "DR" .. line - 4 .. " ", "DR" .. line - 2 .. " ", textColor, textColor, buttonColor)
			end
		end
	end
end


--get total generation
function getGeneration()
	local totalGeneration = 0
	for i = 1, reactorCount do
		totalGeneration = totalGeneration + getReactorGeneration(i)
	end
	return totalGeneration
end

-- get total drainback
function getDrainback()
	local totalDrainback = 0
	for i = 1, reactorCount do
		totalDrainback = totalDrainback + getGateFlow(i)
	end
	return totalDrainback
end

-- get generation of one specific reactor
function getReactorGeneration(number)
	local reactor = connectedReactorPeripherals[number]
	local ri = reactor.getReactorInfo()
	if ri.status == "offline" then
		return 0
	else
		return ri.generationRate
	end
end

-- get flow of one specific gate
function getGateFlow(number)
	local gate = connectedGatePeripherals[number]
	return gate.getSignalLowFlow()
end


-- check that every line displays something
function checkLines()
	for i = 1, monitorCount do
		if monitorData[connectedMonitorNames[i] .. ":line1"] > reactorCount + 3 then
			monitorData[connectedMonitorNames[i] .. ":line1"] = reactorCount + 3
		end
		if monitorData[connectedMonitorNames[i] .. ":line2"] > reactorCount + 3 then
			monitorData[connectedMonitorNames[i] .. ":line2"] = reactorCount + 3
		end
		if monitorData[connectedMonitorNames[i] .. ":line3"] > reactorCount + 3 then
			monitorData[connectedMonitorNames[i] .. ":line3"] = reactorCount + 3
		end
		if monitorData[connectedMonitorNames[i] .. ":line4"] > reactorCount + 3 then
			monitorData[connectedMonitorNames[i] .. ":line4"] = reactorCount + 3
		end
		if monitorData[connectedMonitorNames[i] .. ":line5"] > reactorCount + 3 then
			monitorData[connectedMonitorNames[i] .. ":line5"] = reactorCount + 3
		end
		if monitorData[connectedMonitorNames[i] .. ":line6"] > reactorCount + 3 then
			monitorData[connectedMonitorNames[i] .. ":line6"] = reactorCount + 3
		end
		if monitorData[connectedMonitorNames[i] .. ":line7"] > reactorCount + 3 then
			monitorData[connectedMonitorNames[i] .. ":line7"] = reactorCount + 3
		end
		if monitorData[connectedMonitorNames[i] .. ":line8"] > reactorCount + 3 then
			monitorData[connectedMonitorNames[i] .. ":line8"] = reactorCount + 3
		end
		if monitorData[connectedMonitorNames[i] .. ":line9"] > reactorCount + 3 then
			monitorData[connectedMonitorNames[i] .. ":line9"] = reactorCount + 3
		end
		if monitorData[connectedMonitorNames[i] .. ":line10"] > reactorCount + 3 then
			monitorData[connectedMonitorNames[i] .. ":line10"] = reactorCount + 3
		end
	end
	save_config()
end

-- initialize all the values
function initValues()
	for i = 1, monitorCount do
		local mon, monitor, monX, monY
		monitor = connectedMonitorPeripherals[i]
		monitor.setTextScale(1)
		monX, monY = monitor.getSize()
		mon = {}
		mon.monitor,mon.X, mon.Y = monitor, monX, monY
		if mon.Y <=	5 or monitorData[connectedMonitorNames[i] .. ":smallFont"] then
			monitor.setTextScale(0.5)
			monX, monY = monitor.getSize()
			mon = {}
			mon.monitor,mon.X, mon.Y = monitor, monX, monY
		end
		local amount = 0
		if mon.Y < 16 then
			amount = 1
			monitorData[connectedMonitorNames[i] .. ":y"] = math.floor((mon.Y - 3) / 2)
		else
			local localY = mon.Y - 2
			local int = 8
			while int <= localY do
				int = int + 8
				amount = amount + 1
			end
			monitorData[connectedMonitorNames[i] .. ":y"] = math.floor((mon.Y + 3 - (8 * amount)) / 2)
		end
		monitorData[connectedMonitorNames[i] .. ":amount"] = amount
	end
end


-- run
init()

parallel.waitForAny(buttons, update)
