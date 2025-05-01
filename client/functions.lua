Functions = {}

function Functions.notify(title, description, type, time)
    lib.notify({
        title = title,
        description = description,
        type = type,
        duration = time
    })
end


RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    lib.callback.await('lsk-illenium:server:loadPlayer', true)
end)

CreateThread(function()
    if not LocalPlayer.state.isLoggedIn then return end
    lib.callback.await('lsk-illenium:server:loadPlayer', true)
end)