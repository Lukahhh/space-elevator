# Space Elevator Entity Refactor Plan

## Overview

Change the space elevator from a `rocket-silo` base to an `assembling-machine` base to:
1. Eliminate the misleading "Item ingredient shortage" message
2. Allow direct inserter access (remove companion chest)
3. Allow direct pipe connections (remove companion fluid tank)
4. Provide a cleaner, more intuitive player experience

## Current Architecture

### Entity: `space-elevator` (based on `rocket-silo`)
- 9x9 footprint with rocket silo graphics
- Energy buffer for transfer costs
- **NOT USED**: Rocket part crafting, cargo pod launches

### Companion Entities (spawned at runtime):
- `space-elevator-chest` - 6 tiles south, holds items for construction/transfers
- `space-elevator-fluid-tank` - 6 tiles north, holds fluids for transfers

### Properties Currently Used:
- `entity.energy` - read/write for transfer energy costs
- `entity.electric_buffer_size` - max energy (for GUI display)
- `entity.surface`, `entity.position`, `entity.force`, `entity.unit_number`, `entity.valid` - standard

### Properties NOT Used:
- Rocket part crafting system (source of "Item ingredient shortage")
- Rocket launching mechanics
- Cargo inventory (we use the companion chest instead)

---

## Proposed Architecture

### New Entity: `space-elevator` (based on `assembling-machine`)

**Why assembling-machine?**
- Has `fluid_boxes` for direct pipe connections
- Has input/output inventories for direct inserter access
- Has energy buffer/consumption
- Can use custom graphics
- Can be set to have no recipe (idle state)

### Key Properties:

```lua
{
  type = "assembling-machine",
  name = "space-elevator",

  -- Size & Graphics (reuse rocket-silo visuals)
  collision_box = {{-4.4, -4.4}, {4.4, 4.4}},  -- 9x9
  selection_box = {{-4.5, -4.5}, {4.5, 4.5}},
  -- Graphics copied from rocket-silo prototype

  -- Energy
  energy_source = {
    type = "electric",
    usage_priority = "secondary-input",
    buffer_capacity = "100MJ",  -- Configurable
  },
  energy_usage = "10MW",  -- Configurable (idle draw)

  -- Direct Inventory Access (replaces companion chest)
  inventory_size = 48,  -- Same as current chest
  -- Or use ingredient_count / result_inventory_size

  -- Direct Fluid Access (replaces companion fluid tank)
  fluid_boxes = {
    {
      volume = 25000,  -- Configurable
      pipe_connections = {
        {flow_direction = "input-output", direction = defines.direction.north, position = {0, -4}},
        {flow_direction = "input-output", direction = defines.direction.south, position = {0, 4}},
      },
    },
  },

  -- No recipe required (acts as storage/transfer station)
  fixed_recipe = nil,
  crafting_speed = 1,
  crafting_categories = {"space-elevator"},  -- Empty category
}
```

---

## Files to Modify

### 1. `prototypes/entity.lua`
- [ ] Change base from `rocket-silo` to `assembling-machine`
- [ ] Copy rocket-silo graphics (animations, working_visualisations, etc.)
- [ ] Add `fluid_boxes` for direct pipe connections
- [ ] Configure inventory slots for direct inserter access
- [ ] Set up energy source/buffer
- [ ] Remove `space-elevator-chest` prototype (no longer needed)
- [ ] Remove `space-elevator-fluid-tank` prototype (no longer needed)
- [ ] Create empty crafting category `space-elevator` (required for assembling-machine)

### 2. `prototypes/recipe.lua` (new or modify)
- [ ] Add crafting category definition for `space-elevator`

### 3. `scripts/elevator-controller.lua`
- [ ] Remove `spawn_construction_chest()` function
- [ ] Remove `spawn_fluid_tank()` function
- [ ] Remove chest/tank references from `on_elevator_built()`
- [ ] Remove chest/tank cleanup from `on_elevator_removed()`
- [ ] Update `get_construction_chest()` to return entity inventory directly
- [ ] Update elevator_data structure (remove `chest` and `fluid_tank` fields)

### 4. `scripts/construction-stages.lua`
- [ ] Update `get_inventory()` to work with assembling-machine inventory
- [ ] Change from `defines.inventory.chest` to appropriate assembling-machine inventory type

### 5. `scripts/transfer-controller.lua`
- [ ] Update item transfer functions to use entity inventory directly
- [ ] Update fluid transfer functions to use entity fluidbox directly
- [ ] Remove references to companion chest/tank
- [ ] Update `get_inventory_status()` for new inventory type
- [ ] Update `get_fluid_status()` for direct fluidbox access

### 6. `control.lua`
- [ ] Update GUI to reference entity inventory/fluidbox directly
- [ ] Remove migration code for companion chest positioning
- [ ] Update any chest/tank validity checks

---

## Migration Strategy

For existing saves with the old rocket-silo based elevator:

### Option A: Force Rebuild (Simple)
- Detect old elevators on configuration_changed
- Print warning message to players
- Old elevators continue to (partially) work until replaced
- New elevators use new system

### Option B: Auto-Migration (Complex)
- On configuration_changed, for each existing elevator:
  1. Save contents of companion chest to temp storage
  2. Save contents of companion fluid tank to temp storage
  3. Destroy companion entities
  4. The entity itself changes type automatically (Factorio handles this)
  5. Insert saved items into new entity inventory
  6. Insert saved fluids into new entity fluidbox
- Risk: Entity type change may not work seamlessly

### Recommendation: Option A
- Simpler and safer
- Players can rebuild elevators at their convenience
- Construction is relatively quick with debug button available

---

## Inventory Type Investigation Needed

Assembling machines have multiple inventory types:
- `defines.inventory.assembling_machine_input`
- `defines.inventory.assembling_machine_output`
- `defines.inventory.assembling_machine_modules`

**Question**: Can we have a single unified inventory for both input AND output (like a chest)?

**Alternatives if not**:
- Use `container` type with energy interface overlay entity
- Use custom inventory handling via script
- Accept split input/output inventories

---

## Testing Checklist

- [ ] Entity places correctly with 9x9 footprint
- [ ] Rocket silo graphics display correctly
- [ ] Inserters can insert items directly
- [ ] Inserters can extract items directly
- [ ] Pipes connect directly to entity
- [ ] Fluids flow in/out correctly
- [ ] Energy consumption works
- [ ] Construction stages work with direct inventory
- [ ] Item transfers work (up/down)
- [ ] Fluid transfers work (up/down)
- [ ] Auto-transfer modes work
- [ ] Visual beam effects still work
- [ ] Player transport still works
- [ ] No "Item ingredient shortage" or similar messages appear
- [ ] Old saves load without crashing (graceful degradation)

---

## Open Questions

1. **Graphics complexity**: Rocket silo has complex layered graphics with animations. How much of this can we reuse on an assembling-machine?

2. **Inventory behavior**: Do we want items to be freely insertable/extractable, or should there be any restrictions during construction vs operational phases?

3. **Fluid mixing**: With direct fluid connections, should we support multiple fluid types or restrict to one at a time?

4. **Entity size**: Assembling machines are typically smaller. Will a 9x9 assembling machine work correctly?

5. **Surface placement**: Need to verify assembling-machine can be placed on all surfaces (Nauvis, Vulcanus, etc.) - may need to clear `surface_conditions`.

---

## Estimated Scope

- **Prototype changes**: Medium complexity (graphics copying is the main challenge)
- **Script changes**: Medium complexity (mostly simplification - removing companion entity logic)
- **Testing**: High - many interactions to verify
- **Migration**: Low complexity if using Option A

Total estimate: Moderate refactor, primarily in prototype definition and simplifying runtime scripts.
