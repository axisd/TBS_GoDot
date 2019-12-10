extends Battlefield_Unit

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set these later when the level loads
	UnitMovementStats.movementSteps = 8
	UnitStats.class_bonus_b = 60
	$Animation.current_animation = "Idle"
	
	# Unit portrait
	#unit_portrait_path = preload("res://assets/units/cavalier/sethPortrait.png")
	unit_portrait_path = preload("res://assets/units/cavalier/seth mugshot.png")
	
	# Weapon Select Portrait
	unit_mugshot = preload("res://assets/units/cavalier/seth mugshot.png")
	
	# Add Steel sword
	UnitInventory.add_item(preload("res://Scenes/Items/Lance/Silver Lance.tscn").instance())
	UnitInventory.add_item(preload("res://Scenes/Items/Swords/Steel Sword.tscn").instance())
	UnitInventory.add_item(preload("res://Scenes/Items/Lance/Iron Lance.tscn").instance())
	
	# River penalty test
	UnitMovementStats.riverPenalty = 3
	
	# Death Quote
	death_sentence = []
	death_sentence.append("Seth:\n\nMy lady... Eirika... I wasn't strong enough....")
	
	combat_node = preload("res://Scenes/Units/Player_Units/AllyUnits/Seth/Seth Combat.tscn")