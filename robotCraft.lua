---------------------------------------------mod installer

if not _G._MODVERSION then --для программы требуеться мод для openOS
    print("требуеться устоновка мода для openOS")
    io.write("запустить инсталлер? [Y/n]")
    local read = io.read()
    if read == "Y" or read == "y" then
        os.execute("wget https://raw.githubusercontent.com/igorkll/openOSpath/main/bin/installer.lua /tmp/ins.lua -f")
        os.execute("wget https://raw.githubusercontent.com/igorkll/openOSpath/main/installer.lua /tmp/ins.lua -f")
        os.execute("/tmp/ins.lua")
    end
end

---------------------------------------------libs

local robot = require("robot")
local component = require("component")
local computer = require("computer")
local fs = require("filesystem")
local su = require("superUtiles")
local serialization = require("serialization")
local shell = require("shell")
local simpleGui = require("simpleGui")
local term = require("term")
local process = require("process")

---------------------------------------------variables

local args, options = shell.parse(...)

local function sPrint(...)
    if not options.m then
        _G.print(...)
    end
end

---------------------------------------------components

local craft = component.crafting.craft
local inv = component.inventory_controller
local beep = computer.beep

---------------------------------------------db

local cfgPath = "/etc/craftBot.cfg"
local cfg = {
    crafts = {
        ["minecraft:diamond_pickaxe"] = {
            {{"minecraft:diamond"}, {"minecraft:diamond"}, {"minecraft:diamond"}},
            {nil, {"minecraft:stick"}, nil},
            {nil, {"minecraft:stick"}, nil},
        },
        ["minecraft:stick"] = {
            {nil, {"minecraft:planks"}, nil},
            {nil, {"minecraft:planks"}, nil},
            {nil, nil, nil},
        },
        ["minecraft:planks"] = {
            {{"minecraft:log"}, nil, nil},
            {nil, nil, nil},
            {nil, nil, nil},
        },
    }
}

local function saveCfg()
    su.saveFile(cfgPath, assert(serialization.serialize(cfg)))
end

local function loadCfg()
    cfg = assert(serialization.unserialize(assert(su.getFile(cfgPath))))
end

if fs.exists(cfgPath) then
    loadCfg()
else
    saveCfg()
end

local zoneSlots = {1, 2, 3, 5, 6, 7, 9, 10, 11}

---------------------------------------------functions

--в моем моде для openOS таблица _ENV раздельная для разных программ так что глобалы не будут доступны из стороньнего софта

function warnSound()
    sPrint("WARNING")
    if not options.b then
        beep(50, 0.15)
        os.sleep(0.2)
        beep(50, 1)
        os.sleep(3)
    end
end

function getCraft(name)
    return cfg.crafts[name[math.random(1, #name)]]
end

function isCorrectSlot(slot)
    return not su.inTable(zoneSlots, slot)
end

function findFreeSlot(slot)
    robot.select(slot)
    sPrint("finding free slot")
    for i = robot.inventorySize(), 1, -1 do
        if isCorrectSlot(i) and (robot.count(i) == 0 or (robot.compareTo(i) and robot.space(slot) > 0)) then
            return i
        end
    end
    sPrint("not enough space in inventory")
    warnSound()
    return false
end

function findItem(name, doNotCraft, allSlots, useLabel)
    if type(name) == "string" then name = {name} end
    local crafted = false

    sPrint("finding item " .. serialization.serialize(name))
    for i = robot.inventorySize(), 1, -1 do
        local itemInfo = inv.getStackInInternalSlot(i)
        --gui.status(tostring(isCorrectSlot(i)), 1)
        if (allSlots or isCorrectSlot(i)) and itemInfo and su.inTable(name, useLabel and itemInfo.label or itemInfo.name) then
            return i, crafted
        end
    end

    if doNotCraft then return nil, "item not found" end

    crafted = true
    sPrint("item " .. serialization.serialize(name) .. " not found, crafting attempt")
    local slot, err = craftItem(name, true)
    if slot then return slot, crafted end
    return false, crafted
end

function clearCraftZone()
    sPrint("clearing craft zone")
    for cy = 1, 3 do
        for cx = 1, 3 do
            local slot = cx + ((cy - 1) * 4)
            if robot.count(slot) > 0 then
                robot.select(slot)
                local toNum = findFreeSlot(slot)
                if not toNum then return false end
                robot.transferTo(toNum)
            end
        end
    end
end

function errorSplash(err)
    sPrint(err or "unkown error")
    warnSound()
end

function craftItem(name, freeSlot)
    if type(name) == "string" then name = {name} end

    local function errorSplash(err, name)
        sPrint("error to craft item " .. serialization.serialize(name) .. ", " .. err)
        warnSound()
        return err --для упрошения кода
    end

    local craftRecipe = getCraft(name)
    if not craftRecipe then return nil, errorSplash("no this craft", name) end

    ::tonew::
    clearCraftZone()
    for cy = 1, 3 do
        for cx = 1, 3 do
            local item = craftRecipe[cy][cx]
            if item then
                local slot, crafted = findItem(item, nil, nil, craftRecipe.useLabel)
                if not slot then return false, errorSplash("item not found", name) end
                if crafted then goto tonew end
                robot.select(slot)
                robot.transferTo(cx + ((cy - 1) * 4), 1)
            end
        end
    end

    local slot = 1
    if freeSlot then
        slot = findFreeSlot()
        if not slot then return nil, errorSplash("no free slot found", name) end
    end
    robot.select(slot)
    if not craft(slot) then return nil, errorSplash("craft error", name) end
    return slot
end

---------------------------------------------main

local function exit()
    if term.isAvailable() then
        local gpu = term.gpu()
        gpu.setForeground(0xFFFFFF)
        gpu.setBackground(0)
        term.clear()
    end
    os.exit()
end
process.info().data.signal = exit

if args[1] then
    craftItem(args[1])
else
    local num
    while true do
        local strs = {}
        for k, v in pairs(cfg.crafts) do
            table.insert(strs, k)
        end
        table.insert(strs, "add")
        table.insert(strs, "find")
        table.insert(strs, "give")
        table.insert(strs, "remove")
        table.insert(strs, "exit")

        num = simpleGui.menu("select craft repice", strs, num)
        term.clear()

        local str = strs[num]
        if str == "add" then
            local recipe = {}
            for cy = 1, 3 do
                recipe[cy] = {}
                for cx = 1, 3 do
                    local pos = cx + ((cy - 1) * 4)
                    local info = inv.getStackInInternalSlot(pos)
                    if info and info.label then
                        recipe[cy][cx] = info.label
                    end
                end
            end
            recipe.useLabel = true
            local info = inv.getStackInInternalSlot(4)
            if not info or not info.label then
                print("no item found in slot 4")
                os.sleep(2)
            else
                cfg.crafts[info.label] = recipe
                num = 1
                saveCfg()
            end
        elseif str == "remove" then
            local strs2 = {}
            for k, v in pairs(cfg.crafts) do
                table.insert(strs2, k)
            end
            table.insert(strs2, "back")
            local num2 = simpleGui.menu("select craft repice to remove", strs2)
            local str = strs2[num2]
            if str ~= "back" then
                cfg.crafts[str] = nil
                num = 1
                saveCfg()
            end
        elseif str == "find" then
            local num2
            while true do
                local strs2 = {}
                for k, v in pairs(cfg.crafts) do
                    table.insert(strs2, k)
                end
                table.insert(strs2, "back")
                num2 = simpleGui.menu("select item to find", strs2, num2)
                local str = strs2[num2]
                if str == "back" then
                    break
                end
                term.clear()
                local slot, err = findItem(str, true, true)
                if not slot then
                    errorSplash(err)
                else
                    robot.select(slot)
                    robot.transferTo(1)
                end
            end
        elseif str == "give" then
            local num2
            while true do
                local strs2 = {}
                for k, v in pairs(cfg.crafts) do
                    table.insert(strs2, k)
                end
                table.insert(strs2, "back")
                num2 = simpleGui.menu("select item to give", strs2, num2)
                local str = strs2[num2]
                if str == "back" then
                    break
                end
                term.clear()
                local slot, err = findItem(str, nil, true)
                if not slot then
                    errorSplash(err)
                else
                    robot.select(slot)
                    robot.transferTo(1)
                end
            end
        elseif str == "exit" then
            exit()
        else
            local num = simpleGui.menu("select mode", {"single", "loop", "back"})
            term.clear()
            if num == 1 then
                craftItem(str)
            elseif num == 2 then
                while craftItem(str) do
                    os.sleep(0.5)
                end
            end
        end
    end
end