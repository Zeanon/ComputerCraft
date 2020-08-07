-- Installer for GenerationOverview by Zeanon
-- get it with pastebin get VT6ezUgB install
-- pastebin link: https://pastebin.com/VT6ezUgB
local libURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/lib/gui.lua"
local lib2URL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/lib/color.lua"
local startupURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/DraconicReactorGenerationOverview/startup.lua"
local runURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/DraconicReactorGenerationOverview/run.lua"
local generationOverviewURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/DraconicReactorGenerationOverview/DraconicReactorGenerationOverview.lua"
local lib, lib2, startup, run, generationOverview
local libFile, lib2File, startupFile, runFile, generationOverviewFile


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
startup.readAll()


run = http.get(runURL)

runFile = fs.open("run", "w")
runFile.write(runFile)
runFile.close()
run.close()


generationOverview = http.get(generationOverviewURL)

generationOverviewFile = fs.open("DraconicReactorGenerationOverview", "w")
generationOverviewFile.write(generationOverview.readAll())
generationOverviewFile.close()
generationOverview.close()


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
