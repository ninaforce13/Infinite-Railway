extends Action
class_name CustomSetFlagAction

export (String) var flag:String = ""
export (bool) var value:bool = true

func _run():
	print("training flag set")
	SaveState.set_flag(flag, value)
	check_unlocks()
	return true
	
func check_unlocks():
	if SaveState.has_flag("infdung_null_defeated") and not SaveState.has_flag("practice_mode_unlocked"):
		var banner = load("res://mods/Infinite_Dungeon/CutScenes/NewDungeonUnlock.tscn").instance()
		banner.ability = "Practice Mode"
		banner.description = " unlocked at dungeon entrance"
		MenuHelper.add_child(banner)
		yield (banner.run_menu(), "completed")
		banner.queue_free()
		
