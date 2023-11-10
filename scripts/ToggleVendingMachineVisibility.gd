extends Spatial
export(Resource) var acquisitionform
var VendingMachine = preload("res://mods/Infinite_Dungeon/Objects/EnhancedVendingMachine.tscn")
func _enter_tree():
	if SaveState.inventory:
		if SaveState.inventory.has_item(acquisitionform) and not get_parent().has_node("EnhancedVendingMachine"): 		
			var instance = VendingMachine.instance()
			get_parent().call_deferred("add_child", instance)  	
	


func _on_CheckForms_has_form():
	if SaveState.inventory:
		if SaveState.inventory.has_item(acquisitionform) and not get_parent().has_node("EnhancedVendingMachine"): 		
			var instance = VendingMachine.instance()
			get_parent().call_deferred("add_child", instance)  	
