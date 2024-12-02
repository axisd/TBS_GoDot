extends RefCounted

class_name ALL_ITEMS_REF

# Dictionary container all the items with their position
# Default items
const all_items : Dictionary = {
	"Iron Sword" : "res://Scenes/Items/Swords/Iron Sword.tscn",
	"Iron Bow" : "res://Scenes/Items/Bows/Iron Bow.tscn",
	"Iron Axe" : "res://Scenes/Items/Axes/Iron Axe.tscn",
	"Silver Lance": "res://Scenes/Items/Lance/Silver Lance.tscn",
	"Iron Lance": "res://Scenes/Items/Lance/Iron Lance.tscn",
	"Fire Tome" : "res://Scenes/Items/Tomes/Fire.tscn",
	"Heal Staff" : "res://Scenes/Items/Staves/Heal.tscn",
	"Flux Tome" : "res://Scenes/Items/Tomes/Flux.tscn",
	"Killing Edge" : "res://Scenes/Items/Swords/Killing Edge.tscn"
}

var cur_items : Dictionary

# Add item
func add_item(item_id, item):
	# Do not allow duplicates
	if !cur_items.has(item_id):
		cur_items[item_id] = item
	else:
		print("Error Item Ref: Item already exists.")

# Remove item
func remove_item(item_id):
	if cur_items.has(item_id):
		cur_items.erase(item_id)
	else:
		print("Error Item Ref: No such item exists.")

# Get item
func get_item(item_id):
	if cur_items.has(item_id):
		return cur_items[item_id]
	else:
		print("Error Item Ref: No such item exists.")

# Create an item
func create_item(item_id):
	var item = load(item_id)
	var new_item = item.instantiate()
	
	return new_item
