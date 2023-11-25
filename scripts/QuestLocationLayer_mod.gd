extends Resource
var enter_tree_code = """
var infini_dungeon = preload("res://mods/Infinite_Dungeon/Objects/Infinite_Dungeon.tscn")

func _enter_tree():
	if location == null:
		return 
	assert (spawn_profile != null)
	if reservation == null:
		clear()
		reservation = QuestLocationSystem.get_reservation(location)
		if reservation != null:
			quest = QuestLocationSystem.get_quest(location)
			assert (is_instance_valid(quest))
			instance_reserved_scene()
	
	QuestLocationSystem.location_enter_tree(location, self)

	var beachlocation = load("res://data/quest_locations/overworld_4_0.tres")
	if location == beachlocation:
		if not find_node("Infinite_Dungeon"):
			var instance = infini_dungeon.instance()
			get_parent().add_child(instance)
"""

func patch():
	var script_path = "res://world/core/QuestLocationLayer.gd"
	var patched_script : GDScript = preload("res://world/core/QuestLocationLayer.gd")

	if !patched_script.has_source_code():
		var file : File = File.new()
		var err = file.open(script_path, File.READ)
		if err != OK:
			push_error("%s failed to load, check that it's included in metadata's Modified Files") % script_path
			return
		patched_script.source_code = file.get_as_text()
		file.close()
	
	var code_lines:Array = patched_script.source_code.split("\n")	

	var function_index_range:Array = []
	function_index_range.push_back(code_lines.find("func _enter_tree():")) 
	if function_index_range[0] >= 0:
		for line_index in range(function_index_range[0], code_lines.size() - 1):
			if code_lines[line_index].begins_with("func "):
				function_index_range.push_back(line_index - 1)
	
	for line_index in range(function_index_range[1],function_index_range[0],-1):
		code_lines.remove(line_index)
	
	code_lines[function_index_range[0]] = enter_tree_code

	patched_script.source_code = ""
	for line in code_lines:
		patched_script.source_code += line + "\n"
	var err = patched_script.reload()
	if err != OK:
		push_error("Failed to patch %s." % script_path)
		return
	print("Patched %s successfully." % script_path)
