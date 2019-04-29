local monitor = peripheral.find("monitor")

os.loadAPI("lib/gui")

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
  gui.draw_0(mon, 2, 2, colors.red)
  gui.draw_1(mon, 6, 2, colors.red)
  gui.draw_2(mon, 10, 2, colors.red)
  gui.draw_3(mon, 14, 2, colors.red)
  gui.draw_4(mon, 18, 2, colors.red)
  gui.draw_5(mon, 22, 2, colors.red)
  gui.draw_6(mon, 26, 2, colors.red)
  gui.draw_7(mon, 30, 2, colors.red)
  gui.draw_8(mon, 34, 2, colors.red)
  gui.draw_9(mon, 38, 2, colors.red)
  sleep(0.5)
end

while true do
  update()
end