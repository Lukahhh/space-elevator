-- Visual Effects Controller
-- Handles rendering of transfer beam effects for the space elevator
-- Uses animated sprites for polished lightning beam visuals

local visual_effects = {}

-- Beam configuration
-- Scale: 1.0 = ~8 tiles tall (256px sprite / 32px per tile)
local BEAM_CONFIG = {
  -- Upload beam (surface to platform) - blue lightning
  upload = {
    animation = "space-elevator-beam-blue",
    base_scale = 2.0,   -- ~16 tiles tall minimum
    max_scale = 3.5,    -- ~28 tiles tall at max transfer
  },
  -- Download beam (platform to surface) - orange lightning
  download = {
    animation = "space-elevator-beam-orange",
    base_scale = 2.0,
    max_scale = 3.5,
  },
  -- Fluid transfer beam - cyan lightning
  fluid_upload = {
    animation = "space-elevator-beam-cyan",
    base_scale = 2.0,
    max_scale = 3.0,
  },
  fluid_download = {
    animation = "space-elevator-beam-orange",
    tint = {r = 0.9, g = 0.5, b = 0.1, a = 1.0},  -- Darker orange for fluid download
    base_scale = 2.0,
    max_scale = 3.0,
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
-- Scale Calculation
-- ============================================================================

-- Calculate beam scale based on amount transferred
-- More items = larger/more intense beam (capped at max_scale)
local function calculate_scale(config, amount)
  -- Scale: 10 items = base scale, 100+ items = max scale
  local t = math.min(1, (amount or 10) / 100)
  return config.base_scale + (config.max_scale - config.base_scale) * t
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
    -- Handle surface animations (now an array of stacked segments)
    if beams.surface_anims then
      for _, anim in pairs(beams.surface_anims) do
        if anim and anim.valid then
          anim.destroy()
        end
      end
    end
    -- Handle single platform animation
    if beams.platform_anim and beams.platform_anim.valid then
      beams.platform_anim.destroy()
    end
    beam_data[beam_key] = nil
  end
end

-- ============================================================================
-- Beam Drawing with Persistence
-- ============================================================================

-- Draw or update a transfer beam from the elevator (surface side)
-- Returns table of animation render objects (stacked for infinite beam effect)
-- @param direction: "upload" or "download" - controls animation sequencing
local function draw_surface_beam(entity, config, scale, direction)
  local pos = entity.position
  local animations = {}

  -- Stack multiple animations to create infinite beam going off-screen
  -- Tighter spacing ensures segments overlap for seamless beam
  local sprite_height = 2.5 * scale  -- Very tight spacing for full overlap
  local num_segments = 12  -- More segments to compensate for tighter spacing
  local frame_stagger = 4  -- Frames to offset each segment (creates traveling effect)

  for i = 0, num_segments - 1 do
    local beam_center = {
      x = pos.x,
      y = pos.y - 2 - (i * sprite_height),  -- Stack upward from silo doors
    }

    -- Calculate animation offset for sequential effect
    -- Upload: bottom starts first (high offset), top starts last (low offset)
    -- Download: top starts first (high offset), bottom starts last (low offset)
    local anim_offset
    if direction == "download" then
      -- Top segments are ahead in animation (beam coming down)
      anim_offset = i * frame_stagger
    else
      -- Bottom segments are ahead in animation (beam going up)
      anim_offset = (num_segments - 1 - i) * frame_stagger
    end

    local success, anim_id = pcall(function()
      return rendering.draw_animation{
        animation = config.animation,
        target = beam_center,
        surface = entity.surface,
        time_to_live = BEAM_EXTEND_TTL,
        animation_speed = 0.5,
        animation_offset = anim_offset,
        x_scale = scale,
        y_scale = scale,
        tint = config.tint,
        render_layer = "explosion",
      }
    end)

    if success and anim_id then
      table.insert(animations, anim_id)
    end
  end

  return animations
end

-- Draw or update a transfer beam at the platform dock
-- Returns the animation render object
local function draw_platform_beam_internal(dock_entity, config, scale)
  if not dock_entity or not dock_entity.valid then return nil end

  local dock_pos = dock_entity.position
  local surface = dock_entity.surface
  local platform_bottom = get_platform_bottom_edge(surface, dock_pos)

  -- Position beam below the platform
  local beam_center = {
    x = dock_pos.x,
    y = platform_bottom + 10,
  }

  -- Draw animated beam with uniform scaling
  local success, anim_id = pcall(function()
    return rendering.draw_animation{
      animation = config.animation,
      target = beam_center,
      surface = surface,
      time_to_live = BEAM_EXTEND_TTL,
      animation_speed = 0.5,
      x_scale = scale,
      y_scale = scale,  -- Uniform scale - no warping
      tint = config.tint,
      render_layer = "explosion",  -- Highest visible layer
    }
  end)

  if not success then
    log("ERROR drawing platform animation: " .. tostring(anim_id))
    return nil
  end

  return anim_id
end

-- Main function to draw/update beams on both surfaces
-- @param elevator_entity: The elevator entity on the surface
-- @param dock_entity: The dock entity on the platform (can be nil)
-- @param direction: "upload" or "download"
-- @param is_fluid: boolean
-- @param amount: number of items/fluid transferred (affects beam scale)
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

  -- Calculate scale based on amount
  local scale = calculate_scale(config, amount)

  -- Beam key for tracking (separate upload/download beams)
  local beam_key = config_key

  -- Check if we have valid existing beams
  local existing = beam_data[beam_key]
  local first_anim_valid = existing and existing.surface_anims and existing.surface_anims[1] and existing.surface_anims[1].valid
  local needs_new_beam = not existing
    or not first_anim_valid
    or (existing.scale and math.abs(existing.scale - scale) > 0.1)  -- Scale changed significantly

  if needs_new_beam then
    -- Destroy old beams if they exist
    destroy_beams(beam_data, beam_key)

    -- Create new animated beams (surface returns array of stacked segments)
    -- Pass direction for sequential animation effect
    local surface_anims = draw_surface_beam(elevator_entity, config, scale, direction)
    local platform_anim = draw_platform_beam_internal(dock_entity, config, scale)

    beam_data[beam_key] = {
      surface_anims = surface_anims,
      platform_anim = platform_anim,
      scale = scale,
      last_tick = game.tick,
    }
  else
    -- Extend existing beams by recreating with fresh TTL
    -- (Factorio doesn't let us modify time_to_live directly)
    destroy_beams(beam_data, beam_key)

    local surface_anims = draw_surface_beam(elevator_entity, config, scale, direction)
    local platform_anim = draw_platform_beam_internal(dock_entity, config, scale)

    beam_data[beam_key] = {
      surface_anims = surface_anims,
      platform_anim = platform_anim,
      scale = scale,
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
  local scale = calculate_scale(config, amount or 10)

  -- draw_surface_beam now returns an array, but we don't track it for legacy calls
  draw_surface_beam(entity, config, scale, direction)
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
