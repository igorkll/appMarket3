local su = require("superUtiles")
local fs = require("filesystem")

-----------------------------------------

local command = ...

if command == "open" then
elseif command == "uninstall" then
    fs.remove("/usr/lib/md5.lua")
    fs.remove(su.getPath())
elseif command == "install" then
    assert(su.saveFile("/usr/lib/md5.lua", assert(su.getInternetFile("https://raw.githubusercontent.com/igorkll/appMarket3/main/md5.lua"))))
end