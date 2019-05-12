-- Installer for EnergyCoreOverview by Zeanon
-- get it with pastebin get uAG74E88 install
-- pastebin link: https://pastebin.com/uAG74E88

local libURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/lib/gui.lua"
local startupURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/EnergyCoreOverview/startup.lua"
local runURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/EnergyCoreOverview/run.lua"
local EnergyOverviewURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/EnergyCoreOverview/EnergyCoreOverview.lua"
local lib, startup, run, EnergyOverview
local libFile, startupFile, runFile, EnergyOverviewFile

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


EnergyOverview = http.get(EnergyOverviewURL)
EnergyOverviewFile = EnergyOverview.readAll()

local file4 = fs.open("EnergyCoreOverview", "w")
file4.write(EnergyOverviewFile)
file4.close()

if fs.exists("update") then
    shell.run("delete update")
end
shell.run("pastebin get RQb0M8cZ update")

if os.getComputerLabel() == null then
    os.setComputerLabel("Draconic-Reactor")
end

shell.run("reboot")