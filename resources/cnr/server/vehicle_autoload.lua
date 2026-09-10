CnR = CnR or {}

-- Single loader + registrar for every add-on vehicle under resources/[vehicles].
--   * Starts ALL resources in [vehicles] (this replaces the old standalone
--     vehicle_loader resource — it is now merged in here).
--   * Vehicles in [vehicles]/[police]     -> cop Vehicle Yard (Level 1)
--   * Vehicles in [vehicles]/[dealership] -> Premium Deluxe dealership menu
-- Each vehicle's DISPLAY NAME in the menus is its resource FOLDER NAME (rename the
-- folder to rename the car). Model names are read from the resource's vehicles.meta.

local POLICE_TAG = '[police]'
local DEALER_TAG = '[dealership]'
local VEH_TAG    = '[vehicles]'

-- model -> folder-name label, consumed by buildVehicleList (server/ranks.lua) for the yard.
CnR.AutoVehicleLabels = CnR.AutoVehicleLabels or {}

local function readFirst(res, paths)
    for _, p in ipairs(paths) do
        local content = LoadResourceFile(res, p)
        if content and #content > 0 then return content end
    end
    return nil
end

-- Likely vehicles.meta paths: the manifest's VEHICLE_METADATA_FILE entries plus common
-- fallbacks (LoadResourceFile can't expand globs, so glob paths are simplified).
local function metaCandidates(res)
    local cands, seen = {}, {}
    local function add(p)
        if p and p ~= '' and not seen[p] then seen[p] = true; cands[#cands + 1] = p end
    end
    local manifest = LoadResourceFile(res, 'fxmanifest.lua') or LoadResourceFile(res, '__resource.lua')
    if manifest then
        for path in manifest:gmatch("VEHICLE_METADATA_FILE['\"]%s*['\"]([^'\"]+)['\"]") do
            if path:find('%*') then
                add((path:gsub('%*%*/', ''):gsub('/%*%*', '')))
                add((path:gsub('%*%.meta', 'vehicles.meta')))
            else
                add(path)
            end
        end
    end
    add('vehicles.meta')
    add('data/vehicles.meta')
    add('data/vehicle/vehicles.meta')
    add('data/vehicles/vehicles.meta')
    add('stream/vehicles.meta')
    return cands
end

-- FiveM resource names come back URL-encoded (spaces -> %20). Decode for display.
local function urldecode(s)
    return (tostring(s):gsub('%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end))
end

local function discoverModels(res)
    local out, seen = {}, {}
    local content = readFirst(res, metaCandidates(res))
    if not content then return out end
    for m in content:gmatch("<[Mm]odelName>%s*([%w_]+)%s*</[Mm]odelName>") do
        local model = m:lower()
        if not seen[model] then seen[model] = true; out[#out + 1] = model end
    end
    return out
end

CreateThread(function()
    if not (Config and Config.Ranks and Config.Ranks[1] and Config.Dealership) then
        print('[cnr] vehicle autoload skipped: config not ready')
        return
    end

    local excluded = {}
    for _, m in ipairs((Config.VehicleAutoload and Config.VehicleAutoload.exclude) or {}) do
        excluded[tostring(m):lower()] = true
    end

    local rank1 = Config.Ranks[1]
    rank1.vehicles = rank1.vehicles or {}
    local inYard = {}
    for _, v in ipairs(rank1.vehicles) do inYard[v] = true end
    local inDealer = {}
    for _, c in ipairs(Config.Dealership.cars) do inDealer[c.model] = true end

    local tier  = Config.Dealership.defaultAddonTier or 'Imported'

    -- Stable, varied price per dealership car: $5,000–$50,000 in $1,000 steps, derived
    -- from the model name so each car keeps the same price across restarts. (Robbers earn
    -- $1,000 per store and $5,000 per bank, so a car is several heists of saving.)
    local function priceForModel(model)
        local h = GetHashKey(model) % 0x7FFFFFFF
        return 5000 + (h % 46) * 1000
    end

    local addedPolice, addedDealer, started = {}, {}, 0

    for i = 0, GetNumResources() - 1 do
        local res = GetResourceByFindIndex(i)
        if res and res ~= GetCurrentResourceName() then
            local path = GetResourcePath(res) or ''
            if path:find(VEH_TAG, 1, true) then
                -- Start every vehicle resource (merged-in vehicle_loader behaviour).
                local state = GetResourceState(res)
                if state ~= 'started' and state ~= 'starting' then
                    if StartResource(res) then started = started + 1 end
                end

                local isPolice = path:find(POLICE_TAG, 1, true) ~= nil
                local isDealer = path:find(DEALER_TAG, 1, true) ~= nil
                if isPolice or isDealer then
                    -- Visible (non-excluded) models in this resource.
                    local models = {}
                    for _, m in ipairs(discoverModels(res)) do
                        if not excluded[m] then models[#models + 1] = m end
                    end
                    local folderName = urldecode(res)
                    for _, model in ipairs(models) do
                        -- Display name = the resource's FOLDER NAME. If a pack ships more
                        -- than one car, append the model so they stay distinguishable.
                        local label = (#models > 1) and (folderName .. ' (' .. model .. ')') or folderName
                        if isPolice and not inYard[model] then
                            inYard[model] = true
                            CnR.AutoVehicleLabels[model] = label
                            rank1.vehicles[#rank1.vehicles + 1] = model
                            addedPolice[#addedPolice + 1] = label
                        elseif isDealer and not inDealer[model] then
                            inDealer[model] = true
                            CnR.AutoVehicleLabels[model] = label
                            Config.Dealership.cars[#Config.Dealership.cars + 1] = {
                                model = model, label = label, price = priceForModel(model), tier = tier,
                            }
                            addedDealer[#addedDealer + 1] = label
                        end
                    end
                end
            end
        end
    end

    print(('[cnr] vehicle autoload: started %d resource(s); Yard: %s; Dealership: %s'):format(
        started,
        #addedPolice > 0 and table.concat(addedPolice, ', ') or 'none',
        #addedDealer > 0 and table.concat(addedDealer, ', ') or 'none'))
end)
