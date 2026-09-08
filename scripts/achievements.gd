extends Node

# Achievement system

signal achievement_unlocked(achievement_id: String)
signal achievement_progress(achievement_id: String, current: int, target: int)

# Achievement definitions
var achievements = {
	# Crafting
	"first_axe": {
		"name": "First Tool",
		"description": "Craft your first axe",
		"icon": "🪓",
		"condition": "axe_level >= 1",
		"unlocked": false,
	},
	"first_pickaxe": {
		"name": "Mining Time",
		"description": "Craft your first pickaxe",
		"icon": "⛏️",
		"condition": "pickaxe_level >= 1",
		"unlocked": false,
	},
	"first_ingot": {
		"name": "Metal Worker",
		"description": "Smelt your first ingot",
		"icon": "🔩",
		"condition": "ingots >= 1",
		"unlocked": false,
	},
	"max_tools": {
		"name": "Master Craftsman",
		"description": "Upgrade both tools to max level",
		"icon": "🔨",
		"condition": "axe_level >= 2 and pickaxe_level >= 2",
		"unlocked": false,
	},
	
	# Combat
	"first_kill": {
		"name": "First Blood",
		"description": "Defeat your first enemy",
		"icon": "⚔️",
		"condition": "enemies_killed >= 1",
		"unlocked": false,
	},
	"slayer_10": {
		"name": "Monster Slayer",
		"description": "Defeat 10 enemies",
		"icon": "🗡️",
		"condition": "enemies_killed >= 10",
		"unlocked": false,
	},
	"slayer_50": {
		"name": "Elite Hunter",
		"description": "Defeat 50 enemies",
		"icon": "⚔️",
		"condition": "enemies_killed >= 50",
		"unlocked": false,
	},
	"slayer_100": {
		"name": "Legendary Warrior",
		"description": "Defeat 100 enemies",
		"icon": "👑",
		"condition": "enemies_killed >= 100",
		"unlocked": false,
	},
	
	# Resources
	"wood_100": {
		"name": "Lumberjack",
		"description": "Collect 100 wood total",
		"icon": "🌲",
		"condition": "total_wood >= 100",
		"unlocked": false,
	},
	"stone_100": {
		"name": "Miner",
		"description": "Collect 100 stone total",
		"icon": "⛰️",
		"condition": "total_stone >= 100",
		"unlocked": false,
	},
	"gems_50": {
		"name": "Gem Collector",
		"description": "Collect 50 gems total",
		"icon": "💎",
		"condition": "total_gems >= 50",
		"unlocked": false,
	},
	
	# Wealth
	"coins_100": {
		"name": "Getting Rich",
		"description": "Have 100 coins at once",
		"icon": "💰",
		"condition": "coins >= 100",
		"unlocked": false,
	},
	"coins_1000": {
		"name": "Wealthy",
		"description": "Have 1000 coins at once",
		"icon": "💎",
		"condition": "coins >= 1000",
		"unlocked": false,
	},
	"coins_5000": {
		"name": "Tycoon",
		"description": "Have 5000 coins at once",
		"icon": "👑",
		"condition": "coins >= 5000",
		"unlocked": false,
	},
	
	# Exploration
	"unlock_ice": {
		"name": "Frozen Explorer",
		"description": "Unlock the Frozen Isle",
		"icon": "❄️",
		"condition": "unlocked_locations has 'ice'",
		"unlocked": false,
	},
	"unlock_volcanic": {
		"name": "Volcanic Explorer",
		"description": "Unlock the Volcanic Isle",
		"icon": "🌋",
		"condition": "unlocked_locations has 'volcanic'",
		"unlocked": false,
	},
	"unlock_forest": {
		"name": "Forest Explorer",
		"description": "Unlock the Enchanted Forest",
		"icon": "🌿",
		"condition": "unlocked_locations has 'forest'",
		"unlocked": false,
	},
	"unlock_all": {
		"name": "World Traveler",
		"description": "Unlock all locations",
		"icon": "🗺️",
		"condition": "unlocked_locations.size() >= 4",
		"unlocked": false,
	},
	
	# Upgrades
	"max_speed": {
		"name": "Speed Demon",
		"description": "Max out speed upgrades",
		"icon": "⚡",
		"condition": "speed_level >= 5",
		"unlocked": false,
	},
	"max_backpack": {
		"name": "Pack Mule",
		"description": "Max out backpack upgrades",
		"icon": "🎒",
		"condition": "backpack_level >= 5",
		"unlocked": false,
	},
	"max_island": {
		"name": "Island Expansion",
		"description": "Max out island expansions",
		"icon": "🏝️",
		"condition": "island_level >= 5",
		"unlocked": false,
	},
	
	# Ads
	"watch_ad_1": {
		"name": "Supporter",
		"description": "Watch your first rewarded ad",
		"icon": "🎬",
		"condition": "ads_watched >= 1",
		"unlocked": false,
	},
	"watch_ad_10": {
		"name": "Ad Enthusiast",
		"description": "Watch 10 rewarded ads",
		"icon": "📺",
		"condition": "ads_watched >= 10",
		"unlocked": false,
	},
}

# Progress tracking
var stats = {
	"enemies_killed": 0,
	"total_wood": 0,
	"total_stone": 0,
	"total_gems": 0,
	"ads_watched": 0,
}

func _ready():
	# Connect to game events
	GameData.coins_changed.connect(_check_achievements)
	GameData.resources_changed.connect(_check_achievements)
	GameData.upgrades_changed.connect(_check_achievements)
	GameData.tools_changed.connect(_check_achievements)
	LocationManager.location_changed.connect(_check_achievements)
	
	# Connect to YandexSDK rewards
	YandexSDK.reward_earned.connect(_on_reward_earned)

func _check_achievements():
	for achievement_id in achievements:
		var ach = achievements[achievement_id]
		if ach.unlocked:
			continue
		
		if _evaluate_condition(ach.condition):
			_unlock_achievement(achievement_id)

func _evaluate_condition(condition: String) -> bool:
	# Parse and evaluate condition
	var expr = Expression.new()
	var error = expr.parse(condition, [
		"axe_level", "pickaxe_level", "ingots",
		"enemies_killed", "total_wood", "total_stone", "total_gems",
		"coins", "speed_level", "backpack_level", "island_level",
		"unlocked_locations", "ads_watched"
	])
	
	if error != OK:
		print("[Achievements] Parse error: ", condition)
		return false
	
	var result = expr.execute([
		GameData.axe_level, GameData.pickaxe_level, GameData.ingots,
		stats.enemies_killed, stats.total_wood, stats.total_stone, stats.total_gems,
		GameData.coins, GameData.speed_level, GameData.backpack_level, GameData.island_level,
		LocationManager.unlocked_locations, stats.ads_watched
	])
	
	return result == true

func _unlock_achievement(achievement_id: String):
	var ach = achievements[achievement_id]
	ach.unlocked = true
	
	print("[Achievements] Unlocked: ", ach.name)
	achievement_unlocked.emit(achievement_id)
	SoundManager.play_sound("achievement")
	
	# Show notification
	_show_achievement_notification(ach)
	
	# Submit to Yandex SDK
	if YandexSDK.is_web:
		YandexSDK.submit_score("achievements", _count_unlocked())

func _show_achievement_notification(ach: Dictionary):
	# Create floating notification
	var notification = PanelContainer.new()
	notification.name = "AchievementNotification"
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.15, 0.3, 0.95)
	style.border_color = Color(0.6, 0.4, 0.8, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	notification.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	notification.add_child(vbox)
	
	var title = Label.new()
	title.text = "🏆 Achievement Unlocked!"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0))
	vbox.add_child(title)
	
	var name_label = Label.new()
	name_label.text = "%s %s" % [ach.icon, ach.name]
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = ach.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_label)
	
	# Position and animate
	notification.position = Vector2(20, 150)
	notification.modulate.a = 0.0
	get_tree().root.add_child(notification)
	
	var tween = notification.create_tween()
	tween.tween_property(notification, "modulate:a", 1.0, 0.3)
	tween.tween_interval(3.0)
	tween.tween_property(notification, "modulate:a", 0.0, 0.5)
	tween.tween_callback(notification.queue_free)

func _on_reward_earned(reward_type: String, reward_value: String):
	stats.ads_watched += 1
	_check_achievements()

# Called when enemy is killed
func on_enemy_killed():
	stats.enemies_killed += 1
	_check_achievements()

# Called when resource is collected
func on_resource_collected(type: String, amount: int):
	match type:
		"wood":
			stats.total_wood += amount
		"stone":
			stats.total_stone += amount
		"gem":
			stats.total_gems += amount
	_check_achievements()

func _count_unlocked() -> int:
	var count = 0
	for ach_id in achievements:
		if achievements[ach_id].unlocked:
			count += 1
	return count

# Save/load achievements
func save_achievements() -> Dictionary:
	var save_data = {}
	for ach_id in achievements:
		save_data[ach_id] = achievements[ach_id].unlocked
	return {"achievements": save_data, "stats": stats}

func load_achievements(data: Dictionary):
	if data.has("achievements"):
		for ach_id in data.achievements:
			if ach_id in achievements:
				achievements[ach_id].unlocked = data.achievements[ach_id]
	
	if data.has("stats"):
		stats = data.stats
