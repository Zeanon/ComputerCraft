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
    local totalDrainback = fluxgate1.getFlow() + fluxgate2.getFlow()
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

function update()
    local output = getGeneration() - getDrainback()
    local totalGeneration = getGeneration()
    local totalDrainback = getDrainback()
    gui.clear(mon)
    print("Displaying total reactor energy output on monitor")
    print("Total reactor output: " .. gui.format_int(output))
    print("Total generation: " .. gui.format_int(totalGeneration))
    printGeneration()
    print("Total drainback: " .. gui.format_int(totalDrainback))
    if mon.Y < 16 then
        local y = gui.getInteger((mon.Y - 6) / 2)
        gui.draw_number(mon, output, 2, y, color, rftcolor)
    elseif mon.Y >= 16 and mon.Y < 24 then
        local y = gui.getInteger((mon.Y - 14) / 2)
        gui.draw_number(mon, output, 2, y, color, rftcolor)
        gui.draw_line(mon, 0, y+7, mon.X+1, colors.gray)
        gui.draw_number(mon, totalGeneration, 2, y + 10, color, rftcolor)
    else
        local y = gui.getInteger((mon.Y - 22) / 2)
        gui.draw_number(mon, output, 2, y, color, rftcolor)
        gui.draw_line(mon, 0, y+7, mon.X+1, colors.gray)
        gui.draw_number(mon, totalGeneration, 2, y + 10, color, rftcolor)
        gui.draw_number(mon, totalDrainback, 2, y + 18, color, rftcolor)
    end
end

while true do
    update()
    sleep(1)
end
