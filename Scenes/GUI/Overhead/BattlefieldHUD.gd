# Controls the overhead display when on the battle field
extends CanvasLayer

# Positioning
enum {TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT}
var cursor_quadrant
var previous_quadrant

# Full Bar constant for math
const full_bar_width = 237

func _ready():
	# Connect the cursor movement signal and turning off
	get_parent().get_node("Cursor").connect("cursorMoved", Callable(self, "update_battlefield_ui"))
	get_parent().get_node("Cursor").connect("turn_off_ui", Callable(self, "turn_off_battlefield_ui"))
	get_parent().get_node("Cursor").connect("turn_on_ui", Callable(self, "turn_on_battlefield_ui"))
	
	# Connect cursor to the Area
	get_parent().get_node("GameCamera/Areas/BottomLeft").connect("body_entered", Callable(self, "bottom_left"))
	get_parent().get_node("GameCamera/Areas/BottomRight").connect("body_entered", Callable(self, "bottom_right"))
	get_parent().get_node("GameCamera/Areas/TopLeft").connect("body_entered", Callable(self, "top_left"))
	get_parent().get_node("GameCamera/Areas/TopRight").connect("body_entered", Callable(self, "top_right"))
	
	# Connect to Action selector
	get_parent().get_node("Action Selector Screen").connect("selected_wait", Callable(self, "turn_on_battlefield_ui"))
	
	# Initial Quandrant and previous
	cursor_quadrant = TOP_LEFT
	previous_quadrant = TOP_LEFT
	
	# Set initial text
	set_victory_text()
	
	# UI Easy access
	BattlefieldInfo.battlefield_ui = self

func set_victory_text():
	$"Battlefield HUD/Victory Info/V Name".text = BattlefieldInfo.victory_text

func update_battlefield_ui(cursor_direction, cursor_position):
	# Set Victory Text
	set_victory_text()
	
	# Update Unit Box
	update_unit_box()
	
	# Move Boxes
	move_gui_boxes()
	
	# Update Terrain info tile
	update_terrain_box(cursor_position)

# Update Unit info box
func update_unit_box():
	# Check if there is a unit and display information
	if BattlefieldInfo.current_Unit_Selected != null:
		#print("Printed from BattlefieldHUD:", BattlefieldInfo.current_Unit_Selected) # Set appropriate unit stats here
		$"Battlefield HUD/Unit Info/FadeAnimU".play("Fade") # play the animation for the ui
		$"Battlefield HUD/Unit Info".visible = true
	else:
		$"Battlefield HUD/Unit Info/FadeAnimU".play("FadeOut")

func _on_unit_box_fade():
	$"Battlefield HUD/Unit Info".visible = false

# Update Terrain
func update_terrain_box(cursor_position):
	# Get the cell where the cursor currently is
	var cursor_cell = BattlefieldInfo.grid[cursor_position.x / Cell.CELL_SIZE][cursor_position.y / Cell.CELL_SIZE]
	
	# Set Name of the Unit if not null and set HP stats
	if BattlefieldInfo.current_Unit_Selected != null:
		$"Battlefield HUD/Unit Info/Name".text = BattlefieldInfo.current_Unit_Selected.UnitStats.name
		calculate_health_values()
	
	# Set Tile Name
	$"Battlefield HUD/Terrain Info/T Name".text = cursor_cell.tileName
	
	# Set Stats
	$"Battlefield HUD/Terrain Info/Avd/Avd_Value".text = str(cursor_cell.avoidanceBonus)
	$"Battlefield HUD/Terrain Info/Def/Def_Value".text = str(cursor_cell.defenseBonus)

# Determine which quandrant of the screen the cursor is in
func bottom_left(body) -> void:
	cursor_quadrant = BOTTOM_LEFT
	move_gui_boxes()

func bottom_right(body) -> void:
	cursor_quadrant = BOTTOM_RIGHT
	move_gui_boxes()

func top_left(body) -> void:
	cursor_quadrant = TOP_LEFT
	move_gui_boxes()

func top_right(body) -> void:
	cursor_quadrant = TOP_RIGHT
	move_gui_boxes()

# Moves all the boxes to the correct spot -> Fix box detection
func move_gui_boxes():
	match cursor_quadrant:
		TOP_LEFT:
			# Unit Info Box
			$"Battlefield HUD/Unit Info".position.x = 0 
			$"Battlefield HUD/Unit Info".position.y = 115
			
			# Terrain Box
#			$"Battlefield HUD/Terrain Info/FadeAnimT".play("Fade")
			$"Battlefield HUD/Terrain Info".position.x = 190
			$"Battlefield HUD/Terrain Info".position.y = 120

			# Victory Box
#			$"Battlefield HUD/Victory Info/FadeAnimV".play("Fade")
			$"Battlefield HUD/Victory Info".position.x = 190
			$"Battlefield HUD/Victory Info".position.y = 5

		BOTTOM_LEFT:
			# Unit Info Box
			$"Battlefield HUD/Unit Info".position.x = 0 
			$"Battlefield HUD/Unit Info".position.y = 0

			# Terrain Box
			$"Battlefield HUD/Terrain Info".position.x = 190
			$"Battlefield HUD/Terrain Info".position.y = 120

			# Victory Box
			$"Battlefield HUD/Victory Info".position.x = 190
			$"Battlefield HUD/Victory Info".position.y = 5


		TOP_RIGHT:
			# Unit Info Box
			$"Battlefield HUD/Unit Info".position.x = 0 
			$"Battlefield HUD/Unit Info".position.y = 115

			# Terrain Box
			$"Battlefield HUD/Terrain Info".position.x = 190
			$"Battlefield HUD/Terrain Info".position.y = 120

			# Victory Box
#			$"Battlefield HUD/Victory Info/FadeAnimV".play("Fade")
			$"Battlefield HUD/Victory Info".position.x = 5
			$"Battlefield HUD/Victory Info".position.y = 5

		BOTTOM_RIGHT:
			# Unit Info Box
			$"Battlefield HUD/Unit Info".position.x = 0 
			$"Battlefield HUD/Unit Info".position.y = 115

			# Terrain Box
#			$"Battlefield HUD/Terrain Info/FadeAnimT".play("Fade")
			$"Battlefield HUD/Terrain Info".position.x = 190
			$"Battlefield HUD/Terrain Info".position.y = 5

			# Victory Box
			$"Battlefield HUD/Victory Info".position.x = 5
			$"Battlefield HUD/Victory Info".position.y = 5

# Turn off all UI elements of the battlefield
func turn_off_battlefield_ui():
	$"Battlefield HUD".visible = false
	update_battlefield_ui("up", get_parent().get_node("Cursor").position)
	
	# Update the box for weird glitch when the cursor gets control back
	update_unit_box()

# Turn on all UI elements of the battlefield
func turn_on_battlefield_ui():
	if BattlefieldInfo.turn_manager.turn == Turn_Manager.PLAYER_TURN || BattlefieldInfo.cursor.cursor_state == Cursor.PREP:
		$"Battlefield HUD".visible = true
	update_battlefield_ui("up", get_parent().get_node("Cursor").position)
	# Turn off unit frame
	if BattlefieldInfo.current_Unit_Selected == null:
		$"Battlefield HUD/Unit Info".visible = false

# Calculate Text for Unit 
func calculate_health_values():
	# Set Health Text
	$"Battlefield HUD/Unit Info/Health".text = str(BattlefieldInfo.current_Unit_Selected.UnitStats.current_health, " / ", BattlefieldInfo.current_Unit_Selected.UnitStats.max_health)
	
	# Set Percentage for drawing the box
	$"Battlefield HUD/Unit Info/Full HP".region_rect = Rect2(0, 0, full_bar_width * (float(BattlefieldInfo.current_Unit_Selected.UnitStats.current_health) / float(BattlefieldInfo.current_Unit_Selected.UnitStats.max_health)), 17)
	
	# Set Portrait
	$"Battlefield HUD/Unit Info/Portrait".texture = BattlefieldInfo.current_Unit_Selected.unit_portrait_path
