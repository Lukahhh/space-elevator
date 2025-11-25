-- Space Elevator Mod - Runtime Control
-- Handles runtime logic for space elevator operation

local elevator_controller = require("scripts.elevator-controller")
local construction_stages = require("scripts.construction-stages")
local platform_controller = require("scripts.platform-controller")
local transfer_controller = require("scripts.transfer-controller")
local player_transport = require("scripts.player-transport")

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

    -- Hidden state tracking labels for detecting changes in update callback
    local state_label = container.add{
      type = "label",
      name = "elevator_displayed_stage",
      caption = tostring(stage),
    }
    state_label.visible = false

    local constructing_label = container.add{
      type = "label",
      name = "elevator_displayed_constructing",
      caption = elevator_data.is_constructing and "true" or "false",
    }
    constructing_label.visible = false

    -- Create tabbed interface
    local tab_definitions = {
      {name = "construction", caption = is_complete and "Status" or "Construction"},
      {name = "materials", caption = "Materials"},
      {name = "info", caption = "Info"},
    }
    -- Add Docking, Transfer, and Travel tabs for operational elevators
    if is_complete then
      table.insert(tab_definitions, 2, {name = "docking", caption = "Docking"})
      table.insert(tab_definitions, 3, {name = "transfer", caption = "Transfer"})
      table.insert(tab_definitions, 4, {name = "travel", caption = "Travel"})
    end
    local _, tabs = remote.call("entity_gui_lib", "create_tabs", container, tab_definitions)

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

      -- Material progress bar (use companion chest)
      local chest = elevator_data.chest
      local mat_progress = construction_stages.get_material_progress(chest, stage)
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
        -- Start construction button (check companion chest)
        local can_start = construction_stages.check_materials(chest, stage)
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

      local chest = elevator_data.chest
      local mat_status = construction_stages.get_material_status(chest, stage)
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

      local inventory = construction_stages.get_inventory(chest)
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

    -- ========== Docking Tab (operational elevators only) ==========
    if is_complete and tabs.docking then
      local is_connected = elevator_data.connection_status == "connected"

      tabs.docking.add{
        type = "label",
        caption = "Platform Connection",
        style = "caption_label",
      }

      local dock_flow = tabs.docking.add{type = "flow", direction = "vertical"}
      dock_flow.style.top_margin = 8
      dock_flow.style.vertical_spacing = 4

      -- Connection status
      local status_label = dock_flow.add{
        type = "label",
        caption = {"", "Status: ", is_connected and "Connected" or "Disconnected"},
      }
      if is_connected then
        status_label.style.font_color = {0, 1, 0}  -- Green
      else
        status_label.style.font_color = {1, 0.5, 0}  -- Orange
      end

      if is_connected then
        -- Show connected platform info
        dock_flow.add{
          type = "label",
          caption = {"", "Platform: ", elevator_data.docked_platform_name or "Unknown"},
        }

        -- Undock button
        local undock_flow = dock_flow.add{type = "flow", direction = "horizontal"}
        undock_flow.style.top_margin = 8
        undock_flow.add{
          type = "button",
          name = "elevator_undock",
          caption = "Disconnect",
          tooltip = "Disconnect from the current platform",
        }
      else
        -- Show available platforms
        local planet_name = platform_controller.get_planet_for_surface(entity.surface)

        if planet_name then
          local orbiting = platform_controller.get_orbiting_platforms(planet_name, player.force)
          local platforms_with_docks = {}

          for _, p in ipairs(orbiting) do
            if platform_controller.has_dock(p.platform) then
              table.insert(platforms_with_docks, p)
            end
          end

          dock_flow.add{
            type = "label",
            caption = {"", "Orbiting platforms with docks: ", #platforms_with_docks},
          }.style.top_margin = 8

          if #platforms_with_docks == 0 then
            dock_flow.add{
              type = "label",
              caption = "No platforms with docking stations in orbit.",
              style = "bold_red_label",
            }
            dock_flow.add{
              type = "label",
              caption = "Build a Space Elevator Dock on an orbiting platform.",
            }
          elseif #platforms_with_docks == 1 then
            -- Single platform - show auto-connect button
            local p = platforms_with_docks[1]
            dock_flow.add{
              type = "label",
              caption = {"", "Available: ", p.name},
            }

            local connect_flow = dock_flow.add{type = "flow", direction = "horizontal"}
            connect_flow.style.top_margin = 8
            connect_flow.add{
              type = "button",
              name = "elevator_dock_auto",
              caption = "Connect",
              tooltip = "Connect to " .. p.name,
            }
          else
            -- Multiple platforms - show dropdown
            dock_flow.add{
              type = "label",
              caption = "Select platform to connect:",
            }.style.top_margin = 4

            local dropdown_items = {}
            for _, p in ipairs(platforms_with_docks) do
              table.insert(dropdown_items, p.name)
            end

            local dropdown_flow = dock_flow.add{type = "flow", direction = "horizontal"}
            dropdown_flow.style.top_margin = 4
            dropdown_flow.add{
              type = "drop-down",
              name = "elevator_platform_dropdown",
              items = dropdown_items,
              selected_index = 1,
            }

            dropdown_flow.add{
              type = "button",
              name = "elevator_dock_selected",
              caption = "Connect",
              tooltip = "Connect to selected platform",
            }
          end
        else
          dock_flow.add{
            type = "label",
            caption = "Cannot detect planet - docking unavailable.",
            style = "bold_red_label",
          }
        end
      end
    end

    -- ========== Transfer Tab (operational elevators only) ==========
    if is_complete and tabs.transfer then
      local is_connected = elevator_data.connection_status == "connected"

      tabs.transfer.add{
        type = "label",
        caption = "Cargo Transfer",
        style = "caption_label",
      }

      local transfer_flow = tabs.transfer.add{type = "flow", direction = "vertical"}
      transfer_flow.style.top_margin = 8
      transfer_flow.style.vertical_spacing = 4

      if not is_connected then
        transfer_flow.add{
          type = "label",
          caption = "Connect to a platform to enable transfers.",
          style = "bold_red_label",
        }
      else
        -- Show inventory status
        local status = transfer_controller.get_inventory_status(elevator_data)

        -- Elevator inventory summary
        transfer_flow.add{
          type = "label",
          caption = {"", "Surface Storage: ", status.elevator.used_slots, "/", status.elevator.total_slots, " slots used"},
        }

        -- Dock inventory summary
        transfer_flow.add{
          type = "label",
          caption = {"", "Platform Dock: ", status.dock.used_slots, "/", status.dock.total_slots, " slots used"},
        }

        -- Manual transfer buttons
        transfer_flow.add{
          type = "label",
          caption = "Manual Transfer:",
          style = "bold_label",
        }.style.top_margin = 12

        local manual_flow = transfer_flow.add{type = "flow", direction = "horizontal"}
        manual_flow.style.horizontal_spacing = 8

        manual_flow.add{
          type = "button",
          name = "elevator_transfer_up",
          caption = "Upload 10",
          tooltip = "Transfer 10 items from surface to platform",
        }
        manual_flow.add{
          type = "button",
          name = "elevator_transfer_down",
          caption = "Download 10",
          tooltip = "Transfer 10 items from platform to surface",
        }

        -- Auto transfer mode
        transfer_flow.add{
          type = "label",
          caption = "Automatic Transfer:",
          style = "bold_label",
        }.style.top_margin = 12

        local auto_config = transfer_controller.get_auto_transfer(entity.unit_number)
        local current_mode = auto_config and auto_config.mode or "off"

        local auto_flow = transfer_flow.add{type = "flow", direction = "horizontal"}
        auto_flow.style.horizontal_spacing = 4

        auto_flow.add{
          type = "button",
          name = "elevator_auto_off",
          caption = "Off",
          style = current_mode == "off" and "button" or "tool_button",
          tooltip = "Disable automatic transfers",
        }
        auto_flow.add{
          type = "button",
          name = "elevator_auto_up",
          caption = "Upload",
          style = current_mode == "up" and "button" or "tool_button",
          tooltip = "Automatically upload items to platform",
        }
        auto_flow.add{
          type = "button",
          name = "elevator_auto_down",
          caption = "Download",
          style = current_mode == "down" and "button" or "tool_button",
          tooltip = "Automatically download items from platform",
        }

        -- Status message
        if current_mode ~= "off" then
          transfer_flow.add{
            type = "label",
            caption = {"", "Auto-transfer active: ", current_mode == "up" and "Uploading" or "Downloading"},
          }.style.top_margin = 4
        end
      end
    end

    -- ========== Travel Tab (operational elevators only) ==========
    if is_complete and tabs.travel then
      local is_connected = elevator_data.connection_status == "connected"
      local travel_status = player_transport.get_status(player)

      tabs.travel.add{
        type = "label",
        caption = "Player Transport",
        style = "caption_label",
      }

      local travel_flow = tabs.travel.add{type = "flow", direction = "vertical"}
      travel_flow.style.top_margin = 8
      travel_flow.style.vertical_spacing = 4

      if travel_status.in_transit then
        -- Player is currently traveling
        travel_flow.add{
          type = "label",
          caption = {"", travel_status.direction == "up" and "Ascending to platform..." or "Descending to surface..."},
          style = "bold_label",
        }
        travel_flow.add{
          type = "label",
          caption = {"", "Time remaining: ", travel_status.remaining_seconds, " seconds"},
        }
        travel_flow.add{
          type = "progressbar",
          name = "travel_progress",
          value = 1 - (travel_status.remaining_seconds / 3),  -- 3 second total travel
        }
      elseif not is_connected then
        travel_flow.add{
          type = "label",
          caption = "Connect to a platform to enable travel.",
          style = "bold_red_label",
        }
      else
        -- Show travel options
        travel_flow.add{
          type = "label",
          caption = "Travel between surface and platform.",
        }

        travel_flow.add{
          type = "label",
          caption = {"", "Connected to: ", elevator_data.docked_platform_name or "Unknown"},
        }.style.top_margin = 4

        travel_flow.add{
          type = "label",
          caption = {"", "Travel time: 3 seconds"},
        }

        -- Travel buttons
        local button_flow = travel_flow.add{type = "flow", direction = "horizontal"}
        button_flow.style.top_margin = 12
        button_flow.style.horizontal_spacing = 8

        -- Check if player is on surface or platform
        local player_on_surface = entity.surface.index == player.surface.index
        local can_up, _ = player_transport.can_travel_up(player)
        local can_down, _ = player_transport.can_travel_down(player)

        button_flow.add{
          type = "button",
          name = "elevator_travel_up",
          caption = "Travel to Platform",
          tooltip = "Ascend to the connected platform",
          enabled = can_up,
        }

        button_flow.add{
          type = "button",
          name = "elevator_travel_down",
          caption = "Travel to Surface",
          tooltip = "Descend to the planet surface",
          enabled = can_down,
        }

        -- Hint about position
        if not can_up and not can_down then
          travel_flow.add{
            type = "label",
            caption = "Move closer to the elevator or dock to travel.",
          }.style.top_margin = 8
        end
      end
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
      -- Show docking status in info tab too
      info_flow.add{
        type = "label",
        caption = {"", "Connection: ", elevator_data.connection_status == "connected" and elevator_data.docked_platform_name or "None"},
      }
    end
  end,

  -- Update callback for live refresh
  update_elevator_gui = function(content, entity, player)
    local elevator_data = elevator_controller.get_elevator_data(entity.unit_number)
    if not elevator_data then return end

    local stage = elevator_data.construction_stage or 1
    local is_complete = stage >= construction_stages.STAGE_COMPLETE

    -- Check if GUI state matches current state - if not, do a full refresh
    -- Look for the stage indicator label we added to detect mismatches
    local displayed_stage_label = content["elevator_displayed_stage"]
    if displayed_stage_label then
      local displayed_stage = tonumber(displayed_stage_label.caption) or 0
      local displayed_constructing = content["elevator_displayed_constructing"]
      local was_constructing = displayed_constructing and displayed_constructing.caption == "true"

      -- Refresh if stage changed OR construction state changed
      if displayed_stage ~= stage or was_constructing ~= elevator_data.is_constructing then
        remote.call("entity_gui_lib", "refresh", player.index)
        return
      end
    end

    -- If complete, nothing to update
    if is_complete then return end

    -- Update progress bars
    for _, child in pairs(content.children) do
      if child.type == "tabbed-pane" then
        for _, tab in pairs(child.tabs) do
          local tab_content = tab.content
          if tab_content then
            for _, elem in pairs(tab_content.children) do
              if elem.name == "elevator_material_progress" then
                local chest = elevator_data.chest
                elem.value = construction_stages.get_material_progress(chest, stage)
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
      show_player_inventory = true,  -- Shows player inventory panel on the right
    })
    -- Enable debug mode to troubleshoot registration
    remote.call("entity_gui_lib", "set_debug_mode", true)
  end
end

-- ============================================================================
-- Initialization
-- ============================================================================
script.on_init(function()
  storage.space_elevators = storage.space_elevators or {}
  storage.elevator_count_per_surface = storage.elevator_count_per_surface or {}
  storage.elevators_constructing = storage.elevators_constructing or {}
  platform_controller.init_storage()
  transfer_controller.init_storage()
  player_transport.init_storage()
  register_gui()
end)

script.on_load(function()
  register_gui()
end)

script.on_configuration_changed(function(data)
  storage.space_elevators = storage.space_elevators or {}
  storage.elevator_count_per_surface = storage.elevator_count_per_surface or {}
  storage.elevators_constructing = storage.elevators_constructing or {}
  platform_controller.init_storage()
  transfer_controller.init_storage()
  player_transport.init_storage()
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
  local player = game.get_player(event.player_index)
  if not player then return end

  if element.name == "elevator_start_construction" then
    local entity = remote.call("entity_gui_lib", "get_entity", event.player_index)
    if entity and entity.valid then
      elevator_controller.start_construction(entity.unit_number)
      -- Refresh the GUI
      remote.call("entity_gui_lib", "refresh", event.player_index)
    end

  elseif element.name == "elevator_undock" then
    -- Disconnect from current platform
    local entity = remote.call("entity_gui_lib", "get_entity", event.player_index)
    if entity and entity.valid then
      local elevator_data = elevator_controller.get_elevator_data(entity.unit_number)
      if elevator_data then
        platform_controller.undock(elevator_data)
        remote.call("entity_gui_lib", "refresh", event.player_index)
      end
    end

  elseif element.name == "elevator_dock_auto" then
    -- Auto-connect to single available platform
    local entity = remote.call("entity_gui_lib", "get_entity", event.player_index)
    if entity and entity.valid then
      local elevator_data = elevator_controller.get_elevator_data(entity.unit_number)
      if elevator_data then
        local success, count, msg = platform_controller.try_auto_connect(elevator_data, player.force)
        if not success then
          player.print("[Space Elevator] " .. msg)
        end
        remote.call("entity_gui_lib", "refresh", event.player_index)
      end
    end

  elseif element.name == "elevator_dock_selected" then
    -- Connect to platform selected in dropdown
    local entity = remote.call("entity_gui_lib", "get_entity", event.player_index)
    if entity and entity.valid then
      local elevator_data = elevator_controller.get_elevator_data(entity.unit_number)
      if elevator_data then
        -- Find the dropdown in the GUI
        local dropdown = nil
        local function find_dropdown(elem)
          if elem.name == "elevator_platform_dropdown" then
            dropdown = elem
            return
          end
          if elem.children then
            for _, child in pairs(elem.children) do
              find_dropdown(child)
              if dropdown then return end
            end
          end
        end

        -- Search from the element's parent flow
        local parent = element.parent
        if parent then
          find_dropdown(parent.parent or parent)
        end

        if dropdown and dropdown.selected_index > 0 then
          local selected_name = dropdown.items[dropdown.selected_index]
          local planet_name = platform_controller.get_planet_for_surface(entity.surface)

          if planet_name then
            local orbiting = platform_controller.get_orbiting_platforms(planet_name, player.force)
            for _, p in ipairs(orbiting) do
              if p.name == selected_name and platform_controller.has_dock(p.platform) then
                local success, err = platform_controller.dock(elevator_data, p.platform)
                if not success then
                  player.print("[Space Elevator] Connection failed: " .. err)
                end
                break
              end
            end
          end
        end
        remote.call("entity_gui_lib", "refresh", event.player_index)
      end
    end

  elseif element.name == "elevator_transfer_up" then
    -- Manual upload
    local entity = remote.call("entity_gui_lib", "get_entity", event.player_index)
    if entity and entity.valid then
      local elevator_data = elevator_controller.get_elevator_data(entity.unit_number)
      if elevator_data then
        local result = transfer_controller.transfer_items_up(elevator_data, nil, 10)
        if result.total > 0 then
          player.print("[Space Elevator] Uploaded " .. result.total .. " items")
        elseif result.error then
          player.print("[Space Elevator] " .. result.error)
        else
          player.print("[Space Elevator] No items to upload")
        end
        remote.call("entity_gui_lib", "refresh", event.player_index)
      end
    end

  elseif element.name == "elevator_transfer_down" then
    -- Manual download
    local entity = remote.call("entity_gui_lib", "get_entity", event.player_index)
    if entity and entity.valid then
      local elevator_data = elevator_controller.get_elevator_data(entity.unit_number)
      if elevator_data then
        local result = transfer_controller.transfer_items_down(elevator_data, nil, 10)
        if result.total > 0 then
          player.print("[Space Elevator] Downloaded " .. result.total .. " items")
        elseif result.error then
          player.print("[Space Elevator] " .. result.error)
        else
          player.print("[Space Elevator] No items to download")
        end
        remote.call("entity_gui_lib", "refresh", event.player_index)
      end
    end

  elseif element.name == "elevator_auto_off" then
    local entity = remote.call("entity_gui_lib", "get_entity", event.player_index)
    if entity and entity.valid then
      transfer_controller.set_auto_transfer(entity.unit_number, "off")
      player.print("[Space Elevator] Auto-transfer disabled")
      remote.call("entity_gui_lib", "refresh", event.player_index)
    end

  elseif element.name == "elevator_auto_up" then
    local entity = remote.call("entity_gui_lib", "get_entity", event.player_index)
    if entity and entity.valid then
      transfer_controller.set_auto_transfer(entity.unit_number, "up", 10)
      player.print("[Space Elevator] Auto-upload enabled")
      remote.call("entity_gui_lib", "refresh", event.player_index)
    end

  elseif element.name == "elevator_auto_down" then
    local entity = remote.call("entity_gui_lib", "get_entity", event.player_index)
    if entity and entity.valid then
      transfer_controller.set_auto_transfer(entity.unit_number, "down", 10)
      player.print("[Space Elevator] Auto-download enabled")
      remote.call("entity_gui_lib", "refresh", event.player_index)
    end

  elseif element.name == "elevator_travel_up" then
    -- Travel from surface to platform
    local can_travel, elevator_data = player_transport.can_travel_up(player)
    if can_travel and elevator_data then
      local success, err = player_transport.travel_up(player, elevator_data)
      if not success then
        player.print("[Space Elevator] Cannot travel: " .. (err or "unknown error"))
      end
      remote.call("entity_gui_lib", "refresh", event.player_index)
    else
      player.print("[Space Elevator] Move closer to an operational elevator to travel")
    end

  elseif element.name == "elevator_travel_down" then
    -- Travel from platform to surface
    local can_travel, elevator_data = player_transport.can_travel_down(player)
    if can_travel and elevator_data then
      local success, err = player_transport.travel_down(player, elevator_data)
      if not success then
        player.print("[Space Elevator] Cannot travel: " .. (err or "unknown error"))
      end
      remote.call("entity_gui_lib", "refresh", event.player_index)
    else
      player.print("[Space Elevator] Move closer to a dock connected to an elevator to travel")
    end
  end
end)

-- Tick handler for construction progress
script.on_nth_tick(10, function(event)
  elevator_controller.update_construction(event.tick)
end)

-- Tick handler for automatic item transfers (every 30 ticks = 0.5 seconds)
script.on_nth_tick(30, function(event)
  transfer_controller.process_auto_transfers()
end)

-- Tick handler for player transit (every 10 ticks for smooth countdown)
script.on_nth_tick(10, function(event)
  player_transport.process_transit()
end)

-- ============================================================================
-- Dock Entity Event Handlers (Phase 4)
-- ============================================================================

-- Track when docking stations are built
script.on_event(defines.events.on_built_entity, function(event)
  platform_controller.on_dock_built(event)
end, {{filter = "name", name = "space-elevator-dock"}})

script.on_event(defines.events.on_robot_built_entity, function(event)
  platform_controller.on_dock_built(event)
end, {{filter = "name", name = "space-elevator-dock"}})

-- Track when docking stations are removed
script.on_event(defines.events.on_player_mined_entity, function(event)
  platform_controller.on_dock_removed(event)
end, {{filter = "name", name = "space-elevator-dock"}})

script.on_event(defines.events.on_robot_mined_entity, function(event)
  platform_controller.on_dock_removed(event)
end, {{filter = "name", name = "space-elevator-dock"}})

script.on_event(defines.events.on_entity_died, function(event)
  platform_controller.on_dock_removed(event)
end, {{filter = "name", name = "space-elevator-dock"}})

-- Periodic connection validation (every 5 seconds)
script.on_nth_tick(300, function(event)
  platform_controller.validate_connections()
end)
