local monitor = peripheral.find("monitor")

os.loadAPI("lib/gui")
os.loadAPI("lib/surface")

monX, monY = monitor.getSize()
mon = {}
mon.monitor,mon.X, mon.Y = monitor, monX, monY

function getOutput()
  local reactor1, reactor2 = peripheral.find("flux_gate")
  local totalOutput = reactor1.getSignalLowFlow() + reactor2.getSignalLowFlow()
  return totalOutput
end

function update()
  gui.draw_0(mon, 2, 2, colors.red)
  gui.draw_1(mon, 2, 6, colors.red)
  gui.draw_2(mon, 2, 10, colors.red)
  gui.draw_3(mon, 2, 14, colors.red)
  gui.draw_4(mon, 2, 18, colors.red)
  gui.draw_5(mon, 2, 22, colors.red)
  gui.draw_6(mon, 2, 26, colors.red)
  gui.draw_7(mon, 2, 30, colors.red)
  gui.draw_8(mon, 2, 34, colors.red)
  gui.draw_9(mon, 2, 38, colors.red)
  sleep(0.5)
end

while true do
  update()
end