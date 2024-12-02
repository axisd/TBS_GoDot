extends RefCounted
# Movement Calculator for units
# Calculates which tiles you can move, attack and heal
# Calculates using A* which is the shortest path to the target cell
class_name MovementCalculator

# Reference 
var battlefield

# BFS
var queue = []

# Constructor
func _init(battlefield):
	self.battlefield = battlefield
	

# Calculate Movement Blue Squares
func calculatePossibleMoves(Unit, AllTiles) -> void:
	# Clear the allowed tiles before calculation
	Unit.UnitMovementStats.allowedMovement.clear()
	Unit.UnitMovementStats.allowedAttackRange.clear()
	Unit.UnitMovementStats.allowedHealRange.clear()
	
	# Reset Grid values
	reset_grid_values()
	reset_parent_tile_values()
	
	# Process Move Tiles
	processTile(Unit.UnitMovementStats.currentTile, Unit.UnitMovementStats, Unit.UnitMovementStats.movementSteps, Unit)
	
	# Process Attack tiles -> Find a better way of optimizing this
	processAttackTile(Unit)
	
	# Process Heal Tiles -> Find better way of optimizaing this
	processHealingTile(Unit)
	
	# Turn on the tiles
	turn_on_all_tiles(Unit, AllTiles)

# Turn on tiles for enemies only
func highlight_enemy_movement_range(Unit, AllTiles) -> void:
	# Calculate the move
	calculatePossibleMoves(Unit, AllTiles)
	
	# Turn off the tiles
	turn_off_all_tiles(Unit, AllTiles)
	
	# Light all the blue tiles -> Change this later to check if the unit has a healing ability and turn on green tiles
	for blueTile in Unit.UnitMovementStats.allowedMovement:
		AllTiles[blueTile.getPosition().x][blueTile.getPosition().y].get_node("MovementRangeRect").turnOn("Purple")
	for redTile in Unit.UnitMovementStats.allowedAttackRange:
		AllTiles[redTile.getPosition().x][redTile.getPosition().y].get_node("MovementRangeRect").turnOn("Purple")
	for greenTile in Unit.UnitMovementStats.allowedHealRange:
		AllTiles[greenTile.getPosition().x][greenTile.getPosition().y].get_node("MovementRangeRect").turnOn("Purple")

# Process all the tiles to find what is movable to
func processTile(initialTile, unit_movement, moveSteps, unit):
	# Set parent tile
	initialTile.parentTile = initialTile
	
	# Add first tile to the queue
	queue.append([moveSteps, initialTile])
	
	# Process queue until it is empty
	while !queue.is_empty():
		
		# Pop the first tile
		var tile_to_check = queue.pop_front()
		
		# Add tile to allowed movement and set visited status to true
		unit_movement.allowedMovement.append(tile_to_check[1])
#		tile_to_check[1].isVisited = true
		
		# Get the next cost
		for adjTile in tile_to_check[1].adjCells:
			var next_cost = tile_to_check[0] - adjTile.movementCost - getPenaltyCost(unit, unit_movement, adjTile)
			
			if next_cost >= 0 && !adjTile.isVisited:
				# Is the tile occupied? -> Tile is not occupied, process right away
				if adjTile.occupyingUnit == null:
					adjTile.parentTile = tile_to_check[1]
					adjTile.isVisited = true
					queue.append([next_cost, adjTile])
				else:
					# Tile is occupied -> Check if it's an ally (or enemy for enemy)
					if adjTile.occupyingUnit.UnitMovementStats.is_ally == unit_movement.is_ally:
						adjTile.parentTile = tile_to_check[1]
						adjTile.isVisited = true
						queue.append([next_cost, adjTile])


# Process Attackable Range
func processAttackTile(Unit):
	# Reset values
	reset_grid_values()
	var new_queue = []
	
	# Get tiles
	var moveSteps = (Unit.UnitInventory.MAX_ATTACK_RANGE - 1)
	
	if moveSteps == -1:
		return
	
	for blueTile in Unit.UnitMovementStats.allowedMovement:
		for adjTile in blueTile.adjCells:
			if !Unit.UnitMovementStats.allowedMovement.has(adjTile):
				new_queue.append([moveSteps, adjTile])
	
	# BFS Search for attack tiles
	while !new_queue.is_empty():
		var check_tile = new_queue.pop_front()
		if !Unit.UnitMovementStats.allowedAttackRange.has(check_tile[1]): 
			Unit.UnitMovementStats.allowedAttackRange.append(check_tile[1])
			check_tile[1].isVisited = true
		
		# Get the next cost
		for adjTile in check_tile[1].adjCells:
			var next_cost = check_tile[0] - 1

			# Do not process tiles that we have already seen or if we cannot get there or if the movement already has this
			if next_cost >= 0 && !adjTile.isVisited && !Unit.UnitMovementStats.allowedMovement.has(adjTile):
				new_queue.append([next_cost, adjTile])

# Process Healing Range
func processHealingTile(Unit):
	# Reset values
	reset_grid_values()
	var new_queue = []
	
	# Get tiles
	var moveSteps = (Unit.UnitInventory.MAX_HEAL_RANGE - 1)
	
	if moveSteps == -1:
		return
	
	for blueTile in Unit.UnitMovementStats.allowedMovement:
		for adjTile in blueTile.adjCells:
			if !Unit.UnitMovementStats.allowedMovement.has(adjTile):
				new_queue.append([moveSteps, adjTile])
	
	# BFS Search for attack tiles
	while !new_queue.is_empty():
		var check_tile = new_queue.pop_front()
		if !Unit.UnitMovementStats.allowedAttackRange.has(check_tile[1]) && !Unit.UnitMovementStats.allowedHealRange.has(check_tile[1]):
			Unit.UnitMovementStats.allowedHealRange.append(check_tile[1])
			check_tile[1].isVisited = true
		
		# Get the next cost
		for adjTile in check_tile[1].adjCells:
			var next_cost = check_tile[0] - 1

			# Do not process tiles that we have already seen or if we cannot get there or if the movement already has this
			if next_cost >= 0 && !adjTile.isVisited && !Unit.UnitMovementStats.allowedMovement.has(adjTile):
				new_queue.append([next_cost, adjTile])

# Returns the penalty cost associated with the unit's class for moving across different tiles
func getPenaltyCost(Unit, Unit_Movement, cell) -> int:
	# Flying units can get through
	if Unit.UnitStats.pegasus:
		if cell.movementCost < 1000:
			return (cell.movementCost - 1) * -1
		else:
			return 0
	
	# Everyone else
	var cell_type = cell.tileName
	match cell_type:
		"Plain", "Road", "Bridge", "Throne":
			return Unit_Movement.defaultPenalty
		"Mountain", "Cliff":
			return Unit_Movement.mountainPenalty
		"Hill":
			return Unit_Movement.hillPenalty
		"Forest":
			return Unit_Movement.forestPenalty
		"Fortress":
			return Unit_Movement.fortressPenalty
		"Village":
			return Unit_Movement.buildingPenalty
		"River":
			return Unit_Movement.riverPenalty
		"Ruins":
			return Unit_Movement.ruinsPenalty
		"Sea":
			return Unit_Movement.seaPenalty
		_:
			# fall through
			return 0

# Turn on all tiles
func turn_on_all_tiles(Unit, AllTiles) -> void:
	# Light all the blue tiles -> Change this later to check if the unit has a healing ability and turn on green tiles
	for blueTile in Unit.UnitMovementStats.allowedMovement:
		AllTiles[blueTile.getPosition().x][blueTile.getPosition().y].get_node("MovementRangeRect").turnOn("Blue")
	for redTile in Unit.UnitMovementStats.allowedAttackRange:
		AllTiles[redTile.getPosition().x][redTile.getPosition().y].get_node("MovementRangeRect").turnOn("Red")
	for greenTile in Unit.UnitMovementStats.allowedHealRange:
		AllTiles[greenTile.getPosition().x][greenTile.getPosition().y].get_node("MovementRangeRect").turnOn("Green")

# Turn off all tiles
func turn_off_all_tiles(Unit, AllTiles) -> void:
	# Turn off blue
	for blueTile in Unit.UnitMovementStats.allowedMovement:
		AllTiles[blueTile.getPosition().x][blueTile.getPosition().y].get_node("MovementRangeRect").turnOff("Blue")
	# Turn off Red -> TO DO
	for redTile in Unit.UnitMovementStats.allowedAttackRange:
		AllTiles[redTile.getPosition().x][redTile.getPosition().y].get_node("MovementRangeRect").turnOff("Red")
	# Turn off Green -> TO DO
	for greenTile in Unit.UnitMovementStats.allowedHealRange:
		AllTiles[greenTile.getPosition().x][greenTile.getPosition().y].get_node("MovementRangeRect").turnOff("Green")

# Turn off only purple
func turn_off_purple(Unit, AllTiles) -> void:
		# Turn off blue
	for blueTile in Unit.UnitMovementStats.allowedMovement:
		AllTiles[blueTile.getPosition().x][blueTile.getPosition().y].get_node("MovementRangeRect").turnOff("Purple")
	# Turn off Red -> TO DO
	for redTile in Unit.UnitMovementStats.allowedAttackRange:
		AllTiles[redTile.getPosition().x][redTile.getPosition().y].get_node("MovementRangeRect").turnOff("Purple")
	# Turn off Green -> TO DO
	for greenTile in Unit.UnitMovementStats.allowedHealRange:
		AllTiles[greenTile.getPosition().x][greenTile.getPosition().y].get_node("MovementRangeRect").turnOff("Purple")

# Find the shortest path to the target destination | No A* algorithm | Player version only
func get_path_to_destination(Unit, target_destination, AllTiles):
	# Create the pathfinding queue directly?
	create_pathfinding_queue(target_destination, Unit)

## Find the shortest path to the target destination | This uses the A* algorithm | Player Version
#func get_path_to_destination(Unit, target_destination, AllTiles):
#	# Clear Tile statistics first
#	for tile_array in AllTiles:
#		for tile in tile_array:
#			tile.parentTile = null
#			tile.hCost = 0
#			tile.gCost = 0
#			tile.fCost = 0
#
#	# Clear Queue for the unit
#	Unit.UnitMovementStats.movement_queue.clear()
#
#	# Hashset and Priority Queue to hold all the tiles needed
#	var closed_list = HashSet.new()
#	var open_list = PriorityQueue.new()
#
#	# Get Current Tile
#	var current_tile = Unit.UnitMovementStats.currentTile
#
#	# Add the current cell we are starting on to this list
#	open_list.add_first(Unit.UnitMovementStats.currentTile)
#
#	# Process Tiles until the open list is empty
#	while !open_list.is_empty():
#		# Remove the first tile in the list and add it to the closed list
#		current_tile = open_list.pop_front()
#		closed_list.add(current_tile)
#
#		# Check if we have reached our destination
#		if current_tile == target_destination:
#			break
#
#		# Process Adj Tiles
#		for adjCell in current_tile.adjCells:
#			# Do not process unwalkable tiles or we can't go there
#			if adjCell.movementCost >= 101 || closed_list.contains(adjCell) || !Unit.UnitMovementStats.allowedMovement.has(adjCell):
#				continue
#
#			# Calculate Heuristic costs
#			var movement_cost_to_neighbor = current_tile.gCost + adjCell.movementCost + getPenaltyCost(Unit, Unit.UnitMovementStats, adjCell)
#			if movement_cost_to_neighbor < adjCell.gCost || !open_list.contains(adjCell):
#				adjCell.gCost = movement_cost_to_neighbor
#				adjCell.hCost = calculate_hCost(adjCell, target_destination, Unit, AllTiles)
#				adjCell.parentTile = current_tile
#
#				# Add to the open List
#				if !open_list.contains(adjCell):
#					open_list.add_first(adjCell)
#
#	# Create the Pathfinding Queue
#	create_pathfinding_queue(target_destination, Unit)

# Find the shortest path to the target destination | AI Version | Use this for cinematic purposes too
func get_path_to_destination_AI(Unit, target_destination, AllTiles):
	# Clear Tile statistics first
	for tile_array in AllTiles:
		for tile in tile_array:
			# tile.parentTile = null
			tile.hCost = 0
			tile.gCost = 0
	
	# Clear Queue for the unit
	Unit.UnitMovementStats.movement_queue.clear()
	
	# Hashset and Priority Queue to hold all the tiles needed
	var closed_list = HashSet.new()
	var open_list = PriorityQueue.new()
	
	# Get Current Tile
	var current_tile = Unit.UnitMovementStats.currentTile
	
	# Add the current cell we are starting on to this list
	open_list.add_first(Unit.UnitMovementStats.currentTile)
	
	# Process Tiles until the open list is empty
	while !open_list.is_empty():
		# Remove the first tile in the list and add it to the closed list
		current_tile = open_list.pop_front()
		closed_list.add(current_tile)

		# Check if we have reached our destination
		if current_tile == target_destination:
			break
		
		# Process Adj Tiles
		for adjCell in current_tile.adjCells:
			# Do not process unwalkable tiles or we can't go there
			if Unit.has_node("AI"):
				if adjCell.movementCost >= 100 || closed_list.contains(adjCell):
					continue
			else:
				if adjCell.movementCost >= 101 || closed_list.contains(adjCell):
					continue
			
			# Calculate Heuristic costs
			var movement_cost_to_neighbor = current_tile.gCost + adjCell.movementCost + getPenaltyCost(Unit, Unit.UnitMovementStats, adjCell)
			if movement_cost_to_neighbor < adjCell.gCost || !open_list.contains(adjCell):
				adjCell.gCost = movement_cost_to_neighbor
				adjCell.hCost = calculate_hCost(adjCell, target_destination, Unit, AllTiles)
				adjCell.parentTile = current_tile
				
				# Add to the open List
				if !open_list.contains(adjCell):
					open_list.add_first(adjCell)
	
	# Create the Pathfinding Queue
	create_pathfinding_queue(target_destination, Unit)

# Calculates the H Costs based on how far you need to go
func calculate_hCost(initial_tile, destination_tile, unit, all_tiles) -> int:
	var MovementStats = unit.UnitMovementStats
	var starting_NodeX = initial_tile.getPosition().x
	var starting_NodeY = initial_tile.getPosition().y
	var total_vertical_cost = 0
	var total_horizontal_cost = 0
	
	# Caculate all the tiles using manhattan distance how far you need to go to get to the target destination
	# North South
	var vertical_movement
	
	if initial_tile.getPosition().y - destination_tile.getPosition().y < 0:
		vertical_movement = -1
		for i in range(destination_tile.getPosition().y, initial_tile.getPosition().y, vertical_movement):
			total_vertical_cost += all_tiles[starting_NodeX][i].movementCost + getPenaltyCost(unit, MovementStats, all_tiles[starting_NodeX][i])
	elif initial_tile.getPosition().y - destination_tile.getPosition().y > 0:
		vertical_movement = 1
		for i in range(initial_tile.getPosition().y, destination_tile.getPosition().y, vertical_movement):
			total_vertical_cost += all_tiles[starting_NodeX][i].movementCost + getPenaltyCost(unit, MovementStats, all_tiles[starting_NodeX][i])
	elif initial_tile.getPosition().y - destination_tile.getPosition().y == 0:
		total_vertical_cost = 0
	
	# West East
	var horizontal_movement
	if initial_tile.getPosition().x - destination_tile.getPosition().x < 0:
		horizontal_movement = -1
		for i in range(destination_tile.getPosition().x, initial_tile.getPosition().x, horizontal_movement):
			total_horizontal_cost += all_tiles[i][starting_NodeY].movementCost + getPenaltyCost(unit, MovementStats, all_tiles[i][starting_NodeY])
	elif initial_tile.getPosition().x - destination_tile.getPosition().x > 0:
		horizontal_movement = 1
		for i in range(initial_tile.getPosition().x, destination_tile.getPosition().x, horizontal_movement):
			total_horizontal_cost += all_tiles[i][starting_NodeY].movementCost + getPenaltyCost(unit, MovementStats, all_tiles[i][starting_NodeY])
	elif initial_tile.getPosition().x - destination_tile.getPosition().x == 0:
		total_horizontal_cost = 0
	
	return total_horizontal_cost + total_vertical_cost

# Create the pathfinding queue needed for the unit to move there
func create_pathfinding_queue(destination_cell, unit) -> void:
	# Get the Queue
	var MovementStatsQueue = unit.UnitMovementStats.movement_queue
	
	# Set next cell
	var next_cell = destination_cell
	var starting_cell = unit.UnitMovementStats.currentTile
	
	# Work backwards until we find the destination cell
	while next_cell != starting_cell:
		MovementStatsQueue.push_front(next_cell)
		next_cell = next_cell.parentTile

# Check if move is valid
func check_if_move_is_valid(destination_cell, unit) -> bool:
	# Cell is not part of the allowed moveset
	if !unit.UnitMovementStats.allowedMovement.has(destination_cell):
		return false
	# Is the cell not occupied by yourself?
	if destination_cell.occupyingUnit != null && destination_cell.occupyingUnit != unit:
		return false
	return true

# Reset grid values
func reset_grid_values():
	# Reset the Grid Values
	for tile_array in battlefield.grid:
		for tile in tile_array:
			#tile.parentTile = null
			tile.isVisited = false

# Reset Parent tiles
func reset_parent_tile_values():
		# Reset the Grid Values
	for tile_array in battlefield.grid:
		for tile in tile_array:
			tile.parentTile = null
			#tile.isVisited = false
