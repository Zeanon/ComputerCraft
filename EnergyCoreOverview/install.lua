-- Installer for EnergyCoreOverview by Zeanon
-- get it with pastebin get uAG74E88 install
-- pastebin link: https://pastebin.com/uAG74E88

local libURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/lib/gui.lua"
local lib2URL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/lib/color.lua"
local startupURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/EnergyCoreOverview/startup.lua"
local runURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/EnergyCoreOverview/run.lua"
local energyOverviewURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/EnergyCoreOverview/EnergyCoreOverview.lua"
local lib, lib2, startup, run, energyOverview
local libFile, lib2File, startupFile, runFile, energyOverviewFile


fs.makeDir("lib")

lib = http.get(libURL)

libFile = fs.open("lib/gui", "w")
libFile.write(lib.readAll())
libFile.close()
lib.close()


lib2 = http.get(lib2URL)

lib2File = fs.open("lib/color", "w")
lib2File.write(lib2.readAll())
lib2File.close()
lib2.close()


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


energyOverview = http.get(energyOverviewURL)

energyOverviewFile = fs.open("EnergyCoreOverview", "w")
energyOverviewFile.write(energyOverview.readAll())
energyOverviewFile.close()


if fs.exists("update") then
	shell.run("delete update")
end
shell.run("pastebin get RQb0M8cZ update")

if os.getComputerLabel() == null then
	os.setComputerLabel("Energy-Core-Overview")
end

if fs.exists("install") then
	shell.run("delete install")
end

shell.run("reboot")
