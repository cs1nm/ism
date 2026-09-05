extends Node

# ===== PLAYER STATS =====
var coins: int = 0
var wood: int = 0
var stone: int = 0
var gems: int = 0

var max_backpack: int = 10
var move_speed: float = 200.0
var harvest_speed: float = 1.0  # multiplier

var current_backpack: int:
	get:
		return wood + stone + gems

# ===== UPGRADE COSTS =====
var speed_level: int = 1
var backpack_level: int = 1
var island_level: int = 1

func get_speed_upgrade_cost() -> int:
	return 50 * speed_level * speed_level

func get_backpack_upgrade_cost() -> int:
	return 30 * backpack_level * backpack_level

func get_expand_cost() -> int:
	return 200 * island_level * island_level

# ===== UPGRADE FUNCTIONS =====
func upgrade_speed() -> bool:
	var cost = get_speed_upgrade_cost()
	if coins >= cost:
		coins -= cost
		speed_level += 1
		move_speed += 30.0
		return true
	return false

func upgrade_backpack() -> bool:
	var cost = get_backpack_upgrade_cost()
	if coins >= cost:
		coins -= cost
		backpack_level += 1
		max_backpack += 5
		return true
	return false

func expand_island() -> bool:
	var cost = get_expand_cost()
	if coins >= cost:
		coins -= cost
		island_level += 1
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
	return to_add

func sell_all() -> int:
	var earned = 0
	earned += wood * 2
	earned += stone * 3
	earned += gems * 10
	coins += earned
	wood = 0
	stone = 0
	gems = 0
	return earned

# ===== SIGNALS =====
signal coins_changed(new_amount: int)
signal resources_changed()
signal upgrades_changed()

func notify_coins_changed():
	coins_changed.emit(coins)

func notify_resources_changed():
	resources_changed.emit()

func notify_upgrades_changed():
	upgrades_changed.emit()
