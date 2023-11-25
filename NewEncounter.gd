extends EncounterConfig

export (bool) var add_duplicate_player:bool = false
 
func get_config():
	var map = WorldSystem.get_level_map()
	assert (map != null)
	
	var seed_value = self.seed_value
	if seed_value == 0:
		if unique_id != "":
			seed_value = unique_id.hash()
		else :
			seed_value = randi()
	if combine_with_player_seed:
		seed_value ^= SaveState.random_seed
	var rand = Random.new(seed_value)
	
	var random_seed = rand.get_child_seed("battle")
	if not combine_with_player_seed:
		random_seed ^= SaveState.random_seed
	var loot_rand_seed = rand.get_child_seed("loot") ^ SaveState.random_seed
	
	var fighters = []
	var used_chars = []
	if (add_characters & AddCharacters.PLAYER) != 0:
		_add_character(fighters, SaveState.party.player)
		used_chars.push_back(SaveState.party.player)
	if (add_characters & AddCharacters.PARTNER) != 0:
		_add_character(fighters, SaveState.party.partner)
		used_chars.push_back(SaveState.party.partner)
	if add_duplicate_player:
		var shadow_player:Character = SaveState.party.player.duplicate()
		shadow_player.name = "Shadow " + SaveState.party.player.name
		_add_character(fighters, shadow_player)
		used_chars.push_back(SaveState.party.player)
	if (add_characters & AddCharacters.UNLOCKED_PARTNERS) != 0:
		for id in SaveState.party.unlocked_partners:
			var c = SaveState.party.get_partner_by_id(id)
			if not used_chars.has(c):
				_add_character(fighters, c)
				used_chars.push_back(c)
	for add_c_id in PARTNER_IDS.keys():
		if (add_characters & add_c_id) != 0:
			var c = SaveState.party.get_partner_by_id(PARTNER_IDS[add_c_id])
			if not used_chars.has(c):
				_add_character(fighters, c)
				used_chars.push_back(c)
	if (add_characters & AddCharacters.REL_L1_PARTNERS) != 0:
		for id in SaveState.party.unlocked_partners:
			var c = SaveState.party.get_partner_by_id(id)
			if not used_chars.has(c) and c.relationship_level >= 1:
				_add_character(fighters, c)
				used_chars.push_back(c)
	
	var defeat_count = get_defeat_count()
	
	for c in get_character_nodes():
		fighters.push_back(c.generate_fighter(rand, defeat_count))
	
	_add_extra_fighters(fighters)
	
	for f in fighters:
		for c in f.get_characters():
			if hidden_names.has(c.character_name):
				c.hide_name = true
	
	var bg = background_override
	if not bg and map.region_settings:
		bg = map.region_settings.battle_background
	if not bg:
		bg = "res://battle/backgrounds/BattlePlains.tscn"
	
	var music = _get_music()
	
	return {
		"random_seed":random_seed, 
		"unique_id":unique_id, 
		"fighters":fighters, 
		"background":bg, 
		"advantages":[], 
		"music":music.music, 
		"music_vox":music.music_vox, 
		"spawn_profile":WorldSystem.current_spawn_profile, 
		"extra_exp_yield":extra_exp_yield, 
		"loot_table_override":_get_loot_table_override(), 
		"cutscenes":cutscenes, 
		"enable_ai_fusion":enable_ai_fusion, 
		"can_flee":can_flee, 
		"suppress_exp":suppress_exp, 
		"title_banner":_get_title_banner(), 
		"stamina_increase_on_win":stamina_increase_on_win, 
		"loot_rand_seed":loot_rand_seed
	}
