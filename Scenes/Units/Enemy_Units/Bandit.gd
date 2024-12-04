extends Battlefield_Unit

# Called when the node enters the scene tree for the first time.
func _ready():
	$Animation.current_animation = "Idle"
	UnitMovementStats.is_ally = false
	
	# Portrait
	#unit_portrait_path = preload("res://assets/units/enemyPortrait/normalSoldierPortrait.png")
	unit_portrait_path = preload("res://assets/units/bandit/bandit mugshot.png")
	
	# Mug shot
	unit_mugshot = preload("res://assets/units/bandit/bandit mugshot.png")
	
	# Add axe'
	UnitInventory.usable_weapons.append(Item.WEAPON_TYPE.AXE)
	var axe = preload("res://Scenes/Items/Axes/Iron Axe.tscn").instantiate()
	UnitInventory.add_item(axe)
	
	# Combat sprite
	combat_node = preload("res://Scenes/Units/Enemy_Units/Bandit Combat.tscn")
