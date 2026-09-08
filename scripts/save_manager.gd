extends Node

# Auto-save system for game progress

signal save_completed()
signal load_completed()

var save_timer: Timer
var auto_save_interval: float = 30.0  # Save every 30 seconds

func _ready():
	# Wait for YandexSDK to initialize
	YandexSDK.sdk_initialized.connect(_on_sdk_ready)
	
	# Create auto-save timer
	save_timer = Timer.new()
	save_timer.wait_time = auto_save_interval
	save_timer.autostart = false
	save_timer.timeout.connect(_auto_save)
	add_child(save_timer)

func _on_sdk_ready():
	# Load saved data
	load_game()
	
	# Start auto-save
	save_timer.start()
	
	# Save on important events
	GameData.coins_changed.connect(_on_important_change)
	GameData.resources_changed.connect(_on_important_change)
	GameData.upgrades_changed.connect(_on_important_change)
	GameData.tools_changed.connect(_on_important_change)
	LocationManager.location_changed.connect(_on_location_change)

func _on_important_change():
	# Save immediately on important changes
	save_game()

func _on_location_change(new_location: String):
	# Save when changing location
	save_game()
	
	# Show interstitial ad occasionally
	if randf() < 0.3:  # 30% chance
		YandexSDK.show_interstitial()

func _auto_save():
	save_game()

func save_game():
	var save_data = {
		"version": 1,
		"timestamp": Time.get_unix_time_from_system(),
		"player": {
			"hp": _get_player_hp(),
			"max_hp": _get_player_max_hp(),
		},
		"resources": {
			"coins": GameData.coins,
			"wood": GameData.wood,
			"stone": GameData.stone,
			"gems": GameData.gems,
			"ingots": GameData.ingots,
		},
		"upgrades": {
			"speed_level": GameData.speed_level,
			"backpack_level": GameData.backpack_level,
			"island_level": GameData.island_level,
		},
		"tools": {
			"axe_level": GameData.axe_level,
			"pickaxe_level": GameData.pickaxe_level,
		},
		"location": {
			"current": LocationManager.current_location,
			"unlocked": LocationManager.unlocked_locations,
		},
	}
	
	YandexSDK.save_data(save_data)
	save_completed.emit()

func load_game():
	var data = YandexSDK.load_data()
	
	if data.is_empty():
		print("[SaveManager] No save data found")
		load_completed.emit()
		return
	
	# Validate version
	if not data.has("version"):
		print("[SaveManager] Invalid save data")
		load_completed.emit()
		return
	
	# Load resources
	if data.has("resources"):
		var res = data.resources
		GameData.coins = res.get("coins", 0)
		GameData.wood = res.get("wood", 0)
		GameData.stone = res.get("stone", 0)
		GameData.gems = res.get("gems", 0)
		GameData.ingots = res.get("ingots", 0)
		GameData.notify_coins_changed()
		GameData.resources_changed.emit()
	
	# Load upgrades
	if data.has("upgrades"):
		var upg = data.upgrades
		GameData.speed_level = upg.get("speed_level", 1)
		GameData.backpack_level = upg.get("backpack_level", 1)
		GameData.island_level = upg.get("island_level", 1)
		
		# Recalculate derived values
		GameData.move_speed = GameData.base_move_speed + (GameData.speed_level - 1) * 15.0
		GameData.max_backpack = GameData.base_max_backpack + (GameData.backpack_level - 1) * 5
		GameData.island_radius = GameData.base_island_radius + (GameData.island_level - 1) * 30.0
		GameData.upgrades_changed.emit()
	
	# Load tools
	if data.has("tools"):
		var tools = data.tools
		GameData.axe_level = tools.get("axe_level", 0)
		GameData.pickaxe_level = tools.get("pickaxe_level", 0)
		GameData.tools_changed.emit()
	
	# Load location
	if data.has("location"):
		var loc = data.location
		LocationManager.current_location = loc.get("current", "starter")
		LocationManager.unlocked_locations = loc.get("unlocked", ["starter"])
	
	# Load player HP
	if data.has("player"):
		var player_data = data.player
		await get_tree().process_frame
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var player = players[0]
			player.max_hp = player_data.get("max_hp", 10)
			player.hp = player_data.get("hp", player.max_hp)
	
	print("[SaveManager] Game loaded successfully")
	load_completed.emit()

func _get_player_hp() -> int:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0].hp
	return 10

func _get_player_max_hp() -> int:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0].max_hp
	return 10

# Manual save/load for UI buttons
func manual_save():
	save_game()
	return true

func manual_load():
	load_game()
	return true
