extends "res://battle/ai/archangels/ArchangelAI.gd"

const DeathParticles = preload("res://sprites/vfx/particles/aleph_death_particles/AlephNullDeathParticles.tscn")
const drinkme = preload("res://data/archangel_moves/alice_drink_me.tres")
const eatme = preload("res://data/archangel_moves/alice_eat_me.tres")
const parry = preload("res://data/battle_moves/parry_stance.tres")
const berserk = preload("res://data/status_effects/berserk.tres")
export (Resource) var main_super_attack:Resource
export (Dictionary) var alt_super_attacks:Dictionary
export (AudioStream) var death_sound:AudioStream

export (Array, Resource) var regular_attacks:Array
export (Array, Resource) var berserk_attacks:Array
export (Resource) var change_the_record:Resource 
export (Resource) var glass_bonds:Resource 
export (Resource) var summon_stage1:Resource 
export (int) var change_record_cooldown
export (int) var minion_cooldown
export (bool) var debug_final
var change_record_turn_counter = 0
var summon_turn_counter = 0
func request_orders():
	
	var orders = []
	change_record_turn_counter += 1
	summon_turn_counter += 1
	var ap_total = fighter.status.ap					
			
	if fighter.status.ap >= 10 or debug_final:
		
		var valid_supers = []
		for flag in alt_super_attacks.keys():
			valid_supers.push_back(alt_super_attacks[flag])
		if main_super_attack:
			valid_supers.push_back([main_super_attack])
		if valid_supers.size() > 0:
			var choice = battle.rand.choice(valid_supers)
			assert (choice is Array)
			for move in choice:
				var order = configure_move(move)
				if order:
					orders.push_back(order)
#			assert (orders.size() > 0)
			if orders.size() > 0:
				return orders		
	
	if hot_potato_inflicted():
		if parry.get_expected_cost(fighter) <= ap_total:
			add_move_to_orders(parry, orders, ap_total)
		if orders.size() >= max_move_orders:
			return orders
			
	if no_minions_found() and minion_cooldown_elapsed():
		var priority_order = configure_move(summon_stage1)
		if priority_order:
			orders.push_back(priority_order)
			orders.push_back(priority_order)
			summon_turn_counter = 0
		if orders.size() >= max_move_orders:
			return orders	
						
	if time_to_change_record():				
		if glass_bonds.get_expected_cost(fighter) <= ap_total:
			add_move_to_orders(glass_bonds, orders, ap_total)	
		if change_the_record.get_expected_cost(fighter) <= ap_total:
			add_move_to_orders(change_the_record, orders, ap_total)	
		change_record_turn_counter = 0		
		if orders.size() >= max_move_orders:
			return orders							
		
	for _i in range(20):
		var move
		if not has_berserk():
			move = battle.rand.choice(regular_attacks)	
		else:
			move = battle.rand.choice(berserk_attacks)	
		move = invert_alice_buffs(move)			
		if move.get_expected_cost(fighter) <= ap_total:
			add_move_to_orders(move, orders, ap_total)	
			if orders.size() >= max_move_orders:
				return orders
			yield (Co.next_frame(), "completed")
	
	if orders.size() <= max_move_orders:
		var order = configure_move(SmackMove)
		if order:
			orders.push_back(order)
	
	return orders

func hot_potato_inflicted():
	if has_berserk():
		return false
	for member in battle.get_fighters():
		if member.team != fighter.team and member.status.has_tag("bomb"):
			return true
			
func invert_alice_buffs(move):
	if move == eatme and fighter.status.has_tag("inflated"):
		return drinkme
	if move == drinkme and fighter.status.has_tag("deflated"):
		return eatme
	return move
	
func minion_cooldown_elapsed():
	return summon_turn_counter >= minion_cooldown and not has_berserk()

func has_berserk():
	for status in fighter.status.get_children():
		if status.effect == berserk:
			return true	
	
func add_move_to_orders(move, orders, _ap_total):
	var priority_order = configure_move(move)
	if priority_order:			
		orders.push_back(priority_order)
		_ap_total -= move.get_expected_cost(fighter)		
			
func time_to_change_record()->bool:
	return change_record_turn_counter >= change_record_cooldown and not has_berserk()
	
func unperformed_ritual()->bool:
	return not fighter.status.has_tag("undying") and not fighter.status.has_tag("resurrected") and not has_berserk()	
	
func no_minions_found():
	var enemy_count = 0
	if has_berserk():
		return false
	for member in battle.get_fighters():
		if member.team == fighter.team:
			enemy_count += 1
	return enemy_count <= 1

func _queue_animate_defeat():
	return battle.queue_animation(Bind.new(self, "animate_defeat_aleph_null"))

func get_hurt_animation_name()->String:
	if fighter.status.hp <= 0:
		return "flee_incomplete"
	return "hurt"

func _run_final_words(promise:Promise):
	yield ($FinalWords.run(), "completed")
	promise.fulfill()

func animate_defeat_aleph_null():
	battle.camera_set_state("defeat", [fighter.slot])
	battle.music.track = null
	
	var death_co = fighter.slot.play_sprite_animation("death")
	
	var final_words_promise = Promise.new()
	_run_final_words(final_words_promise)
	
	for f in battle.get_fighters():
		if f.status_bubble:
			f.status_bubble.fade_out()
	
	yield (death_co, "completed")
	
	fighter.slot.play_sound(death_sound, 1.0, 1.1)
	
	Engine.time_scale = 0.333
	var particles = DeathParticles.instance()
	var aabb = fighter.slot.transform.xform(fighter.slot.get_aabb())
	particles.transform.origin = aabb.position + 0.5 * aabb.size
	fighter.slot.get_parent().add_child(particles)
	
	SceneManager.transition = SceneManager.TransitionKind.TRANSITION_WHITE_FADE
	SceneManager.transition_in()
	
	for f in battle.get_teams()[fighter.team]:
		f.status.dead = true
		f.animate_leave_slot(f.slot)
	
	yield (Co.wait(1.0), "completed")
	Engine.time_scale = 1.0
	
	yield (final_words_promise.join(), "completed")
	
	yield (battle.show_message(Loc.trgf("BATTLE_DESTROYED", fighter.get_pronouns(), fighter.get_name_with_team())), "completed")
	
