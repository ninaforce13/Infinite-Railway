extends Action

const HIDDEN_POS = Vector3(60, 0, 0)

export (int) var team:int = 1
export (Array, Resource) var monster_forms:Array
export (Resource) var base_character:Resource
export (Array, String) var enable_flags:Array

func _ready():
	assert (SceneManager.current_scene is Battle)
	if SceneManager.current_scene is Battle:
		var battle = SceneManager.current_scene
		if not battle.sprite_loader:
			yield (battle, "ready")
		for i in range(monster_forms.size()):
			if monster_forms[i] == null:
				continue
#			if i >= enable_flags.size() or SaveState.has_flag(enable_flags[i]):
			battle.sprite_loader.register_extra_forms(monster_forms[i])

func _run():
	var battle = get_pawn()
	
	var level = battle.get_teams()[team][0].status.level
	
	for i in range(monster_forms.size()):
		if monster_forms[i] == null:
			continue
#		if i >= enable_flags.size() or SaveState.has_flag(enable_flags[i]):
		spawn_one(monster_forms[i], level)
	
	return true

func spawn_one(form:Resource, level:int):
	var battle = get_pawn()
	
	var fighter = FighterNode.new()
	fighter.team = team
	
	var tape = MonsterTape.new()
	tape.form = form
	tape.assign_initial_stickers(false, battle.rand)
	
	var char_node = CharacterNode.new()
	char_node.character = base_character.duplicate()
	char_node.character.level = level
	char_node.character.pronouns = Loc.Pronouns.THEY
	char_node.active_tape = tape
	fighter.add_child(char_node)
	
	var ai = load("res://battle/ai/BalancedAI.tscn")
	fighter.add_child(ai.instance())
	battle.add_child(fighter)
	
	if not battle.try_assign_slot(fighter):
		battle.remove_child(fighter)
		fighter.queue_free()
		return 
	
	fighter.generate_enter_slot_animation().call_func()
	
	var pos = fighter.slot.global_transform.origin
	pos.x = HIDDEN_POS.x
	fighter.slot.move_to(pos, true)
	
