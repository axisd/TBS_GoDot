extends Node

# Calculates the values needed for combat damage
class_name Combat_System

# Combat variables
const CRITICAL_BONUS = 3

# Double attack
var player_double_attack = false
var enemy_double_attack = false

# Weapon bonuses
var player_weapon_bonus = 0
var enemy_weapon_bonus = 0

# Accuracy Rate
var player_accuracy = 0
var enemy_accuracy = 0

# Critical strike rate
var player_critical_rate = 0
var enemy_critical_rate = 0

# Damage preview for GUI
var player_damage = 0
var enemy_damage = 0

# Actual damage for combat purposes
var player_actual_damage = 0
var enemy_actual_damage = 0

# Effective bonus
var player_effective_bonus = 1
var enemy_effective_bonus = 1

# Miss
var player_missed = false
var enemy_missed = false

func _init():
	pass

func calculate_damage_and_previews():
	# Get Weapon bonuses
	get_weapon_bonus()

# Double Attack
func calculate_double_attack():
	# Check if speed doubles
	# Player
	var player_attack_speed = get_attack_speed(BattlefieldInfo.combat_player_unit)
	var ai_attack_speed = get_attack_speed(BattlefieldInfo.combat_ai_unit)
	
	if player_attack_speed - ai_attack_speed >= 4:
		player_attack_speed = true
		enemy_double_attack = false
	elif ai_attack_speed - player_attack_speed >= 4:
		player_attack_speed = false
		enemy_double_attack = true
	else:
		player_attack_speed = false
		enemy_double_attack = false

# Hit Chance
func calculate_hit_chance():
	var c_player_accuracy = 0
	var c_player_avoidance = 0
	
	var c_ai_accuracy = 0
	var c_ai_avoidance = 0
	
	# Player
	c_player_accuracy = get_accuracy(BattlefieldInfo.combat_player_unit, player_weapon_bonus)
	c_player_avoidance = get_avoidance(BattlefieldInfo.combat_player_unit)
	
	# AI
	c_ai_accuracy = get_accuracy(BattlefieldInfo.combat_ai_unit, enemy_weapon_bonus)
	c_ai_avoidance = get_avoidance(BattlefieldInfo.combat_ai_unit)
	
	# Calculate accuracy
	player_accuracy = c_player_accuracy - c_ai_avoidance
	enemy_accuracy = c_ai_accuracy - c_player_accuracy
	

# Crit Chance
func calculate_crit_chance():
	player_critical_rate = (BattlefieldInfo.combat_player_unit.UnitStats.skill / 2) + BattlefieldInfo.combat_player_unit.UnitInventory.current_item_equipped.crit + BattlefieldInfo.combat_player_unit.UnitStats.bonus_crit - BattlefieldInfo.combat_ai_unit.UnitStats.luck
	enemy_critical_rate = (BattlefieldInfo.combat_ai_unit.UnitStats.skill / 2) + BattlefieldInfo.combat_ai_unit.UnitInventory.current_item_equipped.crit + BattlefieldInfo.combat_ai_unit.UnitStats.bonus_crit - BattlefieldInfo.combat_player_unit.UnitStats.luck
	

# Damage Preview -> Add double attack mode
func calculate_damage():
	# Reset stats first
	reset_stats()
	
	# Get Bonuses
	get_special_ability(BattlefieldInfo.combat_player_unit, BattlefieldInfo.combat_ai_unit)
	
	# Calculate Crit
	calculate_crit_chance()
	
	# Calculate Hit Chance
	calculate_hit_chance()
	
	# Calculate double attack
	calculate_double_attack()
	
	# Calculate Damage
	var player_base_damage = 0
	var player_base_def = 0
	var enemy_base_damage = 0
	var enemy_base_def = 0
	
	# Player
	if BattlefieldInfo.combat_player_unit.UnitInventory.current_item_equipped.item_class == Item.ITEM_CLASS.PHYSICAL:
		player_base_damage = BattlefieldInfo.combat_player_unit.UnitStats.strength
		enemy_base_def = BattlefieldInfo.combat_ai_unit.UnitStats.def
	elif BattlefieldInfo.combat_player_unit.UnitInventory.current_item_equipped.item_class == Item.ITEM_CLASS.MAGIC:
		player_base_damage = BattlefieldInfo.combat_player_unit.UnitStats.magic
		enemy_base_def = BattlefieldInfo.combat_ai_unit.UnitStats.res
	
	player_base_damage += ((BattlefieldInfo.combat_player_unit.UnitInventory.current_item_equipped.might + player_weapon_bonus) * player_effective_bonus)
	enemy_base_def += BattlefieldInfo.combat_ai_unit.UnitMovementStats.currentTile.defenseBonus
	
	# Set GUI
	player_damage = player_base_damage
	
	# Check Crit Chance
	if (crit_occurred(player_critical_rate)):
		print("FROM COMBAT CALC: PLAYER CRIT OCCURED")
		player_base_damage *= 3
		player_actual_damage = player_base_damage - enemy_base_def
		
		if player_actual_damage < 0:
			player_actual_damage = 0
	else:
		# No Crit, check if unit hit or missed
		if (!hit_occured(player_accuracy)):
			player_actual_damage = player_base_damage - enemy_base_def
			
			if player_actual_damage >= 0:
				player_actual_damage = 0
				print("FROM COMBAT CALC: NO DAMAGE DEALT FROM PLAYER")
		else:
			# Player missed
			print("FROM COMBAT CALC: PLAYER MISSED")
			player_missed = true
	
	# Enemy
	if BattlefieldInfo.combat_ai_unit.UnitInventory.current_item_equipped.item_class == Item.ITEM_CLASS.PHYSICAL:
		enemy_base_damage = BattlefieldInfo.combat_ai_unit.UnitStats.strength
		player_base_def = BattlefieldInfo.combat_player_unit.UnitStats.def
	elif BattlefieldInfo.combat_ai_unit.UnitInventory.current_item_equipped.item_class == Item.ITEM_CLASS.MAGIC:
		enemy_base_damage = BattlefieldInfo.combat_ai_unit.UnitStats.magic
		player_base_def = BattlefieldInfo.combat_player_unit.UnitStats.res
	
	enemy_base_damage += ((BattlefieldInfo.combat_ai_unit.UnitInventory.current_item_equipped.might + player_weapon_bonus) * enemy_effective_bonus)
	player_base_def += BattlefieldInfo.combat_player_unit.UnitMovementStats.currentTile.defenseBonus
	
	# Set GUI
	enemy_damage = enemy_base_damage
	
	# Check Crit Chance
	if (crit_occurred(enemy_critical_rate)):
		print("FROM COMBAT CALC: ENEMY CRIT OCCURED")
		enemy_base_damage *= 3
		enemy_actual_damage = enemy_base_damage - player_base_def
		
		if enemy_actual_damage < 0:
			enemy_actual_damage = 0
	else:
		# No Crit, check if unit hit or missed
		if (!hit_occured(enemy_accuracy)):
			enemy_actual_damage = enemy_base_damage - player_base_def
			
			if enemy_actual_damage >= 0:
				enemy_actual_damage = 0
				print("FROM COMBAT CALC: NO DAMAGE DEALT FROM ENEMY")
		else:
			# Player missed
			print("FROM COMBAT CALC: ENEMY MISSED")
			player_missed = true

####################
# Helper Functions #
####################
func get_attack_speed(unit):
	var item_weight_stat = clamp(unit.UnitInventory.current_item_equipped.weight - unit.UnitStats.consti, 0, 10000)
	return unit.UnitStats.speed - item_weight_stat

func get_accuracy(unit, weapon_bonus):
	return unit.UnitInventory.current_item_equipped.hit + (unit.UnitStats.skill * 2) + (unit.UnitStats.luck / 2) + 5 + (weapon_bonus * 15)

func get_avoidance(unit):
	return get_attack_speed(unit) + unit.UnitStats.luck + 5 + unit.UnitMovementStats.currentTile.avoidanceBonus

func get_special_ability(player_unit, ai_unit):
	player_effective_bonus = player_unit.UnitInventory.current_item_equipped.special_ability(player_unit, ai_unit)
	enemy_effective_bonus = ai_unit.UnitInventory.current_item_equipped.special_ability(ai_unit, player_unit)

func crit_occurred(crit_chance):
	if crit_chance >= 100:
		return true
	elif crit_chance <= 0:
		return false
	
	return randi() % 99 + 1 <= crit_chance

func hit_occured(accuracy_chance):
	if accuracy_chance >= 100:
		return true
	elif accuracy_chance <= 0:
		return false
	
	return randi() % 99 + 1 <= accuracy_chance

func reset_stats():
	# Double attack
	player_double_attack = false
	enemy_double_attack = false
	
	# Weapon bonuses
	player_weapon_bonus = 0
	enemy_weapon_bonus = 0
	
	# Accuracy Rate
	player_accuracy = 0
	enemy_accuracy = 0
	
	# Critical strike rate
	player_critical_rate = 0
	enemy_critical_rate = 0
	
	# Damage preview for GUI
	player_damage = 0
	enemy_damage = 0
	
	# Actual damage for combat purposes
	player_actual_damage = 0
	enemy_actual_damage = 0
	
	# Effective bonus
	player_effective_bonus = 1
	enemy_effective_bonus = 1
	
	# Miss
	player_missed = false
	enemy_missed = false

func get_weapon_bonus():
	# Player
	if BattlefieldInfo.combat_player_unit.UnitInventory.current_item_equipped.strong_against == BattlefieldInfo.combat_ai_unit.UnitInventory.current_item_equipped.weak_against:
		player_weapon_bonus = 1
		enemy_weapon_bonus = -1
	elif BattlefieldInfo.combat_ai_unit.UnitInventroy.current_item_equipped.strong_against == BattlefieldInfo.combat_player_unit.UnitInventory.current_item_equipped.weak_against:
		enemy_weapon_bonus = 1
		player_weapon_bonus = -1
	else:
		player_weapon_bonus = 0
		enemy_weapon_bonus = 0