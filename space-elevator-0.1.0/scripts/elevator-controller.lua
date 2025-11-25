-- Space Elevator Controller
-- Handles runtime logic for space elevator operations

local elevator_controller = {}

-- Called when a space elevator is built
function elevator_controller.on_elevator_built(event)
  local entity = event.entity or event.created_entity
  if not entity or not entity.valid then return end

  local surface = entity.surface
  local surface_name = surface.name

  -- Initialize tracking for this surface if needed
  storage.elevator_count_per_surface[surface_name] = storage.elevator_count_per_surface[surface_name] or 0

  -- Track this elevator
  storage.elevator_count_per_surface[surface_name] = storage.elevator_count_per_surface[surface_name] + 1

  -- Store elevator reference
  table.insert(storage.space_elevators, {
    entity = entity,
    surface = surface_name,
    position = entity.position,
    unit_number = entity.unit_number
  })

  -- Log for debugging
  game.print("[Space Elevator] Built on " .. surface_name .. " (Total on surface: " .. storage.elevator_count_per_surface[surface_name] .. ")")
end

-- Called when a space elevator is removed (mined, destroyed, etc.)
function elevator_controller.on_elevator_removed(event)
  local entity = event.entity
  if not entity or not entity.valid then return end

  local surface_name = entity.surface.name
  local unit_number = entity.unit_number

  -- Update count
  if storage.elevator_count_per_surface[surface_name] then
    storage.elevator_count_per_surface[surface_name] = storage.elevator_count_per_surface[surface_name] - 1
    if storage.elevator_count_per_surface[surface_name] < 0 then
      storage.elevator_count_per_surface[surface_name] = 0
    end
  end

  -- Remove from tracking table
  for i, elevator_data in pairs(storage.space_elevators) do
    if elevator_data.unit_number == unit_number then
      table.remove(storage.space_elevators, i)
      break
    end
  end

  game.print("[Space Elevator] Removed from " .. surface_name)
end

-- Called when a rocket is launched (we detect if it's from our elevator)
function elevator_controller.on_elevator_launch(event)
  local rocket = event.rocket
  local silo = event.rocket_silo

  if not silo or not silo.valid then return end

  -- Check if this launch is from a space elevator
  if silo.name == "space-elevator" then
    local surface_name = silo.surface.name

    -- Log the launch
    game.print("[Space Elevator] Cargo launched from " .. surface_name .. "!")

    -- In Phase 1, the rocket silo logic handles delivery to platforms automatically
    -- The cargo is delivered based on what's configured in the rocket's cargo inventory
    -- and the destination is determined by Space Age's platform system

    -- Future phases might add:
    -- - Custom launch animations
    -- - Different delivery mechanics
    -- - Bidirectional transfers
    -- - Statistics tracking
  end
end

-- Utility function to get elevator count on a surface
function elevator_controller.get_elevator_count(surface_name)
  return storage.elevator_count_per_surface[surface_name] or 0
end

-- Utility function to check if surface can have more elevators
-- For Phase 1, no limit - this will be implemented in Phase 3
function elevator_controller.can_build_elevator(surface_name)
  -- Phase 1: No restrictions, always allow
  return true

  -- Phase 3 will add something like:
  -- local current_count = elevator_controller.get_elevator_count(surface_name)
  -- local max_elevators = settings.global["space-elevator-max-per-surface"].value
  -- return current_count < max_elevators
end

return elevator_controller
