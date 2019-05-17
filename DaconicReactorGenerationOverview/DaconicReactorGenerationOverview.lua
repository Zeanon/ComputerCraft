-- configure colors
local numberColor = colors.red
local unitColor = colors.gray
local buttonColor = colors.lightGray
local textColor = colors.white
-- lower number means higher refresh rate but also increases server load
local refresh = 1

-- program
local version = "1.4.0"
os.loadAPI("lib/gui")
os.loadAPI("lib/color")


local generation, drainback
local reactorGeneration = {}

local monitors = {}

local reactorCount = 0
local gateCount = 0
local monitorCount = 0
local connectedReactors = {}
local connectedGates = {}
local connectedMonitors = {}
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

for i,v in ipairs(periList) do
	local periFunctions = {
		["draconic_reactor"] = function()
			reactorCount = reactorCount + 1
			connectedReactors[reactorCount] = periList[i]
		end,
		["flux_gate"] = function()
			gateCount = gateCount + 1
			connectedGates[gateCount] = periList[i]
		end,
		["monitor"] = function()
			monitorCount = monitorCount + 1
			connectedMonitors[monitorCount] = periList[i]
			monitors[periList[i] .. ":smallFont"] = false
			monitors[periList[i] .. ":drawButtons"] = true
			monitors[periList[i] .. ":amount"] = 0
			monitors[periList[i] .. ":x"] = 0
			monitors[periList[i] .. ":y"] = 0
			for count = 1, 10 do
				monitors[periList[i] .. ":line" .. count] = count
			end
		end
	}

	local isValid = checkValidity(peripheral.getType(v))
	if isValid then periFunctions[isValid]()
	end
end

--write settings to config file
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
		if monitors[connectedMonitors[i] .. ":smallFont"] then
			sw.writeLine(connectedMonitors[i] .. ": smallFont: true")
		else
			sw.writeLine(connectedMonitors[i] .. ": smallFont: false")
		end
	end
	sw.writeLine(" ")
	sw.writeLine("-- draw buttons defines whether the monitor will use the scroll buttons")
	for i = 1, monitorCount do
		if monitors[connectedMonitors[i] .. ":drawButtons"] then
			sw.writeLine(connectedMonitors[i] .. ": drawButtons: true")
		else
			sw.writeLine(connectedMonitors[i] .. ": drawButtons: false")
		end
	end
	sw.writeLine(" ")
	sw.writeLine("-- just some saved data")
	sw.writeLine("monitorCount: " .. monitorCount)
	for i = 1, monitorCount do
		sw.writeLine(" ")
		sw.writeLine("-- monitor: " .. connectedMonitors[i])
		for count = 1, 10 do
			sw.writeLine(connectedMonitors[i] .. ": line" .. count .. ": " .. monitors[connectedMonitors[i] .. ":line" .. count])
		end
	end
	sw.close()
end

--read settings from file
function load_config()
	local sr = fs.open("config.txt", "r")
	local line = sr.readLine()
	while line do
		if gui.split(line, ": ")[1] == "numberColor" then
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
					if connectedMonitors[i] == gui.split(line, ": ")[1] then
						if gui.split(line, ": ")[2] == "smallFont" then
							if gui.split(line, ": ")[3] == "true" then
								monitors[connectedMonitors[i] .. ":smallFont"] = true
							else
								monitors[connectedMonitors[i] .. ":smallFont"] = false
							end
						elseif gui.split(line, ": ")[2] == "drawButtons" then
							if gui.split(line, ": ")[3] == "true" then
								monitors[connectedMonitors[i] .. ":drawButtons"] = true
							else
								monitors[connectedMonitors[i] .. ":drawButtons"] = false
							end
						else
							for count = 1, 10 do
								if gui.split(line, ": ")[2] == "line" .. count then
									monitors[connectedMonitors[i] .. ":line" .. count] = tonumber(gui.split(line, ": ")[3])
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
	save_config()
end

-- 1st time? save our settings, if not, load our settings
if fs.exists("config.txt") == false then
	save_config()
else
	load_config()
end


--Check for reactor, fluxgates and monitors before continuing
if reactorCount == 0 then
	error("No valid reactor was found")
end
if reactorCount ~= gateCount then
	error("Not same amount of flux gates as reactors")
end

if monitorCount == 0 then
	error("No valid monitor was found")
end



--update the monitor
function update()
	while true do
		drawLines()
		sleep(refresh)
	end
end

--draw the different lines on the screen
function drawLines()
	for i = 1, monitorCount do
		local mon, monitor, monX, monY
		monitor = peripheral.wrap(connectedMonitors[i])
		monX, monY = monitor.getSize()
		mon = {}
		mon.monitor,mon.X, mon.Y = monitor, monX, monY

		generation = getGeneration()
		drainback = getDrainback()
		gui.clear(mon)
		print("Total reactor output: " .. gui.format_int(generation - drainback) .. " RF/t")
		print("Total generation: " .. gui.format_int(generation) .. " RF/t")
		for i = 1, reactorCount do
			reactorGeneration[i] = getReactorGeneration(i)
			print("Reactor " .. i .. " Generation: " .. gui.format_int(reactorGeneration[i]) .. " RF/t")
		end
		print("Total drainback: " .. gui.format_int(drainback) .. " RF/t")

		local amount = monitors[connectedMonitors[i] .. ":amount"]
		local drawButtons = monitors[connectedMonitors[i] .. ":drawButtons"]
		local y = monitors[connectedMonitors[i] .. ":y"]

		if amount >= 1 then
			drawLine(mon, y, monitors[connectedMonitors[i] .. ":line1"], drawButtons, connectedMonitors[i])
		end
		if amount >= 2 then
			gui.draw_line(mon, 0, y+7, mon.X+1, colors.gray)
			drawLine(mon, y + 10, monitors[connectedMonitors[i] .. ":line2"], drawButtons, connectedMonitors[i])
		end
		if amount >= 3 then
			drawLine(mon, y + 18, monitors[connectedMonitors[i] .. ":line3"], drawButtons, connectedMonitors[i])
		end
		if amount >= 4 then
			drawLine(mon, y + 26, monitors[connectedMonitors[i] .. ":line4"], drawButtons, connectedMonitors[i])
		end
		if amount >= 5 then
			drawLine(mon, y + 34, monitors[connectedMonitors[i] .. ":line5"], drawButtons, connectedMonitors[i])
		end
		if amount >= 6 then
			drawLine(mon, y + 42, monitors[connectedMonitors[i] .. ":line6"], drawButtons, connectedMonitors[i])
		end
		if amount >= 7 then
			drawLine(mon, y + 50, monitors[connectedMonitors[i] .. ":line7"], drawButtons, connectedMonitors[i])
		end
		if amount >= 8 then
			drawLine(mon, y + 58, monitors[connectedMonitors[i] .. ":line8"], drawButtons, connectedMonitors[i])
		end
		if amount >= 9 then
			drawLine(mon, y + 66, monitors[connectedMonitors[i] .. ":line9"], drawButtons, connectedMonitors[i])
		end
		if amount >= 10 then
			drawLine(mon, y + 74, monitors[connectedMonitors[i] .. ":line10"], drawButtons, connectedMonitors[i])
		end
	end
end

--handle the monitor touch inputs
function buttons()
	while true do
		-- button handler
		local event, side, xPos, yPos = os.pullEvent("monitor_touch")
		if monitors[side .. ":drawButtons"] then
			local mon, monitor, monX, monY
			monitor = peripheral.wrap(side)
			monX, monY = monitor.getSize()
			mon = {}
			mon.monitor,mon.X, mon.Y = monitor, monX, monY
			if monitors[side .. ":amount"] >= 1 and yPos >= monitors[side .. ":y"] and yPos <= monitors[side .. ":y"] + 4 then
				if xPos >= 1 and xPos <= 5 then
					monitors[side .. ":line1"] = monitors[side .. ":line1"] - 1
					if monitors[side .. ":line1"] < 1 then
						monitors[side .. ":line1"] = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitors[side .. ":line1"] = monitors[side .. ":line1"] + 1
					if monitors[side .. ":line1"] > reactorCount + 3 then
						monitors[side .. ":line1"] = 1
					end
				end
				drawLines()
				save_config()
			end

			if monitors[side .. ":amount"] >= 2 and yPos >= monitors[side .. ":y"] + 10 and yPos <= monitors[side .. ":y"] + 14 then
				if xPos >= 1 and xPos <= 5 then
					monitors[side .. ":line2"] = monitors[side .. ":line2"] - 1
					if monitors[side .. ":line2"] < 1 then
						monitors[side .. ":line2"] = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitors[side .. ":line2"] = monitors[side .. ":line2"] + 1
					if monitors[side .. ":line2"] > reactorCount + 3 then
						monitors[side .. ":line2"] = 1
					end
				end
				drawLines()
				save_config()
			end

			if monitors[side .. ":amount"] >= 3 and yPos >= monitors[side .. ":y"] + 18 and yPos <= monitors[side .. ":y"] + 22 then
				if xPos >= 1 and xPos <= 5 then
					monitors[side .. ":line3"] = monitors[side .. ":line3"] - 1
					if monitors[side .. ":line3"] < 1 then
						monitors[side .. ":line3"] = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitors[side .. ":line3"] = monitors[side .. ":line3"] + 1
					if monitors[side .. ":line3"] > reactorCount + 3 then
						monitors[side .. ":line3"] = 1
					end
				end
				drawLines()
				save_config()
			end

			if monitors[side .. ":amount"] >= 4 and yPos >= monitors[side .. ":y"] + 26 and yPos <= monitors[side .. ":y"] + 30 then
				if xPos >= 1 and xPos <= 5 then
					monitors[side .. ":line4"] = monitors[side .. ":line4"] - 1
					if monitors[side .. ":line4"] < 1 then
						monitors[side .. ":line4"] = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitors[side .. ":line4"] = monitors[side .. ":line4"] + 1
					if monitors[side .. ":line4"] > reactorCount + 3 then
						monitors[side .. ":line4"] = 1
					end
				end
				drawLines()
				save_config()
			end

			if monitors[side .. ":amount"] >= 5 and yPos >= monitors[side .. ":y"] + 34 and yPos <= monitors[side .. ":y"] + 38 then
				if xPos >= 1 and xPos <= 5 then
					monitors[side .. ":line5"] = monitors[side .. ":line5"] - 1
					if monitors[side .. ":line5"] < 1 then
						monitors[side .. ":line5"] = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitors[side .. ":line5"] = monitors[side .. ":line5"] + 1
					if monitors[side .. ":line5"] > reactorCount + 3 then
						monitors[side .. ":line5"] = 1
					end
				end
				drawLines()
				save_config()
			end

			if monitors[side .. ":amount"] >= 6 and yPos >= monitors[side .. ":y"] + 42 and yPos <= monitors[side .. ":y"] + 46 then
				if xPos >= 1 and xPos <= 5 then
					monitors[side .. ":line6"] = monitors[side .. ":line6"] - 1
					if monitors[side .. ":line6"] < 1 then
						monitors[side .. ":line6"] = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitors[side .. ":line6"] = monitors[side .. ":line6"] + 1
					if monitors[side .. ":line6"] > reactorCount + 3 then
						monitors[side .. ":line6"] = 1
					end
				end
				drawLines()
				save_config()
			end

			if monitors[side .. ":amount"] >= 7 and yPos >= monitors[side .. ":y"] + 50 and yPos <= monitors[side .. ":y"] + 54 then
				if xPos >= 1 and xPos <= 5 then
					monitors[side .. ":line7"] = monitors[side .. ":line7"] - 1
					if monitors[side .. ":line7"] < 1 then
						monitors[side .. ":line7"] = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitors[side .. ":line7"] = monitors[side .. ":line7"] + 1
					if monitors[side .. ":line7"] > reactorCount + 3 then
						monitors[side .. ":line7"] = 1
					end
				end
				drawLines()
				save_config()
			end

			if monitors[side .. ":amount"] >= 8 and yPos >= monitors[side .. ":y"] + 58 and yPos <= monitors[side .. ":y"] + 62 then
				if xPos >= 1 and xPos <= 5 then
					monitors[side .. ":line8"] = monitors[side .. ":line8"] - 1
					if monitors[side .. ":line8"] < 1 then
						monitors[side .. ":line8"] = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitors[side .. ":line8"] = monitors[side .. ":line8"] + 1
					if monitors[side .. ":line8"] > reactorCount + 3 then
						monitors[side .. ":line8"] = 1
					end
				end
				drawLines()
				save_config()
			end

			if monitors[side .. ":amount"] >= 9 and yPos >= monitors[side .. ":y"] + 66 and yPos <= monitors[side .. ":y"] + 70 then
				if xPos >= 1 and xPos <= 5 then
					monitors[side .. ":line9"] = monitors[side .. ":line9"] - 1
					if monitors[side .. ":line9"] < 1 then
						monitors[side .. ":line9"] = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitors[side .. ":line9"] = monitors[side .. ":line9"] + 1
					if monitors[side .. ":line9"] > reactorCount + 3 then
						monitors[side .. ":line9"] = 1
					end
				end
				drawLines()
				save_config()
			end

			if monitors[side .. ":amount"] >= 10 and yPos >= monitors[side .. ":y"] + 74 and yPos <= monitors[side .. ":y"] + 78 then
				if xPos >= 1 and xPos <= 5 then
					monitors[side .. ":line10"] = monitors[side .. ":line10"] - 1
					if monitors[side .. ":line10"] < 1 then
						monitors[side .. ":line10"] = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitors[side .. ":line10"] = monitors[side .. ":line10"] + 1
					if monitors[side .. ":line10"] > reactorCount + 3 then
						monitors[side .. ":line10"] = 1
					end
				end
				drawLines()
				save_config()
			end
		end
	end
end

--draw line with information on the monitor
function drawLine(mon, localY, line, drawButtons, side)
	if line == 1 then
		local length = string.len(tostring(generation - drainback))
		local offset = (length * 4) + (2 * gui.getInteger((length - 1) / 3)) + 18
		local x = ((mon.X - offset) / 2) - 1
		gui.draw_number(mon, generation - drainback, x + 17, localY, numberColor)
		gui.draw_rft(mon, x, localY, unitColor)
		if drawButtons then
			gui.drawSideButtons(mon, localY, buttonColor)
			gui.draw_text_lr(mon, 2, localY + 2, 0, "DR" .. reactorCount .. " ", " Gen", textColor, textColor, buttonColor)
		end
	elseif line == 2 then
		local length = string.len(tostring(generation))
		local offset = (length * 4) + (2 * gui.getInteger((length - 1) / 3)) + 18
		local x = ((mon.X - offset) / 2) - 1
		gui.draw_number(mon, generation, x + 17, localY, numberColor)
		gui.draw_rft(mon, x, localY, unitColor)
		if drawButtons then
			gui.drawSideButtons(mon, localY, buttonColor)
			gui.draw_text_lr(mon, 2, localY + 2, 0, "Out ", "Back", textColor, textColor, buttonColor)
		end
	elseif line == 3 then
		local length = string.len(tostring(drainback))
		local offset = (length * 4) + (2 * gui.getInteger((length - 1) / 3)) + 18
		local x = ((mon.X - offset) / 2) - 1
		gui.draw_number(mon, drainback, x + 17, localY, numberColor)
		gui.draw_rft(mon, x, localY, unitColor)
		if drawButtons then
			gui.drawSideButtons(mon, localY, buttonColor)
			gui.draw_text_lr(mon, 2, localY + 2, 0, "Gen ", " DR1", textColor, textColor, buttonColor)
		end
	else
		local length = string.len(tostring(reactorGeneration[line - 3]))
		local offset = (length * 4) + (2 * gui.getInteger((length - 1) / 3)) + 18
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

--get total drainback
function getDrainback()
	local totalDrainback = 0
	for i = 1, reactorCount do
		totalDrainback = totalDrainback + getGateFlow(i)
	end
	return totalDrainback
end

--get generation of one specific reactor
function getReactorGeneration(number)
	local reactor = peripheral.wrap(connectedReactors[number])
	local ri = reactor.getReactorInfo()
	if ri.status == "offline" then
		return 0
	else
		return ri.generationRate
	end
end

--get flow of one specific gate
function getGateFlow(number)
	local gate = peripheral.wrap(connectedGates[number])
	return gate.getSignalLowFlow()
end


-- check that every line displays something
function checkLines()
	for i = 1, monitorCount do
		if monitors[connectedMonitors[i] .. ":line1"] > reactorCount + 3 then
			monitors[connectedMonitors[i] .. ":line1"] = reactorCount + 3
		end
		if monitors[connectedMonitors[i] .. ":line2"] > reactorCount + 3 then
			monitors[connectedMonitors[i] .. ":line2"] = reactorCount + 3
		end
		if monitors[connectedMonitors[i] .. ":line3"] > reactorCount + 3 then
			monitors[connectedMonitors[i] .. ":line3"] = reactorCount + 3
		end
		if monitors[connectedMonitors[i] .. ":line4"] > reactorCount + 3 then
			monitors[connectedMonitors[i] .. ":line4"] = reactorCount + 3
		end
		if monitors[connectedMonitors[i] .. ":line5"] > reactorCount + 3 then
			monitors[connectedMonitors[i] .. ":line5"] = reactorCount + 3
		end
		if monitors[connectedMonitors[i] .. ":line6"] > reactorCount + 3 then
			monitors[connectedMonitors[i] .. ":line6"] = reactorCount + 3
		end
		if monitors[connectedMonitors[i] .. ":line7"] > reactorCount + 3 then
			monitors[connectedMonitors[i] .. ":line7"] = reactorCount + 3
		end
		if monitors[connectedMonitors[i] .. ":line8"] > reactorCount + 3 then
			monitors[connectedMonitors[i] .. ":line8"] = reactorCount + 3
		end
		if monitors[connectedMonitors[i] .. ":line9"] > reactorCount + 3 then
			monitors[connectedMonitors[i] .. ":line9"] = reactorCount + 3
		end
		if monitors[connectedMonitors[i] .. ":line10"] > reactorCount + 3 then
			monitors[connectedMonitors[i] .. ":line10"] = reactorCount + 3
		end
	end
	save_config()
end

--initialize all the values
function init()
	for i = 1, monitorCount do
		local mon, monitor, monX, monY
		monitor = peripheral.wrap(connectedMonitors[i])
		monitor.setTextScale(1)
		monX, monY = monitor.getSize()
		mon = {}
		mon.monitor,mon.X, mon.Y = monitor, monX, monY
		if mon.Y <=	5 or monitors[connectedMonitors[i] .. ":smallFont"] then
			monitor.setTextScale(0.5)
			monX, monY = monitor.getSize()
			mon = {}
			mon.monitor,mon.X, mon.Y = monitor, monX, monY
		end
		local amount = 0
		if mon.Y < 16 then
			amount = 1
			monitors[connectedMonitors[i] .. ":y"] = gui.getInteger((mon.Y - 3) / 2)
		else
			local localY = mon.Y - 2
			local int = 8
			while int <= localY do
				int = int + 8
				amount = amount + 1
			end
			monitors[connectedMonitors[i] .. ":y"] = gui.getInteger((mon.Y + 3 - (8 * amount)) / 2)
		end
		monitors[connectedMonitors[i] .. ":amount"] = amount
	end
end


--run
checkLines()

init()

parallel.waitForAny(buttons, update)
