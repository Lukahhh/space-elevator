-- Space Elevator Recipe Prototype
-- The initial recipe is for the "construction site" - actual materials are added during staged construction

data:extend({
  {
    type = "recipe",
    name = "space-elevator",
    enabled = false,  -- Unlocked via technology
    energy_required = 30,  -- 30 seconds to craft the foundation kit
    ingredients = {
      -- Base construction site materials
      -- Relatively affordable to place the site - real cost is in the 5 construction stages
      {type = "item", name = "steel-plate", amount = 500},
      {type = "item", name = "concrete", amount = 500},
      {type = "item", name = "processing-unit", amount = 100},
      {type = "item", name = "electric-engine-unit", amount = 50},
    },
    results = {
      {type = "item", name = "space-elevator", amount = 1}
    },
    category = "crafting",
  }
})

-- Note: The space elevator uses a 5-stage construction process
-- Materials for each stage are inserted directly into the elevator and consumed
-- See scripts/construction-stages.lua for full material requirements:
--
-- Stage 1 (Site Preparation): Stone, Concrete, Steel
-- Stage 2 (Foundation): Refined Concrete, Steel, Gears, Pipes
-- Stage 3 (Tower Assembly): Processing Units, Electric Engines, LDS, Tungsten, Superconductors, Bioflux
-- Stage 4 (Tether Deployment): Carbon Fiber, Supercapacitors, Rocket Fuel
-- Stage 5 (Activation): Processing Units, Superconductors, Rocket Fuel

-- ============================================================================
-- Platform Docking Station Recipe (Phase 4)
-- ============================================================================
data:extend({
  {
    type = "recipe",
    name = "space-elevator-dock",
    enabled = false,  -- Unlocked via technology (same as space elevator)
    energy_required = 10,  -- 10 seconds to craft
    ingredients = {
      -- Late-game materials for platform-side dock
      {type = "item", name = "steel-plate", amount = 100},
      {type = "item", name = "processing-unit", amount = 50},
      {type = "item", name = "low-density-structure", amount = 20},
      {type = "item", name = "superconductor", amount = 10},
    },
    results = {
      {type = "item", name = "space-elevator-dock", amount = 1}
    },
    category = "crafting",
  },
  -- Dock Fluid Tank (Phase 4.5)
  {
    type = "recipe",
    name = "space-elevator-dock-fluid-tank",
    enabled = false,
    energy_required = 5,
    ingredients = {
      {type = "item", name = "steel-plate", amount = 50},
      {type = "item", name = "iron-plate", amount = 20},
      {type = "item", name = "pipe", amount = 10},
    },
    results = {
      {type = "item", name = "space-elevator-dock-fluid-tank", amount = 1}
    },
    category = "crafting",
  }
})
