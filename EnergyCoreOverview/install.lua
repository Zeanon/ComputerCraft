-- Installer for EnergyCoreOverview by Zeanon
-- get it with pastebin get uAG74E88 install
-- pastebin link: https://pastebin.com/uAG74E88

local libURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/lib/gui.lua"
local lib2URL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/lib/color.lua"
local startupURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/EnergyCoreOverview/startup.lua"
local runURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/EnergyCoreOverview/run.lua"
local EnergyOverviewURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/EnergyCoreOverview/EnergyCoreOverview.lua"
local lib, lib2, startup, run, EnergyOverview
local libFile, lib2File, startupFile, runFile, EnergyOverviewFile

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


EnergyOverview = http.get(EnergyOverviewURL)
EnergyOverviewFile = EnergyOverview.readAll()

local file5 = fs.open("EnergyCoreOverview", "w")
file5.write(EnergyOverviewFile)
file5.close()

if fs.exists("update") then
	shell.run("delete update")
end
shell.run("pastebin get RQb0M8cZ update")

if os.getComputerLabel() == null then
	os.setComputerLabel("Energy-Core")
end

shell.run("reboot")
