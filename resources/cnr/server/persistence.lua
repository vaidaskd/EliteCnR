CnR = CnR or {}
CnR.Persistence = CnR.Persistence or {}

local RESOURCE  = 'cnr'
local DATA_FILE = 'data/players.json'

local store    = {}
local dirtyIds = {}      -- set of identifiers whose in-memory profile differs from the DB
local loaded   = false

local json = {}

do
    local encode

    local escape_char_map = {
        [ "\\" ] = "\\",


        [ "\"" ] = "\"",
        [ "\b" ] = "b",


        [ "\f" ] = "f",


        [ "\n" ] = "n",


        [ "\r" ] = "r",


        [ "\t" ] = "t",


    }

    local escape_char_map_inv = { [ "/" ] = "/" }
    for k, v in pairs(escape_char_map) do escape_char_map_inv[v] = k end

    local function escape_char(c)
        return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))


    end

    local function encode_nil(_) return "null" end

    local function encode_table(val, stack)
        local res = {}
        stack = stack or {}
        if stack[val] then error("circular reference") end
        stack[val] = true

        if rawget(val, 1) ~= nil or next(val) == nil then
            local n = 0
            for k in pairs(val) do
                if type(k) ~= "number" then error("invalid table: mixed or invalid key types") end
                n = n + 1
            end
            if n ~= #val then error("invalid table: sparse array") end
            for _, v in ipairs(val) do table.insert(res, encode(v, stack)) end
            stack[val] = nil
            return "[" .. table.concat(res, ",") .. "]"
        else
            for k, v in pairs(val) do
                if type(k) ~= "string" then error("invalid table: mixed or invalid key types") end
                table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
            end
            stack[val] = nil
            return "{" .. table.concat(res, ",") .. "}"
        end
    end

    local function encode_string(val)
        return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
    end

    local function encode_number(val)
        if val ~= val or val <= -math.huge or val >= math.huge then
            error("unexpected number value '" .. tostring(val) .. "'")
        end
        return string.format("%.14g", val)
    end

    local type_func_map = {
        [ "nil"     ] = encode_nil,
        [ "table"   ] = encode_table,
        [ "string"  ] = encode_string,
        [ "number"  ] = encode_number,
        [ "boolean" ] = tostring,
    }

    encode = function(val, stack)
        local t = type(val)
        local f = type_func_map[t]
        if f then return f(val, stack) end
        error("unexpected type '" .. t .. "'")
    end

    function json.encode(val) return encode(val) end

    local parse

    local function create_set(...)
        local res = {}
        for i = 1, select("#", ...) do res[ select(i, ...) ] = true end
        return res
    end

    local space_chars   = create_set(" ", "\t", "\r", "\n")


    local delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",")


    local escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
    local literals      = create_set("true", "false", "null")
    local literal_map   = { [ "true" ] = true, [ "false" ] = false, [ "null" ] = nil }

    local function next_char(str, idx, set, negate)
        for i = idx, #str do
            if set[str:sub(i, i)] ~= negate then return i end
        end
        return #str + 1
    end

    local function decode_error(str, idx, msg)
        local line_count, col_count = 1, 1
        for i = 1, idx - 1 do
            col_count = col_count + 1
            if str:sub(i, i) == "\n" then line_count = line_count + 1; col_count = 1 end


        end
        error(string.format("%s at line %d col %d", msg, line_count, col_count))
    end

    local function codepoint_to_utf8(n)
        local f = math.floor
        if n <= 0x7f then return string.char(n)
        elseif n <= 0x7ff then return string.char(f(n / 64) + 192, n % 64 + 128)
        elseif n <= 0xffff then return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
        elseif n <= 0x10ffff then return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128, f(n % 4096 / 64) + 128, n % 64 + 128) end
        error(string.format("invalid unicode codepoint '%x'", n))
    end

    local function parse_unicode_escape(s)
        local n1 = tonumber(s:sub(1, 4), 16)
        local n2 = tonumber(s:sub(7, 10), 16)
        if n2 then
            return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
        end
        return codepoint_to_utf8(n1)
    end

    local function parse_string(str, i)
        local res, j, k = "", i + 1, i + 1
        while j <= #str do
            local x = str:byte(j)
            if x < 32 then decode_error(str, j, "control character in string")
            elseif x == 92 then
                res = res .. str:sub(k, j - 1)
                j = j + 1
                local c = str:sub(j, j)
                if c == "u" then
                    local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1)


                              or str:match("^%x%x%x%x", j + 1)
                              or decode_error(str, j - 1, "invalid unicode escape in string")
                    res = res .. parse_unicode_escape(hex)
                    j = j + #hex
                else
                    if not escape_chars[c] then decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string") end
                    res = res .. escape_char_map_inv[c]
                end
                k = j + 1
            elseif x == 34 then
                res = res .. str:sub(k, j - 1)
                return res, j + 1
            end
            j = j + 1
        end
        decode_error(str, i, "expected closing quote for string")
    end

    local function parse_number(str, i)
        local x = next_char(str, i, delim_chars)
        local s = str:sub(i, x - 1)
        local n = tonumber(s)
        if not n then decode_error(str, i, "invalid number '" .. s .. "'") end
        return n, x
    end

    local function parse_literal(str, i)
        local x = next_char(str, i, delim_chars)
        local word = str:sub(i, x - 1)
        if not literals[word] then decode_error(str, i, "invalid literal '" .. word .. "'") end
        return literal_map[word], x
    end

    local function parse_array(str, i)
        local res, n = {}, 1
        i = i + 1
        while 1 do
            local x
            i = next_char(str, i, space_chars, true)
            if str:sub(i, i) == "]" then i = i + 1; break end
            x, i = parse(str, i)
            res[n] = x; n = n + 1
            i = next_char(str, i, space_chars, true)
            local chr = str:sub(i, i)
            i = i + 1
            if chr == "]" then break end
            if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
        end
        return res, i
    end

    local function parse_object(str, i)
        local res = {}
        i = i + 1
        while 1 do
            local key, val
            i = next_char(str, i, space_chars, true)
            if str:sub(i, i) == "}" then i = i + 1; break end
            if str:sub(i, i) ~= '"' then decode_error(str, i, "expected string for key") end
            key, i = parse(str, i)
            i = next_char(str, i, space_chars, true)
            if str:sub(i, i) ~= ":" then decode_error(str, i, "expected ':' after key") end
            i = next_char(str, i + 1, space_chars, true)
            val, i = parse(str, i)
            res[key] = val
            i = next_char(str, i, space_chars, true)
            local chr = str:sub(i, i)
            i = i + 1
            if chr == "}" then break end
            if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
        end
        return res, i
    end

    local char_func_map = {
        [ '"' ] = parse_string,
        [ "0" ] = parse_number, [ "1" ] = parse_number, [ "2" ] = parse_number,
        [ "3" ] = parse_number, [ "4" ] = parse_number, [ "5" ] = parse_number,
        [ "6" ] = parse_number, [ "7" ] = parse_number, [ "8" ] = parse_number,
        [ "9" ] = parse_number, [ "-" ] = parse_number,
        [ "t" ] = parse_literal, [ "f" ] = parse_literal, [ "n" ] = parse_literal,
        [ "[" ] = parse_array,   [ "{" ] = parse_object,
    }

    parse = function(str, idx)
        local chr = str:sub(idx, idx)
        local f = char_func_map[chr]
        if f then return f(str, idx) end
        decode_error(str, idx, "unexpected character '" .. chr .. "'")
    end

    function json.decode(str)
        if type(str) ~= "string" then error("expected argument of type string, got " .. type(str)) end
        local res, idx = parse(str, next_char(str, 1, space_chars, true))
        idx = next_char(str, idx, space_chars, true)
        if idx <= #str then decode_error(str, idx, "trailing garbage") end
        return res
    end
end

local function defaultProfile()
    return {
        outfit               = 1,
        cash                 = 0,
        credits              = 0,   -- shared credits currency (cops + robbers; replaced XP/levels)
        jailDebtSeconds      = 0,
        jailSecondsRemaining = 0,
        side                 = 'none',
        skin                 = nil,
        weapons              = {},
        weaponAmmo           = {},
        lastPos              = nil,
    }
end

local function normalizeProfile(p)
    if p.outfit == nil then
        p.outfit = 1
    end
    if p.jailDebtSeconds == nil then
        p.jailDebtSeconds = 0
    end
    if p.jailSecondsRemaining == nil then
        p.jailSecondsRemaining = 0
    end
    if p.credits == nil then
        p.credits = 0
    end
    -- XP/levels were removed (both sides use credits now). Strip the legacy fields so they
    -- stop persisting to players.json.
    p.xp = nil
    p.rankId = nil
    if p.weapons == nil then
        p.weapons = {}
    end
    if p.weaponAmmo == nil then
        p.weaponAmmo = {}
    end
    if p.lastPos == nil then
        p.lastPos = nil
    end
    return p
end

--------------------------------------------------------------------------------
-- MySQL backing store (via oxmysql).
--
-- The whole resource talks to persistence through GetProfile / SaveProfile and an
-- in-memory `store` cache; only Load() (read all profiles once at startup) and
-- Flush() (write changed profiles) touch the database. Every Flush call site runs
-- inside a thread (onResourceStart, playerDropped, onResourceStop, the save timer),
-- so oxmysql's blocking `.await` API is safe here.
--
-- Schema: common fields get their own columns so the table is browsable/queryable
-- in phpMyAdmin, and any field not mapped below is preserved losslessly in the
-- `extra` JSON column — so no profile data is ever dropped, including fields added
-- by future code.
--------------------------------------------------------------------------------

local TABLE = 'players'

-- profile field <-> column mapping. kind: 'scalar' | 'bool' | 'json'
local COLUMNS = {
    { col = 'side',                   field = 'side',                 kind = 'scalar' },
    { col = 'cash',                   field = 'cash',                 kind = 'scalar' },
    { col = 'credits',                field = 'credits',              kind = 'scalar' },
    { col = 'outfit',                 field = 'outfit',               kind = 'scalar' },
    { col = 'jail_seconds_remaining', field = 'jailSecondsRemaining', kind = 'scalar' },
    { col = 'jail_debt_seconds',      field = 'jailDebtSeconds',      kind = 'scalar' },
    { col = 'jail_facility',          field = 'jailFacility',         kind = 'scalar' },
    { col = 'station',                field = 'station',              kind = 'scalar' },
    { col = 'hide_hat',               field = 'hideHat',              kind = 'bool'   },
    { col = 'cop_car_fined',          field = 'copCarFined',          kind = 'bool'   },
    { col = 'skin',                   field = 'skin',                 kind = 'json'   },
    { col = 'weapons',                field = 'weapons',              kind = 'json'   },
    { col = 'weapon_ammo',            field = 'weaponAmmo',           kind = 'json'   },
    { col = 'tattoos',                field = 'tattoos',              kind = 'json'   },
    { col = 'inventory',              field = 'inventory',            kind = 'json'   },
    { col = 'cop_clothes',            field = 'copClothes',           kind = 'json'   },
    { col = 'stats',                  field = 'stats',                kind = 'json'   },
    { col = 'last_pos',               field = 'lastPos',              kind = 'json'   },
}

-- fields owned by a dedicated column; everything else on a profile goes to `extra`.
local KNOWN_FIELDS = {}
for _, c in ipairs(COLUMNS) do KNOWN_FIELDS[c.field] = true end

local CREATE_SQL = [[
CREATE TABLE IF NOT EXISTS `players` (
  `license` VARCHAR(80) NOT NULL,
  `side` VARCHAR(16) NOT NULL DEFAULT 'none',
  `cash` INT NOT NULL DEFAULT 0,
  `credits` INT NOT NULL DEFAULT 0,
  `outfit` INT NOT NULL DEFAULT 1,
  `jail_seconds_remaining` INT NOT NULL DEFAULT 0,
  `jail_debt_seconds` INT NOT NULL DEFAULT 0,
  `jail_facility` VARCHAR(64) NOT NULL DEFAULT '',
  `station` VARCHAR(64) NOT NULL DEFAULT '',
  `hide_hat` TINYINT(1) NOT NULL DEFAULT 0,
  `cop_car_fined` TINYINT(1) NOT NULL DEFAULT 0,
  `skin` JSON NULL,
  `weapons` JSON NULL,
  `weapon_ammo` JSON NULL,
  `tattoos` JSON NULL,
  `inventory` JSON NULL,
  `cop_clothes` JSON NULL,
  `stats` JSON NULL,
  `last_pos` JSON NULL,
  `extra` JSON NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
]]

-- Build the upsert once: INSERT ... ON DUPLICATE KEY UPDATE for every column.
local UPSERT_SQL
local INSERT_COLS = { 'license' }
do
    for _, c in ipairs(COLUMNS) do INSERT_COLS[#INSERT_COLS + 1] = c.col end
    INSERT_COLS[#INSERT_COLS + 1] = 'extra'
    local placeholders, updates = {}, {}
    for i, name in ipairs(INSERT_COLS) do
        placeholders[i] = '?'
        if name ~= 'license' then
            updates[#updates + 1] = ('`%s` = VALUES(`%s`)'):format(name, name)
        end
    end
    UPSERT_SQL = ('INSERT INTO `%s` (`%s`) VALUES (%s) ON DUPLICATE KEY UPDATE %s'):format(
        TABLE, table.concat(INSERT_COLS, '`, `'), table.concat(placeholders, ', '),
        table.concat(updates, ', '))
end

local function hasMySQL()
    return MySQL ~= nil and MySQL.query ~= nil and MySQL.query.await ~= nil
end

-- oxmysql returns JSON columns as either a decoded table or a raw string depending
-- on version/driver; accept both and turn empty/`null` into Lua nil.
local function decodeJsonCol(v)
    if v == nil then return nil end
    if type(v) == 'table' then return v end
    if type(v) == 'string' then
        if v == '' or v == 'null' then return nil end
        local ok, decoded = pcall(json.decode, v)
        if ok then return decoded end
    end
    return nil
end

local function rowToProfile(row)
    local p = {}
    for _, c in ipairs(COLUMNS) do
        local v = row[c.col]
        if c.kind == 'scalar' then
            if v == '' and (c.field == 'jailFacility' or c.field == 'station') then
                p[c.field] = nil
            else
                p[c.field] = v
            end
        elseif c.kind == 'bool' then
            p[c.field] = (v == 1 or v == true) and true or false
        else -- json
            p[c.field] = decodeJsonCol(v)
        end
    end
    local extra = decodeJsonCol(row.extra)
    if type(extra) == 'table' then
        for k, v in pairs(extra) do
            if p[k] == nil then p[k] = v end
        end
    end
    return normalizeProfile(p)
end

-- Produce a dense parameter array (no nil holes — oxmysql cannot send those) for UPSERT_SQL.
local function profileToParams(identifier, p)
    local params = { identifier }
    for _, c in ipairs(COLUMNS) do
        local v = p[c.field]
        if c.kind == 'scalar' then
            if v == nil then
                params[#params + 1] = (c.field == 'jailFacility' or c.field == 'station') and '' or 0
            else
                params[#params + 1] = v
            end
        elseif c.kind == 'bool' then
            params[#params + 1] = (v == true) and 1 or 0
        else -- json: always send a valid JSON string ('null' for absent)
            params[#params + 1] = (v == nil) and 'null' or json.encode(v)
        end
    end
    local extra, hasExtra = {}, false
    for k, v in pairs(p) do
        if not KNOWN_FIELDS[k] then extra[k] = v; hasExtra = true end
    end
    params[#params + 1] = hasExtra and json.encode(extra) or 'null'
    return params
end

-- One-time import of the legacy data/players.json into an empty table, so the
-- migration works even if the SQL dump was never imported by hand.
local function migrateFromJson()
    local raw = LoadResourceFile(RESOURCE, DATA_FILE)
    if not raw or raw == '' then return end
    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then return end
    local n = 0
    for identifier, profile in pairs(decoded) do
        local p = normalizeProfile(profile)
        store[identifier] = p
        local okw, err = pcall(function()
            MySQL.query.await(UPSERT_SQL, profileToParams(identifier, p))
        end)
        if okw then n = n + 1
        else CnR.Util.log('error', 'persistence: migrate failed for %s (%s)', identifier, tostring(err)) end
    end
    CnR.Util.log('info', 'persistence: migrated %d profiles from players.json into MySQL', n)
end

function CnR.Persistence.Load()
    if loaded then return end
    if not hasMySQL() then
        CnR.Util.log('error', 'persistence: oxmysql not available — is `ensure oxmysql` before `ensure cnr` and the connection string set?')
        store = {}
        loaded = true
        dirtyIds = {}
        return
    end
    local ok, err = pcall(function()
        MySQL.query.await(CREATE_SQL)
        local rows = MySQL.query.await('SELECT * FROM `' .. TABLE .. '`') or {}
        store = {}
        local n = 0
        for _, row in ipairs(rows) do
            store[row.license] = rowToProfile(row)
            n = n + 1
        end
        CnR.Util.log('info', 'persistence: loaded %d profiles from MySQL', n)
        if n == 0 then migrateFromJson() end
    end)
    if not ok then
        CnR.Util.log('error', 'persistence: MySQL load failed (%s)', tostring(err))
        store = {}
    end
    loaded = true
    dirtyIds = {}
end

function CnR.Persistence.GetProfile(identifier)
    if not identifier then return nil end
    if not loaded then CnR.Persistence.Load() end
    local p = store[identifier]
    if not p then
        p = defaultProfile()
        store[identifier] = p
    end
    -- The caller receives the live store reference and may mutate it in place
    -- without calling SaveProfile, so mark it for the next flush.
    dirtyIds[identifier] = true
    return normalizeProfile(p)
end

function CnR.Persistence.SaveProfile(identifier, t)
    if not identifier or type(t) ~= 'table' then return end
    if not loaded then CnR.Persistence.Load() end
    local existing = store[identifier] or defaultProfile()
    for k, v in pairs(t) do existing[k] = v end
    store[identifier] = existing
    dirtyIds[identifier] = true
end

function CnR.Persistence.Flush()
    if not loaded then return end
    if next(dirtyIds) == nil then return end
    if not hasMySQL() then return end
    local pending = dirtyIds
    dirtyIds = {}
    local saved = 0
    for id in pairs(pending) do
        local p = store[id]
        if p then
            local ok, err = pcall(function()
                MySQL.query.await(UPSERT_SQL, profileToParams(id, p))
            end)
            if ok then
                saved = saved + 1
            else
                CnR.Util.log('error', 'persistence: failed to save %s (%s)', tostring(id), tostring(err))
                dirtyIds[id] = true -- keep dirty so the next flush retries
            end
        end
    end
    if saved > 0 then CnR.Util.log('info', 'persistence: flushed %d profile(s) to MySQL', saved) end
end
