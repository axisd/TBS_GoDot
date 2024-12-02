extends Node2D

# The world map which is shown in between chapters

# Way Point markers
var castle_waypoint_marker = preload("res://Scenes/World Map/World Map Icons/Castle Icon.tscn")
var fort_waypoint_marker = preload("res://Scenes/World Map/World Map Icons/Fortress Icon.tscn")
var village_waypoint_marker = preload("res://Scenes/World Map/World Map Icons/Village Icon.tscn")

# Way Points Array
var castle_waypoints : Array = []
var fort_waypoints : Array = []
var village_waypoints : Array = []

# Eirika
var eirika_off_screen : Vector2 = Vector2(-300, -75)

# Script for the event on the world map
var current_event

func _ready():
	var tween = get_tree().create_tween()
	tween.tween_callback(Callable(self, "set_eirika_idle")).set_delay(1)

# Start this map
func start():
	# Set Map settings
	visible = true
	modulate = Color(0,0,0,1)
	
	# Set World map
	current_event.world_map = self
	
	# Add child
	add_child(current_event)
	
	# Set Current camera
	$"World Map Cam".current = true
	
	# Clear map and build
	clear_map()
	current_event.build_map()
	
	# Fade in
	$Anim.play("Fade ")

	# Wait until animation is done
	await $Anim.animation_finished
	
	# Start music
	$"World Map Music 1".volume_db = 0
	$"World Map Music 1".play(0)
	
	# Run the event
	current_event.run()
	
	# DC
	SceneTransition.disconnect("scene_changed", Callable(self, "start"))

# Place a new waypoint for a castle
func place_castle_waypoint(castle_position):
	var c_waypoint_marker = castle_waypoint_marker.instantiate()
	c_waypoint_marker.position = castle_position
	castle_waypoints.append(c_waypoint_marker)
	add_child(c_waypoint_marker)

# Place a new waypoint for a fort
func place_fort_waypoint(fort_position):
	var f_waypoint_marker = fort_waypoint_marker.instantiate()
	f_waypoint_marker.position = fort_position
	fort_waypoints.append(f_waypoint_marker)
	add_child(f_waypoint_marker)

func place_village_waypoint(village_position):
	var v_waypoint_marker = village_waypoint_marker.instantiate()
	v_waypoint_marker.position = village_position
	village_waypoints.append(v_waypoint_marker)
	add_child(v_waypoint_marker)

# Place Eirika's new position
func place_eirika(eirika_new_position):
	$Eirika.visible = true
	$Eirika.position = eirika_new_position
	$Eirika/Animation.play("Idle")

# Move Eirika to the new position
func move_eirika(eirika_next_position, movement_seconds = 1):
	var tween : Tween = get_tree().create_tween()
	tween.tween_property($Eirika, "position", \
		Tween.interpolate_value($Eirika.position, eirika_next_position - $Eirika.position, movement_seconds / 2.0, movement_seconds, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT), movement_seconds)
	# Play appropriate animation for Eirika
	if $Eirika.position.x - eirika_next_position.x <= 0:
		$Eirika/Animation.play("Right no sound")
	else:
		$Eirika/Animation.play("Left no sound")
	tween.play()

# Set Camera position
func set_camera_position(new_camera_position):
	$"World Map Cam".position = new_camera_position

# Move the Camera
func move_camera(camera_next_position, movement_seconds = 1):
	var tween : Tween = get_tree().create_tween()
	tween.tween_property($"World Map Cam", "position", \
		Tween.interpolate_value($"World Map Cam".position, camera_next_position - $"World Map Cam".position, movement_seconds / 2.0, movement_seconds, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT), movement_seconds)
	tween.play()

# Set Eirika Animation back to idle
func set_eirika_idle():
	$Eirika/Animation.play("Idle")

# Stop Main camera
func stop_main_camera():
	$"World Map Cam".current = false

# Use to cleanup anything from this screen
func exit():
	$Anim.play_backwards("Fade")
	var tween : Tween = get_tree().create_tween()
	tween.tween_property($"World Map Music 1", "volume_db", \
		Tween.interpolate_value(0.0, -80.0, 0.25, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT), 0.5)
	tween.play()
	await $Anim.animation_finished
	$"World Map Music 1".stop()
	current_event = null
	clear_map()

# Connect to Scene changer
func connect_to_scene_changer():
	SceneTransition.connect("scene_changed", Callable(self, "start"))

# Clear the map
func clear_map():
	# Remove Waypoints
	for c_waypoint in castle_waypoints:
		c_waypoint.queue_free()
	
	for f_waypoint in fort_waypoints:
		f_waypoint.queue_free()
	
	for v_waypoint in village_waypoints:
		v_waypoint.queue_free()
	
	castle_waypoints.clear()
	fort_waypoints.clear()
	village_waypoints.clear()
	
	# Reset Eirika
	$Eirika.position = eirika_off_screen
