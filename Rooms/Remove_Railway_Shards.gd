extends Action
class_name Remove_Railway_Shards

export(Resource) var railway_shards
export(Resource) var fused_material
var bonus_reward = 0	
var shards_collected = 0
func _run():
	bonus_reward = 0
	print("removing shards")
	if SaveState.inventory.has_item(railway_shards):
		shards_collected = SaveState.inventory.get_item_amount(railway_shards)
		bonus_reward = floor(SaveState.inventory.get_item_amount(railway_shards) / 2)
	bonus_reward += floor(SaveState.other_data.infDung_boss_counter * 2)
	print("Shards collected: " + str(shards_collected))
	print("Bonus calculated: " + str(bonus_reward))

	SaveState.inventory.consume_item(railway_shards, shards_collected)
	SaveState.inventory.add_item(fused_material, bonus_reward)
	print("Rewarded with " + str(bonus_reward) + " fusion material")
	reset_stats()
	return true

func reset_stats():
	SaveState.other_data.infDung_lifetime_counter = 0
	SaveState.other_data.infDung_boss_counter = 0
	SaveState.other_data.infinite_dungeon_counter = 0
	SaveState.other_data.infDung_vault_counter = 0
	SaveState.other_data.infdung_vault_chests_state = "closed"
	SaveState.other_data.infdung_vault_battle_state = "closed"
	SaveState.other_data.archangel_lineup = [0,1,7,8,9,10,11,12,2,3,4,5,6]
	
