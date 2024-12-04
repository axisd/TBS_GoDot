extends Node2D

# Map information
@export var map_height: int # cell size
@export var map_width: int # cell size
var all_allies_location = {} # Holds all ally info
var all_enemies_location = {} # holds all enemy info
var grid = [] # Holds all cell data
var cell = preload("res://Scenes/GUI/Cell/Cell.tscn")

# Map information has been loaded
signal mapInformationLoaded

# Called when the node enters the scene tree for the first time.
func _ready():
	# Current Level set
	BattlefieldInfo.current_level = self
	
	# Clear allies movement stats
	for ally in BattlefieldInfo.ally_units.values():
		ally.UnitMovementStats.clear_arrays()
	
	# Set music volume
	BattlefieldInfo.music_player.get_node("AllyLevel").volume_db = 0
	
	# Set Map height
	map_height = self.get_meta("height")
	map_width = self.get_meta("width")
	
	# Set Map victory condition
	BattlefieldInfo.victory_text = self.get_meta("Victory_Condition")
	
	# Start 2D Array
	for i in map_width:
		grid.append([])
		for j in map_height:
			grid[i].append(0)
	
	# Cell information
	# [height, type, visible, width, Avd, Def, MovementCost, TileType] -> Tile String Names
	var cellInfoLayer = $"CellInfo"
	for cellInfo in cellInfoLayer.get_children():
		var map_cell_info = cell.instantiate()
		map_cell_info.init(Vector2(cellInfo.position.x / Cell.CELL_SIZE, cellInfo.position.y / Cell.CELL_SIZE), \
		cellInfo.get_meta("Avd"), cellInfo.get_meta("Def"), cellInfo.get_meta("MovementCost"), cellInfo.get_meta(("TileType")))
		map_cell_info.set_name("map_cell")
		add_child(map_cell_info)
		grid	[cellInfo.position.x / Cell.CELL_SIZE][cellInfo.position.y / Cell.CELL_SIZE] = map_cell_info
		
	# Set Adj Cells
	for cellArray in grid:
		for cell in cellArray:
			# Left
			if cell.getPosition().x - 1 >= 0:
				cell.adjCells.append(grid[cell.getPosition().x - 1][cell.getPosition().y])
			# Right
			if cell.getPosition().x + 1 < map_width:
				cell.adjCells.append(grid[cell.getPosition().x + 1][cell.getPosition().y])
			# Up
			if cell.getPosition().y - 1 >= 0:
				var cellToAdd = grid[cell.getPosition().x][cell.getPosition().y - 1]
				cell.adjCells.append(cellToAdd)
			# Down
			if cell.getPosition().y + 1 < map_height:
				cell.adjCells.append(grid[cell.getPosition().x][cell.getPosition().y + 1])
	
	# Load Units Information
	all_allies_location.clear()
	all_enemies_location.clear()
	var allyInfoLayer = $"Allies"
	var enemyInfoLayer = $"Enemies"
	
	# This should create all the player units -> For now, this will just move the one player unit that I have to the correct location
	# All Strings available
	#[height, type, visible, width, BonusCrit, BonusDodge, BonusHit, Class, 
#	Consti, Defense, Health, Luck, Magic, MaxHealth, Move, Name, Res, Skill, 
#	Speed, Str, Weapon, buildingPenalty, constiChance, defChance, defaultPenalty, forestPenalty, 
#	fortressPenalty, hillPenalty, isAlly, luckChance, magicChance, maxHPChance, mountainPenalty, 
#	resChance, riverPenalty, seaPenalty, skillChance, speedChance, strChance]
	
	for allyCellInfo in allyInfoLayer.get_children():
		# Do we already have this ally?
		var ally_name = allyCellInfo.get_meta("Identifier")
		
		if BattlefieldInfo.ally_units.has(ally_name):
			BattlefieldInfo.ally_units[ally_name].position.x = allyCellInfo.position.x
			BattlefieldInfo.ally_units[ally_name].position.y = allyCellInfo.position.y
			BattlefieldInfo.ally_units[ally_name].visible = false
			BattlefieldInfo.ally_units[ally_name].modulate = Color(1,1,1,1)
			
			# Grid info
			BattlefieldInfo.ally_units[ally_name].UnitMovementStats.currentTile = grid[BattlefieldInfo.ally_units[ally_name].position.x / Cell.CELL_SIZE][BattlefieldInfo.ally_units[ally_name].position.y / Cell.CELL_SIZE]
			grid[BattlefieldInfo.ally_units[ally_name].position.x / Cell.CELL_SIZE][BattlefieldInfo.ally_units[ally_name].position.y / Cell.CELL_SIZE].occupyingUnit = BattlefieldInfo.ally_units[ally_name]
		else:
			var path = str("res://Scenes/Units/Player_Units/AllyUnits/", allyCellInfo.get_meta("InstanceName"),"/",allyCellInfo.get_meta("InstanceName"),".tscn")
			var new_ally = load(path).instantiate()
			new_ally.visible = false
			BattlefieldInfo.y_sort_player_party.add_child(new_ally)
			
			# Set Stats and position
			new_ally.position.x = allyCellInfo.position.x
			new_ally.position.y = allyCellInfo.position.y
			new_ally.UnitStats.name = allyCellInfo.get_meta("Name")
			new_ally.UnitStats.strength = allyCellInfo.get_meta("Str")
			new_ally.UnitStats.skill = allyCellInfo.get_meta("Skill")
			new_ally.UnitStats.speed = allyCellInfo.get_meta("Speed")
			new_ally.UnitStats.magic = allyCellInfo.get_meta("Magic")
			new_ally.UnitStats.luck = allyCellInfo.get_meta("Luck")
			new_ally.UnitStats.def = allyCellInfo.get_meta("Defense")
			new_ally.UnitStats.res = allyCellInfo.get_meta("Res")
			new_ally.UnitStats.consti = allyCellInfo.get_meta("Consti")
			new_ally.UnitStats.bonus_crit = allyCellInfo.get_meta("BonusCrit")
			new_ally.UnitStats.bonus_dodge = allyCellInfo.get_meta("BonusDodge")
			new_ally.UnitStats.bonus_hit = allyCellInfo.get_meta("BonusHit")
			new_ally.UnitStats.level = allyCellInfo.get_meta("Level")
			new_ally.UnitStats.class_type = allyCellInfo.get_meta("Class")
			new_ally.UnitStats.current_health = allyCellInfo.get_meta("Health")
			new_ally.UnitStats.max_health = allyCellInfo.get_meta("MaxHealth")
	
			# Movement
			new_ally.UnitMovementStats.movementSteps = allyCellInfo.get_meta("Move")
			new_ally.UnitMovementStats.defaultPenalty = allyCellInfo.get_meta("defaultPenalty")
			new_ally.UnitMovementStats.forestPenalty = allyCellInfo.get_meta("forestPenalty")
			new_ally.UnitMovementStats.fortressPenalty = allyCellInfo.get_meta("fortressPenalty")
			new_ally.UnitMovementStats.hillPenalty = allyCellInfo.get_meta("hillPenalty")
			new_ally.UnitMovementStats.riverPenalty = allyCellInfo.get_meta("riverPenalty")
			new_ally.UnitMovementStats.seaPenalty = allyCellInfo.get_meta("seaPenalty")
			new_ally.UnitMovementStats.mountainPenalty = allyCellInfo.get_meta("mountainPenalty")
			
			# Stat upgrades
			new_ally.UnitStats.str_chance = allyCellInfo.get_meta("strChance")
			new_ally.UnitStats.skill_chance = allyCellInfo.get_meta("skillChance")
			new_ally.UnitStats.speed_chance = allyCellInfo.get_meta("speedChance")
			new_ally.UnitStats.magic_chance = allyCellInfo.get_meta("magicChance")
			new_ally.UnitStats.luck_chance = allyCellInfo.get_meta("luckChance")
			new_ally.UnitStats.def_chance = allyCellInfo.get_meta("defChance")
			new_ally.UnitStats.res_chance = allyCellInfo.get_meta("resChance")
			new_ally.UnitStats.consti_chance = allyCellInfo.get_meta("constiChance")
			new_ally.UnitStats.max_health_chance = allyCellInfo.get_meta("maxHPChance")
			
			# XP
			new_ally.UnitStats.class_power = allyCellInfo.get_meta("ClassPower")
			new_ally.UnitStats.class_bonus_a = allyCellInfo.get_meta("ClassBonusA")
			new_ally.UnitStats.class_bonus_b = allyCellInfo.get_meta("ClassBonusB")
			new_ally.UnitStats.boss_bonus = allyCellInfo.get_meta("BossBonus")
			new_ally.UnitStats.thief_bonus = allyCellInfo.get_meta("ThiefBonus")
			
			# ID
			new_ally.UnitStats.identifier = allyCellInfo.get_meta("Identifier")
			
			# Set Battlefield Info
			BattlefieldInfo.ally_units[new_ally.UnitStats.identifier] = new_ally
			new_ally.UnitMovementStats.is_ally = true
			new_ally.UnitMovementStats.currentTile = grid[new_ally.position.x / Cell.CELL_SIZE][new_ally.position.y / Cell.CELL_SIZE]
			grid[new_ally.position.x / Cell.CELL_SIZE][new_ally.position.y / Cell.CELL_SIZE].occupyingUnit = new_ally
	
	# Set Eirika
	BattlefieldInfo.Eirika = BattlefieldInfo.ally_units["Eirika"]
	
	# Set HP Status back to max
	for ally_unit_to_heal in BattlefieldInfo.ally_units.values():
		ally_unit_to_heal.UnitStats.current_health = ally_unit_to_heal.UnitStats.max_health
	
	
	# Create Enemy Units
	for enemy in enemyInfoLayer.get_children():
		var path = str("res://Scenes/Units/Enemy_Units/", enemy.get_meta("InstanceName"),".tscn")
		var newEnemy = load(path).instantiate()
		
		# Set AI Type
		var patrol_cell_a
		var patrol_cell_b
		if enemy.has_meta("A_Tile_X"):
			patrol_cell_a = grid[enemy.get_meta("A_Tile_X")][enemy.get_meta("A_Tile_Y")]
			patrol_cell_b = grid[enemy.get_meta("B_Tile_X")][enemy.get_meta("B_Tile_Y")]
		newEnemy.get_node("AI").set_ai(enemy.get_meta("aiType"), patrol_cell_a, patrol_cell_b) 
		$Node2D.add_child(newEnemy)
		
		# Set Stats
		newEnemy.position = Vector2(enemy.position.x, enemy.position.y)
		newEnemy.UnitStats.name = enemy.get_meta("Name")
		newEnemy.UnitStats.strength = enemy.get_meta("Str")
		newEnemy.UnitStats.skill = enemy.get_meta("Skill")
		newEnemy.UnitStats.speed = enemy.get_meta("Speed")
		newEnemy.UnitStats.magic = enemy.get_meta("Magic")
		newEnemy.UnitStats.luck = enemy.get_meta("Luck")
		newEnemy.UnitStats.def = enemy.get_meta("Defense")
		newEnemy.UnitStats.res = enemy.get_meta("Res")
		newEnemy.UnitStats.consti = enemy.get_meta("Consti")
		newEnemy.UnitStats.bonus_crit = enemy.get_meta("BonusCrit")
		newEnemy.UnitStats.bonus_dodge = enemy.get_meta("BonusDodge")
		newEnemy.UnitStats.bonus_hit = enemy.get_meta("BonusHit")
		newEnemy.UnitStats.level = enemy.get_meta("Level")
		newEnemy.UnitStats.class_type = enemy.get_meta("Class")
		newEnemy.UnitStats.current_health = enemy.get_meta("Health")
		newEnemy.UnitStats.max_health = enemy.get_meta("MaxHealth")
		
		# Movement stats
		newEnemy.UnitMovementStats.movementSteps = enemy.get_meta("Move")
		
		# XP Stats
		newEnemy.UnitStats.class_power = enemy.get_meta("ClassPower")
		newEnemy.UnitStats.class_bonus_a = enemy.get_meta("ClassBonusA")
		newEnemy.UnitStats.class_bonus_b = enemy.get_meta("ClassBonusB")
		newEnemy.UnitStats.boss_bonus = enemy.get_meta("BossBonus")
		newEnemy.UnitStats.thief_bonus = enemy.get_meta("ThiefBonus")
		
		# Identifier
		newEnemy.UnitStats.identifier = enemy.get_meta("Identifier")
		
		# Set Battlefield Info
		newEnemy.UnitMovementStats.is_ally = false
		newEnemy.UnitMovementStats.currentTile = grid[newEnemy.position.x / Cell.CELL_SIZE][newEnemy.position.y / Cell.CELL_SIZE]
		grid[newEnemy.position.x / Cell.CELL_SIZE][newEnemy.position.y / Cell.CELL_SIZE].occupyingUnit = newEnemy
		all_enemies_location[enemy.get_meta("Identifier")] = newEnemy
	
	# Spawn points
	for spawn_point in $SpawnPoints.get_children():
		var spawn_point_cell = cell.instantiate()
		spawn_point_cell.init(Vector2(spawn_point.position.x / Cell.CELL_SIZE, spawn_point.position.y / Cell.CELL_SIZE), \
		0, 0, 100, "Plains")
		spawn_point_cell.set_name("spawn_point_cell")
		# grid[cellInfo.position.x / Cell.CELL_SIZE][cellInfo.position.y / Cell.CELL_SIZE] = map_cell_info
		
		# Add Adj Tile since it's off map
		var x_adj_pos: int = spawn_point.get_meta("adj_tile_x") / Cell.CELL_SIZE
		var y_adj_pos: int = spawn_point.get_meta("adj_tile_y") / Cell.CELL_SIZE
		spawn_point_cell.adjCells.append(grid[x_adj_pos][y_adj_pos])
		BattlefieldInfo.spawn_points.append(spawn_point_cell)
		add_child(spawn_point_cell)
	
	$SpawnPoints.free()
	$CellInfo.free()
	$Allies.free()
	$Enemies.free()
	$"temp Ally".free()
	$"Temp enemy".free()
	
	# Send cell and grid information to the battlefield main so it is easily accessible
	BattlefieldInfo.grid = self.grid
	BattlefieldInfo.map_height = self.map_height
	BattlefieldInfo.map_width = self.map_width
	BattlefieldInfo.enemy_units = self.all_enemies_location
	
	# Load the information for the map into the camera
	BattlefieldInfo.main_game_camera._on_Level_mapInformationLoaded()
