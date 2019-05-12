-- configure color
local color = colors.red
local rftcolor = colors.gray
local buttoncolor = colors.lightGray
-- lower number means higher refresh rate but also increases server load
local refresh = 1

-- program
local version = "1.2.0"
local mon, monitor, monX, monY
os.loadAPI("lib/gui")

-- max size: 70x40(8 blocksx 6 blocks)
monitor = peripheral.find("monitor")
monX, monY = monitor.getSize()
mon = {}
mon.monitor,mon.X, mon.Y = monitor, monX, monY

local x
local y

local buttonLine1
local buttonLine2
local buttonLine3

local line1 = 1
local line2 = 2
local line3 = 3

function split(string, delimiter)
    local result = { }
    local from = 1
    local delim_from, delim_to = string.find( string, delimiter, from )
    while delim_from do
        table.insert( result, string.sub( string, from , delim_from-1 ) )
        from = delim_to + 1
        delim_from, delim_to = string.find( string, delimiter, from )
    end
    table.insert( result, string.sub( string, from ) )
    return result
end

--write settings to config file
function save_config()
    local sw = fs.open("config.txt", "w")
    sw.writeLine("-- Config for Draconig Reactor Generation Overview")
    sw.writeLine("version: " .. version	)
    sw.writeLine(" ")
    sw.writeLine("-- configure the display colors")
    sw.writeLine("color: " .. gui.convertColor(color))
    sw.writeLine("rftcolor: " .. gui.convertColor(rftcolor))
    sw.writeLine("buttoncolor: " ..  gui.convertColor(buttoncolor))
    sw.writeLine(" ")
    sw.writeLine("-- lower number means higher refresh rate but also increases server load")
    sw.writeLine("refresh: " ..  refresh)
    sw.writeLine(" ")
    sw.writeLine("-- just some saved data")
    sw.writeLine("line1: " .. line1)
    sw.writeLine("line2: " .. line2)
    sw.writeLine("line3: " .. line3)
    sw.close()
end

--read settings from file
function load_config()
    local sr = fs.open("config.txt", "r")
    local curVersion
    local line = sr.readLine()
    while line do
        if split(line, ": ")[1] == "version" then
            curVersion = split(line, ": ")[2]
        elseif split(line, ": ")[1] == "color" then
            color = gui.getColor(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "rftcolor" then
            rftcolor = gui.getColor(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "buttoncolor" then
            buttoncolor = gui.getColor(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "refresh" then
            refresh = tonumber(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "line1" then
            line1 = tonumber(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "line2" then
            line2 = tonumber(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "line3" then
            line3 = tonumber(split(line, ": ")[2])
        end
        line = sr.readLine()
    end
    sr.close()
    if curVersion ~= version then
        save_config()
    end
end

-- 1st time? save our settings, if not, load our settings
if fs.exists("config.txt") == false then
    save_config()
else
    load_config()
end