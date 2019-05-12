-- configure colors
local numberColor = colors.red
local rftColor = colors.gray
local buttonColor = colors.lightGray
-- lower number means higher refresh rate but also increases server load
local refresh = 1

-- program
local version = "1.2.0"
local mon, monitor, monX, monY
os.loadAPI("lib/gui")
os.loadAPI("lib/color")

-- max size: 70x40(8 blocks x 6 blocks)
monitor = peripheral.find("monitor")
monX, monY = monitor.getSize()
mon = {}
mon.monitor,mon.X, mon.Y = monitor, monX, monY

local x
local y

local line1 = 1
local line2 = 2
local line3 = 3
local line4 = 4

local reactorCount = 0
local gateCount = 0
local connectedReactors = {}
local connectedGates = {}
local periList = peripheral.getNames()
local validPeripherals = {
	"draconic_reactor",
	"flux_gate"
}

function split(string, delimiter)
	local result = { }
	local from = 1
	local delim_from, delim_to = string.find( string, delimiter, from )
	while delim_from do
		table.insert( result, string.sub( string, from , delim_from-1 ) )
		from = delim_to + 1
		delim_from, delim_to = string.find( string, delimiter, from )
	end
	table.insert( result, string.sub( string, from ) )
	return result
end

--write settings to config file
function save_config()
	local sw = fs.open("config.txt", "w")
	sw.writeLine("-- Config for Draconig Reactor Generation Overview")
	sw.writeLine("version: " .. version	)
	sw.writeLine(" ")
	sw.writeLine("-- configure the display numberColors")
	sw.writeLine("numberColor: " .. color.toString(numberColor))
	sw.writeLine("rftColor: " .. color.toString(rftColor))
	sw.writeLine("buttonColor: " ..  color.toString(buttonColor))
	sw.writeLine(" ")
	sw.writeLine("-- lower number means higher refresh rate but also increases server load")
	sw.writeLine("refresh: " ..  refresh)
	sw.writeLine(" ")
	sw.writeLine("-- just some saved data")
	sw.writeLine("line1: " .. line1)
	sw.writeLine("line2: " .. line2)
	sw.writeLine("line3: " .. line3)
	sw.close()
end

--read settings from file
function load_config()
	local sr = fs.open("config.txt", "r")
	local curVersion
	local line = sr.readLine()
	while line do
		if split(line, ": ")[1] == "version" then
			curVersion = split(line, ": ")[2]
		elseif split(line, ": ")[1] == "numberColor" then
			numberColor = color.getColor(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "rftnumberColor" then
			rftColor = color.getColor(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "buttonnumberColor" then
			buttonColor = color.getColor(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "refresh" then
			refresh = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "line1" then
			line1 = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "line2" then
			line2 = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "line3" then
			line3 = tonumber(split(line, ": ")[2])
		end
		line = sr.readLine()
	end
	sr.close()
	if curVersion ~= version then
		save_config()
	end
end

-- 1st time? save our settings, if not, load our settings
if fs.exists("config.txt") == false then
	save_config()
else
	load_config()
end


-- get all connected reactors
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
		end
	}

	local isValid = checkValidity(peripheral.getType(v))
	if isValid then periFunctions[isValid]() end
end

--Check for storage cells and monitors before continuing
if reactorCount == 0 then
	error("No valid reactor was found")
end
if reactorCount ~= gateCount then
	error("Not same amount of flux gates as reactors")
end

if monitor == null then
	error("No valid monitor was found")
end


function drawLines(amount, drawbuttons)
	x = gui.getInteger((mon.X - 46) / 2) + 1
	while true do
		gui.clear(mon)
		print("Total reactor output: " .. gui.format_int(getGeneration() - getDrainback()))
		print("Total generation: " .. gui.format_int(getGeneration()))
		for i = 1, reactorCount do
			print("Reactor " .. i .. " Generation: " .. gui.format_int(getReactorGeneration(i)))
		end
		print("Total drainback: " .. gui.format_int(getDrainback()))
		if amount >= 1 then
			drawLine(y, line1, drawbuttons)
		end
		if amount >= 2 then
			gui.draw_line(mon, 0, y+7, mon.X+1, colors.gray)
			drawLine(y + 10, line2, drawbuttons)
		end
		if amount >= 3 then
			drawLine(y + 18, line3, drawbuttons)
		end
		if amount >= 4 then
			drawLine(y + 26, line4, drawbuttons)
		end
		sleep(refresh)
	end
end

function buttons(amount)
	if amount >= 1 then
		while true do
			-- button handler
			local event, side, xPos, yPos = os.pullEvent("monitor_touch")

			if  yPos >= y and yPos <= y + 4 then
				if xPos >= 1 and xPos <= 5 then
					line1 = line1 - 1
					if line1 < 1 then
						line1 = reactorCount
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					line1 = line1 + 1
					if line1 > reactorCount then
						line1 = 1
					end
				end
				drawLine(y, line1, true)
			end
		end
	end
	if amount >= 2 then
		while true do
			-- button handler
			local event, side, xPos, yPos = os.pullEvent("monitor_touch")

			if  yPos >= y and yPos <= y + 4 then
				if xPos >= 1 and xPos <= 5 then
					line1 = line1 - 1
					if line1 < 1 then
						line1 = reactorCount
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					line1 = line1 + 1
					if line1 > reactorCount then
						line1 = 1
					end
				end
				drawLine(y, line1, true)
			end

			if  yPos >= y + 10 and yPos <= y + 14 then
				if xPos >= 1 and xPos <= 5 then
					line2 = line2 - 1
					if line2 < 1 then
						line2 = reactorCount
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					line2 = line2 + 1
					if line2 > reactorCount then
						line2 = 1
					end
				end
				drawLine(y + 10, line2, true)
			end
		end
	end
	if amount >= 3 then
		while true do
			-- button handler
			local event, side, xPos, yPos = os.pullEvent("monitor_touch")

			if  yPos >= y and yPos <= y + 4 then
				if xPos >= 1 and xPos <= 5 then
					line1 = line1 - 1
					if line1 < 1 then
						line1 = reactorCount
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					line1 = line1 + 1
					if line1 > reactorCount then
						line1 = 1
					end
				end
				drawLine(y, line1, true)
			end

			if  yPos >= y + 10 and yPos <= y + 14 then
				if xPos >= 1 and xPos <= 5 then
					line2 = line2 - 1
					if line2 < 1 then
						line2 = reactorCount
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					line2 = line2 + 1
					if line2 > reactorCount then
						line2 = 1
					end
				end
				drawLine(y + 10, line2, true)
			end

			if  yPos >= y + 18 and yPos <= y + 22 then
				if xPos >= 1 and xPos <= 5 then
					line3 = line3 - 1
					if line3 < 1 then
						line3 = reactorCount
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					line3 = line3 + 1
					if line3 > reactorCount then
						line3 = 1
					end
				end
				drawLine(y + 18, line3, true)
			end
		end
	end
	if amount >= 4 then
		while true do
			-- button handler
			local event, side, xPos, yPos = os.pullEvent("monitor_touch")

			if  yPos >= y and yPos <= y + 4 then
				if xPos >= 1 and xPos <= 5 then
					line1 = line1 - 1
					if line1 < 1 then
						line1 = reactorCount
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					line1 = line1 + 1
					if line1 > reactorCount then
						line1 = 1
					end
				end
				drawLine(y, line1, true)
			end

			if  yPos >= y + 10 and yPos <= y + 14 then
				if xPos >= 1 and xPos <= 5 then
					line2 = line2 - 1
					if line2 < 1 then
						line2 = reactorCount
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					line2 = line2 + 1
					if line2 > reactorCount then
						line2 = 1
					end
				end
				drawLine(y + 10, line2, true)
			end

			if  yPos >= y + 18 and yPos <= y + 22 then
				if xPos >= 1 and xPos <= 5 then
					line3 = line3 - 1
					if line3 < 1 then
						line3 = reactorCount
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					line3 = line3 + 1
					if line3 > reactorCount then
						line3 = 1
					end
				end
				drawLine(y + 18, line3, true)
			end

			if  yPos >= y + 26 and yPos <= y + 30 then
				if xPos >= 1 and xPos <= 5 then
					line4 = line4 - 1
					if line4 < 1 then
						line4 = reactorCount
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					line4 = line4 + 1
					if line4 > reactorCount then
						line4 = 1
					end
				end
				drawLine(y + 26, line4, true)
			end
		end
	end
end

function drawLine(localY, line, drawButtons)
	if line == 1 then
		gui.draw_number(mon, getGeneration() - getDrainback(), x, localY, numberColor, rftColor)
		if drawButtons then
			gui.drawSideButtons(mon, x, localY, buttonColor)
			gui.draw_text_lr(mon, 2, localY + 2, 0, "DR" .. reactorCount .. " ", " Gen", colors.white, colors.white, buttonColor)
		end
	elseif line == 2 then
		gui.draw_number(mon, getGeneration(), x, localY, numberColor, rftColor)
		if drawButtons then
			gui.drawSideButtons(mon, x, localY, buttonColor)
			gui.draw_text_lr(mon, 2, localY + 2, 0, "Out ", "Back", colors.white, colors.white, buttonColor)
		end
	elseif line == 3 then
		gui.draw_number(mon, getDrainback(), x, localY, numberColor, rftColor)
		if drawButtons then
			gui.drawSideButtons(mon, x, localY, buttonColor)
			gui.draw_text_lr(mon, 2, localY + 2, 0, "Gen ", " DR1", colors.white, colors.white, buttonColor)
		end
	else
		for i = 1, reactorCount do
			if line == i + 3 then
				gui.draw_number(mon, getReactorGeneration(i), x, localY, numberColor, rftColor)
				if drawButtons then
					gui.drawSideButtons(mon, x, localY, buttonColor)
					if line == 4 then
						gui.draw_text_lr(mon, 2, localY + 2, 0, "Back", "DR" .. i + 1 .. " ", colors.white, colors.white, buttonColor)
					elseif line == reactorCount then
						gui.draw_text_lr(mon, 2, localY + 2, 0, "DR" .. i - 1 .. " ", " Out", colors.white, colors.white, buttonColor)
					else
						gui.draw_text_lr(mon, 2, localY + 2, 0, "DR" .. i - 1 .. " ", "DR" .. i + 1 .. " ", colors.white, colors.white, buttonColor)
					end
				end
			end
		end
	end
end


function getGeneration()
	local totalGeneration = 0
	for i = 1, reactorCount do
		totalGeneration = totalGeneration + getReactorGeneration(i)
	end
	return totalGeneration
end

function getDrainback()
	local totalDrainback = 0
	for i = 1, reactorCount do
		totalDrainback = totalDrainback + getGateFlow(i)
	end
	return totalDrainback
end

function getReactorGeneration(number)
	local reactor = peripheral.wrap(connectedReactors[number])
	local ri = reactor.getReactorInfo()
	if ri.status == "offline" then
		return 0
	else
		return ri.generationRate
	end
end

function getGateFlow(number)
	local gate = peripheral.wrap(connectedGates[number])
	return gate.getSignalLowFlow()
end


if mon.X >= 57 then
	if mon.Y < 16 then
		y = gui.getInteger((mon.Y - 6) / 2)
		parallel.waitForAny(buttons(1), drawLines(1, true))
	elseif mon.Y >= 16 and mon.Y < 24 then
		y = gui.getInteger((mon.Y - 14) / 2)
		parallel.waitForAny(buttons(2), drawLines(2, true))
	elseif mon.Y >= 24 and mon.Y < 32 then
		y = gui.getInteger((mon.Y - 22) / 2)
		parallel.waitForAny(buttons(3), drawLines(3, true))
	else
		y = gui.getInteger((mon.Y - 30) / 2)
		parallel.waitForAny(buttons(4), drawLines(4, true))
	end
else
	if mon.Y < 16 then
		y = gui.getInteger((mon.Y - 6) / 2)
		drawLines(1, false)
	elseif mon.Y >= 16 and mon.Y < 24 then
		y = gui.getInteger((mon.Y - 14) / 2)
		drawLines(2, false)
	elseif mon.Y >= 24 and mon.Y < 32 then
		y = gui.getInteger((mon.Y - 22) / 2)
		drawLines(2, false)
	else
		y = gui.getInteger((mon.Y - 30) / 2)
		drawLines(2, false)
	end
end