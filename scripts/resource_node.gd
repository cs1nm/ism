extends CharacterBody2D

@export var resource_type: String = "wood"
@export var max_hp: int = 5
@export var respawn_time: float = 15.0

var current_hp: int
var is_dead: bool = false
var sway_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var respawn_timer: Timer = $RespawnTimer
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var harvest_particles: GPUParticles2D = $HarvestParticles

signal depleted()

func _ready():
	current_hp = max_hp
	add_to_group("resources")
	respawn_timer.wait_time = respawn_time
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(_on_respawn)
	harvest_particles.emitting = false
	# Random start phase for sway
	sway_time = randf() * TAU
	# LOCK position - resources don't move
	velocity = Vector2.ZERO

func _process(delta):
	if not is_dead:
		# ONLY trees sway gently, rocks are completely static
		if resource_type == "wood":
			sway_time += delta * 1.5
			sprite.rotation = sin(sway_time) * 0.02

func take_damage(amount: int):
	current_hp -= amount
	_update_visual()
	if current_hp <= 0:
		_deplete()

func _update_visual():
	var ratio = float(current_hp) / float(max_hp)
	sprite.modulate = Color(1, 1, 1, 0.5 + 0.5 * ratio)
	# Shake effect (brief, returns to original position)
	var original_pos = position
	var tween = create_tween()
	tween.tween_property(self, "position", original_pos + Vector2(2, 0), 0.04)
	tween.tween_property(self, "position", original_pos - Vector2(2, 0), 0.04)
	tween.tween_property(self, "position", original_pos + Vector2(1, 0), 0.04)
	tween.tween_property(self, "position", original_pos, 0.04)

func spawn_harvest_particles():
	harvest_particles.emitting = true
	var timer = get_tree().create_timer(0.3)
	timer.timeout.connect(func(): harvest_particles.emitting = false)

func _deplete():
	is_dead = true
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.3)
	tween.tween_callback(func(): 
		sprite.visible = false
		sprite.scale = Vector2.ONE
		collision.set_deferred("disabled", true)
	)
	respawn_timer.start()
	depleted.emit()

func check_depleted() -> bool:
	return is_dead

func _on_respawn():
	is_dead = false
	current_hp = max_hp
	sprite.visible = true
	sprite.modulate = Color.WHITE
	collision.set_deferred("disabled", false)
	sprite.scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.4)
