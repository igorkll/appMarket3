local su = require("superUtiles")
local fs = require("filesystem")

-----------------------------------------

local command = ...

if command == "open" then
    os.execute("/usr/bin/photo.lua")
elseif command == "uninstall" then
    fs.remove("/usr/bin/photo.lua")
    fs.remove(su.getPath())
elseif command == "install" then
    assert(su.saveFile("/usr/bin/photo.lua", assert(su.getInternetFile("https://raw.githubusercontent.com/igorkll/appMarket3/main/photo.lua"))))
end