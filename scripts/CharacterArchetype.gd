extends CharacterConfig

enum Archetype {DPS, Tank, Support}

export(Archetype) var archetype
func _ready():
	archetype = randi()%Archetype.size()
	
func generate_tapes(rand:Random, defeat_count:int, exp_points:int)->Array:
	var result = []
	for tape_node in get_tape_nodes():
		if tape_node.conditions_met(defeat_count):
			if tape_node.get("archetype"):
				tape_node.archetype = archetype
			result.push_back(tape_node.generate_tape(rand, defeat_count, exp_points))
	return result
