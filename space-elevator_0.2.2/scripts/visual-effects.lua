-- Visual Effects Controller
-- Handles rendering of transfer beam effects for the space elevator

local visual_effects = {}

-- Beam configuration
local BEAM_CONFIG = {
  -- Upload beam (surface to platform) - blue
  upload = {
    color = {r = 0.2, g = 0.6, b = 1, a = 0.8},
    base_width = 3,
    max_width = 12,
    base_ttl = 30,  -- Base time to live (~0.5 seconds)
    height = 60,
  },
  -- Download beam (platform to surface) - orange
  download = {
    color = {r = 1, g = 0.5, b = 0.1, a = 0.8},
    base_width = 3,
    max_width = 12,
    base_ttl = 30,
    height = 60,
  },
  -- Fluid transfer beam - cyan/teal
  fluid_upload = {
    color = {r = 0, g = 0.8, b = 0.8, a = 0.7},
    base_width = 4,
    max_width = 10,
    base_ttl = 30,
    height = 60,
  },
  fluid_download = {
    color = {r = 0.8, g = 0.4, b = 0, a = 0.7},
    base_width = 4,
    max_width = 10,
    base_ttl = 30,
    height = 60,
  },
}

-- Active beam tracking
-- storage.active_beams[unit_number][beam_key] = {surface_beam = id, platform_beam = id, ...}
local BEAM_EXTEND_TTL = 45  -- How long to keep beam alive when transfer continues (~0.75 sec)

-- ============================================================================
-- Storage Initialization
-- ============================================================================

function visual_effects.init_storage()
  storage.active_beams = storage.active_beams or {}
  storage.last_beam_time = storage.last_beam_time or {}
end

-- ============================================================================
-- Width Scaling
-- ============================================================================

-- Calculate beam width based on amount transferred
-- More items = wider beam (capped at max_width)
local function calculate_width(config, amount)
  -- Scale: 10 items = base width, 100+ items = max width
  local scale = math.min(1, (amount or 10) / 100)
  return config.base_width + (config.max_width - config.base_width) * scale
end

-- ============================================================================
-- Platform Edge Detection (cached)
-- ============================================================================

local platform_bottom_cache = {}

local function get_platform_bottom_edge(surface, dock_pos)
  local surface_index = surface.index

  -- Check cache first (cache for 5 seconds / 300 ticks)
  local cached = platform_bottom_cache[surface_index]
  if cached and (game.tick - cached.tick) < 300 then
    return cached.bottom_y
  end

  -- Search for tiles in a column below the dock to find where platform ends
  local search_area = {
    left_top = {x = dock_pos.x - 2, y = dock_pos.y},
    right_bottom = {x = dock_pos.x + 2, y = dock_pos.y + 100}
  }

  local tiles = surface.find_tiles_filtered{
    area = search_area,
  }

  -- Find the maximum Y (bottom-most tile)
  local max_y = dock_pos.y
  for _, tile in pairs(tiles) do
    local tile_name = tile.name
    if tile_name and not tile_name:find("out%-of%-map") and not tile_name:find("empty") then
      if tile.position.y > max_y then
        max_y = tile.position.y
      end
    end
  end

  local bottom_y = max_y + 1

  platform_bottom_cache[surface_index] = {
    bottom_y = bottom_y,
    tick = game.tick
  }

  return bottom_y
end

-- ============================================================================
-- Persistent Beam Management
-- ============================================================================

-- Get or create beam tracking for an elevator
local function get_beam_data(unit_number)
  visual_effects.init_storage()
  storage.active_beams[unit_number] = storage.active_beams[unit_number] or {}
  return storage.active_beams[unit_number]
end

-- Check if a render object is still valid (Factorio 2.0 API)
local function is_beam_valid(beam_obj)
  if not beam_obj then return false end
  -- In Factorio 2.0, render objects are LuaRenderObject with .valid property
  return beam_obj.valid
end

-- Destroy old beams for a given key
local function destroy_beams(beam_data, beam_key)
  local beams = beam_data[beam_key]
  if beams then
    if beams.surface_outer and beams.surface_outer.valid then
      beams.surface_outer.destroy()
    end
    if beams.surface_inner and beams.surface_inner.valid then
      beams.surface_inner.destroy()
    end
    if beams.platform_outer and beams.platform_outer.valid then
      beams.platform_outer.destroy()
    end
    if beams.platform_inner and beams.platform_inner.valid then
      beams.platform_inner.destroy()
    end
    beam_data[beam_key] = nil
  end
end

-- ============================================================================
-- Beam Drawing with Persistence
-- ============================================================================

-- Draw or update a transfer beam from the elevator (surface side)
-- Returns the render IDs for outer and inner beams
local function draw_surface_beam(entity, config, width)
  local from_pos = entity.position
  local to_pos = {
    x = from_pos.x,
    y = from_pos.y - config.height,
  }

  -- Draw outer beam
  local outer_id = rendering.draw_line{
    surface = entity.surface,
    from = from_pos,
    to = to_pos,
    color = config.color,
    width = width,
    time_to_live = BEAM_EXTEND_TTL,
  }

  -- Draw inner (brighter core) beam
  local inner_color = {
    r = math.min(1, config.color.r + 0.3),
    g = math.min(1, config.color.g + 0.3),
    b = math.min(1, config.color.b + 0.3),
    a = config.color.a * 0.6,
  }
  local inner_id = rendering.draw_line{
    surface = entity.surface,
    from = from_pos,
    to = to_pos,
    color = inner_color,
    width = math.max(1, width - 2),
    time_to_live = BEAM_EXTEND_TTL,
  }

  return outer_id, inner_id
end

-- Draw or update a transfer beam at the platform dock
-- Returns the render IDs for outer and inner beams
local function draw_platform_beam_internal(dock_entity, config, width)
  if not dock_entity or not dock_entity.valid then return nil, nil end

  local dock_pos = dock_entity.position
  local surface = dock_entity.surface
  local platform_bottom = get_platform_bottom_edge(surface, dock_pos)

  local from_pos = {
    x = dock_pos.x,
    y = platform_bottom + 100,
  }
  local to_pos = {
    x = dock_pos.x,
    y = platform_bottom + 2,
  }

  -- Draw outer beam
  local outer_id = rendering.draw_line{
    surface = surface,
    from = from_pos,
    to = to_pos,
    color = config.color,
    width = width,
    time_to_live = BEAM_EXTEND_TTL,
    render_layer = "zero",
  }

  -- Draw inner beam
  local inner_color = {
    r = math.min(1, config.color.r + 0.3),
    g = math.min(1, config.color.g + 0.3),
    b = math.min(1, config.color.b + 0.3),
    a = config.color.a * 0.6,
  }
  local inner_id = rendering.draw_line{
    surface = surface,
    from = from_pos,
    to = to_pos,
    color = inner_color,
    width = math.max(1, width - 2),
    time_to_live = BEAM_EXTEND_TTL,
    render_layer = "zero",
  }

  return outer_id, inner_id
end

-- Main function to draw/update beams on both surfaces
-- @param elevator_entity: The elevator entity on the surface
-- @param dock_entity: The dock entity on the platform (can be nil)
-- @param direction: "upload" or "download"
-- @param is_fluid: boolean
-- @param amount: number of items/fluid transferred (affects beam width)
local function draw_beam_both(elevator_entity, dock_entity, direction, is_fluid, amount)
  if not elevator_entity or not elevator_entity.valid then return end

  local unit_number = elevator_entity.unit_number
  local beam_data = get_beam_data(unit_number)

  -- Build config key
  local config_key = direction
  if is_fluid then
    config_key = "fluid_" .. direction
  end
  local config = BEAM_CONFIG[config_key] or BEAM_CONFIG.upload

  -- Calculate width based on amount
  local width = calculate_width(config, amount)

  -- Beam key for tracking (separate upload/download beams)
  local beam_key = config_key

  -- Check if we have valid existing beams
  local existing = beam_data[beam_key]
  local needs_new_beam = not existing
    or not is_beam_valid(existing.surface_outer)
    or (existing.width and math.abs(existing.width - width) > 1)  -- Width changed significantly

  if needs_new_beam then
    -- Destroy old beams if they exist
    destroy_beams(beam_data, beam_key)

    -- Create new beams
    local s_outer, s_inner = draw_surface_beam(elevator_entity, config, width)
    local p_outer, p_inner = draw_platform_beam_internal(dock_entity, config, width)

    beam_data[beam_key] = {
      surface_outer = s_outer,
      surface_inner = s_inner,
      platform_outer = p_outer,
      platform_inner = p_inner,
      width = width,
      last_tick = game.tick,
    }
  else
    -- Extend existing beams by recreating with fresh TTL
    -- (Factorio doesn't let us modify time_to_live directly)
    destroy_beams(beam_data, beam_key)

    local s_outer, s_inner = draw_surface_beam(elevator_entity, config, width)
    local p_outer, p_inner = draw_platform_beam_internal(dock_entity, config, width)

    beam_data[beam_key] = {
      surface_outer = s_outer,
      surface_inner = s_inner,
      platform_outer = p_outer,
      platform_inner = p_inner,
      width = width,
      last_tick = game.tick,
    }
  end
end

-- ============================================================================
-- Public API - Item Transfers
-- ============================================================================

function visual_effects.draw_item_upload_beam_both(elevator_entity, dock_entity, amount)
  draw_beam_both(elevator_entity, dock_entity, "upload", false, amount or 10)
end

function visual_effects.draw_item_download_beam_both(elevator_entity, dock_entity, amount)
  draw_beam_both(elevator_entity, dock_entity, "download", false, amount or 10)
end

-- ============================================================================
-- Public API - Fluid Transfers
-- ============================================================================

function visual_effects.draw_fluid_upload_beam_both(elevator_entity, dock_entity, amount)
  draw_beam_both(elevator_entity, dock_entity, "upload", true, amount or 1000)
end

function visual_effects.draw_fluid_download_beam_both(elevator_entity, dock_entity, amount)
  draw_beam_both(elevator_entity, dock_entity, "download", true, amount or 1000)
end

-- ============================================================================
-- Legacy single-surface functions (for backwards compatibility)
-- ============================================================================

function visual_effects.draw_transfer_beam(entity, direction, is_fluid, amount)
  if not entity or not entity.valid then return end

  local config_key = direction
  if is_fluid then
    config_key = "fluid_" .. direction
  end
  local config = BEAM_CONFIG[config_key] or BEAM_CONFIG.upload
  local width = calculate_width(config, amount or 10)

  draw_surface_beam(entity, config, width)
end

function visual_effects.draw_item_upload_beam(entity, amount)
  visual_effects.draw_transfer_beam(entity, "upload", false, amount)
end

function visual_effects.draw_item_download_beam(entity, amount)
  visual_effects.draw_transfer_beam(entity, "download", false, amount)
end

function visual_effects.draw_fluid_upload_beam(entity, amount)
  visual_effects.draw_transfer_beam(entity, "upload", true, amount)
end

function visual_effects.draw_fluid_download_beam(entity, amount)
  visual_effects.draw_transfer_beam(entity, "download", true, amount)
end

-- ============================================================================
-- Cleanup
-- ============================================================================

function visual_effects.cleanup_elevator(unit_number)
  if storage.active_beams then
    local beam_data = storage.active_beams[unit_number]
    if beam_data then
      for beam_key, _ in pairs(beam_data) do
        destroy_beams(beam_data, beam_key)
      end
      storage.active_beams[unit_number] = nil
    end
  end
  if storage.last_beam_time then
    storage.last_beam_time[unit_number] = nil
  end
end

return visual_effects
