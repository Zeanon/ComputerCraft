-- Installer for DraconicReactorControl by acidjazz and Zeanon
-- get it with "pastebin get qpA31HT6 install"
-- pastebin link: https://pastebin.com/qpA31HT6
 
local guiLibURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/lib/gui.lua"
local startupURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/legacy/DraconicReactorControl/startup.lua"
local runURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/legacy/DraconicReactorControl/run.lua"
local reactorControlURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/legacy/DraconicReactorControl/DraconicReactorControl.lua"
local guiLib, startup, run, exe
local guiLibFile, startupFile, runFile, exeFile
 
 
fs.makeDir("lib")
 
guiLib = http.get(guiLibURL)
 
guiLibFile = fs.open("lib/gui", "w")
guiLibFile.write(guiLib.readAll())
guiLibFile.close()
guiLib.close()
 
 
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
 
 
exe = http.get(reactorControlURL)
 
exeFile = fs.open("DraconicReactor", "w")
exeFile.write(exe.readAll())
exeFile.close()
exe.close()
 
 
if fs.exists("update") then
    shell.run("delete update")
end
shell.run("pastebin get DEPNPsSz update")
 
if os.getComputerLabel() == null then
    os.setComputerLabel("Draconic-Reactor-Control")
end
 
if fs.exists("install") then
    shell.run("delete install")
end
 
shell.run("reboot")
