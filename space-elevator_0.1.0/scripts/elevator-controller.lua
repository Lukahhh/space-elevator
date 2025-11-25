-- Space Elevator Controller
-- Handles runtime logic for space elevator operations

local construction_stages = require("scripts.construction-stages")

local elevator_controller = {}

-- ============================================================================
-- Elevator Data Management
-- ============================================================================

-- Get elevator data by unit number
function elevator_controller.get_elevator_data(unit_number)
  for _, data in pairs(storage.space_elevators) do
    if data.unit_number == unit_number then
      return data
    end
  end
  return nil
end

-- Get elevator data index by unit number
local function get_elevator_index(unit_number)
  for i, data in pairs(storage.space_elevators) do
    if data.unit_number == unit_number then
      return i
    end
  end
  return nil
end

-- ============================================================================
-- Construction Management
-- ============================================================================

-- Start construction of current stage
function elevator_controller.start_construction(unit_number)
  local elevator_data = elevator_controller.get_elevator_data(unit_number)
  if not elevator_data then return false end

  -- Already constructing or complete
  if elevator_data.is_constructing then return false end
  if elevator_data.construction_stage >= construction_stages.STAGE_COMPLETE then return false end

  local entity = elevator_data.entity
  if not entity or not entity.valid then return false end

  -- Check materials
  local stage = elevator_data.construction_stage
  if not construction_stages.check_materials(entity, stage) then
    return false
  end

  -- Consume materials and start construction
  construction_stages.consume_materials(entity, stage)
  elevator_data.is_constructing = true
  elevator_data.construction_progress = 0

  -- Add to constructing list for tick updates
  storage.elevators_constructing[unit_number] = true

  game.print("[Space Elevator] Stage " .. stage .. " construction started!")
  return true
end

-- Update construction progress (called from on_nth_tick)
function elevator_controller.update_construction(tick)
  for unit_number, _ in pairs(storage.elevators_constructing) do
    local elevator_data = elevator_controller.get_elevator_data(unit_number)

    if not elevator_data or not elevator_data.entity or not elevator_data.entity.valid then
      -- Entity gone, remove from list
      storage.elevators_constructing[unit_number] = nil
    elseif elevator_data.is_constructing then
      local stage = elevator_data.construction_stage
      local stage_info = construction_stages.get_stage(stage)

      if stage_info then
        -- Progress construction (10 ticks per update)
        elevator_data.construction_progress = elevator_data.construction_progress + 10

        -- Check if stage complete
        if elevator_data.construction_progress >= stage_info.construction_time then
          elevator_controller.complete_stage(unit_number)
        end
      end
    end
  end
end

-- Complete current construction stage
function elevator_controller.complete_stage(unit_number)
  local elevator_data = elevator_controller.get_elevator_data(unit_number)
  if not elevator_data then return end

  local old_stage = elevator_data.construction_stage
  elevator_data.construction_stage = old_stage + 1
  elevator_data.is_constructing = false
  elevator_data.construction_progress = 0

  -- Remove from constructing list
  storage.elevators_constructing[unit_number] = nil

  if elevator_data.construction_stage >= construction_stages.STAGE_COMPLETE then
    game.print("[Space Elevator] Construction complete! The space elevator is now operational.")
    -- Enable the elevator functionality
    elevator_controller.activate_elevator(unit_number)
  else
    game.print("[Space Elevator] Stage " .. old_stage .. " complete! Ready for stage " .. elevator_data.construction_stage .. ".")
  end
end

-- Activate a fully constructed elevator
function elevator_controller.activate_elevator(unit_number)
  local elevator_data = elevator_controller.get_elevator_data(unit_number)
  if not elevator_data then return end

  -- The elevator is now operational
  elevator_data.is_operational = true
  elevator_data.launch_count = 0
end

-- ============================================================================
-- Event Handlers
-- ============================================================================

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

  -- Store elevator reference with construction state
  table.insert(storage.space_elevators, {
    entity = entity,
    surface = surface_name,
    position = entity.position,
    unit_number = entity.unit_number,
    -- Construction state
    construction_stage = 1,  -- Start at stage 1
    construction_progress = 0,
    is_constructing = false,
    is_operational = false,
    launch_count = 0,
  })

  game.print("[Space Elevator] Construction site established on " .. surface_name .. ". Begin stage 1: Site Preparation")
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

  -- Remove from constructing list
  storage.elevators_constructing[unit_number] = nil

  -- Remove from tracking table
  local index = get_elevator_index(unit_number)
  if index then
    table.remove(storage.space_elevators, index)
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
    local elevator_data = elevator_controller.get_elevator_data(silo.unit_number)

    if elevator_data then
      -- Only count launches from operational elevators
      if elevator_data.is_operational then
        elevator_data.launch_count = (elevator_data.launch_count or 0) + 1
        game.print("[Space Elevator] Cargo pod #" .. elevator_data.launch_count .. " launched!")
      else
        game.print("[Space Elevator] Warning: Launch attempted on incomplete elevator!")
      end
    end
  end
end

-- ============================================================================
-- Utility Functions
-- ============================================================================

-- Utility function to get elevator count on a surface
function elevator_controller.get_elevator_count(surface_name)
  return storage.elevator_count_per_surface[surface_name] or 0
end

-- Utility function to check if surface can have more elevators
-- For Phase 2, no limit - this will be implemented in Phase 3
function elevator_controller.can_build_elevator(surface_name)
  return true
end

return elevator_controller
