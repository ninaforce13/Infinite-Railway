extends "res://world/core/QuestLocationLayer.gd"
var infini_dungeon = preload("res://mods/Infinite_Dungeon/Objects/Infinite_Dungeon.tscn")

func _enter_tree():
	._enter_tree()
	var beachlocation = load("res://data/quest_locations/overworld_4_0.tres")
	if location == beachlocation:
		if not find_node("Infinite_Dungeon"):
			var instance = infini_dungeon.instance()
			get_parent().add_child(instance)
