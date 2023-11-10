extends Action
class_name ExchangeMenuLootTableCustom

export (String) var title:String = ""
export (Array, Resource) var exchanges:Array = []
export (bool) var autosort:bool = true
export (bool) var discountable:bool = true
export(Array, Resource) var exclude_from_stock
func _run():
	var subs = {}
	var pawn = get_pawn()
	if is_instance_valid(pawn) and pawn is NPC:
		subs.pawn = pawn.npc_name
	
	var t = Loc.trf(title, subs)
	
	var discount_percent:int = 0
	if discountable:
		discount_percent = SaveState.stats.get_stat("exchange_purchased").get_count("merchant_discounts") * 5
	var limit = 0
	var currentstock = 0
#	var shard = load("res://mods/Infinite_Dungeon/Items/railway_shard.tres")
#	SaveState.inventory.add_item(shard, 100)
	for item in exchanges:
		if item in exclude_from_stock:
			continue
		var shopitem = item.loot_table.guaranteed_items[0]
		limit = SaveState.inventory.get_stack_limit(shopitem)
		currentstock = SaveState.inventory.get_item_amount(shopitem)
		if limit != 0:
			var max_amount = limit - currentstock				
			if max_amount > 0:
				item.max_amount = limit - currentstock
			else:			
				item.max_amount = 1

	yield (MenuHelper.show_exchange(t, exchanges, autosort, discount_percent), "completed")
	return true

