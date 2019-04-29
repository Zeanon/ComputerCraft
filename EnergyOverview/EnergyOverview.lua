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
    print("Displaying total reactor energy output on monitor")
    local output = getOutput()
    gui.draw_number(output, 1000000, mon, 7, 5, colors.red)
    output = output - (1000000 * gui.getInteger(output / 1000000))
    gui.draw_number(output, 100000, mon, 11, 5, colors.red)
    output = output - (100000 * gui.getInteger(output / 100000))
    gui.draw_number(output, 10000, mon, 15, 5, colors.red)
    output = output - (10000 * gui.getInteger(output/ 10000))
    gui.draw_number(output, 1000, mon, 19, 5, colors.red)
    output = output - (1000 * gui.getInteger(output / 1000))
    gui.draw_number(output, 100, mon, 23, 5, colors.red)
    output = output - (100 * gui.getInteger(output / 100))
    gui.draw_number(output, 10, mon, 27, 5, colors.red)
    output = output - (10 * gui.getInteger(output / 10))
    gui.draw_number(output, 1, mon, 31, 5, colors.red)
    sleep(0.5)
end

while true do
    update()
end