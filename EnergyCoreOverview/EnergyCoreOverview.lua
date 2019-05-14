-- configure colors
local numberColor = colors.red
local rftColor = colors.gray
local buttonColor = colors.lightGray
local textColor = colors.white
-- lower number means higher refresh rate but also increases server load
local refresh = 1

-- program
local version = "1.4.0"
os.loadAPI("lib/gui")
os.loadAPI("lib/color")


local totalEnergy, totalMaxEnergy, oldEnergy
local coreEnergy = {}
local coreMaxEnergy = {}

local monitors = {}

local monitorCount = 0
local connectedMonitors = {}
local coreCount = 0
local connectedCores = {}
local periList = peripheral.getNames()
local validPeripherals = {
    "draconic_rf_storage",
    "monitor"
}

-- get all connected peripherals
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
        ["monitor"] = function()
            monitorCount = monitorCount + 1
            connectedMonitors[monitorCount] = periList[i]
            monitors[periList[i] .. ":smallFont"] = false
            monitors[periList[i] .. ":drawButtons"] = false
            monitors[periList[i] .. ":amount"] = 0
            monitors[periList[i] .. ":x"] = 0
            monitors[periList[i] .. ":y"] = 0
            for count = 1, 10 do
                monitors[periList[i] .. ":line" .. count] = count
            end
        end
    }

    local isValid = checkValidity(peripheral.getType(v))
    if isValid then periFunctions[isValid]() end
end

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

function isnan(x)
    return x ~= x
end

--write settings to config file
function save_config()
    local sw = fs.open("config.txt", "w")
    sw.writeLine("-- Config for Draconig Reactor Generation Overview")
    sw.writeLine("version: " .. version	)
    sw.writeLine(" ")
    sw.writeLine("-- configure the display numberColors")
    sw.writeLine("numberColor: " .. color.toString(numberColor))
    sw.writeLine("rftColor: " .. color.toString(rftColor))
    sw.writeLine("buttonColor: " ..  color.toString(buttonColor))
    sw.writeLine("textColor: " ..  color.toString(textColor))
    sw.writeLine(" ")
    sw.writeLine("-- lower number means higher refresh rate but also increases server load")
    sw.writeLine("refresh: " ..  refresh)
    sw.writeLine(" ")
    sw.writeLine("-- small font means a font size of 0.5 instead of 1")
    for i = 1, monitorCount do
        if monitors[connectedMonitors[i] .. ": smallFont"] then
            sw.writeLine(connectedMonitors[i] .. ": smallFont: true")
        else
            sw.writeLine(connectedMonitors[i] .. ": smallFont: false")
        end
    end
    sw.writeLine(" ")
    sw.writeLine("-- just some saved data")
    sw.writeLine("monitorCount: " .. monitorCount)
    for i = 1, monitorCount do
        sw.writeLine(" ")
        sw.writeLine("-- monitor: " .. connectedMonitors[i])
        for count = 1, 10 do
            sw.writeLine(connectedMonitors[i] .. ": line" .. count .. ": " .. monitors[connectedMonitors[i] .. ":line" .. count])
        end
    end
    sw.close()
end

--read settings from file
function load_config()
    local sr = fs.open("config.txt", "r")
    local line = sr.readLine()
    while line do
        if split(line, ": ")[1] == "numberColor" then
            numberColor = color.getColor(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "rftColor" then
            rftColor = color.getColor(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "buttonColor" then
            buttonColor = color.getColor(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "textColor" then
            textColor = color.getColor(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "refresh" then
            refresh = tonumber(split(line, ": ")[2])
        else
            if string.find(split(line, ": ")[1], "monitor_")
                    or split(line, ": ")[1] == "top"
                    or split(line, ": ")[1] == "bottom"
                    or split(line, ": ")[1] == "right"
                    or split(line, ": ")[1] == "left"
                    or split(line, ": ")[1] == "front"
                    or split(line, ": ")[1] == "back" then
                for i = 1, monitorCount do
                    if connectedMonitors[i] == split(line, ": ")[1] then
                        if split(line, ": ")[2] == "smallFont" then
                            if split(line, ": ")[3] == "true" then
                                monitors[connectedMonitors[i] .. ":smallFont"] = true
                            else
                                monitors[connectedMonitors[i] .. ":smallFont"] = false
                            end
                        else
                            for count = 1, 10 do
                                if split(line, ": ")[2] == "line" .. count then
                                    monitors[connectedMonitors[i] .. ":line" .. count] = tonumber(split(line, ": ")[3])
                                end
                            end
                        end
                    end
                end
            end
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


--Check for energycore and monitors before continuing
if coreCount == 0 then
    error("No valid energy core was found")
end

if monitorCount == 0 then
    error("No valid monitor was found")
end


--update the monitor
function update()
    while true do
        drawLines()
        sleep(refresh)
        oldEnergy = totalEnergy
    end
end

--draw the different lines on the screen
function drawLines()
    for i = 1, monitorCount do
        local mon, monitor, monX, monY
        monitor = peripheral.wrap(connectedMonitors[i])
        monX, monY = monitor.getSize()
        mon = {}
        mon.monitor,mon.X, mon.Y = monitor, monX, monY
        local amount = monitors[connectedMonitors[i] .. ":amount"]
        local drawButtons = monitors[connectedMonitors[i] .. ":drawButtons"]
        local x = monitors[connectedMonitors[i] .. ":x"]
        local y = monitors[connectedMonitors[i] .. ":y"]
        totalEnergy = getTotalEnergyStored()
        totalMaxEnergy = getTotalMaxEnergyStored()
        gui.clear(mon)
        print("Total energy stored: " .. gui.format_int(totalEnergy) .. "RF")
        print("Total maximum energy: " .. gui.format_int(totalMaxEnergy) .. "RF")
        print("Total free storage: " .. gui.format_int(totalMaxEnergy - totalEnergy) .. "RF")
        for i = 1, monitorCount do
            coreEnergy[i] = getEnergyStored(i)
            coreMaxEnergy[i] = getMaxEnergyStored(i)
            print("Energy core " .. i .. " energy stored: " .. gui.format_int(coreEnergy[i]) .. "RF")
            print("Energy core " .. i .. " maximum energy: " .. gui.format_int(coreMaxEnergy[i]) .. "RF")
        end
        if amount >= 1 then
            drawLine(mon, x, y, monitors[connectedMonitors[i] .. ":line1"], drawButtons)
        end
        if amount >= 2 then
            gui.draw_line(mon, 0, y+7, mon.X+1, colors.gray)
            drawLine(mon, x, y + 10, monitors[connectedMonitors[i] .. ":line2"], drawButtons)
        end
        if amount >= 3 then
            drawLine(mon, x, y + 18, monitors[connectedMonitors[i] .. ":line3"], drawButtons)
        end
        if amount >= 4 then
            drawLine(mon, x, y + 26, monitors[connectedMonitors[i] .. ":line4"], drawButtons)
        end
        if amount >= 5 then
            drawLine(mon, x, y + 34, monitors[connectedMonitors[i] .. ":line5"], drawButtons)
        end
        if amount >= 6 then
            drawLine(mon, x, y + 42, monitors[connectedMonitors[i] .. ":line6"], drawButtons)
        end
        if amount >= 7 then
            drawLine(mon, x, y + 50, monitors[connectedMonitors[i] .. ":line7"], drawButtons)
        end
        if amount >= 8 then
            drawLine(mon, x, y + 58, monitors[connectedMonitors[i] .. ":line8"], drawButtons)
        end
        if amount >= 9 then
            drawLine(mon, x, y + 66, monitors[connectedMonitors[i] .. ":line9"], drawButtons)
        end
        if amount >= 10 then
            drawLine(mon, x, y + 74, monitors[connectedMonitors[i] .. ":line10"], drawButtons)
        end
    end
end

--handle the monitor touch inputs
function buttons()
    while true do
        -- button handler
        local event, side, xPos, yPos = os.pullEvent("monitor_touch")
        if monitors[side .. ":drawButtons"] then
            local mon, monitor, monX, monY
            monitor = peripheral.wrap(side)
            monX, monY = monitor.getSize()
            mon = {}
            mon.monitor,mon.X, mon.Y = monitor, monX, monY
            if monitors[side .. ":amount"] >= 1 and yPos >= monitors[side .. ":y"] and yPos <= monitors[side .. ":y"] + 4 then
                if xPos >= 1 and xPos <= 5 then
                    monitors[side .. ":line1"] = monitors[side .. ":line1"] - 1
                    if monitors[side .. ":line1"] < 1 then
                        monitors[side .. ":line1"] = (monitorCount * 5) + 6
                    end
                elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
                    monitors[side .. ":line1"] = monitors[side .. ":line1"] + 1
                    if monitors[side .. ":line1"] > (monitorCount * 5) + 6 then
                        monitors[side .. ":line1"] = 1
                    end
                end
                drawLines()
                save_config()
            end

            if monitors[side .. ":amount"] >= 2 and yPos >= monitors[side .. ":y"] + 10 and yPos <= monitors[side .. ":y"] + 14 then
                if xPos >= 1 and xPos <= 5 then
                    monitors[side .. ":line2"] = monitors[side .. ":line2"] - 1
                    if monitors[side .. ":line2"] < 1 then
                        monitors[side .. ":line2"] = (monitorCount * 5) + 6
                    end
                elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
                    monitors[side .. ":line2"] = monitors[side .. ":line2"] + 1
                    if monitors[side .. ":line2"] > (monitorCount * 5) + 6 then
                        monitors[side .. ":line2"] = 1
                    end
                end
                drawLines()
                save_config()
            end

            if monitors[side .. ":amount"] >= 3 and yPos >= monitors[side .. ":y"] + 18 and yPos <= monitors[side .. ":y"] + 22 then
                if xPos >= 1 and xPos <= 5 then
                    monitors[side .. ":line3"] = monitors[side .. ":line3"] - 1
                    if monitors[side .. ":line3"] < 1 then
                        monitors[side .. ":line3"] = (monitorCount * 5) + 6
                    end
                elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
                    monitors[side .. ":line3"] = monitors[side .. ":line3"] + 1
                    if monitors[side .. ":line3"] > (monitorCount * 5) + 6 then
                        monitors[side .. ":line3"] = 1
                    end
                end
                drawLines()
                save_config()
            end

            if monitors[side .. ":amount"] >= 4 and yPos >= monitors[side .. ":y"] + 26 and yPos <= monitors[side .. ":y"] + 30 then
                if xPos >= 1 and xPos <= 5 then
                    monitors[side .. ":line4"] = monitors[side .. ":line4"] - 1
                    if monitors[side .. ":line4"] < 1 then
                        monitors[side .. ":line4"] = (monitorCount * 5) + 6
                    end
                elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
                    monitors[side .. ":line4"] = monitors[side .. ":line4"] + 1
                    if monitors[side .. ":line4"] > (monitorCount * 5) + 6 then
                        monitors[side .. ":line4"] = 1
                    end
                end
                drawLines()
                save_config()
            end

            if monitors[side .. ":amount"] >= 5 and yPos >= monitors[side .. ":y"] + 34 and yPos <= monitors[side .. ":y"] + 38 then
                if xPos >= 1 and xPos <= 5 then
                    monitors[side .. ":line5"] = monitors[side .. ":line5"] - 1
                    if monitors[side .. ":line5"] < 1 then
                        monitors[side .. ":line5"] = (monitorCount * 5) + 6
                    end
                elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
                    monitors[side .. ":line5"] = monitors[side .. ":line5"] + 1
                    if monitors[side .. ":line5"] > (monitorCount * 5) + 6 then
                        monitors[side .. ":line5"] = 1
                    end
                end
                drawLines()
                save_config()
            end

            if monitors[side .. ":amount"] >= 6 and yPos >= monitors[side .. ":y"] + 42 and yPos <= monitors[side .. ":y"] + 46 then
                if xPos >= 1 and xPos <= 5 then
                    monitors[side .. ":line6"] = monitors[side .. ":line6"] - 1
                    if monitors[side .. ":line6"] < 1 then
                        monitors[side .. ":line6"] = (monitorCount * 5) + 6
                    end
                elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
                    monitors[side .. ":line6"] = monitors[side .. ":line6"] + 1
                    if monitors[side .. ":line6"] > (monitorCount * 5) + 6 then
                        monitors[side .. ":line6"] = 1
                    end
                end
                drawLines()
                save_config()
            end

            if monitors[side .. ":amount"] >= 7 and yPos >= monitors[side .. ":y"] + 50 and yPos <= monitors[side .. ":y"] + 54 then
                if xPos >= 1 and xPos <= 5 then
                    monitors[side .. ":line7"] = monitors[side .. ":line7"] - 1
                    if monitors[side .. ":line7"] < 1 then
                        monitors[side .. ":line7"] = (monitorCount * 5) + 6
                    end
                elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
                    monitors[side .. ":line7"] = monitors[side .. ":line7"] + 1
                    if monitors[side .. ":line7"] > (monitorCount * 5) + 6 then
                        monitors[side .. ":line7"] = 1
                    end
                end
                drawLines()
                save_config()
            end

            if monitors[side .. ":amount"] >= 8 and yPos >= monitors[side .. ":y"] + 58 and yPos <= monitors[side .. ":y"] + 62 then
                if xPos >= 1 and xPos <= 5 then
                    monitors[side .. ":line8"] = monitors[side .. ":line8"] - 1
                    if monitors[side .. ":line8"] < 1 then
                        monitors[side .. ":line8"] = (monitorCount * 5) + 6
                    end
                elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
                    monitors[side .. ":line8"] = monitors[side .. ":line8"] + 1
                    if monitors[side .. ":line8"] > (monitorCount * 5) + 6 then
                        monitors[side .. ":line8"] = 1
                    end
                end
                drawLines()
                save_config()
            end

            if monitors[side .. ":amount"] >= 9 and yPos >= monitors[side .. ":y"] + 66 and yPos <= monitors[side .. ":y"] + 70 then
                if xPos >= 1 and xPos <= 5 then
                    monitors[side .. ":line9"] = monitors[side .. ":line9"] - 1
                    if monitors[side .. ":line9"] < 1 then
                        monitors[side .. ":line9"] = (monitorCount * 5) + 6
                    end
                elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
                    monitors[side .. ":line9"] = monitors[side .. ":line9"] + 1
                    if monitors[side .. ":line9"] > (monitorCount * 5) + 6 then
                        monitors[side .. ":line9"] = 1
                    end
                end
                drawLines()
                save_config()
            end

            if monitors[side .. ":amount"] >= 10 and yPos >= monitors[side .. ":y"] + 74 and yPos <= monitors[side .. ":y"] + 78 then
                if xPos >= 1 and xPos <= 5 then
                    monitors[side .. ":line10"] = monitors[side .. ":line10"] - 1
                    if monitors[side .. ":line10"] < 1 then
                        monitors[side .. ":line10"] = (monitorCount * 5) + 6
                    end
                elseif xPos >= mon.X - 5 and xPos <= mon.X - 1 then
                    monitors[side .. ":line10"] = monitors[side .. ":line10"] + 1
                    if monitors[side .. ":line10"] > (monitorCount * 5) + 6 then
                        monitors[side .. ":line10"] = 1
                    end
                end
                drawLines()
                save_config()
            end
        end
    end
end

--draw line with information on the monitor
function drawLine(mon, localX, localY, line, drawButtons)
    if line == 1 then
        gui.draw_integer(mon, totalEnergy, localX + 9, localY, numberColor, rftColor)
        gui.drawRF(mon, localX, localY, rftColor)
        if drawButtons then
            gui.drawSideButtons(mon, localY, buttonColor)
            gui.draw_text_lr(mon, 2, localY + 2, 0, "EC" .. coreCount .. " ", " Max", textColor, textColor, buttonColor)
        end
    elseif line == 2 then
        gui.draw_integer(mon, totalMaxEnergy, localX + 9, localY, numberColor)
        gui.drawRF(mon, localX, localY, rftColor)
        if drawButtons then
            gui.drawSideButtons(mon, localY, buttonColor)
            gui.draw_text_lr(mon, 2, localY + 2, 0, "Ener", "Cent", textColor, textColor, buttonColor)
        end
    elseif line == 3 then
        local energyPercent = math.ceil(totalEnergy / totalMaxEnergy * 10000)*.01
        if energyPercent == math.huge or isnan(energyPercent) then
            energyPercent = 0
        end
        gui.draw_integer(mon, energyPercent , localX, localY, numberColor)
        if drawButtons then
            gui.drawSideButtons(mon, localY, buttonColor)
            gui.draw_text_lr(mon, 2, localY + 2, 0, "Max ", " Bar", textColor, textColor, buttonColor)
        end
    elseif line == 4 then
        local energyPercent = math.ceil(totalEnergy / totalMaxEnergy * 10000)*.01
        if energyPercent == math.huge or isnan(energyPercent) then
            energyPercent = 0
        end
        local energyColor = colors.red
        if energyPercent >= 70 then
            energyColor = colors.green
        elseif energyPercent < 70 and energyPercent > 30 then
            energyColor = colors.orange
        end
        gui.progress_bar(mon, localX, localY, 70, totalEnergy, totalMaxEnergy, energyColor, colors.lightGray)
        gui.progress_bar(mon, localX, localY + 1, 70, totalEnergy, totalMaxEnergy, energyColor, colors.lightGray)
        gui.progress_bar(mon, localX, localY + 2, 70, totalEnergy, totalMaxEnergy, energyColor, colors.lightGray)
        gui.progress_bar(mon, localX, localY + 3, 70, totalEnergy, totalMaxEnergy, energyColor, colors.lightGray)
        gui.progress_bar(mon, localX, localY + 4, 70, totalEnergy, totalMaxEnergy, energyColor, colors.lightGray)
        if drawButtons then
            gui.drawSideButtons(mon, localY, buttonColor)
            gui.draw_text_lr(mon, 2, localY + 2, 0, "Cent", "Flow", textColor, textColor, buttonColor)
        end
    elseif line == 5 then
        local flow = totalEnergy - oldEnergy
        if flow < 0 then
            flow = flow * (-1)
        end
        gui.draw_integer(mon, flow, localX + 9, localY, numberColor)
        gui.drawRF(mon, localX, localY, rftColor)
        if drawButtons then
            gui.drawSideButtons(mon, localY, buttonColor)
            gui.draw_text_lr(mon, 2, localY + 2, 0, "Gen ", " DR1", textColor, textColor, buttonColor)
        end
    elseif line == 6 then
        gui.draw_integer(mon, coreCount, localX, localY, numberColor)
        gui.drawRF(mon, localX, localY, rftColor)
        if drawButtons then
            gui.drawSideButtons(mon, localY, buttonColor)
            gui.draw_text_lr(mon, 2, localY + 2, 0, "Flow", " EC1", textColor, textColor, buttonColor)
        end
    else
        if gui.getModulo(line - 6, 5) == 0 then
            gui.draw_integer(mon, coreEnergy[(line - 6) / 5], localX + 9, localY, numberColor)
            gui.drawRF(mon, localX, localY, rftColor)
        elseif gui.getModulo(line - 6, 5) == 1 then
            gui.draw_integer(mon, coreMaxEnergy[1 + ((line - 7) / 5)], localX + 9, localY, numberColor)
            gui.drawRF(mon, localX, localY, rftColor)
        elseif gui.getModulo(line - 6, 5) == 2 then
            local delimeter = 10 ^ (string.len(tostring(coreEnergy[1 + ((line - 8) / 5)])) - 3)
            local energy = gui.getInteger(coreEnergy[1 + ((line - 8) / 5)] / delimeter) / 100
            local maxDelimeter = 10 ^ (string.len(tostring(coreMaxEnergy[1 + ((line - 8) / 5)])) - 3)
            local maxEnergy = gui.getInteger(coreMaxEnergy[1 + ((line - 8) / 5)] / maxDelimeter) / 100
            local length = string.len(tostring(coreMaxEnergy[1 + ((line - 8) / 5)]))

            gui.draw_integer(mon, energy, localX + 14 + (length * 4) + (2 * gui.getInteger((length - 1) / 3)) - 1, localY, numberColor)
            gui.draw_slash(mon, localX + 10 + (length * 4) + (2 * gui.getInteger((length - 1) / 3)) - 1, localY, rftColor)
            gui.draw_integer(mon, maxEnergy, localX + 9, localY, numberColor)
            gui.drawRF(mon, localX, localY, rftColor)
        elseif gui.getModulo(line - 6, 5) == 3 then
            local energyPercent = math.ceil(coreEnergy[1 + ((line - 10) / 5)] / coreMaxEnergy[1 + ((line - 10) / 5)] * 10000)*.01
            if energyPercent == math.huge or isnan(energyPercent) then
                energyPercent = 0
            end
            gui.draw_integer(mon, energyPercent, localX, localY, numberColor)
        elseif gui.getModulo(line - 6, 5) == 4 then
            local energyPercent = math.ceil(coreEnergy[1 + ((line - 10) / 5)] / coreMaxEnergy[1 + ((line - 10) / 5)] * 10000)*.01
            if energyPercent == math.huge or isnan(energyPercent) then
                energyPercent = 0
            end
            local energyColor = colors.red
            if energyPercent >= 70 then
                energyColor = colors.green
            elseif energyPercent < 70 and energyPercent > 30 then
                energyColor = colors.orange
            end
            gui.progress_bar(mon, localX, localY, 70, coreEnergy[1 + ((line - 10) / 5)], coreMaxEnergy[1 + ((line - 10) / 5)], energyColor, colors.lightGray)
            gui.progress_bar(mon, localX, localY + 1, 70, coreEnergy[1 + ((line - 10) / 5)], coreMaxEnergy[1 + ((line - 10) / 5)], energyColor, colors.lightGray)
            gui.progress_bar(mon, localX, localY + 2, 70, coreEnergy[1 + ((line - 10) / 5)], coreMaxEnergy[1 + ((line - 10) / 5)], energyColor, colors.lightGray)
            gui.progress_bar(mon, localX, localY + 3, 70, coreEnergy[1 + ((line - 10) / 5)], coreMaxEnergy[1 + ((line - 10) / 5)], energyColor, colors.lightGray)
            gui.progress_bar(mon, localX, localY + 4, 70, coreEnergy[1 + ((line - 10) / 5)], coreMaxEnergy[1 + ((line - 10) / 5)], energyColor, colors.lightGray)
        end
    end
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

-- check that every line displays something
function checkLines()
    for i = 1, monitorCount do
        if monitors[connectedMonitors[i] .. ":line1"] > (monitorCount * 5) + 6 then
            monitors[connectedMonitors[i] .. ":line1"] = (monitorCount * 5) + 6
        end
        if monitors[connectedMonitors[i] .. ":line2"] > (monitorCount * 5) + 6 then
            monitors[connectedMonitors[i] .. ":line2"] = (monitorCount * 5) + 6
        end
        if monitors[connectedMonitors[i] .. ":line3"] > (monitorCount * 5) + 6 then
            monitors[connectedMonitors[i] .. ":line3"] = (monitorCount * 5) + 6
        end
        if monitors[connectedMonitors[i] .. ":line4"] > (monitorCount * 5) + 6 then
            monitors[connectedMonitors[i] .. ":line4"] = (monitorCount * 5) + 6
        end
        if monitors[connectedMonitors[i] .. ":line5"] > (monitorCount * 5) + 6 then
            monitors[connectedMonitors[i] .. ":line5"] = (monitorCount * 5) + 6
        end
        if monitors[connectedMonitors[i] .. ":line6"] > (monitorCount * 5) + 6 then
            monitors[connectedMonitors[i] .. ":line6"] = (monitorCount * 5) + 6
        end
        if monitors[connectedMonitors[i] .. ":line7"] > (monitorCount * 5) + 6 then
            monitors[connectedMonitors[i] .. ":line7"] = (monitorCount * 5) + 6
        end
        if monitors[connectedMonitors[i] .. ":line8"] > (monitorCount * 5) + 6 then
            monitors[connectedMonitors[i] .. ":line8"] = (monitorCount * 5) + 6
        end
        if monitors[connectedMonitors[i] .. ":line9"] > (monitorCount * 5) + 6 then
            monitors[connectedMonitors[i] .. ":line9"] = (monitorCount * 5) + 6
        end
        if monitors[connectedMonitors[i] .. ":line10"] > (monitorCount * 5) + 6 then
            monitors[connectedMonitors[i] .. ":line10"] = (monitorCount * 5) + 6
        end
    end
    save_config()
end

--initialize all the values
function init()
    for i = 1, monitorCount do
        local mon, monitor, monX, monY
        monitor = peripheral.wrap(connectedMonitors[i])
        monX, monY = monitor.getSize()
        mon = {}
        mon.monitor,mon.X, mon.Y = monitor, monX, monY
        if mon.Y <=	5 or monitors[connectedMonitors[i] .. ":smallFont"] then
            monitor.setTextScale(0.5)
            monX, monY = monitor.getSize()
            mon = {}
            mon.monitor,mon.X, mon.Y = monitor, monX, monY
        end
        local amount = 0
        if mon.Y < 16 then
            amount = 1
            monitors[connectedMonitors[i] .. ":y"] = gui.getInteger((mon.Y - 3) / 2)
        else
            local localY = mon.Y - 2
            local int = 8
            while int <= localY do
                int = int + 8
                amount = amount + 1
            end
            monitors[connectedMonitors[i] .. ":y"] = gui.getInteger((mon.Y + 3 - (8 * amount)) / 2)
        end
        monitors[connectedMonitors[i] .. ":amount"] = amount
        if mon.X >= 57 then
            monitors[connectedMonitors[i] .. ":drawButtons"] = true
        else
            monitors[connectedMonitors[i] .. ":drawButtons"] = false
        end
        monitors[connectedMonitors[i] .. ":x"] = gui.getInteger((mon.X - 70) / 2)
    end
end

--run
checkLines()

init()

parallel.waitForAny(buttons, update)