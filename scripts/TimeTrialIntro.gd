extends Node


func _ready():
	yield(MenuHelper.show_spooky_dialog("Test"),"completed")
