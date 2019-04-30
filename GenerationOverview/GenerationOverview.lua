-- configure color
local color = colors.red
local rftcolor = colors.gray
-- program
local mon, monitor, monX, monY
local oldOutput = 0
local totalGeneration
local totalDrainback
os.loadAPI("lib/gui")

monitor = peripheral.find("monitor")
monX, monY = monitor.getSize()
mon = {}
mon.monitor,mon.X, mon.Y = monitor, monX, monY

function getOutput()
    local reactor1, reactor2 = peripheral.find("draconic_reactor")
    local fluxgate1, fluxgate2 = peripheral.find("flux_gate")
    local ri1 = reactor1.getReactorInfo()
    local ri2 = reactor2.getReactorInfo()
    totalGeneration = ri1.generationRate + ri2.generationRate
    totalDrainback = fluxgate1.getSignalLowFlow() + fluxgate2.getSignalLowFlow()
    local totalOutput = totalGeneration - totalDrainback
    return totalOutput
end

function update()
    local output = getOutput()
    if output ~= oldOutput then
        oldOutput = output
        gui.clear(mon)
        print("Displaying total reactor energy output on monitor")
        print("Total reactor output: " .. gui.format_int(output))
        print("Total generation: " .. gui.format_int(totalGeneration))
        print("Total drainback: " .. gui.format_int(totalDrainback))
        if mon.Y < 16 then
            local y = gui.getInteger((mon.Y - 6) / 2)
            gui.draw_number(mon, output, 2, y, color, rftcolor)
        elseif mon.Y >= 16 and mon.Y < 24 then
            local y = gui.getInteger((mon.Y - 14) / 2)
            gui.draw_number(mon, output, 2, y, color, rftcolor)
            gui.draw_line(mon, 0, y+6, mon.X+1, colors.gray)
            gui.draw_number(mon, totalGeneration, 2, y + 10, color, rftcolor)
        else
            local y = gui.getInteger((mon.Y - 22) / 2)
            gui.draw_number(mon, output, 2, y, color, rftcolor)
            gui.draw_line(mon, 0, y+6, mon.X+1, colors.gray)
            gui.draw_number(mon, totalGeneration, 2, y + 10, color, rftcolor)
            gui.draw_number(mon, totalDrainback, 2, y + 18, color, rftcolor)
        end
    end
    sleep(0.5)
end

while true do
    update()
end