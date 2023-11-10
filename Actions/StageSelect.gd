extends Action
class_name StageSelect

export(int, 0, 1000) var encounter_range_min
export(int, 0, 1000000) var encounter_range_max


func _run():
	if not SaveState.other_data.has("infDung_lifetime_counter"):	
		SaveState.other_data.infDung_lifetime_counter = 0
	if SaveState.other_data.infDung_lifetime_counter >= encounter_range_min and SaveState.other_data.infDung_lifetime_counter < encounter_range_max:		
		return true
	
	return false
	
