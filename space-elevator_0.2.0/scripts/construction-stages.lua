-- Space Elevator Construction Stages
-- Defines the 5-stage construction process

local construction_stages = {}

-- Stage definitions
-- Each stage has: name, description, required materials, and construction time (in ticks)
-- Materials stored in companion chest (no weight limits)
construction_stages.stages = {
  [1] = {
    name = "Site Preparation",
    description = "Excavate foundation and prepare the construction site",
    materials = {
      {name = "stone", amount = 500},
      {name = "concrete", amount = 1000},
      {name = "steel-plate", amount = 500},
    },
    construction_time = 60 * 30,  -- 30 seconds
  },
  [2] = {
    name = "Foundation Construction",
    description = "Build the anchor point and base structure",
    materials = {
      {name = "refined-concrete", amount = 2000},
      {name = "steel-plate", amount = 1000},
      {name = "iron-gear-wheel", amount = 500},
      {name = "pipe", amount = 200},
    },
    construction_time = 60 * 45,  -- 45 seconds
  },
  [3] = {
    name = "Tower Assembly",
    description = "Construct the main elevator shaft using materials from across the galaxy",
    materials = {
      -- Nauvis materials
      {name = "processing-unit", amount = 500},
      {name = "electric-engine-unit", amount = 200},
      {name = "low-density-structure", amount = 500},
      -- Vulcanus materials
      {name = "tungsten-plate", amount = 500},
      -- Fulgora materials
      {name = "superconductor", amount = 200},
      -- Gleba materials
      {name = "bioflux", amount = 100},
    },
    construction_time = 60 * 60,  -- 60 seconds
  },
  [4] = {
    name = "Tether Deployment",
    description = "Deploy the space tether to reach orbit",
    materials = {
      -- Using low-density-structure for the tether (carbon composite)
      {name = "low-density-structure", amount = 1000},
      -- Accumulators for energy storage along the tether
      {name = "accumulator", amount = 100},
      {name = "rocket-fuel", amount = 500},
    },
    construction_time = 60 * 45,  -- 45 seconds
  },
  [5] = {
    name = "Activation",
    description = "Power up systems and synchronize with orbital platforms",
    materials = {
      {name = "processing-unit", amount = 200},
      {name = "superconductor", amount = 100},
      {name = "rocket-fuel", amount = 200},
    },
    construction_time = 60 * 30,  -- 30 seconds
  },
}

construction_stages.STAGE_COUNT = 5
construction_stages.STAGE_COMPLETE = 6  -- Stage number indicating fully built

-- Get stage info
function construction_stages.get_stage(stage_number)
  return construction_stages.stages[stage_number]
end

-- Get stage name
function construction_stages.get_stage_name(stage_number)
  if stage_number >= construction_stages.STAGE_COMPLETE then
    return "Operational"
  end
  local stage = construction_stages.stages[stage_number]
  return stage and stage.name or "Unknown"
end

-- Helper to get the construction materials inventory from a chest
-- Now uses companion chest instead of rocket silo cargo (no weight limits!)
function construction_stages.get_inventory(chest)
  if not chest or not chest.valid then return nil end

  -- Get the chest's inventory
  return chest.get_inventory(defines.inventory.chest)
end

-- Check if all materials for a stage are provided
-- chest: the companion chest entity (not the elevator)
function construction_stages.check_materials(chest, stage_number)
  local stage = construction_stages.stages[stage_number]
  if not stage then return false end

  local inventory = construction_stages.get_inventory(chest)
  if not inventory then return false end

  -- Check each required material
  for _, req in ipairs(stage.materials) do
    local count = inventory.get_item_count(req.name)
    if count < req.amount then
      return false
    end
  end

  return true
end

-- Consume materials for a stage (call this when stage construction begins)
-- chest: the companion chest entity (not the elevator)
function construction_stages.consume_materials(chest, stage_number)
  local stage = construction_stages.stages[stage_number]
  if not stage then return false end

  local inventory = construction_stages.get_inventory(chest)
  if not inventory then return false end

  -- Remove each required material
  for _, req in ipairs(stage.materials) do
    inventory.remove({name = req.name, count = req.amount})
  end

  return true
end

-- Get material status for GUI display
-- Returns table of {name, required, current, satisfied}
-- chest: the companion chest entity (not the elevator)
function construction_stages.get_material_status(chest, stage_number)
  local stage = construction_stages.stages[stage_number]
  if not stage then return {} end

  local inventory = construction_stages.get_inventory(chest)
  local status = {}

  for _, req in ipairs(stage.materials) do
    local current = inventory and inventory.get_item_count(req.name) or 0
    table.insert(status, {
      name = req.name,
      required = req.amount,
      current = math.min(current, req.amount),  -- Cap at required for display
      satisfied = current >= req.amount,
    })
  end

  return status
end

-- Calculate overall material progress (0-1) for a stage
-- chest: the companion chest entity (not the elevator)
function construction_stages.get_material_progress(chest, stage_number)
  local stage = construction_stages.stages[stage_number]
  if not stage then return 0 end

  local inventory = construction_stages.get_inventory(chest)
  if not inventory then return 0 end

  local total_required = 0
  local total_provided = 0

  for _, req in ipairs(stage.materials) do
    total_required = total_required + req.amount
    local current = inventory.get_item_count(req.name)
    total_provided = total_provided + math.min(current, req.amount)
  end

  if total_required == 0 then return 1 end
  return total_provided / total_required
end

return construction_stages
