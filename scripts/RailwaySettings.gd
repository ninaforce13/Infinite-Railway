extends Resource
enum encounter {STAGE1, STAGE2, STAGE3, STAGE4, STAGE5, STAGE6, STAGE7, STAGE8, STAGE9}
export(float) var rogue_fusion_rate = 0.5
export(float) var magikrab_vault_rate = 0.05
export(float) var ghostly_rate = 0.5
export(float) var time_trial_chance = 0.2
export (float) var mirror_match_rate = 0.01
export (float) var custom_ranger_rate = 0.05
export (int, 0, 100000) var stage1
export (int, 0, 100000) var stage2
export (int, 0, 100000) var stage3
export (int, 0 ,100000) var stage4
export (int, 0 ,100000) var stage5
export (int, 0 ,100000) var stage6
export (int, 0 ,100000) var stage7
export (int, 0 ,100000) var stage8
export (int, 0 ,100000) var stage9

func get_vault_value()->float:
	return magikrab_vault_rate + float(SaveState.other_data.infDung_vault_counter - 10) / 100.00

func get_current_stage()->int:
	if encounter_threshold_met(encounter.STAGE7):
		return encounter.STAGE7
	if encounter_threshold_met(encounter.STAGE6):
		return encounter.STAGE6
	if encounter_threshold_met(encounter.STAGE5):
		return encounter.STAGE5
	if encounter_threshold_met(encounter.STAGE4):
		return encounter.STAGE4
	if encounter_threshold_met(encounter.STAGE3):
		return encounter.STAGE3
	if encounter_threshold_met(encounter.STAGE2):
		return encounter.STAGE2
	if encounter_threshold_met(encounter.STAGE1):
		return encounter.STAGE1

	return encounter.STAGE7

func encounter_threshold_met(chosen_encounter)->bool:
	if not SaveState.other_data.has("infDung_lifetime_counter") and chosen_encounter != encounter.STAGE1:
		return false
	if chosen_encounter == encounter.STAGE1:
		if not SaveState.other_data.has("infDung_lifetime_counter"):
			return true
		return SaveState.other_data.infDung_lifetime_counter >= stage1
	if chosen_encounter == encounter.STAGE2:
		return SaveState.other_data.infDung_lifetime_counter >= stage2
	if chosen_encounter == encounter.STAGE3:
		return SaveState.other_data.infDung_lifetime_counter >= stage3
	if chosen_encounter == encounter.STAGE4:
		return SaveState.other_data.infDung_lifetime_counter >= stage4
	if chosen_encounter == encounter.STAGE5:
		return SaveState.other_data.infDung_lifetime_counter >= stage5
	if chosen_encounter == encounter.STAGE6:
		return SaveState.other_data.infDung_lifetime_counter >= stage6
	if chosen_encounter == encounter.STAGE7:
		return SaveState.other_data.infDung_lifetime_counter >= stage7
	if chosen_encounter == encounter.STAGE8:
		return SaveState.other_data.infDung_lifetime_counter >= stage8
	if chosen_encounter == encounter.STAGE9:
		return SaveState.other_data.infDung_lifetime_counter >= stage9				
	return false
