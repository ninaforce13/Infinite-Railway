extends Action

export (NodePath) var UIElement

func _run():
	get_node(UIElement).visible = true
	return true
