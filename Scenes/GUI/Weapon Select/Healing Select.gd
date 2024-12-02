extends CanvasLayer

# Constants 
const OFF_SET = Vector2(10,10)
const X_OFF_SET = Vector2(6,0)
const OFF_SCREEN = Vector2(-150, -150)
const HAND_POSITION = Vector2(5,18)
const SLOT_Y = Vector2(0,10)

# Input
var is_active = false

# Inventory
var usable_weapons = []

# List
var item_list_menu = []
var current_selected_number = 0
var current_selected_option = null

# Called when this UI comes into play
func start():
	# Get usable items first
	get_all_enemies_available()
	
	# Build menu
	build_item_list()
	
	# Place unit mugshot
	create_mugshot()
	
	# Update item
	update_item_box()
	
	# Start
	turn_on()

# Process input
func _input(event):
	if !is_active:
		return
	if Input.is_action_just_pressed("ui_up"):
		movement("up")
	elif Input.is_action_just_pressed("ui_down"):
		movement("down")
	elif Input.is_action_just_pressed("ui_accept"):
		$"Hand Selector/Accept".play(0)
		process_selection()
	elif Input.is_action_just_pressed("ui_cancel"):
		$"Hand Selector/Cancel".play(0)
		go_back()

# Get enemies available with weapons available
func get_all_enemies_available():
	pass

# Build Item List -> modify later with usable items
func build_item_list():
	# Clear old menu
	item_list_menu.clear()
	
	# Place Top
	$"Weapon Select/Weapon List/Top".position = OFF_SET
	
	var last_position = OFF_SET + X_OFF_SET
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
						if Calculators.get_distance_between_two_tiles(check_tile[1], BattlefieldInfo.current_Unit_Selected.UnitMovementStats.currentTile) >= weapon.min_range:
							# Is the unit already at full HP?
							if check_tile[1].occupyingUnit.UnitStats.current_health < check_tile[1].occupyingUnit.UnitStats.max_health:
								# Create a slot
								var item_slot = preload("res://Scenes/GUI/Weapon Select/Weapon Select Slot.tscn").instantiate() 
								
								# Fill data
								item_slot.start(weapon)
								
								# Place position and add child
								item_slot.position = last_position + SLOT_Y - Vector2(0,1)
								$"Weapon Select/Weapon List".add_child(item_slot)
								
								# New previous position
								last_position = item_slot.position
								
								# Add to array so we can queue free later
								item_list_menu.append(weapon)
								break;
					
					# Tile was empty 
					for adjTile in check_tile[1].adjCells:
						var next_cost = check_tile[0] - 1
						
						if next_cost >= 0:
							queue.append([next_cost, adjTile])
	
	# Add Bottom
	$"Weapon Select/Weapon List/Bottom".position = last_position + SLOT_Y
	
	# Place hand
	$"Hand Selector".position = HAND_POSITION

# Place mugshot
func create_mugshot():
	$"Weapon Select/Unit Mugshot".texture = BattlefieldInfo.current_Unit_Selected.unit_mugshot

# Process movement
func movement(direction):
	match direction:
		"up":
			current_selected_number -= 1
			if current_selected_number < 0:
				current_selected_number = 0
			else:
				$"Hand Selector".position.y -= SLOT_Y.y - 1
				$"Hand Selector/Move".play(0)
			current_selected_option = item_list_menu[current_selected_number]
		"down":
			current_selected_number += 1
			if current_selected_number >item_list_menu.size() - 1:
				current_selected_number = item_list_menu.size() - 1
			else:
				$"Hand Selector".position.y += SLOT_Y.y - 1
				$"Hand Selector/Move".play(0)
			current_selected_option = item_list_menu[current_selected_number]
	update_item_box()
	

# Change the item box window whenever the cursor moves
func update_item_box():
	# Set selected item
	current_selected_option = item_list_menu[current_selected_number]
	set_item_stats(current_selected_option)

# Cancel option
func go_back():
	# Turn off and go back to action selector
	turn_off()
	
	# Go back to action selector
	BattlefieldInfo.unit_movement_system.emit_signal("action_selector_screen")

func set_item_stats(item):
	# Set the stats for the selected item
	$"Weapon Select/Unit Mugshot/Item Stats/Background/Weapon Name".text = item.item_name
	$"Weapon Select/Unit Mugshot/Item Stats/Background/Uses Amount".text = str(item.uses)
	$"Weapon Select/Unit Mugshot/Item Stats/Background/Power Amt".text = str(item.might)
	$"Weapon Select/Unit Mugshot/Item Stats/Background/Crit Amt".text = str(item.crit)
	$"Weapon Select/Unit Mugshot/Item Stats/Background/Hit Amt".text = str(item.hit)
	
	# Set icon
	$"Weapon Select/Unit Mugshot/Item Stats/Background/TextureRect2".texture = item.icon
	
	# Green color
	if BattlefieldInfo.current_Unit_Selected.UnitInventory.current_item_equipped == item:
		$"Weapon Select/Unit Mugshot/Item Stats/Background/anim".play("equipped")
	else:
		$"Weapon Select/Unit Mugshot/Item Stats/Background/anim".stop(true)
		$"Weapon Select/Unit Mugshot/Item Stats/Background/Weapon Name".set("theme_override_colors/font_color", Color(1.0, 1.0, 1.0))

# Go to unit selection
func process_selection():
	# Turn this off
	turn_off()
	
	# Set Current equipped item
	BattlefieldInfo.current_Unit_Selected.UnitInventory.current_item_equipped = current_selected_option
	
	# Go to the Damage preview screen
	get_parent().get_node("Healing Preview").start(current_selected_option)

# On/Off
func turn_on():
	# Activate Visibility
	$"Weapon Select".visible = true
	
	$"Hand Selector".visible = true
	
	# Reset option
	current_selected_number = 0
	
	# Start Input
	$Timer.start(0)

func turn_off():
	for item_slot in get_tree().get_nodes_in_group(GroupNames.ITEM_SLOT_GROUP_NAME):
		item_slot.queue_free()
	
	$"Weapon Select".visible = false
	is_active = false
	
	$"Hand Selector".visible = false
	
	# Reset option
	current_selected_number = 0

func _on_Timer_timeout():
	is_active = true
