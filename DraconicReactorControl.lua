-- Draconic Reactor Control program by drmon(forked by Zeanon)

-- modifiable variables
-- Peripherals
local reactorPeripheral = "back"
local internalInput = "flux_gate_7"
local internalOutput = "flux_gate_9"
local externalOutput = "flux_gate_8"

-- target strength of the containment field
local targetStrength = 50
-- maximum temperature the reactor may reach
local maxTemperature = 7000
local tempBoost1Output = 400000
local tempBoost2Output = 750000
local tempBoost3Output = 1000000
-- temperature the programm should keep the reactor at
local safeTemperature = 5000
-- if the containment field gets below this value the reactor will be shut down (if it's 10% higher, the output will be capped to fieldBoostOutput)
local lowestFieldPercent = 15
local fieldBoost = 25
local fieldBoostOutput = 200000
-- the difference between the internal output and internal input (if you use a buffer core, so that the core will be filled)
local outputInputHyteresis = 2500
--
local satBoostThreshold = 25
local satBoost1 = 35
local satBoost1Output = 350000
local satBoost2 = 45
local satBoost2Output = 600000

local activateOnCharged = true

-- please leave things untouched from here on
os.loadAPI("lib/f")
os.loadAPI("lib/surface")

local version = "0.25"
-- toggleable via the monitor, use our algorithm to achieve our target field strength or let the user tweak it
local autoInputGate = true
local curInputGate = 222000
local curOutputGate = 0
local oldOutput = -1
local threshold = -1
local tempthreshold = -1
local satthreshold = -1
local fieldthreshold = -1
local fuelthreshold = -1
local thresholded = false
local emergencyFlood = false

-- monitor
local mon, monitor, monX, monY

-- peripherals
local reactor
local externalfluxgate
local inputfluxgate
local outputfluxgate

-- reactor information
local ri

-- last performed action
local action = "None since reboot"
local emergencyCharge = false
local emergencyTemp = false

--write settings to config file
function save_config()
    sw = fs.open("config.txt", "w")
    sw.writeLine("version:" .. version)
    sw.writeLine("autoInputGate:" .. (autoInputGate and "true" or "false"))
    sw.writeLine("curInputGate:" .. curInputGate)
    sw.writeLine("curOutputGate:" .. curOutputGate)
    sw.writeLine("targetStrength:" .. targetStrength)
    sw.writeLine("safeTemperature:" .. safeTemperature)
    sw.writeLine("oldOutput:" .. oldOutput)
    sw.writeLine("outputInputHyteresis:" .. outputInputHyteresis)
    sw.writeLine("reactorPeripheral:" .. reactorPeripheral)
    sw.writeLine("internalInput:" .. internalInput)
    sw.writeLine("internalOutput:" .. internalOutput)
    sw.writeLine("externalOutput:" .. externalOutput)
    sw.close()
end

--read settings from file
function load_config()
    sr = fs.open("config.txt", "r")
    local curVersion
    local line = sr.readLine()
    while line do
        local splitted = split(line, ":")
        if splitted[1] == "version" then
            curVersion = split(line, ":")[2]
        elseif split(line, ":")[1] == "autoInputGate" then
            autoInputGate = splitted[3]
        elseif split(line, ":")[1] == "curInputGate" then
            curInputGate = tonumber(split(line, ":")[2])
        elseif split(line, ":")[1] == "curOutputGate" then
            curOutputGate = tonumber(split(line, ":")[2])
        elseif split(line, ":")[1] == "targetStrength" then
            targetStrength = tonumber(split(line, ":")[2])
        elseif split(line, ":")[1] == "safeTemperature" then
            safeTemperature = tonumber(split(line, ":")[2])
        elseif split(line, ":")[1] == "oldOutput" then
            oldOutput = tonumber(split(line, ":")[2])
        elseif split(line, ":")[1] == "outputInputHyteresis" then
            outputInputHyteresis = tonumber(split(line, ":")[2])
        elseif split(line, ":")[1] == "reactorPeripheral" then
            reactorPeripheral = split(line, ":")[2]
        elseif split(line, ":")[1] == "internalInput" then
            internalInput = split(line, ":")[2]
        elseif split(line, ":")[1] == "internalOutput" then
            internalOutput = split(line, ":")[2]
        elseif split(line, ":")[1] == "externalOutput" then
            externalOutput = split(line, ":")[2]
        end
    end
    --autoInputGate = sr.readLine()
    --curInputGate = tonumber(sr.readLine())
    --targetStrength = tonumber(sr.readLine())
    -- safeTemperature = tonumber(sr.readLine())
    --oldOutput = tonumber(sr.readLine())
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

monitor = f.periphSearch("monitor")
inputfluxgate = peripheral.wrap(internalInput)
outputfluxgate = peripheral.wrap(internalOutput)
externalfluxgate = peripheral.wrap(externalOutput)
reactor = peripheral.wrap(reactorPeripheral)

if monitor == null then
    error("No valid monitor was found")
end

if externalfluxgate == null then
    error("No valid external output fluxgate was found")
end

if reactor == null then
    error("No valid reactor was found")
end

if inputfluxgate == null then
    error("No valid input flux gate was found")
end

if outputfluxgate == null then
    error("No valid internal output flux gate was found")
end

monX, monY = monitor.getSize()
mon = {}
mon.monitor,mon.X, mon.Y = monitor, monX, monY


function buttons()

    while true do
        -- button handler
        event, side, xPos, yPos = os.pullEvent("monitor_touch")

        -- reactor control
        local fuelPercent
        fuelPercent = 100 - math.ceil(ri.fuelConversion / ri.maxFuelConversion * 10000)*.01
        if yPos >= 1 and yPos <= 3 and fuelPercent > 15 then
            if ri.status == "charging" then
                reactor.stopReactor()
            elseif ri.status == "online" then
                reactor.stopReactor()
            elseif ri.status == "offline" then
                reactor.chargeReactor()
            elseif ri.status == "stopping" then
                reactor.chargeReactor()
            end
        end

        -- output gate controls
        -- 2-4 = -1000, 6-9 = -10000, 10-12,8 = -100000
        -- 17-19 = +1000, 21-23 = +10000, 25-27 = +100000
        local satPercent
        satPercent = math.ceil(ri.energySaturation / ri.maxEnergySaturation * 10000)*.01
        if yPos == 7 then
            local cFlow = externalfluxgate.getSignalLowFlow()
            if xPos >= 2 and xPos <= 4 then
                cFlow = cFlow-1000
            elseif xPos >= 6 and xPos <= 9 then
                cFlow = cFlow-10000
            elseif xPos >= 10 and xPos <= 12 then
                cFlow = cFlow-100000
            elseif xPos >= 17 and xPos <= 19 then
                cFlow = cFlow+100000
            elseif xPos >= 21 and xPos <= 23 then
                cFlow = cFlow+10000
            elseif xPos >= 25 and xPos <= 27 then
                cFlow = cFlow+1000
            end
            if isnan(cFlow) then
                cFlow = 0
            end
            if threshold >= 0 and cFlow > threshold then
                cFlow = threshold
            end
            oldOutput = cFlow
            save_config()
            externalfluxgate.setSignalLowFlow(cFlow)
        end

        -- input gate controls
        -- 2-4 = -1000, 6-9 = -10000, 10-12,8 = -100000
        -- 17-19 = +1000, 21-23 = +10000, 25-27 = +100000
        if yPos == 10 and autoInputGate == false and xPos ~= 14 and xPos ~= 15 then
            if xPos >= 2 and xPos <= 4 then
                curInputGate = curInputGate-1000
            elseif xPos >= 6 and xPos <= 9 then
                curInputGate = curInputGate-10000
            elseif xPos >= 10 and xPos <= 12 then
                curInputGate = curInputGate-100000
            elseif xPos >= 17 and xPos <= 19 then
                curInputGate = curInputGate+100000
            elseif xPos >= 21 and xPos <= 23 then
                curInputGate = curInputGate+10000
            elseif xPos >= 25 and xPos <= 27 then
                curInputGate = curInputGate+1000
            end
            inputfluxgate.setSignalLowFlow(curInputGate)
            outputfluxgate.setSignalLowFlow(curInputGate + outputInputHyteresis)
            save_config()
        end

        -- input gate toggle
        if yPos == 10 and ( xPos == 14 or xPos == 15) then
            if autoInputGate then
                autoInputGate = false
            else
                autoInputGate = true
            end
            save_config()
        end

        -- Numpad


    end
end

function drawButtons(y)

    -- 2-4 = -1000, 6-9 = -10000, 10-12,8 = -100000
    -- 17-19 = +1000, 21-23 = +10000, 25-27 = +100000

    f.draw_text(mon, 2, y, " < ", colors.white, colors.lightBlue)
    f.draw_text(mon, 6, y, " <<", colors.white, colors.lightBlue)
    f.draw_text(mon, 10, y, "<<<", colors.white, colors.lightBlue)

    f.draw_text(mon, 17, y, ">>>", colors.white, colors.purple)
    f.draw_text(mon, 21, y, ">> ", colors.white, colors.purple)
    f.draw_text(mon, 25, y, " > ", colors.white, colors.purple)
end



function update()
    while true do
        f.clear(mon)
        ri = reactor.getReactorInfo()

        -- monitor output
        local satPercent
        satPercent = math.ceil(ri.energySaturation / ri.maxEnergySaturation * 10000)*.01
        if isnan(satPercent) then
            satPercent = 0
        end

        local tempPercent, tempColor
        tempPercent = math.ceil(ri.temperature / maxTemperature * 10000)*.01
        if isnan(tempPercent) then
            tempPercent = 0
        end

        temperatureColor = colors.red
        if ri.temperature <= (maxTemperature / 8) * 5 then
            tempColor = colors.green end
        if ri.temperature > (maxTemperature / 8) * 5 and ri.temperature <= (maxTemperature / 80) * 65 then
            tempColor = colors.orange
        end

        local fieldPercent, fieldColor
        fieldPercent = math.ceil(ri.fieldStrength / ri.maxFieldStrength * 10000)*.01
        if  isnan(fieldPercent) then
            fieldPercent = 0
        end

        fieldColor = colors.red
        if fieldPercent >= 50 then
            fieldColor = colors.green end
        if fieldPercent < 50 and fieldPercent > 30 then
            fieldColor = colors.orange
        end

        local fuelPercent, fuelColor
        fuelPercent = 100 - math.ceil(ri.fuelConversion / ri.maxFuelConversion * 10000)*.01
        if fuelPercent == math.huge or isnan(fuelPercent) then
            fuelPercent = 0
        end

        fuelColor = colors.red
        if fuelPercent >= 70 then
            fuelColor = colors.green end
        if fuelPercent < 70 and fuelPercent > 30 then
            fuelColor = colors.orange end

        local statusColor

        statusColor = colors.red
        if ri.status == "online" or ri.status == "charged" then
            statusColor = colors.green
            for k,v in pairs(redstone.getSides()) do
                redstone.setOutput(v, false)
            end
        elseif ri.status == "offline" then
            statusColor = colors.gray
            for k,v in pairs(redstone.getSides()) do
                redstone.setOutput(v, true)
            end
        elseif ri.status == "charging" then
            statusColor = colors.orange
            for k,v in pairs(redstone.getSides()) do
                redstone.setOutput(v, false)
            end
        end

        if fuelPercent > 15 then
            f.draw_text_lr(mon, 2, 2, 20, "Reactor Status", string.upper(ri.status), colors.white, statusColor, colors.black)
        end
        if fuelPercent <= 15 then
            f.draw_text_lr(mon, 2, 2, 20, "Reactor Status", "REFUEL NEEDED", colors.white, colors.red, colors.black)
        end

        f.draw_text_lr(mon, 2, 4, 20, "Generation", f.format_int(ri.generationRate) .. " rf/t", colors.white, colors.lime, colors.black)

        f.draw_text_lr(mon, 2, 6, 20, "Output Gate", f.format_int(externalfluxgate.getSignalLowFlow()) .. " rf/t", colors.white, colors.blue, colors.black)

        -- buttons
        drawButtons(7)

        f.draw_text_lr(mon, 2, 9, 20, "Input Gate: H: ".. outputInputHyteresis, f.format_int(inputfluxgate.getSignalLowFlow()) .. " rf/t", colors.white, colors.blue, colors.black)

        if autoInputGate then
            f.draw_text(mon, 14, 10, "AU", colors.white, colors.gray)
        else
            f.draw_text(mon, 14, 10, "MA", colors.white, colors.green)
            drawButtons(10)
        end

        f.draw_line(mon, 0, 12, mon.X-19, colors.yellow)
        f.draw_column(mon, mon.X-20, mon.Y, colors.yellow)

        f.draw_text_lr(mon, 2, 14, 20, "Energy Saturation", satPercent .. "%", colors.white, colors.white, colors.black)
        f.progress_bar(mon, 2, 15, mon.X-22, satPercent, 100, colors.blue, colors.gray)

        f.draw_text_lr(mon, 2, 17, 20, "Temperature: T: ".. safeTemperature, f.format_int(ri.temperature) .. "C", colors.white, tempColor, colors.black)
        f.progress_bar(mon, 2, 18, mon.X-22, tempPercent, 100, tempColor, colors.gray)

        if autoInputGate then
            f.draw_text_lr(mon, 2, 20, 20, "Field Strength T:" .. targetStrength, fieldPercent .. "%", colors.white, fieldColor, colors.black)
        else
            f.draw_text_lr(mon, 2, 20, 20, "Field Strength", fieldPercent .. "%", colors.white, fieldColor, colors.black)
        end
        f.progress_bar(mon, 2, 21, mon.X-22, fieldPercent, 100, fieldColor, colors.gray)

        f.draw_text_lr(mon, 2, 23, 20, "Fuel ", fuelPercent .. "%", colors.white, fuelColor, colors.black)
        f.progress_bar(mon, 2, 24, mon.X-22, fuelPercent, 100, fuelColor, colors.gray)

        f.draw_text_lr(mon, 2, 26, 20, "Last action due to:", action, colors.gray, colors.gray, colors.black)


        -- safeguards

        -- out of fuel, kill it
        if fuelPercent <= 15 then
            action = "Fuel below 15%"
            reactor.stopReactor()
            fuelthreshold = 0
            getThreshold()
        else
            fuelthreshold = -1
            getThreshold()
        end

        -- Saturation too low, regulate Output
        if satPercent < satBoostThreshold and (ri.status == "online" or ri.status == "charging" or ri.status == "stopping") then
            satthreshold = 0
            getThreshold()
        elseif satPercent < satBoost1 and (ri.status == "online" or ri.status == "charging" or ri.status == "stopping") then
            satthreshold = satBoost1Output
            getThreshold()
        elseif satPercent < satBoost2 and (ri.status == "online" or ri.status == "charging" or ri.status == "stopping") then
            satthreshold = satBoost2Output
            getThreshold()
        else
            satthreshold = -1
            getThreshold()
        end

        -- field strength is close to dangerous, fire up input
        if fieldPercent <= fieldBoost and (ri.status == "online" or ri.status == "charging" or ri.status == "stopping") then
            emergencyFlood = true
            inputfluxgate.setSignalLowFlow(900000)
            outputfluxgate.setSignalLowFlow(900000 + outputInputHyteresis)
            fieldthreshold = fieldBoostOutput
            getThreshold()
        else
            emergencyFlood = false
            fieldthreshold = -1
            getThreshold()
        end

        -- field strength is too dangerous, kill it and try to charge it before it blows
        if fieldPercent <= lowestFieldPercent and (ri.status == "online" or ri.status == "charging" or ri.status == "stopping") then
            action = "Field Str < " ..lowestFieldPercent.."%"
            reactor.stopReactor()
            reactor.chargeReactor()
            emergencyCharge = true
            fieldthreshold = 0
            getThreshold()
        else
            fieldthreshold = -1
            getThreshold()
        end


        -- temperature too high, kill it and activate it when its cool
        if ri.temperature > maxTemperature then
            action = "Temp > " .. maxTemperature
            reactor.stopReactor()
            emergencyTemp = true
            tempthreshold = 0
            getThreshold()
        elseif ri.temperature > maxTemperature - ((maxTemperature - safeTemperature)/4) then
            tempthreshold = tempBoost1Output
            getThreshold()
        elseif ri.temperature > maxTemperature - ((maxTemperature - safeTemperature)/2) then
            tempthreshold = tempBoost2Output
            getThreshold()
        elseif ri.temperature > safeTemperature + ((maxTemperature - safeTemperature)/4) then
            tempthreshold = tempBoost3Output
            getThreshold()
        else
            tempthreshold = -1
            getThreshold()
        end


        -- print out all the infos from .getReactorInfo() to term
        if ri == nil then
            error("reactor has an invalid setup")
        end

        for k, v in pairs (ri) do
            print(k.. ": ".. v)
        end

        -- actual reactor interaction

        if emergencyCharge == true then
            reactor.chargeReactor()
        end

        print("Output Gate: ", externalfluxgate.getSignalLowFlow())
        print("Input Gate: ", inputfluxgate.getSignalLowFlow())

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
            getThreshold()
            inputfluxgate.setSignalLowFlow(900000)
            outputfluxgate.setSignalLowFlow(900000 + outputInputHyteresis)
            emergencyCharge = false
        end

        -- are we on? regulate the input fludgate to our target field strength
        -- or set it to our saved setting since we are on manual
        if emergencyFlood == false and (ri.status == "online" or ri.status == "offline" or ri.status == "stopping") then
            if autoInputGate then
                fluxval = ri.fieldDrainRate / (1 - (targetStrength/100) )
                inputfluxgate.setSignalLowFlow(fluxval)
                outputfluxgate.setSignalLowFlow(fluxval + outputInputHyteresis)
            else
                inputfluxgate.setSignalLowFlow(curInputGate)
                outputfluxgate.setSignalLowFlow(curInputGate + outputInputHyteresis)
            end
        end

        print("Target Gate: ".. inputfluxgate.getSignalLowFlow())

        if threshold >= 0 then
            print("Threshold: ".. threshold)
        else
            print("Threshold: false")
        end
        print("Hyteresis: ".. outputInputHyteresis)

        sleep(0.2)
    end
end

function isnan(x)
    return x ~= x
end

function getThreshold()
    if ri.status == "charging" then
        threshold = 0
    elseif satthreshold >= 0 and (satthreshold <= tempthreshold or tempthreshold == -1) and (satthreshold <= fieldthreshold or fieldthreshold == -1) and (satthreshold <= fuelthreshold or fuelthreshold == -1) then
        threshold = satthreshold
    elseif tempthreshold >= 0 and (tempthreshold <= satthreshold or satthreshold == -1) and (tempthreshold <= fieldthreshold or fieldthreshold == -1) and (tempthreshold <= fuelthreshold or fuelthreshold == -1) then
        threshold = tempthreshold
    elseif fieldthreshold >= 0 and (fieldthreshold <= satthreshold or satthreshold == -1) and (fieldthreshold <= tempthreshold or tempthreshold == -1) and (fieldthreshold <= fuelthreshold or fuelthreshold == -1) then
        threshold = fieldthreshold
    elseif fuelthreshold >= 0 and (fuelthreshold <= satthreshold or satthreshold == -1) and (fuelthreshold <= tempthreshold or tempthreshold == -1) and (fuelthreshold <= fieldthreshold or fieldthreshold == -1) then
        threshold = fuelthreshold
    else
        threshold = -1
    end
    if threshold >= 0 and externalfluxgate.getSignalLowFlow() > threshold and thresholded == false then
        oldOutput = externalfluxgate.getSignalLowFlow()
        externalfluxgate.setSignalLowFlow(threshold)
        thresholded = true
    elseif threshold >= 0 and thresholded then
        if threshold < oldOutput then
            externalfluxgate.setSignalLowFlow(threshold)
        elseif threshold >= oldOutput then
            externalfluxgate.setSignalLowFlow(oldOutput)
            oldOutput = -1
            thresholded = false
        end
    elseif threshold == -1 and oldOutput > -1 then
        externalfluxgate.setSignalLowFlow(oldOutput)
        oldOutput = -1
        thresholded = false
    end
    save_config()
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

parallel.waitForAny(buttons, update)