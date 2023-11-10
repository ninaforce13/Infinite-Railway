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
export (int, 0, 1000) var stage1_min
export (int, 0, 1000) var stage1_max
export (int, 0, 1000) var stage2_min
export (int, 0, 1000) var stage2_max
export (int, 0, 1000) var stage3_min
export (int, 0, 1000000) var stage3_max
export (float) var bootleg_spawn_chance = 0.05
export (float) var time_trial_chance = 0.2

onready var detector = $LineOfSightDetector
var iconsave
func _ready():
	if Engine.editor_hint:
		return 
	
	var pawn = get_pawn()
	var encounter = pawn.get_node("EncounterConfig") if pawn.has_node("EncounterConfig") else null
	var triple_threat = pawn.get_node("TripleThreat") if pawn.has_node("TripleThreat") else null
	var fusion_stage = pawn.get_node("FusionStage") if pawn.has_node("FusionStage") else null
	var orb_fusion_stage = pawn.get_node("OrbFusionStage") if pawn.has_node("OrbFusionStage") else null
	
	if ( encounter and encounter.is_defeated() ) or ( triple_threat and triple_threat.is_defeated() ) or ( fusion_stage and fusion_stage.is_defeated() ) or ( orb_fusion_stage and orb_fusion_stage.is_defeated() ):
		emit_signal("defeated")
		if on_defeat == 2 or on_defeat == 3 or on_defeat == 4:
			pawn.visible = false
			pawn.queue_free()
			return 
		elif on_defeat == 1:
			pawn.connect("ready", self, "set_defeat_pose", [], CONNECT_ONESHOT)
	elif encounter:
		encounter.connect("defeated", self, "_on_defeated")
		triple_threat.connect("defeated", self, "_on_defeated")
		fusion_stage.connect("defeated", self, "_on_defeated")
		orb_fusion_stage.connect("defeated", self, "_on_defeated")
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

	var prefusion_lines = [["Can't you hear the rumble of Mer-Line?", "It ushers in the divine collision!"],
	["We are the stations, the Mer-Line is the path, and conflict is the ticket...", "All aboard."],
	["Across the cosmic railway, the Mer-Line propels us towards our destiny.", "You are but a bump on our tracks."],
	["Don't mistake us for simple travelers.", "The Mer-Line guides us, and we shall not deviate."],
	["This is not a fight, it's a transit.", "Welcome to your stop on the Mer-Line."],
	["In the grand scheme of the cosmos, the Mer-Line is the thread that weaves realities.", "You are a loose end, needing to be tied."],
	["We are but humble passengers on the Mer-Line.", "We will clear all obstructions... like you."],
	["The Mer-Line's hum sings of conflict.", "An unfortunate chorus for those who stand on it's tracks."],
	["Our God, the Mer-Line, transcends realities and still you wish to fight?", "You've already lost."],
	["The cogs of realities are ever-turning.", "Your defiance is futile."],
	["The Mer-Line's hymn echoes through the cosmic rails, signaling our battle's arrival.", "Ready for departure?"],
	["The Mer-Line is eternal. It has seen countless battles across infinite realities.", "Your resistance is meaningless."],
	["On the Mer-Line, there are no free rides."],
	["The Mer-Line's whistle blows!", "Are you ready for the journey of a lifetime?"],
	["Every track on the Mer-Line leads somewhere, yours happens to lead to defeat."]]
	
	var postfusion_lines = [["Witness the power of the Mer-Line! Two souls, merged into one by the cosmic railway!"],
	["The Mer-Line calls for your defeat!", "Fusion is on the cosmic timetable!"],
	["Stand before the might of Fusion, a gift from the Mer-Line!"],
	["Just as tracks merge on the Mer-Line, so too shall we.", "Prepare to face our combined might!"],
	["Fusion is the next stop on our journey.", "Will you stand against the combined power of the Mer-Line's chosen?"],
	["You challenge not one, but the unified strength of many, blessed by the Mer-Line!"],
	["Behold the spectacle of Fusion! A testament to the power of Mer-Line!"],
	["Your ticket to conflict has been upgraded to a Fusion confrontation.", "Brace for a rough ride!"],
	["Through the cosmic railway, we unite!", "Fusion is not just our power.. it's our faith!"],
	["Our paths converge on the Mer-Line, merging us into a force of unified determination!"]]	
	
	var orbfusion_lines = [["The Mer-Line roars with untamed power! Behold the calamity of Orb Fusions!"],
	["Strap in for a power so immense it derails reality itself!"],
	["The rails tremble as the Mer-Line delivers the erratic power of Orb Fusions!"],
	["The Mer-Line screams out, calling forth the untamed might of the Orb Fusion!"],
	["Just as the Mer-Line traverses realities, the Orb Fusion transcends limitations. Your defeat is imminent!"],
	["Brace yourself for an onslaught of power...", "The Mer-Line's ultimate test of survival!"],
	["This is the Mer-Line's wrath!"],
	["The Mer-Line hums with an erratic rhythm, heralding the arrival of the Orb Fusion.", "Ready for the surge?"]]	
	
	var random_line
	if not SaveState.other_data.has("infDung_lifetime_counter"):
		SaveState.other_data.infinite_dungeon_counter = 0
		SaveState.other_data.infDung_lifetime_counter = 0
		SaveState.other_data.infDung_boss_counter = 0
	if SaveState.other_data.infDung_lifetime_counter >= stage1_min and SaveState.other_data.infDung_lifetime_counter < stage1_max:
		random_line = randi() % prefusion_lines.size()
		return prefusion_lines[random_line]
	if SaveState.other_data.infDung_lifetime_counter >= stage2_min and SaveState.other_data.infDung_lifetime_counter < stage2_max:
		random_line = randi() % postfusion_lines.size()
		return postfusion_lines[random_line]	
	if SaveState.other_data.infDung_lifetime_counter >= stage3_min and SaveState.other_data.infDung_lifetime_counter < stage3_max:
		random_line = randi() % orbfusion_lines.size()
		return orbfusion_lines[random_line]						
		
	

func get_random_defeat_lines():
	var possible_lines = [
	["It seems... I've missed my train..."],

	["A delay in the cosmic schedule. But the Mer-Line... always... resumes..."],

	["My ticket... has been rejected."],

	["Defeat? No, just... a detour on the cosmic railway..."],

	["The signal fades... but The Mer-Line goes on..."],

	["I may fall... but the Mer-Line is eternal."],

	["It seems I've reached my final destination..."],

	["My journey on the Mer-Line... has reached an unforeseen terminal..."],

	["The rails have faded... but The Mer-Line's journey never ends..."],

	["You may have halted my journey, but the Mer-Line goes on..."],

	["I may be disembarking, but The Mer-Line will carry others..."],

	["My ticket has expired..."],

	["You've disrupted my schedule..."]
	]
	var random_line = randi() % possible_lines.size()
	return possible_lines[random_line]
func set_defeat_pose():
	var pawn = get_pawn()
	pawn.state_machine.set_state("Defeated")

func roll_for_vault_open()->bool:
	var roll_bonus:float = float(SaveState.other_data.infDung_vault_counter - 10) / 100.00
	return randf() < bootleg_spawn_chance + roll_bonus

func roll_for_time_trial()->bool:
	if has_dungeon_properties():
		if not SaveState.other_data.InfiniteRailwayProperties["TrialChambers"]:
			return false
	var trial_roll = randf()
	return trial_roll < time_trial_chance

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
		print("Increased counter to: " + str(SaveState.other_data.infDung_lifetime_counter))
		if SaveState.other_data.infDung_vault_counter >= 10 and roll_for_vault_open():
			print("found magikrab's vault")
			SaveState.other_data.infdung_vault_battle_state = "open"
			SaveState.other_data.infdung_vault_chests_state = "open"
				
			emit_signal("open_vault")
			SaveState.other_data.infDung_vault_counter = 0													
		elif SaveState.other_data.infinite_dungeon_counter >= 5:
				print("boss signal sent")
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
		
		action = $Cutscene / Selector / Sequence / DefeatDialogue
		defeat_dialogue = get_random_defeat_lines()
		action.messages = defeat_dialogue
	if detector:
		detector.enabled = true
	if iconsave:		
		if pawn.has_node(NodePath("Interaction")):
			pawn.get_node(NodePath("Interaction")).icon_override = iconsave
