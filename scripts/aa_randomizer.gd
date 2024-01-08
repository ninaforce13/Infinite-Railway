extends Node
enum DemoBoss {LENNA = 0,
				MOURNINGSTAR = 1,
				LAMENTO_MORI = 2,
				POPPETOX = 3,
				CUBE = 4,
				HELIA = 5,
				ALICE = 6,
				MAMMON = 7,
				MORGANTE = 8,
				MONARCH = 9,
				ROBIN = 10,
				TOWER = 11,
				ALEPH = 12,
				GWEN = 13,
				ALEPH_NULL = 14}

enum BattleMode {SINGLES = 0,
				RANGERS = 1
				FUSION = 2,
				ORBFUSION = 3,
				DOUBLE_BATTLE = 4,
				TRIPLE_BATTLE = 5}
export (bool) var demo_mode:bool = false
export (DemoBoss) var demo_boss
export (BattleMode) var demo_battle_mode
export(Array, String, FILE, "*.tscn") var aa_list
export(String, FILE, "*.tscn") var add_on_ranger
export(String, FILE, "*.tscn") var add_on_fusion
export(String, FILE, "*.tscn") var add_on_orbfusion
export(NodePath) var AAtarget
export(NodePath) var mirror
export(NodePath) var audio
export (AudioStream) var music_override:AudioStream
export (AudioStream) var music_vox_override:AudioStream
export (Array, Resource) var loot_table_override

var RailwaySettings = preload("res://mods/Infinite_Dungeon/resources/RailwaySettings.tres")
var archangel
var nullBattleFlag:bool = false
func _enter_tree():
	var file
	var selected_angel
	if archangel:
		if SaveState.other_data.has("infDung_boss_counter"):
			SaveState.other_data.infDung_boss_counter += 1
		else:
			SaveState.other_data.infDung_boss_counter = 1
		SaveState.other_data.infinite_dungeon_counter = 0
		archangel.queue_free()
		var stream = get_node(audio)
		stream.play()
		var target_node = get_node(mirror)
		yield (Co.safe_yield(self, Co.wait(1.0)), "completed")
		target_node.visible = true
	else:
		if not SaveState.other_data.has("archangel_lineup"):
			SaveState.other_data.archangel_lineup = [0,1,7,8,9,10,11,12,2,3,4,5,6]
			if DLC.has_dlc("pier"):
				SaveState.other_data.archangel_lineup.push_back(DemoBoss.GWEN)
		if SaveState.other_data.archangel_lineup.size() <= 0:
			SaveState.other_data.archangel_lineup = [0,1,7,8,9,10,11,12,2,3,4,5,6]
			if DLC.has_dlc("pier"):
				SaveState.other_data.archangel_lineup.push_back(DemoBoss.GWEN)
			nullBattleFlag = true
		var target_node = get_node(mirror)
		target_node.visible = false
		if demo_mode:
			selected_angel = demo_boss
			file = load(aa_list[demo_boss])
			nullBattleFlag = demo_boss == DemoBoss.ALEPH_NULL

		if nullBattleFlag and not demo_mode:
			file = load(aa_list[DemoBoss.ALEPH_NULL])

		if not nullBattleFlag and not demo_mode:
			selected_angel = randi() % SaveState.other_data.archangel_lineup.size()
			file = load(aa_list[SaveState.other_data.archangel_lineup[selected_angel]])

		archangel = file.instance()
		validate_savestate()
		add_child(archangel)
		setup_loot_table()
		if not nullBattleFlag:
			setup_triples(selected_angel, triples_active())
			setup_doubles(selected_angel, doubles_active())
			setup_add_ons(add_on_orbfusion, orb_fusion_active(),false, (demo_mode and demo_battle_mode == BattleMode.ORBFUSION))
			setup_add_ons(add_on_fusion, fusion_active(),false, (demo_mode and demo_battle_mode == BattleMode.FUSION))
			setup_add_ons(add_on_ranger, rangers_active(),false, (demo_mode and demo_battle_mode == BattleMode.RANGERS))
			setup_add_ons(add_on_ranger, rangers_active(),false, (demo_mode and demo_battle_mode == BattleMode.RANGERS))
			setup_add_ons(add_on_ranger, rangers_active(),false, (demo_mode and demo_battle_mode == BattleMode.RANGERS))
			setup_add_ons(add_on_ranger, rangers_active(),false, (demo_mode and demo_battle_mode == BattleMode.RANGERS))


			SaveState.other_data.archangel_lineup.erase(SaveState.other_data.archangel_lineup[selected_angel])
		print(SaveState.other_data.archangel_lineup)
		var targetnode = get_node(AAtarget)
		archangel.transform = targetnode.transform
		check_music_override()
		nullBattleFlag = false

func check_music_override():
	if not SaveState.other_data.has("infdung_battle_music_altload"):
		SaveState.other_data.infdung_battle_music_altload = false
	if not SaveState.other_data.has("infdung_battle_music"):
		SaveState.other_data.infdung_battle_music = ""

	if SaveState.other_data.infdung_battle_music != "":
		var song
		if not SaveState.other_data.infdung_battle_music_altload:
			song = load(SaveState.other_data.infdung_battle_music)
		if SaveState.other_data.infdung_battle_music_altload:
			song = load_external_ogg(SaveState.other_data.infdung_battle_music)
			get_node("Archangel/RematchConfig").music_override = song
			get_node("Archangel/RematchConfig").music_vox_override = song

func load_external_ogg(path):
	var ogg_file = File.new()
	var err = ogg_file.open(path, File.READ)
	if err != OK:
		return null
	var bytes = ogg_file.get_buffer(ogg_file.get_len())
	var stream = AudioStreamMP3.new()
	stream.data = bytes
	stream.loop = true
	ogg_file.close()
	return stream

func setup_loot_table():
	if triples_active():
		get_node("Archangel/RematchConfig").loot_table_override = loot_table_override[4]
		return
	if doubles_active():
		get_node("Archangel/RematchConfig").loot_table_override = loot_table_override[3]
		return
	if orb_fusion_active():
		get_node("Archangel/RematchConfig").loot_table_override = loot_table_override[2]
		return
	if fusion_active():
		get_node("Archangel/RematchConfig").loot_table_override = loot_table_override[1]
		return
	if rangers_active():
		get_node("Archangel/RematchConfig").loot_table_override = loot_table_override[0]
		return

func validate_savestate():
	if not SaveState.other_data.has("infDung_lifetime_counter"):
		SaveState.other_data.infDung_lifetime_counter = 0
func setup_add_ons(add_on_path, active:bool, music_change=false, demo_override:bool = false):
	if not active and not demo_override:
		return
	var file = load(add_on_path)
	var instance = file.instance()

	get_node("Archangel/RematchConfig").add_child(instance)
	if music_change:
		get_node("Archangel/RematchConfig").music_override = music_override
		get_node("Archangel/RematchConfig").music_vox_override = music_vox_override


func setup_doubles(selected_angel:int, active:bool):
	if not active and not (demo_mode and demo_battle_mode == BattleMode.DOUBLE_BATTLE):
		return
	var index = randi() % aa_list.size() - 1 #Remove Aleph Null.
	#Prevent copies
	if index == SaveState.other_data.archangel_lineup[selected_angel]:
		if index + 1 > aa_list.size() - 1:
			index -= 1
		else:
			index += 1
	var file = load(aa_list[index])
	var second_angel = file.instance()
	var charconfig_node = second_angel.get_node("RematchConfig/CharacterConfig")

	charconfig_node.get_parent().remove_child(charconfig_node)
	get_node("Archangel/RematchConfig").add_child(charconfig_node)
	get_node("Archangel/RematchConfig").music_override = music_override
	get_node("Archangel/RematchConfig").music_vox_override = music_vox_override

func setup_triples(selected_angel:int, active:bool):
	if not active and not (demo_mode and demo_battle_mode == BattleMode.TRIPLE_BATTLE):
		return
	var primary_angel_index = SaveState.other_data.archangel_lineup[selected_angel]
	var temp_angel_list = aa_list.duplicate()
	temp_angel_list.remove(primary_angel_index)
	temp_angel_list.remove(12)
	var index = randi() % temp_angel_list.size()
# Angel two
	var file = load(temp_angel_list[index])
	var angel = file.instance()
	var charconfig_node = angel.get_node("RematchConfig/CharacterConfig")
	charconfig_node.get_parent().remove_child(charconfig_node)
	get_node("Archangel/RematchConfig").add_child(charconfig_node)
	temp_angel_list.remove(index)
# Angel three
	index = randi() % temp_angel_list.size()
	file = load(temp_angel_list[index])
	angel = file.instance()
	charconfig_node = angel.get_node("RematchConfig/CharacterConfig")
	charconfig_node.get_parent().remove_child(charconfig_node)
	get_node("Archangel/RematchConfig").add_child(charconfig_node)

	get_node("Archangel/RematchConfig").music_override = music_override
	get_node("Archangel/RematchConfig").music_vox_override = music_vox_override

func rangers_active()->bool:
	return RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE2) or RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE3)

func fusion_active()->bool:
	return RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE4) or RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE5)

func orb_fusion_active()->bool:
	return RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE6) or RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE7)

func doubles_active()->bool:
	return RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE8)

func triples_active()->bool:
	return RailwaySettings.encounter_threshold_met(RailwaySettings.encounter.STAGE9)
