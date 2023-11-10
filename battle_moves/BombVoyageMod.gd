extends "res://data/battle_move_scripts/GenericAttack.gd"

export (Array, Resource) var explosion_vfx:Array = []

var undying = preload("res://data/status_effects/undying.tres")
var morgante_revive = preload("res://data/archangel_moves/morgante_kayleigh.tres")
func get_expected_hits(user)->Rational:
	var sources = _get_allies(user.battle, user)
	return Rational.new(sources.size(), 1)

func _create_attack_params(battle, user, targets:Array, argument)->Dictionary:
	var params = ._create_attack_params(battle, user, targets, argument)
	params.allies = _get_allies(battle, user)
	params.damage_multiplier = params.allies.size()
	params.ally_slots = []
	for ally in params.allies:
		params.ally_slots.push_back(ally.slot)

		for ally_effect in ally.status.get_effects():
			ally_effect.transfer(user)
		
		if ally.status.moves.has(morgante_revive):
			var index = 0
			for move in ally.status.moves:
				if move == morgante_revive:
					ally.status.moves.remove(index)
					if not user.status.has_tag("undying") and not user.status.has_tag("resurrected"):
						user.status.add_effect(undying, 1)
					break
				index += 1
	return params

func _get_allies(battle, user)->Array:
	var result = []
	for ally in battle.get_active_teams()[user.team]:
		if ally != user:
			result.push_back(ally)
	return result

func is_guaranteed_to_fail(user, targets:Array)->bool:
	if .is_guaranteed_to_fail(user, targets):
		return true
	return _get_allies(user.battle, user).size() == 0

func _animate_attack_vfx(battle, user, target_slots:Array, vfx_params:Dictionary):
	yield (._animate_attack_vfx(battle, user, target_slots, vfx_params), "completed")
	
	var co_list = []
	var offset = (float(vfx_params.ally_slots.size()) - 1.0) * - 0.5
	for i in range(vfx_params.ally_slots.size()):
		var slot = vfx_params.ally_slots[i]
		co_list.push_back(slot.move_to_melee_targets(target_slots, offset * Vector3( - 2.0, 0.0, 3.0)))
		offset += 1.0
	yield (Co.join(co_list), "completed")
	
	co_list.clear()
	for ally in vfx_params.allies:
		co_list.push_back(ally.animate_vfx_sequence(explosion_vfx))
		if ally.status_bubble:
			co_list.push_back(ally.status_bubble.animate_death(true))
	for slot in vfx_params.ally_slots:
		co_list.push_back(slot.play_slot_animation("long_death"))
	yield (Co.join(co_list), "completed")

func _execute(battle, user, argument, attack_params):
	var allies = _get_allies(battle, user)
	var ally_slots = []
	for ally in allies:
		ally_slots.push_back(ally.slot)
	
	._execute(battle, user, argument, attack_params)
	
	battle.queue_animation(Bind.new(self, "_move_allies_back", [ally_slots]))
	for ally in allies:
		ally.get_controller().die(true, false)

func _move_allies_back(slots:Array):
	var co_list = []
	for slot in slots:
		co_list.push_back(slot.reset_position())
	yield (Co.join(co_list), "completed")
