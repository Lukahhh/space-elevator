-- Space Elevator Mod Settings

data:extend({
  -- ============================================================================
  -- Startup Settings (require game restart)
  -- ============================================================================

  -- Gameplay Balance
  {
    type = "int-setting",
    name = "space-elevator-power-consumption",
    setting_type = "startup",
    default_value = 10,
    minimum_value = 1,
    maximum_value = 100,
    order = "a-a",
  },
  {
    type = "int-setting",
    name = "space-elevator-rocket-parts",
    setting_type = "startup",
    default_value = 0,  -- 0 = no rocket parts needed (true elevator experience)
    minimum_value = 0,
    maximum_value = 100,
    order = "a-b",
  },
  {
    type = "int-setting",
    name = "space-elevator-fluid-tank-capacity",
    setting_type = "startup",
    default_value = 25000,
    minimum_value = 1000,
    maximum_value = 100000,
    order = "a-c",
  },

  -- Construction
  {
    type = "double-setting",
    name = "space-elevator-construction-time-multiplier",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0.1,
    maximum_value = 10.0,
    order = "b-a",
  },
  {
    type = "double-setting",
    name = "space-elevator-material-cost-multiplier",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0.1,
    maximum_value = 10.0,
    order = "b-b",
  },

  -- ============================================================================
  -- Runtime Settings (can change during game)
  -- ============================================================================

  -- Transfer Settings
  {
    type = "int-setting",
    name = "space-elevator-manual-item-transfer",
    setting_type = "runtime-global",
    default_value = 10,
    minimum_value = 1,
    maximum_value = 1000,
    order = "c-a",
  },
  {
    type = "int-setting",
    name = "space-elevator-auto-transfer-rate",
    setting_type = "runtime-global",
    default_value = 10,
    minimum_value = 1,
    maximum_value = 1000,
    order = "c-b",
  },
  {
    type = "int-setting",
    name = "space-elevator-manual-fluid-transfer",
    setting_type = "runtime-global",
    default_value = 1000,
    minimum_value = 100,
    maximum_value = 10000,
    order = "c-c",
  },
  {
    type = "int-setting",
    name = "space-elevator-auto-fluid-transfer-rate",
    setting_type = "runtime-global",
    default_value = 1000,
    minimum_value = 100,
    maximum_value = 10000,
    order = "c-d",
  },

  -- Player Transport
  {
    type = "int-setting",
    name = "space-elevator-travel-time",
    setting_type = "runtime-global",
    default_value = 3,
    minimum_value = 1,
    maximum_value = 30,
    order = "d-a",
  },

  -- Debug/Testing
  {
    type = "bool-setting",
    name = "space-elevator-show-debug-button",
    setting_type = "runtime-global",
    default_value = false,
    order = "e-a",
  },
})
