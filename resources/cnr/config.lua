Config = {}

Config.Payouts = {
    storeRobbery = 1000,   -- 24/7 + liquor stores  (1 credit reward)
    bankRobbery  = 5000,   -- bank  (costs 5 credits)
    jewelryRobbery = 3000, -- jewelry (costs 3 credits)
    arrestCash   = 1000,
}

Config.XP = {
    -- Cop XP
    arrest     = 5,   -- arrest a robber: +5 XP (+ arrestCash)
    killWanted = 1,   -- kill a (wanted) robber: +1 XP
    -- Robber XP (per successful robbery)
    storeRob   = 1,   -- 24/7 / liquor store
    bigRob     = 1,   -- bank / jewelry store
    playerRob  = 0,   -- robbing a player (no XP, just cash)
}

-- ─── Police credit economy ──────────────────────────────────────────────────────
-- Cops no longer use XP/levels. They earn CREDITS (kills + arrests) and SPEND them at
-- the armory / vehicle yards. Credits persist until consumed or /newlife. Buying always
-- deducts the cost again (weapons are lost on death, so you re-buy). Cost 0 = free.
Config.Credits = {
    perKill          = 1,   -- killing a wanted robber
    perArrest        = 6,   -- standard arrest (escort to a station entrance)
    perInstantArrest = 3,   -- instant arrest (teleport to jail; fewer credits)
}

-- Credit cost to take each weapon at the armory. Anything not listed costs 0.
Config.WeaponCredits = {
    WEAPON_PISTOL = 0, WEAPON_STUNGUN = 0, WEAPON_NIGHTSTICK = 0, WEAPON_FLASHLIGHT = 0,
    WEAPON_PISTOL_MK2 = 1, WEAPON_COMBATPISTOL = 1, WEAPON_HEAVYPISTOL = 1,
    WEAPON_MICROSMG = 2, WEAPON_COMBATPDW = 2, WEAPON_SMG_MK2 = 2,
    WEAPON_PUMPSHOTGUN = 3, WEAPON_PUMPSHOTGUN_MK2 = 3, WEAPON_FIREEXTINGUISHER = 3,
    WEAPON_REVOLVER = 4, WEAPON_PISTOL50 = 4, WEAPON_FLAREGUN = 4,
    WEAPON_CARBINERIFLE = 5, WEAPON_CARBINERIFLE_MK2 = 5, WEAPON_SMOKEGRENADE = 5,  -- Tear Gas
    WEAPON_ASSAULTRIFLE = 7, WEAPON_ASSAULTRIFLE_MK2 = 7, WEAPON_BATTLERIFLE = 7,
    WEAPON_MARKSMANRIFLE = 7, WEAPON_APPISTOL = 7,
    WEAPON_SNIPERRIFLE = 10, WEAPON_MARKSMANRIFLE_MK2 = 10,
    WEAPON_COMBATMG = 15, WEAPON_HEAVYSNIPER = 15,
}

-- Display names for armory weapons (overrides the auto-generated label).
Config.WeaponLabels = {
    WEAPON_PISTOL = "Pistol", WEAPON_STUNGUN = "Stun Gun", WEAPON_NIGHTSTICK = "Nightstick",
    WEAPON_FLASHLIGHT = "Flashlight",
    WEAPON_PISTOL_MK2 = "Pistol Mk II", WEAPON_COMBATPISTOL = "Combat Pistol", WEAPON_HEAVYPISTOL = "Heavy Pistol",
    WEAPON_MICROSMG = "Micro SMG", WEAPON_COMBATPDW = "Combat PDW", WEAPON_SMG_MK2 = "SMG Mk II",
    WEAPON_PUMPSHOTGUN = "Pump Shotgun", WEAPON_PUMPSHOTGUN_MK2 = "Pump Shotgun Mk II", WEAPON_FIREEXTINGUISHER = "Fire Extinguisher",
    WEAPON_REVOLVER = "Heavy Revolver", WEAPON_PISTOL50 = "Pistol .50", WEAPON_FLAREGUN = "Flare Gun",
    WEAPON_CARBINERIFLE = "Carbine Rifle", WEAPON_CARBINERIFLE_MK2 = "Carbine Rifle Mk II", WEAPON_SMOKEGRENADE = "Tear Gas",
    WEAPON_ASSAULTRIFLE = "Assault Rifle", WEAPON_ASSAULTRIFLE_MK2 = "Assault Rifle Mk II", WEAPON_BATTLERIFLE = "Battle Rifle",
    WEAPON_MARKSMANRIFLE = "Marksman Rifle", WEAPON_APPISTOL = "AP Pistol",
    WEAPON_SNIPERRIFLE = "Sniper Rifle", WEAPON_MARKSMANRIFLE_MK2 = "Marksman Rifle Mk II",
    WEAPON_COMBATMG = "Combat MG", WEAPON_HEAVYSNIPER = "Heavy Sniper",
}

-- Credit cost per armor tier.
Config.ArmorCredits = {
    superlight = 0, light = 1, standard = 2, heavy = 4, superheavy = 5,
}

-- Credit cost per police vehicle. Keyed by model first; add-on cars (auto-loaded from
-- resources/[vehicles]/[police]) are matched by their folder-name label instead.
Config.VehicleCredits = {
    police = 0, policeb = 0,          -- Police Cruiser, Police Bike
    police2 = 1, polthrust = 1,        -- Police Cruiser 2, Dinka Thrust Police Bike
    police3 = 2, policeb2 = 2,         -- Police Cruiser 3, Police Dirtbike BF400
    policet = 3,                       -- Police Transporter
    polmav = 10,                       -- Police Maverick (heli)
    buzzard = 20,                      -- Police Buzzard (heli)
}
Config.VehicleCreditsByLabel = {
    ["police cruiser"] = 0, ["police bike"] = 0,
    ["police cruiser 2"] = 1, ["dinka thrust police bike"] = 1,
    ["police cruiser 3"] = 2, ["police dirtbike bf400"] = 2,
    ["police transporter"] = 3,
    ["police granger 3600lx"] = 5, ["police vapid aleutian"] = 5, ["alamo unmarked"] = 5,
    ["police grotti itali rsx"] = 10, ["police pfister comet s2"] = 10, ["police sentinel gts"] = 10,
    ["lspd brute stockade"] = 15,
    ["leo rcv"] = 20,
    ["police maverick"] = 10, ["police buzzard"] = 20,
}
Config.VehicleCreditsDefault = 5   -- unlisted add-on police vehicles

Config.JailTime = {
    storeRobbery      = 30,   -- robbery: +30 s
    bankRobbery       = 30,
    jewelryRobbery    = 30,
    killPlayer        = 60,   -- murder: +1 min
    prisonerKill      = 60,   -- a jailed prisoner killing any NPC/player: +1 min to sentence
    copShot           = 30,   -- innocent shooting a cop: +30 s (once)
    copCarStolen      = 30,   -- stealing a NEW police vehicle: +30 s
    robPlayer         = 60,   -- robbing another player: +1 min jail
    lowJailThreshold  = 180,   -- ≤ 180 s (3 min) → local PD;  > 180 s → Bolingbroke
}

Config.RobberyDurationSec = 30

Config.Robbery = {
    durationSec      = 30,
    startAimMs       = 800,
    startAimRadius   = 4.0,
    promptRadius     = 4.5,
    stayRadius       = 12.0,
    lootPickupRadius = 2.0,
}

Config.Spawns = {}

Config.PoliceStations = {
    missionRow = {
        label = 'Mission Row PD',
        entry = {
            exterior = vec4(441.0, -985.0, 30.69, 0.0),
            interior = vec4(441.4, -978.5, 30.69, 0.0),
        },
        exit = {
            interior = vec4(441.4, -978.5, 30.69, 180.0),
            exterior = vec4(441.0, -989.0, 30.69, 180.0),
        },
        spawn = vec4(452.0, -990.5, 30.69, 85.0),
        deskNpc = {
            model = 'mp_f_freemode_01',
            pos = vec4(441.15, -978.85, 30.69, 178.0),
            zOffset = -1.0,
        },
        armoryNpc = {
            model = 'mp_m_freemode_01',
            pos = vec4(454.0759, -979.9714, 30.6896, 87.0426),
            zOffset = -1.0,
        },
        rankTerminal = {
            pos = vec3(440.8722, -981.1363, 30.6896),
            spawn = vec4(440.8722, -981.1363, 30.6896, 2.7418),
            radius = 2.0,
        },
        weaponLocker = {
            pos = vec3(452.4108, -980.1582, 30.6896),
            radius = 2.5,
        },
        garageNpc = {
            model = 'mp_m_freemode_01',
            pos = vec4(454.50, -1023.5, 28.40, 85.0),
            zOffset = -1.0,
        },
        vehiclePreview = vec4(441.2105, -1022.0490, 28.2196, 91.1544),
        vehicleYard = vec4(441.2105, -1022.0490, 28.2196, 91.1544),
    },
    vespucci = {
        label = 'Vespucci PD',
        -- Spawn: locker room (two alternating points so cops spread out)
        spawn = {
            vec4(-1083.7656, -827.6849, 15.6458, 121.7991),
            vec4(-1082.9646, -829.4692, 15.6458, 127.1913),
        },
        -- Police Clothing NPC: reception desk, main floor
        deskNpc = {
            model = 'mp_f_freemode_01',
            pos = vec4(-1090.8534, -816.7415, 19.2960, 46.4728),
            zOffset = -1.0,
        },
        extraDeskNpcs = {
            { model = 'mp_f_freemode_01', pos = vec4(-1094.6283, -831.8137, 19.3198, 123.4289), zOffset = -1.0 },
        },
        -- Ammo/armory NPC: jail wing office
        armoryNpc = {
            model = 'mp_m_freemode_01',
            pos = vec4(-1074.9209, -816.4013, 15.6442, 126.0305),
            zOffset = -1.0,
        },
        garageNpc = {
            model = 'mp_m_freemode_01',
            pos = vec4(-1060.1859, -846.7502, 5.0417, 222.4309),
            zOffset = -1.0,
        },
        vehiclePreview = vec4(-1051.5548, -854.8337, 4.8684, 127.3359),
        vehicleYard    = vec4(-1051.5548, -854.8337, 4.8684, 127.3359),
    },
}

Config.Spawns.cops = {
    missionRow = vec3(Config.PoliceStations.missionRow.spawn.x, Config.PoliceStations.missionRow.spawn.y, Config.PoliceStations.missionRow.spawn.z),
    vespucci   = vec3(Config.PoliceStations.vespucci.spawn[1].x, Config.PoliceStations.vespucci.spawn[1].y, Config.PoliceStations.vespucci.spawn[1].z),
}

-- vec4: .w holds the spawn heading. Used for new robbers (after character
-- creation) and respawns when dying as a robber/innocent.
Config.Spawns.robbers = {
    vec4(-1037.9092, -2738.4326, 20.1693, 326.0602),
    vec4(-1037.9092, -2738.4326, 20.1693, 326.0602),
    vec4(  373.7766, -1778.6635, 29.2653,  41.9117),
    vec4(  115.6418, -1948.7930, 20.6631,  38.8055),
    vec4(-1364.5306, -1204.9137,  4.4516, 264.1475),
    vec4( -841.3306,   -74.4377,  37.8303, 208.1000),
    vec4(   55.2677,   268.1949, 109.5369, 159.7633),
    vec4(  234.5573,  -876.1462, 30.4921, 344.1656),
    vec4(  422.7965,  -359.3461,  47.1394, 227.2753),
    vec4( -150.7154,  -874.6870,  29.5916,  112.0384),
}

-- Robber clothing pool. The character creator does NOT let the player pick clothing;
-- it assigns a RANDOM complete outfit from the matching gender list at character creation.
-- Every entry here is a hand-captured, fully-compatible look (via /caprobber & /capoutfit),
-- so robbers always render correctly. Add more with /caprobber and paste them in.
-- Fields: top=jbib(11)  arms=uppr(3)  undershirt=accs(8)  pants=lowr(4)  shoes=feet(6)
Config.RobberOutfits = {
    male = {
        { top = 105, topTxt = 0,  arms = 11, undershirt = 2,  undershirtTxt = 0, pants = 28, pantsTxt = 0,  shoes = 1,  shoesTxt = 0 },
        { top = 135, topTxt = 6,  arms = 2,  undershirt = 15, undershirtTxt = 0, pants = 35, pantsTxt = 0,  shoes = 1,  shoesTxt = 0 },
        { top = 143, topTxt = 9,  arms = 2,  undershirt = 15, undershirtTxt = 0, pants = 37, pantsTxt = 0,  shoes = 1,  shoesTxt = 0 },
        { top = 157, topTxt = 3,  arms = 2,  undershirt = 23, undershirtTxt = 0, pants = 43, pantsTxt = 0,  shoes = 1,  shoesTxt = 0 },
        { top = 7,   topTxt = 13, arms = 2,  undershirt = 23, undershirtTxt = 0, pants = 43, pantsTxt = 0,  shoes = 4,  shoesTxt = 0 },
        { top = 77,  topTxt = 3,  arms = 2,  undershirt = 23, undershirtTxt = 0, pants = 63, pantsTxt = 0,  shoes = 10, shoesTxt = 0 },
        { top = 80,  topTxt = 1,  arms = 2,  undershirt = 15, undershirtTxt = 0, pants = 63, pantsTxt = 0,  shoes = 14, shoesTxt = 0 },
        { top = 86,  topTxt = 1,  arms = 2,  undershirt = 15, undershirtTxt = 0, pants = 76, pantsTxt = 0,  shoes = 24, shoesTxt = 0 },
        { top = 87,  topTxt = 6,  arms = 2,  undershirt = 15, undershirtTxt = 0, pants = 96, pantsTxt = 0,  shoes = 25, shoesTxt = 0 },
        { top = 126, topTxt = 6,  arms = 2,  undershirt = 15, undershirtTxt = 0, pants = 1,  pantsTxt = 0,  shoes = 31, shoesTxt = 0 },
        { top = 134, topTxt = 2,  arms = 2,  undershirt = 15, undershirtTxt = 0, pants = 3,  pantsTxt = 0,  shoes = 32, shoesTxt = 0 },
        { top = 143, topTxt = 9,  arms = 2,  undershirt = 17, undershirtTxt = 0, pants = 4,  pantsTxt = 0,  shoes = 35, shoesTxt = 0 },
        { top = 157, topTxt = 3,  arms = 2,  undershirt = 23, undershirtTxt = 0, pants = 5,  pantsTxt = 0,  shoes = 42, shoesTxt = 0 },
        { top = 76,  topTxt = 4,  arms = 11, undershirt = 24, undershirtTxt = 0, pants = 10, pantsTxt = 1,  shoes = 51, shoesTxt = 0 },
        { top = 86,  topTxt = 4,  arms = 11, undershirt = 1,  undershirtTxt = 0, pants = 13, pantsTxt = 1,  shoes = 54, shoesTxt = 0 },
        { top = 92,  topTxt = 6,  arms = 11, undershirt = 11, undershirtTxt = 0, pants = 42, pantsTxt = 1,  shoes = 3,  shoesTxt = 0 },
        { top = 108, topTxt = 6,  arms = 11, undershirt = 14, undershirtTxt = 0, pants = 45, pantsTxt = 2,  shoes = 8,  shoesTxt = 0 },
        { top = 112, topTxt = 0,  arms = 11, undershirt = 14, undershirtTxt = 0, pants = 22, pantsTxt = 12, shoes = 10, shoesTxt = 0 },
        { top = 118, topTxt = 8,  arms = 11, undershirt = 23, undershirtTxt = 0, pants = 25, pantsTxt = 6,  shoes = 15, shoesTxt = 0 },
        { top = 152, topTxt = 9,  arms = 2,  undershirt = 15, undershirtTxt = 0, pants = 42, pantsTxt = 0,  shoes = 3,  shoesTxt = 0 },
    },
    female = {
        { top = 23, topTxt = 2, arms = 0,  undershirt = 2,  undershirtTxt = 0, pants = 25, pantsTxt = 0,  shoes = 1,  shoesTxt = 0 },
        { top = 27, topTxt = 3, arms = 0,  undershirt = 5,  undershirtTxt = 0, pants = 26, pantsTxt = 0,  shoes = 2,  shoesTxt = 0 },
        { top = 31, topTxt = 3, arms = 0,  undershirt = 13, undershirtTxt = 0, pants = 27, pantsTxt = 3,  shoes = 6,  shoesTxt = 0 },
        { top = 35, topTxt = 3, arms = 0,  undershirt = 16, undershirtTxt = 0, pants = 44, pantsTxt = 3,  shoes = 9,  shoesTxt = 0 },
        { top = 49, topTxt = 1, arms = 0,  undershirt = 17, undershirtTxt = 0, pants = 51, pantsTxt = 3,  shoes = 10, shoesTxt = 0 },
        { top = 53, topTxt = 3, arms = 0,  undershirt = 20, undershirtTxt = 0, pants = 52, pantsTxt = 3,  shoes = 11, shoesTxt = 0 },
        { top = 55, topTxt = 0, arms = 0,  undershirt = 21, undershirtTxt = 0, pants = 54, pantsTxt = 2,  shoes = 14, shoesTxt = 0 },
        { top = 57, topTxt = 1, arms = 0,  undershirt = 13, undershirtTxt = 0, pants = 73, pantsTxt = 2,  shoes = 16, shoesTxt = 0 },
        { top = 65, topTxt = 1, arms = 0,  undershirt = 13, undershirtTxt = 0, pants = 74, pantsTxt = 2,  shoes = 22, shoesTxt = 0 },
        { top = 66, topTxt = 2, arms = 0,  undershirt = 13, undershirtTxt = 0, pants = 75, pantsTxt = 2,  shoes = 42, shoesTxt = 0 },
        { top = 69, topTxt = 0, arms = 0,  undershirt = 13, undershirtTxt = 0, pants = 76, pantsTxt = 0,  shoes = 77, shoesTxt = 0 },
        { top = 92, topTxt = 3, arms = 0,  undershirt = 20, undershirtTxt = 0, pants = 78, pantsTxt = 0,  shoes = 77, shoesTxt = 0 },
        { top = 0,  topTxt = 0, arms = 0,  undershirt = 2,  undershirtTxt = 0, pants = 8,  pantsTxt = 0,  shoes = 0,  shoesTxt = 0 },
        { top = 13, topTxt = 0, arms = 4,  undershirt = 2,  undershirtTxt = 0, pants = 9,  pantsTxt = 0,  shoes = 6,  shoesTxt = 0 },
        { top = 35, topTxt = 5, arms = 5,  undershirt = 5,  undershirtTxt = 0, pants = 14, pantsTxt = 9,  shoes = 7,  shoesTxt = 0 },
        { top = 65, topTxt = 5, arms = 5,  undershirt = 5,  undershirtTxt = 0, pants = 23, pantsTxt = 10, shoes = 8,  shoesTxt = 0 },
        { top = 66, topTxt = 3, arms = 5,  undershirt = 5,  undershirtTxt = 0, pants = 36, pantsTxt = 2,  shoes = 20, shoesTxt = 0 },
        { top = 1,  topTxt = 5, arms = 5,  undershirt = 16, undershirtTxt = 0, pants = 37, pantsTxt = 2,  shoes = 23, shoesTxt = 0 },
        { top = 37, topTxt = 4, arms = 15, undershirt = 21, undershirtTxt = 0, pants = 57, pantsTxt = 7,  shoes = 41, shoesTxt = 0 },
        { top = 35, topTxt = 3, arms = 1,  undershirt = 16, undershirtTxt = 0, pants = 37, pantsTxt = 3,  shoes = 13, shoesTxt = 0 },
    },
}

-- Curated, fully-compatible clothing the player can freely mix in the character creator
-- and at the clothing store. Each number is a drawable index captured via /capoutfit;
-- the texture for each is chosen separately. These render correctly with the fixed
-- arms / undershirt below, so any top+bottom+shoes combination is safe.
-- Add more by capturing with /capoutfit and pasting the drawable index into the list.
Config.RobberClothing = {
    male = {
        arms = 0, undershirt = 15, undershirtTxt = 0,
        tops  = { 0, 1, 26, 33, 34, 63, 73, 78, 80, 81, 82, 84, 86, 87, 89, 96, 105, 110, 123, 125, 126, 128, 134, 135, 138, 143, 153 },
        pants = { 0, 1, 42, 43, 45, 47, 48, 49, 50, 52, 54, 55, 60, 62, 64, 69, 70, 71, 75, 79, 82, 86, 96, 104 },
        shoes = { 3, 7, 18, 31, 32, 36, 40, 41, 45, 46, 49, 50, 52, 55, 56, 86, 89, 93 },
        -- Texture indices that render as the checkerboard "missing texture" for a given
        -- top drawable. Keyed by the TOP DRAWABLE index (not its list position). These are
        -- removed from the Top Texture selector; the shirt itself stays available.
        -- Add more as you find them via /capoutfit.
        topTexBlacklist = {
            [0] = { 6, 9, 10, 12, 13, 14, 15 },
            [1] = { 2, 9, 10, 13, 15 },
        },
        -- Cosmetics sold at the clothing store. hats = prop 0, glasses = prop 1,
        -- watches = prop 6, masks = component 1. Each gets a "None" option + a texture
        -- selector (clamped to what the item actually has). Indices invalid for the model
        -- are skipped automatically.
        hats    = { 2, 3, 4, 6, 7, 12, 13, 14, 15, 20, 21, 26, 29, 44, 45, 55, 77, 95, 104, 120, 154, 161, 166, 175, 198, 216 },
        glasses = { 2, 4, 5, 7, 8, 9, 10, 12, 13, 15, 17, 18, 20, 21, 23, 28, 30, 36, 37, 39, 46, 53, 54, 58 },
        watches = { 0, 3, 4, 5, 16, 18, 19, 20, 21, 32, 33, 34, 35, 37, 39 },
        masks   = { 4, 6, 16, 37, 46, 51, 54, 57, 105, 115, 148, 234 },
    },
    female = {
        arms = 4, undershirt = 6, undershirtTxt = 0,
        tops  = { 11, 13, 16, 23, 26, 28, 32, 36, 37, 39, 45, 54, 66, 70, 71, 77, 79, 87, 99, 105, 112, 118, 132, 142, 143, 151, 156, 158 },
        pants = { 0, 1, 2, 3, 4, 6, 7, 8, 11, 18, 24, 25, 26, 27, 31, 38, 74, 75, 77, 78, 80, 81, 82, 83, 84, 85, 87, 89, 91, 99, 102, 106, 107, 108 },
        shoes = { 22, 23, 24, 25, 26, 27, 28, 29, 30, 32, 33, 36, 37, 39, 41, 43, 47, 49, 52, 57, 58, 64, 67, 68, 72, 77, 93 },
        -- topTexBlacklist = { [11] = { ... } }, -- add checkerboard textures as you find them
        -- Female cosmetics (clothing store only). Textures are chosen per item in the menu.
        hats    = { 0, 2, 3, 4, 5, 8, 9, 11, 12, 13, 14, 21, 22, 28, 29, 30, 42, 43, 44, 60, 75, 103, 131, 135, 142, 150, 157, 188, 214 },
        glasses = { 0 },
        watches = { 7, 8, 9, 10, 22, 23, 24, 25, 26 },
        masks   = { 4, 6, 11, 14, 37, 49, 51, 54, 58 },
    },
}

Config.CharCreatorLocations = {
    cop = {
        ped  = vec4(457.0139, -990.8681, 30.6896, 93.2403),
        cam  = vec3(454.37, -991.92, 32.50),
        look = vec3(457.01, -990.87, 31.60),
    },
    robber = {
        ped  = vec4(198.1415, -932.5767, 30.6868, 319.5725),
        cam  = vec3(199.18, -929.93, 32.50),
        look = vec3(198.14, -932.58, 31.60),
    },
}

Config.AmbientVehicles = {
    models = {
        'blista', 'asea', 'ingot', 'primo', 'fugitive', 'stanier', 'surge',
        'sultan', 'futo', 'buffalo', 'oracle', 'felon', 'baller', 'granger',
        'rebel', 'sandking', 'bison', 'minivan', 'rhapsody', 'panto',
    },
    spawns = {},
}

Config.Stores = {
    -- 24/7 & gas (ef_shops supermarket / Gobz coords)
    { name = "24/7 Strawberry",           ped = vec4(24.47, -1346.62, 29.5, 271.66),       cashier = vec3(24.47, -1346.62, 29.5),       payout = Config.Payouts.storeRobbery },
    { name = "24/7 Chumash",              ped = vec4(-3039.54, 584.38, 7.91, 17.60),       cashier = vec3(-3039.54, 584.38, 7.91),       payout = Config.Payouts.storeRobbery },
    { name = "24/7 Barbareno Rd",         ped = vec4(-3242.97, 1000.01, 12.83, 357.57),    cashier = vec3(-3242.97, 1000.01, 12.83),     payout = Config.Payouts.storeRobbery },
    { name = "24/7 Paleto Bay",           ped = vec4(1728.07, 6415.63, 35.04, 242.95),     cashier = vec3(1728.07, 6415.63, 35.04),      payout = Config.Payouts.storeRobbery },
    { name = "24/7 Grapeseed",            ped = vec4(1697.96, 4923.04, 42.06, 326.61),     cashier = vec3(1697.96, 4923.04, 42.06),      payout = Config.Payouts.storeRobbery },
    { name = "24/7 Sandy Shores",         ped = vec4(1959.82, 3740.48, 32.34, 301.57),     cashier = vec3(1959.82, 3740.48, 32.34),      payout = Config.Payouts.storeRobbery },
    { name = "24/7 Harmony",              ped = vec4(549.13, 2671.35, 42.16, 100.01),      cashier = vec3(549.13, 2671.35, 42.16),       payout = Config.Payouts.storeRobbery },
    { name = "24/7 Senora Fwy",           ped = vec4(2677.47, 3279.76, 55.24, 335.08),     cashier = vec3(2677.47, 3279.76, 55.24),      payout = Config.Payouts.storeRobbery },
    { name = "24/7 Tataviam",              ped = vec4(2556.8, 381.27, 108.62, 359.15),      cashier = vec3(2556.8, 381.27, 108.62),       payout = Config.Payouts.storeRobbery },
    { name = "24/7 Downtown Vinewood",    ped = vec4(372.66, 326.98, 103.57, 253.73),      cashier = vec3(372.66, 326.98, 103.57),      payout = Config.Payouts.storeRobbery },
    { name = "LTD Innocence Blvd",        ped = vec4(-47.42, -1758.67, 29.42, 47.26),      cashier = vec3(-47.42, -1758.67, 29.42),     payout = Config.Payouts.storeRobbery },
    { name = "LTD Banning",               ped = vec4(-706.17, -914.64, 19.22, 88.77),      cashier = vec3(-706.17, -914.64, 19.22),     payout = Config.Payouts.storeRobbery },
    { name = "LTD Richman Glen",          ped = vec4(-1819.53, 793.49, 138.09, 131.46),    cashier = vec3(-1819.53, 793.49, 138.09),    payout = Config.Payouts.storeRobbery },
    { name = "LTD Mirror Park",           ped = vec4(1164.82, -323.66, 69.21, 106.86),     cashier = vec3(1164.82, -323.66, 69.21),     payout = Config.Payouts.storeRobbery },
    -- Rob's Liquor (ef_shops robsliquor coords)
    { name = "Rob's Liquor Vespucci",     ped = vec4(-1221.38, -907.89, 12.33, 27.51),      cashier = vec3(-1221.38, -907.89, 12.33),    payout = Config.Payouts.storeRobbery },
    { name = "Rob's Liquor Prosperity",   ped = vec4(-1486.82, -377.48, 40.16, 130.89),    cashier = vec3(-1486.82, -377.48, 40.16),    payout = Config.Payouts.storeRobbery },
    { name = "Rob's Liquor Chumash",      ped = vec4(-2966.41, 391.62, 15.04, 87.82),      cashier = vec3(-2966.41, 391.62, 15.04),     payout = Config.Payouts.storeRobbery },
    { name = "Rob's Liquor Route 68",     ped = vec4(1165.15, 2710.78, 38.16, 177.96),     cashier = vec3(1165.15, 2710.78, 38.16),     payout = Config.Payouts.storeRobbery },
    { name = "Rob's Liquor Mirror Park",  ped = vec4(1134.3, -983.26, 46.42, 276.3),        cashier = vec3(1134.3, -983.26, 46.42),      payout = Config.Payouts.storeRobbery },
    { name = "Rob's Liquor Sandy Shores", ped = vec4(1744.65, 3611.95, 34.89, 311.19),      cashier = vec3(1744.65, 3611.95, 34.89),     payout = Config.Payouts.storeRobbery },
}

Config.Banks = {
    { name = "Fleeca Legion Square",  teller = vec4(147.0, -1040.20, 29.37, 160.0), ped = vec4(147.0, -1042.5, 29.37, 340.0), payout = Config.Payouts.bankRobbery },
    { name = "Fleeca Hawick",         teller = vec4(310.0, -278.95, 54.17, 160.0),  ped = vec4(310.0, -281.0, 54.17, 340.0),  payout = Config.Payouts.bankRobbery },
    { name = "Fleeca Great Ocean Hwy", teller = vec4(-2965.0, 482.94, 15.70, 270.0), ped = vec4(-2965.0, 480.0, 15.70, 90.0), payout = Config.Payouts.bankRobbery },
    { name = "Fleeca Banham Canyon",  teller = vec4(-1211.2094, -332.1420, 37.7810, 32.1899), ped = vec4(-1213.3101, -332.6627, 37.7809, 28.0272), payout = Config.Payouts.bankRobbery },
    { name = "Pacific Standard",      teller = vec4(232.0, 216.50, 106.29, 160.0), ped = vec4(232.0, 214.0, 106.29, 340.0), payout = Config.Payouts.bankRobbery },
}

Config.JewelryStores = {
    { name = "Vangelico Jewelry", teller = vec4(-622.25, -230.92, 38.06, 125.0), payout = Config.Payouts.jewelryRobbery },
}

Config.Jail = {
    -- Mission Row holding cells (verified in-game)
    missionRowCells = {
        vec4(460.0584, -994.2330,  24.9149, 260.7717),
        vec4(459.5119, -997.8989,  24.9149, 263.4555),
        vec4(460.2803, -1001.5562, 24.9149, 267.1288),
        vec4(467.7009, -994.5691,  24.9147, 178.6101),
        vec4(472.1772, -994.4175,  24.9147, 178.4801),
        vec4(476.3355, -994.3356,  24.9147, 176.7862),
        vec4(480.8525, -994.4323,  24.9147, 179.9334),
    },
    missionRowRelease = vec4(490.0042, -1002.4050, 27.8351, 269.2635),

    -- Vespucci PD holding cells (verified in-game)
    vespucciCells = {
        vec4(-1086.2407, -811.5524, 15.6442, 211.4768),
        vec4(-1083.6492, -809.1373, 15.6442, 214.6089),
        vec4(-1080.3955, -806.9815, 15.6442, 213.2097),
        vec4(-1077.1338, -811.9423, 15.6442,  34.8548),
    },
    vespucciRelease = vec4(-1068.6250, -886.5149, 4.5884, 205.2778),

    bolingbroke        = vec3(1690.0, 2565.0, 45.56),
    bolingbrokeRelease = vec3(1846.0, 2585.0, 45.0),

    -- Bolingbroke cell spots (3 tiers). A long-sentence inmate is teleported to one
    -- of these, chosen uniformly at random — every spot has an equal chance.
    bolingbrokeCells = {
        vec4(1666.4373, 2572.2971, 50.1898, 266.7263),
        vec4(1666.7472, 2575.5898, 50.1896, 271.3210),
        vec4(1666.0289, 2579.5330, 50.1898, 265.5582),
        vec4(1666.2023, 2583.0168, 50.1898, 268.3194),
        vec4(1666.2954, 2586.7322, 50.1897, 266.6755),
        vec4(1666.2172, 2590.2710, 50.1897, 267.2236),
        vec4(1666.5918, 2594.1658, 50.1893, 271.8731),
        vec4(1666.3602, 2597.5559, 50.1894, 265.5196),
        vec4(1666.6995, 2601.1440, 50.1895, 266.6477),
        vec4(1666.6189, 2604.8472, 50.1897, 270.1444),
        vec4(1666.5526, 2608.7217, 50.1897, 266.2179),
        vec4(1666.5376, 2611.9922, 50.1897, 270.0988),
        vec4(1670.8776, 2618.5432, 50.1901, 173.3168),
        vec4(1674.4752, 2618.6477, 50.1898, 177.2827),
        vec4(1678.1917, 2618.4143, 50.1893, 177.8344),
        vec4(1681.5927, 2618.6614, 50.1892, 177.8891),
        vec4(1685.4651, 2618.2058, 50.1890, 179.4017),
        vec4(1689.0364, 2618.4814, 50.1892, 176.6354),
        vec4(1692.6593, 2618.5229, 50.1892, 179.1204),
        vec4(1696.2239, 2618.3621, 50.1891, 179.6255),
        vec4(1699.9741, 2618.1445, 50.1890, 184.1009),
        vec4(1703.4468, 2618.2966, 50.1890, 179.4405),
        vec4(1707.0714, 2618.3706, 50.1891, 178.7137),
        vec4(1710.7167, 2618.4795, 50.1900, 175.1151),
        vec4(1714.8673, 2612.1418, 50.1897, 87.9850),
        vec4(1714.5983, 2608.4634, 50.1897, 90.9768),
        vec4(1714.7639, 2604.9067, 50.1897, 79.9485),
        vec4(1714.9359, 2601.2161, 50.1894, 88.1013),
        vec4(1715.1219, 2597.6072, 50.1893, 85.8188),
        vec4(1714.8680, 2593.9189, 50.1893, 90.8152),
        vec4(1715.0544, 2590.3240, 50.1897, 90.3455),
        vec4(1715.1361, 2586.7292, 50.1897, 89.2587),
        vec4(1715.1447, 2582.9858, 50.1898, 86.4855),
        vec4(1714.7443, 2579.3267, 50.1897, 86.8948),
        vec4(1714.7469, 2575.5156, 50.1897, 90.4115),
        vec4(1714.7114, 2571.8906, 50.1900, 88.3522),
        vec4(1666.6096, 2572.2749, 53.1905, 265.6793),
        vec4(1666.5328, 2575.8525, 53.1905, 271.0682),
        vec4(1666.2721, 2579.2847, 53.1905, 270.1219),
        vec4(1666.2053, 2583.1113, 53.1905, 265.5914),
        vec4(1666.4003, 2586.6750, 53.1905, 268.6592),
        vec4(1666.5146, 2590.1692, 53.1904, 270.4935),
        vec4(1666.5475, 2594.1682, 53.1901, 266.2782),
        vec4(1666.2197, 2597.6802, 53.1902, 266.8269),
        vec4(1666.4738, 2601.3406, 53.1903, 267.9899),
        vec4(1666.3677, 2604.6379, 53.1904, 267.1918),
        vec4(1666.2483, 2608.3318, 53.1905, 266.0281),
        vec4(1666.4994, 2612.2336, 53.1905, 264.3118),
        vec4(1670.7356, 2618.3250, 53.1909, 179.3955),
        vec4(1674.3677, 2618.5918, 53.1906, 180.3341),
        vec4(1678.0825, 2618.4741, 53.1901, 177.9447),
        vec4(1681.5927, 2618.4143, 53.1899, 180.7092),
        vec4(1685.2808, 2618.5581, 53.1900, 178.2299),
        vec4(1688.9216, 2618.1262, 53.1897, 178.0323),
        vec4(1692.4255, 2618.3630, 53.1899, 180.5441),
        vec4(1696.2640, 2618.5469, 53.1900, 179.1070),
        vec4(1700.0969, 2618.2983, 53.1898, 176.8456),
        vec4(1703.7848, 2618.2576, 53.1898, 174.9462),
        vec4(1707.3558, 2618.3701, 53.1900, 175.7356),
        vec4(1710.9980, 2618.4351, 53.1908, 175.2209),
        vec4(1714.7815, 2612.0549, 53.1905, 89.4323),
        vec4(1714.7590, 2608.4370, 53.1905, 89.9727),
        vec4(1714.8125, 2604.7349, 53.1905, 88.7124),
        vec4(1715.0771, 2601.2644, 53.1902, 92.5478),
        vec4(1714.8503, 2597.5881, 53.1900, 91.8859),
        vec4(1714.8081, 2593.8020, 53.1900, 91.5466),
        vec4(1714.5601, 2590.3965, 53.1905, 88.1696),
        vec4(1714.6818, 2586.4651, 53.1905, 94.4911),
        vec4(1714.7709, 2582.8916, 53.1905, 90.8353),
        vec4(1714.6562, 2579.4324, 53.1905, 94.0264),
        vec4(1714.7006, 2575.6870, 53.1905, 92.3255),
        vec4(1714.7811, 2571.8948, 53.1908, 91.4838),
        vec4(1666.2410, 2572.1155, 56.0959, 270.9174),
        vec4(1666.3256, 2575.6433, 56.0958, 269.8388),
        vec4(1666.4323, 2579.1780, 56.0957, 268.5519),
        vec4(1666.2871, 2582.8850, 56.0957, 270.0469),
        vec4(1666.4246, 2586.4836, 56.0957, 266.9952),
        vec4(1666.4781, 2590.2146, 56.0957, 266.4789),
        vec4(1666.5657, 2593.7869, 56.0954, 270.9590),
        vec4(1666.8167, 2597.7319, 56.0953, 269.1696),
        vec4(1666.4531, 2601.2314, 56.0956, 267.1785),
        vec4(1666.5833, 2604.6475, 56.0957, 268.7019),
        vec4(1666.4985, 2608.7749, 56.0957, 267.6984),
        vec4(1666.5662, 2612.3008, 56.0957, 271.6696),
        vec4(1670.7303, 2618.5479, 56.0962, 177.4466),
        vec4(1674.2725, 2618.4734, 56.0958, 177.5048),
        vec4(1678.0695, 2618.4851, 56.0954, 177.0919),
        vec4(1681.8571, 2618.5288, 56.0952, 178.9086),
        vec4(1685.2313, 2618.0547, 56.0949, 183.6071),
        vec4(1688.9514, 2618.3608, 56.0951, 181.0078),
        vec4(1692.5071, 2618.3115, 56.0951, 176.5289),
        vec4(1696.2706, 2618.4451, 56.0952, 180.3732),
        vec4(1699.7909, 2618.4172, 56.0951, 184.8153),
        vec4(1703.4120, 2618.5256, 56.0952, 178.0849),
        vec4(1707.0444, 2618.3381, 56.0952, 177.5941),
        vec4(1710.7094, 2618.5168, 56.0960, 177.0762),
        vec4(1714.9576, 2612.0669, 56.0958, 96.4528),
        vec4(1714.7220, 2608.3193, 56.0957, 88.3533),
        vec4(1714.9795, 2604.9246, 56.0958, 92.1281),
        vec4(1715.1650, 2601.1924, 56.0955, 88.6061),
        vec4(1715.0580, 2597.4841, 56.0953, 88.5600),
        vec4(1714.8813, 2593.9612, 56.0952, 87.6505),
        vec4(1714.9926, 2590.1506, 56.0958, 89.3172),
        vec4(1715.0730, 2586.6392, 56.0958, 89.0557),
        vec4(1714.3640, 2582.9102, 56.0957, 87.6325),
        vec4(1714.9553, 2579.1982, 56.0958, 90.8300),
        vec4(1714.7357, 2575.6697, 56.0957, 90.8058),
        vec4(1714.8033, 2571.9590, 56.0960, 88.1856),
    },
}

-- Bolingbroke prison jumpsuit, applied while serving a long sentence. Uses the
-- textures streamed by the `prison_outfit` resource:
--   top  = component 11 (jbib),  legs = component 4 (lowr).
-- The drawable/texture below come from the prison_outfit filenames (texture 'b' = 1).
-- If the outfit renders wrong (e.g. checkerboard), tweak the drawable/texture here
-- to the value that shows the jumpsuit in-game for that ped.
Config.Jail.prisonOutfit = {
    male = {
        top        = { drawable = 15, texture = 0 },  -- jbib (comp 11)
        legs       = { drawable = 3,  texture = 7 },  -- lowr (comp 4)
        shoes      = { drawable = 34, texture = 0 },  -- comp 6
        undershirt = { drawable = 15, texture = 0 },  -- comp 8
        arms       = { drawable = 15, texture = 0 },  -- comp 3 (incl. sleeve texture)
    },
    female = {
        top        = { drawable = 23, texture = 0 },
        legs       = { drawable = 3,  texture = 15 },
        shoes      = { drawable = 35, texture = 0 },
        undershirt = { drawable = 6,  texture = 0 },
        arms       = { drawable = 4,  texture = 0 },
    },
}

-- (Laundry jail-time-reduction feature removed.)

-- All police stations where a cop can deliver an arrested suspect.
-- 'station' controls which holding facility the prisoner is sent to.
Config.ArrestEntrances = {
    {
        name    = 'Mission Row PD',
        center  = vec3(471.5896, -1023.3898, 28.1632),
        radius  = 3.0,
        station = 'missionRow',
    },
    {
        name    = 'Vespucci PD',
        center  = vec3(-1065.7203, -813.8340, 7.9307),
        radius  = 3.5,
        station = 'vespucci',
    },
}
-- Backward-compat alias used by older code paths
Config.ArrestEntrance = Config.ArrestEntrances[1]

-- Cop progression is a flat Level ladder (no jurisdictions). A player's level is
-- derived automatically from XP (see CnR.Util.rankFromXp); weapons, armor, vehicles
-- and helicopters are cumulative up to the current level. Weapons here define what is
-- buyable at the ARMORY NPC (cops always SPAWN with only pistol/nightstick/taser/
-- flashlight). Vehicles/helis define what the yard / air-support NPC offer.
-- Helicopter models (polmav/annihilator/buzzard) are listed in Config.Helicopters so
-- they show on the air-support NPC instead of the ground yard.
--
-- Vehicle display name -> model used below (verify against your addon spawn names):
--   Police Cruiser=police  Police Bike=policeb  Police Cruiser 2=police2  Police Cruiser 3=police3
--   Police Riot=riot  Sheriff SUV=sheriff2  Sheriff Cruiser=sheriff  Park Ranger=pranger
--   Police Cruiser (Vintage)=policeold1  FIB Buffalo=fbi  FIB Rancher=fbi2  Insurgent=insurgent
--   Riot Van=riot2 (GUESS)  Riot Van 2=policet (GUESS)
--   Police Maverick=polmav  Annihilator=annihilator  Buzzard=buzzard  (helicopters)
Config.Ranks = {
    {
        id = 1, name = "Level 1", xp = 0,
        weapons  = { "WEAPON_PISTOL", "WEAPON_STUNGUN", "WEAPON_NIGHTSTICK", "WEAPON_FLASHLIGHT" },
        armor    = "superlight",
        -- ALL vehicles are available from Level 1 (ground vehicles in the Vehicle Yard,
        -- helicopters in Police Air Support). Weapons/armor still unlock per level.
        -- NOTE: add-on cars dropped into resources/[vehicles]/[police] are auto-added to
        -- this list at runtime by server/vehicle_autoload.lua — no need to list them here.
        vehicles = {
            "police", "policeb",
            "police2", "police3",
            "policet",         -- Police Transporter
        },
    },
    {
        id = 2, name = "Level 2", xp = 10,
        weapons  = { "WEAPON_PISTOL_MK2", "WEAPON_COMBATPISTOL", "WEAPON_HEAVYPISTOL" },
        armor    = "light",
        vehicles = {},  -- all vehicles moved to Level 1
    },
    {
        id = 3, name = "Level 3", xp = 20,
        weapons  = { "WEAPON_MICROSMG", "WEAPON_COMBATPDW", "WEAPON_SMG_MK2", "WEAPON_FIREEXTINGUISHER" },
        armor    = "standard",
        vehicles = { "polmav" },  -- Police Maverick (heli) unlocks at Level 3
    },
    {
        id = 4, name = "Level 4", xp = 40,
        weapons  = { "WEAPON_PUMPSHOTGUN", "WEAPON_PUMPSHOTGUN_MK2", "WEAPON_REVOLVER", "WEAPON_PISTOL50", "WEAPON_FLAREGUN" },
        armor    = "standard",
        vehicles = {},  -- all vehicles moved to Level 1
    },
    {
        id = 5, name = "Level 5", xp = 80,
        weapons  = { "WEAPON_CARBINERIFLE", "WEAPON_CARBINERIFLE_MK2", "WEAPON_SMOKEGRENADE", "GADGET_PARACHUTE" },
        armor    = "heavy",
        vehicles = {},  -- (Police Cruiser Vintage removed)
    },
    {
        id = 6, name = "Level 6", xp = 160,
        weapons  = { "WEAPON_ASSAULTRIFLE", "WEAPON_ASSAULTRIFLE_MK2" },
        armor    = "heavy",
        vehicles = {},  -- (FIB Buffalo removed)
    },
    {
        id = 7, name = "Level 7", xp = 320,
        weapons  = { "WEAPON_BATTLERIFLE" },
        armor    = "superheavy",
        vehicles = {},  -- (FIB Rancher removed)
    },
    {
        -- NOTE: the spec listed Level 8 XP as 320 (same as Level 7). Kept as given —
        -- reaching 320 XP jumps straight to Level 8 (both L7 + L8 unlocks apply). If
        -- you meant the doubling pattern, change this to 640.
        id = 8, name = "Level 8", xp = 320,
        weapons  = { "WEAPON_MARKSMANRIFLE", "WEAPON_APPISTOL", "WEAPON_SNIPERRIFLE" },
        armor    = "superheavy",
        vehicles = {},  -- all vehicles moved to Level 1
    },
    {
        id = 9, name = "Level 9", xp = 640,
        weapons  = { "WEAPON_MARKSMANRIFLE_MK2", "WEAPON_COMBATMG" },
        armor    = "superheavy",
        vehicles = {},  -- all vehicles moved to Level 1
    },
    {
        id = 10, name = "Level 10", xp = 1280,
        weapons  = { "WEAPON_HEAVYSNIPER" },
        armor    = "superheavy",
        vehicles = { "buzzard" },  -- armed Buzzard (stock) unlocks at Level 10
    },
}

-- Robbers use the same CREDITS currency as cops (no XP/levels). They earn credits from
-- store robberies and spend them to unlock bigger jobs.
--   • Any 24/7 / liquor store robbery completed  -> +1 credit and $1,000
--   • Jewelry robbery  -> costs 3 credits to start, pays $3,000
--   • Bank robbery     -> costs 5 credits to start, pays $5,000
-- Credits persist through death/jail; only consumed by use or wiped by /newlife.
Config.RobberCredits = {
    perStoreRob = 1,    -- reward for a completed 24/7 / liquor store robbery
    bankCost    = 5,    -- credits required & consumed to start a bank robbery
    jewelryCost = 3,    -- credits required & consumed to start a jewelry robbery
}

-- Police Clothing store catalog (LSPD ranks). Each outfit is a component set the
-- player can equip at the "Police Clothing" NPC once their level meets `minLevel`.
-- Component fields mirror CnR.Util.ApplyCopUniform:
--   top/topTxt = component 11 (jbib), pants = 4 (lowr), shoes = 6 (feet),
--   undershirt = 8 (accs), arms/armsTxt = 3 (uppr), decl/declTxt = 10 (badge),
--   mask = 1, accessory = 7, hat = prop 0.  Set hat = -1 to wear no hat.
-- NOTE: the values below are PLACEHOLDERS. Wear each LSPD_EUP uniform in vMenu,
-- run /capoutfit, and paste the captured male/female numbers here per rank.
Config.Outfits = {
    {
        id = 1, name = "LSPD Patrol Officer", minLevel = 1,
        male   = { top = 55, topTxt = 0, pants = 35, pantsTxt = 0, shoes = 25, shoesTxt = 0, undershirt = 58, undershirtTxt = 0, arms = 0,  hat = 46, hatTxt = 0 },
        female = { top = 48, topTxt = 0, pants = 34, pantsTxt = 0, shoes = 25, shoesTxt = 0, undershirt = 35, undershirtTxt = 0, arms = 14, hat = 45, hatTxt = 0 },
    },
    {
        id = 2, name = "LSPD Senior Officer", minLevel = 5,
        male   = { top = 55, topTxt = 1, pants = 35, pantsTxt = 1, shoes = 25, shoesTxt = 0, undershirt = 58, undershirtTxt = 1, arms = 0,  hat = 46, hatTxt = 1 },
        female = { top = 48, topTxt = 1, pants = 34, pantsTxt = 1, shoes = 25, shoesTxt = 0, undershirt = 35, undershirtTxt = 1, arms = 14, hat = 45, hatTxt = 1 },
    },
    {
        id = 3, name = "LSPD Sergeant", minLevel = 8,
        male   = { top = 4,  topTxt = 0, pants = 10, pantsTxt = 0, shoes = 10, shoesTxt = 0, undershirt = 0,  undershirtTxt = 0, arms = 1,  accessory = 3, accessoryTxt = 0, hat = -1 },
        female = { top = 6,  topTxt = 1, pants = 6,  pantsTxt = 1, shoes = 13, shoesTxt = 0, undershirt = 22, undershirtTxt = 0, arms = 1,  hat = -1 },
    },
    {
        id = 4, name = "LSPD Lieutenant", minLevel = 11,
        male   = { top = 53, topTxt = 0, pants = 31, pantsTxt = 0, shoes = 25, shoesTxt = 0, undershirt = 15, undershirtTxt = 0, arms = 12, mask = 52, maskTxt = 0, hat = -1 },
        female = { top = 48, topTxt = 0, pants = 34, pantsTxt = 0, shoes = 25, shoesTxt = 0, undershirt = 35, undershirtTxt = 0, arms = 14, hat = 45, hatTxt = 0 },
    },
}

-- How many drawables the LSPD_EUP pack adds per component. Streamed clothing is
-- appended at the END of each component's list, so the Police Clothing browser only
-- shows this trailing slice (the pack) instead of every vanilla item. Update these
-- if the EUP pack's .ydd counts change.
Config.EupClothing = {
    male   = { jbib = 21, lowr = 4, accs = 5, task = 11, hand = 4, decl = 4 },
    female = { jbib = 19, lowr = 4, accs = 3, task = 10, hand = 2, decl = 4 },
}

Config.VehicleCooldownSec = 120

-- Helicopters are handled by dedicated rooftop "Police Air Support" NPCs instead of
-- the ground vehicle yard. These models are hidden from the yard list and shown by
-- the air-support NPCs, which preview/spawn them on their own helipad.
--   pos = where the NPC stands,  pad = preview camera + spawn point.
Config.Helicopters = { 'polmav', 'annihilator', 'buzzard' }
Config.HeliNpcs = {
    {
        key = 'heliMissionRow',
        model = 'mp_m_freemode_01',
        pos = vec4(455.5277, -986.0518, 43.6917, 279.1791),
        pad = vec4(449.2925, -981.2500, 43.6917, 275.1210),
        zOffset = -1.0,
    },
    {
        key = 'heliVespucci',
        model = 'mp_m_freemode_01',
        pos = vec4(-1102.8026, -833.1104, 37.6756, 128.0665),
        pad = vec4(-1095.2205, -835.0055, 37.6756, 124.6913),
        zOffset = -1.0,
    },
}

-- Returns the helipad (preview + spawn) for a given air-support station key, or nil.
function Config.HeliPadFor(key)
    for _, h in ipairs(Config.HeliNpcs or {}) do
        if h.key == key then return h.pad end
    end
    return nil
end

-- Auto-registration of add-on vehicles dropped into resources/[vehicles].
--   [vehicles]/[police]      -> appears in the cop Vehicle Yard (Level 1, all unlocked)
--   [vehicles]/[dealership]  -> appears in the Premium Deluxe dealership menu
-- Model names are read from each resource's vehicles.meta automatically. List any
-- model here to keep it from being auto-added (e.g. a second variant in a pack).
Config.VehicleAutoload = {
    exclude = {
        'sheriffswatstoc',  -- ag_stockade_pack ships this Sheriff variant; keep it hidden
        'opd1',             -- Chevrolet Tahoe Whelen — removed from the yard
        -- Police Thrust pack defines these too but ships no models for them; hide them.
        'fbialamo', 'hwayalamo', 'hwayalamo2', 'sheralamo',
        'policeb1',         -- Hakucho addon (BF400 pack meta defines it but no model shipped)
    },
}

-- Force a specific livery (paint/skin) on a vehicle in the preview AND when spawned,
-- so models that ship multiple liveries (e.g. LSPD + Sheriff) don't show a random one.
-- Index is the livery number; if the wrong skin shows, try another value (0,1,2,…).
Config.VehicleLivery = {
    ineos  = 0,  -- Ineos Grenadier: lock to the LSPD livery
    polmav = 0,  -- Police Maverick: lock to livery 0 (LSPD) so it never shows the ambulance skin
    policeb2 = 2, -- BF400 dirtbike: lock to LSPD livery (livery 2 = POLICE markings)
}

-- Force a paint colour {primary, secondary} on the preview AND spawn. Use /color in the
-- vehicle to find indices. GTA: 0 = Metallic Black, 12 = Matte Black, 11 = Graphite.
Config.VehicleColor = {
    ad_leorcvrb = { 0, 0 },  -- LEO RCV: force black (white is its paint, not a livery)
    umkalamo    = { 0, 0 },  -- Alamo Unmarked: force black
}

Config.VehicleLabels = {
    police      = 'Police Cruiser',
    policeb     = 'Police Bike',
    police2     = 'Police Cruiser 2',
    police3     = 'Police Cruiser 3',
    police4     = 'Police Riot',
    policeold1  = 'Police Cruiser (Vintage)',
    policet     = 'Police Transporter',
    polmav      = 'Police Maverick',
    granger     = 'Police Granger',
    sheriff     = 'Sheriff Cruiser',
    sheriff2    = 'Sheriff SUV',
    pranger     = 'Park Ranger',
    fbi         = 'FIB Buffalo',
    fbi2        = 'FIB Rancher',
    riot        = 'Riot Van',
    riot2       = 'Riot Van 2',
    insurgent   = 'Insurgent',
    annihilator = 'Annihilator',
    buzzard     = 'Police Buzzard',
    polswatstoc     = 'SWAT Stockade',
    chpkawasaki     = 'CHP Kawasaki (Bike)',
    pgranger2       = 'Police Granger 2',
    polsentinel     = 'Police Sentinel',
}

Config.Blips = {
    police = {
        { name = "Mission Row PD", pos = vec3( 441.0,  -982.0,  30.7), sprite = 60, color = 29, scale = 1.1, short = false, audience = 'all' },
        { name = "Vespucci PD",    pos = vec3(-1097.2, -841.5,  19.0), sprite = 60, color = 29, scale = 1.1, short = false, audience = 'all' },
    },
    banks = {
        { name = "Fleeca Legion Square",   pos = vec3( 150.27, -1040.20, 29.37), sprite = 108, color = 2,  scale = 0.85, short = true, audience = 'all' },
        { name = "Fleeca Hawick",          pos = vec3( 313.18,  -278.95, 54.17), sprite = 108, color = 2,  scale = 0.85, short = true, audience = 'all' },
        { name = "Fleeca Great Ocean Hwy", pos = vec3(-2962.58,  482.94, 15.70), sprite = 108, color = 2,  scale = 0.85, short = true, audience = 'all' },
        { name = "Fleeca Banham Canyon",   pos = vec3(-1212.05, -331.20, 37.78), sprite = 108, color = 2,  scale = 0.85, short = true, audience = 'all' },
        { name = "Pacific Standard",       pos = vec3( 235.00,   216.50,106.29), sprite = 108, color = 5,  scale = 1.0,  short = false, audience = 'all' },
    },
    stores = {
        { name = "24/7 Strawberry",          pos = vec3(24.91, -1346.86, 29.5),       sprite = 52, color = 2, scale = 0.8, short = true, audience = 'all' },
        { name = "24/7 Chumash",             pos = vec3(-3039.64, 584.78, 7.91),       sprite = 52, color = 2, scale = 0.8, short = true, audience = 'all' },
        { name = "24/7 Barbareno Rd",        pos = vec3(-3242.73, 1000.46, 12.83),    sprite = 52, color = 2, scale = 0.8, short = true, audience = 'all' },
        { name = "24/7 Paleto Bay",          pos = vec3(1728.44, 6415.4, 35.04),      sprite = 52, color = 2, scale = 0.8, short = true, audience = 'all' },
        { name = "24/7 Grapeseed",           pos = vec3(1697.96, 4923.04, 42.06),     sprite = 52, color = 2, scale = 0.8, short = true, audience = 'all' },
        { name = "24/7 Sandy Shores",        pos = vec3(1960.26, 3740.6, 32.34),      sprite = 52, color = 2, scale = 0.8, short = true, audience = 'all' },
        { name = "24/7 Harmony",             pos = vec3(548.67, 2670.94, 42.16),      sprite = 52, color = 2, scale = 0.8, short = true, audience = 'all' },
        { name = "24/7 Senora Fwy",          pos = vec3(2677.97, 3279.95, 55.24),     sprite = 52, color = 2, scale = 0.8, short = true, audience = 'all' },
        { name = "24/7 Tataviam",            pos = vec3(2556.8, 381.27, 108.62),      sprite = 52, color = 2, scale = 0.8, short = true, audience = 'all' },
        { name = "24/7 Downtown Vinewood",   pos = vec3(373.08, 326.75, 103.57),     sprite = 52, color = 2, scale = 0.8, short = true, audience = 'all' },
        { name = "LTD Innocence Blvd",       pos = vec3(-47.42, -1758.67, 29.42),     sprite = 52, color = 2, scale = 0.8, short = true, audience = 'all' },
        { name = "LTD Banning",              pos = vec3(-706.17, -914.64, 19.22),     sprite = 52, color = 2, scale = 0.8, short = true, audience = 'all' },
        { name = "LTD Richman Glen",         pos = vec3(-1819.53, 793.49, 138.09),   sprite = 52, color = 2, scale = 0.8, short = true, audience = 'all' },
        { name = "LTD Mirror Park",          pos = vec3(1164.82, -323.66, 69.21),     sprite = 52, color = 2, scale = 0.8, short = true, audience = 'all' },
        { name = "Rob's Liquor Vespucci",    pos = vec3(-1221.38, -907.89, 12.33),    sprite = 827, color = 47, scale = 0.8, short = true, audience = 'all' },
        { name = "Rob's Liquor Prosperity",  pos = vec3(-1486.82, -377.48, 40.16),    sprite = 827, color = 47, scale = 0.8, short = true, audience = 'all' },
        { name = "Rob's Liquor Chumash",     pos = vec3(-2966.41, 391.62, 15.04),     sprite = 827, color = 47, scale = 0.8, short = true, audience = 'all' },
        { name = "Rob's Liquor Route 68",    pos = vec3(1165.15, 2710.78, 38.16),     sprite = 827, color = 47, scale = 0.8, short = true, audience = 'all' },
        { name = "Rob's Liquor Mirror Park", pos = vec3(1134.3, -983.26, 46.42),      sprite = 827, color = 47, scale = 0.8, short = true, audience = 'all' },
        { name = "Rob's Liquor Sandy Shores",pos = vec3(1744.65, 3611.95, 34.89),     sprite = 827, color = 47, scale = 0.8, short = true, audience = 'all' },
    },
    -- Custom interior buildings — always shown on the map with their own icons.
    landmarks = {
        -- YouTool hardware store MLO (Senora Fwy, Grand Senora Desert). Wrench/tool icon.
        { name = "YouTool",  pos = vec3(2753.0, 3471.0, 55.7),  sprite = 72, color = 5, scale = 1.0, short = false, audience = 'all' },
    },
    ammunation = {
        { name = "Ammu-Nation Cypress Flats", pos = vec3(808.94, -2158.99, 29.62),  heading = 330.26, sprite = 110, color = 1, scale = 0.85, short = true },
        { name = "Ammu-Nation La Mesa",       pos = vec3(-660.98, -933.6, 21.83),   heading = 154.74, sprite = 110, color = 1, scale = 0.85, short = true },
        { name = "Ammu-Nation Sandy Shores",  pos = vec3(1693.16, 3761.94, 34.71),  heading = 189.83, sprite = 110, color = 1, scale = 0.85, short = true },
        { name = "Ammu-Nation Paleto Bay",    pos = vec3(-330.72, 6085.81, 31.45),  heading = 190.52, sprite = 110, color = 1, scale = 0.85, short = true },
        { name = "Ammu-Nation Hawick",        pos = vec3(253.41, -51.67, 69.94),    heading = 28.88,  sprite = 110, color = 1, scale = 0.85, short = true },
        { name = "Ammu-Nation Pillbox Hill",  pos = vec3(23.69, -1105.95, 29.8),     heading = 124.58, sprite = 110, color = 1, scale = 0.85, short = true },
        { name = "Ammu-Nation Tataviam",      pos = vec3(2566.81, 292.54, 108.73),  heading = 320.09, sprite = 110, color = 1, scale = 0.85, short = true },
        { name = "Ammu-Nation Route 68",      pos = vec3(-1118.19, 2700.5, 18.55),  heading = 185.31, sprite = 110, color = 1, scale = 0.85, short = true },
        { name = "Ammu-Nation La Mesa East",  pos = vec3(841.31, -1035.28, 28.19),  heading = 334.27, sprite = 110, color = 1, scale = 0.85, short = true },
        { name = "Ammu-Nation Morningwood",   pos = vec3(-1304.44, -395.68, 36.7),  heading = 41.85,  sprite = 110, color = 1, scale = 0.85, short = true },
    },
    clothing = {
        { name = "Binco Davis",            pos = vec3(   76.94,  -1391.96, 29.4),  sprite = 73, color = 47, scale = 0.8, short = true },
        { name = "Suburban Vinewood",      pos = vec3(  613.10,   2762.50, 42.1),  sprite = 73, color = 47, scale = 0.8, short = true },
        { name = "Ponsonbys Rockford",     pos = vec3( -708.10,   -154.13, 37.4),  sprite = 73, color = 47, scale = 0.8, short = true },
        { name = "Clothing Hawick",        pos = vec3( -167.86,   -298.86, 39.7),  sprite = 73, color = 47, scale = 0.8, short = true },
    },
    barber = {
        { name = "Barber Hawick",          pos = vec3(  -32.86,   -154.78, 57.08), sprite = 71, color = 47, scale = 0.8, short = true },
        { name = "Barber Davis",           pos = vec3(  136.83,   -1708.37,29.29), sprite = 71, color = 47, scale = 0.8, short = true },
        { name = "Barber Vespucci",        pos = vec3(-1282.60,   -1116.80, 6.99), sprite = 71, color = 47, scale = 0.8, short = true },
        { name = "Barber Rockford",        pos = vec3( -814.22,    -183.70,37.57), sprite = 71, color = 47, scale = 0.8, short = true },
        { name = "Barber Sandy Shores",    pos = vec3( 1931.26,    3729.67,32.84), sprite = 71, color = 47, scale = 0.8, short = true },
        { name = "Barber Paleto Bay",      pos = vec3( -278.10,    6228.45,31.70), sprite = 71, color = 47, scale = 0.8, short = true },
    },


    food = {},
    jewelry = {
        { name = "Vangelico Jewelry", pos = vec3(-622.25, -230.92, 38.06), ped = vec4(-622.25, -230.92, 38.06, 125.0), sprite = 617, color = 5, scale = 0.85, short = true, audience = 'all' },
    },
    services = {
        { name = "LSC Burton",             pos = vec3( -337.0,   -136.0,  39.0),  sprite = 72, color = 17, scale = 0.8, short = true },
        { name = "LSC La Mesa",            pos = vec3(  731.0,  -1088.0,  22.0),  sprite = 72, color = 17, scale = 0.8, short = true },
        { name = "LSC Airport",            pos = vec3(-1155.0,  -2007.0,  13.0),  sprite = 72, color = 17, scale = 0.8, short = true },
        { name = "LSC Harmony",            pos = vec3( 1175.0,   2640.0,  37.0),  sprite = 72, color = 17, scale = 0.8, short = true },
        { name = "LSC Paleto",             pos = vec3(  110.0,   6626.0,  31.0),  sprite = 72, color = 17, scale = 0.8, short = true },
        { name = "LSC Popular Street",     pos = vec3( -211.0,  -1324.0,  30.0),  sprite = 72, color = 17, scale = 0.8, short = true },
    },
    dealership = {
        { name = "Premium Deluxe Motorsport", pos = vec3(-56.71, -1098.98, 26.42), ped = vec4(-56.71, -1101.5, 26.42, 0.0), heading = 0.0, sprite = 326, color = 5, scale = 0.9, short = true },
    },
    jails = {
        { name = "Bolingbroke Penitentiary", pos = vec3( 1690.0,  2565.0,  45.56), sprite = 188, color = 1, scale = 0.95, short = false, audience = 'all' },
        { name = "Mission Row Holding",      pos = vec3(459.48,  -997.86, 24.91),  sprite = 188, color = 1, scale = 0.7,  short = true,  audience = 'all' },
        { name = "Vespucci Holding",         pos = vec3(-1087.0, -849.0,  19.0),   sprite = 188, color = 1, scale = 0.7,  short = true,  audience = 'all' },
    },
    -- Arrest-delivery markers — one per station (visible to cops only)
    arrestEntrances = {
        { name = 'Mission Row Arrest Point', pos = vec3(463.5, -1014.4, 27.0),  sprite = 526, color = 1,  scale = 0.85 },
        { name = 'Vespucci Arrest Point',    pos = vec3(-1065.7203, -813.8340,  7.9307), sprite = 526, color = 1, scale = 0.85 },
    },
    -- Kept for any external code still reading the old key
    arrestEntrance = { pos = vec3(463.5, -1014.4, 27.0), sprite = 526, color = 38, scale = 0.85 },
}

-- General Clothing Store. Players pick a Top and Pants independently from the garments
-- streamed by the 'clothing' resource (which replaces these specific base-game freemode
-- drawables/textures). Only the replaced drawable+texture combos are listed.
Config.ClothingShop = {
    price = 250,  -- legacy flat price (kept as a fallback)
    -- Per-item pricing: every category the player changes adds its cost to the total.
    prices = {
        top     = 150,
        pants   = 150,
        shoes   = 100,
        mask    = 100,
        hat     = 75,
        glasses = 75,
        watch   = 100,
    },
    garments = {
        male = {
            tops = {
                { label = 'Custom Top 1 (A)', top = 0,  topTxt = 0 },
                { label = 'Custom Top 1 (B)', top = 0,  topTxt = 1 },
                { label = 'Custom Top 1 (C)', top = 0,  topTxt = 2 },
                { label = 'Custom Top 2',     top = 12, topTxt = 1 },
                { label = 'Custom Top 3',     top = 13, topTxt = 1 },
            },
            pants = {
                { label = 'Custom Pants 1 (A)', pants = 0, pantsTxt = 0 },
                { label = 'Custom Pants 1 (B)', pants = 0, pantsTxt = 1 },
                { label = 'Custom Pants 1 (C)', pants = 0, pantsTxt = 2 },
                { label = 'Custom Pants 2',     pants = 5, pantsTxt = 1 },
                { label = 'Custom Pants 3',     pants = 6, pantsTxt = 1 },
            },
            -- Hats use ped prop slot 0, glasses use prop slot 1. drawable = -1 means "none".
            hats = {
                { label = 'No Hat',          drawable = -1, texture = 0 },
                { label = 'Baseball Cap',    drawable = 1,  texture = 0 },
                { label = 'Beanie',          drawable = 4,  texture = 0 },
                { label = 'Fedora',          drawable = 5,  texture = 0 },
                { label = 'Hard Hat',        drawable = 8,  texture = 0 },
                { label = 'Bucket Hat',      drawable = 11, texture = 0 },
            },
            glasses = {
                { label = 'No Glasses',      drawable = -1, texture = 0 },
                { label = 'Reading Glasses', drawable = 0,  texture = 0 },
                { label = 'Black Shades',    drawable = 1,  texture = 0 },
                { label = 'Aviators',        drawable = 5,  texture = 0 },
                { label = 'Round Frames',    drawable = 7,  texture = 0 },
                { label = 'Sport Wrap',      drawable = 10, texture = 0 },
            },
            -- Watches use ped prop slot 6. drawable = -1 means "none".
            watches = {
                { label = 'No Watch',        drawable = -1, texture = 0 },
                { label = 'Classic Silver',  drawable = 0,  texture = 0 },
                { label = 'Classic Gold',    drawable = 1,  texture = 0 },
                { label = 'Diver Watch',     drawable = 3,  texture = 0 },
                { label = 'Sport Digital',   drawable = 5,  texture = 0 },
                { label = 'Luxury Gold',     drawable = 7,  texture = 0 },
            },
        },
        female = {
            tops = {
                { label = 'Custom Top 1', top = 13, topTxt = 1 },
                { label = 'Custom Top 2', top = 14, topTxt = 1 },
            },
            pants = {
                { label = 'Custom Pants 1', pants = 6, pantsTxt = 1 },
                { label = 'Custom Pants 2', pants = 7, pantsTxt = 1 },
            },
            hats = {
                { label = 'No Hat',          drawable = -1, texture = 0 },
                { label = 'Baseball Cap',    drawable = 1,  texture = 0 },
                { label = 'Beanie',          drawable = 4,  texture = 0 },
                { label = 'Fedora',          drawable = 5,  texture = 0 },
                { label = 'Sun Hat',         drawable = 8,  texture = 0 },
                { label = 'Bucket Hat',      drawable = 11, texture = 0 },
            },
            glasses = {
                { label = 'No Glasses',      drawable = -1, texture = 0 },
                { label = 'Reading Glasses', drawable = 0,  texture = 0 },
                { label = 'Black Shades',    drawable = 1,  texture = 0 },
                { label = 'Aviators',        drawable = 5,  texture = 0 },
                { label = 'Round Frames',    drawable = 7,  texture = 0 },
                { label = 'Sport Wrap',      drawable = 10, texture = 0 },
            },
            watches = {
                { label = 'No Watch',        drawable = -1, texture = 0 },
                { label = 'Classic Silver',  drawable = 0,  texture = 0 },
                { label = 'Classic Gold',    drawable = 1,  texture = 0 },
                { label = 'Diamond Watch',   drawable = 3,  texture = 0 },
                { label = 'Sport Digital',   drawable = 5,  texture = 0 },
                { label = 'Luxury Gold',     drawable = 7,  texture = 0 },
            },
        },
    },
}

Config.BarberShop = {
    price = 100,  -- legacy flat price (kept as a fallback)
    -- Per-item pricing: each style the player actually changes adds its cost.
    prices = {
        hair       = 100,
        hairColor  = 50,
        beard      = 75,
        beardColor = 50,
    },
    locations = Config.Blips.barber,
}

-- Free Transport / Prison Bike NPC removed (no longer needed). All spawn and
-- interaction code guards on `Config.PrisonBikeNpc`, so leaving it nil disables it.
Config.PrisonBikeNpc = nil

-- Prison canteen NPC: a single "Prison Food" option that is consumed instantly on
-- purchase (no inventory item, no animation) and restores HP. price = 0 -> free.
Config.PrisonFoodNpc = {
    model = 's_m_m_prisguard_01',
    pos = vec4(1713.6276, 2576.5908, 45.587, 94.9970),
    label = 'Prison Canteen',
    price = 0,
    heal = 20,
    -- Eating animation played when the prison food is taken (heals afterwards).
    consume = {
        anim = { dict = "mp_player_inteat@burger", name = "mp_player_int_eat_burger", time = 3000 },
        prop = { model = "prop_cs_burger_01", bone = 18905, pos = vec3(0.13, 0.05, 0.02), rot = vec3(-50.0, 16.0, 60.0) },
    },
}

-- ─── Tattoo parlors ─────────────────────────────────────────────────────────────
-- The six vanilla GTA V tattoo shops. Walk up, press E, browse (live preview), pay.
Config.TattooParlors = {
    vec4(  322.06,  181.26, 103.59, 162.0),   -- Downtown Los Santos (Hawick)
    vec4(-1153.00, -1425.00,   4.95, 120.0),   -- Vespucci
    vec4( 1322.63, -1651.66,  52.27, 200.0),   -- El Burro Heights
    vec4(-3169.50,  1075.50,  20.83, 280.0),   -- Great Ocean Highway (Chumash)
    vec4( 1863.60,  3747.70,  33.03, 210.0),   -- Sandy Shores (Senora Desert)
    vec4( -289.00,  6201.50,  31.49,  40.0),   -- Paleto Bay
}

-- Tattoo catalog (shared by every parlor). Grouped by body ZONE, with several DESIGNS
-- per zone. Each entry has a male + female overlay (the right one is chosen from the
-- player's model) and a `cover` slot — the clothing the preview temporarily removes so
-- you can see the tattoo on bare skin ('top' = torso/arms, 'pants' = legs, nil = hand).
-- Base-game "Beach Bum" (mpbeach_overlays) freemode tattoos.
-- Tattoo catalog. Overlay names are the CONFIRMED GTA V freemode decoration names
-- (the arms are L/RArm, legs are L/Rleg — the old LeftArm/Leg names were invalid, which
-- is why only chest/back used to render). `cover` = which clothing slot to strip while
-- previewing so the design is visible ('top' bares the torso + sleeves, 'pants' the legs).
Config.Tattoos = {
    -- Neck
    { zone = 'Neck',      cover = 'top',   label = 'Neck — Little Fish',     price = 400, collection = 'mpbeach_overlays',    male = 'MP_Bea_M_Neck_000',  female = 'MP_Bea_F_Neck_000' },
    { zone = 'Neck',      cover = 'top',   label = "Neck — Surf's Up",       price = 450, collection = 'mpbeach_overlays',    male = 'MP_Bea_M_Neck_001',  female = 'MP_Bea_F_Neck_001' },
    -- Chest
    { zone = 'Chest',     cover = 'top',   label = 'Chest — Tribal Hammerhead', price = 600, collection = 'mpbeach_overlays', male = 'MP_Bea_M_Chest_000', female = 'MP_Bea_F_Chest_000' },
    { zone = 'Chest',     cover = 'top',   label = 'Chest — Tribal Shark',   price = 650, collection = 'mpbeach_overlays',    male = 'MP_Bea_M_Chest_001', female = 'MP_Bea_F_Chest_001' },
    { zone = 'Chest',     cover = 'top',   label = 'Chest — Demon Rider',    price = 700, collection = 'mpbiker_overlays',    male = 'MP_MP_Biker_Tat_000_M', female = 'MP_MP_Biker_Tat_000_F' },
    -- Back
    { zone = 'Back',      cover = 'top',   label = 'Back — Ship Arms',       price = 900, collection = 'mpbeach_overlays',    male = 'MP_Bea_M_Back_000',  female = 'MP_Bea_F_Back_000' },
    { zone = 'Back',      cover = 'top',   label = "Back — Makin' Paper",    price = 950, collection = 'mpbusiness_overlays', male = 'MP_Buis_M_Back_000', female = 'MP_Buis_F_Back_000' },
    -- Left Arm
    { zone = 'Left Arm',  cover = 'top',   label = 'Left Arm — Tiki Tower',  price = 700, collection = 'mpbeach_overlays',    male = 'MP_Bea_M_LArm_000',  female = 'MP_Bea_F_LArm_000' },
    { zone = 'Left Arm',  cover = 'top',   label = 'Left Arm — Mermaid',     price = 750, collection = 'mpbeach_overlays',    male = 'MP_Bea_M_LArm_001',  female = 'MP_Bea_F_LArm_001' },
    -- Right Arm
    { zone = 'Right Arm', cover = 'top',   label = 'Right Arm — Tribal Sun', price = 700, collection = 'mpbeach_overlays',    male = 'MP_Bea_M_RArm_000',  female = 'MP_Bea_F_RArm_000' },
    { zone = 'Right Arm', cover = 'top',   label = 'Right Arm — Vespucci',   price = 750, collection = 'mpbeach_overlays',    male = 'MP_Bea_M_RArm_001',  female = 'MP_Bea_F_RArm_001' },
    -- Legs
    { zone = 'Legs',      cover = 'pants', label = 'Left Leg — Tribal Star', price = 500, collection = 'mpbeach_overlays',    male = 'MP_Bea_M_Lleg_000',  female = 'MP_Bea_F_Lleg_000' },
    { zone = 'Legs',      cover = 'pants', label = 'Right Leg — Tiki',       price = 500, collection = 'mpbeach_overlays',    male = 'MP_Bea_M_Rleg_000',  female = 'MP_Bea_F_Rleg_000' },
}

Config.Keybinds = {
    cuff       = { key = 'e', device = 'keyboard', description = 'CnR: Cuff a nearby wanted robber' },
    interact   = { key = 'e',  description = 'CnR: Interact (robbery, terminal)' },
    help       = { key = 'h',  description = 'CnR: Open the server guide' },
    inventory  = { key = 'i',  description = 'CnR: Open inventory & player status' },
    teamMenu   = { key = 'm',  description = 'CnR: Open police clothing (cops only)' },
    doorTool   = { key = 'z',  description = 'CnR: Police doors open automatically nearby' },
    playerList = { key = 'f7', description = 'CnR: View online players' },
    passenger  = { key = 'g',  description = 'CnR: Enter nearest vehicle as passenger' },
}

Config.EnableM = false

Config.PoliceDoorTool = {
    range = 2.0,
    doubleDoorRadius = 3.0,
    zones = {
        { name = 'Mission Row PD', pos = vec3(452.0, -990.0, 27.0), radius = 65.0 },
        { name = 'Vespucci PD',    pos = vec3(-1097.2, -841.5, 19.0), radius = 55.0 },
        { name = 'Bolingbroke',    pos = vec3(1690.0, 2565.0, 45.56), radius = 260.0 },
    },
    markers = {
        { name = 'Mission Row Front Glass Left',  pos = vec3(434.7, -981.9, 31.1) },
        { name = 'Mission Row Front Glass Mid',   pos = vec3(440.7, -981.9, 31.1) },
        { name = 'Mission Row Front Glass Right', pos = vec3(446.2, -981.9, 31.1) },
        { name = 'Vespucci Front Door',    pos = vec3(-1096.5, -836.8, 19.7) },
        { name = 'Vespucci Holding Door',  pos = vec3(-1091.8, -841.8, 19.7) },
        { name = 'Bolingbroke Main Gate',  pos = vec3(1845.9, 2604.8, 46.2) },
        { name = 'Bolingbroke Sally Port', pos = vec3(1819.4, 2604.8, 46.2) },
        { name = 'Bolingbroke Yard Gate',  pos = vec3(1791.5, 2593.2, 46.2) },
        { name = 'Bolingbroke Cell Block', pos = vec3(1690.0, 2565.0, 46.2) },
        { name = 'Bolingbroke Laundry',    pos = vec3(1779.0, 2596.0, 46.3) },
    },
    permanentLocked = {
        { name = 'Mission Row Holding Cell 2', model = 'v_ilev_ph_cellgate', pos = vec3(462.3, -993.6, 24.9), radius = 1.5 },
        { name = 'Mission Row Holding Cell 3', model = 'v_ilev_ph_cellgate', pos = vec3(462.3, -998.1, 24.9), radius = 1.5 },
        { name = 'Mission Row Holding Cell 4', model = 'v_ilev_ph_cellgate', pos = vec3(462.7, -1001.9, 24.9), radius = 1.5 },
    },
    markerDistance = 28.0,
}

Config.Inventory = {
    -- action = verb in the inventory (Eat/Drink/Smoke). anim+prop drive the consume
    -- animation (prop is held in the right hand); scenario replaces anim/prop when set
    -- (used for smoking). time = how long the animation runs (ms). Heal applies after.
    items = {
        burger    = { label = "Burger Shot Meal", heal = 25, max = 5, action = "Eat",
                      anim = { dict = "mp_player_inteat@burger", name = "mp_player_int_eat_burger", time = 3000 },
                      prop = { model = "prop_cs_burger_01",  bone = 18905, pos = vec3(0.13,0.05,0.02), rot = vec3(-50.0,16.0,60.0) } },
        soda      = { label = "eCola", heal = 10, max = 8, action = "Drink",
                      anim = { dict = "mp_player_intdrink", name = "loop_bottle", time = 3000 },
                      prop = { model = "prop_ecola_can",     bone = 18905, pos = vec3(0.10,0.01,0.04), rot = vec3(230.0,0.0,0.0) } },
        sandwich  = { label = "Up-n-Atom", heal = 18, max = 5, action = "Eat",
                      anim = { dict = "mp_player_inteat@burger", name = "mp_player_int_eat_burger", time = 3000 },
                      prop = { model = "prop_sandwich_01",   bone = 18905, pos = vec3(0.13,0.05,0.02), rot = vec3(-50.0,16.0,60.0) } },
        water     = { label = "Water Bottle", heal = 5, max = 8, action = "Drink",
                      anim = { dict = "mp_player_intdrink", name = "loop_bottle", time = 3000 },
                      prop = { model = "prop_ld_flow_bottle", bone = 18905, pos = vec3(0.12,0.0,0.05), rot = vec3(230.0,0.0,0.0) } },
        -- 24/7 store snacks & drinks
        psqs      = { label = "P's & Q's", heal = 20, max = 5, action = "Eat",
                      anim = { dict = "mp_player_inteat@burger", name = "mp_player_int_eat_burger", time = 3000 },
                      prop = { model = "prop_candy_pqs",     bone = 18905, pos = vec3(0.13,0.05,0.02), rot = vec3(-50.0,16.0,60.0) } },
        egochaser = { label = "EgoChaser Bar", heal = 18, max = 5, action = "Eat",
                      anim = { dict = "mp_player_inteat@burger", name = "mp_player_int_eat_burger", time = 3000 },
                      prop = { model = "prop_choc_ego",      bone = 18905, pos = vec3(0.13,0.05,0.02), rot = vec3(-50.0,16.0,60.0) } },
        meteorite = { label = "Meteorite Bar", heal = 18, max = 5, action = "Eat",
                      anim = { dict = "mp_player_inteat@burger", name = "mp_player_int_eat_burger", time = 3000 },
                      prop = { model = "prop_choc_meto",     bone = 18905, pos = vec3(0.13,0.05,0.02), rot = vec3(-50.0,16.0,60.0) } },
        sprunk    = { label = "Sprunk", heal = 12, max = 8, action = "Drink",
                      anim = { dict = "mp_player_intdrink", name = "loop_bottle", time = 3000 },
                      prop = { models = { "ng_proc_sprunkcn_01a", "prop_sprunk_can", "prop_ecola_can" }, bone = 18905, pos = vec3(0.10,0.01,0.04), rot = vec3(230.0,0.0,0.0) } },
        smokes    = { label = "Cigarettes", heal = 5, max = 10, action = "Smoke",
                      scenario = "WORLD_HUMAN_SMOKING", time = 7000 },
        -- Liquor store (bottles)
        beer      = { label = "Beer Bottle", heal = 10, max = 6, action = "Drink",
                      anim = { dict = "mp_player_intdrink", name = "loop_bottle", time = 3500 },
                      prop = { model = "prop_amb_beer_bottle", bone = 18905, pos = vec3(0.12,0.0,0.05), rot = vec3(230.0,0.0,0.0) } },
        whiskey   = { label = "Whiskey Bottle", heal = 18, max = 4, action = "Drink",
                      anim = { dict = "mp_player_intdrink", name = "loop_bottle", time = 3500 },
                      prop = { models = { "prop_cs_whiskey_bottle", "prop_amb_whiskey_bottle", "prop_drink_whisky" }, bone = 18905, pos = vec3(0.12,0.0,0.05), rot = vec3(230.0,0.0,0.0) } },
        wine      = { label = "Wine Bottle", heal = 14, max = 4, action = "Drink",
                      anim = { dict = "mp_player_intdrink", name = "loop_bottle", time = 3500 },
                      prop = { models = { "prop_wine_bot_01", "prop_cs_whiskey_bottle", "prop_drink_redwine" }, bone = 18905, pos = vec3(0.12,0.0,0.05), rot = vec3(230.0,0.0,0.0) } },
    },
    -- 24/7 / convenience store menu
    foodShopMenu   = { 'psqs', 'egochaser', 'meteorite', 'soda', 'sprunk', 'smokes' },
    -- Liquor store menu
    liquorShopMenu = { 'beer', 'whiskey', 'wine' },
    foodShopPrices = {
        burger = 75, soda = 25, sandwich = 60, water = 15,
        psqs = 40, egochaser = 35, meteorite = 35, sprunk = 25, smokes = 50,
        beer = 60, whiskey = 120, wine = 90,
    },
}


Config.AmmuShop = {
    {
        weapon  = "WEAPON_PISTOL",         label = "Pistol",          price = 500,    ammo = 60,
        category = "Sidearm",
    },
    {
        weapon  = "WEAPON_COMBATPISTOL",   label = "Combat Pistol",   price = 950,    ammo = 60,
        category = "Sidearm",
    },
    {
        weapon  = "WEAPON_PISTOL50",       label = "Pistol .50",      price = 1800,   ammo = 36,
        category = "Sidearm",
    },
    {
        weapon  = "WEAPON_MICROSMG",       label = "Micro SMG",       price = 2400,   ammo = 120,
        category = "SMG",
    },
    {
        weapon  = "WEAPON_SMG",            label = "SMG",             price = 3200,   ammo = 150,
        category = "SMG",
    },
    {
        weapon  = "WEAPON_PUMPSHOTGUN",    label = "Pump Shotgun",    price = 3800,   ammo = 32,
        category = "Shotgun",
    },
    {
        weapon  = "WEAPON_SAWNOFFSHOTGUN", label = "Sawn-off",        price = 2700,   ammo = 24,
        category = "Shotgun",
    },
    {
        weapon  = "WEAPON_ASSAULTRIFLE",   label = "Assault Rifle",   price = 7000,   ammo = 180,
        category = "Rifle",
    },
    {
        weapon  = "WEAPON_CARBINERIFLE",   label = "Carbine Rifle",   price = 8500,   ammo = 180,
        category = "Rifle",
    },
    {
        weapon  = "WEAPON_SNIPERRIFLE",    label = "Sniper",          price = 12000,  ammo = 30,
        category = "Rifle",
    },
    {
        weapon  = "AMMO_PISTOL",           label = "Pistol Ammo +60", price = 120,    ammo = 60,
        category = "Ammo", ammoFor = "WEAPON_PISTOL",
    },
    {
        weapon  = "AMMO_SMG",              label = "SMG Ammo +90",    price = 220,    ammo = 90,
        category = "Ammo", ammoFor = "WEAPON_SMG",
    },
    {
        weapon  = "AMMO_RIFLE",            label = "Rifle Ammo +120", price = 380,    ammo = 120,
        category = "Ammo", ammoFor = "WEAPON_ASSAULTRIFLE",
    },
    {
        weapon  = "AMMO_SHOTGUN",          label = "Shotgun Ammo +32",price = 250,    ammo = 32,
        category = "Ammo", ammoFor = "WEAPON_PUMPSHOTGUN",
    },
    -- Body armor tiers — armor caps at 100 in-game, so heavier tiers cost more for the
    -- same top-end protection. armorValue is what the vest sets the player's armor to.
    {
        weapon  = "ARMOR_SUPERLIGHT",      label = "Super Light Armor", price = 500,   ammo = 0,
        category = "Gear", armorValue = 20,
    },
    {
        weapon  = "ARMOR_LIGHT",           label = "Light Armor",       price = 1000,  ammo = 0,
        category = "Gear", armorValue = 40,
    },
    {
        weapon  = "ARMOR_STANDARD",        label = "Standard Armor",    price = 1800,  ammo = 0,
        category = "Gear", armorValue = 60,
    },
    {
        weapon  = "ARMOR_HEAVY",           label = "Heavy Armor",       price = 3000,  ammo = 0,
        category = "Gear", armorValue = 80,
    },
    {
        weapon  = "ARMOR_SUPERHEAVY",      label = "Super Heavy Armor", price = 5000,  ammo = 0,
        category = "Gear", armorValue = 100,
    },
    {
        weapon  = "MEDKIT",                label = "Medkit (Full HP)",price = 2000,   ammo = 1,
        category = "Gear",
    },
}


Config.Dealership = {
    previewDistance = 6.0,
    previewBay = vec4(-45.0, -1097.0, 26.42, 70.0),
    spawn   = vec4(-31.05, -1090.45, 26.42, 340.0),
    -- Price/tier used for cars auto-added from resources/[vehicles]/[dealership].
    -- defaultAddonPrice = 0 makes every dealership car free. Override a specific one by
    -- adding it to the `cars` list below with its own price.
    defaultAddonPrice = 0,
    defaultAddonTier  = 'Add-on',
    -- Add-on vehicles from resources/[vehicles]/[dealership] are auto-registered at runtime
    -- (free, per defaultAddonPrice). Vanilla / manually-priced cars are listed here.
    cars = {
        { model = "adder",    label = "Truffade Adder",      price = 50000, tier = "Super" },
        { model = "zentorno", label = "Pegassi Zentorno",    price = 45000, tier = "Super" },
        { model = "entityxf", label = "Overflod Entity XF",  price = 40000, tier = "Super" },
    },
}


Config.VehicleYards = {
    missionRow = Config.PoliceStations.missionRow.vehicleYard,
    vespucci   = Config.PoliceStations.vespucci.vehicleYard,
}

Config.ModShop = {
    repairPrice  = 250,
    modPrice     = 500,
    turboPrice   = 1500,
    resprayPrice = 750,
    locations = {
        { name = "Los Santos Customs Burton",       pos = vec3(-337.0,  -136.0,  39.0), radius = 30.0 },
        { name = "Los Santos Customs La Mesa",      pos = vec3( 731.0, -1088.0,  22.0), radius = 30.0 },
        { name = "Los Santos Customs Airport",     pos = vec3(-1155.0, -2007.0,  13.0), radius = 30.0 },
        { name = "Los Santos Customs Harmony",     pos = vec3( 1175.0,  2640.0,  37.0), radius = 30.0 },
        { name = "Los Santos Customs Paleto",      pos = vec3(  110.0,  6626.0,  31.0), radius = 30.0 },
        { name = "Los Santos Customs Popular St",  pos = vec3( -211.0, -1324.0,  30.0), radius = 30.0 },
    },
}

Config.Save = {
    intervalSec = 60,
}

Config.Chat = {
    theme = 'cnr',
    nameColors = {
        cop    = '#5599ff',   -- blue
        robber = '#ff4444',   -- red
        civ    = '#ffffff',   -- white
        admin  = '#aa66cc',   -- purple (no animation, just solid color now)
        system = '#48ff00',
    },
    notices = {
        cartel = { tag = 'CARTEL', tagColor = '#ff4444', label = 'NOTE!',   labelColor = '#ffcc33' },
        police = { tag = 'POLICE', tagColor = '#33b5e5', label = 'ALERT!',  labelColor = '#ffcc33' },
        admin  = { tag = 'ADMIN',  tagColor = '#aa66cc', label = 'NOTICE!', labelColor = '#ffcc33' },
        system = { tag = 'SYSTEM', tagColor = '#cccccc', label = 'INFO',    labelColor = '#ffcc33' },
    },
}
