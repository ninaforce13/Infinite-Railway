extends "res://mods/Infinite_Dungeon/CustomAI/CustomWeightedAI.gd"

const ORB_MOVE_ORDERS:int = 1

var orb_broken:bool = false

func get_max_move_orders()->int:
	if fighter.is_fusion() and not orb_broken and max_move_orders < ORB_MOVE_ORDERS:
		return ORB_MOVE_ORDERS
	return max_move_orders

func report_species_encounter():
	if not orb_broken and fighter.is_fusion():
		SaveState.stats.get_stat("orb_fusions_encountered").report_event(fighter.get_species())
		return 
	.report_species_encounter()

func _fuse_forms(forms:Array)->BaseForm:
	var kind = Fusions.FusionKind.REGULAR if orb_broken else Fusions.FusionKind.ORB
	return Fusions.fuse_forms(forms, fighter.get_fusion_seed(), kind)

func get_ap_system()->int:
	if orb_broken or not fighter.is_fusion():
		return .get_ap_system()
	return Character.APSystem.ACCUMULATE

func get_adjusted_ap_regen(ap_regen:int)->int:
	if not orb_broken:
		return int(max(0, ap_regen - 2))
	return ap_regen

func is_fusion_power_unlocked()->bool:
	return not orb_broken and fighter.is_fusion()

func get_character_kind()->int:
	if not orb_broken and fighter.is_fusion():
		return Character.CharacterKind.ARCHANGEL
	return .get_character_kind()

func die_fusion()->bool:
	assert (fighter.is_fusion())
	if not orb_broken:
		var yielded_exp = fighter.status.get_exp_yield()
		
		orb_broken = true
		current_general_form = null
		fighter.status.hp = fighter.status.max_hp
		battle.queue_animation(fighter.generate_transform_animation())
		battle.queue_status_update(fighter)
		
		var message = Loc.trf("BATTLE_ORB_BROKE", {
			fusion_name = fighter.get_form_name()
		})
		battle.queue_message(message, true)
		
		if fighter.team != 0:
			battle.exp_yield += yielded_exp
			SaveState.stats.get_stat("kills_orb_fusions").report_event(fighter.get_species())
		
		.report_species_encounter()
		return false
	return .die_fusion()
