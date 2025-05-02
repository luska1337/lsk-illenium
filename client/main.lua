local Illenium = {}

local Core = exports.qbx_core

local typeOptions = {
    { value = "clothing", label = locale('LABELS.Skinshop'), icon = locale('LABELS.SkinshopIcon') },
    { value = "barber", label = locale('LABELS.Barber'), icon = locale('LABELS.BarberIcon') },
    { value = "tattoo", label = locale('LABELS.Tattoo'), icon = locale('LABELS.TattooIcon') },
    { value = "surgeon", label = locale('LABELS.Surgeon'), icon = locale('LABELS.SurgeonIcon') }
}

function Illenium:GetLabel(value)
    for i = 1, #typeOptions do
        if typeOptions[i].value == value then
            return typeOptions[i].label
        end
    end
end

function Illenium:GetIcon(value)
    for i = 1, #typeOptions do
        if typeOptions[i].value == value then
            return typeOptions[i].icon
        end
    end
end

function Illenium:GetGroups()
    local options = {}

    local jobs = Core:GetJobs()
    local gangs = Core:GetGangs()

    for name, data in pairs(jobs or {}) do
        options[#options + 1] = {
            value = name,
            label = string.format("%s (job)", data.label or name)
        }
    end

    for name, data in pairs(gangs or {}) do
        options[#options + 1] = {
            value = name,
            label = string.format("%s (gang)", data.label or name)
        }
    end

    return options
end

function Illenium:Shops(List)
    local options = {}

    options[#options + 1] = {
        title = locale('MENUS.CONTEXT.CREATE'),
        description = locale('MENUS.CONTEXT.CREATE_DESCRIPTION'),
        onSelect = function()
            Illenium:CreateShop()
        end
    }

    local function sortOptions(a, b)
        return a.shopsId < b.shopsId
    end

    table.sort(List, sortOptions)

    for _, shop in ipairs(List) do
        if shop.default ~= true then
            local shopOptions = {
                {
                    title = locale('MENUS.CONTEXT.TELEPORT'),
                    description = locale('MENUS.CONTEXT.TELEPORT_DESCRIPTION'),
                    onSelect = function()
                        lib.callback.await('lsk-illenium:server:Options', true, 'Teleport', shop.coords)
                    end
                },
                {
                    title = locale('MENUS.CONTEXT.DELETE'),
                    description = locale('MENUS.CONTEXT.DELETE_DESCRIPTION'),
                    onSelect = function()
                        lib.callback.await('lsk-illenium:server:Options', true, 'Delete', shop.shopsId)
                    end
                },
                {
                    title = locale('MENUS.CONTEXT.BACK'),
                    onSelect = function()
                        lib.showContext('manageShops')
                    end
                }
            }

            lib.registerContext({
                id = 'shop_' .. shop.shopsId,
                title = ('[%s] %s (ID: %s)'):format(Illenium:GetIcon(shop.type), shop.label, shop.shopsId),
                options = shopOptions
            })

            options[#options + 1] = {
                title = ('#%s %s'):format(shop.shopsId, Illenium:GetLabel(shop.type)),
                description = ('[%s] %s'):format(Illenium:GetIcon(shop.type), shop.label),
                onSelect = function()
                    lib.showContext('shop_' .. shop.shopsId)
                end
            }
        end
    end

    lib.registerContext({
        id = 'manageShops',
        title = locale('MENUS.CONTEXT.TITLE'),
        options = options
    })

    lib.showContext('manageShops')
end

function Illenium:CreateShop()
    local flags = -1
    local ignore = cache.ped
    local _distance = 20
    local coords = nil

    while true do 
        local hit, entityHit, endCoords = lib.raycast.cam(flags, ignore, _distance)
        DrawMarker(0, endCoords.x, endCoords.y, endCoords.z + 0.99, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 0, 0, 200, false, false, 2, false, nil, nil, false)

        if IsControlJustPressed(0, 38) then 
            coords = endCoords
            break
        end

        Wait(0)
    end

    local input = lib.inputDialog(locale('MENUS.DIALOG.TITLE'), {
        {type = 'input', label = locale('MENUS.DIALOG.LABEL'), description = locale('MENUS.DIALOG.LABEL_DESCRIPTION', locale('DEFAULT_LABEL')), required = false},
        {type = 'select', label = locale('MENUS.DIALOG.TYPE'), description = locale('MENUS.DIALOG.TYPE_DESCRIPTION'), options = typeOptions, required = true },
        {type = 'checkbox', label = locale('MENUS.DIALOG.BLIP'), description = locale('MENUS.DIALOG.BLIP_DESCRIPTION') },
        {
            type = "select",
            label = locale('MENUS.DIALOG.GROUPS'),
            description = locale('MENUS.DIALOG.GROUPS_DESCRIPTION'),
            options = Illenium:GetGroups(),
            searchable = true,
            required = false
        }
    })

    if input and coords then
        local title = (input[1] and input[1] ~= "") and input[1] or locale('DEFAULT_LABEL')
        local type = input[2]
        local hasBlip = input[3] or false
        local hasPermission = input[4] or false
        lib.callback.await('lsk-illenium:server:Options', true, 'Create', title, type, hasBlip, coords, hasPermission)
    else
        Functions.notify(locale('NOTIFICATIONS.TITLE'), locale('NOTIFICATIONS.ERROR'), 'error', 15000)
    end
end

local Options = {
    Shops = function(Shops)
        Illenium:Shops(Shops)
    end
}

lib.callback.register('lsk-illenium:client:Options', function(mode, ...)
    local mode = mode or 'default'
    if not Options[mode] then return end
    Options[mode](...)
end)
