local REMOVE_HASH   = 1742849246
local REMOVE_COORDS = vector3(1682.46, 2572.39, 45.60)

CreateThread(function()
    while true do
        Wait(2000)
        local obj = GetClosestObjectOfType(
            REMOVE_COORDS.x, REMOVE_COORDS.y, REMOVE_COORDS.z,
            5.0, REMOVE_HASH, false, false, false
        )
        if obj ~= 0 and DoesEntityExist(obj) then
            SetEntityAsMissionEntity(obj, true, true)
            DeleteObject(obj)
        end
    end
end)
