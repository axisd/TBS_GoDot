extends CanvasLayer

# Constants
const MARGIN_LEFT_OF_TOP = 3
const ACTION_SIZE_Y = 10

# Position
const TOP_LEFT = Vector2(12,20)
const TOP_RIGHT = Vector2(181,20)
const OFF_SIDE = Vector2(-100,-100)
var new_menu_position = Vector2(0,0)

# Hand
const HAND_OFF_SET = Vector2(-5,-1.5)

# Signals for changing UI screens
signal selected_back
signal selected_wait

# UI Active
var is_active = false

# For damage preview screen
signal menu_moved

# Keep track of all the actions that we have currently
var current_actions = []
var current_number_action = 0
var current_option_selected = "Wait"

func _ready():
	# Connect to Cursor
	get_parent().get_node("GameCamera/Areas/BottomLeft").body_entered.connect(left_side)
	get_parent().get_node("GameCamera/Areas/BottomRight").body_entered.connect(right_side)
	get_parent().get_node("GameCamera/Areas/TopLeft").body_entered.connect(left_side)
	get_parent().get_node("GameCamera/Areas/TopRight").body_entered.connect(right_side)
	
	BattlefieldInfo.unit_movement_system.connect("action_selector_screen", Callable(self, "start"))

# Start this screen
func start():
	# Show action menu
	$"Action Menu".visible = true
	
	# Get Menu items
	var menu_items = get_menu_items()
	
	# Build Menu
	build_menu(menu_items)
	
	# Start input acceptance
	$Timer.start(0)

# Input for Hand movement
func _input(event):
	if !is_active:
		return
	if Input.is_action_just_pressed("ui_accept"):
		$"Action Menu/Hand Selector/Accept".play(0)
		process_selection()
	elif Input.is_action_just_pressed("ui_cancel"):
		go_back()
	elif Input.is_action_just_pressed("ui_up"):
		movement("up")
	elif Input.is_action_just_pressed("ui_down"):
		movement("down")

func movement(direction):
	match direction:
		"up":
			current_number_action -= 1
			if current_number_action < 0:
				current_number_action = 0
			else:
				$"Action Menu/Hand Selector".position.y -= ACTION_SIZE_Y - 1
				$"Action Menu/Hand Selector/Move".play(0)
			current_option_selected = current_actions[current_number_action]
		"down":
			current_number_action += 1
			if current_number_action > current_actions.size() - 1:
				current_number_action = current_actions.size() - 1
			else:
				$"Action Menu/Hand Selector".position.y += ACTION_SIZE_Y - 1
				$"Action Menu/Hand Selector/Move".play(0)
			current_option_selected = current_actions[current_number_action]


# Build the menu based on how many options there are
func build_menu(menu_items):
	# Move old items
	for child_nodes in $"Action Menu".get_children():
		child_nodes.position = OFF_SIDE
	current_actions.clear()
	
	# Sort the array alphabetically
	# menu_items.sort()
	
	# Put the top Item first
	$"Action Menu/Top".position = new_menu_position
	
#	Get each item and build the menu
	var last_item = $"Action Menu/Top"
	for menu_item in menu_items:
		get_node(str("Action Menu/",menu_item)).position = Vector2($"Action Menu/Top".position.x + MARGIN_LEFT_OF_TOP, last_item.position.y + ACTION_SIZE_Y - 1)
		last_item = get_node(str("Action Menu/",menu_item))
		current_actions.append(menu_item)
	# Move bottom
	$"Action Menu/Bottom".position = Vector2(last_item.position.x, last_item.position.y + ACTION_SIZE_Y - 1) 
	
	# Set the hand cursor to the first item in the list
	$"Action Menu/Hand Selector".position = get_node(str("Action Menu/", current_actions[0])).position + HAND_OFF_SET
	current_option_selected = current_actions[0]
	current_number_action = 0

# Build the menu items
func get_menu_items():
	var menu_items = []
	# Attack items
	if BattlefieldInfo.current_Unit_Selected.UnitInventory.MAX_ATTACK_RANGE > 0:
		# Build item slot
		for weapon in BattlefieldInfo.current_Unit_Selected.UnitInventory.inventory:
			if weapon.is_usable_by_current_unit && (weapon.item_class == Item.ITEM_CLASS.PHYSICAL || weapon.item_class == Item.ITEM_CLASS.MAGIC):
				if weapon.weapon_type != Item.WEAPON_TYPE.HEALING:
					# Check if we can reach that unit
					var queue = []
					#var max_range # Max range
					#var min_range # Min range
					queue.append([weapon.max_range, BattlefieldInfo.current_Unit_Selected.UnitMovementStats.currentTile])
					while !queue.is_empty():
						# Pop first tile
						var check_tile = queue.pop_front()
						
						# Check if the tile has someone If we do, we have an enemy we can attack Exit, we are done
						if check_tile[1].occupyingUnit != null && !check_tile[1].occupyingUnit.UnitMovementStats.is_ally:
							if Calculators.get_distance_between_two_tiles(check_tile[1], BattlefieldInfo.current_Unit_Selected.UnitMovementStats.currentTile) >= weapon.min_range:
								# Add Attack
								if !menu_items.has("Attack"):
									menu_items.append("Attack")
								break;
						
						# Tile was empty 
						for adjTile in check_tile[1].adjCells:
							var next_cost = check_tile[0] - 1
							
							if next_cost >= 0:
								queue.append([next_cost, adjTile])
	
		# Do we have a healing item? -> This can build the array and send this information already off to the healing screen.
	if BattlefieldInfo.current_Unit_Selected.UnitInventory.MAX_HEAL_RANGE > 0:
		# Build item slot
		for weapon in BattlefieldInfo.current_Unit_Selected.UnitInventory.inventory:
			if weapon.item_class == Item.ITEM_CLASS.PHYSICAL || weapon.item_class == Item.ITEM_CLASS.MAGIC:
				if weapon.weapon_type == Item.WEAPON_TYPE.HEALING:
					# Check if we can reach that unit
					var queue = []
					#var max_range # Max range
					#var min_range # Min range
					queue.append([weapon.max_range, BattlefieldInfo.current_Unit_Selected.UnitMovementStats.currentTile])
					while !queue.is_empty():
						# Pop first tile
						var check_tile = queue.pop_front()
						
						# Check if the tile has someone If we do, we have an ally we can heal and reach Exit, we are done
						if check_tile[1].occupyingUnit != null && check_tile[1].occupyingUnit.UnitMovementStats.is_ally && check_tile[1].occupyingUnit != BattlefieldInfo.current_Unit_Selected:
							if Calculators.get_distance_between_two_tiles(check_tile[1], BattlefieldInfo.current_Unit_Selected.UnitMovementStats.currentTile) >= weapon.min_range && check_tile[1].occupyingUnit.UnitStats.current_health < check_tile[1].occupyingUnit.UnitStats.max_health:
								# Add heal option
								menu_items.append("Heal")
								break;
						
						# Tile was empty 
						for adjTile in check_tile[1].adjCells:
							var next_cost = check_tile[0] - 1
							
							if next_cost >= 0:
								queue.append([next_cost, adjTile])
	
	# Are we Eirika?
	if BattlefieldInfo.current_Unit_Selected.UnitStats.name == "Eirika":
		if !menu_items.has("Convoy"):
			menu_items.append("Convoy")
	
	# Item
	if !BattlefieldInfo.current_Unit_Selected.UnitInventory.inventory.is_empty():
		menu_items.append("Item")
	
	# Trade Option | Convoy
	if BattlefieldInfo.current_Unit_Selected.UnitActionStatus.get_current_action() != Unit_Action_Status.DONE:
		for adj_cell in BattlefieldInfo.current_Unit_Selected.UnitMovementStats.currentTile.adjCells:
			if adj_cell.occupyingUnit != null && adj_cell.occupyingUnit.UnitMovementStats.is_ally:
				if !menu_items.has("Trade"):
					menu_items.append("Trade")
				# Check if next to Eirika
				if adj_cell.occupyingUnit.UnitStats.name == "Eirika":
					if !menu_items.has("Convoy"):
						menu_items.append("Convoy")
		
		# Are we on the throne tile
		if BattlefieldInfo.current_Unit_Selected.UnitMovementStats.currentTile.tileName == "Throne" && BattlefieldInfo.victory_text == "Seize":
			menu_items.append("Seize")
	
	# Cell Visit -> Armory/Arena/Village
	if BattlefieldInfo.current_Unit_Selected.UnitMovementStats.currentTile.tileName == "Arena" || \
	   BattlefieldInfo.current_Unit_Selected.UnitMovementStats.currentTile.tileName == "Village Entrance":
		if !menu_items.has("Visit"):
			menu_items.append("Visit")
	
	# Shop option
	if BattlefieldInfo.current_Unit_Selected.UnitMovementStats.currentTile.tileName == "Armory" || \
	   BattlefieldInfo.current_Unit_Selected.UnitMovementStats.currentTile.tileName == "Item Shop":
		if !menu_items.has("Shop"):
			menu_items.append("Shop")
	
	# Always wait
	var current_number_action = 0
	menu_items.append("Wait")
	return menu_items

# Process Selection
func process_selection():
	match current_option_selected:
		"Attack":
			# Go to the other menu
			get_parent().get_node("Weapon Select").start()
			# Turn off
			hide_action_menu()
		"Convoy":
			# Start the convoy screen with current unit selected
			Convoy.get_node("Convoy UI").start_with_unit_selected(BattlefieldInfo.current_Unit_Selected)
			
			# Turn off
			hide_action_menu()
		"Heal":
			get_parent().get_node("Healing Select").start()
			# Turn off
			hide_action_menu()
		"Item":
			get_parent().get_node("Item Screen").start()
			hide_action_menu()
		"Trade":
			get_parent().get_node("Trade Screen").start()
			hide_action_menu()
		"Visit":
			print("From Action Selector: Selected Visit! Go to the visit screen!")
		"Seize":
			print("From Action Selector: Selected Seize! You have won this level.")
		"Shop":
			print("From Action Selector: Going into the shop!")
		"Wait":
			# Turn this off
			hide_action_menu()
			
			# Set unit to done
			BattlefieldInfo.current_Unit_Selected.UnitActionStatus.set_current_action(Unit_Action_Status.DONE)
			BattlefieldInfo.current_Unit_Selected.turn_greyscale_on()
			BattlefieldInfo.current_Unit_Selected.get_node("Animation").current_animation = "Idle"
			emit_signal("selected_wait")
			
			BattlefieldInfo.turn_manager.emit_signal("check_end_turn")
			
# Go back
func go_back():
	if BattlefieldInfo.current_Unit_Selected.UnitActionStatus.get_current_action() == Unit_Action_Status.DONE || BattlefieldInfo.current_Unit_Selected.UnitActionStatus.get_current_action() == Unit_Action_Status.TRADE:
		$"Action Menu/Hand Selector/Invalid".play(0)
		return
	
	# Accept Sound
	$"Action Menu/Hand Selector/Cancel".play(0)
	
	# Move Unit back
	BattlefieldInfo.current_Unit_Selected.position = BattlefieldInfo.previous_position
	Calculators.update_unit_tile_info(BattlefieldInfo.current_Unit_Selected, BattlefieldInfo.grid[BattlefieldInfo.previous_position.x / Cell.CELL_SIZE][BattlefieldInfo.previous_position.y / Cell.CELL_SIZE])
	
	# Move Camera
	get_parent().get_node("GameCamera").position = BattlefieldInfo.previous_camera_position
	
	# Set status and animation
	BattlefieldInfo.current_Unit_Selected.UnitActionStatus.set_current_action(Unit_Action_Status.MOVE)
	BattlefieldInfo.current_Unit_Selected.get_node("Animation").play("Idle")
	
	# Move Cursor
	get_parent().get_node("Cursor").position = BattlefieldInfo.previous_position
	
	# Set Cursor status
	get_parent().get_node("Cursor").enable_standard()
	
	# Hide menu
	hide_action_menu()

# Left
func left_side(body):
	emit_signal("menu_moved", "right")
	new_menu_position = TOP_RIGHT

# Right
func right_side(body):
	emit_signal("menu_moved", "left")
	new_menu_position = TOP_LEFT

# Move everything off and hide it
func hide_action_menu():
	$"Action Menu".visible = false
	
	# Move old items
	for child_nodes in $"Action Menu".get_children():
		child_nodes.position = OFF_SIDE
	
	# Turn off active
	is_active = false

func _on_Timer_timeout():
	# Active Input
	is_active = true
