-- Installer for EnergyCoreOverview by Zeanon
-- get it with "pastebin get uAG74E88 install"
-- pastebin link: https://pastebin.com/uAG74E88

local guiLibURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/lib/gui.lua"
local colorLibURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/lib/color.lua"
local startupURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/EnergyCoreOverview/startup.lua"
local runURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/EnergyCoreOverview/run.lua"
local energyOverviewURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/EnergyCoreOverview/EnergyCoreOverview.lua"
local guiLib, colorLib, startup, run, exe
local guiLibFile, colorLibFile, startupFile, runFile, exeFile


fs.makeDir("lib")

guiLib = http.get(guiLibURL)

guiLibFile = fs.open("lib/gui", "w")
guiLibFile.write(guiLib.readAll())
guiLibFile.close()
guiLib.close()


colorLib = http.get(colorLibURL)

colorLibFile = fs.open("lib/color", "w")
colorLibFile.write(colorLib.readAll())
colorLibFile.close()
colorLib.close()


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


exe = http.get(energyOverviewURL)

exeFile = fs.open("EnergyCoreOverview", "w")
exeFile.write(exe.readAll())
exeFile.close()


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
