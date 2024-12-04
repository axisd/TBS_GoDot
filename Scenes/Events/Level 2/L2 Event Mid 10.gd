extends Event_Base

class_name L2_Event_Mid_10

# Move Vez back to original position and start spawning reinforcements

var dialogue = [
		"Vezarius@assets/units/enemyPortrait/Main Villain MugShot.png@Hmph, I didn't expect them to put up this much of a fight.",
		"Vezarius@assets/units/enemyPortrait/Main Villain MugShot.png@We are going to reinforcements for this."
]

# Actors
var vez
var id_number = 99

func _init():
	# Get General vez
	vez = BattlefieldInfo.enemy_units["Vezarius"]
	
	# Register to the turn numbers
	BattlefieldInfo.turn_manager.connect("enemy_turn_increased", Callable(self, "start_mid"))
	BattlefieldInfo.turn_manager.connect("player_turn_increased", Callable(self, "play_player_transition"))
	
	path = "res://Scenes/Events/Level 2/L2 Event Mid 10.gd"

func play_player_transition(turn_number):
	BattlefieldInfo.turn_manager.start_ally_transition()

func start_mid(turn_number):
	# Do not process if turn is not 2
	if turn_number != 4:
		BattlefieldInfo.turn_manager.start_enemy_transition()
		return
	
	# Turn off UI/Input
	BattlefieldInfo.event_system.pause_ui()
	
	# Signals needed
	BattlefieldInfo.movement_system_cinematic.individual_unit_finished_moving.connect(start_dialogue)
	BattlefieldInfo.message_system.no_more_text.connect(spawn_enemies)
	BattlefieldInfo.main_game_camera.camera_tween.finished.connect(move_actor)
	
	move_camera()

func move_camera():
	var new_position_for_camera = Vector2(0,190)
	BattlefieldInfo.main_game_camera.camera_tween \
		.tween_property(BattlefieldInfo.main_game_camera, "position", \
			Tween.interpolate_value(BattlefieldInfo.main_game_camera.position, new_position_for_camera - BattlefieldInfo.main_game_camera.position, 0.5, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT), \
			1)
	BattlefieldInfo.main_game_camera.current = true
	BattlefieldInfo.main_game_camera.camera_tween.play()

func move_actor():
	# Build path to Vezarius Original Location
	BattlefieldInfo.movement_calculator.get_path_to_destination_AI(vez, BattlefieldInfo.grid[0][272 / 16], BattlefieldInfo.grid)
	
	# Remove original tile
	vez.UnitMovementStats.currentTile.occupyingUnit = null
	
	# Move Actor
	BattlefieldInfo.movement_system_cinematic.unit_to_move_same_time.append(vez)
	BattlefieldInfo.movement_system_cinematic.is_moving = true

func start_dialogue(unit):
	BattlefieldInfo.message_system.set_position(Messaging_System.TOP)
	enable_text(dialogue)

# Spawn a bunch of new enemies then move them
func spawn_enemies():
	
	# Enemy list
	var e_soldier = preload("res://Scenes/Units/Enemy_Units/Enemy Soldier.tscn")
	var a_soldier = preload("res://Scenes/Units/Enemy_Units/Black Archer.tscn")
	var b_soldier = preload("res://Scenes/Units/Enemy_Units/Bandit.tscn")
	
	# Spawn a bunch of new enemies
	for spawn_point in BattlefieldInfo.spawn_points:
		var random_unit = Calculators.get_random_number(0,2)
		var newEnemy
		
		# Spawn random new enemy based on the number that was randomly generated
		match random_unit:
			0:
				newEnemy = e_soldier.instantiate()
			1:
				newEnemy = a_soldier.instantiate()
			2:
				newEnemy = b_soldier.instantiate()
		
		for adjCell in spawn_point.adjCells:
			if adjCell.occupyingUnit == null:
				newEnemy.get_node("AI").ai_type = "Aggresive"
				BattlefieldInfo.current_level.get_node("Node2D").add_child(newEnemy)
				
				# Set Stats and position
				newEnemy.position = adjCell.position
				newEnemy.UnitStats.name = "Soldier"
				newEnemy.UnitStats.strength = 5 + Calculators.get_random_number(0,2)
				newEnemy.UnitStats.skill = 3 + Calculators.get_random_number(0,2)
				newEnemy.UnitStats.speed = 2 + Calculators.get_random_number(0,2)
				newEnemy.UnitStats.magic = 0
				newEnemy.UnitStats.luck = 0 + Calculators.get_random_number(0,2)
				newEnemy.UnitStats.def = 1 + Calculators.get_random_number(0,2) 
				newEnemy.UnitStats.res = 0 + Calculators.get_random_number(0,2)
				newEnemy.UnitStats.consti = 8
				newEnemy.UnitStats.bonus_crit = 0
				newEnemy.UnitStats.bonus_dodge = 0
				newEnemy.UnitStats.bonus_hit = 0
				newEnemy.UnitStats.level = 3 + Calculators.get_random_number(0,2)
				newEnemy.UnitStats.class_type = "Soldier"
				newEnemy.UnitStats.current_health = 21  + Calculators.get_random_number(0,2)
				newEnemy.UnitStats.max_health = newEnemy.UnitStats.current_health
				
				
				# XP Stats
				newEnemy.UnitStats.class_power = 3
				newEnemy.UnitStats.class_bonus_a = 0
				newEnemy.UnitStats.class_bonus_b = 0
				newEnemy.UnitStats.boss_bonus = 0
				newEnemy.UnitStats.thief_bonus = 0
				
				# Set the current tile
				newEnemy.UnitMovementStats.currentTile = adjCell
				adjCell.occupyingUnit = newEnemy
				
				# Add Unit to the list of enemies
				newEnemy.UnitMovementStats.is_ally = false
				id_number += 1
				newEnemy.UnitStats.identifier = str("Enemy ",id_number)
				BattlefieldInfo.enemy_units[str("Enemy ",id_number)] = newEnemy
	
	# Remove this from the array
	BattlefieldInfo.event_system.mid_level_events.erase(self)
	BattlefieldInfo.turn_manager.start_enemy_transition()
	queue_free()
