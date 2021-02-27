
function onInit()
	onStateChanged();
	onNameUpdated();
end

function onLockChanged()
	onStateChanged();
end


function onStateChanged()
	if header.subwindow then
		header.subwindow.update();
	end
	if main.subwindow then
		main.subwindow.update();
	end
end

function onNameUpdated()
	local nodeRecord = getDatabaseNode()
	
  sTooltip = DB.getValue(nodeRecord, "name", "")
  if sTooltip == "" then
    sTooltip = Interface.getString("library_recordtype_empty_craftingproject")
  end

	setTooltipText(sTooltip)
  
	if header.subwindow and header.subwindow.link then
		header.subwindow.link.setTooltipText(sTooltip);
	end
end
