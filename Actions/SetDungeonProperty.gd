extends Action
class_name SetDungeonPropertyAction
export (bool) var initialize
export (String, "Overspill", "TrialChambers") var property_name
export (bool) var property_value
func _run():
	if initialize:
		if not SaveState.other_data.has("InfiniteRailwayProperties"):		
			SaveState.other_data.InfiniteRailwayProperties = {
															"Overspill":true,
															"TrialChambers":true
															}
		return true
	SaveState.other_data.InfiniteRailwayProperties[property_name] = property_value
	return true
