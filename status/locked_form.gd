extends StatusEffect

export (int) var percent_damage:int = 0
export (int) var absolute_damage:int = 0
export (bool) var hurts_allies:bool = false
export (bool) var heals_enemies:bool = false
export (Array, String) var damage_boost_tags:Array
export (int, "Melee", "Ranged") var damage_physicality:int = 1
export (Resource) var damage_type:Resource
export (Array, Resource) var hit_vfx:Array
export (Array, Resource) var heal_enemy_vfx:Array

func notify(node, id:String, args):
	var formbutton = SceneManager.current_scene.cassette_player.find_node("FormsButton")
	if id == "request_orders":
		if args.fighter.status.has_tag("locked_out"):
			formbutton.set_disabled(true)
			formbutton.set_focusable(false)
		else:
			formbutton.set_disabled(false)
			formbutton.set_focusable(true)
	

func removed(node):
	var formbutton = SceneManager.current_scene.cassette_player.find_node("FormsButton")
	formbutton.set_disabled(false)
	formbutton.set_focusable(true)	
	.removed(node)
	
func exit_tree(node):
	var formbutton = SceneManager.current_scene.cassette_player.find_node("FormsButton")
	formbutton.set_disabled(false)
	formbutton.set_focusable(true)	
	.exit_tree(node)
	
