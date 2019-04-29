local monitor = peripheral.find("monitor")

os.loadAPI("lib/gui")
os.loadAPI("lib/surface")

function getOutput()
  local reactor1, reactor2 = peripheral.find("flux_gate")
  local totalOutput = reactor1.getSignalLowFlow() + reactor2.getSignalLowFlow()
  return totalOutput
end

function update()
  gui.draw1(monitor, 2, 2, colors.red)
end

while true do
  update()
end