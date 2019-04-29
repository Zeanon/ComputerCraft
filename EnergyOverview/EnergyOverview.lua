local color = colors.red
local mon, monitor, monX, monY

os.loadAPI("lib/gui")

monitor = peripheral.find("monitor")
monX, monY = monitor.getSize()
mon = {}
mon.monitor,mon.X, mon.Y = monitor, monX, monY

function getOutput()
  local reactor1, reactor2 = peripheral.find("flux_gate")
  local totalOutput = reactor1.getSignalLowFlow() + reactor2.getSignalLowFlow()
  return totalOutput
end

function update()
    gui.clear(mon)
    local output = getOutput()
    local a,b,c,d,e,f
    print("Displaying total reactor energy output on monitor")
    print("Total reactor output: " .. output)
    a = gui.getInteger(output / 1000000)
    if a ~= 0 then
        gui.draw_number(output, 1000000, mon, 13, 4, color)
    end
    output = output - (1000000 * gui.getInteger(output / 1000000))
    b = gui.getInteger(output / 100000)
    if a ~= 0 or b ~= 0 then
        gui.draw_number(output, 100000, mon, 17, 4, color)
    end
    output = output - (100000 * gui.getInteger(output / 100000))
    c = gui.getInteger(output / 10000)
    if a ~= 0 or b ~= 0 or c ~= 0 then
        gui.draw_number(output, 10000, mon, 21, 4, color)
    end
    output = output - (100000 * gui.getInteger(output / 100000))
    d = gui.getInteger(output / 1000)
    if a ~= 0 or b ~= 0 or c ~= 0 or d ~= 0 then
        gui.draw_number(output, 1000, mon, 25, 4, color)
    end
    output = output - (1000 * gui.getInteger(output / 1000))
    e = gui.getInteger(output / 100)
    if a ~= 0 or b ~= 0 or c ~= 0 or d ~= 0 or e ~= 0 then
        gui.draw_number(output, 100, mon, 29, 4, color)
    end
    output = output - (100 * gui.getInteger(output / 100))
    f = gui.getInteger(output / 10)
    if a ~= 0 or b ~= 0 or c ~= 0 or d ~= 0 or e ~= 0 or f ~= 0 then
        gui.draw_number(output, 10, mon, 33, 4, color)
    end
    output = output - (10 * gui.getInteger(output / 10))
    gui.draw_number(output, 1, mon, 37, 4, color)
    sleep(0.5)
end

while true do
    update()
end