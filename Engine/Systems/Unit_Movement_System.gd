extends Node

# Controls the movement system for the units
class_name Unit_Movement_System

# On/off
var is_moving = false

# Update the world info
signal unit_finished_moving
signal action_selector_screen

var battlefield

func _ready():
	battlefield = get_parent()

func process_movement(delta):
	if !is_moving:
		return
	
	# Variables needed to move the units
	var unit = BattlefieldInfo.current_Unit_Selected
	var starting_cell = unit.UnitMovementStats.currentTile
	var destination_cell = unit.UnitMovementStats.movement_queue.front()
	
	# Set correct animation for unit moving
	unit.get_node("Animation").current_animation = unit.get_direction_to_face(starting_cell, destination_cell)
	
	# Move Unit and smooth it out over time
	if abs(unit.position.x - destination_cell.position.x) >= 0.75 || abs(unit.position.y - destination_cell.position.y) >= 0.75:
		unit.position.x += (destination_cell.position.x - starting_cell.position.x) * unit.animation_movement_speed * delta
		unit.position.y += (destination_cell.position.y - starting_cell.position.y) * unit.animation_movement_speed * delta
		# unit.get_node("Sound_Movement").play()
	else:
		# Finalize movement to prevent rounding errors
		unit.position.x = destination_cell.position.x
		unit.position.y = destination_cell.position.y
		unit.UnitMovementStats.currentTile = destination_cell
		
		# Remove the tile in the queue
		unit.UnitMovementStats.movement_queue.pop_front()
	
	# Prevent weird bug when the FPS drops or game is paused
	if abs(unit.position.x - destination_cell.position.x) >= 16 || abs(unit.position.y - destination_cell.position.y) >= 16:
		# Finalize movement to prevent rounding errors
		unit.position.x = destination_cell.position.x
		unit.position.y = destination_cell.position.y
		unit.UnitMovementStats.currentTile = destination_cell
		
		# Remove the tile in the queue
		unit.UnitMovementStats.movement_queue.pop_front()
	
	# Check if we have no more moves left in the queue
	if unit.UnitMovementStats.movement_queue.empty():
		# Stop moving
		is_moving = false
		
		# Set the new current tile and update the world tiles
		unit.UnitMovementStats.currentTile = destination_cell
		unit.UnitMovementStats.currentTile.occupyingUnit = unit
		
		# Turn off tiles
		BattlefieldInfo.movement_calculator.turn_off_all_tiles(unit, BattlefieldInfo.grid)
		
		# Emit signal to update the cells
		emit_signal("unit_finished_moving")
		
		# Activate AI vs Player Unit
		if unit.has_node("AI"):
			BattlefieldInfo.turn_manager.turn = Turn_Manager.ENEMY_TURN
			
			# Process another AI method here ie, check for attack/do whatever after moving for now just wait
			unit.UnitActionStatus.set_current_action(Unit_Action_Status.DONE)
			unit.turn_greyscale_on()
			unit.get_node("Animation").current_animation = "Idle"
		else:
			# Set unit's status to action state and animation
			unit.UnitActionStatus.set_current_action(Unit_Action_Status.ACTION)
			if BattlefieldInfo.current_Unit_Selected.get_node("Animation").current_animation == "Idle":
				BattlefieldInfo.current_Unit_Selected.get_node("Animation").current_animation == "Idle"
			else:
				BattlefieldInfo.current_Unit_Selected.get_node("Animation").current_animation = str(BattlefieldInfo.current_Unit_Selected.get_node("Animation").current_animation, " no sound")
			
			# Go to the action selector screen
			emit_signal("action_selector_screen")