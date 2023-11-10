extends DecoratorAction
class_name CheckTrialStats

export (String) var stat_name:String
export (int, "GE", "GT", "LE", "LT", "EQ", "NE") var operator:int
export (float) var threshold_value:float
export (bool) var always_succeed:bool = false

func conditions_met()->bool:
	var value = SaveState.other_data.InfiniteRailwayStats[stat_name]
	if operator == 0:
		return value >= threshold_value
	elif operator == 1:
		return value > threshold_value
	elif operator == 2:
		return value <= threshold_value
	elif operator == 3:
		return value < threshold_value
	elif operator == 4:
		return value == threshold_value
	elif operator == 5:
		return value != threshold_value
	assert (false)
	return false

func run():
	if not conditions_met():
		return always_succeed
	return .run()
