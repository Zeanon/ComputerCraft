-- configure color
local color = colors.red
local rftcolor = colors.gray

-- program
local mon, monitor, monX, monY
os.loadAPI("lib/gui")

monitor = peripheral.find("monitor")
monX, monY = monitor.getSize()
mon = {}
mon.monitor,mon.X, mon.Y = monitor, monX, monY

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

function update1()
    local output = getGeneration() - getDrainback()
    local totalGeneration = getGeneration()
    local totalDrainback = getDrainback()
    gui.clear(mon)
    print("Total reactor output: " .. gui.format_int(output))
    print("Total generation: " .. gui.format_int(totalGeneration))
    printGeneration()
    print("Total drainback: " .. gui.format_int(totalDrainback))
    local x = gui.getInteger((mon.X - 45) / 2)
    local y = gui.getInteger((mon.Y - 6) / 2)
    gui.draw_number(mon, output, x, y, color, rftcolor)
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
    local x = gui.getInteger((mon.X - 45) / 2)
    local y = gui.getInteger((mon.Y - 14) / 2)
    gui.draw_number(mon, output, x, y, color, rftcolor)
    gui.draw_line(mon, 0, y+7, mon.X+1, colors.gray)
    gui.draw_number(mon, totalGeneration, x, y + 10, color, rftcolor)
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
    local x = gui.getInteger((mon.X - 45) / 2)
    local y = gui.getInteger((mon.Y - 22) / 2)
    gui.draw_number(mon, output, x, y, color, rftcolor)
    gui.draw_line(mon, 0, y+7, mon.X+1, colors.gray)
    gui.draw_number(mon, totalGeneration, x, y + 10, color, rftcolor)
    gui.draw_number(mon, totalDrainback, x, y + 18, color, rftcolor)
end

if mon.Y < 16 then
    while true do
        update1()
        sleep(1)
    end
elseif mon.Y >= 16 and mon.Y < 24 then
    while true do
        update3()
        sleep(1)
    end
else
    while true do
        update5()
        sleep(1)
    end
end