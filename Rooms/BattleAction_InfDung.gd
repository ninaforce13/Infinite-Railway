extends Action
class_name BattleAction_InfDung

export (String) var encounter_name_override:String = ""
export (int, "Failure", "Success") var result_on_player_win:int = 0
export (int, "Failure", "Success") var result_on_player_loss:int = 1
export (int, "Failure", "Success") var result_on_flee:int = 1
export (bool) var disable_fleeing:bool = false
export (bool) var remove_pawn_on_success:bool = false
export (bool) var skip_banner:bool = true
export(Resource) var railway_shards = preload("res://mods/Infinite_Dungeon/Items/railway_shard.tres")
var rogue_fusion = preload("res://mods/Infinite_Dungeon/CutScenes/WildRogue.tscn")
var RailwaySettings = preload("res://mods/Infinite_Dungeon/resources/RailwaySettings.tres")
var _removed_pawn:bool = false
var fusion_banner = preload("res://mods/Infinite_Dungeon/CutScenes/fusionbanner.tres")
var orb_banner = preload("res://mods/Infinite_Dungeon/CutScenes/orbbanner.tres")
func rogue_fusion_appears()->bool:
	return false
#	return randi() % 100 < RailwaySettings.rogue_fusion_rate #FUTURE UPDATE

func add_fusion(encounter:EncounterConfig):	
	encounter.cutscenes.push_back(rogue_fusion)
	var rogue_cutscene = rogue_fusion.instance()
	var fusion_character = rogue_cutscene.get_node("Fusion")
	rogue_cutscene.remove_child(fusion_character)	
	encounter.add_child(fusion_character)
	fusion_character.character_kind = Character.CharacterKind.MONSTER
	encounter.move_child(fusion_character,1)
	encounter.enable_ai_fusion = false

func add_title_banner(encounter:EncounterConfig):
	if skip_banner:
		return
	if RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE4) or RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE5):
		encounter.title_banner = fusion_banner
	if RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE6) or RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE7):
		encounter.title_banner = orb_banner
		
func _run():	
	hold_railway_shards_in_escrow()
	var e = get_encounter(self, encounter_name_override)
	if rogue_fusion_appears():
		add_fusion(e)
	else:
		add_title_banner(e)
	if e == null:
		push_error("Couldn't find EncounterConfig for BattleAction")
		return false
	e.seed_value = randi()
	if has_mod_properties():
		for character in e.get_character_nodes():
			character.disable_overspill_damage = not SaveState.other_data.InfiniteRailwayProperties["Overspill"]		
	var config = e.get_config()
	if has_mod_properties():
		for fighter in config.fighters:	
			fighter.get_controller().disable_overspill_damage = not SaveState.other_data.InfiniteRailwayProperties["Overspill"]	
			
	var result = yield (_run_encounter(e, config), "completed")
	
	return _handle_battle_result(result)

func has_mod_properties()->bool:
	return SaveState.other_data.has("InfiniteRailwayProperties")

func hold_railway_shards_in_escrow():
	SaveState.other_data.railway_escrow = 0
	if SaveState.inventory.has_item(railway_shards):
		if not SaveState.other_data.has("railway_escrow"):
			SaveState.other_data.railway_escrow = 0		
		print("Holding Railway Shards in escrow")
		var shards_collected = SaveState.inventory.get_item_amount(railway_shards)
		SaveState.other_data.railway_escrow = shards_collected
		SaveState.inventory.consume_item(railway_shards, shards_collected)			

func return_railway_shards_in_escrow():
	if SaveState.other_data.has("railway_escrow"):		
		if SaveState.other_data.railway_escrow > 0:
			SaveState.inventory.add_item(railway_shards, SaveState.other_data.railway_escrow)
			SaveState.other_data.railway_escrow = 0		
		print("Returning Railway Shards from escrow")		

func _handle_battle_result(result):
	var success = false
	if result == 0:
		
		success = result_on_player_win == 1
		return_railway_shards_in_escrow()
	elif result == null:
		
		success = result_on_flee == 1
	else :
		
		success = result_on_player_loss == 1
	
	if remove_pawn_on_success and success and not _removed_pawn:
		_removed_pawn = true
		var pawn = get_pawn()
		if pawn:
			if pawn.is_a_parent_of(self):
				detach_root()
			if blackboard.pawn == pawn or (blackboard.pawn and pawn.is_a_parent_of(blackboard.pawn)):
				blackboard.pawn = null
			pawn.get_parent().remove_child(pawn)
			pawn.queue_free()
	
	return success

func get_pawn():
	if values.size() > 0:
		return values[0]
	return .get_pawn()

func _run_encounter(e:EncounterConfig, config):
	if disable_fleeing:
		config.can_flee = false
	config.advantages = blackboard.advantages if blackboard.has("advantages") else []
	return e.run_encounter(config)

static func get_encounter(a:Node, name:String = "")->EncounterConfig:
	if name == "":
		name = "EncounterConfig"
	if a.has_node(name):
		return a.get_node(name) as EncounterConfig
	if a is Action:
		if a.values.size() > 0 and a.values[0] is EncounterConfig:
			return a.values[0]
		if a.get_pawn().has_node(name):
			return a.get_pawn().get_node(name)
	return null
