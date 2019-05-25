-- configure colors
local numberColor = colors.red
local unitColor = colors.gray
local buttonColor = colors.lightGray
local textColor = colors.white
-- lower number means higher refresh rate but also increases server load
local refresh = 1

-- program
local version = "1.0.0"
-- peripherals
local core, fluxgate
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
    sw.writeLine("buttonColor: " ..  color.toString(buttonColor))
    sw.writeLine("textColor: " ..  color.toString(textColor))
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
        elseif gui.split(line, ": ")[1] == "buttonColor" then
            buttonColor = color.getColor(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "textColor" then
            textColor = color.getColor(gui.split(line, ": ")[2])
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