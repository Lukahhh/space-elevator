-- Space Elevator Entity Prototype
-- Based on rocket silo but modified for fast, cheap launches
--
-- Phase 1 Limitations:
-- - Uses standard rocket parts (but only 1 required per launch)
-- - Reuses rocket silo graphics
-- - Launch mechanics are same as rocket silo

-- Copy the rocket silo as our base
local space_elevator = table.deepcopy(data.raw["rocket-silo"]["rocket-silo"])

-- Rename and rebrand
space_elevator.name = "space-elevator"
space_elevator.minable.result = "space-elevator"

-- Key difference: Only 1 rocket part required per launch
-- This makes launches much cheaper than standard rocket silo (100 parts)
space_elevator.rocket_parts_required = 1

-- Higher constant energy consumption (late game should have power infrastructure)
space_elevator.energy_usage = "10MW"  -- Significant constant draw vs 250kW for rocket silo

-- Update localised name/description references
space_elevator.localised_name = {"entity-name.space-elevator"}
space_elevator.localised_description = {"entity-description.space-elevator"}

-- Note: The following properties from rocket-silo are inherited and could be tweaked:
-- times_to_blink (default 40) - rocket ready blinking
-- light_blinking_speed (default 1/3)
-- door_opening_speed (default 1/64.5)
-- rocket_rising_delay (default 200 ticks)
-- launch_wait_time (default 120 ticks) - time after door opens before launch
-- rocket_result_inventory_size (default 1 slot for cargo pod)
-- fixed_recipe - could be set to use a custom recipe instead of rocket-part
--
-- For Phase 1, we keep defaults to ensure stability

data:extend({space_elevator})
