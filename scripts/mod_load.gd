extends ContentInfo

func _init():
	var res = preload("QuestLocationLayer_mod.gd")
	res.take_over_path("res://world/core/QuestLocationLayer.gd")
