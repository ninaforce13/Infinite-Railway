extends "res://menus/BaseMenu.gd"

const STAT_NAMES = ["max_hp", "melee_attack", "melee_defense", "ranged_attack", "ranged_defense", "speed"]

export (Resource) var character:Resource setget set_character

var max_total:int setget set_max_total
var remaining_points:int = 0 setget set_remaining_points

onready var character_name_label = find_node("CharacterNameLabel")
onready var explanation_label = find_node("ExplanationLabel")
onready var remaining_points_label = find_node("RemainingPointsLabel")
onready var stat_hex = find_node("StatHex")
onready var slider_container = find_node("Sliders")
onready var sliders = {
	max_hp = find_node("MaxHpSlider"), 
	melee_attack = find_node("MeleeAttackSlider"), 
	melee_defense = find_node("MeleeDefenseSlider"), 
	ranged_attack = find_node("RangedAttackSlider"), 
	ranged_defense = find_node("RangedDefenseSlider"), 
	speed = find_node("SpeedSlider")
}

func _ready():
	if character == null:
		var partner = SaveState.party.current_partner_id
		character = SaveState.party.get_partner_by_id(partner)
	
	var total = SaveState.stats.get_stat("exchange_purchased").get_count("gym_points")
	total += 40
	for stat in STAT_NAMES:
		total += get_default_stat_value(stat)
	set_max_total(total)
	
	set_character(character)

func get_default_stat_value(stat:String)->int:
	var player_template = preload("res://data/characters/player.tres")
	return player_template.get("base_" + stat)

func get_min_stat_value(stat:String)->int:
	var max_min:int = get_default_stat_value(stat)
	var min_min:int = max_min / 2
	
	var quest_res = preload("res://data/quests/story/CaptainQuest1.tscn")
	if SaveState.quests.is_completed(quest_res):
		return min_min
	var quest = SaveState.quests.get_quest(quest_res)
	if not quest:
		return max_min
	return int(max(min_min, max_min - quest.get_num_defeated() * max((max_min - min_min) / quest.captain_ids.size(), 1)))

func set_character(value:Resource):
	character = value
	if not character:
		return 
	if character_name_label:
		character_name_label.text = Loc.trf("STAT_ADJUST_MENU_TITLE", {player = character.name})
		explanation_label.text = Loc.trgf("STAT_ADJUST_MENU_EXPLANATION", character.pronouns, {
			player = character.name
		})
		
		stat_hex.set_stats_for(character, null)
		for stat in STAT_NAMES:
			var stat_value = character.get_stat(stat, null)
			sliders[stat].set_value(stat_value)
			sliders[stat].min_value = get_min_stat_value(stat)

func set_max_total(value:int):
	max_total = value
	remaining_points = max_total
	if character:
		for stat in STAT_NAMES:
			remaining_points -= character.get_stat(stat, null)
	set_remaining_points(remaining_points)

func set_remaining_points(value:int):
	remaining_points = value
	if remaining_points_label:
		remaining_points_label.text = Loc.trf("STAT_ADJUST_MENU_REMAINING_POINTS", [remaining_points])

func grab_focus():
	slider_container.grab_focus()

func _on_Slider_value_change_requested(stat, delta, new_value):
	if not character:
		return 
	
	var old_value = new_value - delta
	if remaining_points < delta and delta > 0:
		assert (new_value > old_value)
		delta = remaining_points
		new_value = old_value + delta
	
	var min_stat_value = get_min_stat_value(stat)
	assert (new_value >= min_stat_value)
	if new_value < min_stat_value:
		new_value = min_stat_value
		delta = new_value - old_value
	
	character.set("boost_" + stat, new_value - character.get("base_" + stat))
	stat_hex.set_stats_for(character, null)
	sliders[stat].set_value(new_value)
	set_max_total(max_total)

func _unhandled_input(event):
	if not MenuHelper.is_in_top_menu(self):
		return 
	if event.is_action_pressed("ui_cancel"):
		cancel()
		get_tree().set_input_as_handled()

func cancel():
	if remaining_points > 0:
		if not yield (MenuHelper.confirm("STAT_ADJUST_MENU_WARNING_POINTS_REMAIN"), "completed"):
			slider_container.grab_focus()
			return 
	.cancel()
