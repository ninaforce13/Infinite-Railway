extends Node

export(Resource) var mirrormatch
var RailwaySettings = preload("res://mods/Infinite_Dungeon/resources/RailwaySettings.tres")
func _ready():
	if randf() < RailwaySettings.mirror_match_rate:
		self.add_child(mirrormatch.instance())
