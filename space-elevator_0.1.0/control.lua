-- Space Elevator Mod - Runtime Control
-- Handles runtime logic for space elevator operation

local elevator_controller = require("scripts.elevator-controller")
local construction_stages = require("scripts.construction-stages")

-- ============================================================================
-- Remote Interface for entity-gui-lib
-- ============================================================================
remote.add_interface("space_elevator", {
  -- Build the construction GUI
  build_elevator_gui = function(container, entity, player)
    local elevator_data = elevator_controller.get_elevator_data(entity.unit_number)

    -- Auto-register untracked elevators (e.g., spawned via command or from older saves)
    if not elevator_data then
      elevator_data = elevator_controller.register_elevator(entity)
    end

    -- Safety check
    if not elevator_data then
      container.add{type = "label", caption = "Error: Could not initialize elevator data"}
      return
    end

    local stage = elevator_data.construction_stage or 1
    local is_complete = stage >= construction_stages.STAGE_COMPLETE

    -- Create tabbed interface
    local _, tabs = remote.call("entity_gui_lib", "create_tabs", container, {
      {name = "construction", caption = is_complete and "Status" or "Construction"},
      {name = "materials", caption = "Materials"},
      {name = "info", caption = "Info"},
    })

    -- ========== Construction/Status Tab ==========
    if is_complete then
      -- Operational status
      tabs.construction.add{
        type = "label",
        caption = "Space Elevator Operational",
        style = "caption_label",
      }

      local status_flow = tabs.construction.add{type = "flow", direction = "vertical"}
      status_flow.style.top_margin = 8

      status_flow.add{
        type = "label",
        caption = "Ready to transfer cargo to orbit.",
      }

      status_flow.add{
        type = "label",
        caption = {"", "Energy: ", string.format("%.1f MW", (entity.energy or 0) / 1000000)},
      }
    else
      -- Construction progress
      local stage_info = construction_stages.get_stage(stage)

      tabs.construction.add{
        type = "label",
        caption = {"", "Stage ", stage, " of ", construction_stages.STAGE_COUNT},
        style = "caption_label",
      }

      tabs.construction.add{
        type = "label",
        caption = stage_info.name,
        style = "bold_label",
      }.style.top_margin = 4

      tabs.construction.add{
        type = "label",
        caption = stage_info.description,
      }.style.top_margin = 4

      -- Material progress bar
      local mat_progress = construction_stages.get_material_progress(entity, stage)
      tabs.construction.add{
        type = "label",
        caption = "Material Progress:",
      }.style.top_margin = 12

      tabs.construction.add{
        type = "progressbar",
        name = "elevator_material_progress",
        value = mat_progress,
      }

      -- Construction progress bar (if building)
      if elevator_data.is_constructing then
        tabs.construction.add{
          type = "label",
          caption = "Construction Progress:",
        }.style.top_margin = 8

        local build_progress = elevator_data.construction_progress / stage_info.construction_time
        tabs.construction.add{
          type = "progressbar",
          name = "elevator_build_progress",
          value = build_progress,
        }

        tabs.construction.add{
          type = "label",
          caption = {"", "Time remaining: ", math.ceil((stage_info.construction_time - elevator_data.construction_progress) / 60), "s"},
          name = "elevator_time_remaining",
        }
      else
        -- Start construction button
        local can_start = construction_stages.check_materials(entity, stage)
        local button_flow = tabs.construction.add{type = "flow", direction = "horizontal"}
        button_flow.style.top_margin = 12

        button_flow.add{
          type = "button",
          name = "elevator_start_construction",
          caption = "Begin Construction",
          enabled = can_start,
          tooltip = can_start and "Start construction of current stage" or "Insert required materials first",
        }
      end
    end

    -- ========== Materials Tab ==========
    if is_complete then
      tabs.materials.add{
        type = "label",
        caption = "Construction Complete",
        style = "caption_label",
      }
      tabs.materials.add{
        type = "label",
        caption = "The space elevator is fully operational.",
      }.style.top_margin = 4
    else
      local stage_info = construction_stages.get_stage(stage)
      tabs.materials.add{
        type = "label",
        caption = {"", "Required for Stage ", stage, ": ", stage_info.name},
        style = "caption_label",
      }

      local mat_status = construction_stages.get_material_status(entity, stage)
      local mat_table = tabs.materials.add{
        type = "table",
        column_count = 3,
      }
      mat_table.style.top_margin = 8
      mat_table.style.horizontal_spacing = 12
      mat_table.style.vertical_spacing = 4

      -- Header
      mat_table.add{type = "label", caption = "Item", style = "bold_label"}
      mat_table.add{type = "label", caption = "Have", style = "bold_label"}
      mat_table.add{type = "label", caption = "Need", style = "bold_label"}

      -- Material rows
      for _, mat in ipairs(mat_status) do
        local item_proto = prototypes.item[mat.name]
        local item_flow = mat_table.add{type = "flow", direction = "horizontal"}
        item_flow.style.vertical_align = "center"
        item_flow.add{
          type = "sprite",
          sprite = "item/" .. mat.name,
          tooltip = item_proto and item_proto.localised_name or mat.name,
        }
        item_flow.add{
          type = "label",
          caption = item_proto and item_proto.localised_name or mat.name,
        }

        local have_label = mat_table.add{
          type = "label",
          caption = tostring(mat.current),
        }
        if mat.satisfied then
          have_label.style.font_color = {0, 1, 0}  -- Green
        else
          have_label.style.font_color = {1, 0.3, 0.3}  -- Red
        end

        mat_table.add{
          type = "label",
          caption = tostring(mat.required),
        }
      end

      -- Show current inventory contents
      tabs.materials.add{
        type = "label",
        caption = "Current Inventory:",
        style = "bold_label",
      }.style.top_margin = 12

      local inventory = construction_stages.get_inventory(entity)
      if inventory and #inventory > 0 then
        remote.call("entity_gui_lib", "create_inventory_display", tabs.materials, {
          inventory = inventory,
          columns = 10,
          show_empty = true,
          interactive = true,  -- Enable click-to-transfer
          mod_name = "space_elevator",
          on_click = "on_inventory_click",
          on_transfer = "on_inventory_transfer",
        })
      else
        tabs.materials.add{
          type = "label",
          caption = "[No accessible inventory - use inserters or close GUI to access vanilla inventory]",
          style = "bold_red_label",
        }
      end

      -- Tip about inserting materials
      tabs.materials.add{
        type = "label",
        caption = "Click slots to insert/remove items, or use inserters.",
      }.style.top_margin = 8
    end

    -- ========== Info Tab ==========
    tabs.info.add{
      type = "label",
      caption = "Space Elevator",
      style = "caption_label",
    }

    local info_flow = tabs.info.add{type = "flow", direction = "vertical"}
    info_flow.style.top_margin = 8
    info_flow.style.vertical_spacing = 4

    info_flow.add{
      type = "label",
      caption = {"", "Status: ", is_complete and "Operational" or "Under Construction"},
    }
    info_flow.add{
      type = "label",
      caption = {"", "Surface: ", entity.surface.name},
    }
    info_flow.add{
      type = "label",
      caption = {"", "Position: ", math.floor(entity.position.x), ", ", math.floor(entity.position.y)},
    }

    if is_complete then
      info_flow.add{
        type = "label",
        caption = {"", "Launches: ", elevator_data.launch_count or 0},
      }
    end
  end,

  -- Update callback for live refresh
  update_elevator_gui = function(content, entity, player)
    local elevator_data = elevator_controller.get_elevator_data(entity.unit_number)
    if not elevator_data then return end

    local stage = elevator_data.construction_stage or 1
    if not construction_stages.STAGE_COMPLETE or stage >= construction_stages.STAGE_COMPLETE then return end

    -- Update progress bars
    for _, child in pairs(content.children) do
      if child.type == "tabbed-pane" then
        for _, tab in pairs(child.tabs) do
          local tab_content = tab.content
          if tab_content then
            for _, elem in pairs(tab_content.children) do
              if elem.name == "elevator_material_progress" then
                elem.value = construction_stages.get_material_progress(entity, stage)
              elseif elem.name == "elevator_build_progress" and elevator_data.is_constructing then
                local stage_info = construction_stages.get_stage(stage)
                elem.value = elevator_data.construction_progress / stage_info.construction_time
              elseif elem.name == "elevator_time_remaining" and elevator_data.is_constructing then
                local stage_info = construction_stages.get_stage(stage)
                local remaining = math.ceil((stage_info.construction_time - elevator_data.construction_progress) / 60)
                elem.caption = {"", "Time remaining: ", remaining, "s"}
              end
            end
          end
        end
      end
    end
  end,

  -- GUI close callback
  close_elevator_gui = function(entity, player)
    -- Optional: cleanup if needed
  end,

  -- Handle start construction
  start_construction = function(unit_number)
    elevator_controller.start_construction(unit_number)
  end,

  -- Handle inventory slot clicks
  on_inventory_click = function(player, slot_index, item_stack, data)
    -- Informational only - actual transfers handled by on_inventory_transfer
  end,

  -- Handle inventory transfers (called after items are moved)
  on_inventory_transfer = function(player, slot_index, item_stack, data)
    -- Refresh the GUI to update material counts
    remote.call("entity_gui_lib", "refresh", player.index)
  end,
})

-- ============================================================================
-- GUI Registration
-- ============================================================================
local function register_gui()
  if remote.interfaces["entity_gui_lib"] then
    remote.call("entity_gui_lib", "register", {
      mod_name = "space_elevator",
      entity_name = "space-elevator",
      title = {"entity-name.space-elevator"},
      on_build = "build_elevator_gui",
      on_update = "update_elevator_gui",
      on_close = "close_elevator_gui",
      update_interval = 20,  -- Update every 20 ticks (~3 times/sec)
    })
  end
end

-- ============================================================================
-- Initialization
-- ============================================================================
script.on_init(function()
  storage.space_elevators = storage.space_elevators or {}
  storage.elevator_count_per_surface = storage.elevator_count_per_surface or {}
  storage.elevators_constructing = storage.elevators_constructing or {}
  register_gui()
end)

script.on_load(function()
  register_gui()
end)

script.on_configuration_changed(function(data)
  storage.space_elevators = storage.space_elevators or {}
  storage.elevator_count_per_surface = storage.elevator_count_per_surface or {}
  storage.elevators_constructing = storage.elevators_constructing or {}
end)

-- ============================================================================
-- Event Handlers
-- ============================================================================

-- Track when space elevators are built
script.on_event(defines.events.on_built_entity, function(event)
  elevator_controller.on_elevator_built(event)
end, {{filter = "name", name = "space-elevator"}})

script.on_event(defines.events.on_robot_built_entity, function(event)
  elevator_controller.on_elevator_built(event)
end, {{filter = "name", name = "space-elevator"}})

-- Track when space elevators are removed
script.on_event(defines.events.on_player_mined_entity, function(event)
  elevator_controller.on_elevator_removed(event)
end, {{filter = "name", name = "space-elevator"}})

script.on_event(defines.events.on_robot_mined_entity, function(event)
  elevator_controller.on_elevator_removed(event)
end, {{filter = "name", name = "space-elevator"}})

script.on_event(defines.events.on_entity_died, function(event)
  elevator_controller.on_elevator_removed(event)
end, {{filter = "name", name = "space-elevator"}})

-- Track rocket launches from space elevator
script.on_event(defines.events.on_rocket_launched, function(event)
  elevator_controller.on_elevator_launch(event)
end)

-- Handle GUI button clicks
script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  if not element or not element.valid then return end

  if element.name == "elevator_start_construction" then
    local entity = remote.call("entity_gui_lib", "get_entity", event.player_index)
    if entity and entity.valid then
      elevator_controller.start_construction(entity.unit_number)
      -- Refresh the GUI
      remote.call("entity_gui_lib", "refresh", event.player_index)
    end
  end
end)

-- Tick handler for construction progress
script.on_nth_tick(10, function(event)
  elevator_controller.update_construction(event.tick)
end)
