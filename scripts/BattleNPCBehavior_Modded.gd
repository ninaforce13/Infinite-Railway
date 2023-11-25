extends DecoratorAction

signal defeated
signal boss_unlocked
signal change_sprite
signal open_vault
signal time_trial

export (String) var met_flag:String = ""
export (Array, String) var dialogue:Array = []
export (AudioStream) var dialogue_audio:AudioStream
export (Array, String) var defeat_dialogue:Array = []
export (AudioStream) var defeat_dialogue_audio:AudioStream
export (PackedScene) var defeat_extra:PackedScene
export (bool) var trigger_on_sight:bool = false
export (float) var sight_range:float = 16.0
export (bool) var trigger_on_ready:bool = false
export (int, "No Action", "Defeat Pose", "Fade Remove", "NPC Fade", "NPC Run Off") var on_defeat:int = 0
export (String, "", "up", "down", "left", "right") var on_defeat_face_direction:String

var room_cleared:bool = false
var RailwaySettings = preload("res://mods/Infinite_Dungeon/resources/RailwaySettings.tres")
onready var detector = $LineOfSightDetector
var iconsave

func override_encounter(encounter, pawn):

	if RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE2):
		return 	pawn.get_node("TripleThreat") if pawn.has_node("TripleThreat") else encounter
	if RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE3):
		return 	pawn.get_node("QuadBattle") if pawn.has_node("QuadBattle") else encounter	
	if RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE4):
		return 	pawn.get_node("FusionStage") if pawn.has_node("FusionStage") else encounter
	if RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE5):
		return 	pawn.get_node("DoubleFusion") if pawn.has_node("DoubleFusion") else encounter
	if RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE6):
		return 	pawn.get_node("OrbFusionStage") if pawn.has_node("OrbFusionStage") else encounter		
	if RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE7):
		return 	pawn.get_node("DoubleOrbs") if pawn.has_node("DoubleOrbs") else encounter
	return encounter
func _ready():
	if Engine.editor_hint:
		return 
	
	var pawn = get_pawn()
	var encounter = pawn.get_node("EncounterConfig") if pawn.has_node("EncounterConfig") else null
	override_encounter(encounter, pawn)
	if ( encounter and encounter.is_defeated() ):
		emit_signal("defeated")
		if on_defeat == 2 or on_defeat == 3 or on_defeat == 4:
			pawn.visible = false
			pawn.queue_free()
			return 
		elif on_defeat == 1:
			pawn.connect("ready", self, "set_defeat_pose", [], CONNECT_ONESHOT)
	elif encounter:
		if pawn.has_node(NodePath("Interaction")):
			pawn.get_node(NodePath("Interaction")).icon_override = preload("res://ui/icons/position_markers/battle_icon.png")
	
	detector.max_distance = sight_range
	if trigger_on_ready and encounter and not encounter.is_defeated():
		var trigger = OnReadyAction.new()
		for child in detector.get_children():
			if child is Action:
				detector.remove_child(child)
				trigger.add_child(child)
		detector.queue_free()
		detector = null
		pawn.call_deferred("add_child", trigger)
	elif not trigger_on_sight or trigger_on_ready or not encounter or encounter.is_defeated():
		detector.queue_free()
		detector = null
	else :
		detector.pawn = detector.get_path_to(pawn)
		$LineOfSightDetector / CheckConditionAction.deny_flags = [encounter.get_defeat_flag()]
	
	if met_flag != "":
		$Cutscene.set_flags = [met_flag]
	
	var action = $Cutscene / Selector / StageSelect / IsUndefeatedAction / MainDialogue
	dialogue = get_random_intro_lines()
	action.messages = dialogue
	action.audio = dialogue_audio
	
	action = $Cutscene / Selector / StageSelect / IsUndefeatedAction / BattleAction
	if not encounter:
		action.queue_free()
		
	action = $Cutscene / Selector / StageSelect2 / IsUndefeatedAction / MainDialogue
	dialogue = get_random_intro_lines()
	action.messages = dialogue
	action.audio = dialogue_audio
	
	action = $Cutscene / Selector / StageSelect2 / IsUndefeatedAction / BattleAction
	if not encounter:
		action.queue_free()		

	action = $Cutscene / Selector / StageSelect3 / IsUndefeatedAction / MainDialogue
	dialogue = get_random_intro_lines()
	action.messages = dialogue
	action.audio = dialogue_audio
	
	action = $Cutscene / Selector / StageSelect3 / IsUndefeatedAction / BattleAction
	if not encounter:
		action.queue_free()		
		
	action = $Cutscene / Selector / StageSelect4 / IsUndefeatedAction / MainDialogue
	dialogue = get_random_intro_lines()
	action.messages = dialogue
	action.audio = dialogue_audio
	
	action = $Cutscene / Selector / StageSelect4 / IsUndefeatedAction / BattleAction
	if not encounter:
		action.queue_free()				
	
	action = $Cutscene / Selector / Sequence / DefeatDialogue
	defeat_dialogue = get_random_defeat_lines()
	action.messages = defeat_dialogue
	action.audio = defeat_dialogue_audio
	
	if defeat_extra:
		var extra = defeat_extra.instance()
		action.get_parent().add_child_below_node(action, extra)	
	
	if on_defeat_face_direction == "":
		$Cutscene / Selector / Sequence / FaceDirectionAction.queue_free()
	else :
		$Cutscene / Selector / Sequence / FaceDirectionAction.direction = on_defeat_face_direction

func get_random_intro_lines():

	var prefusion_lines = [[Loc.tr("RAILWAY_ATTENDANT_PREFUSION1")],
	[Loc.tr("RAILWAY_ATTENDANT_PREFUSION2")],
	[Loc.tr("RAILWAY_ATTENDANT_PREFUSION3")],
	[Loc.tr("RAILWAY_ATTENDANT_PREFUSION4")],
	[Loc.tr("RAILWAY_ATTENDANT_PREFUSION5")],
	[Loc.tr("RAILWAY_ATTENDANT_PREFUSION6")],
	[Loc.tr("RAILWAY_ATTENDANT_PREFUSION7")],
	[Loc.tr("RAILWAY_ATTENDANT_PREFUSION8")],
	[Loc.tr("RAILWAY_ATTENDANT_PREFUSION9")],
	[Loc.tr("RAILWAY_ATTENDANT_PREFUSION10")],
	[Loc.tr("RAILWAY_ATTENDANT_PREFUSION11")],
	[Loc.tr("RAILWAY_ATTENDANT_PREFUSION12")],
	[Loc.tr("RAILWAY_ATTENDANT_PREFUSION13")],
	[Loc.tr("RAILWAY_ATTENDANT_PREFUSION14")],
	[Loc.tr("RAILWAY_ATTENDANT_PREFUSION15")]]
	
	var postfusion_lines = [[Loc.tr("RAILWAY_ATTENDANT_POSTFUSION1")],
	[Loc.tr("RAILWAY_ATTENDANT_POSTFUSION2")],
	[Loc.tr("RAILWAY_ATTENDANT_POSTFUSION3")],
	[Loc.tr("RAILWAY_ATTENDANT_POSTFUSION4")],
	[Loc.tr("RAILWAY_ATTENDANT_POSTFUSION5")],
	[Loc.tr("RAILWAY_ATTENDANT_POSTFUSION6")],
	[Loc.tr("RAILWAY_ATTENDANT_POSTFUSION7")],
	[Loc.tr("RAILWAY_ATTENDANT_POSTFUSION8")],
	[Loc.tr("RAILWAY_ATTENDANT_POSTFUSION9")],
	[Loc.tr("RAILWAY_ATTENDANT_POSTFUSION10")]]	
	
	var orbfusion_lines = [[Loc.tr("RAILWAY_ATTENDANT_ORBFUSION1")],
	[Loc.tr("RAILWAY_ATTENDANT_ORBFUSION2")],
	[Loc.tr("RAILWAY_ATTENDANT_ORBFUSION3")],
	[Loc.tr("RAILWAY_ATTENDANT_ORBFUSION4")],
	[Loc.tr("RAILWAY_ATTENDANT_ORBFUSION5")],
	[Loc.tr("RAILWAY_ATTENDANT_ORBFUSION6")],
	[Loc.tr("RAILWAY_ATTENDANT_ORBFUSION7")],
	[Loc.tr("RAILWAY_ATTENDANT_ORBFUSION8")]]	
	
	var random_line
	if not SaveState.other_data.has("infDung_lifetime_counter"):
		SaveState.other_data.infinite_dungeon_counter = 0
		SaveState.other_data.infDung_lifetime_counter = 0
		SaveState.other_data.infDung_boss_counter = 0
	if RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE1) and not RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE4):
		random_line = randi() % prefusion_lines.size()
		return prefusion_lines[random_line]
	if RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE4) and not RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE6):
		random_line = randi() % postfusion_lines.size()
		return postfusion_lines[random_line]	
	if RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE6):
		random_line = randi() % orbfusion_lines.size()
		return orbfusion_lines[random_line]						
		
	

func get_random_defeat_lines():
	var possible_lines = [
	[Loc.tr("RAILWAY_ATTENDANT_DEFEAT1")],

	[Loc.tr("RAILWAY_ATTENDANT_DEFEAT2")],

	[Loc.tr("RAILWAY_ATTENDANT_DEFEAT3")],

	[Loc.tr("RAILWAY_ATTENDANT_DEFEAT4")],

	[Loc.tr("RAILWAY_ATTENDANT_DEFEAT5")],

	[Loc.tr("RAILWAY_ATTENDANT_DEFEAT6")],

	[Loc.tr("RAILWAY_ATTENDANT_DEFEAT7")],

	[Loc.tr("RAILWAY_ATTENDANT_DEFEAT8")],

	[Loc.tr("RAILWAY_ATTENDANT_DEFEAT9")],

	[Loc.tr("RAILWAY_ATTENDANT_DEFEAT10")],

	[Loc.tr("RAILWAY_ATTENDANT_DEFEAT11")],

	[Loc.tr("RAILWAY_ATTENDANT_DEFEAT12")],

	[Loc.tr("RAILWAY_ATTENDANT_DEFEAT13")]
	]
	var random_line = randi() % possible_lines.size()
	return possible_lines[random_line]
func set_defeat_pose():
	var pawn = get_pawn()
	pawn.state_machine.set_state("Defeated")

func roll_for_vault_open()->bool:	
	return randf() < RailwaySettings.get_vault_value()

func roll_for_time_trial()->bool:
	if has_dungeon_properties():
		if not SaveState.other_data.InfiniteRailwayProperties["TrialChambers"]:
			return false
	var trial_roll = randf()
	return trial_roll < RailwaySettings.time_trial_chance

func has_dungeon_properties()->bool:
	return SaveState.other_data.has("InfiniteRailwayProperties")

func _on_defeated():
	if SaveState.other_data.has("infinite_dungeon_counter"):
		SaveState.other_data.infinite_dungeon_counter += 1
		SaveState.other_data.infDung_lifetime_counter += 1
		if SaveState.other_data.has("infDung_vault_counter"):
			SaveState.other_data.infDung_vault_counter += 1
		else:
			SaveState.other_data.infDung_vault_counter = 1
		if SaveState.other_data.infDung_vault_counter >= 10 and roll_for_vault_open():
			SaveState.other_data.infdung_vault_battle_state = "open"
			SaveState.other_data.infdung_vault_chests_state = "open"
				
			emit_signal("open_vault")
			SaveState.other_data.infDung_vault_counter = 0													
		elif SaveState.other_data.infinite_dungeon_counter >= 5:
				emit_signal("boss_unlocked")			
		elif roll_for_time_trial():
			print("time trial activated")
			emit_signal("time_trial")
	else:
		SaveState.other_data.infinite_dungeon_counter = 1
		SaveState.other_data.infDung_lifetime_counter = 1
		SaveState.other_data.infDung_boss_counter = 0
		SaveState.other_data.infDung_vault_counter = 1
	if detector:
		detector.enabled = false
	room_cleared = true
	emit_signal("defeated")
		
func _enter_tree():
	var pawn = get_pawn()
	var encounter = pawn.get_node("EncounterConfig") if pawn.has_node("EncounterConfig") else null
	if pawn.state_machine:		
		pawn.state_machine.set_state("Idle")
	if encounter and encounter.is_defeated():
		emit_signal("change_sprite")	
		encounter.set_defeated(false)		
		get_parent().set_translation(Vector3(0,0,-3)) 

		var action = $Cutscene / Selector / StageSelect / IsUndefeatedAction / MainDialogue
		dialogue = get_random_intro_lines()
		action.messages = dialogue		
		
		action = $Cutscene / Selector / StageSelect2 / IsUndefeatedAction / MainDialogue
		dialogue = get_random_intro_lines()
		action.messages = dialogue			
		
		action = $Cutscene / Selector / StageSelect3 / IsUndefeatedAction / MainDialogue
		dialogue = get_random_intro_lines()
		action.messages = dialogue		
		
		action = $Cutscene / Selector / StageSelect4 / IsUndefeatedAction / MainDialogue
		dialogue = get_random_intro_lines()
		action.messages = dialogue

		action = $Cutscene / Selector / StageSelect5 / IsUndefeatedAction / MainDialogue
		dialogue = get_random_intro_lines()
		action.messages = dialogue		

		action = $Cutscene / Selector / StageSelect6 / IsUndefeatedAction / MainDialogue
		dialogue = get_random_intro_lines()
		action.messages = dialogue		

		action = $Cutscene / Selector / StageSelect7 / IsUndefeatedAction / MainDialogue
		dialogue = get_random_intro_lines()
		action.messages = dialogue		

		action = $Cutscene / Selector / Sequence / DefeatDialogue
		defeat_dialogue = get_random_defeat_lines()
		action.messages = defeat_dialogue
	if detector:
		detector.enabled = true
	if iconsave:		
		if pawn.has_node(NodePath("Interaction")):
			pawn.get_node(NodePath("Interaction")).icon_override = iconsave
