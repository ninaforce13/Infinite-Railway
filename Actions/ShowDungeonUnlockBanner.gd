extends Action

export (String) var ability:String = "glide"

func _run():
	var banner = preload("res://mods/Infinite_Dungeon/CutScenes/NewDungeonUnlock.tscn").instance()
	banner.ability = ability
	MenuHelper.add_child(banner)
	yield (banner.run_menu(), "completed")
	banner.queue_free()
	return true
