extends Action
class_name ReportStats

const SpookyDialog = preload("res://menus/spooky_dialog/SpookyDialog.gd")

enum PronounMode{DONT_USE, USE_PAWN, USE_PLAYER, USE_PARTNER}

export (Texture) var portrait:Texture = null
export (int, "Left", "Center", "Right") var portrait_position:int = 0
export (AudioStream) var audio:AudioStream = null
export (String, "", "greeting", "farewell", "thanks", "sigh_2", "surprise_2", "thinking", "defeat") var use_pawn_sfx_audio:String
export (Resource) var type_sounds:Resource = null
export (String) var title:String = ""
export (Array, String) var messages:Array = []
export (bool) var wait_for_confirm:bool = true
export (bool) var close_after:bool = true
export (Array, String) var substitute_blackboard_keys:Array = []
export (PronounMode) var use_pronouns = PronounMode.DONT_USE
export (int, "Regular", "Full-Window Spooky", "Boxed Spooky", "Boxed Spooky Regular Size") var style:int = 0
export (String) var text_variant_seed:String = ""
export (bool) var report_rewards_only = false
export(Resource) var railway_shards
static func create_subs(action:Action)->Dictionary:
	var subs = {
		"player":Loc.tr(SaveState.party.player.name), 
		"partner":Loc.tr(SaveState.party.partner.name)
	}
	
	var level_map = WorldSystem.get_level_map()
	if level_map and level_map.region_settings:
		subs.region_name = Loc.tr(level_map.region_settings.region_name)
		subs.region_name_phrase = Loc.tr(level_map.region_settings.region_name + "_PHRASE")
	
	if action:
		var pawn = action.get_pawn()
		if is_instance_valid(pawn) and pawn is NPC:
			subs.pawn = pawn.npc_name
		elif is_instance_valid(pawn) and pawn is FighterController:
			subs.pawn = pawn.fighter.get_general_name()
	
	for tape in SaveState.party.player.tapes:
		if tape.form is MonsterForm:
			subs.first_tape_name = tape.get_name()
			subs.first_tape_description = tape.form.description
			break
	
	if action:
		var bb_keys = action.get("substitute_blackboard_keys")
		if bb_keys is Array:
			for key in bb_keys:
				var value = action.blackboard.get(key)
				if value is BaseItem or value is Character or value is BaseForm or value is BattleMove:
					value = value.name
				subs[key] = value
		
	return subs

func get_pronouns():
	if use_pronouns == PronounMode.USE_PLAYER:
		return SaveState.party.player.pronouns
	elif use_pronouns == PronounMode.USE_PARTNER:
		return SaveState.party.partner.pronouns
	elif use_pronouns == PronounMode.USE_PAWN:
		var pawn = get_pawn()
		if pawn and pawn.get("pronouns") != null:
			return pawn.pronouns
	return Loc.Pronouns.THEY

func _run():
	var audio = self.audio
	if audio == null and use_pawn_sfx_audio != "":
		var pawn = get_pawn()
		if pawn and pawn.get("sfx"):
			var sfx = pawn.sfx.get(use_pawn_sfx_audio)
			if sfx.size() > 0:
				audio = sfx[randi() % sfx.size()]
	
	var dlg = GlobalMessageDialog.message_dialog
	dlg.portrait = portrait
	dlg.portrait_position = portrait_position
	dlg.audio = audio
	dlg.type_sounds = type_sounds
	dlg.font = null
	
	if style == 2:
		dlg.font = preload("res://ui/fonts/archangel/archangel_60.tres")
	elif style == 3:
		dlg.font = preload("res://ui/fonts/archangel/archangel_40.tres")
	
	GlobalMessageDialog.layer = 62 if style != 0 else 64
	
	var subs = create_subs(self)
	
	var variant:int = 0
	if text_variant_seed != "" or blackboard.has("text_variant_seed"):
		var bb_seed = blackboard.get("text_variant_seed", 0)
		if not (bb_seed is int):
			bb_seed = str(bb_seed).hash()
		variant ^= bb_seed
		if text_variant_seed != "":
			variant ^= text_variant_seed.hash()
	else :
		variant = randi()
	
	if SaveState.has_flag("mask_name_" + title):
		dlg.title = "UNKNOWN_NAME"
	else :
		dlg.title = Loc.trvf(title, variant, subs)
	var bonus_reward = 0
	for i in range(messages.size()):
		var message = messages[i]
		if not SaveState.other_data.has("infDung_lifetime_counter"):
			SaveState.other_data.infDung_lifetime_counter = 0
			SaveState.other_data.infDung_boss_counter = 0
		if SaveState.inventory.has_item(railway_shards):
			bonus_reward = floor(SaveState.inventory.get_item_amount(railway_shards) / 2)
		if report_rewards_only:
			bonus_reward += floor(SaveState.other_data.infDung_boss_counter * 2)
			message = "If I send you back to New Wirral now, I'll convert your Railway Shards into Fused Material and even toss in a little extra for your troubles. You'd be taking home " + str(bonus_reward) + " Fused Material!"
		if not report_rewards_only:
			if i == 1:
				message = "So far, you've won " + str(SaveState.other_data.infDung_lifetime_counter) + " battles"
			if i == 2: 
				message = "And survived " + str(SaveState.other_data.infDung_boss_counter) + " Archangel encounter(s)"
			if i == 3:
				bonus_reward += floor(SaveState.other_data.infDung_boss_counter * 2)
				message = "If I send you back to New Wirral now, I'll convert your Railway Shards into Fused Material and even toss in a little extra for your troubles. You'd be taking home " + str(bonus_reward) + " Fused Material!"
		var text
		if use_pronouns != PronounMode.DONT_USE:
			text = Loc.trgvf(message, get_pronouns(), variant, subs)
		else :
			text = Loc.trvf(message, variant, subs)
		
		if style == 2:
			text = SpookyDialog.FORMAT.format([text])
		
		
		
		
		text = Loc.substitute_mfn(text, SaveState.party.player.pronouns)
		
		if style == 1:
			yield (MenuHelper.show_spooky_dialog(text, audio if i == 0 else null, type_sounds), "completed")
		else :
			yield (GlobalMessageDialog.show_message(text, false, wait_for_confirm or i < messages.size() - 1), "completed")
		
		dlg.audio = null
	
	return true

func _exit_action(_result):
	if close_after:
		return GlobalMessageDialog.hide()
