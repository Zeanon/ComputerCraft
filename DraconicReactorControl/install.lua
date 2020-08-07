-- Installer for DraconicReactorControl by drmon and Zeanon
-- get it with pastebin get UKxFmqXx install
-- pastebin link: https://pastebin.com/UKxFmqXx

local libURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/lib/gui.lua"
local startupURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/DraconicReactorControl/startup.lua"
local runURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/DraconicReactorControl/run.lua"
local reactorControlURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/DraconicReactorControl/DraconicReactorControl.lua"
local lib, startup, run, reactorControl
local libFile, startupFile, runFile, reactorControlFile

fs.makeDir("lib")

lib = http.get(libURL)

libFile = fs.open("lib/gui", "w")
libFile.write(lib.readAll())
libFile.close()
lib.close()


startup = http.get(startupURL)

startupFile = fs.open("startup", "w")
startupFile.write(startup.readAll())
startupFile.close()
startup.close()


run = http.get(runURL)

runFile = fs.open("run", "w")
runFile.write(run.readAll())
runFile.close()
run.close()


reactorControl = http.get(reactorControlURL)

reactorControlFile = fs.open("DraconicReactor", "w")
reactorControlFile.write(reactorControl.readAll())
reactorControlFile.close()
reactorControl.close()


if fs.exists("update") then
    shell.run("delete update")
end
shell.run("pastebin get UEi3KkwM update")

if os.getComputerLabel() == null then
    os.setComputerLabel("Draconic-Reactor-Control")
end

if fs.exists("install") then
    shell.run("delete install")
end

shell.run("reboot")
