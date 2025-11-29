# Space Elevator

**A late-game alternative to rockets for transferring items, fluids, and players between planets and space platforms.**

---

## What is this mod?

Space Elevator adds a new mega-structure to Factorio 2.0 / Space Age: a planetary space elevator that connects your surface base directly to orbiting space platforms. Once constructed, it provides fast, energy-efficient transfers without the constant rocket part consumption of traditional silos.

**Key Features:**
- **Bidirectional item transfer** - Upload and download items between surface and platform
- **Fluid transfer** - Move fluids without barreling (direct pipe-to-pipe)
- **Player transport** - Fast travel between surface and orbit (3 seconds)
- **Configurable transfer rates** - Choose your throughput (10 to 250 items per cycle)
- **Visual feedback** - Colored beams indicate active transfers

---

## How It Works

### 1. Research & Build

Research **Space Elevator** technology (requires Cryogenic Science Pack - you'll need to have visited all 4 planets).

Place the **Space Elevator Construction Kit** on any planet surface to begin construction.

### 2. Multi-Stage Construction

The elevator requires 5 construction stages, each needing materials from across the galaxy:

| Stage | Name | Key Materials |
|-------|------|---------------|
| 1 | Site Preparation | Stone, Concrete, Steel |
| 2 | Foundation | Refined Concrete, Gears, Pipes |
| 3 | Tower Assembly | Processing Units, LDS, Tungsten, Superconductors, Bioflux |
| 4 | Tether Deployment | LDS, Accumulators, Rocket Fuel |
| 5 | Activation | Processing Units, Superconductors, Rocket Fuel |

Insert materials into the elevator's inventory and click **Begin Construction** for each stage.

### 3. Platform Docking

Build a **Space Elevator Dock** on your space platform while it orbits the planet. Open the elevator GUI on the surface and connect via the **Docking** tab.

- Single platform? Auto-connects!
- Multiple platforms? Choose from a dropdown.

### 4. Transfer Items & Fluids

Use the **Transfer** tab to move cargo:

- Select your **transfer rate** (10, 25, 50, 100, or 250 items per cycle)
- Click **Upload/Download** for manual transfers
- Enable **Auto-Upload/Download** for continuous operation
- Higher rates = wider beams = more energy consumption

**Fluid Transfer:**
- Surface: Connect pipes to the fluid tank (6 tiles north of elevator)
- Platform: Place a **Dock Fluid Tank** within 5 tiles of the dock

### 5. Player Travel

Use the **Travel** tab to teleport between surface and platform. 3-second travel time, no special equipment needed!

---

## Balance

| Aspect | Value |
|--------|-------|
| Base Power Draw | 10 MW constant |
| Transfer Energy | 10 kJ per item |
| Rocket Parts | 1 per launch (vs 100 for standard silo) |
| Tech Requirement | Cryogenic Science Pack |
| Construction | Materials from all 4 planets |

### Transfer Rate Energy Costs

| Rate | Energy/Cycle | Throughput |
|------|-------------|------------|
| 10 items | 100 kJ | 20 items/sec |
| 25 items | 250 kJ | 50 items/sec |
| 50 items | 500 kJ | 100 items/sec |
| 100 items | 1 MJ | 200 items/sec |
| 250 items | 2.5 MJ | 500 items/sec |

---

## Customisation Options

The mod includes several settings to tailor the experience to your playstyle. Access these via **Settings > Mod Settings**.

### Startup Settings (require restart)

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| Power Consumption | 10 MW | 1-100 | Base power draw when operational |
| Rocket Parts Required | 1 | 1-100 | Parts needed per launch (vanilla silo uses 100) |
| Fluid Tank Capacity | 25,000 | 1k-100k | Capacity of elevator and dock fluid tanks |
| Construction Time Multiplier | 1.0x | 0.1-10x | Speed up (0.5) or slow down (2.0) construction |
| Material Cost Multiplier | 1.0x | 0.1-10x | Reduce (0.5) or increase (2.0) material requirements |

### Runtime Settings (change anytime)

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| Manual Item Transfer | 10 | 1-1000 | Items per manual upload/download click |
| Auto Transfer Rate | 10 | 1-1000 | Default rate for new auto-transfers |
| Manual Fluid Transfer | 1,000 | 100-10k | Fluid per manual transfer click |
| Travel Time | 3 sec | 1-30 | Player transport duration |

### Debug Mode: Skip Construction

Want to test the mod's features without waiting through construction? Or just want to have some fun?

1. Go to **Settings > Mod Settings > Map**
2. Enable **"Show Debug Button"**
3. Open any space elevator's GUI
4. Click the red **[DEBUG] Complete Construction** button in the Construction tab

This instantly completes all 5 construction stages, making the elevator fully operational. Great for testing, exploring features, or if you just want to skip straight to the space logistics!

---

## Requirements

- **Factorio 2.0** or later
- **Space Age DLC**
- **[Entity GUI Library](https://mods.factorio.com/mod/entity-gui-lib)** (required dependency)

---

## Early Access Notice

**This mod is a proof of concept and is still in active development.**

### What this means:

- **Bugs may occur** - Please report any issues you encounter
- **Balance is not final** - Costs and rates may change based on feedback
- **Features may change** - The API and behavior could evolve
- **Placeholder graphics** - Currently uses base game assets (rocket silo, storage tank, steel chest)

### Dependencies

This mod relies heavily on **[Entity GUI Library](https://mods.factorio.com/mod/entity-gui-lib)** for its custom GUI system. Both mods are developed together and may have interdependent updates.

---

## Visual Effects

The transfer beam effects (colored lines showing item/fluid movement) are functional but **not final**:

- Blue beam = Item upload
- Orange beam = Item download
- Cyan beam = Fluid upload
- Dark orange beam = Fluid download
- Beam width scales with transfer rate

**Artists Wanted!** If you're interested in contributing custom sprites, animations, or visual effects for the space elevator, I'd love to hear from you! The mod currently uses placeholder graphics and would benefit greatly from dedicated artwork.

---

## Feedback & Bug Reports

Feedback is very welcome! This is an early release and community input helps shape development.

**Please report:**
- Bugs and crashes
- Balance concerns
- Feature suggestions
- Compatibility issues with other mods

**GitHub Issues:** [Report bugs and suggestions here](https://github.com/your-repo/space-elevator/issues)

---

## Known Issues

- Fluid tank position changed in v0.2.1 - older elevators need rebuilding for fluid access
- No placement limits yet - multiple elevators can be built per planet
- Uses placeholder graphics throughout
- May have unexpected interactions with other mods

---

## Changelog (Recent)

### 0.2.3
- Per-elevator transfer rate selector (10/25/50/100/250 items per cycle)
- Energy cost system (10kJ per item transferred)
- Beam width scales with transfer rate
- Live energy display in Transfer tab

### 0.2.2
- Transfer beam visual effects on both surface and platform
- Different colors for upload/download and item/fluid transfers
- Dynamic platform edge detection for beam positioning

### 0.2.1
- Fluid transfer UI improvements
- Custom dock GUI with full inventory display
- Various bug fixes

### 0.2.0
- Platform docking system
- Bidirectional item/fluid transfer
- Player transport

---

## Credits

- **Author:** Lukah
- **Dependencies:** Entity GUI Library
- **Inspired by:** Factorio Space Age, real-world space elevator concepts

---

## Links

- [GitHub Repository](https://github.com/your-repo/space-elevator)
- [Entity GUI Library](https://mods.factorio.com/mod/entity-gui-lib)
- [Bug Reports](https://github.com/your-repo/space-elevator/issues)

---

*Thank you for trying Space Elevator! Your feedback helps make this mod better.*
