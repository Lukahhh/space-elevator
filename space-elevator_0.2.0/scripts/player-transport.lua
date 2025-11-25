-- Player Transport Controller
-- Handles player teleportation between surface and space platforms via elevators

local platform_controller = require("scripts.platform-controller")

local player_transport = {}

-- Travel time in ticks (180 ticks = 3 seconds)
local TRAVEL_TIME = 180

-- ============================================================================
-- Travel State Management
-- ============================================================================

-- Check if a player can travel (must be near elevator/dock)
local function is_player_near_entity(player, entity, max_distance)
  if not player or not player.valid then return false end
  if not entity or not entity.valid then return false end

  local player_pos = player.position
  local entity_pos = entity.position

  local dx = player_pos.x - entity_pos.x
  local dy = player_pos.y - entity_pos.y
  local distance = math.sqrt(dx * dx + dy * dy)

  return distance <= (max_distance or 10)
end

-- Find elevator data for a player on a planet surface
local function find_elevator_for_player(player)
  if not player or not player.valid then return nil end
  if not storage.space_elevators then return nil end

  local surface = player.surface
  local surface_name = surface.name

  for _, elevator_data in pairs(storage.space_elevators) do
    if elevator_data.surface == surface_name and elevator_data.is_operational then
      if elevator_data.entity and elevator_data.entity.valid then
        if is_player_near_entity(player, elevator_data.entity, 10) then
          return elevator_data
        end
      end
    end
  end

  return nil
end

-- Find elevator data from a platform the player is on
local function find_elevator_for_platform_player(player)
  if not player or not player.valid then return nil end
  if not storage.space_elevators then return nil end

  local surface = player.surface
  local platform = surface.platform
  if not platform then return nil end

  -- Find elevator connected to this platform
  for _, elevator_data in pairs(storage.space_elevators) do
    if elevator_data.is_operational and elevator_data.docked_platform_index == platform.index then
      -- Check if player is near the dock
      if elevator_data.docked_dock_entity and elevator_data.docked_dock_entity.valid then
        if is_player_near_entity(player, elevator_data.docked_dock_entity, 10) then
          return elevator_data
        end
      end
    end
  end

  return nil
end

-- ============================================================================
-- Travel Functions
-- ============================================================================

-- Initiate travel from surface to platform
function player_transport.travel_up(player, elevator_data)
  if not player or not player.valid then
    return false, "Invalid player"
  end

  if not elevator_data then
    return false, "No elevator found"
  end

  if not elevator_data.is_operational then
    return false, "Elevator not operational"
  end

  if not platform_controller.is_connected(elevator_data) then
    return false, "Elevator not connected to platform"
  end

  -- Check player is near elevator
  if not is_player_near_entity(player, elevator_data.entity, 10) then
    return false, "Too far from elevator"
  end

  -- Check player is not already in transit
  storage.players_in_transit = storage.players_in_transit or {}
  if storage.players_in_transit[player.index] then
    return false, "Already in transit"
  end

  -- Get destination (platform surface)
  local platform = platform_controller.get_connected_platform(elevator_data, player.force)
  if not platform or not platform.valid then
    return false, "Platform no longer available"
  end

  local dest_surface = platform.surface
  if not dest_surface or not dest_surface.valid then
    return false, "Platform surface invalid"
  end

  -- Find destination position (near the dock)
  local dock = elevator_data.docked_dock_entity
  local dest_position
  if dock and dock.valid then
    dest_position = dest_surface.find_non_colliding_position(
      "character",
      dock.position,
      10,
      0.5
    )
  end

  if not dest_position then
    dest_position = {x = 0, y = 0}  -- Fallback to origin
    dest_position = dest_surface.find_non_colliding_position("character", dest_position, 20, 0.5) or dest_position
  end

  -- Start transit
  local arrival_tick = game.tick + TRAVEL_TIME
  storage.players_in_transit[player.index] = {
    direction = "up",
    elevator_unit_number = elevator_data.unit_number,
    start_tick = game.tick,
    arrival_tick = arrival_tick,
    destination_surface = dest_surface,
    destination_position = dest_position,
  }

  -- Immobilize player during transit
  player.character_running_speed_modifier = -1  -- Can't move
  player.print("[Space Elevator] Ascending to platform... (" .. math.floor(TRAVEL_TIME / 60) .. " seconds)")

  return true
end

-- Initiate travel from platform to surface
function player_transport.travel_down(player, elevator_data)
  if not player or not player.valid then
    return false, "Invalid player"
  end

  if not elevator_data then
    return false, "No elevator found"
  end

  if not elevator_data.is_operational then
    return false, "Elevator not operational"
  end

  if not platform_controller.is_connected(elevator_data) then
    return false, "Elevator not connected to platform"
  end

  -- Check player is near dock
  if elevator_data.docked_dock_entity and elevator_data.docked_dock_entity.valid then
    if not is_player_near_entity(player, elevator_data.docked_dock_entity, 10) then
      return false, "Too far from dock"
    end
  end

  -- Check player is not already in transit
  storage.players_in_transit = storage.players_in_transit or {}
  if storage.players_in_transit[player.index] then
    return false, "Already in transit"
  end

  -- Get destination (planet surface)
  local entity = elevator_data.entity
  if not entity or not entity.valid then
    return false, "Elevator no longer valid"
  end

  local dest_surface = entity.surface
  if not dest_surface or not dest_surface.valid then
    return false, "Surface invalid"
  end

  -- Find destination position (near the elevator)
  local dest_position = dest_surface.find_non_colliding_position(
    "character",
    entity.position,
    10,
    0.5
  )

  if not dest_position then
    dest_position = entity.position
  end

  -- Start transit
  local arrival_tick = game.tick + TRAVEL_TIME
  storage.players_in_transit[player.index] = {
    direction = "down",
    elevator_unit_number = elevator_data.unit_number,
    start_tick = game.tick,
    arrival_tick = arrival_tick,
    destination_surface = dest_surface,
    destination_position = dest_position,
  }

  -- Immobilize player during transit
  player.character_running_speed_modifier = -1
  player.print("[Space Elevator] Descending to surface... (" .. math.floor(TRAVEL_TIME / 60) .. " seconds)")

  return true
end

-- Cancel travel (e.g., player died)
function player_transport.cancel_travel(player_index)
  storage.players_in_transit = storage.players_in_transit or {}
  local transit_data = storage.players_in_transit[player_index]

  if transit_data then
    local player = game.get_player(player_index)
    if player and player.valid then
      player.character_running_speed_modifier = 0  -- Restore movement
    end
    storage.players_in_transit[player_index] = nil
  end
end

-- ============================================================================
-- Tick Handler
-- ============================================================================

-- Process player arrivals (called from on_nth_tick)
function player_transport.process_transit()
  storage.players_in_transit = storage.players_in_transit or {}

  local current_tick = game.tick

  for player_index, transit_data in pairs(storage.players_in_transit) do
    if current_tick >= transit_data.arrival_tick then
      -- Time to teleport!
      local player = game.get_player(player_index)

      if player and player.valid and player.character then
        local dest_surface = transit_data.destination_surface
        local dest_position = transit_data.destination_position

        if dest_surface and dest_surface.valid then
          -- Teleport player
          local success = player.teleport(dest_position, dest_surface)

          if success then
            player.print("[Space Elevator] Arrived at destination!")
          else
            player.print("[Space Elevator] Teleport failed - could not find safe position")
          end
        else
          player.print("[Space Elevator] Destination no longer valid!")
        end

        -- Restore movement
        player.character_running_speed_modifier = 0
      end

      -- Remove from transit
      storage.players_in_transit[player_index] = nil
    end
  end
end

-- ============================================================================
-- Status Functions
-- ============================================================================

-- Get travel status for a player
function player_transport.get_status(player)
  storage.players_in_transit = storage.players_in_transit or {}

  local transit_data = storage.players_in_transit[player.index]
  if transit_data then
    local remaining_ticks = math.max(0, transit_data.arrival_tick - game.tick)
    local remaining_seconds = math.ceil(remaining_ticks / 60)
    return {
      in_transit = true,
      direction = transit_data.direction,
      remaining_seconds = remaining_seconds,
    }
  end

  return {
    in_transit = false,
    direction = nil,
    remaining_seconds = 0,
  }
end

-- Check if player can travel up from current location
function player_transport.can_travel_up(player)
  if not player or not player.valid then return false, nil end

  local elevator_data = find_elevator_for_player(player)
  if not elevator_data then
    return false, nil
  end

  if not platform_controller.is_connected(elevator_data) then
    return false, elevator_data
  end

  return true, elevator_data
end

-- Check if player can travel down from current location
function player_transport.can_travel_down(player)
  if not player or not player.valid then return false, nil end

  local elevator_data = find_elevator_for_platform_player(player)
  if not elevator_data then
    return false, nil
  end

  return true, elevator_data
end

-- ============================================================================
-- Initialization
-- ============================================================================

function player_transport.init_storage()
  storage.players_in_transit = storage.players_in_transit or {}
end

return player_transport
