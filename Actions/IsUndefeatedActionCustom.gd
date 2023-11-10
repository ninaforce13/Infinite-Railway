extends Action
class_name IsUndefeatedActionCustom

export (String) var encounter_name_override:String = ""

func _run():
	var e = BattleAction.get_encounter(self, encounter_name_override)
	if e == null:
		return false
	return not e.is_defeated()
