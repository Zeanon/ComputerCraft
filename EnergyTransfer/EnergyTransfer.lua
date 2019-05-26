-- configure colors
local numberColor = colors.red
local unitColor = colors.gray
-- lower number means higher refresh rate but also increases server load
local refresh = 1

-- program
local version = "1.0.0"
-- peripherals
local core, fluxgate, y
-- monitor
local mon, monitor, monX, monY
os.loadAPI("lib/gui")
os.loadAPI("lib/color")

--write settings to config file
function save_config()
	local sw = fs.open("config.txt", "w")
	sw.writeLine("-- Config for Draconig Reactor Generation Overview")
	sw.writeLine("version: " .. version	)
	sw.writeLine(" ")
	sw.writeLine("-- configure the display numberColors")
	sw.writeLine("numberColor: " .. color.toString(numberColor))
	sw.writeLine("unitColor: " .. color.toString(unitColor))
	sw.writeLine(" ")
	sw.writeLine("-- lower number means higher refresh rate but also increases server load")
	sw.writeLine("refresh: " ..  refresh)
	sw.close()
end

--read settings from file
function load_config()
	local sr = fs.open("config.txt", "r")
	local line = sr.readLine()
	while line do
		if gui.split(line, ": ")[1] == "numberColor" then
			numberColor = color.getColor(gui.split(line, ": ")[2])
		elseif gui.split(line, ": ")[1] == "unitColor" then
			unitColor = color.getColor(gui.split(line, ": ")[2])
		elseif gui.split(line, ": ")[1] == "refresh" then
			refresh = tonumber(gui.split(line, ": ")[2])
		end
		line = sr.readLine()
	end
	sr.close()
	save_config()
end


-- 1st time? save our settings, if not, load our settings
if fs.exists("config.txt") == false then
	save_config()
else
	load_config()
end

core = peripheral.find("draconic_rf_storage")
monitor = peripheral.find("monitor")
fluxgate = peripheral.find("flux_gate")

if core == null then
	error("No valid energy core was found")
end

if monitor == null then
	error("No valid monitor was found")
end

if fluxgate == null then
	error("No valid flux gate was found")
end

monX, monY = monitor.getSize()
mon = {}
mon.monitor,mon.X, mon.Y = monitor, monX, monY

function update()
	if core.getEnergyStored() < (core.getMaxEnergyStored() / 2) - 20 then
		fluxgate.setSignalLowFlow(fluxgate.getSignalLowFlow() + 10)
		fluxgate.setSignalHighFlow(fluxgate.getSignalLowFlow())
	elseif core.getEnergyStored() > (core.getMaxEnergyStored() / 2) + 20 then
		fluxgate.setSignalLowFlow(fluxgate.getSignalLowFlow() - 10)
		fluxgate.setSignalHighFlow(fluxgate.getSignalLowFlow())
	else
		updateGUI(fluxgate.getSignalLowFlow())
	end
end 

function updateGUI(number)
	gui.clear(mon)
	print("|# Transfer: " .. number .. "RF/t")
	local length = string.len(tostring(number))
	local offset = (length * 4) + (2 * gui.getInteger((length - 1) / 3)) + 16
	local x = (mon.X - offset) / 2
	gui.draw_number(mon, number, x + 16, y, numberColor)
	gui.draw_rft(mon, x, y, unitColor)
end

fluxgate.setSignalHighFlow(fluxgate.getSignalLowFlow())
y = (mon.Y - 5) / 2
updateGUI(0)

while true do
	update()
	sleep(refresh)
end