-- Space Elevator Entity Prototype
-- Based on rocket silo but modified for fast, cheap launches
--
-- Phase 1 Limitations:
-- - Uses standard rocket parts (but only 1 required per launch)
-- - Reuses rocket silo graphics
-- - Launch mechanics are same as rocket silo

-- Get settings values
local power_consumption = settings.startup["space-elevator-power-consumption"].value
local rocket_parts = settings.startup["space-elevator-rocket-parts"].value
local fluid_tank_capacity = settings.startup["space-elevator-fluid-tank-capacity"].value

-- Copy the rocket silo as our base
local space_elevator = table.deepcopy(data.raw["rocket-silo"]["rocket-silo"])

-- Rename and rebrand
space_elevator.name = "space-elevator"
space_elevator.minable.result = "space-elevator"

-- Key difference: Configurable rocket parts required per launch
-- This makes launches much cheaper than standard rocket silo (100 parts)
space_elevator.rocket_parts_required = rocket_parts

-- Configurable energy consumption (late game should have power infrastructure)
space_elevator.energy_usage = power_consumption .. "MW"  -- Significant constant draw vs 250kW for rocket silo

-- Increase inventory size for construction materials
-- Default rocket silo has very limited cargo space, we need more for construction stages
space_elevator.rocket_result_inventory_size = 20  -- 20 slots for construction materials (default is 1)

-- Update localised name/description references
space_elevator.localised_name = {"entity-name.space-elevator"}
space_elevator.localised_description = {"entity-description.space-elevator"}

-- Create a custom rocket entity with higher weight capacity for construction materials
local elevator_rocket = table.deepcopy(data.raw["rocket-silo-rocket"]["rocket-silo-rocket"])
elevator_rocket.name = "space-elevator-rocket"

-- Increase the cargo weight capacity significantly
-- Default rockets have limited weight for space cargo, we need much more for construction
if elevator_rocket.inventory_size then
  elevator_rocket.inventory_size = 40  -- More slots
end

-- Increase weight capacity if this property exists
if elevator_rocket.weight_capacity then
  elevator_rocket.weight_capacity = 1000000000  -- 1 billion kg capacity
end

-- Try cargo_weight_capacity for Space Age rockets
if elevator_rocket.cargo_weight_capacity then
  elevator_rocket.cargo_weight_capacity = 1000000000
end

data:extend({elevator_rocket})

-- Link the space elevator to use our custom rocket
space_elevator.rocket_entity = "space-elevator-rocket"

-- Also try increasing the silo's own weight capacity if it has one
if space_elevator.cargo_weight_capacity then
  space_elevator.cargo_weight_capacity = 1000000000
end

data:extend({space_elevator})

-- ============================================================================
-- Companion Chest for Construction Materials / Cargo
-- ============================================================================
-- This chest spawns 3 tiles south of the elevator and holds construction materials
-- and cargo items. Visible and accessible by inserters for automation.

local construction_chest = table.deepcopy(data.raw["container"]["steel-chest"])
construction_chest.name = "space-elevator-chest"
construction_chest.inventory_size = 48  -- Large inventory for all construction materials
construction_chest.minable = nil  -- Cannot be mined separately (linked to elevator)
construction_chest.localised_name = {"entity-name.space-elevator-chest"}
construction_chest.localised_description = {"entity-description.space-elevator-chest"}

-- Use steel chest graphics (visible to player, inserters can interact)
-- Keep default collision_mask and selectable_in_game for normal chest behavior
construction_chest.icon = "__base__/graphics/icons/steel-chest.png"
construction_chest.icon_size = 64

data:extend({construction_chest})

-- ============================================================================
-- Platform Docking Station (Phase 4)
-- ============================================================================
-- This entity is placed on space platforms to connect with planetary elevators.
-- Allows bidirectional item and fluid transfer between surface and platform.

local docking_station = table.deepcopy(data.raw["container"]["steel-chest"])
docking_station.name = "space-elevator-dock"
docking_station.inventory_size = 48  -- Match elevator chest capacity
docking_station.minable = {mining_time = 1, result = "space-elevator-dock"}
docking_station.max_health = 500
docking_station.localised_name = {"entity-name.space-elevator-dock"}
docking_station.localised_description = {"entity-description.space-elevator-dock"}

-- Allow placement on space platforms (remove surface restrictions from steel-chest)
docking_station.surface_conditions = nil

-- Visual distinction from regular chests
-- For now, use steel chest graphics - can be replaced with custom sprites later
docking_station.icon = "__base__/graphics/icons/roboport.png"
docking_station.icon_size = 64

-- Circuit connections for logistics integration
docking_station.circuit_wire_connection_point = data.raw["container"]["steel-chest"].circuit_wire_connection_point
docking_station.circuit_wire_max_distance = 9

data:extend({docking_station})

-- ============================================================================
-- Companion Fluid Tank for Elevator (Phase 4.5)
-- ============================================================================
-- This tank spawns north of the elevator for fluid transfers.
-- Positioned outside the elevator footprint so pipes can connect.

local elevator_fluid_tank = table.deepcopy(data.raw["storage-tank"]["storage-tank"])
elevator_fluid_tank.name = "space-elevator-fluid-tank"
elevator_fluid_tank.minable = nil  -- Cannot be mined separately (linked to elevator)
elevator_fluid_tank.max_health = 500
elevator_fluid_tank.fluid_box = {
  volume = fluid_tank_capacity,  -- Configurable capacity
  pipe_connections = {
    {flow_direction = "input-output", direction = defines.direction.north, position = {0, -1}},
    {flow_direction = "input-output", direction = defines.direction.south, position = {0, 1}},
    {flow_direction = "input-output", direction = defines.direction.east, position = {1, 0}},
    {flow_direction = "input-output", direction = defines.direction.west, position = {-1, 0}},
  },
}
elevator_fluid_tank.localised_name = {"entity-name.space-elevator-fluid-tank"}
elevator_fluid_tank.localised_description = {"entity-description.space-elevator-fluid-tank"}

-- Use standard storage tank graphics (visible to player)
-- Icon to help identify it
elevator_fluid_tank.icon = "__base__/graphics/icons/storage-tank.png"
elevator_fluid_tank.icon_size = 64

data:extend({elevator_fluid_tank})

-- ============================================================================
-- Dock Fluid Tank (Phase 4.5)
-- ============================================================================
-- Visible storage tank placed with the dock for fluid transfers on platform side.

local dock_fluid_tank = table.deepcopy(data.raw["storage-tank"]["storage-tank"])
dock_fluid_tank.name = "space-elevator-dock-fluid-tank"
dock_fluid_tank.minable = {mining_time = 0.5, result = "space-elevator-dock-fluid-tank"}
dock_fluid_tank.max_health = 300
dock_fluid_tank.fluid_box = {
  volume = fluid_tank_capacity,  -- Match elevator tank (configurable)
  pipe_connections = {
    {flow_direction = "input-output", direction = defines.direction.north, position = {0, -1}},
    {flow_direction = "input-output", direction = defines.direction.south, position = {0, 1}},
  },
}
dock_fluid_tank.localised_name = {"entity-name.space-elevator-dock-fluid-tank"}
dock_fluid_tank.localised_description = {"entity-description.space-elevator-dock-fluid-tank"}

data:extend({dock_fluid_tank})

-- ============================================================================
-- Transfer Beam Animation (Visual Effects)
-- ============================================================================
-- Animated lightning beam sprite for item/fluid transfers between
-- surface elevator and orbital platform.

data:extend({
  {
    type = "animation",
    name = "space-elevator-beam-blue",
    filename = "__space-elevator__/graphics/beam-animation.png",
    width = 128,
    height = 256,
    frame_count = 32,
    line_length = 8,
    animation_speed = 0.5,  -- 30 fps (0.5 frames per tick at 60 ticks/sec)
    scale = 0.5,            -- Scale down for better fit
    blend_mode = "additive",
    draw_as_glow = true,
    flags = {"no-crop"},
  },
  -- Orange tinted version for downloads (will apply tint at runtime)
  {
    type = "animation",
    name = "space-elevator-beam-orange",
    filename = "__space-elevator__/graphics/beam-animation.png",
    width = 128,
    height = 256,
    frame_count = 32,
    line_length = 8,
    animation_speed = 0.5,
    scale = 0.5,
    blend_mode = "additive",
    draw_as_glow = true,
    tint = {r = 1.0, g = 0.6, b = 0.2, a = 1.0},  -- Orange tint
    flags = {"no-crop"},
  },
  -- Cyan version for fluid transfers
  {
    type = "animation",
    name = "space-elevator-beam-cyan",
    filename = "__space-elevator__/graphics/beam-animation.png",
    width = 128,
    height = 256,
    frame_count = 32,
    line_length = 8,
    animation_speed = 0.5,
    scale = 0.5,
    blend_mode = "additive",
    draw_as_glow = true,
    tint = {r = 0.2, g = 1.0, b = 1.0, a = 1.0},  -- Cyan tint
    flags = {"no-crop"},
  },
})
