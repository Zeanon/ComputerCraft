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
libFile = lib.readAll()

local file1 = fs.open("lib/gui", "w")
file1.write(libFile)
file1.close()


startup = http.get(startupURL)
startupFile = startup.readAll()

local file2 = fs.open("startup", "w")
file2.write(startupFile)
file2.close()


run = http.get(runURL)
runFile = run.readAll()

local file3 = fs.open("run", "w")
file3.write(runFile)
file3.close()


reactorControl = http.get(reactorControlURL)
reactorControlFile = reactorControl.readAll()

local file4 = fs.open("DraconicReactor", "w")
file4.write(reactorControlFile)
file4.close()

if fs.exists("update") then
	shell.run("delete update")
end
shell.run("pastebin get UEi3KkwM update")

if os.getComputerLabel() == null then
	os.setComputerLabel("Draconic-Reactor-Control")
end

shell.run("reboot")
