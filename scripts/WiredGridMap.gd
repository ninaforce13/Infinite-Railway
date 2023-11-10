extends WiredMovement

func set_enable_animation(value:bool):
	.set_enable_animation(value)
	
	var self0 = self
	if self0 is PhysicsBody:
		var pb = self0 as PhysicsBody
		pb.set_collision_layer_bit(Collisions.BIT_PHYSICAL, value)
		pb.set_collision_mask_bit(Collisions.BIT_PHYSICAL, value)


func get_reveal_transform():
	if target_positions.size() != 1:
		return Transform.IDENTITY
	assert (has_node(target_positions[0]))
	var reveal = get_node(target_positions[0])
	return reveal.global_transform * global_transform.inverse()

