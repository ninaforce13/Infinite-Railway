extends BattleMove

export (Array, Resource) var status_effects:Array
export (int) var amount:int = 3
export (int, "All", "At Random") var status_effects_to_apply:int = 0
export (int) var num_at_random:int = 1
export (bool) var fail_if_already_present:bool = false
export (bool) var fail_against_archangels:bool = false
export (String) var fail_if_has_tag:String
export (int) var sacrifice_hp_percent:int = 0
export (bool) var destroys_walls:bool = false
export (int) var min_hits:int = 1
export (int) var max_hits:int = 1
func _execute(battle, user, _argument, attack_params):
	var targets = attack_params.targets	
	attack_params.applied_status = false	
	
	launch_attack(battle, user, targets, attack_params)
		
func get_valid_switches(target)->Array:
	if not target.is_transformed() or target.is_fusion() or not Character.is_human(target.get_character_kind()) or target.status.has_tag("tape_jam"):
		return []
	var tapes = target.get_controller().get_available_tapes()
	for c in target.get_characters():
		tapes.erase(c.current_tape)
	return tapes

func _pre_contact(_battle, _user, _target, _damage):
	var tapes = get_valid_switches(_target)
	if tapes.size() > 0:
		var tape = _battle.rand.choice(tapes)
		_target.get_controller().switch_tape(tape)
		
	if hit_vfx.size() > 0:
		_battle.queue_animation(Bind.new(_target, "animate_vfx_sequence", [hit_vfx, elemental_types]))
	if status_effects.size() > 0:
		for effect in status_effects:			
			_apply_status(_target, effect)	

func get_effect_hint(_user, _target):
	if status_effects_to_apply == 1 and status_effects.size() > 0:
		var total = Vector3()
		for effect in status_effects:
			total += Vector3(1.0 if effect is TypeModifier else 0.0, 1.0 if effect.is_debuff else 0.0, 1.0 if effect.is_buff else 0.0)
		return total / status_effects.size()
	return status_effects	

func _apply_status(target, effect:StatusEffect):
	if fail_if_already_present and target.status.has_effect(effect):
		return 
	if fail_against_archangels and target.get_character_kind() == Character.CharacterKind.ARCHANGEL:
		return 
	if fail_if_has_tag != "" and target.status.has_tag(fail_if_has_tag):
		return 
	
	var a = amount
	apply_status_effect(target, effect, a)

func get_description()->String:
	return Loc.trf(description, {
		"status_effect":"?" if status_effects.size() != 1 else status_effects[0].name, 
		"duration":amount
	})	
	
func _create_attack_params(battle, user, targets:Array, argument)->Dictionary:
	var params = ._create_attack_params(battle, user, targets, argument)
	params.min_hits = argument.get("min_hits", min_hits)
	params.max_hits = argument.get("max_hits", max_hits)
	params.destroys_walls = destroys_walls
	if argument.has("damage_multiplier"):
		params.multiplier = argument.damage_multiplier
	return params	
