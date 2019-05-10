-- configure color
local color = colors.red
local rftcolor = colors.gray
local buttoncolor = colors.purple
-- lower number means higher refresh rate but also increases server loadAPI
local refresh = 1

-- program
local mon, monitor, monX, monY
os.loadAPI("lib/gui")

monitor = peripheral.find("monitor")
monX, monY = monitor.getSize()
mon = {}
mon.monitor,mon.X, mon.Y = monitor, monX, monY

local x
local y

local buttonLine1
local buttonLine2
local buttonLine3

local line1 = 1
local line2 = 2
local line3 = 3

function getDrainback()
    local fluxgate1, fluxgate2 = peripheral.find("flux_gate")
    local totalDrainback = fluxgate1.getSignalLowFlow() + fluxgate2.getSignalLowFlow()
    return totalDrainback
end

function getGeneration()
    local reactor1, reactor2 = peripheral.find("draconic_reactor")
    local ri1 = reactor1.getReactorInfo()
    local ri2 = reactor2.getReactorInfo()
    local totalGeneration = ri1.generationRate + ri2.generationRate
    if ri1.status == "offline" then
        totalGeneration = ri2.generationRate
    elseif ri2.status == "offline" then
        totalGeneration = ri1.generationRate
    else
        totalGeneration = ri1.generationRate + ri2.generationRate
    end
    return totalGeneration
end

function printGeneration()
    local reactor1, reactor2 = peripheral.find("draconic_reactor")
    local ri1 = reactor1.getReactorInfo()
    local ri2 = reactor2.getReactorInfo()
    print("Reactor 1 Generation: " .. gui.format_int(ri1.generationRate))
    print("Reactor 2 Generation: " .. gui.format_int(ri2.generationRate))
end

function drawButtons(localY)
	gui.drawSideButtons(mon, x, localY, buttoncolor)
end

function drawOutput(localY, output)
    gui.draw_number(mon, output, x, localY, color, rftcolor)
end

function drawGeneration(localY, totalGeneration)
	gui.draw_number(mon, totalGeneration, x, localY, color, rftcolor)
end

function drawDrainback(localY, totalDrainback)
	gui.draw_number(mon, totalDrainback, x, localY, color, rftcolor)
end

function update1()
    local output = getGeneration() - getDrainback()
    local totalGeneration = getGeneration()
    local totalDrainback = getDrainback()
    gui.clear(mon)
    print("Total reactor output: " .. gui.format_int(output))
    print("Total generation: " .. gui.format_int(totalGeneration))
    printGeneration()
    print("Total drainback: " .. gui.format_int(totalDrainback))
	drawButtons(y)
	if line1 == 1 then
		drawOutput(y, output)
	elseif line1 == 2 then
		drawGeneration(y, totalGeneration)
	else
		drawDrainback(y, totalDrainback)
	end
end

function update2()
    local output = getGeneration() - getDrainback()
    local totalGeneration = getGeneration()
    local totalDrainback = getDrainback()
    gui.clear(mon)
    print("Total reactor output: " .. gui.format_int(output))
    print("Total generation: " .. gui.format_int(totalGeneration))
    printGeneration()
    print("Total drainback: " .. gui.format_int(totalDrainback))
    drawOutput(y, output)
end

function update3()
    local output = getGeneration() - getDrainback()
    local totalGeneration = getGeneration()
    local totalDrainback = getDrainback()
    gui.clear(mon)
    print("Total reactor output: " .. gui.format_int(output))
    print("Total generation: " .. gui.format_int(totalGeneration))
    printGeneration()
    print("Total drainback: " .. gui.format_int(totalDrainback))
	drawButtons(y)
	drawButtons(y + 10)
	if line1 == 1 then
		drawOutput(y, output)
	elseif line1 == 2 then
		drawGeneration(y, totalGeneration)
	else
		drawDrainback(y, totalDrainback)
	end
    gui.draw_line(mon, 0, y+7, mon.X+1, colors.gray)
	if line2 == 1 then
		drawOutput(y + 10, output)
	elseif line2 == 2 then
		drawGeneration(y + 10, totalGeneration)
	else
		drawDrainback(y + 10, totalDrainback)
	end
end

function update4()
    local output = getGeneration() - getDrainback()
    local totalGeneration = getGeneration()
    local totalDrainback = getDrainback()
    gui.clear(mon)
    print("Total reactor output: " .. gui.format_int(output))
    print("Total generation: " .. gui.format_int(totalGeneration))
    printGeneration()
    print("Total drainback: " .. gui.format_int(totalDrainback))
	drawOutput(y, output)
    gui.draw_line(mon, 0, y+7, mon.X+1, colors.gray)
	drawGeneration(y + 10, totalGeneration)
end

function update5()
    local output = getGeneration() - getDrainback()
    local totalGeneration = getGeneration()
    local totalDrainback = getDrainback()
    gui.clear(mon)
    print("Total reactor output: " .. gui.format_int(output))
    print("Total generation: " .. gui.format_int(totalGeneration))
    printGeneration()
    print("Total drainback: " .. gui.format_int(totalDrainback))
	drawButtons(y)
	drawButtons(y + 10)
	drawButtons(y + 18)
	if line1 == 1 then
		drawOutput(y, output)
	elseif line1 == 2 then
		drawGeneration(y, totalGeneration)
	else
		drawDrainback(y, totalDrainback)
	end
    gui.draw_line(mon, 0, y+7, mon.X+1, colors.gray)
	if line2 == 1 then
		drawOutput(y + 10, output)
	elseif line2 == 2 then
		drawGeneration(y + 10, totalGeneration)
	else
		drawDrainback(y + 10, totalDrainback)
	end
	if line3 == 1 then
		drawOutput(y + 18, output)
	elseif line3 == 2 then
		drawGeneration(y + 18, totalGeneration)
	else
		drawDrainback(y + 18, totalDrainback)
	end
end

function update6()
    local output = getGeneration() - getDrainback()
    local totalGeneration = getGeneration()
    local totalDrainback = getDrainback()
    gui.clear(mon)
    print("Total reactor output: " .. gui.format_int(output))
    print("Total generation: " .. gui.format_int(totalGeneration))
    printGeneration()
    print("Total drainback: " .. gui.format_int(totalDrainback))
	drawOutput(y, output)
    gui.draw_line(mon, 0, y+7, mon.X+1, colors.gray)
	drawGeneration(y + 10, totalGeneration)
	drawDrainback(y + 18, totalDrainback)
end

funtion buttons()
	local event, side, xPos, yPos = os.pullEvent("monitor_touch")
	if buttonLine1 ~= null and yPos >= buttonLine1 and yPos <= buttonLine1 + 4 then
		if xPos >= 2 and xPos <= 4 then
			line1 = line1 - 1
			if line1 < 1 then
				line1 = 3
			end	
		elseif xPos >= mon.X - 4 and xPos <= mon.X - 2 then
			line1 = line1 + 1
			if line1 > 3
				line1 = 1
			end
		end
		update1()
	elseif buttonLine2 ~= null and yPos >= buttonLine2 and yPos <= buttonLine2 + 4 then
		if xPos >= 2 and xPos <= 4 then
			line2 = line2 - 1
			if line2 < 1 then
				line2 = 3
			end	
		elseif xPos >= mon.X - 4 and xPos <= mon.X - 2 then
			line2 = line2 + 1
			if line2 > 3
				line2 = 1
			end
		end
		update3()
	elseif buttonLine3 ~= null and yPos >= buttonLine3 and yPos <= buttonLine3 + 4 then
		if xPos >= 2 and xPos <= 4 then
			line3 = line3 - 1
			if line3 < 1 then
				line3 = 3
			end	
		elseif xPos >= mon.X - 4 and xPos <= mon.X - 2 then
			line3 = line3 + 1
			if line3 > 3
				line3 = 1
			end
		end
		update5()
	end
end

funtion update()
	if mon.Y < 16 then
		if mon.X >= 55 then
			x = gui.getInteger((mon.X - 47) / 2) + 1
			y = gui.getInteger((mon.Y - 6) / 2)
			while true do
				update1()
				sleep(refresh)
			end
		else
			x = gui.getInteger((mon.X - 47) / 2) + 1
			y = gui.getInteger((mon.Y - 6) / 2)
			while true do
				update2()
				sleep(refresh)
			end
		end
	elseif mon.Y >= 16 and mon.Y < 24 then
		if mon.X >= 55 then
			x = gui.getInteger((mon.X - 47) / 2) + 1
			y = gui.getInteger((mon.Y - 14) / 2)
			while true do
				update3()
				sleep(refresh)
			end
		else
			x = gui.getInteger((mon.X - 47) / 2) + 1
			y = gui.getInteger((mon.Y - 14) / 2)
			while true do
				update4()
				sleep(refresh)
			end
		end
	else
		if mon.X >= 55 then
			x = gui.getInteger((mon.X - 47) / 2) + 1
			y = gui.getInteger((mon.Y - 22) / 2)
			while true do
				update5()
				sleep(refresh)
			end
		else
			x = gui.getInteger((mon.X - 47) / 2) + 1
			y = gui.getInteger((mon.Y - 22) / 2)
			while true do
				update6()
				sleep(refresh)
			end
		end
	end
end

if mon.X >= 55 then
	parallel.waitForAny(buttons, update)
else
	update()
end
