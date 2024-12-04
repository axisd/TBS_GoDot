extends "res://Scenes/Events/Event Base.gd"

class_name L2_Event_Part1
# Event Description:
# Allies will chat for a bit then camera will move
# Steps:
# 0.5 Hide all enemies
# 1. Ally dialogue
# 2. Once ally dialogue is done, move camera south
# 3. Event complete
# Part Number: 1

# Dialogue between the characters
var dialogue = [
	"Seth@assets/units/cavalier/seth mugshot.png@Your highness, you shouldn't be outside right now.",
	"Seth@assets/units/cavalier/seth mugshot.png@I can't guarantee your safety out here. Please head back inside.",
	"Eirika@assets/units/eirika/eirika mugshot.png@I will be alright Seth. The soldiers are my people after all.",
	"Eirika@assets/units/eirika/eirika mugshot.png@Do you think father will be able to convince them to finally lay down their arms?",
	"Seth@assets/units/cavalier/seth mugshot.png@In all fairness, I truly don't know. His highness is a great king and I trust him to do the right decision.",
	"Eirika@assets/units/eirika/eirika mugshot.png@Yes... I think so too.",
	"Eirika@assets/units/eirika/eirika mugshot.png@However, I can't shake the feeling that we shouldn't be here right now.",
	"Seth@assets/units/cavalier/seth mugshot.png@Merceus is the safest place we can be right now. It is surrounded by water and high mountains.",
	"Seth@assets/units/cavalier/seth mugshot.png@It is not very well known to the outside world and given it's remote location, this is the best place to be right now.",
	"Seth@assets/units/cavalier/seth mugshot.png@I should check in with the forward guard. Please head back inside your highness.",
	"Eirika@assets/units/eirika/eirika mugshot.png@I will. Thank you Seth.",
	"Soldiers@assets/units/soldier/soldier_blue_portrait.png@Almyryan soldiers!"
]

var eirika

# Set Names for Debug
func _init():
	event_name = "Level 2 Event Eirika and allies talk, camera moves"
	event_part = "Part 1"
	
	path = "res://Scenes/Events/Level 2/L2 Event Part 10.gd"

func start():
	# Play intro song
	BattlefieldInfo.music_player.get_node("Unfufilled").volume_db = -5
	BattlefieldInfo.music_player.get_node("Unfufilled").play(0)

	
	# Move Eirika
	BattlefieldInfo.ally_units["Eirika"].visible = true
	eirika = BattlefieldInfo.ally_units["Eirika"]
	
	# Signals needed
	BattlefieldInfo.message_system.connect("no_more_text", Callable(self, "move_camera"))
	BattlefieldInfo.movement_system_cinematic.connect("unit_finished_moving_cinema", Callable(self, "start_dialogue"))
	BattlefieldInfo.event_system.get_node("Timer").connect("timeout", Callable(self, "move_actor"))
	
	# Move Eirika
	play_door_sound()

func play_door_sound():
	# Play door open sound
	BattlefieldInfo.extra_sound_effects.get_node("Open Door").play(0)
	
	# Pause for 1 second
	BattlefieldInfo.event_system.get_node("Timer").wait_time = 1.0
	BattlefieldInfo.event_system.get_node("Timer").start(0)

func move_actor():
	# Build path to the enemy
	BattlefieldInfo.movement_calculator.get_path_to_destination_AI(eirika, BattlefieldInfo.grid[9][6], BattlefieldInfo.grid)
	
	# Remove original tile
	eirika.UnitMovementStats.currentTile.occupyingUnit = null
	
	# Move Actor
	# Add actors to movement
	BattlefieldInfo.movement_system_cinematic.unit_to_move_same_time.append(eirika)
	BattlefieldInfo.movement_system_cinematic.is_moving = true


func start_dialogue():
	BattlefieldInfo.message_system.set_position(Messaging_System.TOP)
	enable_text(dialogue)

func move_camera():
	# New Position
	var new_position_for_camera = Vector2(0,190)
	
	# Slow music down and turn it off
	BattlefieldInfo.music_player.music_tween \
		.tween_property(BattlefieldInfo.music_player.get_node("Unfufilled"), "volume_db", \
			Tween.interpolate_value(0.0, -80.0, 0.25, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT), 0.5)
	
	# Move Camera
	BattlefieldInfo.main_game_camera.camera_tween.finished.connect(event_complete)
	BattlefieldInfo.main_game_camera.camera_tween \
		.tween_property(BattlefieldInfo.main_game_camera, "position", \
			Tween.interpolate_value(BattlefieldInfo.main_game_camera.position, new_position_for_camera - BattlefieldInfo.main_game_camera.position, 0.5, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT), \
			1)
	BattlefieldInfo.main_game_camera.camera_tween.play()
