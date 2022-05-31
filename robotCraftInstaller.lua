local su = require("superUtiles")
local fs = require("filesystem")

-----------------------------------------

local command = ...

if command == "open" then
    os.execute("/usr/bin/robotCraft.lua")
elseif command == "uninstall" then
    fs.remove("/usr/bin/robotCraft.lua")
    fs.remove(su.getPath())
elseif command == "install" then
    assert(su.saveFile("/usr/bin/robotCraft.lua", su.getInternetFile("https://raw.githubusercontent.com/igorkll/appMarket3/main/robotCraft.lua")))
end