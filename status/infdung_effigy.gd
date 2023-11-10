extends StatusEffect

var victim_character = null
var creator = null

func notify(node, id:String, args):
	if victim_character == null or creator == null:
		return 
	var target = victim_character.get_parent()
	if target.status.dead or creator.status.dead:
		clear_effigy(node)
		return 
	if id == "damage_starting" and args.fighter == node.fighter:
		if not args.damage.is_splash:
			node.battle.queue_camera_set_state("effect", [node.fighter.slot, target.slot])
			var damage = args.damage.duplicate()
			damage.toast_message = name
			target.get_controller().take_damage(damage)
		return true
	elif id == "status_effect_add_starting" and args.fighter == node.fighter:
		return
#		node.battle.queue_camera_set_state("effect", [node.fighter.slot, target.slot])
#		target.status.add_effect(args.status_effect.effect, args.status_effect.amount)
#		return true

func clear_effigy(node):
	node.fighter.status.clear_effects()
