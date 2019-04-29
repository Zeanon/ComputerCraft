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
    print("Displaying total reactor energy output on monitor")
    print("Total output: " .. output)
    gui.draw_number(output, 1000000, 0, mon, 11, 4, color)
    output = output - (1000000 * gui.getInteger(output / 1000000))
    gui.draw_number(output, 100000, 10, mon, 15, 4, color)
    output = output - (100000 * gui.getInteger(output / 100000))
    gui.draw_number(output, 10000, 100, mon, 19, 4, color)
    output = output - (10000 * gui.getInteger(output/ 10000))
    gui.draw_number(output, 1000, 1000, mon, 23, 4, color)
    output = output - (1000 * gui.getInteger(output / 1000))
    gui.draw_number(output, 100, 10000, mon, 27, 4, color)
    output = output - (100 * gui.getInteger(output / 100))
    gui.draw_number(output, 10, 100000, mon, 31, 4, color)
    output = output - (10 * gui.getInteger(output / 10))
    gui.draw_number(output, 1, 1000000, mon, 35, 4, color)
    sleep(0.5)
end

while true do
    update()
end