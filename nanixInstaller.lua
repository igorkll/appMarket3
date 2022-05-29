local su = require("superUtiles")
local fs = require("filesystem")

-----------------------------------------

local command = ...

if command == "open" then
    os.execute("/usr/bin/nanix.lua")
elseif command == "uninstall" then
    fs.remove("/usr/bin/nanix.lua")
elseif command == "install" then
    assert(su.saveFile("/usr/bin/nanix.lua", su.getInternetFile("https://raw.githubusercontent.com/igorkll/appMarket3/main/nanix.lua")))
end