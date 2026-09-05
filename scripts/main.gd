extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var ui: CanvasLayer = $UI
@onready var world_tiles: Node2D = $WorldTiles
@onready var resources_container: Node2D = $Resources
@onready var buildings_container: Node2D = $Buildings

# Island parameters
var island_radius: float = 400.0
var tile_size: float = 64.0

func _ready():
	add_to_group("world")
	ui.set_player(player)
	_add_player_extras()
	_generate_island()
	_spawn_initial_resources()
	_spawn_buildings()
	player.add_to_group("player")
	_spawn_ambient_particles()

func _add_player_extras():
	# Add shadow
	var shadow = Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = _create_shadow_texture(24, 10)
	shadow.position = Vector2(0, 20)
	shadow.z_index = -1
	player.add_child(shadow)
	player.move_child(shadow, 0)  # Behind sprite
	
	# Add dust particles
	var dust = GPUParticles2D.new()
	dust.name = "DustParticles"
	dust.amount = 8
	dust.lifetime = 0.6
	dust.emitting = false
	dust.position = Vector2(0, 20)
	var dust_mat = ParticleProcessMaterial.new()
	dust_mat.direction = Vector3(0, -1, 0)
	dust_mat.spread = 30.0
	dust_mat.initial_velocity_min = 15.0
	dust_mat.initial_velocity_max = 30.0
	dust_mat.gravity = Vector3(0, 40, 0)
	dust_mat.scale_min = 0.5
	dust_mat.scale_max = 1.0
	dust_mat.color = Color(0.8, 0.75, 0.6, 0.6)
	dust.process_material = dust_mat
	player.add_child(dust)
	
	# Tell player script about these nodes
	player.setup_extras(shadow, dust)

func _spawn_ambient_particles():
	# Floating leaves/pollen
	var ambient = GPUParticles2D.new()
	ambient.name = "AmbientParticles"
	ambient.amount = 20
	ambient.lifetime = 6.0
	ambient.emitting = true
	ambient.position = Vector2(0, 0)
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(1, 0.5, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 5.0
	mat.initial_velocity_max = 15.0
	mat.gravity = Vector3(0, 10, 0)
	mat.scale_min = 0.3
	mat.scale_max = 0.8
	mat.color = Color(0.9, 0.85, 0.4, 0.4)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(300, 200, 0)
	ambient.process_material = mat
	# Attach to player so particles follow camera
	player.add_child(ambient)
	player.move_child(ambient, 0)

func _generate_island():
	var tiles_data: Array = []
	var radius_cells = int(island_radius / tile_size)
	
	for x in range(-radius_cells - 3, radius_cells + 4):
		for y in range(-radius_cells - 3, radius_cells + 4):
			var dist = Vector2(x, y).length()
			var pos = Vector2(x * tile_size, y * tile_size)
			if dist <= radius_cells:
				if dist > radius_cells - 1.5:
					tiles_data.append([pos, 2])  # sand
				else:
					tiles_data.append([pos, 0])  # grass
			elif dist <= radius_cells + 3:
				tiles_data.append([pos, 1])  # water
	
	world_tiles.set_tiles(tiles_data)

func _spawn_initial_resources():
	for i in range(8):
		_spawn_resource("tree", _random_island_pos())
	for i in range(6):
		_spawn_resource("rock", _random_island_pos())
	# Gold only from location 2+
	# for i in range(3):
	# 	_spawn_resource("gold", _random_island_pos())

func _spawn_resource(type: String, pos: Vector2):
	# Avoid spawning on buildings
	if pos.distance_to(Vector2(0, 50)) < 100 or pos.distance_to(Vector2(200, 50)) < 100:
		pos = _random_island_pos()
	
	var node = CharacterBody2D.new()
	node.position = pos
	node.add_to_group("resources")
	
	var script_res = load("res://scripts/resource_node.gd")
	node.set_script(script_res)
	
	# Shadow (behind everything)
	var shadow = Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = _create_shadow_texture(28, 12)
	shadow.position = Vector2(0, 18)
	shadow.z_index = -1
	node.add_child(shadow)
	
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	match type:
		"tree":
			sprite.texture = load("res://assets/sprites/resources/tree.png")
			node.resource_type = "wood"
			node.max_hp = 5
		"rock":
			sprite.texture = load("res://assets/sprites/resources/rock.png")
			node.resource_type = "stone"
			node.max_hp = 8
		"gold":
			sprite.texture = load("res://assets/sprites/resources/gold_ore.png")
			node.resource_type = "gem"
			node.max_hp = 12
	node.add_child(sprite)
	
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape = RectangleShape2D.new()
	shape.size = Vector2(40, 40)
	col.shape = shape
	node.add_child(col)
	node.collision_layer = 2
	node.collision_mask = 0
	
	var timer = Timer.new()
	timer.name = "RespawnTimer"
	timer.one_shot = true
	node.add_child(timer)
	
	# Harvest particles
	var particles = GPUParticles2D.new()
	particles.name = "HarvestParticles"
	particles.amount = 6
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.emitting = false
	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = Vector3(0, -1, 0)
	p_mat.spread = 60.0
	p_mat.initial_velocity_min = 30.0
	p_mat.initial_velocity_max = 60.0
	p_mat.gravity = Vector3(0, 80, 0)
	p_mat.scale_min = 0.3
	p_mat.scale_max = 0.6
	var p_color: Color
	match type:
		"tree":
			p_color = Color(0.4, 0.8, 0.3, 0.8)
		"rock":
			p_color = Color(0.7, 0.7, 0.75, 0.8)
		"gold":
			p_color = Color(1.0, 0.85, 0.0, 0.8)
		_:
			p_color = Color.WHITE
	p_mat.color = p_color
	particles.process_material = p_mat
	node.add_child(particles)
	
	resources_container.add_child(node)

func _spawn_buildings():
	_spawn_building("base", Vector2(0, 50))
	_spawn_building("shop", Vector2(200, 50))

func _spawn_building(type: String, pos: Vector2):
	var node = CharacterBody2D.new()
	node.position = pos
	node.add_to_group("base")
	if type == "shop":
		node.add_to_group("shop")
	
	var script_bld = load("res://scripts/building.gd")
	node.set_script(script_bld)
	node.building_type = type
	
	# Shadow
	var shadow = Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = _create_shadow_texture(40, 16)
	shadow.position = Vector2(0, 30)
	shadow.z_index = -1
	node.add_child(shadow)
	
	# Glow (for interaction feedback)
	var glow_sprite = Sprite2D.new()
	glow_sprite.name = "Glow"
	glow_sprite.texture = _create_glow_texture()
	glow_sprite.position = Vector2(0, 0)
	glow_sprite.z_index = -1
	glow_sprite.visible = false
	node.add_child(glow_sprite)
	
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	if type == "base":
		sprite.texture = load("res://assets/sprites/buildings/base.png")
	else:
		sprite.texture = load("res://assets/sprites/buildings/shop.png")
	node.add_child(sprite)
	
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape = RectangleShape2D.new()
	shape.size = Vector2(60, 60)
	col.shape = shape
	node.add_child(col)
	node.collision_layer = 4
	node.collision_mask = 0
	
	var area = Area2D.new()
	area.name = "InteractionArea"
	area.collision_layer = 0
	area.collision_mask = 1
	var area_col = CollisionShape2D.new()
	var area_shape = CircleShape2D.new()
	area_shape.radius = 80.0
	area_col.shape = area_shape
	area.add_child(area_col)
	node.add_child(area)
	
	var label = Label.new()
	label.name = "InteractLabel"
	label.position = Vector2(-60, -70)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	node.add_child(label)
	
	buildings_container.add_child(node)

func _random_island_pos() -> Vector2:
	var angle = randf() * TAU
	var dist = randf() * (island_radius - 100)
	return Vector2(cos(angle), sin(angle)) * dist

func expand_island():
	island_radius += 64.0 * 3
	_generate_island()
	for i in range(3):
		_spawn_resource("tree", _random_island_pos())
	for i in range(2):
		_spawn_resource("rock", _random_island_pos())
	_spawn_resource("gold", _random_island_pos())
	_show_expand_effect()

func _show_expand_effect():
	# Flash effect when island expands
	var flash = ColorRect.new()
	flash.color = Color(1, 1, 0.8, 0.3)
	flash.size = Vector2(2000, 2000)
	flash.position = player.position - Vector2(1000, 1000)
	add_child(flash)
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)

# ===== TEXTURE HELPERS =====
func _create_shadow_texture(w: int, h: int) -> ImageTexture:
	var img = Image.create(w * 2, h * 2, false, Image.FORMAT_RGBA8)
	var center = Vector2(w, h)
	for x in range(w * 2):
		for y in range(h * 2):
			var dist = Vector2(x - w, y - h) / Vector2(w, h)
			var len = dist.length()
			if len < 1.0:
				var alpha = int(80 * (1.0 - len))
				img.set_pixel(x, y, Color(0, 0, 0, alpha / 255.0))
	return ImageTexture.create_from_image(img)

func _create_glow_texture() -> ImageTexture:
	var size = 120
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = size / 2
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x - center, y - center).length() / (size / 2.0)
			if dist < 1.0:
				var alpha = int(60 * (1.0 - dist * dist))
				img.set_pixel(x, y, Color(1, 0.9, 0.5, alpha / 255.0))
	return ImageTexture.create_from_image(img)
