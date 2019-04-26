print("Running Draconic Reactor Control Program")
while true do
  if multishell.getTitle(1) ~= "Draconic Reactor" and multishell.getTitle(2) ~= "Draconic Reactor" and multishell.getTitle(3) ~= "Draconic Reactor" then
    newTabID = shell.openTab("DraconicReactor")
    multishell.setTitle(newTabID, "Draconic Reactor")
  end 
  os.sleep(1);
end
