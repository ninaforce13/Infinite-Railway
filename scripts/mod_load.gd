extends ContentInfo

var quest_location_mod_patch = preload("res://mods/Infinite_Dungeon/resources/questlocationlayer_patch.tres")

func _init():
	quest_location_mod_patch.patch()

