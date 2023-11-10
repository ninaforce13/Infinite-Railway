extends Action
class_name ShowMusicSelection

func _run():
	var scene = load("res://mods/Infinite_Dungeon/UI/MusicSelection.tscn")
	var menu = scene.instance()
	MenuHelper.add_child(menu)
	yield (menu.run_menu(), "completed")
	menu.queue_free()
	return true
	

