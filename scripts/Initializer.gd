extends Node

func _enter_tree():	
	SaveState.other_data.infinite_dungeon_counter = 0
	SaveState.other_data.infDung_lifetime_counter = 0
	SaveState.other_data.infDung_boss_counter = 0
	SaveState.other_data.infDung_vault_counter = 0
	if not SaveState.other_data.has("InfiniteRailwayProperties"):
		SaveState.other_data.InfiniteRailwayProperties = {
														"Overspill":true,
														"TrialChambers":true
														}
