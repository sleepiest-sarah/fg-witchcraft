local checkboxes

local prep_dice = {}
local modifier = 0

function onInit()
  checkboxes = {KnowledgeCheckbox, MaterialsCheckbox, AssistanceCheckbox, SacrificeCheckbox,
                GenerosityCheckbox, InspirationCheckbox, BonusDiceCheckbox1, BonusDiceCheckbox2,
                BonusDiceCheckbox3}
              
  registerEvents()
  updateDiceField()
end

function registerEvents()
  RollButton.onButtonPress = rollCraftingDice
  ToolProficiency.onValueChanged = updateDiceField
  ToolModifier.onValueChanged = updateDiceField
end

function rollCraftingDice()
  Comm.throwDice("dice", prep_dice, modifier, "")
  
end

function preparationDiceChange()
  updateDiceField()
end

function updateDiceField()
  prep_dice = {}
  
  local num_dice = 0
  for i,c in pairs(checkboxes) do
    local value = c.getValue()
    num_dice = num_dice + value
    
    if (value == 1) then
      table.insert(prep_dice, "d6")
    end
  end
  
  if (not User.isHost()) then
    
    local actor = ActorManager.getActor("pc", "charsheet.".. User.getCurrentIdentity())
    
    local ability = ToolModifier.getValue()
    ability = DataCommon.ability_stol[string.upper(ability)]
    local ability_mod = ActorManager5E.getAbilityBonus(actor, ability)
    
    local ui_prof_value = ToolProficiency.getValue()
    local prof_multiplier = 0
    if (ui_prof_value == 3) then
      prof_multiplier = .5
    else 
      prof_multiplier = ui_prof_value
    end
    
    local prof = ActorManager5E.getAbilityScore(actor, "prf")
    local prof_mod = prof * prof_multiplier
    
    modifier = ability_mod + prof_mod
  end
  
  CraftingRollView.setValue(tostring(num_dice) .. "d6+" .. tostring(modifier))
end