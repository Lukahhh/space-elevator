# Space Elevator Mod - Development Roadmap

## Overview

A Factorio 2.0 / Space Age mod that adds space elevators to planets, providing an alternative late-game logistics solution for transferring items between planetary surfaces and space platforms.

**Core Concept:** An expensive, multi-stage construction that acts as a fast, low-cost (or free) rocket silo alternative for late-game players.

---

## Design Pillars

1. **Late-Game Exclusive** - Inaccessible in early/mid game through tech gates and resource requirements
2. **High Investment, Low Operating Cost** - Expensive to build and maintain, but cheaper per-launch than rockets
3. **Balanced Alternative** - Complements rockets rather than replacing them entirely
4. **Mod Compatibility** - Works alongside other mods in modpacks

---

## Phase 1: Core Prototype

### Goals
- [ ] Basic space elevator entity that functions as a modified rocket silo
- [ ] Single-stage construction (refinement in later phases)
- [ ] Item transfer TO space platforms only
- [ ] Basic technology research requirement

### Technical Tasks
- [ ] Create prototype entity based on rocket silo
- [ ] Define basic recipe and crafting requirements
- [ ] Implement technology unlock (Cryogenic Science or higher)
- [ ] Create placeholder graphics/sprites
- [ ] Test basic item transfer functionality
- [ ] Verify platform detection and delivery

### Success Criteria
- Player can build elevator, load items, and send to orbiting platform
- Transfer is faster than standard rocket launch
- No launch cost (or minimal cost)

---

## Phase 2: Multi-Stage Construction

### Goals
- [ ] Implement staged construction system (similar to Rocket-Silo Construction mod)
- [ ] Add foundation/excavation phase
- [ ] Add structural construction phases
- [ ] Add final assembly/activation phase

### Proposed Construction Stages

```
Stage 1: Site Preparation
├── Excavate foundation (large area clearing)
├── Resource cost: Stone, Concrete, Steel
└── Time: Significant

Stage 2: Foundation Construction
├── Build anchor point and base structure
├── Resource cost: Refined Concrete, Steel, Advanced materials
└── Time: Moderate

Stage 3: Tower Assembly
├── Construct main elevator shaft
├── Resource cost: Materials from multiple planets
│   ├── Nauvis: Steel, Processing Units
│   ├── Vulcanus: Tungsten, Calcite
│   ├── Fulgora: Holmium, Superconductors
│   └── Gleba: Bioflux, Biter Eggs(?)
└── Time: Extended

Stage 4: Tether Deployment
├── Deploy space tether to orbit
├── Resource cost: Carbon Fiber, Supercapacitors
└── Time: Moderate

Stage 5: Activation & Calibration
├── Power up and synchronize with platforms
├── Resource cost: Quality components(?)
└── Time: Short
```

### Technical Tasks
- [ ] Research staged construction implementation methods
- [ ] Create construction phase state machine
- [ ] Design intermediate entity states/graphics
- [ ] Implement per-stage resource requirements
- [ ] Add progress indicators/GUI elements
- [ ] Handle construction interruption/resumption

---

## Phase 3: Balance & Restrictions

### Goals
- [ ] Implement elevator placement limits
- [ ] Add ongoing maintenance system
- [ ] Balance energy consumption
- [ ] Fine-tune resource costs

### Placement Restrictions (Choose One - TBD)
- **Option A:** 1 elevator per planet surface (simplest)
- **Option B:** Minimum distance between elevators (e.g., 2000 tiles)
- **Option C:** 1 elevator per X chunks claimed/developed

### Energy Requirements
- [ ] Define constant power draw (substantial - MW range)
- [ ] Define additional power per launch
- [ ] Implement brownout/failure behavior

### Maintenance System (TBD - See Open Questions)
- [ ] Define maintenance resource types
- [ ] Define consumption rate
- [ ] Implement degradation/failure states

### Technical Tasks
- [ ] Implement surface-wide elevator tracking
- [ ] Add placement validation logic
- [ ] Create maintenance consumption system
- [ ] Design failure/degradation states
- [ ] Balance testing across game stages

---

## Phase 4: Advanced Features

### Goals
- [ ] Bidirectional transfer (receive from platforms)
- [ ] Platform docking station entity
- [ ] Fluid transfer capability
- [ ] Player transport

### Platform Docking Station
- New entity placed on space platforms
- Required to "dock" with planetary elevator
- Enables bidirectional item/fluid transfer
- Visual indicator of connection status

### Fluid Transfer
- Eliminates need for barreling
- Requires docking station on both ends
- Throughput balanced against barrel logistics

### Player Transport
- Fast travel between surface and platform
- Possible health/suit requirements
- Animation/transition effect

### Technical Tasks
- [ ] Create docking station entity and prototype
- [ ] Implement platform-to-surface item routing
- [ ] Add fluid transfer capability
- [ ] Implement player teleportation
- [ ] Handle edge cases (platform moving, multiple elevators)

---

## Phase 5: Polish & Compatibility

### Goals
- [ ] Final graphics and animations
- [ ] Sound design
- [ ] GUI improvements
- [ ] Mod compatibility layer
- [ ] Localization

### Graphics & Audio
- [ ] Elevator base sprite (multiple stages)
- [ ] Tether/cable visual
- [ ] Launch/transfer animation
- [ ] Ambient operation sounds
- [ ] Transfer initiation/completion sounds

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
- [ ] Localization file structure

---

## Open Questions (To Be Decided)

### Placement & Limits

| Question | Options | Notes |
|----------|---------|-------|
| Elevator limit per surface? | 1 / Multiple / Distance-based | Affects balance significantly |
| Minimum distance between elevators? | None / 1000 / 2000 / 3000 tiles | Only if multiple allowed |
| Allow on all planet types? | Yes / Only base planets / Configurable | Consider modded planets |

### Functionality

| Question | Options | Notes |
|----------|---------|-------|
| Bidirectional transfer? | Send only / Send & Receive / Configurable | Complexity vs utility |
| Require docking station on platform? | Yes / No / Optional for receiving | Adds another entity to manage |
| Fluid transfer support? | Yes / No | Eliminates barrel meta |
| Player transport? | Yes / No / Separate upgrade | Quality of life feature |
| Cargo capacity vs rockets? | Same / Smaller / Larger / Configurable | Smaller + faster = different use case |

### Costs & Maintenance

| Question | Options | Notes |
|----------|---------|-------|
| Per-launch cost? | Free / Minimal / Significant | Core to balance |
| Maintenance system? | Constant drain / Per-use / Random events / None | Complexity consideration |
| Failure mode? | Stops working / Collapses / Two-stage degradation | Consequences matter |
| Energy consumption? | Constant only / Constant + per-launch / Massive per-launch | Power infrastructure requirement |

### Platform Interaction

| Question | Options | Notes |
|----------|---------|-------|
| Multiple elevators + cargo pad behavior? | Priority system / Player choice / Nearest | Edge case handling |
| Platform in transit behavior? | Queue items / Refuse / Auto-route to next | What if platform leaves orbit? |

---

## Technical Reference

### Factorio 2.0 / Space Age APIs to Investigate

- `rocket-silo` prototype modifications
- Space platform detection and interaction
- Surface-specific entity limits
- Multi-stage construction patterns
- Cross-surface item transfer mechanisms
- Custom GUI implementation

### Similar Mods for Reference

- **Rocket Silo Construction** - Multi-stage building pattern
- **Space Exploration** - Space elevator concept (different implementation)
- **Various logistics mods** - Cross-surface transfer patterns

### File Structure (Proposed)

```
space-elevator/
├── info.json
├── data.lua
├── data-updates.lua
├── data-final-fixes.lua
├── control.lua
├── settings.lua
├── changelog.txt
├── thumbnail.png
├── locale/
│   └── en/
│       └── locale.cfg
├── prototypes/
│   ├── entity.lua
│   ├── item.lua
│   ├── recipe.lua
│   ├── technology.lua
│   └── docking-station.lua
├── scripts/
│   ├── elevator-controller.lua
│   ├── construction-stages.lua
│   ├── maintenance.lua
│   ├── platform-interface.lua
│   └── compatibility.lua
└── graphics/
    ├── entity/
    ├── icons/
    └── gui/
```

---

## Milestones

### Milestone 1: Proof of Concept
- Basic working elevator (modified rocket silo)
- Sends items to platform
- No fancy graphics needed

### Milestone 2: Playable Alpha
- Multi-stage construction
- Placement restrictions
- Basic maintenance
- Placeholder graphics

### Milestone 3: Feature Complete Beta
- All core features implemented
- Bidirectional transfer (if decided)
- Docking station (if decided)
- Balance pass complete

### Milestone 4: Release Candidate
- Final graphics and audio
- Full localization
- Mod compatibility tested
- Documentation complete

### Milestone 5: Public Release
- Mod portal upload
- Community feedback integration
- Bug fixes

---

## Resources & Links

- [Factorio Modding Wiki](https://wiki.factorio.com/Modding)
- [Factorio API Documentation](https://lua-api.factorio.com/latest/)
- [Factorio Forums - Modding](https://forums.factorio.com/viewforum.php?f=82)
- [Space Age DLC Documentation](https://factorio.com/blog/) (check dev blogs)

---

## Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2024-XX-XX | 0.0.1 | Initial roadmap created |

---

*This document is a living roadmap and will be updated as development progresses and decisions are made on open questions.*
