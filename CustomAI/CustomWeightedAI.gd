extends AIFighterController

const DEBUG:bool = false
const ORDER_SCORES_PER_FRAME:int = 4

const WallStatusMove = preload("res://data/battle_move_scripts/WallStatusMove.gd")
const Coating = preload("res://data/battle_move_scripts/Coating.gd")
const PureStatus = preload("res://data/battle_move_scripts/PureStatus.gd")
const APSteal = preload("res://data/battle_move_scripts/APSteal.gd")
const Copycat = preload("res://data/battle_move_scripts/Copycat.gd")
const CopyThat = preload("res://data/battle_move_scripts/CopyThat.gd")
const HPDonate = preload("res://data/battle_move_scripts/HPDonate.gd")
const ChangeTheRecord = preload("res://data/battle_move_scripts/ChangeTheRecord.gd")
const ParryStance = preload("res://data/battle_moves/parry_stance.tres")
onready var Summon = load("res://data/battle_move_scripts/Summon.gd")
onready var FissionPower = load("res://data/battle_move_scripts/FissionPower.gd")

enum Category{CATEGORY_WALL, CATEGORY_COATING, CATEGORY_BUFF, CATEGORY_DEBUFF, CATEGORY_ATTACK, CATEGORY_SUMMON, CATEGORY_FISSION_POWER, CATEGORY_MISC}

export (int) var max_move_orders:int = 1
export (int, "No Repeats", "Allow Repeat Moves w/Distinct Targets", "Allow Repeat Orders") var order_repeat_mode:int = 0
export (bool) var allow_multiple_attacks:bool = false

export (float) var cooldown_wall:float = 2
export (float) var cooldown_coating:float = 2
export (float) var cooldown_buff:float = 1
export (float) var cooldown_debuff:float = 1
export (float) var cooldown_attack:float = 0
export (float) var cooldown_summon:float = 3
export (float) var cooldown_fission_power:float = 1
export (float) var cooldown_misc:float = 1

export (float) var weight_wall:float = 1.0
export (float) var weight_defensive_coating:float = 1.0
export (float) var weight_offensive_coating:float = 1.0
export (float) var weight_buff:float = 1.0
export (float) var weight_debuff:float = 1.0
export (float) var weight_attack:float = 3.0
export (float) var weight_summon:float = 1.0
export (float) var weight_fission_power:float = 10.0
export (float) var weight_self_damage:float = 1.0
export (float) var weight_heal:float = 1.0
export (float) var weight_random:float = 0.1
export (float) var weight_ap_steal:float = 2.0
export (float) var weight_ap_cost:float = 0.1
export (float) var weight_copycat:float = 1.5
export (float) var weight_copy_that:float = 1.5
export (float) var weight_change_the_record:float = 1.0
export (float) var multiplier_duplicate_status:float = 0.1
export (float) var multiplier_weak_wall:float = 0.1
export (int) var threshold_max_self_damage_power:int = 0
export (float) var parry_stance_caution:float = 0.95
var RailwaySettings = preload("res://mods/Infinite_Dungeon/resources/RailwaySettings.tres")
var cooldowns:Dictionary
var has_fair_fight:bool = false
var parry_stancers:Dictionary

func _ready():
	cooldowns = {}
	if randf() <= RailwaySettings.ghostly_rate:
		set_ghost()

func set_ghost():
	var effect_node = StatusEffectNode.new()
	effect_node.effect = preload("res://data/status_effects/ghostly.tres")
	effect_node.amount = 4
	fighter.status.add_child(effect_node)	
			
func _post_ready():
	._post_ready()
	
	if not battle.controller:
		yield (battle, "ready")
	battle.controller.connect("moves_refreshed", self, "_on_moves_refreshed")

func request_orders():
	has_fair_fight = battle.has_status_tag("fair_fight")
	
	if not fighter.is_transformed():
		return []
	
	if is_fusion_appropriate():
		fighter.will_fuse = true
		return [BattleOrder.new(fighter, BattleOrder.OrderType.FUSE)]
	
	battle.rand.push("AI")
	
	
	var valid_moves = get_valid_moves()
	
	var ap:int = fighter.status.ap
	var orders = []
	for _i in range(get_max_move_orders()):
		if valid_moves.size() == 0:
			break
		
		var best = choose_best_order(valid_moves, orders if order_repeat_mode == 1 else [])
		if best is GDScriptFunctionState:
			best = yield (best, "completed")
		
		if best == null:
			break
		if order_repeat_mode == 0:
			assert (valid_moves.has(best.order))
			valid_moves.erase(best.order)
		if not allow_multiple_attacks and categorize(best.order) == Category.CATEGORY_ATTACK:
			_remove_attacks(valid_moves)
		
		orders.push_back(best)
		
		ap -= best.order.get_expected_cost(fighter)
		valid_moves = _filter_moves_cost_limit(valid_moves, ap)
	
	if orders.size() == 0:
		orders.push_back(BattleOrder.new(fighter, BattleOrder.OrderType.NOOP))
	
	battle.rand.pop()
	
	return orders

func _remove_attacks(moves:Array)->void :
	for i in range(moves.size() - 1, - 1, - 1):
		if categorize(moves[i]) == Category.CATEGORY_ATTACK:
			moves.remove(i)

func get_max_move_orders()->int:
	return max_move_orders

func _filter_moves_cost_limit(valid_moves:Array, ap:int)->Array:
	var result = []
	for move in valid_moves:
		if move.get_expected_cost(fighter) <= ap:
			result.push_back(move)
	return result

func choose_best_order(valid_moves:Array, exclude_orders:Array):
	
	var valid_orders = []
	for move in valid_moves:
		if not cooldowns.has(move):
			get_move_configurations(valid_orders, move, exclude_orders)
	yield (Co.next_frame(), "completed")
	
	
	
	
	battle.rand.shuffle(valid_orders)
	
	var best_order = null
	var best_score = 0.0
	
	var being_smart = battle.rand.rand_int(100) < ai_smartness
	
	if DEBUG:
		print(fighter.get_name_with_team() + " order scores:")
	
	
	var i = 0
	for order in valid_orders:
		var score = get_order_score(order)
		if DEBUG:
			print(order._to_string() + " Score: " + str(score))
		if score > best_score:
			best_order = order
			best_score = score
			if not being_smart:
				break
		i += 1
		if i % ORDER_SCORES_PER_FRAME == 0:
			yield (Co.next_frame(), "completed")
	
	if DEBUG:
		print(fighter.get_name_with_team() + " end of orders")
	
	if best_order != null:
		update_cooldowns(best_order)
		return best_order
	
	
	battle.rand.shuffle(valid_moves)
	for move in valid_moves:
		var order = configure_move(move)
		if order != null:
			update_cooldowns(order)
			return order
	
	return null

func get_move_configurations(results:Array, move:BattleMove, exclude_orders:Array)->void :
	var base_args = {}
	var config_result = move.configure(battle, fighter, base_args, null)
	assert ( not (config_result is GDScriptFunctionState))
	if not config_result:
		
		return 
	
	if base_args.has("target_slots"):
		results.push_back(BattleOrder.new(fighter, BattleOrder.OrderType.FIGHT, move, base_args))
		return 
	
	var target_sets = get_valid_target_sets(move)
	battle.rand.shuffle(target_sets)
	for targets in target_sets:
		var target_slots = get_target_slots(targets)
		if _has_order(exclude_orders, move, target_slots):
			continue
		var args = base_args.duplicate()
		args.target_slots = target_slots
		results.push_back(BattleOrder.new(fighter, BattleOrder.OrderType.FIGHT, move, args))

func _has_order(orders:Array, move:BattleMove, target_slots:Array):
	for order in orders:
		if order.order == move and order.argument.get("target_slots") == target_slots:
			return true
	return false

func get_order_score(order:BattleOrder)->float:
	assert (order.type == BattleOrder.OrderType.FIGHT)
	var score = 0.0
	var move:BattleMove = order.order
	
	if move is Summon:
		score += weight_summon
	elif move is FissionPower:
		score += weight_fission_power
	
	if get_ap_system() == Character.APSystem.SPEND:
		score -= weight_ap_cost * order.argument.get("cost", move.get_expected_cost(fighter))
	score -= weight_self_damage * float(move.get_damage_to_user(fighter)) / float(fighter.status.hp)
	
	var total_power = get_expected_total_power(move)
	
	var targets = move.get_targets(battle, fighter, order.argument)
	if targets.size() == 0:
		targets.push_back(fighter)
	
	if (move is Copycat or move is CopyThat) and targets.has(fighter):
		return 0.0
	
	var could_be_parried = false
	
	var hit_chance = Rational.new(0, 1)
	
	for target in targets:
		if move.unavoidable:
			hit_chance.add_ip(1)
		else :
			hit_chance.add_ip(BattleFormulas.get_hit_chance(move.accuracy, fighter, target).min_with(1))
		
		var multiplier = - 1.0 if target.team != fighter.team else 1.0
		
		if move is APSteal:
			score -= multiplier * weight_ap_steal * move.ap_to_steal
		if move is ChangeTheRecord:
			score -= multiplier * weight_change_the_record
		if move is Copycat and target.last_used_move:
			score += weight_copycat
		if move is CopyThat:
			score += weight_copy_that
		if move is HPDonate:
			var hp_donate = move.hp_donate_percent * fighter.status.hp / 100
			var overfill = clamp(float(target.status.hp + hp_donate - target.status.max_hp) / target.status.max_hp, 0.0, 1.0)
			score += multiplier * weight_heal * min(target.status.max_hp - target.status.hp, hp_donate) / target.status.max_hp * (1.0 - overfill)
		
		var attack_score = - multiplier * weight_attack * _get_attack_score(move, target)
		score += attack_score
		
		if move.power > 0 and move.physicality == BattleMove.Physicality.MELEE and parry_stancers.has(target.get_instance_id()):
			could_be_parried = true
		
		var effect_hint = move.get_effect_hint(fighter, target)
		if effect_hint is Array:
			for effect in effect_hint:
				var effect_score = get_status_score(effect, target) * multiplier
				if target.team == fighter.team and effect_score > 0.0 and total_power > threshold_max_self_damage_power:
					
					
					effect_score = 0.0
				score += effect_score
		elif effect_hint is Vector3 and total_power == 0:
			var effect_score = get_vector_score(effect_hint) * multiplier
			if target.team == fighter.team and effect_score > 0.0 and total_power > threshold_max_self_damage_power:
				effect_score = 0.0
			score += effect_score
	
	if move is MoveUsingMove and move.target_move == 1:
		var target_move = move.get_target_move(fighter)
		assert (target_move != null)
		if target_move:
			var sub_order = BattleOrder.new(fighter, BattleOrder.OrderType.FIGHT, target_move, {})
			var sub_order_score = get_order_score(sub_order)
			score += sub_order_score * move.num_uses
			if DEBUG:
				print("MoveUsingMove sub order: ", sub_order, " score: ", sub_order_score)
	
	if targets.size() > 0:
		hit_chance.multiply_ip(1, targets.size())
		score *= hit_chance.to_float()
	
	if could_be_parried:
		if DEBUG:print("Could be parried ", order)
		score *= (1.0 - parry_stance_caution)
	
	if fighter.status.has_tag("multistrike"):
		if fighter.status.ap >= move.get_expected_cost(fighter) * 2:
			score *= 2
	
	if score > 0.0:
		score *= lerp(1.0, battle.rand.rand_float(), weight_random)
	
	for child in get_children():
		if child is WeightedAIMovePreference:
			score = child.get_order_score(order, score)
	
	return score

func get_expected_total_power(move:BattleMove)->int:
	return move.get_power(fighter) * move.get_expected_hits(fighter).to_int(100) / 100

func _get_attack_score(move:BattleMove, target)->float:
	var power = get_expected_total_power(move)
	
	var baseline_attack = BattleFormulas.get_stat("melee_attack", 100, 100, fighter.status.level)
	var baseline_defense = BattleFormulas.get_stat("melee_defense", 100, 100, target.status.level)
	var baseline_damage = BattleFormulas.get_damage(null, 100, fighter.status.level, baseline_attack, baseline_defense, [], [], [])
	
	var attack = fighter.status.get_attack_variant(move.physicality)
	var defense = target.status.get_attack_variant(move.physicality)
	var damage = BattleFormulas.get_damage(null, power, fighter.status.level, attack, defense, move.get_types(fighter), target.status.get_types(), fighter.status.get_types())
	
	return float(damage) / float(baseline_damage)

func get_status_score(effect:StatusEffect, target)->float:
	if has_fair_fight and effect.is_removable:
		return 0.0
	var multiplier = 1.0
	if target.status.has_effect(effect):
		multiplier = multiplier_duplicate_status
	if effect is TypeModifier:
		return multiplier * get_coating_score(effect, target)
	elif effect is WallStatus:
		return multiplier * get_wall_score(effect, target)
	elif effect is Healing:
		if target.team != fighter.team:
			return multiplier * weight_heal
		return multiplier * (target.status.max_hp - target.status.hp) * weight_heal
	else :
		if effect is StatModifier:
			multiplier *= effect.stats_affected.size()
		return multiplier * get_vector_score(effect.get_effect_hint(target))

func get_opponents(target)->Array:
	var result = []
	for f in battle.get_fighters(false):
		if f.team != target.team:
			result.push_back(f)
	return result

func get_defense_types(fighters:Array)->Array:
	var result = []
	for f in fighters:
		for type in f.status.get_types():
			result.push_back(type)
	return result

func get_attack_types(fighters:Array, type_modifier:Array = [])->Array:
	var result = []
	for f in fighters:
		for move in get_valid_moves(f):
			if move.power > 0:
				var types = move.elemental_types
				if types.size() == 0:
					if type_modifier.size() > 0:
						types = type_modifier
					else :
						types = f.status.get_types()
				for type in types:
					result.push_back(type)
	return result

func score_type_matchup(attack_types:Array, defense_types:Array)->float:
	var score = 0.0
	for attack in attack_types:
		for defense in defense_types:
			var reaction = ElementalReactions.find(attack, defense)
			if reaction != null:
				if reaction.result_hint == ElementalReaction.ResultHint.NEGATIVE:
					score += 1.0
				elif reaction.result_hint == ElementalReaction.ResultHint.POSITIVE:
					score -= 1.0
	return score

func count_negative_reactions(attack_types:Array, defense_types:Array)->int:
	var count = 0
	for attack in attack_types:
		for defense in defense_types:
			var reaction = ElementalReactions.find(attack, defense)
			if reaction != null:
				if reaction.result_hint == ElementalReaction.ResultHint.NEGATIVE:
					count += 1
	return count

func get_coating_score(effect:TypeModifier, target)->float:
	var score = 0.0
	var opponents = get_opponents(target)
	
	var opponent_types = get_defense_types(opponents)
	var my_types = target.status.get_types()
	if my_types == effect.elemental_types:
		return 0.0
	
	var opposing_attacks = get_attack_types(opponents)
	var my_attacks = get_attack_types([target])
	var my_modified_attacks = get_attack_types([target], effect.elemental_types)
	
	var m = 1.0 if target.team == fighter.team else - 1.0
	
	if m * score_type_matchup(opposing_attacks, my_types) > m * score_type_matchup(opposing_attacks, effect.elemental_types):
		score += weight_defensive_coating if m > 0.0 else weight_offensive_coating
	elif m * score_type_matchup(my_attacks, opponent_types) < m * score_type_matchup(my_modified_attacks, opponent_types):
		score += weight_offensive_coating if m > 0.0 else weight_defensive_coating
	
	return score

func get_wall_score(effect:WallStatus, target)->float:
	if target.team != fighter.team:
		return weight_wall
	
	if target.current_decoy != null:
		return 0.0
	
	var score = weight_wall
	var opponents = get_opponents(target)
	
	var my_types = target.status.get_types()
	var wall_types = [effect.elemental_type]
	
	var opposing_attacks = get_attack_types(opponents)
	
	if score_type_matchup(opposing_attacks, my_types) > score_type_matchup(opposing_attacks, wall_types):
		score += weight_wall
	
	if count_negative_reactions(opposing_attacks, wall_types) > 0:
		score *= multiplier_weak_wall
	
	return score

func get_vector_score(effect:Vector3)->float:
	return effect.y * - weight_debuff + effect.z * weight_buff

func has_buff(status_effects:Array)->bool:
	for status in status_effects:
		if status.is_buff:
			return true
	return false

func has_debuff(status_effects:Array)->bool:
	for status in status_effects:
		if status.is_debuff:
			return true
	return false

func categorize(move:BattleMove):
	if move is WallStatusMove:
		return Category.CATEGORY_WALL
	elif move is Coating:
		return Category.CATEGORY_COATING
	elif move is Summon:
		return Category.CATEGORY_SUMMON
	elif move is FissionPower:
		return Category.CATEGORY_FISSION_POWER
	elif move.get_power(fighter) > 0:
		return Category.CATEGORY_ATTACK
	elif move is PureStatus and has_buff(move.status_effects):
		return Category.CATEGORY_BUFF
	elif move is PureStatus and has_debuff(move.status_effects):
		return Category.CATEGORY_DEBUFF
	return Category.CATEGORY_MISC

func get_category_cooldown(category)->float:
	if category == Category.CATEGORY_WALL:
		return cooldown_wall
	elif category == Category.CATEGORY_COATING:
		return cooldown_coating
	elif category == Category.CATEGORY_SUMMON:
		return cooldown_summon
	elif category == Category.CATEGORY_FISSION_POWER:
		return cooldown_fission_power
	elif category == Category.CATEGORY_ATTACK:
		return cooldown_attack
	elif category == Category.CATEGORY_BUFF:
		return cooldown_buff
	elif category == Category.CATEGORY_DEBUFF:
		return cooldown_debuff
	return cooldown_misc

func update_cooldowns(new_order:BattleOrder)->void :
	if new_order.type == BattleOrder.OrderType.FIGHT:
		var move:BattleMove = new_order.order
		
		var category = categorize(move)
		var cooldown = get_category_cooldown(category)
		cooldowns[move] = cooldowns.get(move, 0.0) + cooldown + 1.0
	
	for move in cooldowns.keys():
		cooldowns[move] -= 1.0
		if cooldowns[move] <= 0.0:
			cooldowns.erase(move)

func notify(id:String, args):
	if id == "move_starting" and args.move.is_move(ParryStance):
		parry_stancers[args.fighter.get_instance_id()] = true
	return .notify(id, args)

func _on_moves_refreshed():
	for id in parry_stancers.keys():
		var f = instance_from_id(id)
		if f == null or not f.status.has_move(ParryStance):
			parry_stancers.erase(id)
