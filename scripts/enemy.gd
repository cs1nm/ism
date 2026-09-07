extends CharacterBody2D

# Enemy base script

signal enemy_died(enemy: CharacterBody2D, drops: Dictionary)

@export var enemy_type: String = "slime"
@export var max_hp: int = 3
@export var damage: int = 1
@export var move_speed: float = 40.0
@export var attack_range: float = 30.0
@export var detection_range: float = 150.0
@export var attack_cooldown: float = 1.0

var hp: int = 3
var target: Node2D = null
var is_attacking: bool = false
var attack_timer: float = 0.0
var is_dead: bool = false

func _ready():
	hp = max_hp
	add_to_group("enemies")
	# Find player
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]

func _physics_process(delta):
	if is_dead:
		return
	
	# Attack cooldown
	if attack_timer > 0:
		attack_timer -= delta
	
	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		
		# Detection
		if distance <= detection_range:
			if distance <= attack_range:
				# Attack
				if attack_timer <= 0:
					_attack()
					attack_timer = attack_cooldown
				velocity = Vector2.ZERO
			else:
				# Move towards target
				var direction = (target.global_position - global_position).normalized()
				velocity = direction * move_speed
				
				# Flip sprite based on direction
				if has_node("Sprite2D"):
					if velocity.x < 0:
						$Sprite2D.flip_h = true
					elif velocity.x > 0:
						$Sprite2D.flip_h = false
		else:
			# Idle - wander slightly
			velocity = velocity.lerp(Vector2.ZERO, delta * 2.0)
	else:
		velocity = velocity.lerp(Vector2.ZERO, delta * 2.0)
	
	move_and_slide()

func _attack():
	if target and target.has_method("take_damage"):
		target.take_damage(damage)
		# Visual feedback - bounce
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.2, 0.8), 0.1)
		tween.tween_property(self, "scale", Vector2(1, 1), 0.1)

func take_damage(amount: int):
	if is_dead:
		return
	
	hp -= amount
	
	# Flash red
	if has_node("Sprite2D"):
		var sprite = $Sprite2D
		sprite.modulate = Color(1, 0.3, 0.3)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	
	# Knockback
	if target and is_instance_valid(target):
		var knockback_dir = (global_position - target.global_position).normalized()
		velocity = knockback_dir * 100
	
	if hp <= 0:
		_die()

func _die():
	is_dead = true
	
	# Death animation
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0, 0), 0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	
	# Emit drops
	var drops = _calculate_drops()
	enemy_died.emit(self, drops)
	
	# Remove after animation
	tween.tween_callback(queue_free)

func _calculate_drops() -> Dictionary:
	var drops = {}
	
	# Base drops by type
	match enemy_type:
		"slime":
			drops["coins"] = randi_range(2, 5)
			if randf() < 0.3:
				drops["wood"] = randi_range(1, 2)
		"ice_elemental":
			drops["coins"] = randi_range(5, 10)
			drops["gem"] = randi_range(1, 2)
		"fire_elemental":
			drops["coins"] = randi_range(8, 15)
			drops["gem"] = randi_range(2, 3)
			if randf() < 0.2:
				drops["ingot"] = 1
		"forest_spirit":
			drops["coins"] = randi_range(4, 8)
			drops["wood"] = randi_range(2, 4)
			if randf() < 0.25:
				drops["stone"] = randi_range(1, 2)
	
	return drops
