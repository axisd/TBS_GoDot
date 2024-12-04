extends "res://Scenes/Events/Event Base.gd"

class_name L2_Event_Part5
# Event Description:
# Camera pans back to original location, all allies are now visible, Eirika and Seth have a few last words and then into combat we go
# Steps:
# 1. Camera pans back to original location
# 2. Dialogue
# 3. Move Units into the castle
# 4. Gameplay
# Part Number: 3

# Dialogue between the characters
var dialogue = [
	"Soldiers@assets/units/soldier/soldier_blue_portrait.png@Protect Lady Eirika with your lives!",
	"Soldiers@assets/units/soldier/soldier_blue_portrait.png@Don't let a single one of those bastards get through!",
	"Soldiers@assets/units/soldier/soldier_blue_portrait.png@For Ephraim!"
]

func _init():
	event_name = "Level 2 Before Battle Event"
	event_part = "Part 3"
	path = "res://Scenes/Events/Level 2/L2 Event Part 50.gd"

func start():
	# Register to the dialogue system
	BattlefieldInfo.message_system.connect("no_more_text", Callable(self, "move_camera"))
	# Start Text
	enable_text(dialogue)
	
func move_camera():
	# New Position
	var new_position_for_camera = Vector2(48,0)
	
	# Move Camera and Remove old camera
	BattlefieldInfo.main_game_camera.camera_tween.finished.connect(event_complete)
	BattlefieldInfo.main_game_camera.camera_tween \
		.tween_property(BattlefieldInfo.main_game_camera, "position", \
			Tween.interpolate_value(BattlefieldInfo.main_game_camera.position, new_position_for_camera - BattlefieldInfo.main_game_camera.position, 0.5, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT), \
			1)
	BattlefieldInfo.main_game_camera.camera_tween.play()
