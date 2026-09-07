extends CharacterBody2D

signal near_resource(resource_node)
signal near_base()
signal resource_collected(type: String, amount: int)
signal player_damaged(amount: int)
signal player_healed(amount: int)

@onready var sprite: Sprite2D = $Sprite2D
@onready var harvest_area: Area2D = $HarvestArea
@onready var harvest_timer: Timer = $HarvestTimer
@onready var camera: Camera2D = $Camera2D
@onready var harvest_indicator: Label = $HarvestIndicator

var shadow: Sprite2D = null
var dust_particles: GPUParticles2D = null

var current_resource: Node2D = null
var is_harvesting: bool = false
var walk_time: float = 0.0
var is_moving: bool = false
var original_y: float = 0.0
var resources_in_range: Array = []
var joystick_direction: Vector2 = Vector2.ZERO  # From touch joystick

# HP system
var max_hp: int = 10
var hp: int = 10
var invulnerable: bool = false
var invulnerable_time: float = 0.5

# Combat
var attack_range: float = 40.0
var attack_damage: int = 2
var attack_cooldown: float = 0.8
var attack_timer: float = 0.0
var enemies_in_range: Array = []

func _ready():
	harvest_timer.wait_time = 0.5 / GameData.harvest_speed
	harvest_timer.timeout.connect(_on_harvest_tick)
	harvest_area.body_entered.connect(_on_harvest_area_body_entered)
	harvest_area.body_exited.connect(_on_harvest_area_body_exited)
	harvest_indicator.visible = false
	original_y = sprite.position.y
	
	# Create combat area
	var combat_area = Area2D.new()
	combat_area.name = "CombatArea"
	combat_area.collision_layer = 0
	combat_area.collision_mask = 8  # Enemy layer
	var combat_col = CollisionShape2D.new()
	var combat_shape = CircleShape2D.new()
	combat_shape.radius = attack_range
	combat_col.shape = combat_shape
	combat_area.add_child(combat_col)
	add_child(combat_area)
	combat_area.body_entered.connect(_on_combat_area_body_entered)
	combat_area.body_exited.connect(_on_combat_area_body_exited)

func setup_extras(p_shadow: Sprite2D, p_dust: GPUParticles2D):
	shadow = p_shadow
	dust_particles = p_dust
	if dust_particles:
		dust_particles.emitting = false

func _physics_process(delta):
	# Attack cooldown
	if attack_timer > 0:
		attack_timer -= delta
	
	# Auto-attack nearest enemy
	if attack_timer <= 0 and enemies_in_range.size() > 0:
		var closest_enemy = null
		var closest_dist = INF
		for enemy in enemies_in_range:
			if is_instance_valid(enemy):
				var dist = global_position.distance_to(enemy.global_position)
				if dist < closest_dist:
					closest_dist = dist
					closest_enemy = enemy
		
		if closest_enemy:
			_attack_enemy(closest_enemy)
			attack_timer = attack_cooldown
	
	var input_dir = Vector2.ZERO
	
	# Keyboard input
	var keyboard_dir = Vector2.ZERO
	keyboard_dir.x = Input.get_axis("move_left", "move_right")
	keyboard_dir.y = Input.get_axis("move_up", "move_down")
	
	# Touch joystick input (takes priority if active)
	if joystick_direction.length() > 0.1:
		input_dir = joystick_direction
	elif keyboard_dir.length() > 0:
		input_dir = keyboard_dir.normalized()
	
	if input_dir.length() > 0:
		is_moving = true
	else:
		is_moving = false
	
	velocity = input_dir * GameData.move_speed
	move_and_slide()
	
	# Walk animation
	if is_moving:
		walk_time += delta * 12.0
		sprite.position.y = original_y + sin(walk_time) * 2.0
		sprite.rotation = sin(walk_time * 0.5) * 0.05
		if dust_particles:
			dust_particles.emitting = true
		
		if velocity.x < 0:
			sprite.flip_h = true
		elif velocity.x > 0:
			sprite.flip_h = false
	else:
		sprite.position.y = lerp(sprite.position.y, original_y, delta * 10.0)
		sprite.rotation = lerp(sprite.rotation, 0.0, delta * 10.0)
		walk_time = 0.0
		if dust_particles:
			dust_particles.emitting = false
	
	if shadow:
		shadow.global_position = global_position + Vector2(0, 20)
	
	# Auto-start harvesting if near a resource and not already harvesting
	if not is_harvesting and resources_in_range.size() > 0:
		# Find closest valid resource
		var closest = null
		var closest_dist = INF
		for res in resources_in_range:
			if is_instance_valid(res) and not res.check_depleted():
				var dist = global_position.distance_to(res.global_position)
				if dist < closest_dist:
					closest_dist = dist
					closest = res
		if closest:
			current_resource = closest
			is_harvesting = true
			harvest_timer.start()
			harvest_indicator.visible = true
			harvest_indicator.text = "Mining..."

func _on_harvest_area_body_entered(body):
	if body.is_in_group("resources"):
		if not body.check_depleted():
			resources_in_range.append(body)
			near_resource.emit(body)
	elif body.is_in_group("base"):
		near_base.emit()

func _on_harvest_area_body_exited(body):
	if body in resources_in_range:
		resources_in_range.erase(body)
	if body == current_resource:
		current_resource = null
		is_harvesting = false
		harvest_timer.stop()
		harvest_indicator.visible = false
	# If we lost our resource, try to find another one
	if resources_in_range.size() > 0 and not is_harvesting:
		# Will be picked up in _physics_process
		pass
	elif resources_in_range.size() == 0:
		is_harvesting = false
		harvest_timer.stop()
		harvest_indicator.visible = false

func _on_harvest_tick():
	if current_resource and is_instance_valid(current_resource) and is_harvesting:
		if current_resource.check_depleted():
			resources_in_range.erase(current_resource)
			current_resource = null
			is_harvesting = false
			harvest_timer.stop()
			harvest_indicator.visible = false
			return
		
		if GameData.current_backpack >= GameData.max_backpack:
			harvest_indicator.text = "FULL!"
			return
		
		var res_type = current_resource.resource_type
		var mult = GameData.get_harvest_multiplier(res_type)
		var amount = int(mult)  # Harvest more per tick with tools
		var added = GameData.add_resource(res_type, amount)
		if added > 0:
			current_resource.take_damage(amount)
			resource_collected.emit(res_type, added)
			var mult_text = "" if mult <= 1.0 else " x%d" % int(mult)
			harvest_indicator.text = "+%d %s%s" % [added, res_type.capitalize(), mult_text]
			_spawn_floating_text("+%d%s" % [added, mult_text], Color.GREEN)
			if current_resource.has_method("spawn_harvest_particles"):
				current_resource.spawn_harvest_particles()
		else:
			harvest_indicator.text = "FULL!"
		
		if current_resource and current_resource.check_depleted():
			resources_in_range.erase(current_resource)
			current_resource = null
			is_harvesting = false
			harvest_timer.stop()
			harvest_indicator.visible = false

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

func take_damage(amount: int):
	if invulnerable or hp <= 0:
		return
	
	hp -= amount
	player_damaged.emit(amount)
	
	# Visual feedback
	sprite.modulate = Color(1, 0.3, 0.3)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	
	# Knockback
	if velocity.length() > 0:
		var knockback_dir = -velocity.normalized()
		var knockback_vel = knockback_dir * 150
		var kb_tween = create_tween()
		kb_tween.tween_property(self, "position", position + knockback_dir * 20, 0.2)
	
	# Invulnerability frames
	invulnerable = true
	await get_tree().create_timer(invulnerable_time).timeout
	invulnerable = false
	
	_spawn_floating_text("-%d HP" % amount, Color.RED)
	
	if hp <= 0:
		_die()

func heal(amount: int):
	hp = min(hp + amount, max_hp)
	player_healed.emit(amount)
	_spawn_floating_text("+%d HP" % amount, Color.GREEN)

func _die():
	# Respawn at base
	hp = max_hp
	position = Vector2(0, 80)
	player_healed.emit(0)  # Signal to update UI

func _on_combat_area_body_entered(body):
	if body.is_in_group("enemies"):
		enemies_in_range.append(body)

func _on_combat_area_body_exited(body):
	if body in enemies_in_range:
		enemies_in_range.erase(body)

func _attack_enemy(enemy: Node2D):
	if not is_instance_valid(enemy):
		return
	
	# Visual feedback - swing animation
	var tween = create_tween()
	tween.tween_property(sprite, "rotation", 0.3, 0.1)
	tween.tween_property(sprite, "rotation", -0.3, 0.1)
	tween.tween_property(sprite, "rotation", 0.0, 0.1)
	
	# Deal damage
	if enemy.has_method("take_damage"):
		enemy.take_damage(attack_damage)
		_spawn_floating_text("-%d" % attack_damage, Color.ORANGE)
