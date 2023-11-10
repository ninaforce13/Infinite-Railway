extends Action

export(NodePath) var warpregion
func _run():
	var node = get_node(warpregion)
	if SaveState.other_data.has("infinite_dungeon_counter"):
		if SaveState.other_data.infinite_dungeon_counter >= 5:
			node.warp_target_scene = "res://mods/Infinite_Dungeon/Rooms/PreBossRoom.tscn"	
			return true	
	node.warp_target_scene = "res://mods/Infinite_Dungeon/Rooms/RangerBattleRoom.tscn"
	SaveState.other_data.infDung_vault_counter = 0
	return true
