-- configure colors
local numberColor = colors.red
local unitColor = colors.gray
local buttonColor = colors.lightGray
local textColor = colors.white
-- lower number means higher refresh rate but also increases server load
local refresh = 1

-- program
local version = "1.5.0"
os.loadAPI("lib/gui")
os.loadAPI("lib/color")


local totalEnergy, totalMaxEnergy
local oldEnergy = 0
local coreEnergy = {}
local coreMaxEnergy = {}

local monitorData = {}

local monitorCount = 0
local connectedMonitorNames = {}
local connectedMonitorPeripherals = {}
local coreCount = 0
local connectedCoreNames = {}
local connectedCorePeripherals = {}
local periList = peripheral.getNames()
local validPeripherals = {
	"draconic_rf_storage",
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
		["draconic_rf_storage"] = function()
			coreCount = coreCount + 1
			connectedCoreNames[coreCount] = periList[i]
			connectedCorePeripherals[coreCount] = peripheral.wrap(periList[i])
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
	if isValid then periFunctions[isValid]() end
end

function isnan(x)
	return x ~= x
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
	sw.writeLine("-- just some saved data")
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
	save_config()
end

-- 1st time? save our settings, if not, load our settings
if fs.exists("config.txt") == false then
	save_config()
else
	load_config()
end


--Check for energycore and monitorData before continuing
if coreCount == 0 then
	error("No valid energy core was found")
end

if monitorCount == 0 then
	error("No valid monitor was found")
end


--update the monitor
function update()
	while true do
		drawLines()
		sleep(refresh)
		oldEnergy = totalEnergy
	end
end

--draw the different lines on the screen
function drawLines()
	for i = 1, monitorCount do
		local mon, monitor, monX, monY
		monitor = connectedMonitorPeripherals[i]
		monX, monY = monitor.getSize()
		mon = {}
		mon.monitor,mon.X, mon.Y = monitor, monX, monY

		totalEnergy = getTotalEnergyStored()
		totalMaxEnergy = getTotalMaxEnergyStored()
		gui.clear(mon)
		print("|# Total energy stored: " .. gui.format_int(totalEnergy) .. " RF")
		print("|# Total maximum energy: " .. gui.format_int(totalMaxEnergy) .. " RF")
		print("|# Total free storage: " .. gui.format_int(totalMaxEnergy - totalEnergy) .. " RF")
		print("|# Transfer: " .. (totalEnergy - oldEnergy) / (20 * refresh) .. " RF/t")
		for i = 1, coreCount do
			coreEnergy[i] = getEnergyStored(i)
			coreMaxEnergy[i] = getMaxEnergyStored(i)
			print("|# Energy core " .. i .. " energy stored: " .. gui.format_int(coreEnergy[i]) .. " RF")
			print("|# Energy core " .. i .. " maximum energy: " .. gui.format_int(coreMaxEnergy[i]) .. " RF")
		end

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

--handle the monitor touch inputs
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
						monitorData[side .. ":line1"] = (monitorCount * 6) + 7
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitorData[side .. ":line1"] = monitorData[side .. ":line1"] + 1
					if monitorData[side .. ":line1"] > (monitorCount * 6) + 7 then
						monitorData[side .. ":line1"] = 1
					end
				end
				drawLines()
				save_config()
			end

			if monitorData[side .. ":amount"] >= 2 and yPos >= monitorData[side .. ":y"] + 10 and yPos <= monitorData[side .. ":y"] + 14 then
				if xPos >= 1 and xPos <= 5 then
					monitorData[side .. ":line2"] = monitorData[side .. ":line2"] - 1
					if monitorData[side .. ":line2"] < 1 then
						monitorData[side .. ":line2"] = (monitorCount * 6) + 7
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitorData[side .. ":line2"] = monitorData[side .. ":line2"] + 1
					if monitorData[side .. ":line2"] > (monitorCount * 6) + 7 then
						monitorData[side .. ":line2"] = 1
					end
				end
				drawLines()
				save_config()
			end

			if monitorData[side .. ":amount"] >= 3 and yPos >= monitorData[side .. ":y"] + 18 and yPos <= monitorData[side .. ":y"] + 22 then
				if xPos >= 1 and xPos <= 5 then
					monitorData[side .. ":line3"] = monitorData[side .. ":line3"] - 1
					if monitorData[side .. ":line3"] < 1 then
						monitorData[side .. ":line3"] = (monitorCount * 6) + 7
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitorData[side .. ":line3"] = monitorData[side .. ":line3"] + 1
					if monitorData[side .. ":line3"] > (monitorCount * 6) + 7 then
						monitorData[side .. ":line3"] = 1
					end
				end
				drawLines()
				save_config()
			end

			if monitorData[side .. ":amount"] >= 4 and yPos >= monitorData[side .. ":y"] + 26 and yPos <= monitorData[side .. ":y"] + 30 then
				if xPos >= 1 and xPos <= 5 then
					monitorData[side .. ":line4"] = monitorData[side .. ":line4"] - 1
					if monitorData[side .. ":line4"] < 1 then
						monitorData[side .. ":line4"] = (monitorCount * 6) + 7
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitorData[side .. ":line4"] = monitorData[side .. ":line4"] + 1
					if monitorData[side .. ":line4"] > (monitorCount * 6) + 7 then
						monitorData[side .. ":line4"] = 1
					end
				end
				drawLines()
				save_config()
			end

			if monitorData[side .. ":amount"] >= 5 and yPos >= monitorData[side .. ":y"] + 34 and yPos <= monitorData[side .. ":y"] + 38 then
				if xPos >= 1 and xPos <= 5 then
					monitorData[side .. ":line5"] = monitorData[side .. ":line5"] - 1
					if monitorData[side .. ":line5"] < 1 then
						monitorData[side .. ":line5"] = (monitorCount * 6) + 7
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitorData[side .. ":line5"] = monitorData[side .. ":line5"] + 1
					if monitorData[side .. ":line5"] > (monitorCount * 6) + 7 then
						monitorData[side .. ":line5"] = 1
					end
				end
				drawLines()
				save_config()
			end

			if monitorData[side .. ":amount"] >= 6 and yPos >= monitorData[side .. ":y"] + 42 and yPos <= monitorData[side .. ":y"] + 46 then
				if xPos >= 1 and xPos <= 5 then
					monitorData[side .. ":line6"] = monitorData[side .. ":line6"] - 1
					if monitorData[side .. ":line6"] < 1 then
						monitorData[side .. ":line6"] = (monitorCount * 6) + 7
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitorData[side .. ":line6"] = monitorData[side .. ":line6"] + 1
					if monitorData[side .. ":line6"] > (monitorCount * 6) + 7 then
						monitorData[side .. ":line6"] = 1
					end
				end
				drawLines()
				save_config()
			end

			if monitorData[side .. ":amount"] >= 7 and yPos >= monitorData[side .. ":y"] + 50 and yPos <= monitorData[side .. ":y"] + 54 then
				if xPos >= 1 and xPos <= 5 then
					monitorData[side .. ":line7"] = monitorData[side .. ":line7"] - 1
					if monitorData[side .. ":line7"] < 1 then
						monitorData[side .. ":line7"] = (monitorCount * 6) + 7
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitorData[side .. ":line7"] = monitorData[side .. ":line7"] + 1
					if monitorData[side .. ":line7"] > (monitorCount * 6) + 7 then
						monitorData[side .. ":line7"] = 1
					end
				end
				drawLines()
				save_config()
			end

			if monitorData[side .. ":amount"] >= 8 and yPos >= monitorData[side .. ":y"] + 58 and yPos <= monitorData[side .. ":y"] + 62 then
				if xPos >= 1 and xPos <= 5 then
					monitorData[side .. ":line8"] = monitorData[side .. ":line8"] - 1
					if monitorData[side .. ":line8"] < 1 then
						monitorData[side .. ":line8"] = (monitorCount * 6) + 7
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitorData[side .. ":line8"] = monitorData[side .. ":line8"] + 1
					if monitorData[side .. ":line8"] > (monitorCount * 6) + 7 then
						monitorData[side .. ":line8"] = 1
					end
				end
				drawLines()
				save_config()
			end

			if monitorData[side .. ":amount"] >= 9 and yPos >= monitorData[side .. ":y"] + 66 and yPos <= monitorData[side .. ":y"] + 70 then
				if xPos >= 1 and xPos <= 5 then
					monitorData[side .. ":line9"] = monitorData[side .. ":line9"] - 1
					if monitorData[side .. ":line9"] < 1 then
						monitorData[side .. ":line9"] = (monitorCount * 6) + 7
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitorData[side .. ":line9"] = monitorData[side .. ":line9"] + 1
					if monitorData[side .. ":line9"] > (monitorCount * 6) + 7 then
						monitorData[side .. ":line9"] = 1
					end
				end
				drawLines()
				save_config()
			end

			if monitorData[side .. ":amount"] >= 10 and yPos >= monitorData[side .. ":y"] + 74 and yPos <= monitorData[side .. ":y"] + 78 then
				if xPos >= 1 and xPos <= 5 then
					monitorData[side .. ":line10"] = monitorData[side .. ":line10"] - 1
					if monitorData[side .. ":line10"] < 1 then
						monitorData[side .. ":line10"] = (monitorCount * 6) + 7
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					monitorData[side .. ":line10"] = monitorData[side .. ":line10"] + 1
					if monitorData[side .. ":line10"] > (monitorCount * 6) + 7 then
						monitorData[side .. ":line10"] = 1
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
		local length = string.len(tostring(totalEnergy))
		local offset = (length * 4) + (2 * gui.getInteger((length - 1) / 3)) + 9
		local x = ((mon.X - offset) / 2) - 1
		gui.draw_number(mon, totalEnergy, x + 9, localY, numberColor, unitColor)
		gui.draw_rf(mon, x, localY, unitColor)
		if drawButtons then
			gui.drawSideButtons(mon, localY, buttonColor)
			gui.draw_text_lr(mon, 2, localY + 2, 0, "EC" .. coreCount .. " ", " Max", textColor, textColor, buttonColor)
		end
	elseif line == 2 then
		local length = string.len(tostring(totalMaxEnergy))
		local offset = (length * 4) + (2 * gui.getInteger((length - 1) / 3)) + 9
		local x = ((mon.X - offset) / 2) - 1
		gui.draw_number(mon, totalMaxEnergy, x + 9, localY, numberColor)
		gui.draw_rf(mon, x, localY, unitColor)
		if drawButtons then
			gui.drawSideButtons(mon, localY, buttonColor)
			gui.draw_text_lr(mon, 2, localY + 2, 0, "Ener", "Cent", textColor, textColor, buttonColor)
		end
	elseif line == 3 then
		local delimeter = (1000 ^ (gui.getInteger((string.len(tostring(totalEnergy))) - 1) / 3)) / 100
		local energy = gui.getInteger(totalEnergy / delimeter) / 100
		local maxDelimeter = (1000 ^ (gui.getInteger((string.len(tostring(totalMaxEnergy))) - 1) / 3)) / 100
		local maxEnergy = gui.getInteger(totalMaxEnergy / maxDelimeter) / 100
		local length = string.len(tostring(energy)) + string.len(tostring(maxEnergy)) - 1
		local offset = (length * 4) + (2 * gui.getInteger((length - 3) / 3)) + 22
		local x = ((mon.X - offset) / 2)

		gui.draw_number(mon, energy, x + 39, localY, numberColor)
		gui.draw_si(mon, x + 33, localY, string.len(tostring(gui.getInteger(totalEnergy))), unitColor)

		gui.draw_slash(mon, x + 28, localY, unitColor)
		gui.draw_number(mon, maxEnergy, x + 15, localY, numberColor)
		gui.draw_si(mon, x + 9, localY, string.len(tostring(gui.getInteger(totalMaxEnergy))), unitColor)

		gui.draw_rf(mon, x, localY, unitColor)
		if drawButtons then
			gui.drawSideButtons(mon, localY, buttonColor)
		end
	elseif line == 4 then
		local energyPercent = math.ceil(totalEnergy / totalMaxEnergy * 10000)*.01
		if energyPercent == math.huge or isnan(energyPercent) then
			energyPercent = 0
		end
		local length = string.len(tostring(energyPercent))
		local offset = (length * 4) + (2 * gui.getInteger((length - 1) / 3)) + 9
		local x = ((mon.X - offset) / 2) - 1
		gui.draw_number(mon, energyPercent , x + 7, localY, numberColor)
		gui.draw_percent(mon, x, localY, numberColor)
		if drawButtons then
			gui.drawSideButtons(mon, localY, buttonColor)
			gui.draw_text_lr(mon, 2, localY + 2, 0, "Max ", " Bar", textColor, textColor, buttonColor)
		end
	elseif line == 5 then
		local length
		if drawButtons then
			length = mon.X - 12
		else
			length = mon.X - 2
		end
		local x = ((mon.X - length) / 2) - 1
		local energyPercent = math.ceil(totalEnergy / totalMaxEnergy * 10000)*.01
		if energyPercent == math.huge or isnan(energyPercent) then
			energyPercent = 0
		end
		local energyColor = colors.red
		if energyPercent >= 70 then
			energyColor = colors.green
		elseif energyPercent < 70 and energyPercent > 30 then
			energyColor = colors.orange
		end

		gui.progress_bar(mon, x + 2, localY, length, totalEnergy, totalMaxEnergy, energyColor, colors.lightGray)
		gui.progress_bar(mon, x + 2, localY + 1, length, totalEnergy, totalMaxEnergy, energyColor, colors.lightGray)
		gui.progress_bar(mon, x + 2, localY + 2, length, totalEnergy, totalMaxEnergy, energyColor, colors.lightGray)
		gui.progress_bar(mon, x + 2, localY + 3, length, totalEnergy, totalMaxEnergy, energyColor, colors.lightGray)
		gui.progress_bar(mon, x + 2, localY + 4, length, totalEnergy, totalMaxEnergy, energyColor, colors.lightGray)
		if drawButtons then
			gui.drawSideButtons(mon, localY, buttonColor)
			gui.draw_text_lr(mon, 2, localY + 2, 0, "Cent", "Flow", textColor, textColor, buttonColor)
		end
	elseif line == 6 then
		local flow = (totalEnergy - oldEnergy) / (20 * refresh)
		local length = string.len(tostring(flow))
		local offset = (length * 4) + (2 * gui.getInteger((length - 1) / 3)) + 17
		local x = ((mon.X - offset) / 2) - 1
		
		gui.draw_number(mon, flow, x + 17, localY, numberColor)
		gui.draw_rft(mon, x, localY, unitColor)
		if drawButtons then
			gui.drawSideButtons(mon, localY, buttonColor)
			gui.draw_text_lr(mon, 2, localY + 2, 0, "Gen ", "Count", textColor, textColor, buttonColor)
		end
	elseif line == 7 then
		local length = string.len(tostring(coreCount))
		local offset = (length * 4) + (2 * gui.getInteger((length - 1) / 3)) + 22
		local x = ((mon.X - offset) / 2)

		gui.draw_cores(mon, x + 1, localY, unitColor)
		gui.draw_number(mon, coreCount, x - 1, localY, numberColor)
		if drawButtons then
			gui.drawSideButtons(mon, localY, buttonColor)
			gui.draw_text_lr(mon, 2, localY + 2, 0, "Flow", " EC1", textColor, textColor, buttonColor)
		end
	else
		if gui.getModulo(line - 7, 6) == 1 then
			local length = string.len(tostring(coreEnergy[1 + (line - 8) / 6]))
			local offset = (length * 4) + (2 * gui.getInteger((length - 1) / 3)) + 9
			local x = ((mon.X - offset) / 2) - 1
			gui.draw_number(mon, coreEnergy[1 + (line - 8) / 6], x + 9, localY, numberColor)
			gui.draw_rf(mon, x, localY, unitColor)
			if drawButtons then
				gui.drawSideButtons(mon, localY, buttonColor)
				if line == 8 then
					gui.draw_text_lr(mon, 2, localY + 2, 0, "Count", " EC1", textColor, textColor, buttonColor)
				else
					gui.draw_text_lr(mon, 2, localY + 2, 0, "EC" .. (line - 8) / 6 .. " ", " EC" .. 1 + ((line - 8) / 6), textColor, textColor, buttonColor)
				end
			end
		elseif gui.getModulo(line - 7, 6) == 2 then
			local length = string.len(tostring(coreMaxEnergy[1 + ((line - 9) / 6)]))
			local offset = (length * 4) + (2 * gui.getInteger((length - 1) / 3)) + 9
			local x = ((mon.X - offset) / 2) - 1
			gui.draw_number(mon, coreMaxEnergy[1 + ((line - 9) / 6)], x + 9, localY, numberColor)
			gui.draw_rf(mon, x, localY, unitColor)
			if drawButtons then
				gui.drawSideButtons(mon, localY, buttonColor)
				gui.draw_text_lr(mon, 2, localY + 2, 0, "EC" .. 1 + ((line - 9) / 6) .. " ", " EC" .. 1 + ((line - 9) / 6), textColor, textColor, buttonColor)
			end
		elseif gui.getModulo(line - 7, 6) == 3 then
			local delimeter = (1000 ^ (gui.getInteger((string.len(tostring(coreEnergy[1 + ((line - 10) / 6)]))) - 1) / 3)) / 100
			local energy = gui.getInteger(coreEnergy[1 + ((line - 10) / 6)] / delimeter) / 100
			local maxDelimeter = (1000 ^ (gui.getInteger((string.len(tostring(coreMaxEnergy[1 + ((line - 10) / 6)]))) - 1) / 3)) / 100
			local maxEnergy = gui.getInteger(coreMaxEnergy[1 + ((line - 10) / 6)] / maxDelimeter) / 100
			local length = string.len(tostring(energy)) + string.len(tostring(maxEnergy)) - 1
			local offset = (length * 4) + (2 * gui.getInteger((length - 3) / 3)) + 22
			local x = ((mon.X - offset) / 2)

			gui.draw_number(mon, energy, x + 39, localY, numberColor)
			gui.draw_si(mon, x + 33, localY, string.len(tostring(gui.getInteger(coreEnergy[1 + ((line - 10) / 6)]))), unitColor)
			
			gui.draw_slash(mon, x + 28, localY, unitColor)
			gui.draw_number(mon, maxEnergy, x + 15, localY, numberColor)
			gui.draw_si(mon, x + 9, localY, string.len(tostring(gui.getInteger(coreMaxEnergy[1 + ((line - 10) / 6)]))), unitColor)
			
			gui.draw_rf(mon, x, localY, unitColor)
			if drawButtons then
				gui.drawSideButtons(mon, localY, buttonColor)
				gui.draw_text_lr(mon, 2, localY + 2, 0, "EC" .. 1 + ((line - 10) / 6) .. " ", " EC" .. 1 + ((line - 10) / 6), textColor, textColor, buttonColor)
			end
		elseif gui.getModulo(line - 7, 6) == 4 then
			local energyPercent = math.ceil(coreEnergy[1 + ((line - 11) / 6)] / coreMaxEnergy[1 + ((line - 11) / 6)] * 10000)*.01
			if energyPercent == math.huge or isnan(energyPercent) then
				energyPercent = 0
			end
			local length = string.len(tostring(energyPercent))
			local offset = (length * 4) + (2 * gui.getInteger((length - 1) / 3)) + 9
			local x = ((mon.X - offset) / 2) - 1
			gui.draw_number(mon, energyPercent, x + 7, localY, numberColor)
			gui.draw_percent(mon, x, localY, numberColor)
			if drawButtons then
				gui.drawSideButtons(mon, localY, buttonColor)
				gui.draw_text_lr(mon, 2, localY + 2, 0, "EC" .. 1 + ((line - 11) / 6) .. " ", " EC" .. 1 + ((line - 11) / 6), textColor, textColor, buttonColor)

			end
		elseif gui.getModulo(line - 7, 6) == 5 then
			local length
			if drawButtons then
				length = mon.X - 12
			else
				length = mon.X - 2
			end
			local x = ((mon.X - length) / 2) - 1
			local energyPercent = math.ceil(coreEnergy[1 + ((line - 12) / 6)] / coreMaxEnergy[1 + ((line - 12) / 6)] * 10000)*.01
			if energyPercent == math.huge or isnan(energyPercent) then
				energyPercent = 0
			end
			local energyColor = colors.red
			if energyPercent >= 70 then
				energyColor = colors.green
			elseif energyPercent < 70 and energyPercent > 30 then
				energyColor = colors.orange
			end
			gui.progress_bar(mon, x + 2, localY, length, coreEnergy[1 + ((line - 12) / 6)], coreMaxEnergy[1 + ((line - 12) / 6)], energyColor, colors.lightGray)
			gui.progress_bar(mon, x + 2, localY + 1, length, coreEnergy[1 + ((line - 12) / 6)], coreMaxEnergy[1 + ((line - 12) / 6)], energyColor, colors.lightGray)
			gui.progress_bar(mon, x + 2, localY + 2, length, coreEnergy[1 + ((line - 12) / 6)], coreMaxEnergy[1 + ((line - 12) / 6)], energyColor, colors.lightGray)
			gui.progress_bar(mon, x + 2, localY + 3, length, coreEnergy[1 + ((line - 12) / 6)], coreMaxEnergy[1 + ((line - 12) / 6)], energyColor, colors.lightGray)
			gui.progress_bar(mon, x + 2, localY + 4, length, coreEnergy[1 + ((line - 12) / 6)], coreMaxEnergy[1 + ((line - 12) / 6)], energyColor, colors.lightGray)
			if drawButtons then
				gui.drawSideButtons(mon, localY, buttonColor)
				gui.draw_text_lr(mon, 2, localY + 2, 0, "EC" .. 1 + ((line - 12) / 6) .. " ", " EC" .. 1 + ((line - 12) / 6), textColor, textColor, buttonColor)
			end
		elseif gui.getModulo(line - 7, 6) == 0 then
			local tier
			if coreMaxEnergy[(line - 7) / 6] == 45500000 then
				tier = 1
			elseif coreMaxEnergy[(line - 7) / 6] == 273000000 then
				tier = 2
			elseif coreMaxEnergy[(line - 7) / 6] == 1640000000 then
				tier = 3
			elseif coreMaxEnergy[(line - 7) / 6] == 9880000000 then
				tier = 4
			elseif coreMaxEnergy[(line - 7) / 6] == 59300000000 then
				tier = 5
			elseif coreMaxEnergy[(line - 7) / 6] == 356000000000 then
				tier = 6
			elseif coreMaxEnergy[(line - 7) / 6] == 2140000000000 then
				tier = 7
			end
			local length = string.len(tostring(tier))
			local offset = (length * 4) + 19
			local x = ((mon.X - offset) / 2)


			gui.draw_tier(mon, x + 2, localY, unitColor)
			if length == 1 then
				x = x + 1
			end
			gui.draw_number(mon, tier, x - 1, localY, numberColor)
			if drawButtons then
				gui.drawSideButtons(mon, localY, buttonColor)
				if line == (monitorCount * 6) + 7 then
					gui.draw_text_lr(mon, 2, localY + 2, 0, "EC" .. ((line - 7) / 6) .. " ", "Ener", textColor, textColor, buttonColor)
				else
					gui.draw_text_lr(mon, 2, localY + 2, 0, "EC" .. ((line - 7) / 6) .. " ", " EC" .. ((line - 7) / 6), textColor, textColor, buttonColor)
				end
			end
		end
	end
end


function getTotalMaxEnergyStored()
	local totalMaxEnergy = 0
	for i = 1, coreCount do
		totalMaxEnergy = totalMaxEnergy + getMaxEnergyStored(i)
	end
	return totalMaxEnergy
end

function getTotalEnergyStored()
	local totalEnergy = 0
	for i = 1, coreCount do
		totalEnergy = totalEnergy + getEnergyStored(i)
	end
	return totalEnergy
end

function getMaxEnergyStored(number)
	local core = connectedCorePeripherals[number]
	return core.getMaxEnergyStored()
end

function getEnergyStored(number)
	local core = connectedCorePeripherals[number]
	return core.getEnergyStored()
end

-- check that every line displays something
function checkLines()
	for i = 1, monitorCount do
		if monitorData[connectedMonitorNames[i] .. ":line1"] > (monitorCount * 6) + 7 then
			monitorData[connectedMonitorNames[i] .. ":line1"] = (monitorCount * 6) + 7
		end
		if monitorData[connectedMonitorNames[i] .. ":line2"] > (monitorCount * 6) + 7 then
			monitorData[connectedMonitorNames[i] .. ":line2"] = (monitorCount * 6) + 7
		end
		if monitorData[connectedMonitorNames[i] .. ":line3"] > (monitorCount * 6) + 7 then
			monitorData[connectedMonitorNames[i] .. ":line3"] = (monitorCount * 6) + 7
		end
		if monitorData[connectedMonitorNames[i] .. ":line4"] > (monitorCount * 6) + 7 then
			monitorData[connectedMonitorNames[i] .. ":line4"] = (monitorCount * 6) + 7
		end
		if monitorData[connectedMonitorNames[i] .. ":line5"] > (monitorCount * 6) + 7 then
			monitorData[connectedMonitorNames[i] .. ":line5"] = (monitorCount * 6) + 7
		end
		if monitorData[connectedMonitorNames[i] .. ":line6"] > (monitorCount * 6) + 7 then
			monitorData[connectedMonitorNames[i] .. ":line6"] = (monitorCount * 6) + 7
		end
		if monitorData[connectedMonitorNames[i] .. ":line7"] > (monitorCount * 6) + 7 then
			monitorData[connectedMonitorNames[i] .. ":line7"] = (monitorCount * 6) + 7
		end
		if monitorData[connectedMonitorNames[i] .. ":line8"] > (monitorCount * 6) + 7 then
			monitorData[connectedMonitorNames[i] .. ":line8"] = (monitorCount * 6) + 7
		end
		if monitorData[connectedMonitorNames[i] .. ":line9"] > (monitorCount * 6) + 7 then
			monitorData[connectedMonitorNames[i] .. ":line9"] = (monitorCount * 6) + 7
		end
		if monitorData[connectedMonitorNames[i] .. ":line10"] > (monitorCount * 6) + 7 then
			monitorData[connectedMonitorNames[i] .. ":line10"] = (monitorCount * 6) + 7
		end
	end
	save_config()
end

--initialize all the values
function init()
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
			monitorData[connectedMonitorNames[i] .. ":y"] = gui.getInteger((mon.Y - 3) / 2)
		else
			local localY = mon.Y - 2
			local int = 8
			while int <= localY do
				int = int + 8
				amount = amount + 1
			end
			monitorData[connectedMonitorNames[i] .. ":y"] = gui.getInteger((mon.Y + 3 - (8 * amount)) / 2)
		end
		monitorData[connectedMonitorNames[i] .. ":amount"] = amount
	end
end

--run
checkLines()

init()

parallel.waitForAny(buttons, update)