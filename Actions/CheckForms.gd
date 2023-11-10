extends Action
class_name CheckForms
signal has_form
export (Resource) var form

func _run():	
	emit_signal("has_form")
	
	return true
