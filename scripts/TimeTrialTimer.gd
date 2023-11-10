extends Node
signal TrialForceEnd

export(String) var trialname
export(NodePath) var timer_path
export(float) var autostop_seconds = 59.99
export(bool) var autostop_enabled = false
onready var game_start_time = OS.get_ticks_msec()
export(bool) var paused:bool = true
export(bool) var supress_flight = false
export(bool) var supress_swim = false
export(bool) var supress_magnetism = false
export(bool) var supress_climb = false
export(bool) var supress_glide = false
export(bool) var supress_dash = false

var timer_label

func _ready():
	timer_label = get_node(timer_path)
	initialize_savedata()
func _process(delta):	
	if paused:
		return	
	timer_label.text = get_time_str()
	if get_seconds_elapsed() >= autostop_seconds and autostop_enabled:
		stop()
		
func initialize_savedata():
	if not SaveState.other_data.has("InfiniteRailwayStats"):
		SaveState.other_data.InfiniteRailwayStats = {}
		
func stop():
	paused = true	
	save_trial_time()
	SaveState.set_ability("flight", true)
	SaveState.set_ability("swim", true)
	SaveState.set_ability("climb", true)
	SaveState.set_ability("dash", true)
	SaveState.set_ability("glide", true)
	SaveState.set_ability("magnetism", true)
	remove_button("StopTimer")
	emit_signal("TrialForceEnd")
func start():
		
	SaveState.set_ability("flight", !supress_flight)
	SaveState.set_ability("swim", !supress_swim)
	SaveState.set_ability("climb", !supress_climb)
	SaveState.set_ability("dash", !supress_dash)
	SaveState.set_ability("glide", !supress_glide)
	SaveState.set_ability("magnetism", !supress_magnetism)
	reset_timer()	
	paused = false

func remove_button(ButtonNodeName:String):
	var parent = get_parent()
	var button = parent.get_node(ButtonNodeName)
	if button:
		parent.remove_child(button)  	

func reset_timer():
	timer_label.text = "00:00:00"
	game_start_time = OS.get_ticks_msec()
		
func get_seconds_elapsed()->float:
	var current_time = OS.get_ticks_msec() - game_start_time	
	var seconds:float = current_time/1000.00
	return seconds
		
func get_time_str():
	var current_time = OS.get_ticks_msec() - game_start_time
	var minutes = current_time/1000/60
	var seconds = current_time/1000%60
	var msec = current_time%1000/10
	
	if minutes < 10:
		minutes = "0"+str(minutes)
	if seconds < 10:
		seconds = "0"+str(seconds)
	if msec < 10:
		if msec == 0:
			msec = "00"
		else:
			msec = "0" + str(msec)
	return str(minutes) + ":" + str(seconds) + ":" + str(msec)

func save_trial_time():
	SaveState.other_data.InfiniteRailwayStats[trialname] = get_seconds_elapsed()	
	
