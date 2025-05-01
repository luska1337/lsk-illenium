Functions = {}

local Core = exports.qbx_core

function Functions.isAdmin(source, permission)
    return Core:HasPermission(source, permission)
end

function Functions.notify(source, title, description, type, time)
    lib.notify(source, {
        title = title,
        description = description,
        type = type,
        duration = time
    })
end