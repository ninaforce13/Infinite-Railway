extends ExchangeConditional
class_name HasItemConditional

export (Resource) var item:Resource

func conditions_met()->bool:
	if SaveState.inventory.has_item(item):
		return false
	return true
