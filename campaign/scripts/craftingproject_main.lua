--stamina/project size
--hide result fields until after a roll

local prep_checkboxes

local prepDiceArray, craftingRollModifier

local tierStamina, tierCraftDice

local SUCCESS_COLOR = "#50cc54"
local FAILURE_COLOR = "#d42b1c"

function onInit()
  prep_checkboxes = {knowledge_checkbox, knowledge_checkbox2, knowledge_checkbox3, materials_checkbox, materials_checkbox2, materials_checkbox3, assistance_checkbox, assistance_checkbox2, assistance_checkbox3, sacrifice_checkbox, generosity_checkbox, inspiration_checkbox}
  
  local node = getDatabaseNode()
  
  registerEvents()
  
  updateTierFields()
  calculateFields()
  
  setResultVisibility(result_value.getValue() ~= "")
  initializeCrafterField()
  initializeCyclers()
  updateResultColor()
	update();
end

function registerEvents()
  for i,c in pairs(prep_checkboxes) do
    c.onValueChanged = calculateFields
  end    
  
  tier.onValueChanged = onTierValueChanged
  difficulty.onValueChanged = onDifficultyChanged
  project_size.onValueChanged = updateSizeFields
  
  DC.onValueChanged = calculateFields
  tool_proficiency.onValueChanged = calculateFields
  tool_modifier.onValueChanged = calculateFields  
  custombonus.onValueChanged = calculateFields
  roll_button.onButtonPress = rollCraftingDice
  
  boon_result.onValueChanged = updateBoonFlawFields
  flaw_result.onValueChanged = updateBoonFlawFields
  
  ActionsManager.registerResultHandler("crafting", onCraftingRoll)
end

function initializeCyclers()
  if (difficulty.getValue() == "-") then
    difficulty.setStringValue("2")
  end
  
  if (project_size.getValue() == "-") then
    project_size.setStringValue("1")
  end
end

function initializeCrafterField()
  if (crafter.getValue() == "") then
    if (not User.isHost() and getDatabaseNode().isOwner()) then
      local current_char = User.getCurrentIdentity()
      if (current_char) then
        crafter.setValue(current_char)
      end
    elseif (User.isHost() and getDatabaseNode.getOwner() == "") then
      crafter.setValue("DM")
    end
  end
end

-------------------
--Event Handlers --
-------------------

function VisDataCleared()
	update();
end

function InvisDataAdded()
	update();
end

function onTierValueChanged()
  updateTierFields()
  calculateFields()
end

function onDifficultyChanged()
  updateDifficultyFields()
  updateSizeFields()
  calculateFields()
end

function update()
	local nodeRecord = getDatabaseNode()
  
  setReadOnlyState(WindowManager.getReadOnlyState(nodeRecord))
end

function onCraftingRoll(source, target, roll)
  
  if (roll.id == getDatabaseNode().getPath()) then
    updateResultFields(roll)
    
    setResultVisibility(true)
    
    local rMessage = ActionsManager.createActionMessage(source, roll);
    Comm.deliverChatMessage(rMessage);
  end
end

function rollCraftingDice()
  local projectname = getDatabaseNode().getChild("name").getValue()
  
  local roll = {sType = "crafting", sDesc = "Crafting Project: " .. projectname, aDice = prepDiceArray, nMod = craftingRollModifier, id = getDatabaseNode().getPath(), bSecret = false};
  
  local identity = User.getCurrentIdentity()
  local actor = identity and ActorManager.getActor("pc", "charsheet."..identity)
  
  ActionsManager.roll(actor, nil, roll, false)
end

--------------------
--Update DB Fields--
--------------------

function updateResultFields(roll)
  local sum = roll.nMod
  local flaws = 0
  local boons = 0
  
  local diceResultsTable = {}
  for i,d in pairs(roll.aDice) do
    if (d.value) then
      sum = sum + d.value
      
      if (d.value == 1) then
        flaws = flaws + 1
      elseif (d.value == 6) then
        boons = boons + 1
      end
      
      table.insert(diceResultsTable, d.value)
    end
  end
  
  result_value.setValue(sum .. " = " .. table.concat(diceResultsTable, "|") .. " + " .. tostring(roll.nMod))
  
  local dc = DC.getValue()
  if (sum >= dc) then
    result_type.setValue("Success")
  else
    result_type.setValue("Failure")
  end
  updateResultColor()
  
  boon_result.setValue(boons)
  flaw_result.setValue(flaws)
end

function updateResultColor()
  local result = result_type.getValue()
  if (result == "Success") then
    result_type.setColor(SUCCESS_COLOR)
  else
    result_type.setColor(FAILURE_COLOR)
  end
end

function updateBoonFlawFields()
  local boons = boon_result.getValue()
  local flaws = flaw_result.getValue()
  
  if (boons > 0) then
    local magical_boons, major_boons, minor_boons = getBoonFlawBuckets(boons)
      
    local boon_table = {}
    if (magical_boons > 0) then
      table.insert(boon_table, tostring(magical_boons) .. " Magical")
    end
    if (major_boons > 0) then
      table.insert(boon_table, tostring(major_boons) .. " Major")
    end
    if (minor_boons > 0) then
      table.insert(boon_table, tostring(minor_boons) .. " Minor")
    end
    
    local boon_string = "(" .. table.concat(boon_table, ",") .. ")"
    boon_result_type.setValue(boon_string)
  else
    boon_result_type.setValue("")
  end
  
  if (flaws > 0) then
    local dangerous_flaws, major_flaws, minor_flaws = getBoonFlawBuckets(flaws)
    
    local flaw_table = {}
    if (dangerous_flaws > 0) then
      table.insert(flaw_table, tostring(dangerous_flaws) .. " Dangerous")
    end
    if (major_flaws > 0) then
      table.insert(flaw_table, tostring(major_flaws) .. " Major")
    end
    if (minor_flaws > 0) then
      table.insert(flaw_table, tostring(minor_flaws) .. " Minor")
    end
    
    local flaw_string = "(" .. table.concat(flaw_table, ",") .. ")"
    flaw_result_type.setValue(flaw_string)
  else 
    flaw_result_type.setValue("")
  end
end

function calculateFields()
  local modifier, custom_bonus = getRollModifier()
  
  if (WC.isRecordCreator(getDatabaseNode())) then
    craftingRollModifier = modifier + custom_bonus
    bonus.setValue(getModifierPrefix(modifier) .. tostring(modifier))
  end
  
  local numPrepDice, prepDice = getPrepDice()
  prepDiceArray = prepDice
  
  local dc = DC.getValue()
  local success = calculateSuccess(dc, numPrepDice, modifier)
  success_pct.setValue(tostring(round(success*100,2)).."%")
  
  local roll_string = tostring(numPrepDice) .. "d6+" .. tostring(modifier)
  roll_string = custom_bonus ~= 0 and roll_string .. "+(" .. tostring(custom_bonus) .. ")" or roll_string
  
  roll_view.setValue(roll_string)  
end

function updateTierFields()
  local tier_num = tier.getValue()
  local tier_data = WC_Data.crafting_tiers[tier_num]
  
  tier_dice.setValue(tostring(tier_data.craft_dice) .. "d6")
  tier_stamina.setValue(tier_data.stamina)
  
  tierCraftDice = tier_data.craft_dice
  tierStamina = tier_data.stamina
end

function updateDifficultyFields()
  if (difficulty.getStringValue() ~= "-") then
    local diff_num = difficulty.getStringValue()
    local dc_value = (diff_num * 5) + 5
    
    DC.setValue(dc_value)
  else
    DC.setValue(0)
  end
end

function updateSizeFields()
  local size_mult = project_size.getStringValue() and tonumber(project_size.getStringValue()) or 0
  local diff_num = difficulty.getStringValue() and tonumber(difficulty.getStringValue()) or 0
  
  local required_stamina = diff_num * size_mult
  project_stamina.setValue(required_stamina)
end

function getRollModifier()
  local identity = User.getCurrentIdentity()
  
  local custom_bonus = custombonus.getValue() or 0
  
  if ((not User.isHost() and not identity) or (User.isHost() and getDatabaseNode().getOwner() == "")) then
    return 0, custom_bonus
  elseif (User.isHost()) then
    return bonus.getValue() or 0, custom_bonus
  end
  
  local actor = ActorManager.getActor("pc", "charsheet.".. identity)
  
  local ability = tool_modifier.getValue()
  ability = DataCommon.ability_stol[string.upper(ability)]
  local ability_mod = ActorManager5E.getAbilityBonus(actor, ability)
  
  local ui_prof_value = tool_proficiency.getValue()
  local prof_multiplier = 0
  if (ui_prof_value == 3) then
    prof_multiplier = .5
  else 
    prof_multiplier = ui_prof_value
  end
  
  local prof = ActorManager5E.getAbilityScore(actor, "prf")
  local prof_mod = prof * prof_multiplier
  
  return ability_mod + prof_mod, custom_bonus
end

function calculateSuccess(dc, numPrepDice, bonus)
  if (dc <= 0 or dc - bonus <= 0) then
    return 1
  end
  
  local target = dc - bonus
  local maxvalue = numPrepDice * 6
  local prob = 0
  for i=target,maxvalue do
    prob = prob + multinomial(i,numPrepDice)
  end
  
  return prob
end

function setReadOnlyState(flag)
	notes.setReadOnly(flag)
  
  tier.setReadOnly(flag)
  DC.setReadOnly(flag)
  difficulty.setReadOnly(flag)
  project_size.setReadOnly(flag)
  project_stamina.setReadOnly(flag)
  spentstamina.setReadOnly(flag)
  
  tool_modifier.setReadOnly(flag)
  tool_proficiency.setReadOnly(flag)
  
  knowledge_notes.setReadOnly(flag)
  materials_notes.setReadOnly(flag)
  assistance_notes.setReadOnly(flag)
  sacrifice_notes.setReadOnly(flag)
  generosity_notes.setReadOnly(flag)
  inspiration_notes.setReadOnly(flag)
  flawboon_notes.setReadOnly(flag)
  
  for i,c in pairs(prep_checkboxes) do
    c.setReadOnly(flag)
  end  
end

function setResultVisibility(flag)
  divider5.setVisible(flag)
  
  result_label.setVisible(flag)
  result_value.setVisible(flag)
  result_type.setVisible(flag)
  
  boon_label.setVisible(flag)
  boon_result.setVisible(flag)
  boon_result_type.setVisible(flag)
  
  flaw_label.setVisible(flag)
  flaw_result.setVisible(flag)
  flaw_result_type.setVisible(flag)
  
  flaws_link.setVisible(flag)
  flaw_boon_link_label.setVisible(flag)
  flawboon_notes_label.setVisible(flag)
  flawboon_notes.setVisible(flag)
end

-----------
--Helpers--
-----------

function getPrepDice()
  local prep_dice = {}
  
  local num_dice = 0
  for i,c in pairs(prep_checkboxes) do
    local value = c.getValue()
    num_dice = num_dice + value
    
    if (value == 1) then
      table.insert(prep_dice, "d6")
    end
  end  
  
  for i=1,tierCraftDice do
    table.insert(prep_dice, "d6")
  end
  
  return table.getn(prep_dice), prep_dice
end

function getBoonFlawBuckets(n)
  local extreme,major,minor = 0,0,0
  
  if (n >= 3) then
    extreme = math.floor(n/3)
    n = math.fmod(n,3)
  end  
  
  if (n == 2) then
    major = 1
  elseif (n == 1) then
    minor = 1
  end
  
  return extreme,major,minor
end

function getModifierPrefix(modifier)
  if (modifier == 0) then
    return ""
  elseif (modifier > 0) then
    return "+"
  else
    return "-"
  end
end

function multinomial(p,n)
  local upperbound = math.floor((p-n)/6)
  
  local sum = 0
  for k=0,upperbound do
    local v = ((math.fmod(k,2) == 0 and 1 or -1) * choose(n,k) * choose(p-(k*6)-1, n-1))
    sum = sum + v
  end  
  
  return sum / (math.pow(6,n))
end

function factorial(n)
  local res = 1
  for i=0,n-1 do
    res = res * (n-i)
  end
  
  return res
end

function choose(n,k)
  return factorial(n)/(factorial(k)*factorial(n-k))  
end

function round(num, precision)
  local mult = 10^(precision or 0)
  return math.floor(num * mult + 0.5) / mult
end