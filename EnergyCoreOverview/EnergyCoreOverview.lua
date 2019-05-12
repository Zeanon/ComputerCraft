-- configure colors
local rftColor = colors.gray
local buttonColor = colors.lightGray
local textColor = colors.white
-- lower number means higher refresh rate but also increases server load
local refresh = 1

-- program
local version = "1.0.0"
local mon, monitor, monX, monY
os.loadAPI("lib/gui")
os.loadAPI("lib/color")

-- max size: 70x40(8 blocks x 6 blocks)
monitor = peripheral.find("monitor")
monX, monY = monitor.getSize()
mon = {}
mon.monitor,mon.X, mon.Y = monitor, monX, monY

local x, y

local line1 = 1
local line2 = 2
local line3 = 3
local line4 = 4

local amount, drawButtons, energyColor, energyPercent

local coreCount = 0
local connectedCores = {}
local periList = peripheral.getNames()
local validPeripherals = {
    "draconic_rf_storage"
}

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
    sw.writeLine("-- configure the display numberColors")
    sw.writeLine("rftColor: " .. color.toString(rftColor))
    sw.writeLine("buttonColor: " ..  color.toString(buttonColor))
    sw.writeLine("textColor: " ..  color.toString(textColor))
    sw.writeLine(" ")
    sw.writeLine("-- lower number means higher refresh rate but also increases server load")
    sw.writeLine("refresh: " ..  refresh)
    sw.writeLine(" ")
    sw.writeLine("-- just some saved data")
    sw.writeLine("line1: " .. line1)
    sw.writeLine("line2: " .. line2)
    sw.writeLine("line3: " .. line3)
    sw.writeLine("line4: " .. line4)
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
        elseif split(line, ": ")[1] == "rftColor" then
            rftColor = color.getColor(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "buttonColor" then
            buttonColor = color.getColor(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "textColor" then
            textColor = color.getColor(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "refresh" then
            refresh = tonumber(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "line1" then
            line1 = tonumber(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "line2" then
            line2 = tonumber(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "line3" then
            line3 = tonumber(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "line4" then
            line4 = tonumber(split(line, ": ")[2])
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


-- get all connected reactors
function checkValidity(periName)
    for n,b in pairs(validPeripherals) do
        if periName:find(b) then return b end
    end
    return false
end

for i,v in ipairs(periList) do
    local periFunctions = {
        ["draconic_rf_storage"] = function()
            coreCount = coreCount + 1
            connectedCores[coreCount] = periList[i]
        end,
    }

    local isValid = checkValidity(peripheral.getType(v))
    if isValid then periFunctions[isValid]() end
end

--Check for reactor, fluxgates and monitors before continuing
if coreCount == 0 then
    error("No valid energy core was found")
end

if monitor == null then
    error("No valid monitor was found")
end


function getTotalMaxEnergyStored()
    local totalMaxEnergy = 0
    for i = 1, coreCount do
        totalMaxEnergy = totalMaxEnergy + getMaxEnergyStored(i)
    end
    return totalMaxEnergy
end

function getTotalEnergyStored()
    local totalEnergy = 0
    for i = 1, coreCount do
        totalEnergy = totalEnergy + getEnergyStored(i)
    end
    return totalEnergy
end

function getMaxEnergyStored(number)
    local core = peripheral.wrap(connectedCores[number])
    return core.getMaxEnergyStored()
end

function getEnergyStored(number)
    local core = peripheral.wrap(connectedCores[number])
    return core.getEnergyStored()
end

--draw line with information on the monitor
function drawLine(localY, line)
    if line == 1 then
        energyPercent = math.ceil(getTotalEnergyStored() / getTotalMaxEnergyStored() * 10000)*.01
        if energyPercent == math.huge or isnan(energyPercent) then
            energyPercent = 0
        end
        energyColor = colors.red
        if energyPercent >= 70 then
            energyColor = colors.green
        elseif energyPercent < 70 and energyPercent > 30 then
            energyColor = colors.orange
        end
        gui.draw_number(mon, getTotalEnergyStored(), x, localY, energyColor, rftColor)
        if drawButtons then
            gui.drawSideButtons(mon, x, localY, buttonColor)
            gui.draw_text_lr(mon, 2, localY + 2, 0, "EC" .. coreCount .. " ", " Gen", textColor, textColor, buttonColor)
        end
    elseif line == 2 then
        energyPercent = math.ceil(getTotalEnergyStored() / getTotalMaxEnergyStored() * 10000)*.01
        if energyPercent == math.huge or isnan(energyPercent) then
            energyPercent = 0
        end
        energyColor = colors.red
        if energyPercent >= 70 then
            energyColor = colors.green
        elseif energyPercent < 70 and energyPercent > 30 then
            energyColor = colors.orange
        end
        gui.draw_number(mon, getTotalMaxEnergyStored(), x, localY, energyColor, rftColor)
        if drawButtons then
            gui.drawSideButtons(mon, x, localY, buttonColor)
            gui.draw_text_lr(mon, 2, localY + 2, 0, "Out ", "Back", textColor, textColor, buttonColor)
        end
    elseif line == 3 then
        energyPercent = math.ceil(getTotalEnergyStored() / getTotalMaxEnergyStored() * 10000)*.01
        if energyPercent == math.huge or isnan(energyPercent) then
            energyPercent = 0
        end
        energyColor = colors.red
        if energyPercent >= 70 then
            energyColor = colors.green
        elseif energyPercent < 70 and energyPercent > 30 then
            energyColor = colors.orange
        end
        gui.draw_number(mon, getTotalMaxEnergyStored(), x, localY, energyColor, rftColor)
        if drawButtons then
            gui.drawSideButtons(mon, x, localY, buttonColor)
            gui.draw_text_lr(mon, 2, localY + 2, 0, "Out ", "Back", textColor, textColor, buttonColor)
        end
    elseif line == 4 then
        energyPercent = math.ceil(getTotalEnergyStored() / getTotalMaxEnergyStored() * 10000)*.01
        if energyPercent == math.huge or isnan(energyPercent) then
            energyPercent = 0
        end
        energyColor = colors.red
        if energyPercent >= 70 then
            energyColor = colors.green
        elseif energyPercent < 70 and energyPercent > 30 then
            energyColor = colors.orange
        end
        gui.draw_number(mon, getTotalMaxEnergyStored(), x, localY, energyColor, rftColor)
        if drawButtons then
            gui.drawSideButtons(mon, x, localY, buttonColor)
            gui.draw_text_lr(mon, 2, localY + 2, 0, "Out ", "Back", textColor, textColor, buttonColor)
        end
    elseif line == 5 then
        local energyColor, energyPercent
        energyPercent = math.ceil(getTotalEnergyStored() / getTotalMaxEnergyStored() * 10000)*.01
        if energyPercent == math.huge or isnan(energyPercent) then
            energyPercent = 0
        end
        energyColor = colors.red
        if energyPercent >= 70 then
            energyColor = colors.green
        elseif energyPercent < 70 and energyPercent > 30 then
            energyColor = colors.orange
        end
        gui.progress_bar(mon, x, localY, 48, getTotalEnergyStored(), getTotalMaxEnergyStored(), energyColor, colors.light_gray)
        gui.progress_bar(mon, x, localY + 1, 48, getTotalEnergyStored(), getTotalMaxEnergyStored(), energyColor, colors.light_gray)
        gui.progress_bar(mon, x, localY + 2, 48, getTotalEnergyStored(), getTotalMaxEnergyStored(), energyColor, colors.light_gray)
        gui.progress_bar(mon, x, localY + 3, 48, getTotalEnergyStored(), getTotalMaxEnergyStored(), energyColor, colors.light_gray)
        gui.progress_bar(mon, x, localY + 4, 48, getTotalEnergyStored(), getTotalMaxEnergyStored(), energyColor, colors.light_gray)
        if drawButtons then
            gui.drawSideButtons(mon, x, localY, buttonColor)
            gui.draw_text_lr(mon, 2, localY + 2, 0, "Gen ", " EC1", textColor, textColor, buttonColor)
        end
    else
        for i = 1, coreCount do
            if line == i + 5 then
                gui.draw_number(mon, getReactorGeneration(i), x, localY, numberColor, rftColor)
                if drawButtons then
                    gui.drawSideButtons(mon, x, localY, buttonColor)
                    if line == 6 and line == coreCount + 3 then
                        gui.draw_text_lr(mon, 2, localY + 2, 0, "Back", " Out", textColor, textColor, buttonColor)
                    elseif line == 6 then
                        gui.draw_text_lr(mon, 2, localY + 2, 0, "Back", "EC" .. i + 1 .. " ", textColor, textColor, buttonColor)
                    elseif line == coreCount + 5 then
                        gui.draw_text_lr(mon, 2, localY + 2, 0, "EC" .. i - 1 .. " ", " Out", textColor, textColor, buttonColor)
                    else
                        gui.draw_text_lr(mon, 2, localY + 2, 0, "EC" .. i - 1 .. " ", "EC" .. i + 1 .. " ", textColor, textColor, buttonColor)
                    end
                end
            end
        end
    end
end

--run
if mon.X >= 57 then
    if mon.Y < 16 then
        amount = 1
        drawButtons= true
        y = gui.getInteger((mon.Y - 6) / 2)
        parallel.waitForAny(buttons, update)
    elseif mon.Y >= 16 and mon.Y < 24 then
        amount = 2
        drawButtons= true
        y = gui.getInteger((mon.Y - 14) / 2)
        parallel.waitForAny(buttons, update)
    elseif mon.Y >= 24 and mon.Y < 32 then
        amount = 3
        drawButtons= true
        y = gui.getInteger((mon.Y - 22) / 2)
        parallel.waitForAny(buttons, update)
    else
        amount = 4
        drawButtons= true
        y = gui.getInteger((mon.Y - 30) / 2)
        parallel.waitForAny(buttons, update)
    end
else
    if mon.Y < 16 then
        amount = 1
        drawButtons= false
        y = gui.getInteger((mon.Y - 6) / 2)
        update()
    elseif mon.Y >= 16 and mon.Y < 24 then
        amount = 2
        drawButtons= false
        y = gui.getInteger((mon.Y - 14) / 2)
        update()
    elseif mon.Y >= 24 and mon.Y < 32 then
        amount = 3
        drawButtons= false
        y = gui.getInteger((mon.Y - 22) / 2)
        update()
    else
        amount = 4
        drawButtons= false
        y = gui.getInteger((mon.Y - 30) / 2)
        update()
    end
end