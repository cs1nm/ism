extends CanvasLayer

@onready var coins_label: Label = $TopBar/CoinsLabel
@onready var wood_label: Label = $TopBar/ResourcesPanel/WoodLabel
@onready var stone_label: Label = $TopBar/ResourcesPanel/StoneLabel
@onready var gems_label: Label = $TopBar/ResourcesPanel/GemsLabel
@onready var ingots_label: Label = $TopBar/ResourcesPanel/IngotsLabel
@onready var backpack_label: Label = $TopBar/ResourcesPanel/BackpackLabel
@onready var tools_label: Label = $TopBar/ToolsLabel

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
var hp_bar: ProgressBar = null
var hp_label: Label = null

func _ready():
	upgrade_panel.visible = false
	sell_button.pressed.connect(_on_sell_pressed)
	speed_button.pressed.connect(_on_speed_upgrade)
	backpack_button.pressed.connect(_on_backpack_upgrade)
	expand_button.pressed.connect(_on_expand)
	sell_button.visible = false
	_update_ui()
	_add_vignette()
	_create_hp_bar()
	_create_reward_button()
	_animate_ui_in()

func _create_hp_bar():
	# HP bar container
	var hp_container = VBoxContainer.new()
	hp_container.name = "HPContainer"
	hp_container.position = Vector2(20, 60)
	hp_container.size = Vector2(150, 20)
	add_child(hp_container)
	
	# HP label
	hp_label = Label.new()
	hp_label.name = "HPLabel"
	hp_label.text = "HP: 10/10"
	hp_label.add_theme_font_size_override("font_size", 14)
	hp_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	hp_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	hp_label.add_theme_constant_override("shadow_offset_x", 2)
	hp_label.add_theme_constant_override("shadow_offset_y", 2)
	hp_container.add_child(hp_label)
	
	# HP progress bar
	hp_bar = ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.min_value = 0
	hp_bar.max_value = 10
	hp_bar.value = 10
	hp_bar.size = Vector2(150, 16)
	hp_bar.show_percentage = false
	hp_container.add_child(hp_bar)
	
	# Style the HP bar
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.1, 0.1, 0.8)
	style_bg.border_color = Color(0.4, 0.2, 0.2, 1.0)
	style_bg.set_border_width_all(2)
	style_bg.set_corner_radius_all(4)
	hp_bar.add_theme_stylebox_override("background", style_bg)
	
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.8, 0.2, 0.2, 1.0)
	style_fill.set_corner_radius_all(2)
	hp_bar.add_theme_stylebox_override("fill", style_fill)

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
	ingots_label.text = "Ingots: %d" % GameData.ingots
	backpack_label.text = "%d/%d" % [GameData.current_backpack, GameData.max_backpack]
	
	# Update HP bar
	if player_node and hp_bar and hp_label:
		hp_bar.max_value = player_node.max_hp
		hp_bar.value = player_node.hp
		hp_label.text = "HP: %d/%d" % [player_node.hp, player_node.max_hp]
		
		# Color based on HP percentage
		var hp_percent = float(player_node.hp) / float(player_node.max_hp)
		if hp_percent > 0.6:
			hp_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
		elif hp_percent > 0.3:
			hp_label.add_theme_color_override("font_color", Color(1, 1, 0.3))
		else:
			hp_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	
	# Show equipped tools
	var tools_text = ""
	if GameData.axe_level > 0:
		tools_text += "Axe Lv%d " % GameData.axe_level
	if GameData.pickaxe_level > 0:
		tools_text += "Pick Lv%d" % GameData.pickaxe_level
	tools_label.text = tools_text if tools_text != "" else "No tools"
	
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
		SoundManager.play_sound("sell")
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
		SoundManager.play_sound("upgrade")
	else:
		_show_message("Not enough coins!", Color(1, 0.5, 0.5))

func _on_backpack_upgrade():
	if GameData.upgrade_backpack():
		_show_message("Backpack upgraded!", Color(0.5, 1, 0.5))
		_bump_label(backpack_level_label)
		SoundManager.play_sound("upgrade")
	else:
		_show_message("Not enough coins!", Color(1, 0.5, 0.5))

func _on_expand():
	if GameData.expand_island():
		_show_message("Island expanded!", Color(1, 1, 0.5))
		_bump_label(island_level_label)
		SoundManager.play_sound("upgrade")
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

func _create_reward_button():
	# Rewarded video button
	var reward_btn = Button.new()
	reward_btn.name = "RewardButton"
	reward_btn.text = "🎬 Watch Ad +50 Coins"
	reward_btn.position = Vector2(20, 100)
	reward_btn.size = Vector2(180, 40)
	reward_btn.add_theme_font_size_override("font_size", 14)
	reward_btn.add_theme_color_override("font_color", Color.WHITE)
	
	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.6, 0.3, 0.9)
	style.border_color = Color(0.1, 0.4, 0.2, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	reward_btn.add_theme_stylebox_override("normal", style)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.3, 0.7, 0.4, 0.95)
	style_hover.border_color = Color(0.2, 0.5, 0.3, 1.0)
	style_hover.set_border_width_all(2)
	style_hover.set_corner_radius_all(8)
	reward_btn.add_theme_stylebox_override("hover", style_hover)
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.15, 0.5, 0.25, 0.9)
	style_pressed.border_color = Color(0.1, 0.4, 0.2, 1.0)
	style_pressed.set_border_width_all(2)
	style_pressed.set_corner_radius_all(8)
	reward_btn.add_theme_stylebox_override("pressed", style_pressed)
	
	reward_btn.pressed.connect(_on_reward_pressed)
	add_child(reward_btn)
	
	# Achievement button
	var ach_btn = Button.new()
	ach_btn.name = "AchievementsButton"
	ach_btn.text = "🏆 Achievements"
	ach_btn.position = Vector2(20, 150)
	ach_btn.size = Vector2(180, 40)
	ach_btn.add_theme_font_size_override("font_size", 14)
	
	var ach_style = StyleBoxFlat.new()
	ach_style.bg_color = Color(0.3, 0.2, 0.4, 0.9)
	ach_style.border_color = Color(0.5, 0.3, 0.7, 1.0)
	ach_style.set_border_width_all(2)
	ach_style.set_corner_radius_all(8)
	ach_btn.add_theme_stylebox_override("normal", ach_style)
	
	ach_btn.pressed.connect(_on_achievements_pressed)
	add_child(ach_btn)
	
	# Create achievements panel (hidden by default)
	_create_achievements_panel()
	
	# Connect to YandexSDK signals
	YandexSDK.reward_earned.connect(_on_reward_earned)
	YandexSDK.reward_error.connect(_on_reward_error)

func _on_reward_pressed():
	YandexSDK.show_rewarded_video("coins", 50)

func _on_reward_earned(reward_type: String, reward_value: String):
	_show_message("🎁 +%s %s!" % [reward_value, reward_type.capitalize()], Color(0.3, 1, 0.3))
	# Submit to leaderboard
	YandexSDK.submit_score("coins", GameData.coins)

func _on_reward_error(error: String):
	_show_message("❌ Ad failed: %s" % error, Color(1, 0.4, 0.4))

var achievements_panel: PanelContainer = null

func _create_achievements_panel():
	achievements_panel = PanelContainer.new()
	achievements_panel.name = "AchievementsPanel"
	achievements_panel.position = Vector2(220, 50)
	achievements_panel.size = Vector2(350, 500)
	achievements_panel.visible = false
	achievements_panel.z_index = 50
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.2, 0.95)
	style.border_color = Color(0.4, 0.3, 0.6, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	achievements_panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	achievements_panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "🏆 Achievements"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0))
	vbox.add_child(title)
	
	# Scroll container
	var scroll = ScrollContainer.new()
	scroll.size = Vector2(330, 420)
	vbox.add_child(scroll)
	
	var content = VBoxContainer.new()
	content.name = "AchievementList"
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	
	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func(): achievements_panel.visible = false)
	vbox.add_child(close_btn)
	
	add_child(achievements_panel)

func _on_achievements_pressed():
	achievements_panel.visible = !achievements_panel.visible
	if achievements_panel.visible:
		_refresh_achievements_list()

func _refresh_achievements_list():
	var list = achievements_panel.get_node("PanelContainer/VBoxContainer/ScrollContainer/AchievementList")
	if not list:
		# Try alternative path
		list = achievements_panel.find_child("AchievementList", true, false)
	
	if not list:
		return
	
	# Clear existing
	for child in list.get_children():
		child.queue_free()
	
	# Add achievements
	var unlocked_count = 0
	for ach_id in Achievements.achievements:
		var ach = Achievements.achievements[ach_id]
		if ach.unlocked:
			unlocked_count += 1
		
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		
		var icon = Label.new()
		icon.text = ach.icon
		icon.add_theme_font_size_override("font_size", 24)
		row.add_child(icon)
		
		var info = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var name_label = Label.new()
		name_label.text = ach.name
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", 
			Color(1, 0.85, 0) if ach.unlocked else Color(0.5, 0.5, 0.5))
		info.add_child(name_label)
		
		var desc_label = Label.new()
		desc_label.text = ach.description
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.add_theme_color_override("font_color", 
			Color(0.8, 0.8, 0.8) if ach.unlocked else Color(0.4, 0.4, 0.4))
		info.add_child(desc_label)
		
		row.add_child(info)
		
		# Status
		var status = Label.new()
		status.text = "✓" if ach.unlocked else "🔒"
		status.add_theme_font_size_override("font_size", 20)
		row.add_child(status)
		
		list.add_child(row)
	
	# Add counter at top
	var counter = list.get_children()[0] if list.get_child_count() > 0 else null
	if counter:
		var count_label = Label.new()
		count_label.text = "Unlocked: %d / %d" % [unlocked_count, Achievements.achievements.size()]
		count_label.add_theme_font_size_override("font_size", 12)
		count_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		list.add_child(count_label)
		list.move_child(count_label, 0)
