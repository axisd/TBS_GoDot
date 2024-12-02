extends Node2D

## TEST ##
# New test system for events

# Queue to hold all events
var all_events_queue = []

# Debug info
var current_event_name = "DEFAULT"
var is_running = false

# Enum for all event names
enum EVENT_NAMES {MOVE_CAMERA, MOVE_ACTOR, DIALOGUE, COMBAT, MOVE_CURSOR, HIDE_UNIT, SHOW_UNIT}

# Signal for next even
signal event_done
signal all_events_done

func _ready():
	# Connect to self for signals
	self.event_done.connect(parse_event)
	
	# Connect to the camera to know when the tween is done
	BattlefieldInfo.main_game_camera.camera_tween.finished.connect(event_complete)

func start(all_events_array):
	for event in all_events_array:
		add_to_queue(event)

# Process Event
func parse_event(event):
	# Do not process event if the queue is empty
	if all_events_queue.size() == 0:
		emit_signal("all_events_done")
		return
	
	# Process next event
	match event[0]:
		EVENT_NAMES.MOVE_CAMERA:
			set_debug_info(event[1])
			move_camera(event[2], event[3], event[4])
	

## The following are helper functions to facilitate progression of the story

# Move the camera
func move_camera(starting_position, ending_position, time_to_move):
	BattlefieldInfo.main_game_camera.camera_tween \
		.tween_property(BattlefieldInfo.main_game_camera, "position", \
		Tween.interpolate_value(starting_position, ending_position - starting_position, time_to_move / 2, time_to_move, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT), time_to_move)
	BattlefieldInfo.main_game_camera.current = true
	BattlefieldInfo.main_game_camera.camera_tween.play()

# Move units
func move_units(array_of_units_to_move):
	BattlefieldInfo.movement_system_cinematic.is_moving = true

# Initiate Dialogue
func start_dialogue(dialogue_text):
	pass

# Combat between units
func start_combat_btn_units(unit_a, unit_b):
	pass

# Move the cursor to certain coordinate
func move_cursor(new_cursor_position):
	pass

# Makes a unit invisible
func hide_unit(unit):
	pass

# Makes a unit visible
func show_unit(unit):
	pass

func event_complete():
	event_done.emit()	

# Event queue operations
func add_to_queue(event):
	all_events_queue.append(event)

func remove_event(event):
	return all_events_queue.pop_front()

# Debug functions
func set_debug_info(event_name):
	current_event_name = event_name
	is_running = true

func reset_debug_info():
	current_event_name = "DEFAULT"
	is_running = false
