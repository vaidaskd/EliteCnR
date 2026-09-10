This is a custom cops and robbers server for GTA V Legacy (FiveM) that anybody can use as an example.
Feel free to use resources to help build your own cops and robbers server.

# Elite Cops & Robbers — FiveM Server

**Elite Cops & Robbers** is a FiveM cops-vs-robbers server where players can choose between **Law Enforcement** and **Criminals**.

Cops earn credits by arresting or eliminating wanted robbers, while robbers earn money and credits by committing crimes and completing robberies.

There are **no levels or XP**. Both teams use credits to unlock weapons, vehicles, armor, and other equipment.

> **Press `H` in-game to open the full server guide.**

---

## General Information

### Commands

| Command    | Description                                                              |
| ---------- | ------------------------------------------------------------------------ |
| `/newlife` | Resets everything, including credits, and returns you to team selection. |
| `/help`    | Opens the in-game server guide.                                          |

### Keybinds

| Key  | Action                                |
| ---- | ------------------------------------- |
| `C`  | Cuff wanted robbers only              |
| `F`  | Enter vehicle / hijack driver         |
| `G`  | Enter / exit as passenger             |
| `L`  | Lock / unlock your vehicle            |
| `E`  | Interact with stores, terminals, etc. |
| `I`  | Inventory & player status             |
| `H`  | Open the server guide                 |
| `T`  | Chat — Global / Local / Police Radio  |
| `F7` | Players list                          |
| `F8` | Open console                          |

### Player Colors

* 🔵 **Blue** — Cop
* 🔴 **Red** — Wanted Robber
* 🟠 **Orange** — Prisoner
* ⚪ **White** — Innocent Robber

Innocent robbers are hidden on the map.

### Chat & Interface

Press `T` to open chat and switch between:

* Global Chat
* Local Chat
* Police Radio

Your **role, credits, cash, and jail time** are displayed on the right-side status bar.

There are **no levels or XP**. Both teams earn and spend credits.

---

# Cops

## Law Enforcement

### Getting Started

* Spawn at **Mission Row PD** or **Vespucci PD**.
* Friendly fire between cops is disabled.
* Earn credits from arrests and kills.
* Spend credits at the **Armory** and **Vehicle Yard** NPCs.
* Credits can be used for weapons, armor, vehicles, and helicopters.
* There are no levels.
* Credits remain after death until they are spent or `/newlife` is used.
* Officers wear their police uniform.
* At clothing stores, cops can only purchase glasses and watches.
* Glasses and watches remain through death and reconnecting.
* Clothing accessories are cleared when `/newlife` is used.

## Cop Rewards

| Action               |                  Reward |
| -------------------- | ----------------------: |
| Standard arrest      | **+6 credits + $1,000** |
| Instant arrest       |          **+3 credits** |
| Kill a wanted robber |           **+1 credit** |

### Standard Arrest

Escort the suspect to a police station and complete the arrest.

**Reward:** `+6 credits` and `$1,000`

### Instant Arrest

Send the suspect directly to jail.

**Reward:** `+3 credits` and no cash reward.

## Cop Penalties

* Cop-on-cop friendly fire is disabled.
* Killing an innocent player costs **-1 credit**.
* Killing an NPC costs **-1 credit**.
* Killing a prisoner costs **-1 credit**.
* Killing an aggressive red-blip NPC in self-defense does **not** cost a credit.
* Disrupting another player's gameplay can result in a **kick or ban**.

---

# Police Vehicles

| Vehicle                      |       Cost |
| ---------------------------- | ---------: |
| Police Cruiser               |       Free |
| Police Bike                  |       Free |
| Police Cruiser 2             |   1 credit |
| Dinka Thrust Police Bike     |   1 credit |
| Police Cruiser 3             |  2 credits |
| Police Dirtbike BF400        |  2 credits |
| Police Transporter           |  3 credits |
| Police Granger 3600LX        |  5 credits |
| Police Vapid Aleutian        |  5 credits |
| Alamo Unmarked               |  5 credits |
| Police Grotti Itali RSX      | 10 credits |
| Police Pfister Comet S2      | 10 credits |
| Police Sentinel GTS          | 10 credits |
| LSPD Brute Stockade          | 15 credits |
| LEO RCV                      | 20 credits |
| Other add-on police vehicles |  5 credits |

## Police Helicopters

| Helicopter      |       Cost |
| --------------- | ---------: |
| Police Maverick | 10 credits |
| Police Buzzard  | 20 credits |

---

# Police Weapons

| Weapon Tier                                                                 |       Cost |
| --------------------------------------------------------------------------- | ---------: |
| Pistol, Stun Gun, Nightstick, Flashlight                                    |       Free |
| Pistol Mk II, Combat Pistol, Heavy Pistol                                   |   1 credit |
| Micro SMG, Combat PDW, SMG Mk II                                            |  2 credits |
| Pump Shotgun, Pump Shotgun Mk II, Fire Extinguisher                         |  3 credits |
| Heavy Revolver, Pistol .50, Flare Gun                                       |  4 credits |
| Carbine Rifle, Carbine Rifle Mk II, Tear Gas                                |  5 credits |
| Assault Rifle, Assault Rifle Mk II, Battle Rifle, Marksman Rifle, AP Pistol |  7 credits |
| Sniper Rifle, Marksman Rifle Mk II                                          | 10 credits |
| Combat MG, Heavy Sniper                                                     | 15 credits |

## Police Armor

| Armor             |      Cost |
| ----------------- | --------: |
| Super Light Armor |      Free |
| Light Armor       |  1 credit |
| Standard Armor    | 2 credits |
| Heavy Armor       | 4 credits |
| Super Heavy Armor | 5 credits |

---

# Robbers

## Criminals

### How It Works

* Innocent robbers are hidden on the map.
* Committing a robbery or murder makes you **wanted** and visible.
* Jail time is automatically added for crimes.
* Robbers spawn at random locations across Los Santos.
* To rob a store, bank, or jewelry store, point your gun at the clerk/teller for approximately one second.
* Credits remain after death and leaving jail until they are spent or `/newlife` is used.
* A robber leaving jail starts with **$0 cash**.
* Weapons can be purchased at any Ammu-Nation using cash earned from jobs.
* Weapon prices range from **$500 for a pistol** up to **$12,000 for a sniper rifle**.
* 24/7 and liquor stores also sell food and snacks.
* Clothing stores and barbers can be used to change your appearance.

---

# Jail Locations

| Jail Time           | Location                            |
| ------------------- | ----------------------------------- |
| 3 minutes or less   | Mission Row / Vespucci holding cell |
| More than 3 minutes | Bolingbroke Penitentiary            |

---

# Robberies & Rewards

| Target               | Cost to Start |             Reward |
| -------------------- | ------------: | -----------------: |
| 24/7 or Liquor Store |          Free | +1 credit + $1,000 |
| Jewelry Store        |     3 credits |            +$3,000 |
| Bank                 |     5 credits |            +$5,000 |

### Important

Only **24/7 and liquor store robberies** reward credits.

These robberies give **+1 credit** each.

Credits are then used to unlock the bigger jobs:

* Jewelry Store — costs **3 credits**
* Bank — costs **5 credits**

The credits required to start these larger robberies are **consumed**, and you do not receive additional credits from them.

---

# Innocent Robber Penalties

| Crime                               | Penalty                            |
| ----------------------------------- | ---------------------------------- |
| Rob a store, jewelry store, or bank | Wanted + 30 seconds                |
| Kill another player or NPC          | Wanted + 1 minute                  |
| Injure a police officer             | Wanted + 30 seconds, once only     |
| Steal a police vehicle              | Wanted + 30 seconds, once per life |

---

# Wanted Robber Penalties

| Crime                      | Penalty                    |
| -------------------------- | -------------------------- |
| Kill another player or NPC | +1 minute jail per kill    |
| Steal a police vehicle     | +30 seconds, once per life |

---

# Arrests & Cuffing

* Cops can only cuff **wanted robbers**.
* Stand close to a wanted robber and press `C`.
* A cuffed robber follows the cop on foot.
* A cuffed robber can also ride in the cop's vehicle.
* Press `C` again next to a cuffed suspect to open the arrest options.

### Arrest Options

**Standard Arrest**

Escort the suspect to a police station arrest point.

**Reward:** `+6 credits + $1,000`

**Instant Arrest**

Send the suspect directly to jail.

**Reward:** `+3 credits`

### Disconnecting

* If the cop dies, the cuffed robber is automatically freed.
* If the cop disconnects, the cuffed robber is automatically freed.
* If a robber disconnects while cuffed, they go directly to jail when they reconnect.

---

# Killing Rules

### Police

Police cannot damage or kill other police officers.

If a cop kills:

* An innocent player → **-1 credit**
* An NPC → **-1 credit**
* A prisoner → **-1 credit**

### Innocent Robbers

If an innocent robber kills another player or NPC:

* They become wanted.
* **+1 minute** is added to their jail time.

### Wanted Robbers

If a wanted robber kills another player or NPC:

* **+1 minute of jail time per kill**.

### Prisoners

If a prisoner kills another player:

* **+1 minute** is added to their current sentence.

---

# Police Vehicle Theft

Stealing a police vehicle as a robber:

* Makes you **wanted**.
* Adds **30 seconds** to your jail time.
* The penalty applies **once per life**.

---

# Server Rules

To keep the server fair and enjoyable:

* Do not use cheats, hacks, or unauthorized software.
* Do not exploit bugs or abuse server mechanics.
* Do not intentionally disrupt another player's gameplay.
* Do not intentionally kill innocent players as a cop.
* Cops may only cuff **wanted robbers**.
* Follow the server's arrest and wanted systems.
* Respect other players.
* Follow staff instructions.
* Abuse of server mechanics may result in a **kick or ban**.

---

# Quick Reference

### Everyone

* `/help` — Open the server guide
* `/newlife` — Reset your character, credits, and team selection
* `H` — Open guide
* `T` — Chat
* `F7` — Players list
* `F8` — Console

### Cops

* `C` — Cuff wanted robbers
* Earn credits through arrests and kills.
* Spend credits on police weapons, vehicles, helicopters, and armor.
* Friendly fire is disabled.

### Robbers

* Stay innocent to remain hidden.
* Commit crimes to become wanted.
* Rob 24/7 and liquor stores to earn credits.
* Use credits to unlock jewelry store and bank robberies.
* Avoid police and manage your wanted status.

---

# Important Information

**Credits are permanent** and remain after death until they are spent or `/newlife` is used.

**There are no levels or XP.**

**Innocent robbers are hidden from the map.**

**Wanted robbers are visible and can be arrested by police.**

**Press `H` in-game at any time to open the server guide.**

