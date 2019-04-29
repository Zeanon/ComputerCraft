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
  gui.draw1(mon, 2, 2, colors.red)
  gui.draw2(mon, 9, 2, colors.red)
  sleep(0.5)
end

while true do
  update()
end