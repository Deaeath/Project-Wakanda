# SFM Programs — ATM10

```
   _____ ______ __  __   ____                                          
  / ____|  ____|  \/  | |  _ \                                         
 | (___ | |__  | \  / | | |_) |_ __ ___   __ _ _ __ __ _ _ __ ___  ___  
  \___ \|  __| | |\/| | |  __/| '__/ _ \ / _` | '__/ _` | '_ ` _ \/ __| 
  ____) | |    | |  | | | |   | | | (_) | (_| | | | (_| | | | | | \__ \
 |_____/|_|    |_|  |_| |_|   |_|  \___/ \__, |_|  \__,_|_| |_| |_|___/ 
                                          __/ |                        
                                         |___/                         
```

Automation scripts for a Super Factory Manager + CC:Tweaked base in **All the Mods 10**.
Machines that never idle, turtles that talk back, a diagnostic dump that
never crashes, and a couple of local tools to get code into a game that
actively fights you on it.

---

## Contents

| File | What it is |
|------|------------|
| [`crystal_assembler.sfml`](#crystal_assemblersfml) | ExtendedAE Crystal Assembler automation + power feed |
| [`circuit_cutter.sfml`](#circuit_cuttersfml) | ExtendedAE Circuit Cutter automation |
| [`reaction_chamber.sfml`](#reaction_chambersfml) | AdvancedAE Reaction Chamber automation |
| [`crusher.sfml`](#crushersfml) | Mekanism Crusher — every crushing recipe in the pack |
| [`jarvis.lua`](#jarvislua) | CC:Tweaked base assistant: chat commands, alarms, dashboard |
| [`status.lua`](#statuslua) | One-shot diagnostic dump for any turtle/computer |
| [`paste.lua`](#pastelua) | In-game line-buffered paste receiver, for when `edit` chokes |
| [`type-into-mc.ps1`](#type-into-mcps1--type-clipboardbat) | Local Windows auto-typer, clipboard → game window |

---

## `crystal_assembler.sfml`

Automates every ExtendedAE Crystal Assembler recipe **and** keeps the
assemblers powered — no more walking over to babysit an empty energy buffer.

**Labels to assign:**

| Label | Block |
|-------|-------|
| `Barrel` | Input chest/barrel with all ingredients |
| `Assembler` | All Crystal Assembler machines |
| `Storage` | Output storage |
| `Battery` | Power source (capacitor bank, energy cell, etc) |

**Notes:**
- Energy is just another SFM resource type (`forge:energy`) — moved every
  20 ticks from `Battery` to every `Assembler`, same `INPUT`/`OUTPUT`
  syntax as items. No dedicated `POWER` keyword exists in SFM.
- Recipes needing fluids (budding, entro_ingot, fluix_transformation,
  redstone_crystal, sky_bronze/steel/osmium) need water or lava piped in
  separately — SFM doesn't move fluids in this program.
- Each assembler must be configured to its recipe via the machine GUI.

---

## `circuit_cutter.sfml`

Automates the ExtendedAE Circuit Cutter — one cutter per recipe.

**Labels to assign:**

| Label | Block |
|-------|-------|
| `Barrel` | Input chest/barrel with block ingredients |
| `Slicer` | All Circuit Cutter machines (each self-configured to its recipe) |
| `Storage` | Output storage |

**Notes:**
- All cutters share the single `Slicer` label; each machine self-selects
  its configured recipe.
- Input slot is `SLOTS 0`, output slot is `SLOTS 1`.
- Uncomment the megacells/appflux lines if those mods are present.

---

## `reaction_chamber.sfml`

Automates the AdvancedAE Reaction Chamber across both its water and lava
recipe families, plus fluid output draining.

**Labels to assign:**

| Label | Block |
|-------|-------|
| `Barrel` | Input chest with all solid ingredients |
| `WaterTank` | Water source tank |
| `LavaTank` | Lava source tank |
| `Chamber` | All Reaction Chamber machines |
| `Storage` | Output chest for items |
| `FluidStorage` | Output tank for `quantum_infusion_source` fluid |

**Notes:**
- Water and lava recipe blocks run as separate `FORGET`-delimited passes
  in the same trigger, since a Chamber can only hold one fluid at a time.
- The quantum infusion recipe outputs a fluid, not an item — drained
  separately at the bottom into `FluidStorage`.

---

## `crusher.sfml`

Covers **every crushing recipe registered by any mod in the pack** —
addons add recipes to Mekanism's own crushing recipe type rather than
shipping their own crusher block, so one program covers all of them.

**Labels to assign:**

| Label | Block |
|-------|-------|
| `Barrel` | Input chest/barrel with all raw materials |
| `Crusher` | All Mekanism Crusher machines |
| `Storage` | Output storage |

**Notes:**
- Single input/single output machine — no `RETAIN` combos needed, just
  keep every valid input stocked and drain the result.
- Covers tag-based inputs (ingots, clumps, gems, ores), the waxed copper
  family via wildcard match, and every literal stone-cycle/organic chain
  in the modpack (deeperdarker, biomeswevegone, biomesoplenty, vanilla).

---

## `jarvis.lua`

A CC:Tweaked base assistant. Auto-detects whichever Advanced Peripherals
are attached and activates matching features — nothing crashes if a
peripheral is missing, it just quietly disables that feature.

**Supported peripherals** (attach any or all, wired or wireless):

| Peripheral | Feature |
|------------|---------|
| Chat Box | Talk back in-game, listen for `jarvis <cmd>` |
| ME Bridge / RS Bridge | Storage totals + item lookups |
| Player Detector | Greet trusted players on arrival, alarm on strangers |
| Energy Detector | Low-power warnings |
| Speaker | Chimes for events |
| Monitor | Live base status dashboard |

**Chat commands:** `jarvis status`, `jarvis storage`, `jarvis energy`,
`jarvis find <item>`, `jarvis hello`

**Install:** save as `startup` on the turtle/computer, then `reboot`.

> **Gotcha:** Advanced Peripherals registers everything in snake_case —
> `chat_box`, `me_bridge`, `rs_bridge`, `player_detector`,
> `energy_detector` — **not** the camelCase you'd guess from the item
> names. Confirmed straight from the mod jar's bytecode after multiple
> rounds of "why is this always nil." `peripheral.find("chatBox")` will
> silently return nothing forever.
>
> **Also:** a turtle needs the actual **Chat Box turtle upgrade**
> (`Advanced Chatty Turtle` — craft turtle + Chat Box block together)
> equipped in a tool slot. A Chat Box block placed nearby, or even
> directly adjacent, does nothing for a turtle — that's a Computer-only
> peripheral-adjacency behavior.

---

## `status.lua`

One-shot diagnostic dump. Prints everything it can find; missing
peripherals or features just print "not present" instead of erroring —
every peripheral call is wrapped in `pcall`.

Covers: system info, turtle fuel/inventory/equipped upgrades/GPS,
every attached peripheral by name and type, storage bridge totals +
network energy, energy detector reading, nearby players, chat box
presence, and redstone levels on all 6 sides.

Run with: `status`

---

## `paste.lua`

A line-buffered paste receiver for the turtle terminal. CC:Tweaked's
built-in `edit` can choke on large pastes or drop characters under load;
this reads raw lines instead and writes them straight to a file.

```
paste <filename>
```

Type or paste your code, then end with a line containing only `:done`.

---

## `type-into-mc.ps1` / `type-clipboard.bat`

The nuclear option: when in-game paste isn't reliable and typing 300+
lines by hand isn't happening, this reads your **clipboard** on the
Windows side and injects it into whatever window has focus, character by
character, as fast as your CPU can push `SendInput` calls.

```
powershell -File .\sfm-programs\type-into-mc.ps1
```

or double-click `type-clipboard.bat` / use the pinned shortcut.

**Workflow:** copy your code → alt-tab into Minecraft → open `edit
<filename>` → run the script within the countdown → `Ctrl+S`.

> **Why not `SendKeys`?** Minecraft binds `/` to open chat/commands.
> `SendKeys` simulates real key-presses, so a `/` mid-paste gets
> intercepted by the game's keybind and yanks focus out of the editor
> mid-type. The script instead injects characters via `SendInput` +
> `KEYEVENTF_UNICODE` — pure text events, not real keypresses — so no
> keybind ever sees a literal `/` (or any other bound key) fire.
> `Enter` is still sent as a real key, since the editor needs an actual
> newline.

**Tuning:**
- `-DelayMs` — per-character pause, default `0` (no artificial
  throttling — raw back-to-back injection). Bump to `1`–`2` if the game
  starts dropping characters under heavy tick load.
- `-CountdownSeconds` — how long you get to alt-tab back in before it
  starts typing. Default `5`.

---

## Lessons paid for in blood

- **SFM has no `POWER` keyword.** Energy is just a resource type
  (`forge:energy`) moved with ordinary `INPUT`/`OUTPUT` statements, same
  as items.
- **Advanced Peripherals types are snake_case**, not camelCase — always
  verify against the mod jar (`javap` the `PERIPHERAL_TYPE` constant)
  before trusting a peripheral name.
- **Turtle peripherals need turtle *upgrades*, not adjacent blocks.**
  Crafting a turtle + peripheral item together in a crafting grid
  produces a *new* turtle with the peripheral built in — it does not
  retrofit the turtle you already have placed.
- **`/` will always fight you** in any text-input context inside
  Minecraft. Either strip it from source (see the `^-1` power-operator
  trick in `jarvis.lua` for avoiding division), or inject text as
  Unicode events instead of simulated keypresses.
