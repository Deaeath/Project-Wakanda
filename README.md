# SFM Programs — ATM10

Super Factory Manager programs for All the Mods 10.

## Programs

### `crystal_assembler.sfml`
Automates all ExtendedAE Crystal Assembler recipes.

**Labels to assign:**
| Label | Block |
|-------|-------|
| `Barrel` | Input chest/barrel with all ingredients |
| `Assembler` | All Crystal Assembler machines |
| `Storage` | Output storage |

**Notes:**
- Recipes that need fluids (budding, entro_ingot, fluix_transformation, redstone_crystal, sky_bronze/steel/osmium) require water or lava piped in separately — SFM does not handle fluids here
- Each assembler must be configured to its recipe via the machine GUI

---

### `circuit_cutter.sfml`
Automates the ExtendedAE Circuit Cutter (one cutter per recipe).

**Labels to assign:**
| Label | Block | Produces |
|-------|-------|----------|
| `Barrel` | Input chest/barrel | — |
| `SlicerCalc` | Circuit Cutter | printed_calculation_processor |
| `SlicerLogic` | Circuit Cutter | printed_logic_processor |
| `SlicerEng` | Circuit Cutter | printed_engineering_processor |
| `SlicerSi` | Circuit Cutter | printed_silicon |
| `SlicerConc` | Circuit Cutter | concurrent_processor_print |
| `SlicerAccum` | Circuit Cutter | printed_accumulation_processor *(megacells)* |
| `SlicerEnergy` | Circuit Cutter | printed_energy_processor *(appflux)* |
| `Storage` | Output storage | — |

**Notes:**
- Input slot is SLOTS 0, output slot is SLOTS 1
- Uncomment the megacells/appflux lines in the program if those mods are present
