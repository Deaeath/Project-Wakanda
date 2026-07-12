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
├── sfm/                        Super Factory Manager programs (.sfml), one subfolder per mod
│   ├── extendedae/
│   ├── advancedae/
│   └── mekanism/
├── cc-tweaked/                 CC:Tweaked turtle/computer programs (.lua)
└── tools/                      Local Windows helper tools (.ps1 / .bat)
```

| Callsign | File | Role |
|----------|------|------|
| **Forge** | [`sfm/extendedae/crystal_assembler.sfml`](#sfmextendedaecrystal_assemblersfml) | ExtendedAE Crystal Assembler automation + self-feeding power |
| **Cutter** | [`sfm/extendedae/circuit_cutter.sfml`](#sfmextendedaecircuit_cuttersfml) | ExtendedAE Circuit Cutter automation + self-feeding power |
| **Chamber** | [`sfm/advancedae/reaction_chamber.sfml`](#sfmadvancedaereaction_chambersfml) | AdvancedAE Reaction Chamber automation + self-feeding power |
| **Crusher** | [`sfm/mekanism/crusher.sfml`](#sfmmekanismcrushersfml) | Mekanism Crusher — every crushing recipe in the pack + self-feeding power |
| **Dissolver** | [`sfm/mekanism/chemical_dissolution_chamber.sfml`](#sfmmekanismchemical_dissolution_chambersfml) | 5x ore processing step 1/7: ore/raw material → dirty slurry |
| **Washer** | [`sfm/mekanism/chemical_washer.sfml`](#sfmmekanismchemical_washersfml) | 5x ore processing step 2/7: dirty slurry → clean slurry |
| **Crystallizer** | [`sfm/mekanism/chemical_crystallizer.sfml`](#sfmmekanismchemical_crystallizersfml) | 5x ore processing step 3/7: clean slurry → crystal |
| **Injector** | [`sfm/mekanism/chemical_injection_chamber.sfml`](#sfmmekanismchemical_injection_chambersfml) | 5x ore processing step 4/7: crystal → shard |
| **Purifier** | [`sfm/mekanism/purification_chamber.sfml`](#sfmmekanismpurification_chambersfml) | 5x ore processing step 5/7: shard → clump |
| **Enricher** | [`sfm/mekanism/enrichment_chamber.sfml`](#sfmmekanismenrichment_chambersfml) | 5x ore processing step 7/7: dirty dust → dust (+ misc enriching recipes) |
| **Alchemist** | [`sfm/mekanism/chemical_infuser.sfml`](#sfmmekanismchemical_infusersfml) | Produces the Sulfuric Acid / Hydrogen Chloride the ore chain consumes |
| **Alloyer** | [`sfm/mekanism/metallurgic_infuser.sfml`](#sfmmekanismmetallurgic_infusersfml) | Alloy tiers + mossy-block/misc infusion recipes (all 19, source-verified) |
| **Combiner** | [`sfm/mekanism/combiner.sfml`](#sfmmekanismcombinersfml) | Dye mixing, copper waxing, misc combos (all 53, wildcarded) |
| **Jarvis** | [`cc-tweaked/jarvis.lua`](#cc-tweakedjarvislua) | Base assistant — chat commands, alarms, live dashboard |
| **Griot** | [`cc-tweaked/status.lua`](#cc-tweakedstatuslua) | On-demand diagnostic report for any turtle or computer |
| **Scribe** | [`cc-tweaked/paste.lua`](#cc-tweakedpastelua) | In-game paste receiver, for when `edit` chokes |
| **Lift** | [`cc-tweaked/elevator.lua`](#cc-tweakedelevatorlua) | Turtle-pushed vertical lift, chat-commanded by floor name |
| **Sentry** | [`cc-tweaked/patrol.lua`](#cc-tweakedpatrollua) | Turtle patrol loop with Player Detector intruder alarm |
| **Kimoyo** | [`tools/type-into-mc.ps1`](#toolstype-into-mcps1--type-clipboardbat) | Local clipboard-to-game injector |

---

> **Power feeds target a specific face on purpose.** Every `.sfml`
> program below reads/writes energy via an explicit `TOP SIDE`
> qualifier on both `Battery` and the machine label, not just a bare
> label reference. This is required for Mekanism (see the gotcha under
> `crusher.sfml`) and is good practice everywhere else too — pin it to
> whichever face you actually wired for power, on every machine and the
> battery itself.

## `sfm/extendedae/crystal_assembler.sfml`

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
  every `Assembler`. **Two traps found the hard way, both confirmed
  against `SFMServerConfig`'s bytecode:** `forge:energy` isn't the
  resource — that parses as an item lookup and silently moves nothing —
  and a bare `INPUT FROM Battery` with no resource literal defaults to
  `sfm:item:*:*`. That second one matters twice over: it pulls *items*
  instead of energy, **and** it disqualifies the trigger block from
  SFM's lower "forge-energy-only" minimum interval (default 1 tick),
  falling back to the general minimum (default 20 ticks) instead — which
  is why `EVERY 1 TICKS` gets rejected with "Minimum trigger interval is
  20 ticks" until the resource literal is explicit on *both* sides:
  `INPUT fe:: FROM Battery` / `OUTPUT fe:: TO EACH X`.
- Recipes needing fluids (budding, entro_ingot, fluix_transformation,
  redstone_crystal, sky_bronze/steel/osmium) need water or lava piped in
  separately — SFM doesn't move fluids in this program.
- Each assembler must be configured to its recipe via the machine GUI
  (typically an AE2 Pattern Provider assigning it a specific pattern).
- **Each recipe is gated behind `IF Barrel has gt 0 <signature item>`**
  and every ingredient targets an explicit `SLOTS` index. Slot indices
  are **not verified** against the Assembler's real container class —
  they're assigned sequentially per recipe and need in-game confirmation
  (open the GUI mid-craft, check the numbers match). A few recipes share
  generic ingredients (`capacity_card`, `concurrent_processor`, `piston`,
  `charged_certus_quartz_crystal`) that can't be fully disambiguated by a
  single signature item — those use an `AND`-combined condition instead;
  see the in-file comments for which.
- **`TO Assembler ROUND ROBIN BY BLOCK`, not `TO EACH Assembler`.**
  Confirmed against the official bundled `round_robin.sfml` example:
  `TO EACH X` broadcasts to every matching block simultaneously every
  execution; `TO X ROUND ROBIN BY BLOCK` targets exactly one, rotating
  which one on each subsequent pulse. The original broadcast approach
  stuffed every recipe's ingredients into every Assembler at once,
  fighting the Pattern Provider over slot occupancy and breaking builds.
- **Periodic unjam trigger** (`EVERY 100 TICKS`): drains every
  Assembler's input slots (0-8) **out to Storage** (not back to the
  Barrel — draining to Barrel just fed wrong items right back into the
  next pulse's supply, often onto a *different* Assembler than the one
  they came from, since neither SFM nor the broadcast/round-robin
  targeting has any memory of which machine an item originated from).
  Fixes machines stuck holding leftover/wrong ingredients; move an item
  back from Storage to Barrel manually if it turns out to still be
  needed. Tradeoff: it can't distinguish "wrong leftover items" from
  "correct items about to finish a craft" — if a craft takes longer than
  100 ticks, this will interrupt it repeatedly and it'll never complete.
  Lengthen the interval past your actual craft time, or remove the block
  once machines stop getting stuck.

---

## `sfm/extendedae/circuit_cutter.sfml`

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

## `sfm/advancedae/reaction_chamber.sfml`

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

## `sfm/mekanism/crusher.sfml`

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

## The 5x ore processing chain (`chemical_dissolution_chamber.sfml` → `enrichment_chamber.sfml`)

Six more programs cover Mekanism's full 5x ore processing line for all 7
base metals (iron, gold, copper, lead, osmium, tin, uranium) — every step
source-verified against `data/mekanism/recipe/processing/<metal>/*.json`
in the Mekanism jar, not guessed from memory:

| Step | Program | Machine | Transform |
|------|---------|---------|-----------|
| 1/7 | `chemical_dissolution_chamber.sfml` | Chemical Dissolution Chamber | ore/raw material + Sulfuric Acid → dirty slurry |
| 2/7 | `chemical_washer.sfml` | Chemical Washer | dirty slurry + water → clean slurry |
| 3/7 | `chemical_crystallizer.sfml` | Chemical Crystallizer | clean slurry → crystal |
| 4/7 | `chemical_injection_chamber.sfml` | Chemical Injection Chamber | crystal + Hydrogen Chloride → shard |
| 5/7 | `purification_chamber.sfml` | Purification Chamber | shard + Oxygen → clump |
| 6/7 | `crusher.sfml` | Crusher | clump → dirty dust (already covered above) |
| 7/7 | `enrichment_chamber.sfml` | Enrichment Chamber | dirty dust → dust (smelts to ingot) |

**Chain it end to end:** each program's output `Storage` label feeds the
next program's input `Barrel` label — point them at the same physical
chest/barrel to run the whole line unattended.

**Chemicals are a resource type too**, same as items/fluids/energy —
`chemical:mekanism:sulfuric_acid` targets one specific gas,
`chemical::` (wildcard) matches any Mekanism chemical regardless of
which metal produced it. Confirmed via `ChemicalResourceType` in the SFM
jar, registered only when Mekanism is loaded (`SFMMekanismCompat`).

**Known gaps, called out honestly:** the exact inventory slot index used
for each machine's item OUTPUT (`SLOTS n`) was pattern-matched from
`crusher.sfml`, not independently verified against each machine's
container class — those base classes are shared/generic and didn't
expose slot layout through simple decompilation. If items stop draining,
open that machine's GUI in-game, note the real output slot position,
and adjust the `SLOTS` number. Everything else — recipe inputs/outputs,
resource type syntax, chemical amounts — is source-verified.

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

## `cc-tweaked/elevator.lua`

A turtle sitting in a vertical shaft that pushes you along when it
moves — a real vertical lift, not a simulation.

**Source-verified:** CC:Tweaked turtles can push entities on movement
using the same `PushReaction` mechanism vanilla pistons use — confirmed
via `dan200.computercraft.shared.turtle.core.TurtleMoveCommand.canPushEntities()`
and `dan200.computercraft.shared.config.Config.turtlesCanPush` (defaults
to enabled). If your server has `turtlesCanPush` disabled, this won't
push you at all — check that first if it doesn't work, before assuming
the script is broken.

**Build requirements:**
- A clear vertical shaft (turtle's own column, minimum) spanning every
  floor you want to stop at.
- The turtle sitting in that shaft, powered, with the Chat Box turtle
  upgrade (see `jarvis.lua`'s notes on why this has to be a crafted
  upgrade, not an adjacent block).
- Fuel in the turtle's inventory.

**Configure `FLOORS`** at the top of the file — each entry is `{name,
height}`, where height is blocks from the bottom of the shaft (where the
turtle starts). Edit to match your actual base.

**Chat commands:** `elevator floor <name>`, `elevator floors`,
`elevator status`, `elevator resync <name>` (manually correct the
turtle's tracked position if a move gets interrupted mid-shaft and it
loses track of which floor it's actually on).

---

## `cc-tweaked/patrol.lua`

Walks a turtle around a defined loop, watching for non-trusted players
via a Player Detector and sounding an alarm — same trust-list convention
as `jarvis.lua`.

**No GPS required.** The route is a relative step sequence (forward N,
turn, forward N...) starting from wherever the turtle is placed and
facing when the program first runs, not absolute coordinates. If you set
up GPS satellites later this could be upgraded to `gps.locate()`-based
waypoints for a route that self-corrects; until then, an obstruction the
turtle can't clear leaves it stuck rather than rerouting around it.

**Configure `ROUTE`** at the top of the file as a sequence of
`{"forward", N}` / `{"turn_left"}` / `{"turn_right"}` / `{"wait", N}`
steps forming a closed loop back to the start. Also configure
`TRUSTED_PLAYERS` — same convention as `jarvis.lua`; keep them in sync
if you run both.

**Notes:**
- Digs through obstructions in its path — the route is assumed to run
  through territory you control. If it ever passes anywhere a player
  could wall it off maliciously, this will tunnel through that too.
- The alarm-clear logic is time-based (`os.clock()`), not event-driven —
  this script is synchronous via `sleep()` while walking, unlike
  `jarvis.lua`'s event loop, so it can't `os.pullEvent("timer")` without
  risking a hang mid-route.

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

<div align="center">

**Wakanda Forever.**

</div>
