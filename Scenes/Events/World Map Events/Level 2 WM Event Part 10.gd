extends World_Map_Event

class_name Level2_WM_Event_Part10

# New Game start
var level3 = "res://Scenes/Battlefield/Chapter 3.tscn"

# Eirika Start and move
var eirika_final = Vector2(-162, -134)
var eirika_initial = Vector2(-168, - 93)

func _init():
	# Text
	text_array = [
		"After giving the report on the situation at the village borders, King Terenas invites the Almaryan envoy to discuss the terms of peace",
		"With these historial peace negotiations about to start, Eirika's father, King Terenas\nsends his daughter to Fort Merceus with Knight Commander Seth.",
		"Accompanied by her friends and closest allies, they set out for Fort Merceus.",
		"That night, a terrible storm blankets the region..."
	]
	
	# Signals needed
	WorldMapScreen.get_node("Eirika/Eirika Tween").connect("tween_completed", Callable(self, "after_eirika_move"))
	WorldMapScreen.get_node("Message System").connect("no_more_text", Callable(self, "after_text"))
	
	# Set text position bottom
	WorldMapScreen.get_node("Message System").set_position(Messaging_System.BOTTOM)
	
	# Place Fort and Castle
	castle_waypoints_array.append(Vector2(-164, -94))
	fort_waypoints_array.append(Vector2(-159, -129))
	village_waypoints_array.append(Vector2(-118, -35))

func run():
	# Set Eirika's initial position
	WorldMapScreen.get_node("Eirika").position = eirika_initial
	
	# 1.5 second pause
	await get_tree().create_timer(2).timeout
	
	# Move Eirika and start text
	WorldMapScreen.get_node("Message System").start(text_array)
	WorldMapScreen.move_eirika(eirika_final, 3)

func build_map():
	# Create castle
	for c_waypoint in castle_waypoints_array:
		WorldMapScreen.place_castle_waypoint(c_waypoint)
	
	# Create fort
	for f_waypoint in fort_waypoints_array:
		WorldMapScreen.place_fort_waypoint(f_waypoint)

func after_text():
	await get_tree().create_timer(0.5).timeout
	SceneTransition.change_scene_to_file("res://Scenes/Chapter/Chapter Background.tscn", 0.1)
	WorldMapScreen.exit()
	await SceneTransition.scene_changed
	SceneTransition.get_tree().current_scene.start(Callable("2", "Fort Merceus").bind(level3), 2)
	queue_free()
