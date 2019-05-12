-- configure colors
local numberColor = colors.red
local rftColor = colors.gray
local buttonColor = colors.lightGray
local textColor = colors.white
-- lower number means higher refresh rate but also increases server load
local refresh = 1

-- program
local version = "1.3.0"
local mon, monitor, monX, monY
os.loadAPI("lib/gui")
os.loadAPI("lib/color")

-- max size: 70x40(8 blocks x 6 blocks)
monitor = peripheral.find("monitor")
monX, monY = monitor.getSize()
mon = {}
mon.monitor,mon.X, mon.Y = monitor, monX, monY

local x, y

local line1 = 1
local line2 = 2
local line3 = 3
local line4 = 4

local amount, drawButtons

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
	sw.writeLine("textColor: " ..  color.toString(textColor))
	sw.writeLine(" ")
	sw.writeLine("-- lower number means higher refresh rate but also increases server load")
	sw.writeLine("refresh: " ..  refresh)
	sw.writeLine(" ")
	sw.writeLine("-- just some saved data")
	sw.writeLine("line1: " .. line1)
	sw.writeLine("line2: " .. line2)
	sw.writeLine("line3: " .. line3)
	sw.writeLine("line4: " .. line4)
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
		elseif split(line, ": ")[1] == "rftColor" then
			rftColor = color.getColor(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "buttonColor" then
			buttonColor = color.getColor(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "textColor" then
			textColor = color.getColor(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "refresh" then
			refresh = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "line1" then
			line1 = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "line2" then
			line2 = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "line3" then
			line3 = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "line4" then
			line4 = tonumber(split(line, ": ")[2])
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

--Check for reactor, fluxgates and monitors before continuing
if reactorCount == 0 then
	error("No valid reactor was found")
end
if reactorCount ~= gateCount then
	error("Not same amount of flux gates as reactors")
end

if monitor == null then
	error("No valid monitor was found")
end


--update the monitor
function update()
	x = gui.getInteger((mon.X - 46) / 2) - 1
	while true do
		drawLines()
		sleep(refresh)
	end
end

--draw the different lines on the screen
function drawLines()
	gui.clear(mon)
	print("Total reactor output: " .. gui.format_int(getGeneration() - getDrainback()))
	print("Total generation: " .. gui.format_int(getGeneration()))
	for i = 1, reactorCount do
		print("Reactor " .. i .. " Generation: " .. gui.format_int(getReactorGeneration(i)))
	end
	print("Total drainback: " .. gui.format_int(getDrainback()))
	if amount >= 1 then
		drawLine(y, line1, drawButtons)
	end
	if amount >= 2 then
		gui.draw_line(mon, 0, y+7, mon.X+1, colors.gray)
		drawLine(y + 10, line2, drawButtons)
	end
	if amount >= 3 then
		drawLine(y + 18, line3, drawButtons)
	end
	if amount >= 4 then
		drawLine(y + 26, line4, drawButtons)
	end
end

--handle the monitor touch inputs
function buttons()
	if amount == 1 then
		while true do
			-- button handler
			local event, side, xPos, yPos = os.pullEvent("monitor_touch")

			if  yPos >= y and yPos <= y + 4 then
				if xPos >= 1 and xPos <= 5 then
					line1 = line1 - 1
					if line1 < 1 then
						line1 = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					line1 = line1 + 1
					if line1 > reactorCount + 3 then
						line1 = 1
					end
				end
				drawLines()
			end
		end
	end
	if amount == 2 then
		while true do
			-- button handler
			local event, side, xPos, yPos = os.pullEvent("monitor_touch")

			if  yPos >= y and yPos <= y + 4 then
				if xPos >= 1 and xPos <= 5 then
					line1 = line1 - 1
					if line1 < 1 then
						line1 = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					line1 = line1 + 1
					if line1 > reactorCount + 3 then
						line1 = 1
					end
				end
				drawLines()
			end

			if  yPos >= y + 10 and yPos <= y + 14 then
				if xPos >= 1 and xPos <= 5 then
					line2 = line2 - 1
					if line2 < 1 then
						line2 = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					line2 = line2 + 1
					if line2 > reactorCount + 3 then
						line2 = 1
					end
				end
				drawLines()
			end
		end
	end
	if amount == 3 then
		while true do
			-- button handler
			local event, side, xPos, yPos = os.pullEvent("monitor_touch")

			if  yPos >= y and yPos <= y + 4 then
				if xPos >= 1 and xPos <= 5 then
					line1 = line1 - 1
					if line1 < 1 then
						line1 = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					line1 = line1 + 1
					if line1 > reactorCount + 3 then
						line1 = 1
					end
				end
				drawLines()
			end

			if  yPos >= y + 10 and yPos <= y + 14 then
				if xPos >= 1 and xPos <= 5 then
					line2 = line2 - 1
					if line2 < 1 then
						line2 = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					line2 = line2 + 1
					if line2 > reactorCount + 3 then
						line2 = 1
					end
				end
				drawLines()
			end

			if  yPos >= y + 18 and yPos <= y + 22 then
				if xPos >= 1 and xPos <= 5 then
					line3 = line3 - 1
					if line3 < 1 then
						line3 = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					line3 = line3 + 1
					if line3 > reactorCount + 3 then
						line3 = 1
					end
				end
				drawLines()
			end
		end
	end
	if amount == 4 then
		while true do
			-- button handler
			local event, side, xPos, yPos = os.pullEvent("monitor_touch")

			if  yPos >= y and yPos <= y + 4 then
				if xPos >= 1 and xPos <= 5 then
					line1 = line1 - 1
					if line1 < 1 then
						line1 = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					line1 = line1 + 1
					if line1 > reactorCount + 3 then
						line1 = 1
					end
				end
				drawLines()
			end

			if  yPos >= y + 10 and yPos <= y + 14 then
				if xPos >= 1 and xPos <= 5 then
					line2 = line2 - 1
					if line2 < 1 then
						line2 = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					line2 = line2 + 1
					if line2 > reactorCount + 3 then
						line2 = 1
					end
				end
				drawLines()
			end

			if  yPos >= y + 18 and yPos <= y + 22 then
				if xPos >= 1 and xPos <= 5 then
					line3 = line3 - 1
					if line3 < 1 then
						line3 = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					line3 = line3 + 1
					if line3 > reactorCount + 3 then
						line3 = 1
					end
				end
				drawLines()
			end

			if  yPos >= y + 26 and yPos <= y + 30 then
				if xPos >= 1 and xPos <= 5 then
					line4 = line4 - 1
					if line4 < 1 then
						line4 = reactorCount + 3
					end
				elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
					line4 = line4 + 1
					if line4 > reactorCount + 3 then
						line4 = 1
					end
				end
				drawLines()
			end
		end
	end
end

--draw line with information on the monitor
function drawLine(localY, line)
	if line == 1 then
		gui.draw_number(mon, getGeneration() - getDrainback(), 7, x, localY, numberColor, rftColor)
		if drawButtons then
			gui.drawSideButtons(mon, x, localY, buttonColor)
			gui.draw_text_lr(mon, 2, localY + 2, 0, "DR" .. reactorCount .. " ", " Gen", textColor, textColor, buttonColor)
		end
	elseif line == 2 then
		gui.draw_number(mon, getGeneration(), 7, x, localY, numberColor, rftColor)
		if drawButtons then
			gui.drawSideButtons(mon, x, localY, buttonColor)
			gui.draw_text_lr(mon, 2, localY + 2, 0, "Out ", "Back", textColor, textColor, buttonColor)
		end
	elseif line == 3 then
		gui.draw_number(mon, getDrainback(), 7, x, localY, numberColor, rftColor)
		if drawButtons then
			gui.drawSideButtons(mon, x, localY, buttonColor)
			gui.draw_text_lr(mon, 2, localY + 2, 0, "Gen ", " DR1", textColor, textColor, buttonColor)
		end
	else
		for i = 1, reactorCount do
			if line == i + 3 then
				gui.draw_number(mon, getReactorGeneration(i), 7, x, localY, numberColor, rftColor)
				if drawButtons then
					gui.drawSideButtons(mon, x, localY, buttonColor)
					if line == 4 and line == reactorCount + 3 then
						gui.draw_text_lr(mon, 2, localY + 2, 0, "Back", " Out", textColor, textColor, buttonColor)
					elseif line == 4 then
						gui.draw_text_lr(mon, 2, localY + 2, 0, "Back", "DR" .. i + 1 .. " ", textColor, textColor, buttonColor)
					elseif line == reactorCount + 3 then
						gui.draw_text_lr(mon, 2, localY + 2, 0, "DR" .. i - 1 .. " ", " Out", textColor, textColor, buttonColor)
					else
						gui.draw_text_lr(mon, 2, localY + 2, 0, "DR" .. i - 1 .. " ", "DR" .. i + 1 .. " ", textColor, textColor, buttonColor)
					end
				end
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


--run
if mon.X >= 57 then
	if mon.Y < 16 then
		amount = 1
		drawButtons= true
		y = gui.getInteger((mon.Y - 6) / 2)
		parallel.waitForAny(buttons, update)
	elseif mon.Y >= 16 and mon.Y < 24 then
		amount = 2
		drawButtons= true
		y = gui.getInteger((mon.Y - 14) / 2)
		parallel.waitForAny(buttons, update)
	elseif mon.Y >= 24 and mon.Y < 32 then
		amount = 3
		drawButtons= true
		y = gui.getInteger((mon.Y - 22) / 2)
		parallel.waitForAny(buttons, update)
	else
		amount = 4
		drawButtons= true
		y = gui.getInteger((mon.Y - 30) / 2)
		parallel.waitForAny(buttons, update)
	end
else
	if mon.Y < 16 then
		amount = 1
		drawButtons= false
		y = gui.getInteger((mon.Y - 6) / 2)
		update()
	elseif mon.Y >= 16 and mon.Y < 24 then
		amount = 2
		drawButtons= false
		y = gui.getInteger((mon.Y - 14) / 2)
		update()
	elseif mon.Y >= 24 and mon.Y < 32 then
		amount = 3
		drawButtons= false
		y = gui.getInteger((mon.Y - 22) / 2)
		update()
	else
		amount = 4
		drawButtons= false
		y = gui.getInteger((mon.Y - 30) / 2)
		update()
	end
end