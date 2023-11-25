extends Action
class_name StageSelect

const RailwaySettings = preload("res://mods/Infinite_Dungeon/resources/RailwaySettings.tres")
export (RailwaySettings.encounter) var selected_encounter 


func _run():
	if not SaveState.other_data.has("infDung_lifetime_counter"):	
		SaveState.other_data.infDung_lifetime_counter = 0
	
	return RailwaySettings.encounter_threshold_met(selected_encounter)

	
