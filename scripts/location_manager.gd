extends Node

# Location system for multiple islands

signal location_changed(new_location: String)

var current_location: String = "starter"
var unlocked_locations: Array = ["starter"]

# Location definitions
var locations = {
	"starter": {
		"name": "Starter Island",
		"description": "A safe island with basic resources",
		"ground_tile": "res://assets/sprites/world/ground.png",
		"water_tile": "res://assets/sprites/world/water.png",
		"sand_tile": "res://assets/sprites/world/sand.png",
		"resources": [
			{"type": "tree", "texture": "res://assets/sprites/resources/tree.png", "resource_type": "wood", "hp": 5, "count": 8},
			{"type": "rock", "texture": "res://assets/sprites/resources/rock.png", "resource_type": "stone", "hp": 8, "count": 6},
		],
		"bg_color": Color(0.2, 0.23, 0.27),
	},
	"ice": {
		"name": "Frozen Isle",
		"description": "An icy island with crystals and frozen trees",
		"ground_tile": "res://assets/sprites/world/ice/ground.png",
		"water_tile": "res://assets/sprites/world/water.png",
		"sand_tile": "res://assets/sprites/world/ice/ground.png",
		"resources": [
			{"type": "crystal", "texture": "res://assets/sprites/resources/ice/crystal.png", "resource_type": "gem", "hp": 10, "count": 5},
			{"type": "frozen_tree", "texture": "res://assets/sprites/resources/ice/frozen_tree.png", "resource_type": "wood", "hp": 7, "count": 6},
		],
		"bg_color": Color(0.15, 0.22, 0.30),
		"unlock_cost": 500,
	},
	"volcanic": {
		"name": "Volcanic Isle",
		"description": "A dangerous island with rare ores and lava",
		"ground_tile": "res://assets/sprites/world/volcanic/ground.png",
		"water_tile": "res://assets/sprites/world/water.png",
		"sand_tile": "res://assets/sprites/world/volcanic/ground.png",
		"resources": [
			{"type": "obsidian", "texture": "res://assets/sprites/resources/volcanic/obsidian.png", "resource_type": "stone", "hp": 12, "count": 5},
			{"type": "ember_ore", "texture": "res://assets/sprites/resources/volcanic/ember_ore.png", "resource_type": "gem", "hp": 15, "count": 4},
		],
		"bg_color": Color(0.25, 0.15, 0.12),
		"unlock_cost": 1000,
	},
	"forest": {
		"name": "Enchanted Forest",
		"description": "A lush island with mushrooms and berries",
		"ground_tile": "res://assets/sprites/world/forest/ground.png",
		"water_tile": "res://assets/sprites/world/water.png",
		"sand_tile": "res://assets/sprites/world/forest/ground.png",
		"resources": [
			{"type": "giant_mushroom", "texture": "res://assets/sprites/resources/forest/giant_mushroom.png", "resource_type": "wood", "hp": 6, "count": 7},
			{"type": "berry_bush", "texture": "res://assets/sprites/resources/forest/berry_bush.png", "resource_type": "stone", "hp": 4, "count": 8},
		],
		"bg_color": Color(0.12, 0.20, 0.15),
		"unlock_cost": 750,
	},
}

func get_current_location_data() -> Dictionary:
	return locations[current_location]

func can_unlock(location_id: String) -> bool:
	if location_id in unlocked_locations:
		return false
	if not location_id in locations:
		return false
	var cost = locations[location_id].get("unlock_cost", 0)
	return GameData.coins >= cost

func unlock_location(location_id: String) -> bool:
	if not can_unlock(location_id):
		return false
	var cost = locations[location_id].get("unlock_cost", 0)
	GameData.coins -= cost
	unlocked_locations.append(location_id)
	GameData.notify_coins_changed()
	return true

func travel_to(location_id: String) -> bool:
	if not location_id in unlocked_locations:
		return false
	current_location = location_id
	location_changed.emit(location_id)
	return true
