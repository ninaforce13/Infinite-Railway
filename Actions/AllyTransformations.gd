extends Action
class_name BattleAllyTransformations

export (int) var fighter_team:int = 0

export (String) var animation:String = ""
export (bool) var play_slot_animation:bool = true
export (bool) var play_sprite_animation:bool = true

export (bool) var reset_idle_override:bool = false
export(int) var min_doubles = 65
func _run():
	if not SaveState.other_data.has("infDung_lifetime_counter"):
		return true
	if SaveState.other_data.infDung_lifetime_counter < min_doubles:
		return true
	var battle = get_pawn()
	var fighters = battle.get_teams()[fighter_team]
	var slots = []
	var index = 0
	for fighter in fighters:
		if index == 0:
			index += 1
			continue
		slots.push_back(fighter.slot)
		index += 1
	if slots.size() == 0:
		return true
	
	var co_list = []
	for slot in slots:
		if play_slot_animation:
			co_list.push_back(slot.play_slot_animation(animation))
		if play_sprite_animation:
			co_list.push_back(slot.play_sprite_animation(animation))
	
		if reset_idle_override:
			slot.set_idle_override("")
	
	yield (Co.join(co_list), "completed")
	
	return true
