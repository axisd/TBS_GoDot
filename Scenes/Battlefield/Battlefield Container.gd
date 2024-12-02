extends Node2D

var level_music = preload("res://assets/music/Chasing Daybreak.ogg")

var chapter_title = "Chapter 2: Fort Merceus"

var enemy_commander_name = "Vezarius"

func _ready():
	# Container for this
	BattlefieldInfo.level_container = self
	
	# Set Camera to new spot
	BattlefieldInfo.main_game_camera.position = Vector2(48, 0)
	
	# Set cursor
	BattlefieldInfo.cursor.position = Vector2(144,80)
	
	# Reset the turn manager
	BattlefieldInfo.turn_manager.reset()
	
	# Set Music
	BattlefieldInfo.music_player.get_node("AllyLevel").stream = level_music
	
	# Set victory condition
	BattlefieldInfo.victory = false
	BattlefieldInfo.victory_system.clear()
	BattlefieldInfo.victory_system.victory_condition_state = Victory_Checker.SURVIVE
	BattlefieldInfo.victory_system.turns_left_to_survive = 10
	
	# Enemy Commander
	BattlefieldInfo.enemy_commander = BattlefieldInfo.enemy_units[enemy_commander_name]
	
	# Load events for this level
	BattlefieldInfo.event_system.add_event(L2_Event_Part05.new())
	BattlefieldInfo.event_system.add_event(L2_Event_Part1.new())
	BattlefieldInfo.event_system.add_event(L2_Event_Part2.new())
	BattlefieldInfo.event_system.add_event(L2_Event_Part3.new())
	BattlefieldInfo.event_system.add_event(L2_Event_Part4.new())
	BattlefieldInfo.event_system.add_event(L2_Event_Part5.new())
	
	# Mid Level Events
	BattlefieldInfo.event_system.add_mid_event(L2_Event_Mid_10.new())
	BattlefieldInfo.event_system.add_mid_event(L2_Event_Mid_20.new())
	
	# Reset event manager
	BattlefieldInfo.event_system.current_state = Event_System.starting_events
	
	# Add the players from the y sort to the battle field y sort
	for player_unit in BattlefieldInfo.y_sort_player_party.get_children():
		BattlefieldInfo.y_sort_player_party.remove_child(player_unit)
		BattlefieldInfo.current_level.get_node("Node2D").add_child(player_unit)
	
	# Start the level
	if !BattlefieldInfo.save_load_system.is_loading_level:
		BattlefieldInfo.event_system.start_events_queue()
	
	# Get rid of the other one
	if has_node("/root/Level/Chapter 2"):
		get_node("/root/Level/Chapter 2").queue_free()

func check_loss():
	return BattlefieldInfo.ally_units.has("Seth")

func next_level():
	# Remove any ally units that are still alive
	for unit in BattlefieldInfo.current_level.get_node("Node2D").get_children():
		if unit.UnitMovementStats.is_ally:
			BattlefieldInfo.current_level.get_node("Node2D").remove_child(unit)
			BattlefieldInfo.y_sort_player_party.add_child(unit)
	
	#stop input
	BattlefieldInfo.cursor.disable_standard("hello world")
	
	# stop music
	BattlefieldInfo.music_player.get_node("AllyLevel").stop()
	
	# Fade Away
	BattlefieldInfo.battlefield_container.get_node("Anim").play_backwards("Fade")
	await BattlefieldInfo.battlefield_container.get_node("Anim").animation_finished
	
	# Move to next level
	WorldMapScreen.current_event = Level3_WM_Event_Part10.new()
	WorldMapScreen.connect_to_scene_changer()
	SceneTransition.change_scene_to_packed(WorldMapScreen, 0.1)
