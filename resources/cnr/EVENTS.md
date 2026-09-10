# CnR Event & NUI Contract

This document is **authoritative** for all inter-file communication inside the
`cnr` resource. Sibling workers (Gameplay = Phase 2, Ranks/Teams = Phase 3,
NUI = Phase 4) MUST use these exact event names and payload shapes. Do not
rename, do not add extra positional arguments — extend the payload object
instead, and update this file in the same commit.

Direction key:
- `c→s` — client → server (`TriggerServerEvent`)
- `s→c` — server → client (`TriggerClientEvent`)
- `s→all-cops` — server fan-out to every player whose `CnR.GetSide(src) == 'cop'`

All payloads are a single Lua table unless explicitly noted as "no payload".

---

## 0. Shared Profile Shape

`CnR.Persistence.GetProfile(identifier)` returns / accepts:

```
{
    xp                   = 0,
    rankId               = 1,
    jurisdiction         = 'LSPD',
    cash                 = 0,
    jailSecondsRemaining = 0,
    side                 = 'none',
    skin                 = nil,
}
```

`identifier` is always the player's `license:` identifier
(`GetPlayerIdentifierByType(src, 'license')`).

---

## 1. Team selection & loadout

| Event | Direction | Payload | Notes |
|---|---|---|---|
| `cnr:server:requestTeamSelect` | c→s | _none_ | Client asks to (re)open the team-select flow. |
| `cnr:client:openTeamSelect`    | s→c | `{ skinsByTeam = { cop = {…}, robber = {…} } }` | Server pushes available skin lists. |
| `cnr:server:setSide`           | c→s | `{ side='cop'\|'robber', skin=string, station='missionRow'\|'vespucci'\|nil }` | `station` only meaningful for cops. |
| `cnr:client:applyLoadout`      | s→c | `{ side, weapons={…}, ammo={WEAPON_X=int,…}, armor='light'\|'standard'\|'heavy'\|'super', skin, spawn=vec3 }` | Server is the authority for what the client gets. |

---

## 2. Robberies (Guide §5.2)

| Event | Direction | Payload | Notes |
|---|---|---|---|
| `cnr:server:robberyStart`    | c→s | `{ kind='store'\|'bank', id=int }` | `id` is the 1-based index into `Config.Stores` or `Config.Banks`. |
| `cnr:server:robberyTick`     | c→s | `{ id }` | Client pings every 5 s while still in range; server validates and credits at `Config.RobberyDurationSec`. |
| `cnr:client:robberyProgress` | s→c | `{ percent, payoutSoFar }` | Server-driven HUD update; percent in `[0,100]`. |

---

## 3. Crime reporting & wanted state (Guide §5.5, §8.2)

| Event | Direction | Payload | Notes |
|---|---|---|---|
| `cnr:server:reportDeath`            | c→s | `{ killer = serverId }` | Fired by the victim's client on death (killer resolved via GetPedSourceOfDeath). Drives respawn AND the kill jail/wanted penalties. |
| `cnr:server:reportCopShot`          | c→s | _none_ | Fired when an innocent robber's bullet hits a cop. |
| `cnr:server:reportPoliceCarTheft`   | c→s | _none_ | Fired when an innocent player enters a police vehicle driver seat. |
| `cnr:client:setWanted`              | s→c | `{ wanted = true\|false }` | Drives blip color (white → red). |

---

## 4. Arrests (Guide §6.3, §6.4)

| Event | Direction | Payload | Notes |
|---|---|---|---|
| `cnr:server:attemptCuff`     | c→s | `{ target = src }` | Cop pressed Q on a nearby wanted robber. |
| `cnr:client:cuffed`          | s→c | `{ byCopSrc = src }` | Server authorises and notifies the cuffed player. |
| `cnr:client:uncuffed`        | s→c | _none_ | Cuffing cop died/disconnected or escort failed. |
| `cnr:server:deliverArrest`   | c→s | `{ target = src }` | Cop drove through `Config.ArrestEntrance` with cuffed player in tow. |
| `cnr:client:arrestRewarded`  | s→c | `{ xp = number, cash = number }` | Local HUD pop for the arresting cop. |

---

## 5. Jail (Guide §8)

| Event | Direction | Payload | Notes |
|---|---|---|---|
| `cnr:client:goToJail`        | s→c | `{ seconds = number }` | Server picks Mission Row vs Bolingbroke from `Config.JailTime.lowJailThreshold`. |
| `cnr:client:jailTimeUpdate`  | s→c | `{ seconds = number }` | Periodic countdown; client mirrors into HUD. |
| `cnr:server:laundryComplete` | c→s | _none_ | One full laundry cycle done; server subtracts `Config.Laundry.reductionSec`. |

---

## 6. Ranks & vehicles (Guide §7)

| Event | Direction | Payload | Notes |
|---|---|---|---|
| `cnr:server:requestRankSwitch` | c→s | `{ rankId = int, skin = string }` | Fired from the station rank terminal. |
| `cnr:client:rankApplied`       | s→c | `{ rank = Config.Ranks[i] }` | Full rank table echoed for HUD/skin. |
| `cnr:server:requestVehicle`    | c→s | `{ model = string }` | Validated against current rank's vehicle list. |
| `cnr:client:spawnVehicle`      | s→c | `{ model = string, coords = vec3 }` | Server-chosen spawn (yard slot). |

---

## 7. Police radio (Guide §6.5)

| Event | Direction | Payload | Notes |
|---|---|---|---|
| `cnr:server:radioMessage` | c→s        | `{ text = string }` | Cop-only; server drops if sender isn't a cop. |
| `cnr:client:radioMessage` | s→all-cops | `{ from = playerName, text = string }` | Server rebroadcasts to every on-duty cop. |

---

## 8. Misc UX

| Event | Direction | Payload | Notes |
|---|---|---|---|
| `cnr:client:openHelp`    | s→c | _none_ | Triggered by `/help`. |
| `cnr:client:openHud`     | s→c | `{ side, xp, jailSeconds }` | Sent on spawn / after rank change / after sentence update. |
| `cnr:server:newLife`     | c→s | _none_ | `/newlife` confirmation — server wipes profile to defaults. |

---

## 9. NUI message types (`SendNUIMessage`)

The client always sends a `type` field; payload fields are siblings.

| `type` | Payload | Sent by |
|---|---|---|
| `teamSelect`     | `{ skinsByTeam = { cop = {…}, robber = {…} } }` | Teams worker on `cnr:client:openTeamSelect` |
| `skinPicker`     | `{ skins = {…}, forRankId = int }` | Ranks worker after `cnr:client:rankApplied` (skin re-pick) |
| `help`           | `{ sections = {…} }` | `/help` |
| `hudUpdate`      | `{ xp = number, jailSeconds = number }` | Gameplay/Jail workers; HUD always reads the latest |
| `close`          | _none_ | `CnR.NUI.close()` |

## 10. NUI callbacks (`RegisterNUICallback`)

| Callback name | Body | Replies | Notes |
|---|---|---|---|
| `cnr/chooseTeam`      | `{ side = 'cop'\|'robber' }` | `{ ok = true }` | NUI responds; client then triggers `cnr:server:requestTeamSelect` flow. |
| `cnr/chooseSkin`      | `{ skin = string, station = 'missionRow'\|'vespucci'\|nil }` | `{ ok = true }` | Triggers `cnr:server:setSide`. |
| `cnr/closeHelp`       | _none_ | `{ ok = true }` | Closes the help overlay. |
| `cnr/newLifeConfirm`  | `{ confirm = bool }` | `{ ok = true }` | If `confirm`, triggers `cnr:server:newLife`. |

---

## Phase 3 amendments

Integration pass. Append-only — nothing above changes.

### Server events (additional)

| Event | Direction | Payload | Notes |
|---|---|---|---|
| `cnr:client:profileUpdate` | s→c | `{ side, xp, rankId, rankName, jurisdiction, cash, jailSeconds }` | Server pushes the persisted profile to the client whenever any of these fields mutate (setSide, GrantXp, ApplyRank, robbery payout, arrestRewarded, jail 5s tick + on release). The client HUD caches the last payload and re-emits `hudUpdate` from it. |

### Routing changes

- `/newlife` no longer uses the chat-based "type again to confirm" fallback. The client command now opens the NUI `newLifeConfirm` modal directly; confirmation flows through the existing `cnr/newLifeConfirm` NUI callback to `cnr:server:newLife`.
- `client/station.lua` no longer calls `SendNUIMessage{type='vehiclePicker',...}` directly. It now fires `cnr:client:vehiclePicker` so the central dispatcher in `client/nui.lua` owns the NUI message + focus.
- `cnr:server:setSide` now fires `cnr:client:applyLoadout` for both sides on first spawn: cops via `CnR.Ranks.ApplyRank` (station spawn anchor), robbers with a random pick from `Config.Spawns.robbers` and a starter pistol (100 rounds).
- `cnr:server:requestTeamSelect` is now handled in `server/main.lua` and replies with the default `cnr:client:openTeamSelect` payload (rank-1 cop skins + civilian skin pool).

---

## Phase 2C amendments

The NUI worker added the following message types and callbacks. All are
append-only — existing names and shapes above are unchanged.

### Additional `SendNUIMessage` types (s/c → NUI)

| `type` | Payload | Sent by |
|---|---|---|
| `skinPicker` (extended) | `{ side = 'cop'\|'robber', skins = {string,…}, stations = { missionRow=vec3, vespucci=vec3 }\|nil }` | `client/spawn.lua` after `cnr/chooseTeam`. Adds `side` and optional `stations` fields. |
| `rankPicker` / `rankList` | `{ ranks = Config.Ranks, xp = number }` | Forwarded from `cnr:client:rankList`. Either type is accepted by the NUI. |
| `vehiclePicker` | `{ vehicles = { { model=string, rankName=string, unlocked=bool }, … } }` | Forwarded from `cnr:client:vehiclePicker`. |
| `newLifeConfirm` | _none_ | Opens the reset-confirmation modal. |
| `radioInput` | _none_ | Cop-only; opens the radio compose modal. Forwarded from `cnr:client:openRadioInput`. |
| `radioRecv` | `{ from = string, text = string }` | Forwarded from `cnr:client:radioMessage` for the cop radio feed. |
| `notify` | `{ text = string, level='ok'\|'warn'\|'error'\|nil, duration=ms\|nil }` | Forwarded from `cnr:client:notify`. |
| `hudUpdate` (extended) | `{ side, xp, jailSeconds, rank, cash }` | `client/hud.lua` 1 Hz tick. `rank` may include `{ id, name, jurisdiction, xp, nextXp, skins }`. |
| `jailTimeUpdate` | `{ seconds = number }` | Forwarded from `cnr:client:jailTimeUpdate`. |
| `robberyProgress` | `{ percent, payoutSoFar }` | Forwarded from `cnr:client:robberyProgress`. |
| `closeAll` | _none_ | Emitted on ESC by the NUI dispatcher; hides every transient panel. |

### Additional `RegisterNUICallback` callbacks (NUI → client)

| Callback | Body | Replies | Effect |
|---|---|---|---|
| `cnr/applyRank` | `{ rankId = int, skin = string }` | `{ ok = true }` | Triggers `cnr:server:requestRankSwitch`. |
| `cnr/spawnVehicle` | `{ model = string }` | `{ ok = true }` | Triggers `cnr:server:requestVehicle`. |
| `cnr/sendRadio` | `{ text = string }` | `{ ok = true }` | Triggers `cnr:server:radioMessage`. |

### Additional `s→c` net events accepted by the dispatcher

| Event | Payload | Effect |
|---|---|---|
| `cnr:client:vehiclePicker` | `{ vehicles = {…} }` | Opens the vehicle picker (with NUI focus). |
| `cnr:client:openRadioInput` | _none_ | Cop-only; opens the radio compose panel (with NUI focus). |


---

## Phase 2B amendments

The following events/callbacks were appended by the Phase 2B (Progression & Cop)
worker. They extend — never replace — the contracts above.

### Server events (additional)

| Event | Direction | Payload | Notes |
|---|---|---|---|
| `cnr:server:requestRankList` | c→s | _none_ | Station rank terminal asks server for the rank list (with unlock flags) for the local cop. Server replies via `cnr:client:rankList`. |

### Client events (additional)

| Event | Direction | Payload | Notes |
|---|---|---|---|
| `cnr:client:rankList` | s→c | `{ ranks = { { id, name, jurisdiction, xp, weapons, armor, vehicles, skins, unlocked }, … } }` | Reply to `cnr:server:requestRankList`. Forwarded by the Ranks client worker to NUI as `{ type='rankList', payload=… }`. |
| `cnr:client:notify`   | s→c | `{ kind = 'info'\|'warn'\|'error', text = string }` | Generic transient notification (GTA feed ticker). Any worker may fire it. |

### NUI message types (additional)

| `type` | Payload | Sent by |
|---|---|---|
| `rankList`      | `{ payload = <ranks list as above> }` | Ranks client worker on `cnr:client:rankList` |
| `vehiclePicker` | `{ payload = { models = {…} } }`      | Station worker on E-press near a vehicle yard |
| `radioInput`    | _none_ | Police radio client worker on F6 (opens NUI input box) |
| `radioRecv`     | `{ from = string, text = string }` | Police radio client worker on `cnr:client:radioMessage` |

### NUI callbacks (additional)

| Callback name | Body | Replies | Notes |
|---|---|---|---|
| `cnr/chooseRank`    | `{ rankId = int, skin = string }`  | `{ ok = true }` | Station worker → triggers `cnr:server:requestRankSwitch`. |
| `cnr/chooseVehicle` | `{ model = string }`               | `{ ok = true }` | Station worker → triggers `cnr:server:requestVehicle`. |
| `cnr/sendRadio`     | `{ text = string }`                | `{ ok = true }` | Police radio worker → triggers `cnr:server:radioMessage`. |

