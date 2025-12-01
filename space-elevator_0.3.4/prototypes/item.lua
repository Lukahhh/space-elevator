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
  },
  -- Platform Docking Station (Phase 4)
  {
    type = "item",
    name = "space-elevator-dock",
    icon = "__base__/graphics/icons/roboport.png",  -- Placeholder icon
    icon_size = 64,
    subgroup = "space-related",
    order = "b[rocket-silo]-c[space-elevator-dock]",  -- Place after space elevator in menu
    place_result = "space-elevator-dock",
    stack_size = 10,
    weight = 100000,  -- 100kg
  },
  -- Dock Fluid Tank (Phase 4.5)
  {
    type = "item",
    name = "space-elevator-dock-fluid-tank",
    icon = "__base__/graphics/icons/storage-tank.png",
    icon_size = 64,
    subgroup = "space-related",
    order = "b[rocket-silo]-d[space-elevator-dock-fluid-tank]",
    place_result = "space-elevator-dock-fluid-tank",
    stack_size = 10,
    weight = 50000,  -- 50kg
  },
  {
    type = "item",
    name = "space-elevator-cable",
    icon = "__space-elevator__/graphics/space-elevator-cable.png",
    icon_size = 64,
    subgroup = "space-related",
    order = "d[rocket-parts]-d[space-elevator-cable]",
    stack_size = 1000,
    weight = 1 * kg
  }
})
