-- Space Elevator Recipe Prototype
-- Expensive recipe requiring late-game materials from multiple planets

data:extend({
  {
    type = "recipe",
    name = "space-elevator",
    enabled = false,  -- Unlocked via technology
    energy_required = 120,  -- 2 minutes to craft
    ingredients = {
      -- Base materials (Nauvis)
      {type = "item", name = "steel-plate", amount = 2000},
      {type = "item", name = "processing-unit", amount = 500},
      {type = "item", name = "electric-engine-unit", amount = 200},
      {type = "item", name = "low-density-structure", amount = 500},

      -- Vulcanus materials
      {type = "item", name = "tungsten-plate", amount = 500},

      -- Fulgora materials
      {type = "item", name = "superconductor", amount = 200},

      -- Gleba materials
      {type = "item", name = "bioflux", amount = 200},

      -- Space materials
      {type = "item", name = "rocket-fuel", amount = 100},
    },
    results = {
      {type = "item", name = "space-elevator", amount = 1}
    },
    category = "crafting",  -- May need to be "advanced-crafting" or custom category
  }
})

-- Note: Phase 1 uses standard rocket-part recipe for launches
-- The space elevator only requires 1 rocket part per launch vs 100 for rocket silo
-- This makes it much cheaper to operate
--
-- Future phases might add a custom "elevator-cargo-pod" that's even cheaper
-- and could be tied to the space elevator via the fixed_recipe property
