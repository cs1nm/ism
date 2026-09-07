extends Node

# ===== RESOURCES =====
var coins: int = 0
var wood: int = 0
var stone: int = 0
var gems: int = 0
var ingots: int = 0  # Smelted from stone

# ===== CRAFTED ITEMS =====
var has_axe: bool = false
var axe_level: int = 0  # 0=none, 1=basic, 2=improved
var has_pickaxe: bool = false
var pickaxe_level: int = 0

# ===== PLAYER STATS =====
var max_backpack: int = 10
var move_speed: float = 200.0
var harvest_speed: float = 1.0

var current_backpack: int:
	get:
		return wood + stone + gems

# ===== UPGRADE LEVELS =====
var speed_level: int = 1
var backpack_level: int = 1
var island_level: int = 1

# ===== RECIPES =====
func get_axe_recipe() -> Dictionary:
	if axe_level == 0:
		return {"wood": 8, "stone": 5, "coins": 0}
	elif axe_level == 1:
		return {"wood": 5, "stone": 3, "coins": 50, "ingots": 3}
	return {}

func get_pickaxe_recipe() -> Dictionary:
	if pickaxe_level == 0:
		return {"wood": 5, "stone": 8, "coins": 0}
	elif pickaxe_level == 1:
		return {"wood": 3, "stone": 5, "coins": 50, "ingots": 3}
	return {}

func get_smelt_recipe() -> Dictionary:
	return {"stone": 3, "output": "ingot", "output_amount": 1}

# ===== UPGRADE COSTS =====
func get_speed_upgrade_cost() -> int:
	return 50 * speed_level * speed_level

func get_backpack_upgrade_cost() -> int:
	return 30 * backpack_level * backpack_level

func get_expand_cost() -> int:
	return 200 * island_level * island_level

# ===== CRAFTING FUNCTIONS =====
func can_craft_axe() -> bool:
	var recipe = get_axe_recipe()
	if recipe.is_empty():
		return false
	return (wood >= recipe.get("wood", 0) and 
			stone >= recipe.get("stone", 0) and 
			coins >= recipe.get("coins", 0) and
			ingots >= recipe.get("ingots", 0))

func craft_axe() -> bool:
	if not can_craft_axe():
		return false
	var recipe = get_axe_recipe()
	wood -= recipe.get("wood", 0)
	stone -= recipe.get("stone", 0)
	coins -= recipe.get("coins", 0)
	ingots -= recipe.get("ingots", 0)
	axe_level += 1
	has_axe = true
	notify_resources_changed()
	return true

func can_craft_pickaxe() -> bool:
	var recipe = get_pickaxe_recipe()
	if recipe.is_empty():
		return false
	return (wood >= recipe.get("wood", 0) and 
			stone >= recipe.get("stone", 0) and 
			coins >= recipe.get("coins", 0) and
			ingots >= recipe.get("ingots", 0))

func craft_pickaxe() -> bool:
	if not can_craft_pickaxe():
		return false
	var recipe = get_pickaxe_recipe()
	wood -= recipe.get("wood", 0)
	stone -= recipe.get("stone", 0)
	coins -= recipe.get("coins", 0)
	ingots -= recipe.get("ingots", 0)
	pickaxe_level += 1
	has_pickaxe = true
	notify_resources_changed()
	return true

func can_smelt() -> bool:
	return stone >= 3

func smelt() -> bool:
	if not can_smelt():
		return false
	stone -= 3
	ingots += 1
	notify_resources_changed()
	return true

# ===== HARVEST SPEED MULTIPLIER =====
func get_harvest_multiplier(resource_type: String) -> float:
	var mult = 1.0
	match resource_type:
		"wood":
			if axe_level >= 2:
				mult = 3.0
			elif axe_level >= 1:
				mult = 2.0
		"stone":
			if pickaxe_level >= 2:
				mult = 3.0
			elif pickaxe_level >= 1:
				mult = 2.0
	return mult

# ===== UPGRADE FUNCTIONS =====
func upgrade_speed() -> bool:
	var cost = get_speed_upgrade_cost()
	if coins >= cost:
		coins -= cost
		speed_level += 1
		move_speed += 30.0
		notify_coins_changed()
		return true
	return false

func upgrade_backpack() -> bool:
	var cost = get_backpack_upgrade_cost()
	if coins >= cost:
		coins -= cost
		backpack_level += 1
		max_backpack += 5
		notify_coins_changed()
		return true
	return false

func expand_island() -> bool:
	var cost = get_expand_cost()
	if coins >= cost:
		coins -= cost
		island_level += 1
		notify_coins_changed()
		return true
	return false

# ===== RESOURCE MANAGEMENT =====
func add_resource(resource_type: String, amount: int = 1) -> int:
	var space = max_backpack - current_backpack
	var to_add = mini(amount, space)
	if to_add <= 0:
		return 0
	match resource_type:
		"wood":
			wood += to_add
		"stone":
			stone += to_add
		"gem":
			gems += to_add
	notify_resources_changed()
	return to_add

func sell_all() -> int:
	var earned = 0
	earned += wood * 2
	earned += stone * 3
	earned += gems * 10
	earned += ingots * 15
	coins += earned
	wood = 0
	stone = 0
	gems = 0
	ingots = 0
	notify_coins_changed()
	notify_resources_changed()
	return earned

# ===== SIGNALS =====
signal coins_changed(new_amount: int)
signal resources_changed()
signal upgrades_changed()
signal tools_changed()

func notify_coins_changed():
	coins_changed.emit(coins)

func notify_resources_changed():
	resources_changed.emit()

func notify_upgrades_changed():
	upgrades_changed.emit()

func notify_tools_changed():
	tools_changed.emit()
