function onInit()
  update();
end

function update()
  local nodeRecord = getDatabaseNode();

  local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
  name.setReadOnly(bReadOnly);
end