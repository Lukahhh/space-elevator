-- Platform Controller
-- Handles platform detection, docking, and connection management for space elevators

local platform_controller = {}

-- ============================================================================
-- Platform Detection
-- ============================================================================

-- Get the planet name for a surface (returns nil if not a planet surface)
function platform_controller.get_planet_for_surface(surface)
  if not surface or not surface.valid then return nil end

  local planet = surface.planet
  if planet then
    return planet.name
  end
  return nil
end

-- Get all space platforms orbiting a specific planet
-- Returns array of platform references: {platform = LuaSpacePlatform, name = string, index = number}
function platform_controller.get_orbiting_platforms(planet_name, force)
  local orbiting = {}

  if not force or not force.valid then return orbiting end

  local platforms = force.platforms
  if not platforms then return orbiting end

  for _, platform in pairs(platforms) do
    if platform and platform.valid then
      local location = platform.space_location
      if location and location.name == planet_name then
        table.insert(orbiting, {
          platform = platform,
          name = platform.name or "Unnamed Platform",
          index = platform.index,
        })
      end
    end
  end

  return orbiting
end

-- Get all platforms for a force (regardless of location)
function platform_controller.get_all_platforms(force)
  local all_platforms = {}

  if not force or not force.valid then return all_platforms end

  local platforms = force.platforms
  if not platforms then return all_platforms end

  for _, platform in pairs(platforms) do
    if platform and platform.valid then
      local location = platform.space_location
      local location_name = location and location.name or "In Transit"
      table.insert(all_platforms, {
        platform = platform,
        name = platform.name or "Unnamed Platform",
        index = platform.index,
        location = location_name,
      })
    end
  end

  return all_platforms
end

-- ============================================================================
-- Dock Entity Management
-- ============================================================================

-- Check if a platform has a docking station
function platform_controller.has_dock(platform)
  return platform_controller.get_dock(platform) ~= nil
end

-- Get the docking station entity for a platform
function platform_controller.get_dock(platform)
  if not platform or not platform.valid then return nil end

  local surface = platform.surface
  if not surface or not surface.valid then return nil end

  -- Search for dock entity on platform surface
  local docks = surface.find_entities_filtered{
    name = "space-elevator-dock",
  }

  if docks and #docks > 0 then
    return docks[1]  -- Return first dock (should only be one per platform)
  end

  return nil
end

-- Get dock data by unit number
function platform_controller.get_dock_data(unit_number)
  if not storage.platform_docks then return nil end
  return storage.platform_docks[unit_number]
end

-- ============================================================================
-- Docking Management
-- ============================================================================

-- Check if an elevator can dock (must be operational and not already docked)
function platform_controller.can_dock(elevator_data)
  if not elevator_data then return false end
  if not elevator_data.is_operational then return false end
  if elevator_data.docked_platform_index then return false end  -- Already docked
  return true
end

-- Establish connection between elevator and platform
-- Returns true on success, false with reason on failure
function platform_controller.dock(elevator_data, platform)
  if not elevator_data then
    return false, "Invalid elevator data"
  end

  if not elevator_data.is_operational then
    return false, "Elevator not operational"
  end

  if not platform or not platform.valid then
    return false, "Invalid platform"
  end

  -- Check if platform has a dock
  local dock = platform_controller.get_dock(platform)
  if not dock or not dock.valid then
    return false, "Platform has no docking station"
  end

  -- Check if dock is already connected to another elevator
  local dock_data = platform_controller.get_dock_data(dock.unit_number)
  if dock_data and dock_data.connected_elevator_unit_number then
    return false, "Dock already connected to another elevator"
  end

  -- Check if elevator is already docked elsewhere
  if elevator_data.docked_platform_index then
    return false, "Elevator already docked to a platform"
  end

  -- Establish connection
  elevator_data.docked_platform_index = platform.index
  elevator_data.docked_platform_name = platform.name or "Unnamed Platform"
  elevator_data.connection_status = "connected"
  elevator_data.docked_dock_entity = dock

  -- Update dock data
  if storage.platform_docks and storage.platform_docks[dock.unit_number] then
    storage.platform_docks[dock.unit_number].connected_elevator_unit_number = elevator_data.unit_number
  end

  game.print("[Space Elevator] Connected to platform: " .. elevator_data.docked_platform_name)
  return true
end

-- Break connection between elevator and platform
function platform_controller.undock(elevator_data)
  if not elevator_data then return false end

  -- Clear dock's connection reference
  if elevator_data.docked_dock_entity and elevator_data.docked_dock_entity.valid then
    local dock_data = platform_controller.get_dock_data(elevator_data.docked_dock_entity.unit_number)
    if dock_data then
      dock_data.connected_elevator_unit_number = nil
    end
  end

  local old_name = elevator_data.docked_platform_name or "Unknown"

  -- Clear elevator's connection
  elevator_data.docked_platform_index = nil
  elevator_data.docked_platform_name = nil
  elevator_data.connection_status = "disconnected"
  elevator_data.docked_dock_entity = nil

  game.print("[Space Elevator] Disconnected from platform: " .. old_name)
  return true
end

-- Check if elevator is connected to a platform
function platform_controller.is_connected(elevator_data)
  if not elevator_data then return false end
  return elevator_data.connection_status == "connected" and elevator_data.docked_platform_index ~= nil
end

-- Get the connected platform for an elevator
function platform_controller.get_connected_platform(elevator_data, force)
  if not platform_controller.is_connected(elevator_data) then return nil end
  if not force or not force.valid then return nil end

  local platforms = force.platforms
  if not platforms then return nil end

  for _, platform in pairs(platforms) do
    if platform and platform.valid and platform.index == elevator_data.docked_platform_index then
      return platform
    end
  end

  return nil
end

-- ============================================================================
-- Auto-Connection Logic
-- ============================================================================

-- Attempt auto-connection if exactly one platform with dock is orbiting
-- Returns: connected (bool), platform_count (number), message (string)
function platform_controller.try_auto_connect(elevator_data, force)
  if not elevator_data or not force then
    return false, 0, "Invalid parameters"
  end

  if not elevator_data.is_operational then
    return false, 0, "Elevator not operational"
  end

  if platform_controller.is_connected(elevator_data) then
    return false, 0, "Already connected"
  end

  -- Get planet name from elevator surface
  local entity = elevator_data.entity
  if not entity or not entity.valid then
    return false, 0, "Invalid elevator entity"
  end

  local planet_name = platform_controller.get_planet_for_surface(entity.surface)
  if not planet_name then
    return false, 0, "Elevator not on a planet surface"
  end

  -- Get orbiting platforms
  local orbiting = platform_controller.get_orbiting_platforms(planet_name, force)

  -- Filter to only platforms with docks
  local docked_platforms = {}
  for _, p in ipairs(orbiting) do
    if platform_controller.has_dock(p.platform) then
      table.insert(docked_platforms, p)
    end
  end

  local count = #docked_platforms

  if count == 0 then
    return false, count, "No platforms with docking stations in orbit"
  elseif count == 1 then
    -- Auto-connect to the single platform
    local success, err = platform_controller.dock(elevator_data, docked_platforms[1].platform)
    if success then
      return true, count, "Auto-connected to " .. docked_platforms[1].name
    else
      return false, count, err
    end
  else
    -- Multiple platforms - manual selection required
    return false, count, "Multiple platforms in orbit - manual selection required"
  end
end

-- ============================================================================
-- Event Handlers
-- ============================================================================

-- Called when a docking station is built
function platform_controller.on_dock_built(event)
  local entity = event.entity or event.created_entity
  if not entity or not entity.valid then return end
  if entity.name ~= "space-elevator-dock" then return end

  local surface = entity.surface

  -- Verify this is a space platform surface
  local is_platform = surface.platform ~= nil
  if not is_platform then
    -- Not on a platform - destroy it and return item
    local player = event.player_index and game.get_player(event.player_index)
    if player then
      player.insert{name = "space-elevator-dock", count = 1}
      player.create_local_flying_text{
        text = "Docking stations can only be placed on space platforms!",
        position = entity.position,
        color = {r = 1, g = 0.3, b = 0.3},
      }
    end
    entity.destroy()
    return
  end

  -- Check if platform already has a dock
  local platform = surface.platform
  local existing_docks = surface.find_entities_filtered{
    name = "space-elevator-dock",
  }

  if #existing_docks > 1 then
    -- More than one dock (including this one) - destroy the new one
    local player = event.player_index and game.get_player(event.player_index)
    if player then
      player.insert{name = "space-elevator-dock", count = 1}
      player.create_local_flying_text{
        text = "Only one docking station per platform!",
        position = entity.position,
        color = {r = 1, g = 0.3, b = 0.3},
      }
    end
    entity.destroy()
    return
  end

  -- Initialize storage if needed
  storage.platform_docks = storage.platform_docks or {}

  -- Register the dock
  storage.platform_docks[entity.unit_number] = {
    entity = entity,
    platform_index = platform.index,
    platform_name = platform.name or "Unnamed Platform",
    connected_elevator_unit_number = nil,
  }

  game.print("[Space Elevator] Docking station built on " .. (platform.name or "platform"))
end

-- Called when a docking station is removed
function platform_controller.on_dock_removed(event)
  local entity = event.entity
  if not entity or not entity.valid then return end
  if entity.name ~= "space-elevator-dock" then return end

  local dock_data = platform_controller.get_dock_data(entity.unit_number)

  -- If dock was connected to an elevator, disconnect it
  if dock_data and dock_data.connected_elevator_unit_number then
    -- Find and disconnect the elevator
    if storage.space_elevators then
      for _, elevator_data in pairs(storage.space_elevators) do
        if elevator_data.unit_number == dock_data.connected_elevator_unit_number then
          elevator_data.docked_platform_index = nil
          elevator_data.docked_platform_name = nil
          elevator_data.connection_status = "disconnected"
          elevator_data.docked_dock_entity = nil
          game.print("[Space Elevator] Connection lost - docking station removed")
          break
        end
      end
    end
  end

  -- Remove from tracking
  if storage.platform_docks then
    storage.platform_docks[entity.unit_number] = nil
  end
end

-- Periodic check for connection validity (called from on_nth_tick)
-- Handles cases like platform moving away from planet
function platform_controller.validate_connections()
  if not storage.space_elevators then return end

  for _, elevator_data in pairs(storage.space_elevators) do
    if platform_controller.is_connected(elevator_data) then
      -- Get the elevator's own force to search for platforms
      local entity = elevator_data.entity
      if not entity or not entity.valid then
        platform_controller.undock(elevator_data)
      else
        local force = entity.force

        -- Check if platform is still valid and in orbit
        local platform = platform_controller.get_connected_platform(elevator_data, force)

        if not platform or not platform.valid then
          -- Platform no longer exists - debug info
          game.print("[Space Elevator] Connection lost - platform no longer exists (index: " .. tostring(elevator_data.docked_platform_index) .. ")")
          platform_controller.undock(elevator_data)
        else
          -- Check if platform is still orbiting the same planet
          local elevator_planet = platform_controller.get_planet_for_surface(entity.surface)
          local platform_location = platform.space_location
          local platform_planet = platform_location and platform_location.name

          if elevator_planet ~= platform_planet then
            -- Platform has left orbit
            game.print("[Space Elevator] Connection lost - platform departed from orbit")
            platform_controller.undock(elevator_data)
          end
        end
      end
    end
  end
end

-- ============================================================================
-- Initialization
-- ============================================================================

function platform_controller.init_storage()
  storage.platform_docks = storage.platform_docks or {}
end

return platform_controller
