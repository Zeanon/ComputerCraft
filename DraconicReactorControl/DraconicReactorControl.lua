-- Draconic Reactor Control program by drmon(forked by Zeanon)

-- Version
local version = "1.8.0"

-- Peripherals
local internalInput = "flux_gate_0"
local internalOutput = "flux_gate_1"
local externalOutput = "flux_gate_2"

-- target strength of the containment field
local targetStrength = 30
-- maximum temperature the reactor may reach
local maxTemperature = 7000
local tempBoost1Output = 400000
local tempBoost2Output = 750000
local tempBoost3Output = 1000000
-- temperature the programm should keep the reactor at
local safeTemperature = 5000
-- if the containment field gets below this value the reactor will be shut down
local minFieldPercent = 20
local fieldBoost = 25
local fieldBoostOutput = 400000
-- different boost levels for energySaturation
local satBoostThreshold = 25
local satBoost1 = 35
local satBoost1Output = 600000
local satBoost2 = 45
local satBoost2Output = 1000000
-- tolerances for auto boosting
local genTolerance = 250
local satTolerance = 2
local tempTolerance = 10
local maxIncrease = 10000
local safeTarget = 100000
-- the amount of turns the program goes through until the output can be changed again
local minChangeWait = 10
-- the amount of turns the program will save to check whether the reactor is stable
local stableTurns = 25
-- maximum output level
local maxTargetGeneration = 1500000
-- target saturation
local targetSat = 50
-- minimum fuelPercent needed
local minFuelPercent = 15

local activateOnCharged = true

-- please leave things untouched from here on
os.loadAPI("lib/gui")

-- toggleable via the monitor, use our algorithm to achieve our target field strength or let the user tweak it
local autoInputGate = true
local curInputGate = 222000
local targetGeneration = 100000
local threshold = -1
local tempthreshold = -1
local satthreshold = -1
local fieldthreshold = -1
local fuelthreshold = -1
local energythreshold = -1
local outputInputHyteresis = 25000
local lastTemp = {}
local lastGen = {}
local lastSat = {}
local thresholded = false
local emergencyFlood = false
local sinceOutputChange = 0
local editConfigButton = 0
local loadConfigButton = 0
local loadConfigReboot = false

-- monitor
local mon, monitor, monX, monY

-- peripherals
local reactor, core, externalfluxgate, inputfluxgate, outputfluxgate

-- reactor information
local ri

-- last performed action
local action = "None since reboot"
local emergencyCharge = false
local emergencyTemp = false

-- some percentages
local satPercent, fieldPercent, fuelPercent, energyPercent

--write settings to config file
function save_config()
    local sw = fs.open("config.txt", "w")
    sw.writeLine("-- Config for Draconig Reactor Control Program")
    sw.writeLine("version: " .. version)
    sw.writeLine(" ")
    sw.writeLine("-- FluxGate modem names")
    sw.writeLine("internalInput: " .. internalInput)
    sw.writeLine("internalOutput: " .. internalOutput)
    sw.writeLine("externalOutput: " .. externalOutput)
    sw.writeLine(" ")
    sw.writeLine("-- numbers for the temperatureBoost steps")
    sw.writeLine("safeTemperature: " .. safeTemperature)
    sw.writeLine("maxTemperature: " .. maxTemperature)
    sw.writeLine("tempBoost1Output: " .. tempBoost1Output)
    sw.writeLine("tempBoost2Output: " .. tempBoost2Output)
    sw.writeLine("tempBoost3Output: " .. tempBoost3Output)
    sw.writeLine(" ")
    sw.writeLine("-- numbers for the fieldBoost steps")
    sw.writeLine("targetStrength: " .. targetStrength)
    sw.writeLine("minFieldPercent: " .. minFieldPercent)
    sw.writeLine("fieldBoost: " .. fieldBoost)
    sw.writeLine("fieldBoostOutput: " .. fieldBoostOutput)
    sw.writeLine(" ")
    sw.writeLine("-- numbers for the saturationBoost steps")
    sw.writeLine("targetSat: " .. targetSat)
    sw.writeLine("satBoostThreshold: " .. satBoostThreshold)
    sw.writeLine("satBoost1: " .. satBoost1)
    sw.writeLine("satBoost1Output: " .. satBoost1Output)
    sw.writeLine("satBoost2: " .. satBoost2)
    sw.writeLine("satBoost2Output: " .. satBoost2Output)
    sw.writeLine(" ")
    sw.writeLine("-- genTolerance and tempTolerance are absolute numbers, satTolerance is in percent")
    sw.writeLine("genTolerance: " .. genTolerance)
    sw.writeLine("satTolerance: " .. satTolerance)
    sw.writeLine("tempTolerance: " .. tempTolerance)
    sw.writeLine(" ")
    sw.writeLine("-- maxIncrease is the maximum amount the externalOutput can be increased by in one step")
    sw.writeLine("maxIncrease: " .. maxIncrease)
    sw.writeLine(" ")
    sw.writeLine("-- under this generation limit the algorythm won't do anything and the output will just be set to this amount")
    sw.writeLine("safeTarget: " .. safeTarget)
    sw.writeLine(" ")
    sw.writeLine("-- minimum fuelPercent needed so the reactor stays online")
    sw.writeLine("minFuelPercent: " .. minFuelPercent)
    sw.writeLine(" ")
    sw.writeLine("-- the minimum turns to wait for the next output increase after one was done")
    sw.writeLine("minChangeWait: " .. minChangeWait)
    sw.writeLine(" ")
    sw.writeLine("-- the amount of turns to be checked for stability")
    sw.writeLine("stableTurns: " .. stableTurns)
    sw.writeLine(" ")
    sw.writeLine("-- the maximum allowed output(-1 equals infinite)")
    sw.writeLine("maxTargetGeneration: " .. maxTargetGeneration)
    sw.writeLine(" ")
    sw.writeLine("-- whether the reactor shall be started when it is fully charged")
    if activateOnCharged then
        sw.writeLine("activateOnCharged: true")
    else
        sw.writeLine("activateOnCharged: false")
    end
    sw.writeLine(" ")
    sw.writeLine(" ")
    sw.writeLine(" ")
    sw.writeLine(" ")
    sw.writeLine(" ")
    sw.writeLine(" ")
    sw.writeLine(" ")
    sw.writeLine(" ")
    sw.writeLine(" ")
    sw.writeLine(" ")
    sw.writeLine(" ")
    sw.writeLine(" ")
    sw.writeLine(" ")
    sw.writeLine(" ")
    sw.writeLine(" ")
    sw.writeLine(" ")
    sw.writeLine(" ")
    sw.writeLine(" ")
    sw.writeLine(" ")
    sw.writeLine("-- just some saved data")
    if autoInputGate then
        sw.writeLine("autoInputGate: true")
    else
        sw.writeLine("autoInputGate: false")
    end
    sw.writeLine("curInputGate: " .. curInputGate)
    sw.writeLine("targetGeneration: " .. targetGeneration)
    sw.close()
end

--read settings from file
function load_config()
    local sr = fs.open("config.txt", "r")
    local curVersion
    local line = sr.readLine()
    while line do
        if gui.split(line, ": ")[1] == "version" then
            curVersion = gui.split(line, ": ")[2]
        elseif gui.split(line, ": ")[1] == "autoInputGate" then
            if gui.split(line, ": ")[2] == "true" then
                autoInputGate = true
            else
                autoInputGate = false
            end
        elseif gui.split(line, ": ")[1] == "activateOnCharged" then
            if gui.split(line, ": ")[2] == "true" then
                activateOnCharged = true
            else
                activateOnCharged = false
            end
        elseif gui.split(line, ": ")[1] == "curInputGate" then
            curInputGate = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "targetGeneration" then
            targetGeneration = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "targetStrength" then
            targetStrength = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "safeTemperature" then
            safeTemperature = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "maxTemperature" then
            maxTemperature = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "tempBoost1Output" then
            tempBoost1Output = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "tempBoost2Output" then
            tempBoost2Output = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "tempBoost3Output" then
            tempBoost3Output = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "minFieldPercent" then
            minFieldPercent = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "fieldBoost" then
            fieldBoost = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "fieldBoostOutput" then
            fieldBoostOutput = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "satBoostThreshold" then
            satBoostThreshold = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "satBoost1" then
            satBoost1 = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "satBoost1Output" then
            satBoost1Output = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "satBoost2" then
            satBoost2 = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "satBoost2Output" then
            satBoost2Output = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "genTolerance" then
            genTolerance = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "satTolerance" then
            satTolerance = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "tempTolerance" then
            tempTolerance = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "maxIncrease" then
            maxIncrease = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "safeTarget" then
            safeTarget = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "minFuelPercent" then
            minFuelPercent = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "minChangeWait" then
            minChangeWait = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "stableTurns" then
            stableTurns = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "maxTargetGeneration" then
            maxTargetGeneration = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "targetSat" then
            targetSat = tonumber(gui.split(line, ": ")[2])
        elseif gui.split(line, ": ")[1] == "internalInput" then
            internalInput = gui.split(line, ": ")[2]
        elseif gui.split(line, ": ")[1] == "internalOutput" then
            internalOutput = gui.split(line, ": ")[2]
        elseif gui.split(line, ": ")[1] == "externalOutput" then
            externalOutput = gui.split(line, ": ")[2]
        end
        line = sr.readLine()
    end
    sr.close()
    if targetGeneration > maxTargetGeneration and maxTargetGeneration >= 0 then
        targetGeneration = maxTargetGeneration
    end
    if curVersion ~= version then
        save_config()
    end
end

--open a new tab with the config file
function editConfig()
    local new = true
    local i = 1
    while i <= multishell.getCount() do
        if multishell.getTitle(i) == "Config" then
            multishell.setFocus(i)
            new = false
        end
        i = i + 1
    end
    if new then
        local newTabID = shell.openTab("edit", "config.txt")
        multishell.setTitle(newTabID, "Config")
        multishell.setFocus(newTabID)
    end
end

--initialize the tables for stability checking
function initTables()
    local i = 1
    while i <= stableTurns do
        lastGen[i] = 0
        lastSat[i] = 0
        lastTemp[i] = 0
        i = i + 1
    end
end

-- 1st time? save our settings, if not, load our settings
if fs.exists("config.txt") then
    load_config()
else
    save_config()
end

initTables()

--initialize the peripherals
reactor = peripheral.find("draconic_reactor")
core = peripheral.find("draconic_rf_storage")
monitor = peripheral.find("monitor")
inputfluxgate = peripheral.wrap(internalInput)
outputfluxgate = peripheral.wrap(internalOutput)
externalfluxgate = peripheral.wrap(externalOutput)


if reactor == null then
    error("No valid reactor was found")
elseif core == null or core.getMaxEnergyStored() < 1500000 then
    error("No valid energy core was found")
elseif monitor == null then
    error("No valid monitor was found")
elseif inputfluxgate == null then
    editConfig()
    error("No valid input flux gate was found")
elseif outputfluxgate == null then
    editConfig()
    error("No valid internal output flux gate was found")
elseif externalfluxgate == null then
    editConfig()
    error("No valid external output fluxgate was found")
end



monX, monY = monitor.getSize()
mon = {}
mon.monitor, mon.X, mon.Y = monitor, monX, monY


--handle the monitor touch inputs
function buttons()
    while true do
        -- button handler
        local event, side, xPos, yPos = os.pullEvent("monitor_touch")

        -- reactor control
        if yPos >= 1 and yPos <= 3 and xPos >= mon.X - 16 and xPos <= mon.X - 1 and core.getEnergyStored() > 1500000 then
            if ri.status == "online" or ri.status == "charging" or ri.status == "charged" then
                reactor.stopReactor()
            elseif (ri.status == "offline" or ri.status == "stopping") and fuelPercent > minFuelPercent then
                reactor.chargeReactor()
            end
        end

        -- edit or load Config
        if yPos >= 6 and yPos <= 8 then
            if xPos >= mon.X - 25 and xPos <= mon.X - 14 then
                editConfig()
                gui.draw_line(mon, mon.X - 23, 6, 11, colors.lightBlue)
                gui.draw_text(mon, mon.X - 23, 7, "Edit Config", colors.white, colors.lightBlue)
                gui.draw_line(mon, mon.X - 23, 8, 11, colors.lightBlue)
                editConfigButton = 3
            elseif xPos >= mon.X - 12 and xPos <= mon.X - 2 then
                gui.draw_line(mon, mon.X - 11, 6, 11, colors.orange)
                gui.draw_text(mon, mon.X - 11, 7, "Load Config", colors.white, colors.orange)
                gui.draw_line(mon, mon.X - 11, 8, 11, colors.orange)
                loadConfigButton = 3
            end
        end

        -- output gate controls
        -- 2-4 = -1000, 6-9 = -10000, 10-12,8 = -100000
        -- 17-19 = +1000, 21-23 = +10000, 25-27 = +100000
        if yPos >= 5 and yPos <= 6 then
            if xPos >= 2 and xPos <= 4 then
                targetGeneration = targetGeneration - 1000
            elseif xPos >= 6 and xPos <= 8 then
                targetGeneration = targetGeneration - 10000
            elseif xPos >= 10 and xPos <= 12 then
                targetGeneration = targetGeneration - 100000
            elseif xPos >= 17 and xPos <= 19 then
                targetGeneration = targetGeneration + 100000
            elseif xPos >= 21 and xPos <= 23 then
                targetGeneration = targetGeneration + 10000
            elseif xPos >= 25 and xPos <= 27 then
                targetGeneration = targetGeneration + 1000
            end

            if targetGeneration == math.huge or isnan(targetGeneration) then
                targetGeneration = 0
            end

            if targetGeneration > maxTargetGeneration and maxTargetGeneration >= 0 then
                targetGeneration = maxTargetGeneration
            end

            save_config()
            gui.draw_text_lr(mon, 2, 4, 26, "Target Generation", gui.format_int(targetGeneration) .. " RF/t", colors.white, colors.green, colors.black)
        end

        -- input gate controls
        -- 2-4 = -1000, 6-9 = -10000, 10-12,8 = -100000
        -- 17-19 = +1000, 21-23 = +10000, 25-27 = +100000
        if yPos == 8 and autoInputGate == false and xPos ~= 14 and xPos ~= 15 then
            if xPos >= 2 and xPos <= 4 then
                curInputGate = curInputGate - 1000
            elseif xPos >= 6 and xPos <= 9 then
                curInputGate = curInputGate - 10000
            elseif xPos >= 10 and xPos <= 12 then
                curInputGate = curInputGate - 100000
            elseif xPos >= 17 and xPos <= 19 then
                curInputGate = curInputGate + 100000
            elseif xPos >= 21 and xPos <= 23 then
                curInputGate = curInputGate + 10000
            elseif xPos >= 25 and xPos <= 27 then
                curInputGate = curInputGate + 1000
            end

            if curInputGate == math.huge or isnan(curInputGate) or curInputGate < 0 then
                curInputGate = 0
            end

            if curInputGate > maxTargetGeneration then
                curInputGate = maxTargetGeneration
            end

            inputfluxgate.setSignalLowFlow(curInputGate)
            inputfluxgate.setSignalHighFlow(curInputGate)

            save_config()
            gui.draw_text_lr(mon, 2, 7, 28, "Input Gate", gui.format_int(inputfluxgate.getSignalLowFlow()) .. " RF/t", colors.white, colors.blue, colors.black)
        end

        -- input gate toggle
        if yPos == 8 and (xPos == 14 or xPos == 15) then
            if autoInputGate then
                autoInputGate = false
                save_config()
                gui.draw_text(mon, 14, 8, "MA", colors.white, colors.green)
                drawButtons(8)
            else
                autoInputGate = true
                save_config()
                gui.draw_text(mon, 14, 8, "AU", colors.white, colors.lightGray)
            end
        end
    end
end


function drawButtons(y)
    -- 2-4 = -1000, 6-9 = -10000, 10-12,8 = -100000
    -- 17-19 = +1000, 21-23 = +10000, 25-27 = +100000
    gui.drawButtons(mon, 2, y, colors.white, colors.lightBlue, colors.purple)
end


function update()
    
    -- block external access to the fluxgates
    inputfluxgate.setOverrideEnabled(false)
    outputfluxgate.setOverrideEnabled(false)
    externalfluxgate.setOverrideEnabled(false)

    while true do
        ri = reactor.getReactorInfo()

        -- check, if reactor has valid setup
        if ri == nil then
            error("reactor has an invalid setup")
        end


        local satColor
        satPercent = math.ceil(ri.energySaturation / ri.maxEnergySaturation * 10000) * .01
        if satPercent == math.huge or isnan(satPercent) then
            satPercent = 0
        end
        if satPercent > satBoost2 then
            satColor = colors.green
        elseif satPercent <= satBoost2 and satPercent > satBoost1 then
            satColor = colors.yellow
        elseif satPercent <= satBoost1 and satPercent > satBoostThreshold then
            satColor = colors.orange
        else
            satColor = colors.red
        end

        local tempColor
        if ri.temperature <= (maxTemperature / 8) * 5 then
            tempColor = colors.green
        elseif ri.temperature > (maxTemperature / 8) * 5 and ri.temperature <= (maxTemperature / 8) * 7 then
            tempColor = colors.orange
        else
            local tempColor = colors.red
        end

        local fieldColor
        fieldPercent = math.ceil(ri.fieldStrength / ri.maxFieldStrength * 10000) * .01
        if fieldPercent == math.huge or isnan(fieldPercent) then
            fieldPercent = 0
        end
        if fieldPercent >= fieldBoost then
            fieldColor = colors.green
        elseif fieldPercent < fieldBoost and fieldPercent >= minFieldPercent then
            fieldColor = colors.orange
        else
            fieldColor = colors.red
        end

        local fuelColor
        fuelPercent = 100 - math.ceil(ri.fuelConversion / ri.maxFuelConversion * 10000) * .01
        if fuelPercent == math.huge or isnan(fuelPercent) then
            fuelPercent = 0
        end
        if fuelPercent >= 70 then
            fuelColor = colors.green
        elseif fuelPercent < 70 and fuelPercent > 30 then
            fuelColor = colors.orange
        else
            fuelColor = colors.red
        end

        local energyColor
        energyPercent = math.ceil(core.getEnergyStored() / core.getMaxEnergyStored() * 10000) * .01
        if energyPercent == math.huge or isnan(energyPercent) then
            energyPercent = 0
        end
        if energyPercent >= 70 then
            energyColor = colors.green
        elseif energyPercent < 70 and energyPercent > 30 then
            energyColor = colors.orange
        else
            energyColor = colors.red
        end

        local statusColor
        if ri.status == "online" or ri.status == "charged" then
            statusColor = colors.green
            for k, v in pairs(redstone.getSides()) do
                redstone.setOutput(v, true)
            end
        elseif ri.status == "offline" then
            statusColor = colors.lightGray
            for k, v in pairs(redstone.getSides()) do
                redstone.setOutput(v, false)
            end
        elseif ri.status == "charging" then
            statusColor = colors.orange
            for k, v in pairs(redstone.getSides()) do
                redstone.setOutput(v, true)
            end
        elseif ri.status == "stopping" then
            statusColor = colors.red
            for k, v in pairs(redstone.getSides()) do
                redstone.setOutput(v, true)
            end
        end


        -- SAFEGUARDS -- DONT EDIT

        -- out of fuel, kill it
        if fuelPercent < minFuelPercent then
            action = "Fuel below " .. minFuelPercent .. "%"
            reactor.stopReactor()
            fuelthreshold = 0
        else
            fuelthreshold = -1
        end

        -- Saturation too low, regulate Output
        if satPercent <= satBoostThreshold and ri.status ~= "offline" then
            satthreshold = 0
        elseif satPercent <= satBoost1 and ri.status ~= "offline" then
            satthreshold = satBoost1Output
        elseif satPercent <= satBoost2 and ri.status ~= "offline" then
            satthreshold = satBoost2Output
        else
            satthreshold = -1
        end

        -- field strength is close to dangerous, fire up input
        if fieldPercent < fieldBoost and ri.status ~= "offline" then
            action = "Field Str dangerous"
            emergencyFlood = true
            inputfluxgate.setSignalLowFlow(900000)
            inputfluxgate.setSignalHighFlow(900000)
            outputfluxgate.setSignalLowFlow(900000 + outputInputHyteresis)
            outputfluxgate.setSignalHighFlow(900000 + outputInputHyteresis)
            fieldthreshold = fieldBoostOutput
        else
            emergencyFlood = false
            fieldthreshold = -1
        end

        -- field strength is too dangerous, kill it and try to charge it before it blows
        if fieldPercent < minFieldPercent and ri.status ~= "offline" then
            action = "Field Str < " .. minFieldPercent .. "%"
            reactor.stopReactor()
            reactor.chargeReactor()
            emergencyCharge = true
            fieldthreshold = 0
        else
            fieldthreshold = -1
        end

        -- temperature too high, kill it and activate it when its cool
        if ri.temperature > maxTemperature then
            action = "Temp > " .. maxTemperature
            reactor.stopReactor()
            emergencyTemp = true
            tempthreshold = 0
        elseif ri.temperature > maxTemperature - ((maxTemperature - safeTemperature) / 4) then
            tempthreshold = tempBoost1Output
        elseif ri.temperature > maxTemperature - ((maxTemperature - safeTemperature) / 2) then
            tempthreshold = tempBoost2Output
        elseif ri.temperature > safeTemperature + ((maxTemperature - safeTemperature) / 4) then
            tempthreshold = tempBoost3Output
        else
            tempthreshold = -1
        end

        -- check for emergenyCharge
        if emergencyCharge == true then
            reactor.chargeReactor()
        end


        -- actual reactor interaction

        -- are we stopping from a shutdown and our temp is better? activate
        if emergencyTemp == true and ri.status == "stopping" and ri.temperature < safeTemperature then
            reactor.activateReactor()
            emergencyTemp = false
        end

        -- are we charged? lets activate
        if ri.status == "charged" and activateOnCharged then
            reactor.activateReactor()
        end

        -- are we charging? open the floodgates
        if ri.status == "charging" then
            inputfluxgate.setSignalLowFlow(900000)
            inputfluxgate.setSignalHighFlow(900000)
            outputfluxgate.setSignalLowFlow(900000 + outputInputHyteresis)
            outputfluxgate.setSignalHighFlow(900000 + outputInputHyteresis)
            emergencyCharge = false
        end

        -- get the hysteresis for the internal output gate
        if ri.status == "offline" then
            outputInputHyteresis = 0
        elseif core.getEnergyStored() >= 1000000 then
            if energyPercent == 100 then
                outputInputHyteresis = 0
            elseif energyPercent >= 95 and energyPercent < 100 then
                outputInputHyteresis = 10000
            elseif energyPercent >= 90 and energyPercent < 95 then
                outputInputHyteresis = 25000
            elseif energyPercent >= 80 and energyPercent < 90 then
                outputInputHyteresis = 50000
            elseif energyPercent >= 70 and energyPercent < 80 then
                outputInputHyteresis = 75000
            elseif energyPercent >= 60 and energyPercent < 70 then
                outputInputHyteresis = 100000
            elseif energyPercent >= 50 and energyPercent < 60 then
                outputInputHyteresis = 125000
            elseif energyPercent >= 40 and energyPercent < 50 then
                outputInputHyteresis = 250000
            elseif energyPercent >= 30 and energyPercent < 40 then
                outputInputHyteresis = 500000
            else
                action = "Not enough buffer energy"
                reactor.stopReactor()
                satthreshold = 0
            end
        else
            action = "Not enough buffer energy"
            reactor.stopReactor()
            satthreshold = 0
        end

        -- are we on? regulate the input fludgate to our target field strength
        -- or set it to our saved setting since we are on manual
        local fluxval = 0
        if emergencyFlood == false and (ri.status == "online" or ri.status == "stopping") then
            if autoInputGate then
                fluxval = ri.fieldDrainRate / (1 - (targetStrength / 100))
                inputfluxgate.setSignalLowFlow(fluxval)
                inputfluxgate.setSignalHighFlow(fluxval)
            else
                inputfluxgate.setSignalLowFlow(curInputGate)
                inputfluxgate.setSignalHighFlow(curInputGate)
            end
        end

        -- get the different output values
        getOutput()

        -- clear monitor and computer screens
        gui.clear(mon)


        -- print information on the computer
        print("|# -------------Reactor Information------------- #|")
        for k, v in pairs(ri) do
            print("|# " .. k .. ": " .. v)
        end
        print("|# Fuel: ", fuelPercent)
        print("|# External Gate: ", externalfluxgate.getSignalLowFlow())
        print("|# Target Gate: ", fluxval)
        print("|# Input Gate: ", inputfluxgate.getSignalLowFlow())
        print("|# Till next change: " .. sinceOutputChange)


        -- monitor output
        if ri.status == "offline" then
            gui.draw_text_lr(mon, 2, 2, 26, "Generation", gui.format_int(0) .. " RF/t", colors.white, colors.lime, colors.black)
        else
            gui.draw_text_lr(mon, 2, 2, 26, "Generation", gui.format_int(ri.generationRate) .. " RF/t", colors.white, colors.lime, colors.black)
        end

        gui.draw_text_lr(mon, 2, 4, 26, "Target Generation", gui.format_int(targetGeneration) .. " RF/t", colors.white, colors.green, colors.black)
        drawButtons(5)

        if ri.status == "offline" and autoInputGate then
            gui.draw_text_lr(mon, 2, 7, 26, "Input Gate", gui.format_int(0) .. " RF/t", colors.white, colors.blue, colors.black)
        else
            gui.draw_text_lr(mon, 2, 7, 26, "Input Gate", gui.format_int(inputfluxgate.getSignalLowFlow()) .. " RF/t", colors.white, colors.blue, colors.black)
        end

        if autoInputGate then
            gui.draw_text(mon, 14, 8, "AU", colors.white, colors.lightGray)
        else
            gui.draw_text(mon, 14, 8, "MA", colors.white, colors.green)
            drawButtons(8)
        end

        gui.draw_line(mon, 0, 10, mon.X + 1, colors.gray)
        gui.draw_column(mon, mon.X - 25, 1, mon.Y, colors.gray)

        gui.draw_text_lr(mon, 2, 12, 26, "Energy Saturation", satPercent .. "%", colors.white, satColor, colors.black)
        gui.progress_bar(mon, 2, 13, mon.X - 28, satPercent, 100, colors.blue, colors.lightGray)

        gui.draw_text_lr(mon, 2, 15, 26, "Temperature  M:" .. maxTemperature .. "C", gui.format_int(ri.temperature) .. "C", colors.white, tempColor, colors.black)
        gui.progress_bar(mon, 2, 16, mon.X - 28, ri.temperature, maxTemperature, tempColor, colors.lightGray)

        if autoInputGate then
            gui.draw_text_lr(mon, 2, 18, 26, "Field Strength  T:" .. targetStrength, fieldPercent .. "%", colors.white, fieldColor, colors.black)
        else
            gui.draw_text_lr(mon, 2, 18, 26, "Field Strength", fieldPercent .. "%", colors.white, fieldColor, colors.black)
        end
        gui.progress_bar(mon, 2, 19, mon.X - 28, fieldPercent, 100, fieldColor, colors.lightGray)

        gui.draw_text_lr(mon, 2, 21, 26, "Core Energy Level", energyPercent .. "%", colors.white, energyColor, colors.black)
        gui.progress_bar(mon, 2, 22, mon.X - 28, energyPercent, 100, energyColor, colors.lightGray)

        gui.draw_text_lr(mon, 2, 24, 26, "Fuel ", fuelPercent .. "%", colors.white, fuelColor, colors.black)
        gui.progress_bar(mon, 2, 25, mon.X - 28, fuelPercent, 100, fuelColor, colors.lightGray)

        gui.draw_text_lr(mon, 2, 26, 26, "Last:", action, colors.lightGray, colors.lightGray, colors.black)



        if fuelPercent > 10 then
            gui.draw_text_lr(mon, mon.X - 23, 2, 0, "Status", string.upper(ri.status), colors.white, statusColor, colors.black)
        else
            gui.draw_text_lr(mon, mon.X - 23, 2, 0, "Status", "REFUEL NEEDED", colors.white, colors.red, colors.black)
        end

        gui.draw_text_lr(mon, mon.X - 23, 4, 0, "Output", gui.format_int(externalfluxgate.getSignalLowFlow()) .. " RF/t", colors.white, colors.blue, colors.black)

        if editConfigButton == 0 then
            gui.draw_line(mon, mon.X - 23, 6, 11, colors.cyan)
            gui.draw_text(mon, mon.X - 23, 7, "Edit Config", colors.white, colors.cyan)
            gui.draw_line(mon, mon.X - 23, 8, 11, colors.cyan)
        else
            gui.draw_line(mon, mon.X - 23, 6, 11, colors.lightBlue)
            gui.draw_text(mon, mon.X - 23, 7, "Edit Config", colors.white, colors.lightBlue)
            gui.draw_line(mon, mon.X - 23, 8, 11, colors.lightBlue)
        end
        if loadConfigButton == 0 then
            gui.draw_line(mon, mon.X - 11, 8, 11, colors.red)
            gui.draw_text(mon, mon.X - 11, 7, "Load Config", colors.white, colors.red)
            gui.draw_line(mon, mon.X - 11, 6, 11, colors.red)
        else
            gui.draw_line(mon, mon.X - 11, 8, 11, colors.orange)
            gui.draw_text(mon, mon.X - 11, 7, "Load Config", colors.white, colors.orange)
            gui.draw_line(mon, mon.X - 11, 6, 11, colors.orange)
        end

        gui.draw_text_lr(mon, mon.X - 23, 12, 0, "Hyteresis", gui.format_int(outputInputHyteresis) .. " RF", colors.white, colors.blue, colors.black)

        if threshold >= 0 then
            gui.draw_text_lr(mon, mon.X - 23, 14, 0, "Threshold", gui.format_int(threshold) .. " RF", colors.white, colors.magenta, colors.black)

            gui.draw_line(mon, mon.X - 24, 16, 27, colors.gray)

            if satthreshold >= 0 then
                gui.draw_text_lr(mon, mon.X - 23, 18, 0, "SatThreshold", gui.format_int(satthreshold) .. " RF", colors.white, colors.magenta, colors.black)
            else
                gui.draw_text_lr(mon, mon.X - 23, 18, 0, "SatThreshold", "false", colors.white, colors.magenta, colors.black)
            end

            if fieldthreshold >= 0 then
                gui.draw_text_lr(mon, mon.X - 23, 20, 0, "FieldThreshold", gui.format_int(fieldthreshold) .. " RF", colors.white, colors.magenta, colors.black)
            else
                gui.draw_text_lr(mon, mon.X - 23, 20, 0, "FieldThreshold", "false", colors.white, colors.magenta, colors.black)
            end

            if fuelthreshold >= 0 then
                gui.draw_text_lr(mon, mon.X - 23, 22, 0, "FuelThreshold", gui.format_int(fuelthreshold) .. " RF", colors.white, colors.magenta, colors.black)
            else
                gui.draw_text_lr(mon, mon.X - 23, 22, 0, "FuelThreshold", "false", colors.white, colors.magenta, colors.black)
            end

            if tempthreshold >= 0 then
                gui.draw_text_lr(mon, mon.X - 23, 24, 0, "TempThreshold", gui.format_int(tempthreshold) .. " RF", colors.white, colors.magenta, colors.black)
            else
                gui.draw_text_lr(mon, mon.X - 23, 24, 0, "TempThreshold", "false", colors.white, colors.magenta, colors.black)
            end

            if energythreshold >= 0 then
                gui.draw_text_lr(mon, mon.X - 23, 26, 0, "EnergyThreshold", gui.format_int(energythreshold) .. " RF", colors.white, colors.magenta, colors.black)
            else
                gui.draw_text_lr(mon, mon.X - 23, 26, 0, "EnergyThreshold", "false", colors.white, colors.magenta, colors.black)
            end
        else
            gui.draw_text_lr(mon, mon.X - 23, 14, 0, "Threshold", "false", colors.white, colors.magenta, colors.black)

            gui.draw_line(mon, mon.X - 24, 16, 25, colors.gray)
        end


        -- reboot if config has to be reloaded
        if loadConfigReboot then
            shell.run("reboot")
        elseif loadConfigButton == 1 then
            loadConfigReboot = true
        end


        -- count down till external output can be changed again
        if sinceOutputChange > 0 then
            sinceOutputChange = sinceOutputChange - 1
        end

        -- count down till Edit Config button will be reset to default color
        if editConfigButton > 0 then
            editConfigButton = editConfigButton - 1
        end

        -- count down till Load Config button will be reset to default color
        if loadConfigButton > 0 then
            loadConfigButton = loadConfigButton - 1
        end
        sleep(0.25)
    end
end


function getOutput()
    if ri.status == "charging" then
        threshold = 0
    elseif satthreshold >= 0 and (satthreshold <= tempthreshold or tempthreshold == -1) and (satthreshold <= fieldthreshold or fieldthreshold == -1) and (satthreshold <= fuelthreshold or fuelthreshold == -1) and (satthreshold <= energythreshold or energythreshold == -1) then
        threshold = satthreshold
    elseif tempthreshold >= 0 and (tempthreshold <= satthreshold or satthreshold == -1) and (tempthreshold <= fieldthreshold or fieldthreshold == -1) and (tempthreshold <= fuelthreshold or fuelthreshold == -1) and (tempthreshold <= energythreshold or energythreshold == -1) then
        threshold = tempthreshold
    elseif fieldthreshold >= 0 and (fieldthreshold <= satthreshold or satthreshold == -1) and (fieldthreshold <= tempthreshold or tempthreshold == -1) and (fieldthreshold <= fuelthreshold or fuelthreshold == -1) and (fieldthreshold <= energythreshold or energythreshold == -1) then
        threshold = fieldthreshold
    elseif fuelthreshold >= 0 and (fuelthreshold <= satthreshold or satthreshold == -1) and (fuelthreshold <= tempthreshold or tempthreshold == -1) and (fuelthreshold <= fieldthreshold or fieldthreshold == -1) and (fuelthreshold <= energythreshold or energythreshold == -1) then
        threshold = fuelthreshold
    elseif energythreshold >= 0 and (energythreshold <= satthreshold or satthreshold == -1) and (energythreshold <= tempthreshold or tempthreshold == -1) and (energythreshold <= fieldthreshold or fieldthreshold == -1) and (energythreshold <= fuelthreshold or fuelthreshold == -1) then
        threshold = energythreshold
    else
        threshold = -1
    end

    updateOutput()

    local tempCap
    if threshold < targetGeneration and threshold ~= -1 then
        tempCap = threshold - outputfluxgate.getSignalLowFlow()
    else
        tempCap = targetGeneration - outputfluxgate.getSignalLowFlow()
    end

    local tempOutput = tempCap - (externalfluxgate.getSignalLowFlow() / 2)
    if tempOutput > maxIncrease then
        tempOutput = maxIncrease
    end
    tempOutput = externalfluxgate.getSignalLowFlow() + tempOutput

    if emergencyFlood == false and ri.status ~= "offline" then
        if (externalfluxgate.getSignalLowFlow() + outputfluxgate.getSignalLowFlow() <= targetGeneration) and (externalfluxgate.getSignalLowFlow() + outputfluxgate.getSignalLowFlow() <= threshold or threshold == -1) then
            outputfluxgate.setSignalLowFlow(inputfluxgate.getSignalLowFlow() + outputInputHyteresis)
            outputfluxgate.setSignalHighFlow(outputfluxgate.getSignalLowFlow())
        end
        if ri.generationRate < safeTarget - 2500 then
            if threshold < safeTarget and threshold ~= -1 then
                if threshold < targetGeneration then
                    externalfluxgate.setSignalLowFlow(threshold - outputfluxgate.getSignalLowFlow())
                    externalfluxgate.setSignalHighFlow(externalfluxgate.getSignalLowFlow())
                    sinceOutputChange = minChangeWait
                else
                    externalfluxgate.setSignalLowFlow(targetGeneration - outputfluxgate.getSignalLowFlow())
                    externalfluxgate.setSignalHighFlow(externalfluxgate.getSignalLowFlow())
                    sinceOutputChange = minChangeWait
                end
            else
                if targetGeneration < safeTarget then
                    externalfluxgate.setSignalLowFlow(targetGeneration - outputfluxgate.getSignalLowFlow())
                    externalfluxgate.setSignalHighFlow(externalfluxgate.getSignalLowFlow())
                    sinceOutputChange = minChangeWait
                else
                    externalfluxgate.setSignalLowFlow(safeTarget - outputfluxgate.getSignalLowFlow())
                    externalfluxgate.setSignalHighFlow(externalfluxgate.getSignalLowFlow())
                    sinceOutputChange = minChangeWait
                end
            end
        else
            if checkOutput() and sinceOutputChange == 0 and ri.temperature <= safeTemperature and satPercent > targetSat then
                externalfluxgate.setSignalLowFlow(tempOutput)
                externalfluxgate.setSignalHighFlow(tempOutput)
                sinceOutputChange = minChangeWait
            elseif ri.temperature > safeTemperature or satPercent < targetSat then
                externalfluxgate.setSignalLowFlow(externalfluxgate.getSignalLowFlow() - (maxIncrease / 2))
                externalfluxgate.setSignalHighFlow(externalfluxgate.getSignalLowFlow())
                sinceOutputChange = minChangeWait
            end
        end

        if externalfluxgate.getSignalLowFlow() + outputfluxgate.getSignalLowFlow() > targetGeneration then
            if outputfluxgate.getSignalLowFlow() > targetGeneration then
                outputfluxgate.setSignalLowFlow(targetGeneration)
                outputfluxgate.setSignalHighFlow(targetGeneration)
                externalfluxgate.setSignalLowFlow(0)
                externalfluxgate.setSignalHighFlow(0)
                sinceOutputChange = minChangeWait
            else
                outputfluxgate.setSignalLowFlow(inputfluxgate.getSignalLowFlow() + outputInputHyteresis)
                outputfluxgate.setSignalHighFlow(outputfluxgate.getSignalLowFlow())
                externalfluxgate.setSignalLowFlow(targetGeneration - outputfluxgate.getSignalLowFlow())
                externalfluxgate.setSignalHighFlow(externalfluxgate.getSignalLowFlow())
                sinceOutputChange = minChangeWait
            end
        end

        if externalfluxgate.getSignalLowFlow() + outputfluxgate.getSignalLowFlow() > threshold and threshold ~= -1 then
            if outputfluxgate.getSignalLowFlow() > threshold then
                outputfluxgate.setSignalLowFlow(threshold)
                outputfluxgate.setSignalHighFlow(threshold)
                externalfluxgate.setSignalLowFlow(0)
                externalfluxgate.setSignalHighFlow(0)
                sinceOutputChange = minChangeWait
            else
                outputfluxgate.setSignalLowFlow(inputfluxgate.getSignalLowFlow() + outputInputHyteresis)
                outputfluxgate.setSignalHighFlow(outputfluxgate.getSignalLowFlow())
                externalfluxgate.setSignalLowFlow(threshold - outputfluxgate.getSignalLowFlow())
                externalfluxgate.setSignalHighFlow(externalfluxgate.getSignalLowFlow())
                sinceOutputChange = minChangeWait
            end
        end
    end

    if ri.status == "offline" then
        outputfluxgate.setSignalLowFlow(0)
        outputfluxgate.setSignalHighFlow(0)
        externalfluxgate.setSignalLowFlow(0)
        externalfluxgate.setSignalHighFlow(0)
        sinceOutputChange = minChangeWait
    end

    if externalfluxgate.getSignalLowFlow() < 0 then
        externalfluxgate.setSignalLowFlow(0)
        externalfluxgate.setSignalHighFlow(0)
        sinceOutputChange = minChangeWait
    end
end

function updateOutput()
    local satPercent = math.ceil(ri.energySaturation / ri.maxEnergySaturation * 10000) * .01
    local i = 1
    while i < stableTurns do
        lastGen[i] = lastGen[i + 1]
        lastSat[i] = lastSat[i + 1]
        lastTemp[i] = lastTemp[i + 1]
        i = i + 1
    end
    lastGen[stableTurns] = ri.generationRate
    lastSat[stableTurns] = satPercent
    lastTemp[stableTurns] = ri.temperature
end

function checkOutput()
    local leastGen = lastGen[1]
    local leastSat = lastSat[1]
    local leastTemp = lastTemp[1]
    local i = 1
    while i <= stableTurns do
        if lastGen[i] < leastGen then
            leastGen = lastGen[i]
        end
        if lastSat[i] < leastSat then
            leastSat = lastSat[i]
        end
        if lastTemp[i] < leastTemp then
            leastTemp = lastTemp[i]
        end
        if leastGen + genTolerance < lastGen[i] then
            return false
        end
        if leastSat - satTolerance > lastSat[i] then
            return false
        end
        if leastTemp + tempTolerance < lastTemp[i] then
            return false
        end
        i = i + 1
    end
    if lastTemp[stableTurns] > safeTemperature - (500 / tempTolerance) or lastSat[stableTurns] < targetSat + (5 / satTolerance) then
        return false
    end
    if lastGen[stableTurns] + (2 * maxIncrease) < externalfluxgate.getSignalLowFlow() + outputfluxgate.getSignalLowFlow() then
        return false
    end
    return true
end


function isnan(x)
    return x ~= x
end

parallel.waitForAny(buttons, update)
