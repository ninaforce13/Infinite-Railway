extends "res://nodes/warp_region/WarpRegion.gd"
export(bool) var reset_on_enter_tree = false
export(Array, String) var trial_paths
func _enter_tree():
	if reset_on_enter_tree:
		warp_target_scene = "res://mods/Infinite_Dungeon/Rooms/RangerBattleRoom.tscn"
func open_boss_room():
	print("Boss signal received")	
	warp_target_scene = "res://mods/Infinite_Dungeon/Rooms/PreBossRoom.tscn"

func open_vault():
	print("Vault signal received")
	warp_target_scene = "res://mods/Infinite_Dungeon/Rooms/bootleg_room.tscn"
	
func open_trial():
	var index = randi() % trial_paths.size()
	warp_target_scene = trial_paths[index] 
