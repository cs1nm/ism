extends CharacterBody2D

@export var building_type: String = "base"

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $Shadow
@onready var interaction_area: Area2D = $InteractionArea
@onready var label: Label = $InteractLabel
@onready var glow: Sprite2D = $Glow

var player_nearby: bool = false
var glow_time: float = 0.0

signal sell_triggered()
signal upgrade_requested(type: String)

func _ready():
	add_to_group("base")
	label.visible = false
	if glow:
		glow.visible = false
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _process(delta):
	if player_nearby:
		label.visible = true
		if building_type == "base":
			label.text = "SELL RESOURCES"
		elif building_type == "shop":
			label.text = "UPGRADES"
		
		# Pulsing glow effect
		if glow:
			glow.visible = true
			glow_time += delta * 3.0
			glow.modulate.a = 0.3 + sin(glow_time) * 0.2
	else:
		label.visible = false
		if glow:
			glow.visible = false

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		# Scale up animation
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(sprite, "scale", Vector2(1.05, 1.05), 0.2)

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		label.visible = false
		# Scale back
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite, "scale", Vector2.ONE, 0.2)
