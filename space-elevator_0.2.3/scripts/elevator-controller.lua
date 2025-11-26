-- Space Elevator Controller
-- Handles runtime logic for space elevator operations

local construction_stages = require("scripts.construction-stages")
local transfer_controller = require("scripts.transfer-controller")

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

  -- Get companion chest for materials
  local chest = elevator_data.chest
  if not chest or not chest.valid then return false end

  -- Check materials in companion chest
  local stage = elevator_data.construction_stage
  if not construction_stages.check_materials(chest, stage) then
    return false
  end

  -- Consume materials and start construction
  construction_stages.consume_materials(chest, stage)
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

-- Spawn companion chest for construction materials
local function spawn_construction_chest(entity)
  if not entity or not entity.valid then return nil end

  -- Create invisible chest at same position for construction materials
  local chest = entity.surface.create_entity{
    name = "space-elevator-chest",
    position = entity.position,
    force = entity.force,
  }

  if chest then
    chest.destructible = false  -- Can't be destroyed directly
  end

  return chest
end

-- Spawn companion fluid tank for fluid transfers (Phase 4.5)
-- Tank is positioned outside the elevator footprint so pipes can connect
local function spawn_fluid_tank(entity)
  if not entity or not entity.valid then return nil end

  -- Rocket silo is ~9x9 tiles. Position tank at the north edge (offset by 6 tiles)
  -- This puts the tank just outside the silo's collision box for easy pipe access
  local tank_position = {
    x = entity.position.x,
    y = entity.position.y - 6,  -- North of elevator
  }

  -- Create fluid tank at offset position (visible so player can connect pipes)
  local tank = entity.surface.create_entity{
    name = "space-elevator-fluid-tank",
    position = tank_position,
    force = entity.force,
  }

  if tank then
    tank.destructible = false
  end

  return tank
end

-- Register an untracked elevator (e.g., spawned via command or from older saves)
function elevator_controller.register_elevator(entity)
  if not entity or not entity.valid then return nil end

  -- Check if already registered
  local existing = elevator_controller.get_elevator_data(entity.unit_number)
  if existing then return existing end

  local surface = entity.surface
  local surface_name = surface.name

  -- Initialize tracking for this surface if needed
  storage.elevator_count_per_surface[surface_name] = storage.elevator_count_per_surface[surface_name] or 0
  storage.elevator_count_per_surface[surface_name] = storage.elevator_count_per_surface[surface_name] + 1

  -- Spawn companion chest for construction materials
  local chest = spawn_construction_chest(entity)
  -- Spawn companion fluid tank for fluid transfers
  local fluid_tank = spawn_fluid_tank(entity)

  -- Create elevator data
  local elevator_data = {
    entity = entity,
    chest = chest,  -- Link to companion chest
    fluid_tank = fluid_tank,  -- Link to companion fluid tank (Phase 4.5)
    surface = surface_name,
    position = entity.position,
    unit_number = entity.unit_number,
    construction_stage = 1,
    construction_progress = 0,
    is_constructing = false,
    is_operational = false,
    launch_count = 0,
    -- Phase 4: Docking fields
    docked_platform_index = nil,
    docked_platform_name = nil,
    connection_status = "disconnected",
    docked_dock_entity = nil,
    -- Phase 5: Per-elevator transfer rate (items per transfer tick)
    transfer_rate = 10,  -- Default to 10 items per 0.5 second
  }

  table.insert(storage.space_elevators, elevator_data)
  return elevator_data
end

-- Get the construction chest for an elevator
function elevator_controller.get_construction_chest(unit_number)
  local elevator_data = elevator_controller.get_elevator_data(unit_number)
  if elevator_data and elevator_data.chest and elevator_data.chest.valid then
    return elevator_data.chest
  end
  return nil
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

  -- Spawn companion chest for construction materials
  local chest = spawn_construction_chest(entity)
  -- Spawn companion fluid tank for fluid transfers
  local fluid_tank = spawn_fluid_tank(entity)

  -- Store elevator reference with construction state
  table.insert(storage.space_elevators, {
    entity = entity,
    chest = chest,  -- Link to companion chest
    fluid_tank = fluid_tank,  -- Link to companion fluid tank (Phase 4.5)
    surface = surface_name,
    position = entity.position,
    unit_number = entity.unit_number,
    -- Construction state
    construction_stage = 1,  -- Start at stage 1
    construction_progress = 0,
    is_constructing = false,
    is_operational = false,
    launch_count = 0,
    -- Phase 4: Docking fields
    docked_platform_index = nil,
    docked_platform_name = nil,
    connection_status = "disconnected",
    docked_dock_entity = nil,
    -- Phase 5: Per-elevator transfer rate (items per transfer tick)
    transfer_rate = 10,  -- Default to 10 items per 0.5 second
  })

  game.print("[Space Elevator] Construction site established on " .. surface_name .. ". Begin stage 1: Site Preparation")
end

-- Called when a space elevator is removed (mined, destroyed, etc.)
function elevator_controller.on_elevator_removed(event)
  local entity = event.entity
  if not entity or not entity.valid then return end

  local surface_name = entity.surface.name
  local unit_number = entity.unit_number

  -- Get elevator data to find companion chest
  local elevator_data = elevator_controller.get_elevator_data(unit_number)

  -- Remove companion chest if it exists
  if elevator_data and elevator_data.chest and elevator_data.chest.valid then
    -- Drop chest contents on ground before destroying
    local chest_inventory = elevator_data.chest.get_inventory(defines.inventory.chest)
    if chest_inventory then
      for i = 1, #chest_inventory do
        local stack = chest_inventory[i]
        if stack and stack.valid_for_read then
          entity.surface.spill_item_stack{
            position = entity.position,
            stack = stack,
            force = entity.force,
          }
        end
      end
    end
    elevator_data.chest.destroy()
  end

  -- Remove companion fluid tank if it exists (Phase 4.5)
  if elevator_data and elevator_data.fluid_tank and elevator_data.fluid_tank.valid then
    -- Fluids are lost when elevator is removed (no spill mechanic for fluids)
    elevator_data.fluid_tank.destroy()
  end

  -- Update count
  if storage.elevator_count_per_surface[surface_name] then
    storage.elevator_count_per_surface[surface_name] = storage.elevator_count_per_surface[surface_name] - 1
    if storage.elevator_count_per_surface[surface_name] < 0 then
      storage.elevator_count_per_surface[surface_name] = 0
    end
  end

  -- Remove from constructing list
  storage.elevators_constructing[unit_number] = nil

  -- Cleanup visual effects tracking
  transfer_controller.cleanup_elevator(unit_number)

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
