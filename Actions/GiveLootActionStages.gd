extends Action

export (Array, Resource) var loot_table:Array
export (Resource) var extra_loot_table:Resource
export (int) var max_value:int = 100
export (int) var max_num:int = - 1
var RailwaySettings = preload("res://mods/Infinite_Dungeon/resources/RailwaySettings.tres")
func _run():
	var index = RailwaySettings.get_current_stage()
	if index >= self.loot_table.size():
		index = 0
	var loot_table:Resource = self.loot_table[index]
	
	if blackboard.has("loot_table"):
		loot_table = blackboard.loot_table as Resource
	
	var loot:Array = []
	var rand:Random = Random.new()
	
	if extra_loot_table:
		loot += extra_loot_table.generate_rewards(rand, max_value, max_num)
	
	var total_value = max_value * blackboard.get("loot_value_multiplier", 1)
	
	for _i in range(blackboard.get("loot_multiplier", 1)):
		loot += loot_table.generate_rewards(rand, total_value, max_num)
	
	var co = MenuHelper.give_items(loot)
	if co is GDScriptFunctionState:
		yield (co, "completed")
	
	return true
