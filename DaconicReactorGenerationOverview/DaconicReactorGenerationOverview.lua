-- configure color
local color = colors.red
local rftcolor = colors.gray
local buttoncolor = colors.lightGray
-- lower number means higher refresh rate but also increases server load
local refresh = 1

-- program
local version = "1.0.0"
local mon, monitor, monX, monY
os.loadAPI("lib/gui")

local fluxgate1, fluxgate2 = peripheral.find("flux_gate")
local reactor1, reactor2 = peripheral.find("draconic_reactor")
monitor = peripheral.find("monitor")
monX, monY = monitor.getSize()
mon = {}
mon.monitor,mon.X, mon.Y = monitor, monX, monY
local ri1 = reactor1.getReactorInfo()
local ri2 = reactor2.getReactorInfo()

local x
local y

local buttonLine1
local buttonLine2
local buttonLine3

local line1 = 1
local line2 = 2
local line3 = 3

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
	sw.writeLine("-- configure the display colors")
	sw.writeLine("color: " .. gui.convertColor(color))
	sw.writeLine("rftcolor: " .. gui.convertColor(rftcolor))
	sw.writeLine("buttoncolor: " ..  gui.convertColor(buttoncolor))
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
		elseif split(line, ": ")[1] == "color" then
			color = gui.getColor(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "rftcolor" then
			rftcolor = gui.getColor(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "buttoncolor" then
			buttoncolor = gui.getColor(split(line, ": ")[2])
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

function getDrainback()
    local totalDrainback = fluxgate1.getSignalLowFlow() + fluxgate2.getSignalLowFlow()
    return totalDrainback
end

function getGeneration1()
    if ri1.status == "offline" then
        return 0
    else
        return ri1.generationRate
    end
end

function getGeneration2()
	if ri2.status == "offline" then
		return 0
	else
		return ri2.generationRate
	end
end

function drawButtons(localY)
	gui.drawSideButtons(mon, x, localY, buttoncolor)
end

function drawNumber(localY, output)
    gui.draw_number(mon, output, x, localY, color, rftcolor)
end

function update1()
	local generation1 = getGeneration1()
	local generation2 = getGeneration2()
	local totalDrainback = getDrainback()
	local totalGeneration = generation1 + generation2
	local output = totalGeneration - totalDrainback
    gui.clear(mon)
	print("Total reactor output: " .. gui.format_int(output))
	print("Total generation: " .. gui.format_int(totalGeneration))
	print("Reactor 1 Generation: " .. gui.format_int(generation1))
	print("Reactor 2 Generation: " .. gui.format_int(generation2))
	print("Total drainback: " .. gui.format_int(totalDrainback))
	drawButtons(y)
	if line1 == 1 then
		drawNumber(y, output)
		gui.draw_text(mon, 2, y + 2, "DR2 ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 2, " Gen", colors.white, buttoncolor)
	elseif line1 == 2 then
		drawNumber(y, totalGeneration)
		gui.draw_text(mon, 2, y + 2, "Out ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 2, "Back", colors.white, buttoncolor)
	elseif line1 == 3 then
		drawNumber(y, totalDrainback)
		gui.draw_text(mon, 2, y + 2, "Gen ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 2, " DR1", colors.white, buttoncolor)
	elseif line1 == 4 then
		drawNumber(y, generation1)
		gui.draw_text(mon, 2, y + 2, "Back", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 2, " DR2", colors.white, buttoncolor)
	else
		drawNumber(y, generation2)
		gui.draw_text(mon, 2, y + 2, "DR1 ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 2, " Out", colors.white, buttoncolor)
	end
end

function update2()
	local generation1 = getGeneration1()
	local generation2 = getGeneration2()
	local totalDrainback = getDrainback()
	local totalGeneration = generation1 + generation2
	local output = totalGeneration - totalDrainback
    gui.clear(mon)
	print("Total reactor output: " .. gui.format_int(output))
	print("Total generation: " .. gui.format_int(totalGeneration))
	print("Reactor 1 Generation: " .. gui.format_int(generation1))
	print("Reactor 2 Generation: " .. gui.format_int(generation2))
	print("Total drainback: " .. gui.format_int(totalDrainback))
    drawNumber(y, output)
end

function update3()
	local generation1 = getGeneration1()
	local generation2 = getGeneration2()
	local totalDrainback = getDrainback()
	local totalGeneration = generation1 + generation2
	local output = totalGeneration - totalDrainback
    gui.clear(mon)
	print("Total reactor output: " .. gui.format_int(output))
	print("Total generation: " .. gui.format_int(totalGeneration))
	print("Reactor 1 Generation: " .. gui.format_int(generation1))
	print("Reactor 2 Generation: " .. gui.format_int(generation2))
	print("Total drainback: " .. gui.format_int(totalDrainback))
	drawButtons(y)
	drawButtons(y + 10)
	if line1 == 1 then
		drawNumber(y, output)
		gui.draw_text(mon, 2, y + 2, "DR2 ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 2, " Gen", colors.white, buttoncolor)
	elseif line1 == 2 then
		drawNumber(y, totalGeneration)
		gui.draw_text(mon, 2, y + 2, "Out ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 2, "Back", colors.white, buttoncolor)
	elseif line1 == 3 then
		drawNumber(y, totalDrainback)
		gui.draw_text(mon, 2, y + 2, "Gen ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 2, " DR1", colors.white, buttoncolor)
	elseif line1 == 4 then
		drawNumber(y, generation1)
		gui.draw_text(mon, 2, y + 2, "Back", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 2, " DR2", colors.white, buttoncolor)
	else
		drawNumber(y, generation2)
		gui.draw_text(mon, 2, y + 2, "DR1 ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 2, " Out", colors.white, buttoncolor)
	end

    gui.draw_line(mon, 0, y+7, mon.X+1, colors.gray)

	if line2 == 1 then
		drawNumber(y + 10, output)
		gui.draw_text(mon, 2, y + 12, "DR2 ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 12, " Gen ", colors.white, buttoncolor)
	elseif line2 == 2 then
		drawNumber(y + 10, totalGeneration)
		gui.draw_text(mon, 2, y + 12, "Out ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 12, "Back", colors.white, buttoncolor)
	elseif line2 == 3 then
		drawNumber(y + 10, totalDrainback)
		gui.draw_text(mon, 2, y + 12, "Gen ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 12, " DR1", colors.white, buttoncolor)
	elseif line2 == 4 then
		drawNumber(y, generation1)
		gui.draw_text(mon, 2, y + 12, "Back", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 12, " DR2", colors.white, buttoncolor)
	else
		drawNumber(y, generation2)
		gui.draw_text(mon, 2, y + 12, "DR1 ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 12, " Out", colors.white, buttoncolor)
	end
end

function update4()
	local generation1 = getGeneration1()
	local generation2 = getGeneration2()
	local totalDrainback = getDrainback()
	local totalGeneration = generation1 + generation2
	local output = totalGeneration - totalDrainback
    gui.clear(mon)
	print("Total reactor output: " .. gui.format_int(output))
	print("Total generation: " .. gui.format_int(totalGeneration))
	print("Reactor 1 Generation: " .. gui.format_int(generation1))
	print("Reactor 2 Generation: " .. gui.format_int(generation2))
	print("Total drainback: " .. gui.format_int(totalDrainback))
	drawNumber(y, output)
    gui.draw_line(mon, 0, y+7, mon.X+1, colors.gray)
	drawNumber(y + 10, totalGeneration)
end

function update5()
	local generation1 = getGeneration1()
	local generation2 = getGeneration2()
	local totalDrainback = getDrainback()
	local totalGeneration = generation1 + generation2
	local output = totalGeneration - totalDrainback
    gui.clear(mon)
	print("Total reactor output: " .. gui.format_int(output))
	print("Total generation: " .. gui.format_int(totalGeneration))
	print("Reactor 1 Generation: " .. gui.format_int(generation1))
	print("Reactor 2 Generation: " .. gui.format_int(generation2))
	print("Total drainback: " .. gui.format_int(totalDrainback))
	drawButtons(y)
	drawButtons(y + 10)
	drawButtons(y + 18)
	if line1 == 1 then
		drawNumber(y, output)
		gui.draw_text(mon, 2, y + 2, "DR2 ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 2, " Gen", colors.white, buttoncolor)
	elseif line1 == 2 then
		drawNumber(y, totalGeneration)
		gui.draw_text(mon, 2, y + 2, "Out ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 2, "Back", colors.white, buttoncolor)
	elseif line1 == 3 then
		drawNumber(y, totalDrainback)
		gui.draw_text(mon, 2, y + 2, "Gen ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 2, " DR1", colors.white, buttoncolor)
	elseif line1 == 4 then
		drawNumber(y, generation1)
		gui.draw_text(mon, 2, y + 2, "Back", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 2, " DR2", colors.white, buttoncolor)
	else
		drawNumber(y, generation2)
		gui.draw_text(mon, 2, y + 2, "DR1 ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 2, " Out", colors.white, buttoncolor)
	end

    gui.draw_line(mon, 0, y+7, mon.X+1, colors.gray)

	if line2 == 1 then
		drawNumber(y + 10, output)
		gui.draw_text(mon, 2, y + 12, "DR2 ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 12, " Gen ", colors.white, buttoncolor)
	elseif line2 == 2 then
		drawNumber(y + 10, totalGeneration)
		gui.draw_text(mon, 2, y + 12, "Out ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 12, "Back", colors.white, buttoncolor)
	elseif line2 == 3 then
		drawNumber(y + 10, totalDrainback)
		gui.draw_text(mon, 2, y + 12, "Gen ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 12, " DR1", colors.white, buttoncolor)
	elseif line2 == 4 then
		drawNumber(y, generation1)
		gui.draw_text(mon, 2, y + 12, "Back", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 12, " DR2", colors.white, buttoncolor)
	else
		drawNumber(y, generation2)
		gui.draw_text(mon, 2, y + 12, "DR1 ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 12, " Out", colors.white, buttoncolor)
	end

	if line3 == 1 then
		drawNumber(y + 18, output)
		gui.draw_text(mon, 2, y + 20, "DR2 ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 20, " Gen", colors.white, buttoncolor)
	elseif line3 == 2 then
		drawNumber(y + 18, totalGeneration)
		gui.draw_text(mon, 2, y + 20, "Out ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 20, "Back", colors.white, buttoncolor)
	elseif line3 == 3 then
		drawNumber(y + 18, totalDrainback)
		gui.draw_text(mon, 2, y + 20, "Gen ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 20, " DR1", colors.white, buttoncolor)
	elseif line3 == 4 then
		drawNumber(y, generation1)
		gui.draw_text(mon, 2, y + 20, "Back", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 20, " DR2", colors.white, buttoncolor)
	else
		drawNumber(y, generation2)
		gui.draw_text(mon, 2, y + 20, "DR1 ", colors.white, buttoncolor)
		gui.draw_text_right(mon, 0, y + 20, " Out", colors.white, buttoncolor)
	end
end

function update6()
	local generation1 = getGeneration1()
	local generation2 = getGeneration2()
	local totalDrainback = getDrainback()
	local totalGeneration = generation1 + generation2
	local output = totalGeneration - totalDrainback
    gui.clear(mon)
    print("Total reactor output: " .. gui.format_int(output))
    print("Total generation: " .. gui.format_int(totalGeneration))
	print("Reactor 1 Generation: " .. gui.format_int(generation1))
	print("Reactor 2 Generation: " .. gui.format_int(generation2))
    print("Total drainback: " .. gui.format_int(totalDrainback))
	drawNumber(y, output)
    gui.draw_line(mon, 0, y+7, mon.X+1, colors.gray)
	drawNumber(y + 10, totalGeneration)
	drawNumber(y + 18, totalDrainback)
end

function buttons1()
	while true do
		local event, side, xPos, yPos = os.pullEvent("monitor_touch")
		if buttonLine1 ~= null and yPos >= buttonLine1 and yPos <= buttonLine1 + 4 then
			if xPos >= 1 and xPos <= 5 then
				line1 = line1 - 1
				if line1 < 1 then
					line1 = 5
				end
			elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
				line1 = line1 + 1
				if line1 > 5 then
					line1 = 1
				end
			end
			update1()
			save_config()
		end
	end
end

function buttons2()
	while true do
		local event, side, xPos, yPos = os.pullEvent("monitor_touch")
		if buttonLine1 ~= null and yPos >= buttonLine1 and yPos <= buttonLine1 + 4 then
			if xPos >= 1 and xPos <= 5 then
				line1 = line1 - 1
				if line1 < 1 then
					line1 = 5
				end
			elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
				line1 = line1 + 1
				if line1 > 5 then
					line1 = 1
				end
			end
			update3()
			save_config()
		elseif buttonLine2 ~= null and yPos >= buttonLine2 and yPos <= buttonLine2 + 4 then
			if xPos >= 1 and xPos <= 5 then
				line2 = line2 - 1
				if line2 < 1 then
					line2 = 5
				end
			elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
				line2 = line2 + 1
				if line2 > 5 then
					line2 = 1
				end
			end
			update3()
			save_config()
		end
	end
end

function buttons3()
	while true do
		local event, side, xPos, yPos = os.pullEvent("monitor_touch")
		if buttonLine1 ~= null and yPos >= buttonLine1 and yPos <= buttonLine1 + 4 then
			if xPos >= 1 and xPos <= 5 then
				line1 = line1 - 1
				if line1 < 1 then
					line1 = 5
				end
			elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
				line1 = line1 + 1
				if line1 > 5 then
					line1 = 1
				end
			end
			update5()
			save_config()
		elseif buttonLine2 ~= null and yPos >= buttonLine2 and yPos <= buttonLine2 + 4 then
			if xPos >= 1 and xPos <= 5 then
				line2 = line2 - 1
				if line2 < 1 then
					line2 = 5
				end
			elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
				line2 = line2 + 1
				if line2 > 5 then
					line2 = 1
				end
			end
			update5()
			save_config()
		elseif buttonLine3 ~= null and yPos >= buttonLine3 and yPos <= buttonLine3 + 4 then
			if xPos >= 1 and xPos <= 5 then
				line3 = line3 - 1
				if line3 < 1 then
					line3 = 5
				end
			elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
				line3 = line3 + 1
				if line3 > 5 then
					line3 = 1
				end
			end
			update5()
			save_config()
		end
	end
end


function updateManual1()
    x = gui.getInteger((mon.X - 46) / 2) + 1
    y = gui.getInteger((mon.Y - 6) / 2)
	buttonLine1 = y
    while true do
        update1()
        sleep(refresh)
    end
end

function updateManual2()
    x = gui.getInteger((mon.X - 46) / 2) + 1
    y = gui.getInteger((mon.Y - 14) / 2)
	buttonLine1 = y
	buttonLine2 = y + 10
    while true do
        update3()
        sleep(refresh)
    end
end

function updateManual3()
    x = gui.getInteger((mon.X - 46) / 2) + 1
    y = gui.getInteger((mon.Y - 22) / 2)
	buttonLine1 = y
	buttonLine2 = y + 10
	buttonLine3 = y + 18
    while true do
        update5()
        sleep(refresh)
    end
end

function updateAutomatic1()
	x = gui.getInteger((mon.X - 46) / 2) + 1
	y = gui.getInteger((mon.Y - 6) / 2)
	while true do
		update2()
		sleep(refresh)
	end
end

function updateAutomatic2()
	x = gui.getInteger((mon.X - 46) / 2) + 1
	y = gui.getInteger((mon.Y - 14) / 2)
	while true do
		update4()
		sleep(refresh)
	end
end

function updateAutomatic3()
	x = gui.getInteger((mon.X - 46) / 2) + 1
	y = gui.getInteger((mon.Y - 22) / 2)
	while true do
		update6()
		sleep(refresh)
	end
end


if mon.X >= 57 then
	if mon.Y < 16 then
		parallel.waitForAny(buttons1, updateManual1)
	elseif mon.Y >= 16 and mon.Y < 24 then
		parallel.waitForAny(buttons2, updateManual2)
	else 
		parallel.waitForAny(buttons3, updateManual3)
	end
else
	if mon.Y < 16 then
		updateAutomatic1()
	elseif mon.Y >= 16 and mon.Y < 24 then
		updateAutomatic2()
	else
		updateAutomatic3()
	end
end