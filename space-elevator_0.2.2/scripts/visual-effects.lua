-- Visual Effects Controller
-- Handles rendering of transfer beam effects for the space elevator

local visual_effects = {}

-- Beam configuration
local BEAM_CONFIG = {
  -- Upload beam (surface to platform) - blue
  upload = {
    color = {r = 0.2, g = 0.6, b = 1, a = 0.8},
    width = 5,
    time_to_live = 20,  -- ~0.33 seconds
    height = 60,  -- How far the beam extends upward
  },
  -- Download beam (platform to surface) - orange
  download = {
    color = {r = 1, g = 0.5, b = 0.1, a = 0.8},
    width = 5,
    time_to_live = 20,
    height = 60,
  },
  -- Fluid transfer beam - cyan/teal
  fluid_upload = {
    color = {r = 0, g = 0.8, b = 0.8, a = 0.7},
    width = 4,
    time_to_live = 25,
    height = 60,
  },
  fluid_download = {
    color = {r = 0.8, g = 0.4, b = 0, a = 0.7},
    width = 4,
    time_to_live = 25,
    height = 60,
  },
}

-- ============================================================================
-- Beam Drawing Functions
-- ============================================================================

-- Draw a transfer beam from the elevator
-- @param entity: The elevator entity
-- @param direction: "upload" or "download"
-- @param is_fluid: boolean, true for fluid transfers
function visual_effects.draw_transfer_beam(entity, direction, is_fluid)
  if not entity or not entity.valid then return end

  -- Select beam configuration
  local config_key = direction
  if is_fluid then
    config_key = "fluid_" .. direction
  end
  local config = BEAM_CONFIG[config_key] or BEAM_CONFIG.upload

  -- Calculate beam endpoints
  -- Beam originates from center of elevator and shoots upward
  local from_pos = entity.position
  local to_pos = {
    x = from_pos.x,
    y = from_pos.y - config.height,  -- Negative Y is up in Factorio
  }

  -- Draw the main beam
  rendering.draw_line{
    surface = entity.surface,
    from = from_pos,
    to = to_pos,
    color = config.color,
    width = config.width,
    time_to_live = config.time_to_live,
  }

  -- Draw a thinner inner beam for a "core" effect
  local inner_color = {
    r = math.min(1, config.color.r + 0.3),
    g = math.min(1, config.color.g + 0.3),
    b = math.min(1, config.color.b + 0.3),
    a = config.color.a * 0.6,
  }
  rendering.draw_line{
    surface = entity.surface,
    from = from_pos,
    to = to_pos,
    color = inner_color,
    width = math.max(1, config.width - 2),
    time_to_live = config.time_to_live,
  }
end

-- Draw beam for item transfers
function visual_effects.draw_item_upload_beam(entity)
  visual_effects.draw_transfer_beam(entity, "upload", false)
end

function visual_effects.draw_item_download_beam(entity)
  visual_effects.draw_transfer_beam(entity, "download", false)
end

-- Draw beam for fluid transfers
function visual_effects.draw_fluid_upload_beam(entity)
  visual_effects.draw_transfer_beam(entity, "upload", true)
end

function visual_effects.draw_fluid_download_beam(entity)
  visual_effects.draw_transfer_beam(entity, "download", true)
end

-- ============================================================================
-- Platform-side Beam Effects
-- ============================================================================

-- Find the bottom edge of the platform (maximum Y coordinate of tiles)
-- Caches the result per surface to avoid expensive tile searches every transfer
local platform_bottom_cache = {}

local function get_platform_bottom_edge(surface, dock_pos)
  local surface_index = surface.index

  -- Check cache first (cache for 5 seconds / 300 ticks)
  local cached = platform_bottom_cache[surface_index]
  if cached and (game.tick - cached.tick) < 300 then
    return cached.bottom_y
  end

  -- Search for tiles in a column below the dock to find where platform ends
  -- We search in a narrow vertical strip centered on the dock's X position
  local search_area = {
    left_top = {x = dock_pos.x - 2, y = dock_pos.y},
    right_bottom = {x = dock_pos.x + 2, y = dock_pos.y + 100}
  }

  local tiles = surface.find_tiles_filtered{
    area = search_area,
    -- No filter - get all non-space tiles (space tiles have name "out-of-map" or similar)
  }

  -- Find the maximum Y (bottom-most tile)
  -- Only count actual platform tiles, not empty space
  local max_y = dock_pos.y
  for _, tile in pairs(tiles) do
    local tile_name = tile.name
    -- Skip empty/space tiles (they typically have "out-of-map" or "empty-space" names)
    if tile_name and not tile_name:find("out%-of%-map") and not tile_name:find("empty") then
      if tile.position.y > max_y then
        max_y = tile.position.y
      end
    end
  end

  -- Add a small buffer (tile is 1x1, so add 1 to get to the actual edge)
  local bottom_y = max_y + 1

  -- Cache the result
  platform_bottom_cache[surface_index] = {
    bottom_y = bottom_y,
    tick = game.tick
  }

  return bottom_y
end

-- Draw a transfer beam at the platform dock (comes from below, visible in empty space)
-- @param dock_entity: The dock entity on the platform
-- @param direction: "upload" or "download"
-- @param is_fluid: boolean, true for fluid transfers
function visual_effects.draw_platform_beam(dock_entity, direction, is_fluid)
  if not dock_entity or not dock_entity.valid then return end

  -- Select beam configuration
  local config_key = direction
  if is_fluid then
    config_key = "fluid_" .. direction
  end
  local config = BEAM_CONFIG[config_key] or BEAM_CONFIG.upload

  local dock_pos = dock_entity.position
  local surface = dock_entity.surface

  -- Find the actual bottom edge of the platform
  local platform_bottom = get_platform_bottom_edge(surface, dock_pos)

  -- Calculate beam endpoints
  -- Beam comes from deep in empty space below and ends just at the platform edge
  local from_pos = {
    x = dock_pos.x,
    y = platform_bottom + 100,  -- Start from 100 tiles below the platform edge
  }

  local to_pos = {
    x = dock_pos.x,
    y = platform_bottom + 2,  -- End just below the platform edge (small gap)
  }

  -- Draw the main beam (render_layer zero since we're in empty space)
  rendering.draw_line{
    surface = surface,
    from = from_pos,
    to = to_pos,
    color = config.color,
    width = config.width,
    time_to_live = config.time_to_live,
    render_layer = "zero",
  }

  -- Draw a thinner inner beam for a "core" effect
  local inner_color = {
    r = math.min(1, config.color.r + 0.3),
    g = math.min(1, config.color.g + 0.3),
    b = math.min(1, config.color.b + 0.3),
    a = config.color.a * 0.6,
  }
  rendering.draw_line{
    surface = surface,
    from = from_pos,
    to = to_pos,
    color = inner_color,
    width = math.max(1, config.width - 2),
    time_to_live = config.time_to_live,
    render_layer = "zero",
  }
end

-- ============================================================================
-- Combined Beam Effects (surface + platform)
-- ============================================================================

-- Draw beams on both surface and platform for item transfers
function visual_effects.draw_item_upload_beam_both(elevator_entity, dock_entity)
  visual_effects.draw_transfer_beam(elevator_entity, "upload", false)
  visual_effects.draw_platform_beam(dock_entity, "upload", false)
end

function visual_effects.draw_item_download_beam_both(elevator_entity, dock_entity)
  visual_effects.draw_transfer_beam(elevator_entity, "download", false)
  visual_effects.draw_platform_beam(dock_entity, "download", false)
end

-- Draw beams on both surface and platform for fluid transfers
function visual_effects.draw_fluid_upload_beam_both(elevator_entity, dock_entity)
  visual_effects.draw_transfer_beam(elevator_entity, "upload", true)
  visual_effects.draw_platform_beam(dock_entity, "upload", true)
end

function visual_effects.draw_fluid_download_beam_both(elevator_entity, dock_entity)
  visual_effects.draw_transfer_beam(elevator_entity, "download", true)
  visual_effects.draw_platform_beam(dock_entity, "download", true)
end

-- ============================================================================
-- Batch/Throttled Effects (for auto-transfers)
-- ============================================================================

-- Track last beam time per elevator to avoid excessive rendering
-- storage.last_beam_time[unit_number] = tick
local MIN_BEAM_INTERVAL = 15  -- Minimum ticks between beams (~0.25 seconds)

function visual_effects.init_storage()
  storage.last_beam_time = storage.last_beam_time or {}
end

-- Draw beam with throttling (for auto-transfers that happen frequently)
function visual_effects.draw_transfer_beam_throttled(entity, direction, is_fluid)
  if not entity or not entity.valid then return end

  visual_effects.init_storage()

  local unit_number = entity.unit_number
  local current_tick = game.tick
  local last_tick = storage.last_beam_time[unit_number] or 0

  if current_tick - last_tick >= MIN_BEAM_INTERVAL then
    visual_effects.draw_transfer_beam(entity, direction, is_fluid)
    storage.last_beam_time[unit_number] = current_tick
  end
end

-- Cleanup tracking for removed elevators
function visual_effects.cleanup_elevator(unit_number)
  if storage.last_beam_time then
    storage.last_beam_time[unit_number] = nil
  end
end

return visual_effects
