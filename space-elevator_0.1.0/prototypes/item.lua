-- Space Elevator Item Prototype

data:extend({
  {
    type = "item",
    name = "space-elevator",
    icon = "__base__/graphics/icons/rocket-silo.png",  -- Reuse rocket silo icon for Phase 1
    icon_size = 64,
    subgroup = "space-related",
    order = "b[rocket-silo]-b[space-elevator]",  -- Place after rocket silo in menu
    place_result = "space-elevator",
    stack_size = 1,
    weight = 10000000,  -- Very heavy, 10 tons
  }
})
