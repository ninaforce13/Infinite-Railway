extends DetailedExchange

export (Resource) var loot_table:Resource
export (int) var loot_value:int = 1000

	
func purchased(count:int):
	.purchased(count)
	
	var rand = SaveState.item_rand
	var loot = []
	for _i in range(count):
		loot += loot_table.generate_rewards(rand, loot_value)
	MenuHelper.give_items(loot)
	var limit = SaveState.inventory.get_stack_limit(loot_table.guaranteed_items[0])
	var currentstock = SaveState.inventory.get_item_amount(loot_table.guaranteed_items[0])
	var difference = limit - currentstock
	if limit != 0:
		if difference > 0:
			max_amount = difference
		else:
			max_amount = 1
	return 
