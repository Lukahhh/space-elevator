-- Transfer Controller
-- Handles bidirectional item and fluid transfers between elevators and platform docks

local platform_controller = require("scripts.platform-controller")
local visual_effects = require("scripts.visual-effects")

local transfer_controller = {}

-- Get transfer rates from settings (runtime-global)
local function get_auto_item_rate()
  return settings.global["space-elevator-auto-transfer-rate"].value
end

local function get_fluid_rate()
  return settings.global["space-elevator-manual-fluid-transfer"].value
end

-- Default fallback rates (used if settings not available)
local DEFAULT_ITEM_RATE = 10
local DEFAULT_FLUID_RATE = 1000  -- Fluid units per transfer

-- ============================================================================
-- Inventory Helpers
-- ============================================================================

-- Get the elevator's companion chest inventory
local function get_elevator_inventory(elevator_data)
  if not elevator_data then return nil end
  local chest = elevator_data.chest
  if not chest or not chest.valid then return nil end
  return chest.get_inventory(defines.inventory.chest)
end

-- Get the platform dock's inventory
local function get_dock_inventory(elevator_data)
  if not elevator_data then return nil end
  local dock = elevator_data.docked_dock_entity
  if not dock or not dock.valid then return nil end
  return dock.get_inventory(defines.inventory.chest)
end

-- ============================================================================
-- Item Transfer Functions
-- ============================================================================

-- Transfer items from elevator to platform dock (upload)
-- Returns: {transferred = {[item_name] = count}, total = number}
function transfer_controller.transfer_items_up(elevator_data, item_name, amount)
  if not platform_controller.is_connected(elevator_data) then
    return {transferred = {}, total = 0, error = "Not connected to platform"}
  end

  local source = get_elevator_inventory(elevator_data)
  local dest = get_dock_inventory(elevator_data)

  if not source or not dest then
    return {transferred = {}, total = 0, error = "Invalid inventory"}
  end

  amount = amount or DEFAULT_ITEM_RATE
  local transferred = {}
  local total = 0

  if item_name then
    -- Transfer specific item
    local available = source.get_item_count(item_name)
    local to_transfer = math.min(available, amount)
    if to_transfer > 0 then
      local inserted = dest.insert{name = item_name, count = to_transfer}
      if inserted > 0 then
        source.remove{name = item_name, count = inserted}
        transferred[item_name] = inserted
        total = inserted
      end
    end
  else
    -- Transfer any items up to amount
    local contents = source.get_contents()
    local remaining = amount
    for _, item in pairs(contents) do
      if remaining <= 0 then break end
      local to_transfer = math.min(item.count, remaining)
      local inserted = dest.insert{name = item.name, count = to_transfer}
      if inserted > 0 then
        source.remove{name = item.name, count = inserted}
        transferred[item.name] = (transferred[item.name] or 0) + inserted
        total = total + inserted
        remaining = remaining - inserted
      end
    end
  end

  -- Draw upload beam effect on both surface and platform if items were transferred
  -- Pass total to scale beam width based on transfer amount
  if total > 0 and elevator_data.entity and elevator_data.entity.valid then
    visual_effects.draw_item_upload_beam_both(elevator_data.entity, elevator_data.docked_dock_entity, total)
  end

  return {transferred = transferred, total = total}
end

-- Transfer items from platform dock to elevator (download)
-- Returns: {transferred = {[item_name] = count}, total = number}
function transfer_controller.transfer_items_down(elevator_data, item_name, amount)
  if not platform_controller.is_connected(elevator_data) then
    return {transferred = {}, total = 0, error = "Not connected to platform"}
  end

  local source = get_dock_inventory(elevator_data)
  local dest = get_elevator_inventory(elevator_data)

  if not source or not dest then
    return {transferred = {}, total = 0, error = "Invalid inventory"}
  end

  amount = amount or DEFAULT_ITEM_RATE
  local transferred = {}
  local total = 0

  if item_name then
    -- Transfer specific item
    local available = source.get_item_count(item_name)
    local to_transfer = math.min(available, amount)
    if to_transfer > 0 then
      local inserted = dest.insert{name = item_name, count = to_transfer}
      if inserted > 0 then
        source.remove{name = item_name, count = inserted}
        transferred[item_name] = inserted
        total = inserted
      end
    end
  else
    -- Transfer any items up to amount
    local contents = source.get_contents()
    local remaining = amount
    for _, item in pairs(contents) do
      if remaining <= 0 then break end
      local to_transfer = math.min(item.count, remaining)
      local inserted = dest.insert{name = item.name, count = to_transfer}
      if inserted > 0 then
        source.remove{name = item.name, count = inserted}
        transferred[item.name] = (transferred[item.name] or 0) + inserted
        total = total + inserted
        remaining = remaining - inserted
      end
    end
  end

  -- Draw download beam effect on both surface and platform if items were transferred
  -- Pass total to scale beam width based on transfer amount
  if total > 0 and elevator_data.entity and elevator_data.entity.valid then
    visual_effects.draw_item_download_beam_both(elevator_data.entity, elevator_data.docked_dock_entity, total)
  end

  return {transferred = transferred, total = total}
end

-- ============================================================================
-- Combined Inventory View (for GUI)
-- ============================================================================

-- Helper to count actual used slots in an inventory
local function count_used_slots(inventory)
  if not inventory then return 0 end
  local used = 0
  for i = 1, #inventory do
    if inventory[i].valid_for_read then
      used = used + 1
    end
  end
  return used
end

-- Get combined view of both inventories for GUI display
function transfer_controller.get_inventory_status(elevator_data)
  local status = {
    elevator = {items = {}, total_slots = 0, used_slots = 0},
    dock = {items = {}, total_slots = 0, used_slots = 0},
    connected = false,
  }

  local elevator_inv = get_elevator_inventory(elevator_data)
  if elevator_inv then
    status.elevator.total_slots = #elevator_inv
    status.elevator.used_slots = count_used_slots(elevator_inv)
    local contents = elevator_inv.get_contents()
    for _, item in pairs(contents) do
      status.elevator.items[item.name] = item.count
    end
  end

  if platform_controller.is_connected(elevator_data) then
    status.connected = true
    local dock_inv = get_dock_inventory(elevator_data)
    if dock_inv then
      status.dock.total_slots = #dock_inv
      status.dock.used_slots = count_used_slots(dock_inv)
      local contents = dock_inv.get_contents()
      for _, item in pairs(contents) do
        status.dock.items[item.name] = item.count
      end
    end
  end

  return status
end

-- ============================================================================
-- Automatic Transfer Mode
-- ============================================================================

-- Storage keys for active transfers
-- storage.active_transfers[unit_number] = {mode = "up"/"down"/"balanced", rate = number}

function transfer_controller.set_auto_transfer(unit_number, mode, rate)
  storage.active_transfers = storage.active_transfers or {}

  if mode == "off" or mode == nil then
    storage.active_transfers[unit_number] = nil
  else
    storage.active_transfers[unit_number] = {
      mode = mode,  -- "up", "down", or "balanced"
      rate = rate or DEFAULT_ITEM_RATE,
    }
  end
end

function transfer_controller.get_auto_transfer(unit_number)
  storage.active_transfers = storage.active_transfers or {}
  return storage.active_transfers[unit_number]
end

-- Process automatic transfers (called from on_nth_tick)
function transfer_controller.process_auto_transfers()
  storage.active_transfers = storage.active_transfers or {}

  for unit_number, config in pairs(storage.active_transfers) do
    -- Find elevator data
    local elevator_data = nil
    if storage.space_elevators then
      for _, data in pairs(storage.space_elevators) do
        if data.unit_number == unit_number then
          elevator_data = data
          break
        end
      end
    end

    if elevator_data and elevator_data.is_operational then
      if config.mode == "up" then
        transfer_controller.transfer_items_up(elevator_data, nil, config.rate)
      elseif config.mode == "down" then
        transfer_controller.transfer_items_down(elevator_data, nil, config.rate)
      elseif config.mode == "balanced" then
        -- Transfer half each way for balanced mode
        local half_rate = math.ceil(config.rate / 2)
        transfer_controller.transfer_items_up(elevator_data, nil, half_rate)
        transfer_controller.transfer_items_down(elevator_data, nil, half_rate)
      end
    else
      -- Remove invalid elevator from auto-transfer
      storage.active_transfers[unit_number] = nil
    end
  end
end

-- ============================================================================
-- Fluid Transfer Functions (Phase 4.5)
-- ============================================================================

-- Get elevator fluid tank
local function get_elevator_fluid_tank(elevator_data)
  if not elevator_data then return nil end
  local tank = elevator_data.fluid_tank
  if tank and tank.valid then
    return tank
  end
  return nil
end

-- Find nearby dock fluid tank (searches for space-elevator-dock-fluid-tank near the dock)
local function get_dock_fluid_tank(elevator_data)
  if not elevator_data then return nil end
  local dock = elevator_data.docked_dock_entity
  if not dock or not dock.valid then return nil end

  -- Search for fluid tank near the dock on the platform
  local tanks = dock.surface.find_entities_filtered{
    name = "space-elevator-dock-fluid-tank",
    position = dock.position,
    radius = 5,  -- Search within 5 tiles
    force = dock.force,
  }

  if tanks and #tanks > 0 then
    return tanks[1]
  end
  return nil
end

-- Get fluid info from a tank
local function get_fluid_info(tank)
  if not tank or not tank.valid then return nil end
  local fluidbox = tank.fluidbox
  if not fluidbox then return nil end

  -- In Factorio 2.0, fluidbox access may work differently
  -- Try direct access first
  local fluid = fluidbox[1]
  if fluid and fluid.name then
    return {
      name = fluid.name,
      amount = fluid.amount or 0,
      temperature = fluid.temperature or 15,
    }
  end

  -- Fallback: try get_fluid_segment_contents for 2.0 compatibility
  if fluidbox.get_fluid_segment_contents then
    local contents = fluidbox.get_fluid_segment_contents(1)
    if contents and next(contents) then
      for name, amount in pairs(contents) do
        return {
          name = name,
          amount = amount,
          temperature = 15,  -- Default temp
        }
      end
    end
  end

  return nil
end

-- Transfer fluids from elevator to platform dock (upload)
function transfer_controller.transfer_fluids_up(elevator_data, amount)
  if not platform_controller.is_connected(elevator_data) then
    return {transferred = 0, error = "Not connected to platform"}
  end

  local source_tank = get_elevator_fluid_tank(elevator_data)
  local dest_tank = get_dock_fluid_tank(elevator_data)

  if not source_tank then
    return {transferred = 0, error = "No elevator fluid tank"}
  end
  if not dest_tank then
    return {transferred = 0, error = "No dock fluid tank nearby"}
  end

  amount = amount or DEFAULT_FLUID_RATE

  local source_fluid = get_fluid_info(source_tank)
  if not source_fluid then
    return {transferred = 0, error = "Elevator tank is empty"}
  end
  if source_fluid.amount <= 0 then
    return {transferred = 0, error = "Elevator tank has no fluid to transfer"}
  end

  local to_transfer = math.min(source_fluid.amount, amount)

  -- Check if destination can accept this fluid
  local dest_fluid = get_fluid_info(dest_tank)
  if dest_fluid and dest_fluid.name ~= source_fluid.name then
    return {transferred = 0, error = "Destination has different fluid", fluid_name = source_fluid.name}
  end

  -- Try to insert into destination
  local inserted = dest_tank.insert_fluid{
    name = source_fluid.name,
    amount = to_transfer,
    temperature = source_fluid.temperature,
  }

  if inserted > 0 then
    -- Remove from source
    source_tank.remove_fluid{name = source_fluid.name, amount = inserted}
    -- Draw fluid upload beam effect on both surface and platform
    -- Pass inserted amount to scale beam width
    if elevator_data.entity and elevator_data.entity.valid then
      visual_effects.draw_fluid_upload_beam_both(elevator_data.entity, elevator_data.docked_dock_entity, inserted)
    end
  else
    -- Destination tank is full
    return {transferred = 0, error = "Dock tank is full", fluid_name = source_fluid.name}
  end

  return {transferred = inserted, fluid_name = source_fluid.name}
end

-- Transfer fluids from platform dock to elevator (download)
function transfer_controller.transfer_fluids_down(elevator_data, amount)
  if not platform_controller.is_connected(elevator_data) then
    return {transferred = 0, error = "Not connected to platform"}
  end

  local source_tank = get_dock_fluid_tank(elevator_data)
  local dest_tank = get_elevator_fluid_tank(elevator_data)

  if not source_tank then
    return {transferred = 0, error = "No dock fluid tank nearby (place within 5 tiles of dock)"}
  end
  if not dest_tank then
    return {transferred = 0, error = "No elevator fluid tank"}
  end

  amount = amount or DEFAULT_FLUID_RATE

  local source_fluid = get_fluid_info(source_tank)
  if not source_fluid then
    return {transferred = 0, error = "Dock tank is empty"}
  end
  if source_fluid.amount <= 0 then
    return {transferred = 0, error = "Dock tank has no fluid to transfer"}
  end

  local to_transfer = math.min(source_fluid.amount, amount)

  -- Check if destination can accept this fluid
  local dest_fluid = get_fluid_info(dest_tank)
  if dest_fluid and dest_fluid.name ~= source_fluid.name then
    return {transferred = 0, error = "Destination has different fluid", fluid_name = source_fluid.name}
  end

  -- Try to insert into destination
  local inserted = dest_tank.insert_fluid{
    name = source_fluid.name,
    amount = to_transfer,
    temperature = source_fluid.temperature,
  }

  if inserted > 0 then
    -- Remove from source
    source_tank.remove_fluid{name = source_fluid.name, amount = inserted}
    -- Draw fluid download beam effect on both surface and platform
    -- Pass inserted amount to scale beam width
    if elevator_data.entity and elevator_data.entity.valid then
      visual_effects.draw_fluid_download_beam_both(elevator_data.entity, elevator_data.docked_dock_entity, inserted)
    end
  else
    -- Destination tank is full
    return {transferred = 0, error = "Elevator tank is full", fluid_name = source_fluid.name}
  end

  return {transferred = inserted, fluid_name = source_fluid.name}
end

-- Get fluid status for GUI
function transfer_controller.get_fluid_status(elevator_data)
  local tank_capacity = settings.startup["space-elevator-fluid-tank-capacity"].value
  local status = {
    elevator = {fluid = nil, amount = 0, capacity = tank_capacity, has_tank = false},
    dock = {fluid = nil, amount = 0, capacity = tank_capacity, has_tank = false},
    connected = false,
  }

  local elevator_tank = get_elevator_fluid_tank(elevator_data)
  if elevator_tank then
    status.elevator.has_tank = true
    local fluid = get_fluid_info(elevator_tank)
    if fluid then
      status.elevator.fluid = fluid.name
      status.elevator.amount = math.floor(fluid.amount)
    end
  end

  if platform_controller.is_connected(elevator_data) then
    status.connected = true
    local dock_tank = get_dock_fluid_tank(elevator_data)
    if dock_tank then
      status.dock.has_tank = true
      local fluid = get_fluid_info(dock_tank)
      if fluid then
        status.dock.fluid = fluid.name
        status.dock.amount = math.floor(fluid.amount)
      end
    end
  end

  return status
end

-- ============================================================================
-- Initialization
-- ============================================================================

function transfer_controller.init_storage()
  storage.active_transfers = storage.active_transfers or {}
  visual_effects.init_storage()
end

-- Cleanup visual effects tracking when elevator is removed
function transfer_controller.cleanup_elevator(unit_number)
  visual_effects.cleanup_elevator(unit_number)
end

return transfer_controller
