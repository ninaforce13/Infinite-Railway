extends ExchangeConditional
class_name StockConditional

export (Resource) var item:Resource

func conditions_met()->bool:
	if SaveState.inventory.has_item(item):
		var stacklimit = SaveState.inventory.get_stack_limit(item)
		var itemamount = SaveState.inventory.get_item_amount(item)
		return itemamount < stacklimit
	return true 
