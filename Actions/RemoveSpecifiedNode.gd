extends Action
class_name RemoveNodeList

export(Array, NodePath) var nodepath

func _run():
	for path in nodepath: 
		var node = get_node(path)
		if node:
			node.get_parent().remove_child(node)
	return true
