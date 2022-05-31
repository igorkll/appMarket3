local su = require("superUtiles")
local fs = require("filesystem")

-----------------------------------------

local command = ...

if command == "open" then
    os.execute("/usr/bin/lchat.lua")
elseif command == "uninstall" then
    fs.remove("/usr/bin/lchat.lua")
    fs.remove(su.getPath())
elseif command == "install" then
    assert(su.saveFile("/usr/bin/lchat.lua", su.getInternetFile("https://raw.githubusercontent.com/igorkll/appMarket3/main/lchat.lua")))
end