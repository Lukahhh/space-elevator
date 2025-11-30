# Space Elevator

A Factorio 2.0 / Space Age mod that adds space elevators to planets, providing a late-game alternative to rocket launches for transferring items, fluids, and players between planetary surfaces and orbiting space platforms.

## Features

### Multi-Stage Construction
Build your space elevator through 5 construction stages, each requiring materials from across the galaxy:

1. **Site Preparation** - Stone, Concrete, Steel Plate
2. **Foundation Construction** - Refined Concrete, Steel, Gears, Pipes
3. **Tower Assembly** - Processing Units, Electric Engines, LDS, Tungsten (Vulcanus), Superconductors (Fulgora), Bioflux (Gleba)
4. **Tether Deployment** - Low Density Structures, Accumulators, Rocket Fuel
5. **Activation** - Processing Units, Superconductors, Rocket Fuel

### Platform Docking
- Place a **Space Elevator Dock** on your orbiting space platform
- Connect the surface elevator to the platform dock
- Auto-connects when only one platform is in orbit
- Manual selection when multiple platforms orbit the same planet
- Automatic disconnection when platform leaves orbit

### Bidirectional Item Transfer
- **Upload** items from surface to platform
- **Download** items from platform to surface
- **Configurable transfer rate** - Choose 10, 25, 50, 100, or 250 items per cycle
- Manual and automatic transfer modes
- **Energy cost** - 10kJ per item transferred (higher rates = more power)
- **Visual feedback** - Beam width scales with transfer rate
- 48-slot cargo storage on both ends
- **Full inserter support** - Visible cargo chest (6 tiles south) for inserter input/output

### Fluid Transfer
- Transfer fluids without barreling
- **Surface:** Connect pipes to the fluid tank (spawns 6 tiles north of elevator)
- **Platform:** Place a Dock Fluid Tank within 5 tiles of the dock
- 25,000 unit capacity on each end
- Manual transfer (1000 units per click)

### Player Transport
- Fast travel between surface and platform
- 3-second travel time
- Works in both directions
- No special equipment required

## Requirements

- **Factorio** 2.0 or later
- **Space Age DLC**
- **[Entity GUI Library](https://mods.factorio.com/mod/entity-gui-lib)** 0.1.0 or later

## Installation

1. Download from the Factorio Mod Portal (coming soon) or manually install
2. Ensure Entity GUI Library is also installed
3. Enable both mods in your save

## How to Use

### Building the Elevator

1. Research **Space Elevator** technology (requires Cryogenic Science Pack)
2. Craft and place the **Space Elevator Construction Kit**
3. Open the elevator GUI and view the **Construction** tab
4. Insert required materials for Stage 1 into the elevator's inventory
5. Click **Begin Construction** when materials are ready
6. Repeat for all 5 stages
7. Once complete, the elevator becomes operational

### Connecting to a Platform

1. Build a **Space Elevator Dock** on your space platform (while it orbits the planet)
2. Open the elevator GUI on the surface
3. Go to the **Docking** tab
4. Click **Connect** (auto-connects if only one platform has a dock)
5. Status shows "Connected" when successful

### Transferring Items

1. Insert items into the elevator's cargo storage (Materials tab)
2. Go to the **Transfer** tab
3. **Set transfer rate** using the dropdown (10, 25, 50, 100, or 250 items/cycle)
4. Click **Upload** or **Download** for manual transfers
5. Or enable **Auto-Upload/Download** for continuous transfers
6. Monitor energy cost - higher rates consume more power (10kJ per item)

### Using Inserters

The elevator has a visible cargo chest 6 tiles south that supports full inserter automation:
- **Input inserters:** Point inserters at the cargo chest to deposit items
- **Output inserters:** Point inserters away from the cargo chest to extract items
- Works during construction (for materials) and when operational (for cargo)
- Combine with auto-transfer for fully automated surface-to-platform logistics
- The cargo chest contents appear in the elevator's GUI Materials/Cargo tab

### Transferring Fluids

1. **Surface Setup:**
   - Find the fluid tank 6 tiles north of the elevator
   - Connect pipes and pump fluid into the tank

2. **Platform Setup:**
   - Place a **Dock Fluid Tank** within 5 tiles of the dock
   - Connect pipes to extract/inject fluids

3. **Transfer:**
   - Use the Transfer tab's fluid buttons to move fluids
   - "Upload 1000" sends fluid up, "Download 1000" brings it down

### Player Travel

1. Ensure elevator is connected to a platform
2. Go to the **Travel** tab
3. Click **Travel to Platform** or **Travel to Surface**
4. Wait 3 seconds for transit to complete

## Entity Summary

| Entity | Description | Placement |
|--------|-------------|-----------|
| Space Elevator | Main structure for surface-to-orbit transfers | Planet surface |
| Space Elevator Dock | Platform-side docking station | Space platform |
| Dock Fluid Tank | Fluid storage for platform transfers | Near dock on platform |

## Balance

- **Power:** 10MW constant consumption + 10kJ per item transferred
- **Transfer Rates:** 10/25/50/100/250 items per cycle (every 0.5 seconds)
- **Launch Cost:** Only 1 rocket part per launch (vs 100 for standard silo)
- **Construction:** Requires materials from all 4 planets
- **Technology:** Cryogenic Science Pack required

### Transfer Energy Costs
| Rate | Energy per Cycle | Items/Second |
|------|-----------------|--------------|
| 10   | 100 kJ          | 20           |
| 25   | 250 kJ          | 50           |
| 50   | 500 kJ          | 100          |
| 100  | 1 MJ            | 200          |
| 250  | 2.5 MJ          | 500          |

## Tips

- The elevator's cargo inventory persists - great for staging materials
- Use auto-transfer for hands-off logistics
- Fluids don't need barreling - direct pipe-to-pipe transfer
- Player transport is instant (after 3s countdown) - faster than rockets
- Connection auto-validates - if platform leaves orbit, it disconnects
- **Cargo chest is 6 tiles south** - use inserters for automated material delivery or cargo loading
- **Fluid tank is 6 tiles north** - connect pipes for fluid transfers

## Known Issues

- Fluid tank position changed in 0.2.1 - existing elevators from before 0.2.1 need rebuilding for fluid access
- Cargo chest auto-migrates to new position (6 tiles south) on version upgrade
- Currently no limit on elevators per planet (balance feature pending)
- Uses placeholder graphics (rocket silo, steel chest, storage tank)

## Roadmap

See [devroadmap.md](devroadmap.md) for detailed development status.

**Completed:**
- Phase 1: Core Prototype
- Phase 2: Multi-Stage Construction
- Phase 4: Advanced Features (Docking, Transfers, Player Transport)

**In Progress:**
- Phase 3: Balance & Restrictions (placement limits)
- Phase 5: Polish (custom graphics, sounds)

## Credits

- **Author:** Lukah
- **Dependencies:** Entity GUI Library
- **Inspired by:** Factorio Space Age, real-world space elevator concepts

## License

MIT License - See LICENSE file for details.

## Links

- [Factorio Mod Portal](#) (coming soon)
- [GitHub Repository](https://github.com/your-repo/space-elevator)
- [Bug Reports & Feature Requests](https://github.com/your-repo/space-elevator/issues)
