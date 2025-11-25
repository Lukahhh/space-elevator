-- Space Elevator Mod - Runtime Control
-- Handles runtime logic for space elevator operation

local elevator_controller = require("scripts.elevator-controller")

-- Initialize mod data on game start
script.on_init(function()
  storage.space_elevators = storage.space_elevators or {}
  storage.elevator_count_per_surface = storage.elevator_count_per_surface or {}
end)

-- Handle save game loading
script.on_load(function()
  -- Re-register any conditional event handlers if needed
end)

-- Handle configuration changes (mod updates, etc.)
script.on_configuration_changed(function(data)
  storage.space_elevators = storage.space_elevators or {}
  storage.elevator_count_per_surface = storage.elevator_count_per_surface or {}
end)

-- Track when space elevators are built
script.on_event(defines.events.on_built_entity, function(event)
  elevator_controller.on_elevator_built(event)
end, {{filter = "name", name = "space-elevator"}})

script.on_event(defines.events.on_robot_built_entity, function(event)
  elevator_controller.on_elevator_built(event)
end, {{filter = "name", name = "space-elevator"}})

-- Track when space elevators are removed
script.on_event(defines.events.on_player_mined_entity, function(event)
  elevator_controller.on_elevator_removed(event)
end, {{filter = "name", name = "space-elevator"}})

script.on_event(defines.events.on_robot_mined_entity, function(event)
  elevator_controller.on_elevator_removed(event)
end, {{filter = "name", name = "space-elevator"}})

script.on_event(defines.events.on_entity_died, function(event)
  elevator_controller.on_elevator_removed(event)
end, {{filter = "name", name = "space-elevator"}})

-- Track rocket launches from space elevator
script.on_event(defines.events.on_rocket_launched, function(event)
  elevator_controller.on_elevator_launch(event)
end)
