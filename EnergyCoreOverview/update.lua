-- Updater for EnergyCoreOverview by Zeanon
-- get it with pastebin get RQb0M8cZ update
-- pastebin link: https://pastebin.com/RQb0M8cZ

if fs.exists("install") then
    shell.run("delete install")
end
shell.run("pastebin get uAG74E88 install")
shell.run("install")