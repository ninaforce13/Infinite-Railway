extends Action


func _run():
	if SaveState.other_data.has("infinite_dungeon_counter"):
		SaveState.other_data.infinite_dungeon_counter += 1
		SaveState.other_data.infDung_lifetime_counter += 1
	return true
