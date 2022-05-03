-- Installer for GenerationOverview by Zeanon
-- get it with pastebin get aUyxiBs0 install
-- pastebin link: https://pastebin.com/aUyxiBs0
local libURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/lib/gui.lua"
local lib2URL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/lib/color.lua"
local startupURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/legacy/DraconicReactorGenerationOverview/startup.lua"
local runURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/legacy/DraconicReactorGenerationOverview/run.lua"
local generationOverviewURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/DraconicReactorGenerationOverview/legacy/DaconicReactorGenerationOverview.lua"
local lib, lib2, startup, run, generationOverview
local libFile, lib2File, startupFile, runFile, generationOverviewFile

fs.makeDir("lib")

lib = http.get(libURL)
libFile = lib.readAll()

local file1 = fs.open("lib/gui", "w")
file1.write(libFile)
file1.close()


lib2 = http.get(lib2URL)
lib2File = lib2.readAll()

local file2 = fs.open("lib/color", "w")
file2.write(lib2File)
file2.close()


startup = http.get(startupURL)
startupFile = startup.readAll()

local file3 = fs.open("startup", "w")
file3.write(startupFile)
file3.close()


run = http.get(runURL)
runFile = run.readAll()

local file4 = fs.open("run", "w")
file4.write(runFile)
file4.close()


generationOverview = http.get(generationOverviewURL)
generationOverviewFile = generationOverview.readAll()

local file5 = fs.open("DraconicReactorGenerationOverview", "w")
file5.write(generationOverviewFile)
file5.close()

if fs.exists("update") then
	shell.run("delete update")
end
shell.run("pastebin get RD8sVpNn update")

if os.getComputerLabel() == null then
	os.setComputerLabel("Reactor-Generation-Overview")
end

shell.run("reboot")
