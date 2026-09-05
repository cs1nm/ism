extends CharacterBody2D

@export var resource_type: String = "wood"
@export var max_hp: int = 5
@export var respawn_time: float = 15.0

var current_hp: int
var is_dead: bool = false
var sway_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $Shadow
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

func _process(delta):
	if not is_dead:
		# Gentle swaying animation
		sway_time += delta * 2.0
		sprite.rotation = sin(sway_time) * 0.03
		sprite.position.x = sin(sway_time * 0.7) * 1.0

func take_damage(amount: int):
	current_hp -= amount
	_update_visual()
	if current_hp <= 0:
		_deplete()

func _update_visual():
	var ratio = float(current_hp) / float(max_hp)
	sprite.modulate = Color(1, 1, 1, 0.5 + 0.5 * ratio)
	# Shake effect
	var original_pos = position
	var tween = create_tween()
	tween.tween_property(self, "position", original_pos + Vector2(3, 0), 0.05)
	tween.tween_property(self, "position", original_pos - Vector2(3, 0), 0.05)
	tween.tween_property(self, "position", original_pos + Vector2(1, 0), 0.05)
	tween.tween_property(self, "position", original_pos, 0.05)

func spawn_harvest_particles():
	harvest_particles.emitting = true
	# Stop after short burst
	var timer = get_tree().create_timer(0.3)
	timer.timeout.connect(func(): harvest_particles.emitting = false)

func _deplete():
	is_dead = true
	# Fade out animation
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
	# Pop-in animation
	sprite.scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.4)
