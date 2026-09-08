extends Node

# Tutorial system for new players

signal tutorial_step_completed(step: int)
signal tutorial_finished()

var current_step: int = 0
var tutorial_active: bool = false
var tutorial_messages = [
	{
		"text": "Welcome to Island Idle! 🏝️\nUse WASD or touch joystick to move",
		"condition": "always",
		"duration": 5.0,
	},
	{
		"text": "Walk near trees to harvest wood automatically 🌲",
		"condition": "near_tree",
		"duration": 4.0,
	},
	{
		"text": "Collect resources to fill your backpack 🎒",
		"condition": "has_resources",
		"duration": 4.0,
	},
	{
		"text": "Return to base and press SELL to earn coins 💰",
		"condition": "near_base",
		"duration": 4.0,
	},
	{
		"text": "Visit the shop to upgrade your stats! ⚡",
		"condition": "near_shop",
		"duration": 4.0,
	},
	{
		"text": "Craft tools at the workbench for better harvesting 🪓",
		"condition": "near_workbench",
		"duration": 4.0,
	},
	{
		"text": "Watch out for enemies! They attack when you get close ⚔️",
		"condition": "enemy_visible",
		"duration": 4.0,
	},
	{
		"text": "Use the portal to travel to new islands! 🌀",
		"condition": "near_portal",
		"duration": 4.0,
	},
	{
		"text": "Good luck, adventurer! 🎮",
		"condition": "always",
		"duration": 3.0,
	},
]

var tutorial_label: Label = null
var tutorial_panel: PanelContainer = null

func _ready():
	# Only show tutorial for new players
	if _is_new_player():
		await get_tree().create_timer(1.0).timeout
		start_tutorial()

func _is_new_player() -> bool:
	# Check if this is first time playing
	return GameData.coins == 0 and GameData.wood == 0 and GameData.stone == 0

func start_tutorial():
	tutorial_active = true
	current_step = 0
	_create_tutorial_ui()
	_show_current_step()

func _create_tutorial_ui():
	tutorial_panel = PanelContainer.new()
	tutorial_panel.name = "TutorialPanel"
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = Color(0.36, 0.88, 0.93, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	tutorial_panel.add_theme_stylebox_override("panel", style)
	
	tutorial_panel.position = Vector2(200, 400)
	tutorial_panel.size = Vector2(400, 80)
	
	tutorial_label = Label.new()
	tutorial_label.name = "TutorialLabel"
	tutorial_label.add_theme_font_size_override("font_size", 16)
	tutorial_label.add_theme_color_override("font_color", Color.WHITE)
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	tutorial_panel.add_child(tutorial_label)
	get_tree().root.add_child(tutorial_panel)
	tutorial_panel.z_index = 1000

func _show_current_step():
	if current_step >= tutorial_messages.size():
		_finish_tutorial()
		return
	
	var msg = tutorial_messages[current_step]
	tutorial_label.text = msg.text
	
	# Animate in
	tutorial_panel.modulate.a = 0.0
	var tween = tutorial_panel.create_tween()
	tween.tween_property(tutorial_panel, "modulate:a", 1.0, 0.3)
	tween.tween_interval(msg.duration)
	tween.tween_property(tutorial_panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_next_step)

func _next_step():
	current_step += 1
	tutorial_step_completed.emit(current_step)
	
	# Wait before showing next
	await get_tree().create_timer(0.5).timeout
	_show_current_step()

func _finish_tutorial():
	tutorial_active = false
	tutorial_finished.emit()
	
	if tutorial_panel:
		var tween = tutorial_panel.create_tween()
		tween.tween_property(tutorial_panel, "modulate:a", 0.0, 0.5)
		tween.tween_callback(tutorial_panel.queue_free)

func skip_tutorial():
	_finish_tutorial()
