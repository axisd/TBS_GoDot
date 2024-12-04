extends Battlefield_Unit

func _ready():
	# Load base class variable
	super()
	
	# Initial Animation
	$Animation.current_animation = "Idle"
	
	# Set this when the level loads but for now, this is just a test to simply things
	UnitStats.name = "Natasha"
	
	# Unit Portrait
	#unit_portrait_path = preload("res://assets/units/cleric/natasha portrait.png")
	unit_portrait_path = preload("res://assets/units/cleric/natasha mugshot.png")
	
	# Unit Mugshot
	unit_mugshot = preload("res://assets/units/cleric/natasha mugshot.png")
	
	# Allowed weapon usage
	UnitInventory.usable_weapons.append(Item.WEAPON_TYPE.HEALING)
	
	# Add Healing Staff
	UnitInventory.add_item(preload("res://Scenes/Items/Staves/Heal.tscn").instantiate())
	
	# Set combat node
	combat_node = preload("res://Scenes/Units/Player_Units/AllyUnits/Natasha/Natasha Combat.tscn")
	
	# Death sentence
	death_sentence = []
	death_sentence.append("Natasha:\n\nAhh...forgive me... Lady Eirika...")
