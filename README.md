<div align="center">

<img src="banner.webp" alt="ColossusCraft: Project Wakanda" />

# ColossusCraft: Project Wakanda

### *Wakanda Forever. The base runs itself now.*

**Vibranium-grade automation for a Super Factory Manager + CC:Tweaked base**
**in All the Mods 10.**

Machines that never idle. Turtles that talk back. A diagnostic dump that
never crashes. And a couple of local tools to get code into a game that
actively fights you on it.

[![Status](https://img.shields.io/badge/status-online-00e5ff?style=for-the-badge&labelColor=0a0a0a)](#)
[![Platform](https://img.shields.io/badge/platform-ATM10%20%2F%20NeoForge-00e5ff?style=for-the-badge&labelColor=0a0a0a)](#)
[![Suite](https://img.shields.io/badge/part%20of-ColossusCraft-00e5ff?style=for-the-badge&labelColor=0a0a0a)](https://github.com/Deaeath/ColossusCraft)
[![Tech](https://img.shields.io/badge/tech-vibranium-00e5ff?style=for-the-badge&labelColor=0a0a0a)](#)
[![License](https://img.shields.io/badge/license-Wakandan%20Council-00e5ff?style=for-the-badge&labelColor=0a0a0a)](#)

</div>

---

## What is this?

**Project Wakanda** is a self-sufficient production suite: crafting machines
that feed themselves, turtles that answer you in chat, and a full base
status report on demand. Point it at your factory once, label the blocks,
and walk away — it keeps running whether or not you're standing there.

Built the way Wakanda builds things: hidden in plain sight, quietly more
advanced than everything around it, and never showing its work until it
matters.

---

## Systems Roster

```
project-wakanda/
├── sfm/            Super Factory Manager programs (.sfml)
├── cc-tweaked/      CC:Tweaked turtle/computer programs (.lua)
└── tools/           Local Windows helper tools (.ps1 / .bat)
```

| Callsign | File | Role |
|----------|------|------|
| **Forge** | [`sfm/crystal_assembler.sfml`](#sfmcrystal_assemblersfml) | ExtendedAE Crystal Assembler automation + self-feeding power |
| **Cutter** | [`sfm/circuit_cutter.sfml`](#sfmcircuit_cuttersfml) | ExtendedAE Circuit Cutter automation + self-feeding power |
| **Chamber** | [`sfm/reaction_chamber.sfml`](#sfmreaction_chambersfml) | AdvancedAE Reaction Chamber automation + self-feeding power |
| **Crusher** | [`sfm/crusher.sfml`](#sfmcrushersfml) | Mekanism Crusher — every crushing recipe in the pack + self-feeding power |
| **Jarvis** | [`cc-tweaked/jarvis.lua`](#cc-tweakedjarvislua) | Base assistant — chat commands, alarms, live dashboard |
| **Griot** | [`cc-tweaked/status.lua`](#cc-tweakedstatuslua) | On-demand diagnostic report for any turtle or computer |
| **Scribe** | [`cc-tweaked/paste.lua`](#cc-tweakedpastelua) | In-game paste receiver, for when `edit` chokes |
| **Kimoyo** | [`tools/type-into-mc.ps1`](#toolstype-into-mcps1--type-clipboardbat) | Local clipboard-to-game injector |

---

## `sfm/crystal_assembler.sfml`

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
- Energy is a scalar SFM resource type — the literal `fe::` expands to
  `sfm:fe:*:*`, and `fe`/`rf`/`energy`/`power` all alias to the same
  underlying `forge_energy` type. Moved every tick from `Battery` to
  every `Assembler`, same `INPUT`/`OUTPUT` syntax as items. **`forge:energy`
  is a trap** — that gets parsed as an item lookup and silently moves
  nothing (see [Lessons paid for in blood](#lessons-paid-for-in-blood)).
- Recipes needing fluids (budding, entro_ingot, fluix_transformation,
  redstone_crystal, sky_bronze/steel/osmium) need water or lava piped in
  separately — SFM doesn't move fluids in this program.
- Each assembler must be configured to its recipe via the machine GUI.

---

## `sfm/circuit_cutter.sfml`

Automates the ExtendedAE Circuit Cutter — one cutter per recipe — and
keeps every cutter powered.

**Labels to assign:**

| Label | Block |
|-------|-------|
| `Barrel` | Input chest/barrel with block ingredients |
| `Slicer` | All Circuit Cutter machines (each self-configured to its recipe) |
| `Storage` | Output storage |
| `Battery` | Power source (capacitor bank, energy cell, etc) |

**Notes:**
- All cutters share the single `Slicer` label; each machine self-selects
  its configured recipe.
- Input slot is `SLOTS 0`, output slot is `SLOTS 1`.
- Uncomment the megacells/appflux lines if those mods are present.
- Power feed runs every tick, `Battery` → every `Slicer`, using `fe::`
  (see the energy note above — `forge:energy` does not work).

---

## `sfm/reaction_chamber.sfml`

Automates the AdvancedAE Reaction Chamber across both its water and lava
recipe families, plus fluid output draining and power.

**Labels to assign:**

| Label | Block |
|-------|-------|
| `Barrel` | Input chest with all solid ingredients |
| `WaterTank` | Water source tank |
| `LavaTank` | Lava source tank |
| `Chamber` | All Reaction Chamber machines |
| `Storage` | Output chest for items |
| `FluidStorage` | Output tank for `quantum_infusion_source` fluid |
| `Battery` | Power source (capacitor bank, energy cell, etc) |

**Notes:**
- Water and lava recipe blocks run as separate `FORGET`-delimited passes
  in the same trigger, since a Chamber can only hold one fluid at a time.
- The quantum infusion recipe outputs a fluid, not an item — drained
  separately at the bottom into `FluidStorage`.
- Power feed runs every tick, `Battery` → every `Chamber`, using `fe::`.

---

## `sfm/crusher.sfml`

Covers **every crushing recipe registered by any mod in the pack** —
addons add recipes to Mekanism's own crushing recipe type rather than
shipping their own crusher block, so one program covers all of them.
Also keeps every crusher powered.

**Labels to assign:**

| Label | Block |
|-------|-------|
| `Barrel` | Input chest/barrel with all raw materials |
| `Crusher` | All Mekanism Crusher machines |
| `Storage` | Output storage |
| `Battery` | Power source (capacitor bank, energy cell, etc) |

**Notes:**
- Single input/single output machine — no `RETAIN` combos needed, just
  keep every valid input stocked and drain the result.
- Covers tag-based inputs (ingots, clumps, gems, ores), the waxed copper
  family via wildcard match, and every literal stone-cycle/organic chain
  in the modpack (deeperdarker, biomeswevegone, biomesoplenty, vanilla).
- Power feed runs every tick, `Battery` → every `Crusher`, using `fe::`.

> **Mekanism gotcha:** unlike the AE2/ExtendedAE machines above, Mekanism
> blocks expose **per-face IO configuration** — the colored side config
> screen, opened by right-clicking the machine with the Configurator. A
> face that isn't explicitly set to accept Energy won't receive power
> even though the block has the capability and even if a cable/manager
> is physically touching it. Before the power feed does anything: open
> each Crusher's side config, set at least one face to accept Energy
> (red by default), and point your SFM energy cable/manager at that
> specific face.

---

## `cc-tweaked/jarvis.lua`

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

## `cc-tweaked/status.lua`

One-shot diagnostic dump. Prints everything it can find; missing
peripherals or features just print "not present" instead of erroring —
every peripheral call is wrapped in `pcall`.

Covers: system info, turtle fuel/inventory/equipped upgrades/GPS,
every attached peripheral by name and type, storage bridge totals +
network energy, energy detector reading, nearby players, chat box
presence, and redstone levels on all 6 sides.

Run with: `status`

---

## `cc-tweaked/paste.lua`

A line-buffered paste receiver for the turtle terminal. CC:Tweaked's
built-in `edit` can choke on large pastes or drop characters under load;
this reads raw lines instead and writes them straight to a file.

```
paste <filename>
```

Type or paste your code, then end with a line containing only `:done`.

---

## `tools/type-into-mc.ps1` / `type-clipboard.bat`

The nuclear option: when in-game paste isn't reliable and typing 300+
lines by hand isn't happening, this reads your **clipboard** on the
Windows side and injects it into whatever window has focus, character by
character, as fast as your CPU can push `SendInput` calls.

```
powershell -File .\tools\type-into-mc.ps1
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

- **SFM has no `POWER` keyword, and `forge:energy` is not the energy
  resource.** Energy is a *scalar* resource type, referenced with the
  literal `fe::` (or `rf::`/`energy::`/`power::` — all four alias to the
  same `forge_energy` type internally). Writing `forge:energy` instead
  parses as an item lookup for a nonexistent item and silently moves
  nothing — no error, it just never fires. Confirmed against the
  bundled `resource_types.sfml` template and the parser bytecode
  (`ResourceIdentifier`'s constructor literally special-cases
  `["fe","rf","energy","power"]`).
- **`OUTPUT ALL <resource> TO ...` isn't valid grammar.** `ALL` expects
  `TO` or `EXCEPT` immediately after it — the in-game parser error is
  `mismatched input '<resource>' expecting {TO, EXCEPT}`. To move every
  unit of a resource, just omit `ALL` entirely: the `::` wildcard in
  `fe::`/`fluid::` already means "everything of this type."
- **Mekanism machines need an explicit side qualifier for energy.**
  Unlike AE2/ExtendedAE blocks, Mekanism's per-face IO config means a
  cable/manager touching an unconfigured face won't deliver power even
  though the capability exists. SFM supports targeting a specific face
  directly — `<label> <direction> side` right after the label (see the
  bundled `slots_and_sides.sfml` template) — and it has to match
  whichever face you set to accept Energy in Mekanism's Configurator.
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

---

<div align="center">

**Wakanda Forever.**

</div>
