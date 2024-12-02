extends World_Map_Event

class_name Level4_WM_Event_Part10

# New Game start
var level4 = "res://Scenes/Battlefield/Chapter 5.tscn"

# Eirika Start and move
var eirika_initial = Vector2(-178, -154)
var eirika_final = Vector2(-167, -100)

func _init():
	# Text
	text_array = [
		"Princess Eirika and her companions defeat the pirates and Almaryan mages and are able to finally reach the shore.",
		"The fastest way to the capital city is by the main road by the Great Fortress Line.",
		"As they hurry toward the capital, they approach the Great Fortress Line..."
	]
	
	# Signals needed
	var tween = get_tree().create_tween()
	tween.tween_callback(Callable(self, "after_eirika_move")).set_delay(1)
	WorldMapScreen.get_node("Message System").no_more_text.connect(after_text)
	
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
	SceneTransition.get_tree().current_scene.start(Callable("5", "The Great Fortress Line").bind(level4), 2)
	queue_free()
