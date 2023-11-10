extends Node


func _enter_tree():	
	if not SaveState.other_data.has("infdung_vault_chests_state"):
		SaveState.other_data.infdung_vault_chests_state = "open"
	if SaveState.other_data.infdung_vault_chests_state == "open":
		for chest in get_children():
			chest.set_opened_flag(false)
			chest.daily_flag_name = str(Random.new())	
			if chest.interaction:
				chest.interaction.disabled = false
				chest.opened = false
				chest.animation_player.play_backwards("open")
				chest.animation_player.seek(0, true)
		SaveState.other_data.infdung_vault_chests_state = "closed"								
