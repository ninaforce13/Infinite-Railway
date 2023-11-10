extends Node
signal open_gate
func _enter_tree():
	print("Send Gate Signal")
	emit_signal("open_gate")
