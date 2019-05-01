-- Draconic Reactor Control program by drmon(forked by Zeanon)

-- modifiable variables
-- Peripherals
local internalInput = "flux_gate_0"
local internalOutput = "flux_gate_1"
local externalOutput = "flux_gate_2"

-- target strength of the containment field
local targetStrength = 35
-- maximum temperature the reactor may reach
local maxTemperature = 7000
local tempBoost1Output = 400000
local tempBoost2Output = 750000
local tempBoost3Output = 1000000
-- temperature the programm should keep the reactor at
local safeTemperature = 5000
-- if the containment field gets below this value the reactor will be shut down
local lowestFieldPercent = 15
local fieldBoost = 25
local fieldBoostOutput = 200000
-- different boost levels for energySaturation
local satBoostThreshold = 25
local satBoost1 = 35
local satBoost1Output = 350000
local satBoost2 = 45
local satBoost2Output = 600000
-- tolerances for auto boosting
local genTolerance = 250
local satTolerance = 2
local tempTolerance = 10
local maxIncrease = 10000
local safeTarget = 20000
-- the amount of loops the program goes through until the output can be changed again
local minChangeWait = 5
-- the amount of turns the program will save to check whether the reactor is stable
local stableTurns = 20
-- maximum output level
local maxOutput = 1200000

local activateOnCharged = true

-- please leave things untouched from here on
os.loadAPI("lib/gui")
os.loadAPI("lib/surface")

local version = "1.1.5"
-- toggleable via the monitor, use our algorithm to achieve our target field strength or let the user tweak it
local autoInputGate = true
local curInputGate = 222000
local curOutput = 0
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

-- monitor
local mon, monitor, monX, monY

-- peripherals
local reactor
local core 
local externalfluxgate
local inputfluxgate
local outputfluxgate

-- reactor information
local ri

-- last performed action
local action = "None since reboot"
local emergencyCharge = false
local emergencyTemp = false

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
    sw.writeLine("-- Config for Draconig Reactor Control Program")
    sw.writeLine("version: " .. version)
    sw.writeLine(" ")
    sw.writeLine("-- reactorPeripheral modem names")
    sw.writeLine("internalInput: " .. internalInput)
    sw.writeLine("internalOutput: " .. internalOutput)
    sw.writeLine("externalOutput: " .. externalOutput)
    sw.writeLine(" ")
    sw.writeLine("-- the numbers for the temperatureBoost steps")
    sw.writeLine("safeTemperature: " .. safeTemperature)
	sw.writeLine("maxTemperature: " .. maxTemperature)
	sw.writeLine("tempBoost1Output: " .. tempBoost1Output)
	sw.writeLine("tempBoost2Output: " .. tempBoost2Output)
	sw.writeLine("tempBoost3Output: " .. tempBoost3Output)
    sw.writeLine(" ")
    sw.writeLine("-- numbers for the fieldBoost steps")
    sw.writeLine("targetStrength: " .. targetStrength)
	sw.writeLine("lowestFieldPercent: " .. lowestFieldPercent)
	sw.writeLine("fieldBoost: " .. fieldBoost)
	sw.writeLine("fieldBoostOutput: " .. fieldBoostOutput)
    sw.writeLine(" ")
    sw.writeLine("-- numbers for the saturationBoost steps")
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
    sw.writeLine("-- maxIncrease is the maximum amount the externalOutput can be increased by in one step")
    sw.writeLine("maxIncrease: " ..  maxIncrease)
    sw.writeLine("-- under this generation limit the algorythm won't do anyrhing and the output will just be set to this amoun")
    sw.writeLine("safeTarget: " .. safeTarget)
    sw.writeLine("-- the minimum turns to wait for the next output increase after one was done")
    sw.writeLine("minChangeWait: " .. minChangeWait)
    sw.writeLine("-- the amount of turns to be checked if stable")
    sw.writeLine("stableTurns: " .. stableTurns)
    sw.writeLine("-- the maximum allowed output")
    sw.writeLine("maxOutput: " .. maxOutput)
    sw.writeLine(" ")
    sw.writeLine("-- just some saved data")
    if autoInputGate then
        sw.writeLine("autoInputGate: true")
    else
        sw.writeLine("autoInputGate: false")
    end
    if activateOnCharged then
        sw.writeLine("activateOnCharged: true")
    else
        sw.writeLine("activateOnCharged: false")
    end
    sw.writeLine("curInputGate: " .. curInputGate)
    sw.writeLine("targetOutput: " .. curOutput)
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
        elseif split(line, ": ")[1] == "autoInputGate" then
            autoInputGate = split(line, ": ")[2]
        elseif split(line, ": ")[1] == "activateOnCharged" then
            activateOnCharged = split(line, ": ")[2]
        elseif split(line, ": ")[1] == "curInputGate" then
            curInputGate = tonumber(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "targetOutput" then
            curOutput = tonumber(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "targetStrength" then
            targetStrength = tonumber(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "safeTemperature" then
            safeTemperature = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "maxTemperature" then
			maxTemperature = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "tempBoost1Output" then
			tempBoost1Output = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "tempBoost2Output" then
			tempBoost2Output = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "tempBoost3Output" then
			tempBoost3Output = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "lowestFieldPercent" then
			lowestFieldPercent = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "fieldBoost" then
			fieldBoost = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "fieldBoostOutput" then
			fieldBoostOutput = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "satBoostThreshold" then
			satBoostThreshold = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "satBoost1" then
			satBoost1 = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "satBoost1Output" then
			satBoost1Output = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "satBoost2" then
			satBoost2 = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "satBoost2Output" then
			satBoost2Output = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "genTolerance" then
			genTolerance = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "satTolerance" then
			satTolerance = tonumber(split(line, ": ")[2])
		elseif split(line, ": ")[1] == "tempTolerance" then
			tempTolerance = tonumber(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "maxIncrease" then
            maxIncrease = tonumber(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "safeTarget" then
            safeTarget = tonumber(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "minChangeWait" then
            minChangeWait = tonumber(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "stableTurns" then
            stableTurns = tonumber(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "maxOutput" then
            maxOutput = tonumber(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "internalInput" then
            internalInput = split(line, ": ")[2]
        elseif split(line, ": ")[1] == "internalOutput" then
            internalOutput = split(line, ": ")[2]
        elseif split(line, ": ")[1] == "externalOutput" then
            externalOutput = split(line, ": ")[2]
        end
        line = sr.readLine()
    end
    sr.close()
    if curVersion ~= version then
        save_config()
    end
end

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
if fs.exists("config.txt") == false then
    save_config()
    initTables()
else
	load_config()
    initTables()
end

monitor = peripheral.find("monitor")
inputfluxgate = peripheral.wrap(internalInput)
outputfluxgate = peripheral.wrap(internalOutput)
externalfluxgate = peripheral.wrap(externalOutput)
reactor = peripheral.find("draconic_reactor")
core = peripheral.find("draconic_rf_storage")

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

if core == null then
    error("No valid energy core was found")
end


function buttons()

    while true do
        -- button handler
        local event, side, xPos, yPos = os.pullEvent("monitor_touch")

        -- reactor control
        local fuelPercent
        fuelPercent = 100 - math.ceil(ri.fuelConversion / ri.maxFuelConversion * 10000)*.01
        if yPos >= 1 and yPos <= 3 and xPos >= mon.X-27 then
            if ri.status == "online" or ri.status == "charging" or ri.status == "charged" then
                reactor.stopReactor()
            elseif ri.status == "offline" and fuelPercent > 10 then
                reactor.chargeReactor()
            elseif ri.status == "stopping" and fuelPercent > 10 then
                reactor.chargeReactor()
            end
        end

        -- edit Config
        if yPos >= 6 and yPos <= 8 then
            if xPos >= mon.X-25 and xPos <= mon.X-14 then
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
                gui.draw_line(mon, mon.X-25, 6, 12, colors.lightBlue)
                gui.draw_text(mon, mon.X-25, 7, " Edit Config", colors.white, colors.lightBlue)
                gui.draw_line(mon, mon.X-25, 8, 12, colors.lightBlue)
            elseif xPos >= mon.X-12 and xPos <= mon.X-2 then
                gui.draw_line(mon, mon.X-12, 6, 12, colors.orange)
                gui.draw_text(mon, mon.X-12, 7, " Load Config", colors.white, colors.orange)
                gui.draw_line(mon, mon.X-12, 8, 12, colors.orange)

                shell.run("reboot")
            end
        end

        -- output gate controls
        -- 2-4 = -1000, 6-9 = -10000, 10-12,8 = -100000
        -- 17-19 = +1000, 21-23 = +10000, 25-27 = +100000
        local satPercent
        satPercent = math.ceil(ri.energySaturation / ri.maxEnergySaturation * 10000)*.01
        if yPos >= 5 and yPos <= 6 then
            if xPos >= 2 and xPos <= 4 then
                curOutput = curOutput-1000
            elseif xPos >= 6 and xPos <= 8 then
                curOutput = curOutput-10000
            elseif xPos >= 10 and xPos <= 12 then
                curOutput = curOutput-100000
            elseif xPos >= 17 and xPos <= 19 then
                curOutput = curOutput+100000
            elseif xPos >= 21 and xPos <= 23 then
                curOutput = curOutput+10000
            elseif xPos >= 25 and xPos <= 27 then
                curOutput = curOutput+1000
            end

            if curOutput == math.huge or isnan(curOutput) or curOutput < 0 then
                curOutput = 0
            end

            if curOutput > maxOutput then
                curOutput = maxOutput
            end
            save_config()
        end

        -- input gate controls
        -- 2-4 = -1000, 6-9 = -10000, 10-12,8 = -100000
        -- 17-19 = +1000, 21-23 = +10000, 25-27 = +100000
        if yPos == 8 and autoInputGate == false and xPos ~= 14 and xPos ~= 15 then
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

            if curInputGate == math.huge or isnan(curInputGate) or curInputGate < 0 then
                curInputGate = 0
            end

            if curInputGate > maxOutput then
                curInputGate = maxOutput
            end
            inputfluxgate.setSignalLowFlow(curInputGate)
            save_config()
        end

        -- input gate toggle
        if yPos == 8 and ( xPos == 14 or xPos == 15) then
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

    gui.draw_text(mon, 2, y, " < ", colors.white, colors.lightBlue)
    gui.draw_text(mon, 6, y, " <<", colors.white, colors.lightBlue)
    gui.draw_text(mon, 10, y, "<<<", colors.white, colors.lightBlue)

    gui.draw_text(mon, 17, y, ">>>", colors.white, colors.purple)
    gui.draw_text(mon, 21, y, ">> ", colors.white, colors.purple)
    gui.draw_text(mon, 25, y, " > ", colors.white, colors.purple)
end



function update()
    while true do
        monX, monY = monitor.getSize()
        mon = {}
        mon.monitor,mon.X, mon.Y = monitor, monX, monY

        gui.clear(mon)
        ri = reactor.getReactorInfo()
        local fluxval

        local satPercent, satColor
        satPercent = math.ceil(ri.energySaturation / ri.maxEnergySaturation * 10000)*.01
        if isnan(satPercent) then
            satPercent = 0
        end
        satColor = colors.red
        if satPercent >= 70 then
            satColor = colors.green
        elseif satPercent < 70 and satPercent > 30 then
            satColor = colors.orange
        end

        local tempPercent, tempColor
        tempPercent = math.ceil(ri.temperature / maxTemperature * 10000)*.01
        if isnan(tempPercent) then
            tempPercent = 0
        end
        local tempColor = colors.red
        if ri.temperature <= (maxTemperature / 8) * 5 then
            tempColor = colors.green
        elseif ri.temperature > (maxTemperature / 8) * 5 and ri.temperature <= (maxTemperature / 80) * 65 then
            tempColor = colors.orange
        end

        local fieldPercent, fieldColor
        fieldPercent = math.ceil(ri.fieldStrength / ri.maxFieldStrength * 10000)*.01
        if  isnan(fieldPercent) then
            fieldPercent = 0
        end
        fieldColor = colors.red
        if fieldPercent >= 50 then
            fieldColor = colors.green
        elseif fieldPercent < 50 and fieldPercent > 30 then
            fieldColor = colors.orange
        end

        local fuelPercent, fuelColor
        fuelPercent = 100 - math.ceil(ri.fuelConversion / ri.maxFuelConversion * 10000)*.01
        if fuelPercent == math.huge or isnan(fuelPercent) then
            fuelPercent = 0
        end
        fuelColor = colors.red
        if fuelPercent >= 70 then
            fuelColor = colors.green
        elseif fuelPercent < 70 and fuelPercent > 30 then
            fuelColor = colors.orange
        end

        local energyPercent, energyColor
        energyPercent = math.ceil(core.getEnergyStored() / core.getMaxEnergyStored() * 10000)*.01
        if energyPercent == math.huge or isnan(energyPercent) then
            energyPercent = 0
        end
        energyColor = colors.red
        if energyPercent >= 70 then
            energyColor = colors.green
        elseif energyPercent < 70 and energyPercent > 30 then
            energyColor = colors.orange
        end

        local statusColor
        statusColor = colors.red
        if ri.status == "online" or ri.status == "charged" then
            statusColor = colors.green
            for k,v in pairs(redstone.getSides()) do
                redstone.setOutput(v, true)
            end
        elseif ri.status == "offline" then
            statusColor =  colors.lightGray
            for k,v in pairs(redstone.getSides()) do
                redstone.setOutput(v, false)
            end
            inputfluxgate.setSignalLowFlow(0)
        elseif ri.status == "charging" then
            statusColor = colors.orange
            for k,v in pairs(redstone.getSides()) do
                redstone.setOutput(v, true)
            end
        end


        -- SAFEGUARDS -- DONT EDIT

        -- out of fuel, kill it
        if fuelPercent <= 10 then
            action = "Fuel below 10%"
            reactor.stopReactor()
            fuelthreshold = 0
        else
            fuelthreshold = -1
        end

        -- Saturation too low, regulate Output
        if satPercent < satBoostThreshold and (ri.status == "online" or ri.status == "charging" or ri.status == "stopping") then
            satthreshold = 0
        elseif satPercent < satBoost1 and (ri.status == "online" or ri.status == "charging" or ri.status == "stopping") then
            satthreshold = satBoost1Output
        elseif satPercent < satBoost2 and (ri.status == "online" or ri.status == "charging" or ri.status == "stopping") then
            satthreshold = satBoost2Output
        else
            satthreshold = -1
        end

        -- field strength is close to dangerous, fire up input
        if fieldPercent <= fieldBoost and (ri.status == "online" or ri.status == "charging" or ri.status == "stopping") then
            action = "Field Str dangerous"
            emergencyFlood = true
            inputfluxgate.setSignalLowFlow(900000)
            outputfluxgate.setSignalLowFlow(900000 + outputInputHyteresis)
            fieldthreshold = fieldBoostOutput
        else
            emergencyFlood = false
            fieldthreshold = -1
        end

        -- field strength is too dangerous, kill it and try to charge it before it blows
        if fieldPercent <= lowestFieldPercent and (ri.status == "online" or ri.status == "charging" or ri.status == "stopping") then
            action = "Field Str < " ..lowestFieldPercent.."%"
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
        elseif ri.temperature > maxTemperature - ((maxTemperature - safeTemperature)/4) then
            tempthreshold = tempBoost1Output
        elseif ri.temperature > maxTemperature - ((maxTemperature - safeTemperature)/2) then
            tempthreshold = tempBoost2Output
        elseif ri.temperature > safeTemperature + ((maxTemperature - safeTemperature)/4) then
            tempthreshold = tempBoost3Output
        else
            tempthreshold = -1
        end

        -- check, if reactor has valid setup
        if ri == nil then
            error("reactor has an invalid setup")
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
            outputfluxgate.setSignalLowFlow(900000 + outputInputHyteresis)
            emergencyCharge = false
        end

		-- get the hysteresis for the internal output gate
        if energyPercent == 100 then
            outputInputHyteresis = 0
		elseif energyPercent >= 95 and energyPercent < 100  then
			outputInputHyteresis = 1000
        elseif energyPercent >= 90 and energyPercent < 95 then
            outputInputHyteresis = 2500
		elseif energyPercent >= 80 and energyPercent < 90 then
			outputInputHyteresis = 5000
		elseif energyPercent >= 70 and energyPercent < 80 then
			outputInputHyteresis = 7500
		elseif energyPercent >= 60 and energyPercent < 70 then
			outputInputHyteresis = 10000
		elseif energyPercent >= 50 and energyPercent < 60 then
			outputInputHyteresis = 12500
		elseif energyPercent >= 40 and energyPercent < 50 then
			outputInputHyteresis = 25000
		elseif core.getEnergyStored() < 1000000 then
			action = "not enough buffer energy left"
			reactor.stopReactor()
			satthreshold = 0
        end

        -- are we on? regulate the input fludgate to our target field strength
        -- or set it to our saved setting since we are on manual
        if emergencyFlood == false and (ri.status == "online" or ri.status == "offline" or ri.status == "stopping") then
            if autoInputGate then
                fluxval = ri.fieldDrainRate / (1 - (targetStrength/100))
                inputfluxgate.setSignalLowFlow(fluxval)
            else
                inputfluxgate.setSignalLowFlow(curInputGate)
            end
        end

        -- get the different output values
        getOutput()


        -- monitor output
        gui.draw_text_lr(mon, 2, 2, 28, "Generation", gui.format_int(ri.generationRate) .. " RF/t", colors.white, colors.lime, colors.black)

        gui.draw_text_lr(mon, 2, 4, 28, "Target Output", gui.format_int(curOutput) .. " RF/t", colors.white, colors.blue, colors.black)
        drawButtons(5)

        gui.draw_text_lr(mon, 2, 7, 28, "Input Gate", gui.format_int(inputfluxgate.getSignalLowFlow()) .. " RF/t", colors.white, colors.blue, colors.black)

        if autoInputGate then
            gui.draw_text(mon, 14, 8, "AU", colors.white,  colors.lightGray)
        else
            gui.draw_text(mon, 14, 8, "MA", colors.white, colors.green)
            drawButtons(8)
        end

        gui.draw_line(mon, 0, 10, mon.X+1, colors.gray)
        gui.draw_column(mon, mon.X-27, 0, mon.Y+1, colors.gray)

        gui.draw_text_lr(mon, 2, 12, 28, "Energy Saturation", satPercent .. "%", colors.white, satColor, colors.black)
        gui.progress_bar(mon, 2, 13, mon.X-30, satPercent, 100, colors.blue,  colors.lightGray)

        gui.draw_text_lr(mon, 2, 15, 28, "Temperature", gui.format_int(ri.temperature) .. "C", colors.white, tempColor, colors.black)
        gui.progress_bar(mon, 2, 16, mon.X-30, tempPercent, 100, tempColor,  colors.lightGray)

        if autoInputGate then
            gui.draw_text_lr(mon, 2, 18, 28, "Field Strength T:" .. targetStrength, fieldPercent .. "%", colors.white, fieldColor, colors.black)
        else
            gui.draw_text_lr(mon, 2, 18, 28, "Field Strength", fieldPercent .. "%", colors.white, fieldColor, colors.black)
        end
        gui.progress_bar(mon, 2, 19, mon.X-30, fieldPercent, 100, fieldColor,  colors.lightGray)

        gui.draw_text_lr(mon, 2, 21, 28, "Core Energy Level", energyPercent .. "%", colors.white, energyColor, colors.black)
        gui.progress_bar(mon, 2, 22, mon.X-30, energyPercent, 100, energyColor,  colors.lightGray)

        gui.draw_text_lr(mon, 2, 24, 28, "Fuel ", fuelPercent .. "%", colors.white, fuelColor, colors.black)
        gui.progress_bar(mon, 2, 25, mon.X-30, fuelPercent, 100, fuelColor,  colors.lightGray)

        gui.draw_text_lr(mon, 2, 26, 28, "Last:", action,  colors.lightGray,  colors.lightGray, colors.black)



        if fuelPercent > 10 then
            gui.draw_text_lr(mon, mon.X-25, 2, 0, "Status", string.upper(ri.status), colors.white, statusColor, colors.black)
        else
            gui.draw_text_lr(mon, mon.X-25, 2, 0, "Status", "REFUEL NEEDED", colors.white, colors.red, colors.black)
        end

        gui.draw_text_lr(mon, mon.X-25, 4, 0, "Output", gui.format_int(externalfluxgate.getSignalLowFlow()) .. " RF/t", colors.white, colors.blue, colors.black)

        gui.draw_line(mon, mon.X-25, 6, 12, colors.cyan)
        gui.draw_line(mon, mon.X-12, 6, 12, colors.red)
        gui.draw_text(mon, mon.X-25, 7, " Edit Config", colors.white, colors.cyan)
        gui.draw_text(mon, mon.X-12, 7, " Load Config", colors.white, colors.red)
        gui.draw_line(mon, mon.X-25, 8, 12, colors.cyan)
        gui.draw_line(mon, mon.X-12, 8, 12, colors.red)

        gui.draw_text_lr(mon, mon.X-25, 12, 0, "Hyteresis", gui.format_int(outputInputHyteresis) .. " RF", colors.white, colors.blue, colors.black)

        if threshold >= 0 then
            gui.draw_text_lr(mon, mon.X-25, 14, 0, "Threshold", gui.format_int(threshold) .. " RF", colors.white, colors.blue, colors.black)

            gui.draw_line(mon, mon.X-26, 16, 27, colors.gray)

            if satthreshold >= 0 then
                gui.draw_text_lr(mon, mon.X-25, 18, 0, "SatThreshold", gui.format_int(satthreshold) .. " RF", colors.white, colors.blue, colors.black)
            else
                gui.draw_text_lr(mon, mon.X-25, 18, 0, "SatThreshold", "false", colors.white, colors.blue, colors.black)
            end

            if fieldthreshold >= 0 then
                gui.draw_text_lr(mon, mon.X-25, 20, 0, "FieldThreshold", gui.format_int(fieldthreshold) .. " RF", colors.white, colors.blue, colors.black)
            else
                gui.draw_text_lr(mon, mon.X-25, 20, 0, "FieldThreshold", "false", colors.white, colors.blue, colors.black)
            end

            if fuelthreshold >= 0 then
                gui.draw_text_lr(mon, mon.X-25, 22, 0, "FuelThreshold", gui.format_int(fuelthreshold) .. " RF", colors.white, colors.blue, colors.black)
            else
                gui.draw_text_lr(mon, mon.X-25, 22, 0, "FuelThreshold", "false", colors.white, colors.blue, colors.black)
            end

            if tempthreshold >= 0 then
                gui.draw_text_lr(mon, mon.X-25, 24, 0, "TempThreshold", gui.format_int(tempthreshold) .. " RF", colors.white, colors.blue, colors.black)
            else
                gui.draw_text_lr(mon, mon.X-25, 24, 0, "TempThreshold", "false", colors.white, colors.blue, colors.black)
            end

            if energythreshold >= 0 then
                gui.draw_text_lr(mon, mon.X-25, 26, 0, "EnergyThreshold", gui.format_int(energythreshold) .. " RF", colors.white, colors.blue, colors.black)
            else
                gui.draw_text_lr(mon, mon.X-25, 26, 0, "EnergyThreshold", "false", colors.white, colors.blue, colors.black)
            end
        else
            gui.draw_text_lr(mon, mon.X-25, 14, 0, "Threshold", "false", colors.white, colors.blue, colors.black)

            gui.draw_line(mon, mon.X-26, 16, 27, colors.gray)
        end


        -- print information on the computer
        for k, v in pairs (ri) do
            print(k.. ": ".. v)
        end
        print("Output Gate: ", externalfluxgate.getSignalLowFlow())
        print("Input Gate: ", inputfluxgate.getSignalLowFlow())
        print("Target Gate: ".. fluxval)
        if threshold >= 0 then
            print("Threshold: ".. threshold)
        else
            print("Threshold: false")
        end
        print("Hyteresis: ".. outputInputHyteresis)
        print("Till next change: " .. sinceOutputChange)

        -- count down till external output can be changed again
        if sinceOutputChange > 0 then
            sinceOutputChange = sinceOutputChange - 1
        end

        sleep(0.5)
    end
end

function getOutput()
    if ri.status == "charging" then
        threshold = 0
    elseif satthreshold >= 0 and (satthreshold <= tempthreshold or tempthreshold == -1) and (satthreshold <= fieldthreshold or fieldthreshold == -1) and (satthreshold <= fuelthreshold or fuelthreshold == -1) and (satthreshold<= energythreshold or energythreshold == -1) then
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
    if threshold < curOutput and threshold ~= -1 then
        tempCap = threshold - outputfluxgate.getSignalLowFlow()
    else
        tempCap = curOutput - outputfluxgate.getSignalLowFlow()
    end
    local tempOutput = tempCap - (externalfluxgate.getSignalLowFlow() / 2)
    if tempOutput > maxIncrease then
        tempOutput = maxIncrease
    end
    tempOutput = externalfluxgate.getSignalLowFlow() + tempOutput
    if emergencyFlood == false then
        if (externalfluxgate.getSignalLowFlow() + outputfluxgate.getSignalLowFlow() < curOutput) and (externalfluxgate.getSignalLowFlow() + outputfluxgate.getSignalLowFlow() < threshold or threshold == -1) then
            outputfluxgate.setSignalLowFlow(inputfluxgate.getSignalLowFlow() + outputInputHyteresis)
        end
        if ri.generationRate < safeTarget - 2500 then
           if threshold < safeTarget and threshold ~= -1 then
               if threshold < curOutput then
                   externalfluxgate.setSignalLowFlow(threshold - outputfluxgate.getSignalLowFlow())
               else
                   externalfluxgate.setSignalLowFlow(curOutput - outputfluxgate.getSignalLowFlow())
               end
           else
               if curOutput < safeTarget then
                   externalfluxgate.setSignalLowFlow(curOutput - outputfluxgate.getSignalLowFlow())
               else
                   externalfluxgate.setSignalLowFlow(safeTarget - outputfluxgate.getSignalLowFlow())
               end
           end
        else
            if checkOutput()and sinceOutputChange == 0 then
                externalfluxgate.setSignalLowFlow(tempOutput)
                if threshold > curOutput or threshold == -1 then
                    sinceOutputChange = minChangeWait
                end
            end
        end
        if externalfluxgate.getSignalLowFlow() + outputfluxgate.getSignalLowFlow() > curOutput then
            if outputfluxgate.getSignalLowFlow() > curOutput then
                outputfluxgate.setSignalLowFlow(curOutput)
                externalfluxgate.setSignalLowFlow(0)
            else
                outputfluxgate.setSignalLowFlow(inputfluxgate.getSignalLowFlow() + outputInputHyteresis)
                externalfluxgate.setSignalLowFlow(curOutput - outputfluxgate.getSignalLowFlow())
            end
        end
        if externalfluxgate.getSignalLowFlow() + outputfluxgate.getSignalLowFlow() > threshold and threshold ~= -1 then
            if outputfluxgate.getSignalLowFlow() > threshold then
                outputfluxgate.setSignalLowFlow(threshold)
                externalfluxgate.setSignalLowFlow(0)
            else
                outputfluxgate.setSignalLowFlow(inputfluxgate.getSignalLowFlow() + outputInputHyteresis)
                externalfluxgate.setSignalLowFlow(threshold - outputfluxgate.getSignalLowFlow())
            end
        end
    end
    if externalfluxgate.getSignalLowFlow() < 0 then
        externalfluxgate.setSignalLowFlow(0)
    end
end

function updateOutput()
    local satPercent = math.ceil(ri.energySaturation / ri.maxEnergySaturation * 10000)*.01
    local tempPercent = math.ceil(ri.temperature / maxTemperature * 10000)*.01
    local i = 1
	while i <= stableTurns do
		if i < stableTurns then
			lastGen[i] = lastGen[i + 1]
			lastSat[i] = lastSat[i + 1]
			lastTemp[i] = lastTemp[i + 1]
            i = i + 1
		else
			lastGen[i] = ri.generationRate
			lastSat[i] = satPercent
			lastTemp[i] = ri.temperature
            i = i + 1
		end
    end
end

function checkOutput()
    local checked = true
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
			checked = false
		end
		if leastSat - satTolerance > lastSat[i] then
			checked = false
		end
		if leastTemp + tempTolerance < lastTemp[i] then
			checked = false
        end
        i = i + 1
    end
	return checked
end

function isnan(x)
    return x ~= x
end

parallel.waitForAny(buttons, update)