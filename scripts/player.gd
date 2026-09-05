extends CharacterBody2D

signal near_resource(resource_node)
signal near_base()
signal resource_collected(type: String, amount: int)

@onready var sprite: Sprite2D = $Sprite2D
@onready var harvest_area: Area2D = $HarvestArea
@onready var harvest_timer: Timer = $HarvestTimer
@onready var camera: Camera2D = $Camera2D
@onready var harvest_indicator: Label = $HarvestIndicator

# These will be set after main.gd creates them
var shadow: Sprite2D = null
var dust_particles: GPUParticles2D = null

var current_resource: Node2D = null
var is_harvesting: bool = false
var walk_time: float = 0.0
var is_moving: bool = false
var original_y: float = 0.0

func _ready():
	harvest_timer.wait_time = 0.5 / GameData.harvest_speed
	harvest_timer.timeout.connect(_on_harvest_tick)
	harvest_area.body_entered.connect(_on_harvest_area_body_entered)
	harvest_area.body_exited.connect(_on_harvest_area_body_exited)
	harvest_indicator.visible = false
	original_y = sprite.position.y

func setup_extras(p_shadow: Sprite2D, p_dust: GPUParticles2D):
	shadow = p_shadow
	dust_particles = p_dust
	if dust_particles:
		dust_particles.emitting = false

func _physics_process(delta):
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")
	
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
		is_harvesting = false
		harvest_indicator.visible = false
		is_moving = true
	else:
		is_moving = false
	
	velocity = input_dir * GameData.move_speed
	move_and_slide()
	
	# Walk animation - bob and tilt
	if is_moving:
		walk_time += delta * 12.0
		sprite.position.y = original_y + sin(walk_time) * 2.0
		sprite.rotation = sin(walk_time * 0.5) * 0.05
		if dust_particles:
			dust_particles.emitting = true
		
		# Flip sprite based on direction
		if velocity.x < 0:
			sprite.flip_h = true
		elif velocity.x > 0:
			sprite.flip_h = false
	else:
		# Return to idle
		sprite.position.y = lerp(sprite.position.y, original_y, delta * 10.0)
		sprite.rotation = lerp(sprite.rotation, 0.0, delta * 10.0)
		walk_time = 0.0
		if dust_particles:
			dust_particles.emitting = false
	
	# Shadow follows player
	if shadow:
		shadow.global_position = global_position + Vector2(0, 20)

func _on_harvest_area_body_entered(body):
	if body.is_in_group("resources"):
		current_resource = body
		is_harvesting = true
		harvest_timer.start()
		harvest_indicator.visible = true
		harvest_indicator.text = "Mining..."
		near_resource.emit(body)
	elif body.is_in_group("base"):
		near_base.emit()

func _on_harvest_area_body_exited(body):
	if body == current_resource:
		current_resource = null
		is_harvesting = false
		harvest_timer.stop()
		harvest_indicator.visible = false

func _on_harvest_tick():
	if current_resource and is_harvesting:
		if GameData.current_backpack >= GameData.max_backpack:
			harvest_indicator.text = "FULL!"
			return
		var res_type = current_resource.resource_type
		var added = GameData.add_resource(res_type, 1)
		if added > 0:
			current_resource.take_damage(1)
			resource_collected.emit(res_type, added)
			harvest_indicator.text = "+1 " + res_type.capitalize()
			_spawn_floating_text("+1", Color.GREEN)
			# Spawn harvest particles
			if current_resource.has_method("spawn_harvest_particles"):
				current_resource.spawn_harvest_particles()
		else:
			harvest_indicator.text = "FULL!"
		
		if current_resource and current_resource.check_depleted():
			current_resource = null
			is_harvesting = false
			harvest_timer.stop()

func _spawn_floating_text(text: String, color: Color):
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 16)
	label.position = Vector2(-20, -50)
	label.z_index = 100
	add_child(label)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y - 50, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)
