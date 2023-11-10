extends Node

func _ready():
	change_sprite()
func _enter_tree():
	var config
	
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
			
		print("Encounter music override")
		if has_node("MerLine_Attendant/EncounterConfig"):
			config = get_node("MerLine_Attendant/EncounterConfig")
			config.music_override = song
			config.music_vox_override = song
		if has_node("MerLine_Attendant/TripleThreat"):
			config = get_node("MerLine_Attendant/TripleThreat")
			config.music_override = song
			config.music_vox_override = song
		if has_node("MerLine_Attendant/FusionStage"):
			config = get_node("MerLine_Attendant/FusionStage")
			config.music_override = song
			config.music_vox_override = song
		if has_node("MerLine_Attendant/OrbFusionStage"):
			config = get_node("MerLine_Attendant/OrbFusionStage")
			config.music_override = song
			config.music_vox_override = song		

	

	if not HumanLayersHelper.human_templates:
		HumanLayersHelper.setup()

func change_sprite():
	$MerLine_Attendant.randomize_sprite()

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
