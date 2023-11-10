tool 
extends Spatial

export (int) var rows:int = 8 setget set_rows
export (int) var columns:int = 2 setget set_columns
export (float) var shake_duration:float = 0.5
export (Vector2) var block_spacing:Vector2 = Vector2(2, 2) setget set_block_spacing
export (Vector3) var block_offset:Vector3 = Vector3(1, - 1, 1) setget set_block_offset

func _ready():
	spawn_blocks()

func set_rows(value:int):
	rows = value
	spawn_blocks()

func set_columns(value:int):
	columns = value
	spawn_blocks()

func set_block_spacing(value:Vector2):
	block_spacing = value
	spawn_blocks()

func set_block_offset(value:Vector3):
	block_offset = value
	spawn_blocks()

func spawn_blocks():
	for child in get_children():
		if child.owner == null:
			remove_child(child)
			child.queue_free()
	
	for x in range(columns):
		for z in range(rows):
			var block = preload("res://world/objects/collapsing/CollapsingRock.tscn").instance()
			block.translation = Vector3(block_spacing.x * x, 0.0, block_spacing.y * z) - Vector3(block_spacing.x * columns / 2.0, 0.0, block_spacing.y * rows / 2.0) + block_offset
			block.rotation_degrees.y = (randi() % 4) * 90.0
			block.shake_duration = shake_duration
			add_child(block)
