extends CanvasLayer

# Crafting UI — appears when near workbench/forge/furnace

var player_node: Node2D = null
var current_station: String = ""  # "workbench", "furnace", "forge"

@onready var panel: PanelContainer = $CraftPanel
@onready var title_label: Label = $CraftPanel/VBox/Title
@onready var content: VBoxContainer = $CraftPanel/VBox/Content
@onready var message_label: Label = $MessageLabel2

func _ready():
	panel.visible = false
	message_label.visible = false

func _process(_delta):
	if not player_node:
		return
	
	var near_station = ""
	var stations = get_tree().get_nodes_in_group("crafting_station")
	for station in stations:
		if player_node.global_position.distance_to(station.global_position) < 80:
			near_station = station.building_type if station.has_method("get") else ""
			# Check via metadata
			if station.has_meta("station_type"):
				near_station = station.get_meta("station_type")
			break
	
	if near_station != "" and near_station != current_station:
		current_station = near_station
		_show_station_ui(near_station)
	elif near_station == "" and current_station != "":
		current_station = ""
		panel.visible = false

func _show_station_ui(station_type: String):
	# Clear old buttons
	for child in content.get_children():
		child.queue_free()
	
	match station_type:
		"workbench":
			title_label.text = "WORKBENCH"
			_add_craft_button("Axe (8 Wood + 5 Stone)", "axe")
			_add_craft_button("Pickaxe (5 Wood + 8 Stone)", "pickaxe")
		"furnace":
			title_label.text = "FURNACE"
			_add_craft_button("Smelt: 3 Stone -> 1 Ingot", "smelt")
		"forge":
			title_label.text = "FORGE"
			if GameData.axe_level >= 1:
				_add_craft_button("Upgrade Axe Lv2 (5W+3S+50c+3I)", "axe_upgrade")
			if GameData.pickaxe_level >= 1:
				_add_craft_button("Upgrade Pickaxe Lv2 (3W+5S+50c+3I)", "pickaxe_upgrade")
		"portal":
			title_label.text = "PORTAL"
			_build_portal_ui()
	
	if content.get_child_count() == 0:
		var empty_label = Label.new()
		empty_label.text = "Nothing to craft yet"
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		content.add_child(empty_label)
	
	panel.visible = true
	# Animate in
	panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)

func _add_craft_button(text: String, action: String):
	var btn = Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 13)
	btn.custom_minimum_size = Vector2(0, 32)
	btn.pressed.connect(_on_craft.bind(action))
	content.add_child(btn)

func _on_craft(action: String):
	var success = false
	var msg = ""
	match action:
		"axe":
			if GameData.can_craft_axe():
				success = GameData.craft_axe()
				msg = "Axe crafted! Chopping x2"
			else:
				msg = "Not enough resources!"
		"pickaxe":
			if GameData.can_craft_pickaxe():
				success = GameData.craft_pickaxe()
				msg = "Pickaxe crafted! Mining x2"
			else:
				msg = "Not enough resources!"
		"smelt":
			if GameData.can_smelt():
				success = GameData.smelt()
				msg = "Smelted 1 Ingot!"
			else:
				msg = "Need 3 Stone!"
		"axe_upgrade":
			if GameData.can_craft_axe():
				success = GameData.craft_axe()
				msg = "Axe upgraded to Lv2! x3"
			else:
				msg = "Not enough resources!"
		"pickaxe_upgrade":
			if GameData.can_craft_pickaxe():
				success = GameData.craft_pickaxe()
				msg = "Pickaxe upgraded to Lv2! x3"
			else:
				msg = "Not enough resources!"
	
	# Portal actions
	if action.begins_with("travel_"):
		var loc_id = action.substr(7)
		if LocationManager.travel_to(loc_id):
			success = true
			msg = "Traveling to %s!" % LocationManager.locations[loc_id].name
			SoundManager.play_sound("portal")
		else:
			msg = "Cannot travel there!"
	elif action.begins_with("unlock_"):
		var loc_id = action.substr(7)
		if LocationManager.unlock_location(loc_id):
			success = true
			msg = "%s unlocked!" % LocationManager.locations[loc_id].name
			_show_station_ui(current_station)  # Refresh
		else:
			msg = "Not enough coins!"
	
	if success:
		GameData.notify_tools_changed()
		_show_station_ui(current_station)  # Refresh UI
	
	_show_message(msg, Color.GREEN if success else Color(1, 0.5, 0.5))

func _build_portal_ui():
	for loc_id in LocationManager.locations:
		var loc = LocationManager.locations[loc_id]
		var is_current = (loc_id == LocationManager.current_location)
		var is_unlocked = loc_id in LocationManager.unlocked_locations
		
		if is_current:
			var current_label = Label.new()
			current_label.text = "> %s (HERE)" % loc.name
			current_label.add_theme_font_size_override("font_size", 13)
			current_label.add_theme_color_override("font_color", Color(0.36, 0.88, 0.93))
			content.add_child(current_label)
		elif is_unlocked:
			_add_craft_button("Travel: %s" % loc.name, "travel_%s" % loc_id)
		else:
			var cost = loc.get("unlock_cost", 0)
			_add_craft_button("Unlock: %s (%d coins)" % [loc.name, cost], "unlock_%s" % loc_id)

func _show_message(text: String, color: Color):
	message_label.text = text
	message_label.add_theme_color_override("font_color", color)
	message_label.visible = true
	message_label.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(message_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): message_label.visible = false)

func set_player(p: Node2D):
	player_node = p
