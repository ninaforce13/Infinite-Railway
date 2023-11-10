extends BaseLootTable

export (Array, String) var sticker_tags:Array
export (int) var num_stickers:int = 6
export (int) var num_rarity_upgrades:int = 1
export(Array, String, FILE, "*.tscn") var attributes = []
func generate_rewards(rand:Random, _max_value:int, max_num:int = - 1)->Array:
	var rewards = []
	
	var count = num_stickers
	if max_num >= 0 and max_num < count:
		count = max_num
	
	var moves:Array
	if sticker_tags.size() == 0:
		moves = BattleMoves.sellable_stickers
	else :
		for tag in sticker_tags:
			moves += BattleMoves.get_sellable_stickers_for_tag(tag)
	
	assert (moves.size() > 0)
	if moves.size() == 0:
		return []
	
	for i in range(count):		
		var valid = false
		var move
		var new_attributes = []
		while not valid:	
			move = rand.choice(moves)		
			for attribute in attributes:
				var file = load(attribute)
				var instance = file.instance()
				if instance.has_method("generate"):
					if instance.is_applicable_to(move):
						instance.generate(move, Random.new())						
						new_attributes.append((instance))						
						valid = true
		var item = ItemFactory.generate_item(move, rand)
		assert (item != null)

		item.rarity = BaseItem.Rarity.RARITY_RARE
		randomize_attributes(item, new_attributes)
		rewards.push_back({item = item, amount = 1})
	
	return rewards

func randomize_attributes(item:StickerItem, seeded_attribute = [], rand:Random = null)->void :
	assert (item.battle_move != null)
	if item.battle_move.attribute_profile == null:
		item.set_attributes([])
		return 
	
	var profile = item.battle_move.attribute_profile
	
	if rand == null:
		rand = SaveState.item_rand
	
	var new_attributes = []	

	for attr_rarity in range(item.rarity + 1):		
		var valid_attributes = profile.get_applicable_attributes(attr_rarity, item.battle_move)
		var upperlimit = ItemFactory._rand_attr_count(rand, item.rarity, attr_rarity)
		for _i in range(upperlimit):			
			var attr = rand.weighted_choice(valid_attributes)
			if attr == null:
				break
			var attr_inst = attr.instance()
			attr_inst.generate(item.battle_move, rand)
			new_attributes.push_back(attr_inst)
			valid_attributes.erase(attr)
	var attribute_to_remove
	var index = 0
	for attribute in new_attributes:
		if attribute.rarity == seeded_attribute[0].rarity:
			attribute_to_remove = attribute
			break	
		index+=1
	new_attributes.insert(index, seeded_attribute[0])
	new_attributes.erase(attribute_to_remove)
	
	item.set_attributes(new_attributes)
