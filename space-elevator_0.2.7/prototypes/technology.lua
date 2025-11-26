-- Space Elevator Technology Prototype
-- Late-game tech requiring cryogenic science

data:extend({
  {
    type = "technology",
    name = "space-elevator",
    icon = "__base__/graphics/technology/rocket-silo.png",  -- Reuse for Phase 1
    icon_size = 256,
    effects = {
      {
        type = "unlock-recipe",
        recipe = "space-elevator"
      },
      {
        type = "unlock-recipe",
        recipe = "space-elevator-dock"
      },
      {
        type = "unlock-recipe",
        recipe = "space-elevator-dock-fluid-tank"
      }
    },
    prerequisites = {
      "rocket-silo",
      -- Require late-game techs to ensure this is end-game content
      "cryogenic-science-pack",  -- Requires visiting multiple planets (Aquilo)
    },
    unit = {
      count = 2000,
      ingredients = {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1},
        {"chemical-science-pack", 1},
        {"production-science-pack", 1},
        {"utility-science-pack", 1},
        {"space-science-pack", 1},
        {"metallurgic-science-pack", 1},  -- Vulcanus
        {"electromagnetic-science-pack", 1},  -- Fulgora
        {"agricultural-science-pack", 1},  -- Gleba
        {"cryogenic-science-pack", 1},  -- Aquilo
      },
      time = 60
    },
    localised_name = {"technology-name.space-elevator"},
    localised_description = {"technology-description.space-elevator"},
  }
})
