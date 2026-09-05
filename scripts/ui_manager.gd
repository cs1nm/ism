extends CanvasLayer

@onready var coins_label: Label = $TopBar/CoinsLabel
@onready var wood_label: Label = $TopBar/ResourcesPanel/WoodLabel
@onready var stone_label: Label = $TopBar/ResourcesPanel/StoneLabel
@onready var gems_label: Label = $TopBar/ResourcesPanel/GemsLabel
@onready var backpack_label: Label = $TopBar/ResourcesPanel/BackpackLabel

@onready var upgrade_panel: PanelContainer = $UpgradePanel
@onready var speed_cost_label: Label = $UpgradePanel/VBox/SpeedRow/SpeedCost
@onready var backpack_cost_label: Label = $UpgradePanel/VBox/BackpackRow/BackpackCost
@onready var expand_cost_label: Label = $UpgradePanel/VBox/ExpandRow/ExpandCost
@onready var speed_level_label: Label = $UpgradePanel/VBox/SpeedRow/SpeedLevel
@onready var backpack_level_label: Label = $UpgradePanel/VBox/BackpackRow/BackpackLevel
@onready var island_level_label: Label = $UpgradePanel/VBox/ExpandRow/IslandLevel

@onready var sell_button: Button = $SellButton
@onready var speed_button: Button = $UpgradePanel/VBox/SpeedRow/SpeedBtn
@onready var backpack_button: Button = $UpgradePanel/VBox/BackpackRow/BackpackBtn
@onready var expand_button: Button = $UpgradePanel/VBox/ExpandRow/ExpandBtn

@onready var message_label: Label = $MessageLabel

var player_node: Node2D = null
var expand_signal_connected: bool = false

func _ready():
	upgrade_panel.visible = false
	sell_button.pressed.connect(_on_sell_pressed)
	speed_button.pressed.connect(_on_speed_upgrade)
	backpack_button.pressed.connect(_on_backpack_upgrade)
	expand_button.pressed.connect(_on_expand)
	sell_button.visible = false
	_update_ui()
	_add_vignette()
	_animate_ui_in()

func _add_vignette():
	var vignette = TextureRect.new()
	vignette.name = "Vignette"
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.z_index = 100
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	var size = 128
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = size / 2.0
	for x in range(size):
		for y in range(size):
			var dx = float(x - center) / center
			var dy = float(y - center) / center
			var dist = sqrt(dx * dx + dy * dy) / 1.2
			var alpha = 0.0
			if dist > 0.5:
				alpha = clampf((dist - 0.5) * 1.8, 0.0, 0.65)
			img.set_pixel(x, y, Color(0, 0, 0.05, alpha))
	
	vignette.texture = ImageTexture.create_from_image(img)
	add_child(vignette)

func _animate_ui_in():
	# Fade in UI elements smoothly
	for child in $TopBar.get_children():
		child.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(child, "modulate:a", 1.0, 0.5)
	
	$HelpLabel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_interval(0.3)
	tween.tween_property($HelpLabel, "modulate:a", 0.6, 0.8)

func _process(_delta):
	_update_ui()
	if player_node:
		var bases = get_tree().get_nodes_in_group("base")
		var show_sell = false
		for base in bases:
			if not base.is_in_group("shop") and player_node.global_position.distance_to(base.global_position) < 100:
				show_sell = true
				break
		if sell_button.visible != show_sell:
			sell_button.visible = show_sell
			if show_sell:
				# Animate button in
				sell_button.modulate.a = 0.0
				var tween = create_tween()
				tween.set_ease(Tween.EASE_OUT)
				tween.set_trans(Tween.TRANS_BACK)
				tween.tween_property(sell_button, "modulate:a", 1.0, 0.3)
		
		var shops = get_tree().get_nodes_in_group("shop")
		var show_shop = false
		for shop in shops:
			if player_node.global_position.distance_to(shop.global_position) < 120:
				show_shop = true
				break
		if upgrade_panel.visible != show_shop:
			upgrade_panel.visible = show_shop
			if show_shop:
				# Slide in animation
				upgrade_panel.position.x -= 50
				upgrade_panel.modulate.a = 0.0
				var tween = create_tween()
				tween.set_ease(Tween.EASE_OUT)
				tween.set_trans(Tween.TRANS_BACK)
				tween.tween_property(upgrade_panel, "position:x", upgrade_panel.position.x + 50, 0.4)
				tween.parallel().tween_property(upgrade_panel, "modulate:a", 1.0, 0.3)

func _update_ui():
	coins_label.text = "Coins: %d" % GameData.coins
	wood_label.text = "Wood: %d" % GameData.wood
	stone_label.text = "Stone: %d" % GameData.stone
	gems_label.text = "Gems: %d" % GameData.gems
	backpack_label.text = "%d/%d" % [GameData.current_backpack, GameData.max_backpack]
	
	speed_cost_label.text = "%d" % GameData.get_speed_upgrade_cost()
	backpack_cost_label.text = "%d" % GameData.get_backpack_upgrade_cost()
	expand_cost_label.text = "%d" % GameData.get_expand_cost()
	
	speed_level_label.text = "Lv.%d" % GameData.speed_level
	backpack_level_label.text = "Lv.%d" % GameData.backpack_level
	island_level_label.text = "Lv.%d" % GameData.island_level
	
	# Color feedback - red if can't afford, green if can
	speed_cost_label.add_theme_color_override("font_color", 
		Color.GREEN_YELLOW if GameData.coins >= GameData.get_speed_upgrade_cost() else Color(1, 0.5, 0.5))
	backpack_cost_label.add_theme_color_override("font_color", 
		Color.GREEN_YELLOW if GameData.coins >= GameData.get_backpack_upgrade_cost() else Color(1, 0.5, 0.5))
	expand_cost_label.add_theme_color_override("font_color", 
		Color.GREEN_YELLOW if GameData.coins >= GameData.get_expand_cost() else Color(1, 0.5, 0.5))
	
	# Backpack full warning
	if GameData.current_backpack >= GameData.max_backpack:
		backpack_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	else:
		backpack_label.add_theme_color_override("font_color", Color.WHITE)

func _on_sell_pressed():
	if GameData.current_backpack > 0:
		var earned = GameData.sell_all()
		_show_message("Sold for %d coins!" % earned, Color(1, 0.85, 0))
		_animate_coins(earned)
	else:
		_show_message("Backpack is empty!", Color(1, 0.5, 0.5))

func _animate_coins(amount: int):
	# Coin fly animation towards coins label
	for i in range(mini(amount / 5, 5)):
		var coin = Label.new()
		coin.text = "+"
		coin.add_theme_color_override("font_color", Color(1, 0.85, 0))
		coin.add_theme_font_size_override("font_size", 20)
		coin.position = sell_button.position + Vector2(0, -20)
		coin.z_index = 50
		add_child(coin)
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(coin, "position", coins_label.position + Vector2(randf() * 30, randf() * 10), 0.5 + i * 0.05)
		tween.parallel().tween_property(coin, "modulate:a", 0.0, 0.5 + i * 0.05)
		tween.tween_callback(coin.queue_free)

func _on_speed_upgrade():
	if GameData.upgrade_speed():
		_show_message("Speed upgraded!", Color(0.5, 0.9, 1))
		_bump_label(speed_level_label)
	else:
		_show_message("Not enough coins!", Color(1, 0.5, 0.5))

func _on_backpack_upgrade():
	if GameData.upgrade_backpack():
		_show_message("Backpack upgraded!", Color(0.5, 1, 0.5))
		_bump_label(backpack_level_label)
	else:
		_show_message("Not enough coins!", Color(1, 0.5, 0.5))

func _on_expand():
	if GameData.expand_island():
		_show_message("Island expanded!", Color(1, 1, 0.5))
		_bump_label(island_level_label)
		get_tree().call_group("world", "expand_island")
	else:
		_show_message("Not enough coins!", Color(1, 0.5, 0.5))

func _bump_label(label: Label):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	label.scale = Vector2(1.5, 1.5)
	tween.tween_property(label, "scale", Vector2.ONE, 0.3)

func _show_message(text: String, color: Color):
	message_label.text = text
	message_label.add_theme_color_override("font_color", color)
	message_label.modulate.a = 1.0
	message_label.scale = Vector2(1.2, 1.2)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(message_label, "scale", Vector2.ONE, 0.2)
	tween.tween_interval(1.5)
	tween.tween_property(message_label, "modulate:a", 0.0, 0.5)

func set_player(p: Node2D):
	player_node = p
