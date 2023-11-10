extends "res://battle/ai/archangels/ArchangelAI.gd"

const Spotlight = preload("res://nodes/battle_slot/PuppetSpotlight.tscn")

const EFFIGY_FORMS = {
	player = preload("res://data/monster_forms_unlisted/effigy_player.tres"), 
	dog = preload("res://data/monster_forms_unlisted/effigy_dog.tres"), 
	eugene = preload("res://data/monster_forms_unlisted/effigy_eugene.tres"), 
	felix = preload("res://data/monster_forms_unlisted/effigy_felix.tres"), 
	kayleigh = preload("res://data/monster_forms_unlisted/effigy_kayleigh.tres"), 
	meredith = preload("res://data/monster_forms_unlisted/effigy_meredith.tres"), 
	viola = preload("res://data/monster_forms_unlisted/effigy_viola.tres")
}

var num_effigies_spawned = 0
var next_direction = 0
var spotlight = null

func request_orders():
	var orders = .request_orders()
	if orders is GDScriptFunctionState:
		orders = yield (orders, "completed")
	
	var order = BattleOrder.new(fighter, BattleOrder.OrderType.CALLBACK_PRE_FIGHT, Bind.new(self, "swap_places", [next_direction]))
	orders.push_back(order)
	
	var end_order = BattleOrder.new(fighter, BattleOrder.OrderType.CALLBACK_END, Bind.new(self, "recenter"))
	orders.push_back(end_order)
	
	return orders

func _round_starting():
	._round_starting()
	var left = battle.rand.rand_bool()
	next_direction = - 1 if left else 1
	
	var my_slots = get_my_slots(false)
	var my_index = get_my_index(my_slots)
	if my_index + next_direction < 0 or my_index + next_direction >= my_slots.size():
		return 
	
	var target_slot = my_slots[my_index + next_direction]
	
	if not spotlight:
		spotlight = Spotlight.instance()
	if spotlight.get_parent():
		spotlight.get_parent().remove_child(spotlight)
	target_slot.add_child(spotlight)
	spotlight.fade_in()
	
	fighter.slot.sprite_container.idle = "idle_left" if left else "idle_right"

func join_battle(spawned:bool):
	spawn_effigies()
	var result = .join_battle(spawned)
	return result

func get_my_slots(allow_dead:bool)->Array:
	var slots = battle.get_slots()
	var result = []
	var added_fighters = []
	for slot in slots:
		if slot.team == fighter.team:
			if not allow_dead and (slot.get_fighter() == null or slot.get_fighter().status.dead) :
				continue			
			if not slot.get_fighter() in added_fighters:
				result.push_back(slot)
				added_fighters.append(slot.get_fighter())
	return result

func count_occupied_slots(slots)->int:
	var count = 0
	for slot in slots:
		if slot.get_fighter() != null:
			count += 1
	return count

func count_occupied_allied_slots(slots)->int:
	var count = 0
	for slot in slots:
		if slot.get_fighter() != null:
			if slot.get_fighter().team == fighter.team:
				count += 1
	return count	

func get_occupied_ally_slots()->Array:
	var allies = []
	for slot in get_my_slots(false):
		if slot.get_fighter() != null:
			if slot.get_fighter().team == fighter.team and slot.get_fighter() != fighter:
				allies.append(slot.get_fighter())
	return allies

func get_my_index(slots)->int:
	var i = 0
	for slot in slots:
		if slot == fighter.slot:
			return i
		i += 1
	return - 1

func is_vanilla():
	if not SaveState.other_data.has("infDung_lifetime_counter"):
		SaveState.other_data.infDung_lifetime_counter = 0
	return SaveState.other_data.infDung_lifetime_counter < 15

func create_effigy()->bool:
	var effigy_status_cust = load("res://mods/Infinite_Dungeon/status/infdung_effigy.tres")
	var effigy_status = load("res://data/status_effects/effigy.tres")
	var candidates = []
	var teammates = get_occupied_ally_slots()
	var skipflag = false	
	for f in battle.get_fighters():
		skipflag = false
		if f.team == fighter.team:
			continue
		for member in teammates:
			for status in member.status.get_children():
				if status.effect.name != effigy_status.name and status.effect.name != effigy_status_cust.name:
					continue
				if status.effect.victim_character == f.get_characters()[0]:
					skipflag = true
					print("skip flag 1 set")
		if not skipflag or is_vanilla():			
			candidates.push_back(f.get_characters()[0])
			skipflag = false
	if num_effigies_spawned >= candidates.size():
		return false
	var victim = candidates[num_effigies_spawned]
	
	var effigy = FighterNode.new()
	effigy.team = fighter.team
	var controller = preload("res://battle/ai/NoOrdersAI.gd").new()
	effigy.add_child(controller)
	controller.status_bubble_enabled = false
	
	var character = CharacterNode.new()
	character.character = victim.character.duplicate()
	character.character.name = ""
	character.character.tapes = []
	effigy.add_child(character)
	
	var tape = MonsterTape.new()
	if EFFIGY_FORMS.has(victim.character.partner_id):
		tape.form = EFFIGY_FORMS[victim.character.partner_id]
	else :
		tape.form = EFFIGY_FORMS.player
	character.active_tape = tape

	battle.add_child(effigy)
	
	add_effigy_status(effigy, victim)
	
	num_effigies_spawned += 1
	
	if not fighter.battle.join_fighter(effigy):
		battle.remove_child(effigy)
		effigy.queue_free()
		return false
	return true
	
func add_effect_to_team():
	var teammates = get_occupied_ally_slots()
	var candidates = []
	var numberofallies = 0
	var effigy_status = preload("res://data/status_effects/effigy.tres").duplicate()
	var effigy_status_cust = load("res://mods/Infinite_Dungeon/status/infdung_effigy.tres")
	var skipflag = false
	var fusioneffigycount = 0
	for f in battle.get_fighters():
		if f.team == fighter.team:
			continue			
		if f.status.dead:
			continue
		for member in teammates:
			if member.is_fusion():
				for status in member.status.get_children():
					if status.effect.name == effigy_status.name or status.effect.name == effigy_status_cust.name:
						fusioneffigycount += 1
				
				if fusioneffigycount < 2:
					candidates.push_back(f.get_characters()[0])
				skipflag = true
			else:		
				for status in member.status.get_children():
					if status.effect == effigy_status or status.effect == effigy_status_cust:
						if status.effect.victim_character == f.get_characters()[0]:
							skipflag = true
		if not skipflag:
			candidates.push_back(f.get_characters()[0])	
		skipflag = false
	var victim	
	if candidates.size() == 0:
		return
	for member in teammates:
		skipflag = false
		for status in member.status.get_children():
			if status.effect.name == effigy_status.name and not member.is_fusion():
				skipflag = true
				break	
		
		if not skipflag and not member.is_fusion():
			victim  = candidates[numberofallies]	
			add_effigy_status(member, victim, true)
			numberofallies += 1
		if not skipflag and member.is_fusion():
			for candidate in candidates:	
				add_effigy_status(member, candidate, true)
func add_effigy_status(effigy, victim, custom=false):
	var effigy_status
	if custom:
		effigy_status = preload("res://mods/Infinite_Dungeon/status/infdung_effigy.tres").duplicate()
	else: 
		effigy_status = preload("res://data/status_effects/effigy.tres").duplicate()
	effigy_status.victim_character = victim
	effigy_status.creator = fighter
	var effigy_status_node = StatusEffectNode.new()
	effigy_status_node.effect = effigy_status
	effigy_status_node.amount = 1
	effigy.status.add_child(effigy_status_node)	

func spawn_effigies():
	var num_empty_slots = fighter.battle.find_empty_slots(fighter.team).size()
	print(str(num_empty_slots) + "empty slots")

	if num_empty_slots < 2 and not is_vanilla():
		add_effect_to_team()
	if num_empty_slots != 0:	
		for _i in range(num_empty_slots):
			if not create_effigy():
				break
	
	recenter()

func swap_places(direction:int):
	var my_slots = get_my_slots(false)
	var my_index = get_my_index(my_slots)
	if my_index + direction < 0 or my_index + direction >= my_slots.size():
		return 
	
	var swaps = []
	for i in range(my_slots.size()):
		var next = posmod(i + direction, my_slots.size())
		swaps.push_back([i, next])
	
	battle.queue_camera_set_state("dialog", my_slots)
	battle.queue_message(Loc.trgf("BATTLE_SWITCH_PLACES", fighter.get_pronouns(), [fighter.get_name_with_team()]), true)
	do_swaps(my_slots, swaps)

func recenter():
	var my_slots = get_my_slots(false)
	if my_slots.size() <= 1:
		return 
	var my_index = get_my_index(my_slots)
	if my_index == 0:
		do_swaps(my_slots, [[my_index, my_index + 1], [my_index + 1, my_index]])
	elif my_index == my_slots.size() - 1:
		do_swaps(my_slots, [[my_index, my_index - 1], [my_index - 1, my_index]])

func do_swaps(my_slots, swaps):
	var fighters = []
	for slot in my_slots:
		if not slot.get_fighter() in fighters:
			fighters.push_back(slot.get_fighter())
	for swap in swaps:
		if fighters[swap[0]]:
			fighters[swap[0]].get_characters()[0].slot = my_slots[swap[1]]
			fighters[swap[0]].set_preferred_slot()
	
	battle.queue_animation(Bind.new(self, "_animate_swaps", [fighters, my_slots, swaps]))

func _animate_swaps(fighters, my_slots, swaps):
	fighter.slot.sprite_container.idle = "idle"
	if spotlight:
		spotlight.fade_out()
	
	var co_list = []
	var new_slots = {}
	for swap in swaps:
		new_slots[swap[0]] = swap[1]
		co_list.push_back(my_slots[swap[0]].move_to(my_slots[swap[1]].global_transform.origin))
	yield (Co.join(co_list), "completed")
	for i in new_slots.values():
		my_slots[i].clear()
	for i in range(my_slots.size()):
		var fighter = fighters[i]
		if fighter and new_slots.has(i):
			_animate_enter_slot(fighter, my_slots[new_slots[i]])
		my_slots[i].reset_position(true)

func _animate_enter_slot(fighter, slot):
	slot.set_form(fighter.get_general_form())
	slot.set_palette(fighter.get_palette(), false)
