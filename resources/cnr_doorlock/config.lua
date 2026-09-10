Config = Config or {}

Config.ToggleKey = 20 -- Z
Config.UseDistance = 5.0
Config.DrawDistance = 8.0

Config.DoorList = {


    -- Mission Row Cells
    {
        objHash = GetHashKey('v_ilev_ph_cellgate'), -- 1st cell
        objHeading = 270.0,
        objCoords = vector3(462.3, -993.6, 24.9),
        textCoords = vector3(461.8, -993.3, 25.0),
        locked = true,
        permanentLocked = true,
        maxDistance = 5.0,
    },
    {
        objHash = GetHashKey('v_ilev_ph_cellgate'), -- 2nd cell
        objHeading = 90.0,
        objCoords = vector3(462.3, -998.1, 24.9),
        textCoords = vector3(461.8, -998.8, 25.0),
        locked = true,
        permanentLocked = true,
        maxDistance = 5.0,
    },
    {
        objHash = GetHashKey('v_ilev_ph_cellgate'), -- 3rd cell
        objHeading = 86.2949,
        objCoords = vector3(461.8428, -1001.8630, 24.9149),
        textCoords = vector3(461.8428, -1001.8630, 25.4149),
        locked = true,
        permanentLocked = true,
        maxDistance = 5.0,
    },
    {
        objHash = GetHashKey('v_ilev_ph_cellgate'), -- ammunation door
        objHeading = 0.0,
        objCoords = vector3(463.8, -992.6, 24.9),
        textCoords = vector3(463.3, -992.6, 25.1),
        locked = false,
        maxDistance = 5.0,
    },
    {
        objHash = GetHashKey('v_ilev_gtdoor'), -- ammunation door2
        objHeading = 0.0,
        objCoords = vector3(463.4, -1003.5, 25.0),
        textCoords = vector3(464.0, -1003.5, 25.5),
        locked = false,
        maxDistance = 5.0,
    },

    -- Mission Row Back
    {
        textCoords = vector3(468.6, -1014.4, 27.1),
        locked = true,
        maxDistance = 5.0,
        doors = {
            { objHash = GetHashKey('v_ilev_rc_door2'), objHeading = 0.0,   objCoords = vector3(467.3, -1014.4, 26.5) },
            { objHash = GetHashKey('v_ilev_rc_door2'), objHeading = 180.0, objCoords = vector3(469.9, -1014.4, 26.5) },
        },
    },
    {
        objHash = GetHashKey('hei_prop_station_gate'),
        objHeading = 90.0,
        objCoords = vector3(488.8, -1017.2, 27.1),
        textCoords = vector3(488.8, -1020.2, 30.0),
        locked = true,
        autoDistance = 8.0,
        maxDistance = 8.0,
    },

    -- Sandy Shores
    {
        objHash = GetHashKey('v_ilev_shrfdoor'),
        objHeading = 30.0,
        objCoords = vector3(1855.1, 3683.5, 34.2),
        textCoords = vector3(1855.1, 3683.5, 35.0),
        locked = false,
        maxDistance = 5.0,
    },

    -- Paleto Bay
    {
        textCoords = vector3(-443.5, 6016.3, 32.0),
        locked = false,
        maxDistance = 5.0,
        doors = {
            { objHash = GetHashKey('v_ilev_shrf2door'), objHeading = 315.0, objCoords = vector3(-443.1, 6015.6, 31.7) },
            { objHash = GetHashKey('v_ilev_shrf2door'), objHeading = 135.0, objCoords = vector3(-443.9, 6016.6, 31.7) },
        },
    },

    -- Vespucci PD Jail cells (permanentLocked — frozen in default closed position)
    -- Hashes and coords from /doorscan standing at each cell door.
    -- 3 cells × 2 doors: jail_door bar gate + model 1609356763 sliding gate.
    {
        objHash = GetHashKey('jail_door'),
        objHeading = 36.7,
        objCoords = vector3(-1084.85, -812.47, 15.98),
        textCoords = vector3(-1084.85, -811.47, 16.48),
        locked = true,
        permanentLocked = true,
        maxDistance = 5.0,
    },
    {
        objHash = 1609356763,
        objHeading = 187.4,
        objCoords = vector3(-1085.62, -813.12, 15.99),
        textCoords = vector3(-1085.62, -812.12, 16.49),
        locked = true,
        permanentLocked = true,
        maxDistance = 5.0,
    },
    {
        objHash = GetHashKey('jail_door'),
        objHeading = 36.7,
        objCoords = vector3(-1081.86, -810.23, 15.98),
        textCoords = vector3(-1081.86, -809.23, 16.48),
        locked = true,
        permanentLocked = true,
        maxDistance = 5.0,
    },
    {
        objHash = 1609356763,
        objHeading = 183.6,
        objCoords = vector3(-1082.36, -810.68, 15.99),
        textCoords = vector3(-1082.36, -809.68, 16.49),
        locked = true,
        permanentLocked = true,
        maxDistance = 5.0,
    },
    {
        objHash = GetHashKey('jail_door'),
        objHeading = 217.0,
        objCoords = vector3(-1079.22, -811.43, 15.98),
        textCoords = vector3(-1079.22, -810.43, 16.48),
        locked = true,
        permanentLocked = true,
        maxDistance = 5.0,
    },
    {
        objHash = 1609356763,
        objHeading = 359.5,
        objCoords = vector3(-1078.99, -810.49, 15.42),
        textCoords = vector3(-1078.99, -809.49, 15.92),
        locked = true,
        permanentLocked = true,
        maxDistance = 5.0,
    },
    {
        objHash = 1467525553,
        objHeading = 185.6,
        objCoords = vector3(-1079.47, -808.49, 15.99),
        textCoords = vector3(-1079.47, -808.49, 16.49),
        locked = true,
        permanentLocked = true,
        maxDistance = 5.0,
    },
    {
        objHash = -1899196150,
        objHeading = 185.6,
        objCoords = vector3(-1079.41, -808.50, 16.01),
        textCoords = vector3(-1079.41, -808.50, 16.51),
        locked = true,
        permanentLocked = true,
        maxDistance = 5.0,
    },
    {
        objHash = -1899196150,
        objHeading = 358.1,
        objCoords = vector3(-1080.12, -807.31, 15.45),
        textCoords = vector3(-1080.12, -807.31, 15.95),
        locked = true,
        permanentLocked = true,
        maxDistance = 5.0,
    },
    {
        objHash = GetHashKey('jail_door'),
        objHeading = 36.6,
        objCoords = vector3(-1078.82, -807.96, 15.98),
        textCoords = vector3(-1078.82, -807.96, 16.48),
        locked = true,
        permanentLocked = true,
        maxDistance = 5.0,
    },
    {
        objHash = 1872312775,
        objHeading = 36.8,
        objCoords = vector3(-1080.70, -805.99, 14.98),
        textCoords = vector3(-1080.70, -805.99, 15.48),
        locked = true,
        permanentLocked = true,
        maxDistance = 5.0,
    },

    -- Bolingbroke Penitentiary
    {
        objHash = GetHashKey('prop_gate_prison_01'),
        objCoords = vector3(1844.9, 2604.8, 44.6),
        textCoords = vector3(1844.9, 2608.5, 48.0),
        locked = true,
        maxDistance = 12.0,
    },
    {
        objHash = GetHashKey('prop_gate_prison_01'),
        objCoords = vector3(1818.5, 2604.8, 44.6),
        textCoords = vector3(1818.5, 2608.4, 48.0),
        locked = true,
        maxDistance = 12.0,
    },

    -- Two interior Bolingbroke doors, frozen shut (scanned with /doorscan).
    {
        objHash = 1411103374,
        objHeading = 180.0,
        objCoords = vector3(1796.35, 2591.71, 44.64),
        textCoords = vector3(1796.35, 2591.71, 45.14),
        locked = true,
        permanentLocked = true,
        maxDistance = 5.0,
    },
    {
        objHash = -1156020871,
        objHeading = 180.0,
        objCoords = vector3(1798.09, 2591.69, 46.42),
        textCoords = vector3(1798.09, 2591.69, 46.92),
        locked = true,
        permanentLocked = true,
        maxDistance = 5.0,
    },
}
