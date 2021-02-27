
local DB_ROOT_NAME = "wcRoot"
local DB_ROOT_UI_NAME = "wcUI"

local ROLLER_CLASS_NAME = "WC_Roller"

local rootNode
local rootUiNode

local userRollerNodes = {}

function onInit()
  registerNodes()
  registerShortcuts()
  
  User.onLogin = onLogin
end

function onLogin(username, activated)
  if (User.isHost()) then
    if (activated and not userRollerNodes[username]) then
      userRollerNodes[username] = rootUiNode.createChild(username, "windowreference")
      DB.setOwner(userRollerNodes[username], username)
    elseif (not activated and userRollerNodes[username]) then
      DB.deleteNode(userRollerNodes[username])
      userRollerNodes[username] = nil
    end
  end
end

function registerNodes()
  if (User.isHost()) then
    rootNode = DB.createNode(DB_ROOT_NAME)
    rootUiNode = DB.createChild(rootNode, DB_ROOT_UI_NAME)
    
    DB.createNode("craftingprojects")
  end
end

function registerShortcuts()
  local uiDbName = User.isHost() and buildPath(DB_ROOT_NAME, DB_ROOT_UI_NAME) or buildPath(DB_ROOT_NAME, DB_ROOT_UI_NAME, User.getUsername())  
  
  --roller
  DesktopManager.registerStackShortcut2(
  "raise_hand_button",
  "raise_hand_button",
  "",
  ROLLER_CLASS_NAME,
  uiDbName,
  true);


  local craftingRecord = {
      bExport = true,
      aDataMap = {"craftingprojects", "reference.craftingprojects"},
      sRecordDisplayClass = "craftingproject",
      sEditMode = "play"
    }

  LibraryData.overrideRecordTypeInfo("craftingproject", craftingRecord)
end

function buildPath(...)
  return table.concat({...}, ".")
end

function isRecordCreator(node)
  return (User.isHost() and node.getOwner() == "") or (not User.isHost() and node.isOwner())
end