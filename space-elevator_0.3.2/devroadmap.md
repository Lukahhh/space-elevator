# Space Elevator Mod - Development Roadmap

## Overview

A Factorio 2.0 / Space Age mod that adds space elevators to planets, providing an alternative late-game logistics solution for transferring items between planetary surfaces and space platforms.

**Core Concept:** An expensive, multi-stage construction that acts as a fast, low-cost (or free) rocket silo alternative for late-game players.

**Current Version:** 0.2.4

---

## Design Pillars

1. **Late-Game Exclusive** - Inaccessible in early/mid game through tech gates and resource requirements
2. **High Investment, Low Operating Cost** - Expensive to build and maintain, but cheaper per-launch than rockets
3. **Balanced Alternative** - Complements rockets rather than replacing them entirely
4. **Mod Compatibility** - Works alongside other mods in modpacks

---

## Phase 1: Core Prototype - COMPLETE

### Goals
- [x] Basic space elevator entity that functions as a modified rocket silo
- [x] Single-stage construction (refinement in later phases)
- [x] Item transfer TO space platforms only
- [x] Basic technology research requirement

### Technical Tasks
- [x] Create prototype entity based on rocket silo
- [x] Define basic recipe and crafting requirements
- [x] Implement technology unlock (Cryogenic Science Pack)
- [x] Create placeholder graphics/sprites (uses rocket silo graphics)
- [x] Test basic item transfer functionality
- [x] Verify platform detection and delivery

### Implementation Notes
- Entity: `space-elevator` based on `rocket-silo` prototype
- Only 1 rocket part required per launch (vs 100 for standard silo)
- 10MW constant power consumption
- Technology requires Cryogenic Science Pack (all 4 planets visited)
- Uses companion chest system to bypass rocket cargo weight limits

---

## Phase 2: Multi-Stage Construction - COMPLETE

### Goals
- [x] Implement staged construction system
- [x] Add foundation/excavation phase
- [x] Add structural construction phases
- [x] Add final assembly/activation phase

### Construction Stages (Implemented)

```
Stage 1: Site Preparation
├── Excavate foundation
├── Resource cost: 500 Stone, 1000 Concrete, 500 Steel Plate
└── Time: 30 seconds

Stage 2: Foundation Construction
├── Build anchor point and base structure
├── Resource cost: 2000 Refined Concrete, 1000 Steel, 500 Gears, 200 Pipes
└── Time: 45 seconds

Stage 3: Tower Assembly
├── Construct main elevator shaft
├── Resource cost: Materials from multiple planets
│   ├── Nauvis: 500 Processing Units, 200 Electric Engines, 500 LDS
│   ├── Vulcanus: 500 Tungsten Plate
│   ├── Fulgora: 200 Superconductors
│   └── Gleba: 100 Bioflux
└── Time: 60 seconds

Stage 4: Tether Deployment
├── Deploy space tether to orbit
├── Resource cost: 1000 LDS, 100 Accumulators, 500 Rocket Fuel
└── Time: 45 seconds

Stage 5: Activation & Calibration
├── Power up and synchronize with platforms
├── Resource cost: 200 Processing Units, 100 Superconductors, 200 Rocket Fuel
└── Time: 30 seconds
```

### Technical Implementation
- [x] Construction phase state machine in `construction-stages.lua`
- [x] Per-stage resource requirements
- [x] Progress indicators/GUI elements via entity-gui-lib
- [x] Handle construction interruption/resumption
- [x] Companion chest (48 slots) for construction materials
- [x] Debug button for testing (skips construction)

---

## Phase 3: Balance & Restrictions - PARTIAL

### Goals
- [ ] Implement elevator placement limits
- [ ] Add ongoing maintenance system
- [x] Balance energy consumption
- [x] Fine-tune resource costs

### Placement Restrictions
**Status:** Not yet implemented
- Option A: 1 elevator per planet surface (simplest) - PREFERRED
- Option B: Minimum distance between elevators
- Option C: 1 elevator per X chunks

### Energy Requirements
- [x] Constant power draw: 10MW
- [ ] Additional power per launch (not implemented)
- [ ] Brownout/failure behavior (not implemented)

### Maintenance System
**Status:** Not yet implemented - deferred to future version

### Technical Tasks
- [ ] Implement surface-wide elevator tracking
- [ ] Add placement validation logic
- [ ] Create maintenance consumption system
- [ ] Design failure/degradation states
- [x] Balance testing across game stages

---

## Phase 4: Advanced Features - COMPLETE

### Goals
- [x] Bidirectional transfer (receive from platforms)
- [x] Platform docking station entity
- [x] Fluid transfer capability
- [x] Player transport

### Platform Docking Station - COMPLETE
- [x] New entity `space-elevator-dock` placed on space platforms
- [x] Required to "dock" with planetary elevator
- [x] Enables bidirectional item/fluid transfer
- [x] Visual indicator of connection status in GUI
- [x] Custom GUI with 48-slot inventory display

### Bidirectional Item Transfer - COMPLETE
- [x] Upload items from surface to platform
- [x] Download items from platform to surface
- [x] Manual transfer with configurable rate
- [x] Automatic transfer modes (continuous upload/download)
- [x] Per-elevator transfer rate selector (10/25/50/100/250 items per cycle)
- [x] Energy cost system (10kJ per item transferred)
- [x] Transfer tab in elevator GUI with energy display

### Fluid Transfer - COMPLETE
- [x] Eliminates need for barreling
- [x] Elevator fluid tank (spawns 6 tiles north, visible)
- [x] Dock fluid tank (place within 5 tiles of dock)
- [x] Manual fluid transfer (1000 units per click)
- [x] Fluid status display in GUI

### Player Transport - COMPLETE
- [x] Fast travel between surface and platform
- [x] 3-second travel time with countdown
- [x] Works in both directions
- [x] Travel tab in elevator GUI

### Technical Implementation
- [x] `platform-controller.lua` - Platform detection, docking, connection management
- [x] `transfer-controller.lua` - Item and fluid transfer logic
- [x] `player-transport.lua` - Player teleportation with transit state
- [x] Auto-connect when single platform orbits
- [x] Manual selection for multiple platforms
- [x] Connection validation (auto-disconnect when platform leaves orbit)
- [x] GUI tabs: Docking, Transfer, Travel

---

## Phase 5: Polish & Compatibility - IN PROGRESS

### Goals
- [ ] Final graphics and animations
- [ ] Sound design
- [ ] GUI improvements
- [ ] Mod compatibility layer
- [ ] Localization (additional languages)

### Graphics & Audio
- [ ] Elevator base sprite (multiple stages)
- [ ] Tether/cable visual
- [x] Launch/transfer animation (beam effect via LuaRendering)
- [x] Beam width scales with transfer rate (visual feedback for transfer volume)
- [x] Persistent beams during continuous transfers
- [ ] Ambient operation sounds
- [ ] Transfer initiation/completion sounds

### Transfer Visual Effects
**Goal:** Display a visual "beam" effect when items/fluids transfer between elevator and platform.

**Limitation:** Rocket silo doors cannot be opened programmatically - `rocket_silo_status` is read-only and door animation is tied to launch sequence.

**Implementation Options:**

#### Option 1: LuaRendering.draw_line() - SELECTED FOR INITIAL IMPLEMENTATION
- Simple colored beam shooting upward from elevator during transfers
- No prototype changes required (runtime only)
- Customizable color (blue for upload, orange for download)
- Set `time_to_live` for automatic fade
- Can add width/dash effects for visual flair
- Example:
  ```lua
  rendering.draw_line{
    surface = elevator.surface,
    from = elevator.position,
    to = {elevator.position.x, elevator.position.y - 50},
    color = {r = 0, g = 0.5, b = 1, a = 0.8},
    width = 4,
    time_to_live = 30,
  }
  ```

#### Option 2: BeamPrototype Entity (Future)
- Create custom `BeamPrototype` in data.lua
- More realistic beam with head/tail/body segments
- Can reuse laser turret graphics as base
- Requires `surface.create_entity{name="beam", source=..., target=...}`
- More complex but better visual quality

#### Option 3: LuaRendering.draw_animation() (Future)
- Create custom animation sprite sheet
- Most polished appearance
- Requires artwork creation
- Can animate beam intensity, particles, etc.

### Current Status
- Using rocket silo placeholder graphics
- Using steel chest graphics for dock
- Using storage tank graphics for fluid tanks
- English localization complete

### Mod Compatibility
- [ ] Define API for resource additions
- [ ] Test with popular modpacks
- [ ] Add settings for mod integration
- [ ] Document compatibility features

### Technical Tasks
- [ ] Commission/create final artwork
- [ ] Implement animations
- [ ] Add configuration options
- [ ] Create mod API documentation
- [ ] Additional localization files

---

## Implemented File Structure

```
space-elevator_0.2.3/
├── info.json
├── data.lua
├── control.lua
├── changelog.txt
├── devroadmap.md
├── README.md
├── locale/
│   └── en/
│       └── locale.cfg
├── prototypes/
│   ├── entity.lua      # Elevator, dock, fluid tanks, companion chest
│   ├── item.lua        # All items
│   ├── recipe.lua      # All recipes
│   └── technology.lua  # Tech unlock
└── scripts/
    ├── elevator-controller.lua    # Core elevator logic
    ├── construction-stages.lua    # 5-stage construction system
    ├── platform-controller.lua    # Docking and platform management
    ├── transfer-controller.lua    # Item and fluid transfers
    ├── player-transport.lua       # Player teleportation
    └── visual-effects.lua         # Transfer beam rendering (Phase 5)
```

---

## Dependencies

- **Factorio Base** >= 2.0
- **Space Age DLC** >= 2.0
- **entity-gui-lib** >= 0.1.0 (custom GUI framework)

---

## Milestones

### Milestone 1: Proof of Concept - COMPLETE
- [x] Basic working elevator (modified rocket silo)
- [x] Sends items to platform
- [x] Placeholder graphics

### Milestone 2: Playable Alpha - COMPLETE
- [x] Multi-stage construction
- [ ] Placement restrictions (deferred)
- [ ] Basic maintenance (deferred)
- [x] Placeholder graphics

### Milestone 3: Feature Complete Beta - COMPLETE
- [x] All core features implemented
- [x] Bidirectional transfer
- [x] Docking station
- [x] Fluid transfer
- [x] Player transport
- [x] Balance pass complete

### Milestone 4: Release Candidate - IN PROGRESS
- [ ] Final graphics and audio
- [ ] Full localization
- [ ] Mod compatibility tested
- [ ] Documentation complete

### Milestone 5: Public Release
- [ ] Mod portal upload
- [ ] Community feedback integration
- [ ] Bug fixes

---

## Future Consideration: Direct Hub Integration

**Status:** Investigated (2025-11-27) - Not yet implemented

### Overview

Currently, the space elevator uses a custom `space-elevator-dock` entity (a 48-slot chest) placed on space platforms. An alternative approach would be to interact directly with the vanilla space platform hub's inventory, eliminating the need for the dock entity entirely.

### Technical Feasibility: CONFIRMED

The Factorio 2.0 API supports direct hub inventory access:

```lua
-- Get the hub from a platform surface
local platform = entity.surface.platform  -- LuaSpacePlatform
local hub = platform and platform.hub      -- The hub entity (can be nil!)

-- Get the hub's inventory
local hub_inventory = hub:get_inventory(defines.inventory.hub_main)

-- Insert/remove items
hub_inventory:insert({name = "iron-plate", count = 100})
hub_inventory:remove({name = "iron-plate", count = 50})
```

### Key API Elements

| API | Description |
|-----|-------------|
| `surface.platform` | Returns `LuaSpacePlatform` if surface is a space platform |
| `platform.hub` | Returns the hub entity (nil if starter pack not applied or hub destroyed) |
| `defines.inventory.hub_main` | Inventory constant for hub's main storage |
| `hub:get_inventory()` | Standard `LuaEntity` method |
| `inventory:insert()` / `inventory:remove()` | Standard `LuaInventory` methods |

### Architecture Comparison

| Aspect | Current (Dock) | Direct Hub |
|--------|----------------|------------|
| Platform entity | `space-elevator-dock` required | None needed |
| Inventory access | `dock.get_inventory(defines.inventory.chest)` | `hub:get_inventory(defines.inventory.hub_main)` |
| Player setup | Must place dock on platform | Automatic - just connect |
| Automation | Inserters at dock location | Inserters at hub (vanilla) |
| Complexity | Moderate | Simpler |

### Implementation Changes Required

If implementing direct hub integration:

1. **`transfer-controller.lua`**: Change `get_dock_inventory()` to use `hub:get_inventory(defines.inventory.hub_main)`
2. **`platform-controller.lua`**: Remove dock validation, store hub reference instead
3. **Remove**: `space-elevator-dock` entity prototype, item, recipe
4. **GUI**: Update to show hub inventory status instead of dock

### Important Considerations

1. **Hub Availability**: `platform.hub` returns `nil` if:
   - Starter pack hasn't been applied yet
   - Hub has been destroyed (platform deletes at end of tick)

2. **Inventory Capacity**: Hub has 65,535 slot limit; cargo bays extend this

3. **User Experience Trade-off**:
   - Pro: Simpler setup, no extra entity to place
   - Con: Players may expect a dedicated "landing area" for the elevator

4. **Mod Conflicts**: Direct hub access might conflict with other mods that manipulate hub inventory

### Reference Mods Using This Pattern

- [Hub Extensions](https://github.com/daviscook477/hub-extensions) - Uses `defines.inventory.hub_main`
- [Hub Inventory Unlocked](https://github.com/Sopel97/hub_inventory_unlocked) - Script-managed hub inventory

### Decision

**TBD** - Keep current dock system for explicit player control, or switch to direct hub integration for simplicity.

---

## Known Issues / Future Work

1. **Existing elevators need rebuild** - Fluid tank position change requires rebuilding elevator
2. **No placement limits** - Multiple elevators can be built per planet (Phase 3 incomplete)
3. **No maintenance system** - Deferred to future version
4. **Placeholder graphics** - Using base game assets

---

## Version History

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-26 | 0.2.4 | Full inserter support via visible cargo chest (6 tiles south) |
| 2025-11-26 | 0.2.3 | Per-elevator transfer rate selector, energy cost system |
| 2025-11-26 | 0.2.2 | Phase 5 started - Transfer beam visual effects |
| 2025-11-26 | 0.2.1 | Bug fixes, fluid UI, dock GUI improvements |
| 2025-11-26 | 0.2.0 | Phase 4 complete - Docking, transfers, player transport |
| 2025-11-26 | 0.1.0 | Initial release - Phases 1 & 2 complete |

---

*This document is a living roadmap and will be updated as development progresses.*
