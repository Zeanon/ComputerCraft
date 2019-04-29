local monitor = peripheral.find("monitor")

os.loadAPI("lib/gui")

local monX, monY = monitor.getSize()
local mon = {}
mon.monitor,mon.X, mon.Y = monitor, monX, monY

function getOutput()
  local reactor1, reactor2 = peripheral.find("flux_gate")
  local totalOutput = reactor1.getSignalLowFlow() + reactor2.getSignalLowFlow()
  return totalOutput
end

function update()
    gui.clear(mon)
    gui.draw_number(getOutput(), 1000000, mon, 7, 5, colors.red)
    gui.draw_number(getOutput(), 100000, mon, 11, 5, colors.red)
    gui.draw_number(getOutput(), 10000, mon, 15, 5, colors.red)
    gui.draw_number(getOutput(), 1000, mon, 19, 5, colors.red)
    gui.draw_number(getOutput(), 100, mon, 23, 5, colors.red)
    gui.draw_number(getOutput(), 10, mon, 27, 5, colors.red)
    gui.draw_number(getOutput(), 1, mon, 31, 5, colors.red)
    sleep(0.5)
end

print("Displaying total reactor energy output on monitor")
while true do
  update()
end