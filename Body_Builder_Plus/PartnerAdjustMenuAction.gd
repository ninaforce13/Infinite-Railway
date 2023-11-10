extends Action
class_name PartnerStatAdjustMenuAction
var PartnerAdjustMenu = preload("res://mods/Infinite_Dungeon/Body_Builder_Plus/StatAdjustMenuPlus.tscn")
func _run():
	yield (show_stat_adjust_partner(), "completed")
	return true

func show_stat_adjust_partner():
	var menu = PartnerAdjustMenu.instance()
	add_child(menu)
	yield (menu.run_menu(), "completed")
	menu.queue_free()	
