extends Control

# Virtual joystick for mobile touch controls

var joystick_center: Vector2 = Vector2(80, 80)
var joystick_radius: float = 60.0
var knob_position: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.ZERO
var is_active: bool = false
var touch_index: int = -1

func _ready():
	# Only show on touch devices
	if not DisplayServer.is_touchscreen_available():
		visible = false
	
	position = Vector2(20, 20)
	size = Vector2(160, 160)
	
	# Draw joystick base and knob
	queue_redraw()

func _draw():
	# Draw base circle
	draw_circle(joystick_center, joystick_radius, Color(0.2, 0.2, 0.2, 0.5))
	draw_arc(joystick_center, joystick_radius, 0, TAU, 32, Color(0.8, 0.8, 0.8, 0.7), 3)
	
	# Draw knob
	var knob_pos = joystick_center + knob_position
	draw_circle(knob_pos, 20, Color(0.9, 0.9, 0.9, 0.8))
	draw_arc(knob_pos, 20, 0, TAU, 32, Color(1, 1, 1, 1), 2)

func _input(event: InputEvent):
	if not visible:
		return
	
	if event is InputEventScreenTouch:
		if event.pressed:
			# Check if touch is inside joystick area
			var local_pos = event.position - global_position
			if local_pos.distance_to(joystick_center) <= joystick_radius:
				is_active = true
				touch_index = event.index
				_update_knob(local_pos)
		else:
			# Release
			if event.index == touch_index:
				is_active = false
				touch_index = -1
				knob_position = Vector2.ZERO
				direction = Vector2.ZERO
				queue_redraw()
	
	elif event is InputEventScreenDrag:
		if is_active and event.index == touch_index:
			var local_pos = event.position - global_position
			_update_knob(local_pos)

func _update_knob(local_pos: Vector2):
	var offset = local_pos - joystick_center
	var distance = offset.length()
	
	if distance > joystick_radius:
		offset = offset.normalized() * joystick_radius
	
	knob_position = offset
	direction = offset / joystick_radius
	queue_redraw()
