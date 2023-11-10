extends Node

export(float) var spawn_chance:float = 0.1
export(Resource) var mirrormatch
func _ready():
	if randf() < spawn_chance:
		self.add_child(mirrormatch.instance())
