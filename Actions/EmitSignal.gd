extends Action
class_name EmitSignalAction

signal triggeraction
func _run():
	emit_signal("triggeraction")
	return true
