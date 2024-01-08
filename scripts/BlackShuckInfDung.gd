extends Spatial

const WorldHumanSprite3DScene = preload("res://nodes/layered_sprite/WorldHumanSprite3D.tscn")
const WorldUniqueSprite3DScene = preload("res://nodes/layered_sprite/WorldUniqueSprite3D.tscn")

export (float) var chase_chance:float = 0.01
onready var monster = $Monster
onready var monster2 = $Monster2
onready var chase_behavior = $Monster / IdleBehavior
onready var interaction_behavior = $Monster / InteractionBehavior
onready var cutscene = $Monster / Cutscene
onready var char1 = $Monster / EncounterConfig / CharacterConfig
onready var char2 = $Monster / EncounterConfig / CharacterConfig2

const meredith = preload("res://data/characters/meredith.tres")
const felix = preload("res://data/characters/felix.tres")
const kayleigh = preload("res://data/characters/kayleigh.tres")
const dog = preload("res://data/characters/dog.tres")
const eugene = preload("res://data/characters/eugene.tres")
const viola = preload("res://data/characters/viola.tres")

const felix_sfx = preload("res://data/character_sfx/felix_sfx.tres")
const meredith_sfx = preload("res://data/character_sfx/meredith_sfx.tres")
const kayleigh_sfx = preload("res://data/character_sfx/kayleigh_sfx.tres")
const dog_sfx = preload("res://data/character_sfx/dog_sfx.tres")
const eugene_sfx = preload("res://data/character_sfx/eugene_sfx.tres")
const viola_sfx = preload("res://data/character_sfx/viola_sfx.tres")

const dog_sprite = preload("res://world/recurring_npcs/Dog.tscn")

var detected:bool = false

func _ready():
	var sprite = WorldHumanSprite3DScene.instance()
	sprite.part_names = SaveState.party.player.human_part_names.duplicate()
	for color_key in sprite.colors.keys():
		sprite.colors[color_key] = SaveState.party.player.human_colors[color_key]
	monster.sprite.set_scene(sprite)

	char1.human_part_names = sprite.part_names.duplicate()
	char1.human_colors = sprite.colors.duplicate()
	char1.character_name = "Mirror " + SaveState.party.player.name
	char1.level_override = SaveState.party.player.level

	if SaveState.party.partner.partner_id == "dog":
		monster2.sprite_body = dog_sprite.instance().sprite_body
		monster2.sprite_colors = dog_sprite.instance().sprite_colors
		monster2.sprite_part_names = dog_sprite.instance().sprite_part_names
	else:
		var sprite2 = WorldHumanSprite3DScene.instance()
		sprite2.part_names = SaveState.party.partner.human_part_names.duplicate()
		for color_key in sprite2.colors.keys():
			sprite2.colors[color_key] = SaveState.party.partner.human_colors[color_key]
		monster2.sprite.set_scene(sprite2)
#
	char2.level_override = SaveState.party.partner.level
	char2.character_name = "Mirror " + tr(SaveState.party.partner.name)

	if SaveState.party.partner.partner_id == "kayleigh":
		char2.base_character = kayleigh
		char2.character_sfx = kayleigh_sfx
		char2.custom_battle_sprite = kayleigh.battle_sprite
	if SaveState.party.partner.partner_id == "meredith":
		char2.base_character = meredith
		char2.character_sfx = meredith_sfx
		char2.custom_battle_sprite = meredith.battle_sprite
	if SaveState.party.partner.partner_id == "felix":
		char2.base_character = felix
		char2.character_sfx = felix_sfx
		char2.custom_battle_sprite = felix.battle_sprite
	if SaveState.party.partner.partner_id == "dog":
		char2.base_character = dog
		char2.character_sfx = dog_sfx
		char2.custom_battle_sprite = dog.battle_sprite
	if SaveState.party.partner.partner_id == "eugene":
		char2.base_character = eugene
		char2.character_sfx = eugene_sfx
		char2.custom_battle_sprite = eugene.battle_sprite
	if SaveState.party.partner.partner_id == "viola":
		char2.base_character = viola
		char2.character_sfx = viola_sfx
		char2.custom_battle_sprite = viola.battle_sprite
	setup_tapes()

func setup_tapes():
	for child in char1.get_children():
		char1.remove_child(child)
		child.queue_free()
	for child in char2.get_children():
		char2.remove_child(child)
		child.queue_free()
	for tape in SaveState.party.player.tapes:
		char1.add_child(_create_tape_config(tape))
	for tape in SaveState.party.partner.tapes:
		char2.add_child(_create_tape_config(tape))

func _create_tape_config(tape:MonsterTape)->TapeConfig:
	var node = TapeConfig.new()
	node.form = tape.form
	node.moves_override = tape.stickers.duplicate()
	node.type_override = tape.type_override

	return node

func _on_PlayerDetector_detected(_detection):
	if detected:
		return
	detected = true

	yield (Co.next_frame(), "completed")

	if WorldSystem.is_player_control_enabled() and (randf() < chase_chance):

		setup_tapes()

		yield (cutscene.run(), "completed")

		chase_behavior.run()

	else :
		chase_behavior.get_parent().remove_child(chase_behavior)
		chase_behavior.queue_free()
		interaction_behavior.get_parent().remove_child(interaction_behavior)
		interaction_behavior.queue_free()
		monster.kill()
