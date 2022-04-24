-- Installer for GenerationOverview by Zeanon
-- get it with pastebin get VT6ezUgB install
-- pastebin link: https://pastebin.com/VT6ezUgB
local guiLibURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/lib/gui.lua"
local colorLibURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/lib/color.lua"
local startupURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/DraconicReactorGenerationOverview/startup.lua"
local runURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/DraconicReactorGenerationOverview/run.lua"
local generationOverviewURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/DraconicReactorGenerationOverview/DraconicReactorGenerationOverview.lua"
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
runFile.write(runFile)
runFile.close()
run.close()


exe = http.get(generationOverviewURL)

exeFile = fs.open("DraconicReactorGenerationOverview", "w")
exeFile.write(exe.readAll())
exeFile.close()
exe.close()


if fs.exists("update") then
	shell.run("delete update")
end
shell.run("pastebin get HZ7ffzMn update")

if os.getComputerLabel() == null then
	os.setComputerLabel("Reactor-Generation-Overview")
end

if fs.exists("install") then
	shell.run("delete install")
end

shell.run("reboot")
