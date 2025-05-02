local Illenium = {
    cachedShops = {},
    shopsId = 0
}

function Illenium:Create(source, title, type, hasBlip, coords, hasPermission)
    if not Functions.isAdmin(source, Config.Permissions.Create) then return end

    local heading = GetEntityHeading(GetPlayerPed(source))
    local formatCoords = string.format("[%.2f,%.2f,%.2f,%.2f]", coords.x, coords.y, coords.z, heading)

    local formatPermission = (hasPermission and hasPermission ~= "") and json.encode(hasPermission) or nil

    exports.oxmysql:query_async("INSERT INTO illenium_shops (label, type, coords, blip, groups) VALUES (?, ?, ?, ?, ?)", { title, type, formatCoords, hasBlip, formatPermission })

    Illenium.shopsId = Illenium.shopsId + 1
    local shopData = {
        shopsId = Illenium.shopsId,
        label = title,
        type = type,
        coords = json.decode(formatCoords),
        hasBlip = hasBlip,
        hasPermission = formatPermission and json.decode(formatPermission) or false,
        default = false
    }

    Illenium.cachedShops[#Illenium.cachedShops + 1] = shopData

    TriggerClientEvent('illenium-appearance:Add', -1, shopData)
    Wait(10)
    TriggerClientEvent('illenium-appearance:Blips', -1)
    Functions.notify(source, locale('NOTIFICATIONS.TITLE'), locale('NOTIFICATIONS.SUCCESS'), 'success', 15000)
end


function Illenium:Teleport(source, coords)
    if not Functions.isAdmin(source, Config.Permissions.Create) then return end

    SetEntityCoords(GetPlayerPed(source), coords[1], coords[2], coords[3])
end

function Illenium:Delete(source, id)
    if not Functions.isAdmin(source, Config.Permissions.Delete) then return end

    for i = 1, #Illenium.cachedShops do
        if Illenium.cachedShops[i].shopsId == id then
            exports.oxmysql:query_async("DELETE FROM illenium_shops WHERE id = ?", { id })
            table.remove(Illenium.cachedShops, i)
            break
        end
    end
    
    Functions.notify(source, locale('NOTIFICATIONS.TITLE'), locale('NOTIFICATIONS.DELETE', id), 'success', 15000)
    TriggerClientEvent('illenium-appearance:Rem', -1, id)
    Wait(10)
    TriggerClientEvent('illenium-appearance:Blips', -1)
end

function Illenium:Init()
    self.cachedShops = {}
    self.shopsId = 0
    
    exports.oxmysql:query_async([[
    CREATE TABLE IF NOT EXISTS `illenium_shops` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `label` VARCHAR(30) DEFAULT 'No Name',
        `type` VARCHAR(50) DEFAULT 'clothing',
        `coords` LONGTEXT DEFAULT '[0.0,0.0,0.0]',
        `blip` INT(5) DEFAULT 0,
        `locked` INT(5) DEFAULT 0,
        `groups` VARCHAR(50) DEFAULT NULL,
        PRIMARY KEY (`id`)
    )
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    ENGINE=InnoDB;
    ]])
    Wait(10)

    local shopList = exports.oxmysql:query_async("SELECT * FROM illenium_shops ORDER BY id DESC")

    if shopList and #shopList > 0 then
        local maxId = shopList[1].id
        
        for i = 1, #shopList do
            local row = shopList[i]
            local shopData = {
                shopsId = row.id,
                label = row.label,
                type = row.type,
                coords = json.decode(row.coords),
                hasBlip = row.blip == 1,
                hasPermission = row.groups and json.decode(row.groups) or false,
                default = row.locked == 1
            }
            
            self.cachedShops[#self.cachedShops + 1] = shopData
            TriggerClientEvent('illenium-appearance:Add', -1, shopData)
        end

        self.shopsId = maxId
        lib.print.info(locale('LOADED', #self.cachedShops))
    else
        lib.print.info(locale('NOT_ENOUGHT'))
    end
end

-- OPTIONS
local Options = {
    Create = function(source, title, type, hasBlip, coords, hasPermission)
        Illenium:Create(source, title, type, hasBlip, coords, hasPermission)
    end,
    Delete = function(source, id)
        Illenium:Delete(source, id)
    end,
    Teleport = function(source, coords)
        Illenium:Teleport(source, coords)
    end
}

-- EVENTS
lib.callback.register('lsk-illenium:server:Options', function(source, mode, ...)
    local mode = mode or 'default'
    if not Options[mode] then return end
    Options[mode](source, ...)
end)

lib.callback.register('lsk-illenium:server:loadPlayer', function(source)
    for i = 1, #Illenium.cachedShops do
        TriggerClientEvent('illenium-appearance:Add', source, Illenium.cachedShops[i])
    end
    Wait(10)
    TriggerClientEvent('illenium-appearance:Blips', source)
end)

-- INIT SYSTEM
CreateThread(function()
    Wait(100)
    Illenium:Init()
end)

-- COMMANDS
lib.addCommand(Config.Command, { help = locale('HELP') }, function(source, args)
    if not Functions.isAdmin(source, Config.Permissions.Create) then return end
    lib.callback.await('lsk-illenium:client:Options', source, 'Shops', Illenium.cachedShops)
end)