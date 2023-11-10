extends Node

export(NodePath) var encounterconfig
func _enter_tree():
	if not SaveState.other_data.has("infdung_vault_battle_state"):
		SaveState.other_data.infdung_vault_battle_state = "open"	
	if SaveState.other_data.infdung_vault_battle_state == "open":
		if encounterconfig:
			var node = get_node(encounterconfig)
			if node.is_defeated():
				node.set_defeated(false)
		SaveState.other_data.infdung_vault_battle_state == "closed"
				
