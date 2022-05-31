local su = require("superUtiles")
local fs = require("filesystem")

-----------------------------------------

local command = ...

if command == "open" then
    os.execute("/usr/bin/md5.lua")
elseif command == "uninstall" then
    fs.remove("/usr/bin/md5.lua")
    fs.remove(su.getPath())
elseif command == "install" then
    assert(su.saveFile("/usr/bin/md5.lua", su.getInternetFile("https://raw.githubusercontent.com/igorkll/appMarket3/main/md5.lua")))
end