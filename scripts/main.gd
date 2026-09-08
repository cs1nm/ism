extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var ui: CanvasLayer = $UI
@onready var crafting_ui: CanvasLayer = $CraftingUI
@onready var world_tiles: Node2D = $WorldTiles
@onready var resources_container: Node2D = $Resources
@onready var enemies_container: Node2D = $Buildings
@onready var decor_container: Node2D = $Decor

var island_radius: float = 400.0
var tile_size: float = 16.0

# Decoration textures
var tex_bush: Texture2D
var tex_flower: Texture2D
var tex_flower2: Texture2D
var tex_mushroom: Texture2D
var tex_stump: Texture2D
var tex_small_rock: Texture2D
var tex_fence: Texture2D
var tex_grass_tuft: Texture2D
var tex_path: Texture2D

func _ready():
	add_to_group("world")
	
	# Load decoration textures
	tex_bush = load("res://assets/sprites/decor/bush.png")
	tex_flower = load("res://assets/sprites/decor/flower.png")
	tex_flower2 = load("res://assets/sprites/decor/flower2.png")
	tex_mushroom = load("res://assets/sprites/decor/mushroom.png")
	tex_stump = load("res://assets/sprites/decor/stump.png")
	tex_small_rock = load("res://assets/sprites/decor/small_rock.png")
	tex_fence = load("res://assets/sprites/decor/fence.png")
	tex_grass_tuft = load("res://assets/sprites/decor/grass_tuft.png")
	tex_path = load("res://assets/sprites/world/path.png")
	
	ui.set_player(player)
	crafting_ui.set_player(player)
	_add_player_extras()
	
	# Connect location change signal
	LocationManager.location_changed.connect(_on_location_changed)
	
	# Build the current location
	_build_location()
	
	# Create enemies container
	enemies_container = Node2D.new()
	enemies_container.name = "Enemies"
	add_child(enemies_container)
	
	# Spawn enemies for current location
	_spawn_enemies()
	
	# Create touch joystick
	_setup_joystick()

func _add_player_extras():
	var shadow = Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = _create_shadow_texture(24, 10)
	shadow.position = Vector2(0, 12)
	shadow.z_index = -1
	player.add_child(shadow)
	player.move_child(shadow, 0)
	
	var dust = GPUParticles2D.new()
	dust.name = "DustParticles"
	dust.amount = 8
	dust.lifetime = 0.6
	dust.emitting = false
	dust.position = Vector2(0, 12)
	var dust_mat = ParticleProcessMaterial.new()
	dust_mat.direction = Vector3(0, -1, 0)
	dust_mat.spread = 30.0
	dust_mat.initial_velocity_min = 15.0
	dust_mat.initial_velocity_max = 30.0
	dust_mat.gravity = Vector3(0, 40, 0)
	dust_mat.scale_min = 0.5
	dust_mat.scale_max = 1.0
	dust_mat.color = Color(0.6, 0.55, 0.4, 0.5)
	dust.process_material = dust_mat
	player.add_child(dust)
	player.setup_extras(shadow, dust)

func _spawn_ambient_particles():
	var ambient = GPUParticles2D.new()
	ambient.name = "AmbientParticles"
	ambient.amount = 15
	ambient.lifetime = 8.0
	ambient.emitting = true
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(1, 0.3, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 10.0
	mat.gravity = Vector3(0, 5, 0)
	mat.scale_min = 0.2
	mat.scale_max = 0.5
	mat.color = Color(0.7, 0.8, 0.6, 0.3)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(250, 180, 0)
	ambient.process_material = mat
	player.add_child(ambient)
	player.move_child(ambient, 0)

func _build_location():
	var loc_data = LocationManager.get_current_location_data()
	
	# Update background color
	$Background.color = loc_data.bg_color
	
	# Clear existing world
	_clear_world()
	
	# Generate new world
	_generate_island(loc_data)
	_spawn_path()
	if LocationManager.current_location == "starter":
		_spawn_fence_around_base()
		_spawn_decorations()
	_spawn_resources_from_data(loc_data)
	_spawn_buildings()
	_spawn_portal()
	
	player.add_to_group("player")
	_spawn_ambient_particles()
	player.position = Vector2(0, 80)

func _clear_world():
	# Remove all world tiles
	world_tiles.set_tiles([])
	# Remove resources
	for child in resources_container.get_children():
		child.queue_free()
	# Remove buildings
	for child in buildings_container.get_children():
		child.queue_free()
	# Remove decorations
	for child in decor_container.get_children():
		child.queue_free()
	# Remove enemies
	if enemies_container:
		for child in enemies_container.get_children():
			child.queue_free()

func _on_location_changed(new_location: String):
	_build_location()

func _setup_joystick():
	# Create touch joystick for mobile
	var joystick_script = load("res://scripts/touch_joystick.gd")
	var joystick = Control.new()
	joystick.set_script(joystick_script)
	joystick.name = "TouchJoystick"
	joystick.z_index = 1000
	
	# Add to UI CanvasLayer
	var ui_layer = $UI
	ui_layer.add_child(joystick)
	
	# Connect joystick direction to player
	joystick.connect("draw", func():
		player.joystick_direction = joystick.direction
	)
	
	# Use process to continuously update direction
	var update_script = GDScript.new()
	update_script.source_code = """extends Node
var joystick: Control
var player_ref: CharacterBody2D

func _process(delta):
	if joystick and player_ref:
		player_ref.joystick_direction = joystick.direction
"""
	update_script.reload()
	var updater = Node.new()
	updater.set_script(update_script)
	updater.name = "JoystickUpdater"
	add_child(updater)
	updater.joystick = joystick
	updater.player_ref = player

func _generate_island(loc_data: Dictionary):
	var tiles_data: Array = []
	var radius_cells = int(island_radius / tile_size)
	
	# Load location-specific textures
	var tex_ground = load(loc_data.ground_tile)
	var tex_water = load(loc_data.water_tile)
	var tex_sand = load(loc_data.sand_tile)
	
	# Update world renderer textures
	world_tiles.set_textures(tex_ground, tex_water, tex_sand)
	
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

func _spawn_path():
	# Path from base to shop
	var base_pos = Vector2(0, 50)
	var shop_pos = Vector2(200, 50)
	var dir = (shop_pos - base_pos).normalized()
	var dist = base_pos.distance_to(shop_pos)
	var steps = int(dist / tile_size)
	
	for i in range(steps + 1):
		var pos = base_pos + dir * i * tile_size
		_place_decor_sprite(tex_path, pos, -5)
		# Add some width to the path
		var perp = Vector2(-dir.y, dir.x)
		_place_decor_sprite(tex_path, pos + perp * tile_size, -5)
		_place_decor_sprite(tex_path, pos - perp * tile_size, -5)

func _spawn_fence_around_base():
	var base_pos = Vector2(0, 50)
	var fence_radius = 80.0
	var fence_spacing = 16.0
	var num_posts = int(TAU * fence_radius / fence_spacing)
	
	for i in range(num_posts):
		var angle = float(i) / float(num_posts) * TAU
		var pos = base_pos + Vector2(cos(angle), sin(angle)) * fence_radius
		
		# Leave gap for entrance (south side)
		if angle > 1.3 and angle < 1.85:
			continue
		
		_place_decor_sprite(tex_fence, pos, 2)

func _spawn_decorations():
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345
	
	var decor_types = [
		{"tex": tex_bush, "weight": 20, "z": 0},
		{"tex": tex_flower, "weight": 25, "z": -1},
		{"tex": tex_flower2, "weight": 20, "z": -1},
		{"tex": tex_mushroom, "weight": 8, "z": -1},
		{"tex": tex_stump, "weight": 5, "z": 0},
		{"tex": tex_small_rock, "weight": 15, "z": -2},
		{"tex": tex_grass_tuft, "weight": 30, "z": -2},
	]
	
	# Total weight
	var total_weight = 0
	for d in decor_types:
		total_weight += d.weight
	
	# Spawn ~60 decorations
	for i in range(60):
		var pos = _random_island_pos_rng(rng)
		
		# Don't spawn too close to buildings
		if pos.distance_to(Vector2(0, 50)) < 90:
			continue
		if pos.distance_to(Vector2(200, 50)) < 60:
			continue
		# Don't spawn on path
		if abs(pos.y - 50) < 24 and pos.x > -10 and pos.x < 210:
			continue
		
		# Pick random decoration type
		var roll = rng.randi() % total_weight
		var cumul = 0
		var chosen = decor_types[0]
		for d in decor_types:
			cumul += d.weight
			if roll < cumul:
				chosen = d
				break
		
		_place_decor_sprite(chosen.tex, pos, chosen.z)

func _place_decor_sprite(tex: Texture2D, pos: Vector2, z_offset: int):
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.position = pos
	sprite.z_index = z_offset
	decor_container.add_child(sprite)

func _spawn_initial_resources():
	var loc_data = LocationManager.get_current_location_data()
	_spawn_resources_from_data(loc_data)

func _spawn_resources_from_data(loc_data: Dictionary):
	for res_def in loc_data.resources:
		for i in range(res_def.count):
			_spawn_resource_from_def(res_def, _random_island_pos())

func _spawn_resource_from_def(res_def: Dictionary, pos: Vector2):
	if pos.distance_to(Vector2(0, 50)) < 100 or pos.distance_to(Vector2(200, 50)) < 100:
		pos = _random_island_pos()
	
	var node = CharacterBody2D.new()
	node.position = pos
	node.add_to_group("resources")
	
	var script_res = load("res://scripts/resource_node.gd")
	node.set_script(script_res)
	node.resource_type = res_def.resource_type
	node.max_hp = res_def.hp
	
	# Shadow
	var shadow = Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = _create_shadow_texture(28, 12)
	shadow.position = Vector2(0, 18)
	shadow.z_index = -1
	node.add_child(shadow)
	
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = load(res_def.texture)
	node.add_child(sprite)
	
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape = RectangleShape2D.new()
	shape.size = Vector2(18, 18)
	col.shape = shape
	node.add_child(col)
	node.collision_layer = 2
	node.collision_mask = 0
	
	var timer = Timer.new()
	timer.name = "RespawnTimer"
	timer.one_shot = true
	node.add_child(timer)
	
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
	match res_def.resource_type:
		"wood": p_color = Color(0.4, 0.8, 0.3, 0.8)
		"stone": p_color = Color(0.7, 0.7, 0.75, 0.8)
		"gem": p_color = Color(0.36, 0.88, 0.93, 0.8)
		_: p_color = Color.WHITE
	p_mat.color = p_color
	particles.process_material = p_mat
	node.add_child(particles)
	
	resources_container.add_child(node)

# Old _spawn_resource used for expand - now uses location data
func _spawn_resource(type: String, pos: Vector2):
	# Legacy - used by expand_island
	var res_def = {}
	match type:
		"tree":
			res_def = {"texture": "res://assets/sprites/resources/tree.png", "resource_type": "wood", "hp": 5}
		"rock":
			res_def = {"texture": "res://assets/sprites/resources/rock.png", "resource_type": "stone", "hp": 8}
		"gold":
			res_def = {"texture": "res://assets/sprites/resources/gold_ore.png", "resource_type": "gem", "hp": 12}
	if not res_def.is_empty():
		_spawn_resource_from_def(res_def, pos)

func _spawn_buildings():
	_spawn_building("base", Vector2(0, 50))
	_spawn_building("shop", Vector2(200, 50))
	_spawn_crafting_station("workbench", Vector2(-120, 50))
	_spawn_crafting_station("furnace", Vector2(-120, -40))
	_spawn_crafting_station("forge", Vector2(200, -40))

func _spawn_portal():
	var node = CharacterBody2D.new()
	node.position = Vector2(100, -60)
	node.add_to_group("base")
	node.add_to_group("portal")
	node.set_meta("station_type", "portal")
	
	var script_bld = load("res://scripts/building.gd")
	node.set_script(script_bld)
	node.building_type = "portal"
	
	# Shadow
	var shadow = Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = _create_shadow_texture(30, 12)
	shadow.position = Vector2(0, 20)
	shadow.z_index = -1
	node.add_child(shadow)
	
	# Glow
	var glow_sprite = Sprite2D.new()
	glow_sprite.name = "Glow"
	glow_sprite.texture = _create_glow_texture()
	glow_sprite.position = Vector2(0, 0)
	glow_sprite.z_index = -1
	glow_sprite.visible = false
	node.add_child(glow_sprite)
	
	# Sprite
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = load("res://assets/sprites/buildings/portal.png")
	node.add_child(sprite)
	
	# Collision
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape = RectangleShape2D.new()
	shape.size = Vector2(24, 24)
	col.shape = shape
	node.add_child(col)
	node.collision_layer = 4
	node.collision_mask = 0
	
	# Interaction area
	var area = Area2D.new()
	area.name = "InteractionArea"
	area.collision_layer = 0
	area.collision_mask = 1
	var area_col = CollisionShape2D.new()
	var area_shape = CircleShape2D.new()
	area_shape.radius = 60.0
	area_col.shape = area_shape
	area.add_child(area_col)
	node.add_child(area)
	
	# Label
	var label = Label.new()
	label.name = "InteractLabel"
	label.position = Vector2(-40, -50)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.36, 0.88, 0.93))
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	node.add_child(label)
	
	buildings_container.add_child(node)

func _spawn_building(type: String, pos: Vector2):
	var node = CharacterBody2D.new()
	node.position = pos
	node.add_to_group("base")
	if type == "shop":
		node.add_to_group("shop")
	
	var script_bld = load("res://scripts/building.gd")
	node.set_script(script_bld)
	node.building_type = type
	
	var shadow = Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = _create_shadow_texture(40, 16)
	shadow.position = Vector2(0, 20)
	shadow.z_index = -1
	node.add_child(shadow)
	
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
	shape.size = Vector2(30, 30)
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
	label.position = Vector2(-60, -50)
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

func _random_island_pos_rng(rng: RandomNumberGenerator) -> Vector2:
	var angle = rng.randf() * TAU
	var dist = rng.randf() * (island_radius - 100)
	return Vector2(cos(angle), sin(angle)) * dist

func expand_island():
	island_radius += 64.0 * 3
	_generate_island()
	_spawn_path()
	for i in range(3):
		_spawn_resource("tree", _random_island_pos())
	for i in range(2):
		_spawn_resource("rock", _random_island_pos())
	_spawn_resource("gold", _random_island_pos())
	_show_expand_effect()

func _show_expand_effect():
	var flash = ColorRect.new()
	flash.color = Color(0.36, 0.88, 0.93, 0.2)
	flash.size = Vector2(2000, 2000)
	flash.position = player.position - Vector2(1000, 1000)
	add_child(flash)
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)

func _spawn_crafting_station(station_type: String, pos: Vector2):
	var node = CharacterBody2D.new()
	node.position = pos
	node.add_to_group("base")
	node.add_to_group("crafting_station")
	node.set_meta("station_type", station_type)
	
	var script_bld = load("res://scripts/building.gd")
	node.set_script(script_bld)
	node.building_type = station_type
	
	# Shadow
	var shadow = Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = _create_shadow_texture(30, 12)
	shadow.position = Vector2(0, 16)
	shadow.z_index = -1
	node.add_child(shadow)
	
	# Glow
	var glow_sprite = Sprite2D.new()
	glow_sprite.name = "Glow"
	glow_sprite.texture = _create_glow_texture()
	glow_sprite.position = Vector2(0, 0)
	glow_sprite.z_index = -1
	glow_sprite.visible = false
	node.add_child(glow_sprite)
	
	# Sprite
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	match station_type:
		"workbench":
			sprite.texture = load("res://assets/sprites/buildings/workbench.png")
		"furnace":
			sprite.texture = load("res://assets/sprites/buildings/furnace.png")
		"forge":
			sprite.texture = load("res://assets/sprites/buildings/forge.png")
	node.add_child(sprite)
	
	# Collision
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape = RectangleShape2D.new()
	shape.size = Vector2(24, 24)
	col.shape = shape
	node.add_child(col)
	node.collision_layer = 4
	node.collision_mask = 0
	
	# Interaction area
	var area = Area2D.new()
	area.name = "InteractionArea"
	area.collision_layer = 0
	area.collision_mask = 1
	var area_col = CollisionShape2D.new()
	var area_shape = CircleShape2D.new()
	area_shape.radius = 60.0
	area_col.shape = area_shape
	area.add_child(area_col)
	node.add_child(area)
	
	# Label
	var label = Label.new()
	label.name = "InteractLabel"
	label.position = Vector2(-50, -40)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	node.add_child(label)
	
	buildings_container.add_child(node)

func _create_shadow_texture(w: int, h: int) -> ImageTexture:
	var img = Image.create(w * 2, h * 2, false, Image.FORMAT_RGBA8)
	for x in range(w * 2):
		for y in range(h * 2):
			var dist = Vector2(float(x - w) / w, float(y - h) / h).length()
			if dist < 1.0:
				var alpha = int(80 * (1.0 - dist))
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
				img.set_pixel(x, y, Color(0.36, 0.88, 0.93, alpha / 255.0))
	return ImageTexture.create_from_image(img)

func _spawn_enemies():
	var loc = LocationManager.current_location
	var enemy_types = []
	var count = 0
	
	match loc:
		"starter":
			enemy_types = ["slime"]
			count = 3
		"ice":
			enemy_types = ["ice_elemental"]
			count = 4
		"volcanic":
			enemy_types = ["fire_elemental"]
			count = 3
		"forest":
			enemy_types = ["forest_spirit"]
			count = 4
	
	for i in range(count):
		var enemy_type = enemy_types[randi() % enemy_types.size()]
		_spawn_enemy(enemy_type, _random_island_pos())

func _spawn_enemy(enemy_type: String, pos: Vector2):
	# Don't spawn near base
	if pos.distance_to(Vector2(0, 50)) < 100:
		pos = _random_island_pos()
	
	var enemy = CharacterBody2D.new()
	enemy.position = pos
	
	var script_enemy = load("res://scripts/enemy.gd")
	enemy.set_script(script_enemy)
	enemy.enemy_type = enemy_type
	
	# Set stats based on type
	match enemy_type:
		"slime":
			enemy.max_hp = 3
			enemy.damage = 1
			enemy.move_speed = 30.0
		"ice_elemental":
			enemy.max_hp = 5
			enemy.damage = 2
			enemy.move_speed = 40.0
		"fire_elemental":
			enemy.max_hp = 8
			enemy.damage = 3
			enemy.move_speed = 45.0
		"forest_spirit":
			enemy.max_hp = 4
			enemy.damage = 2
			enemy.move_speed = 35.0
	
	# Shadow
	var shadow = Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = _create_shadow_texture(20, 8)
	shadow.position = Vector2(0, 12)
	shadow.z_index = -1
	enemy.add_child(shadow)
	
	# Sprite
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = load("res://assets/sprites/enemies/%s.png" % enemy_type)
	enemy.add_child(sprite)
	
	# Collision
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = 10.0
	col.shape = shape
	enemy.add_child(col)
	enemy.collision_layer = 8
	enemy.collision_mask = 0
	
	# Connect death signal
	enemy.enemy_died.connect(_on_enemy_died)
	
	enemies_container.add_child(enemy)

func _on_enemy_died(enemy: CharacterBody2D, drops: Dictionary):
	# Track achievement
	Achievements.on_enemy_killed()
	SoundManager.play_sound("enemy_die")
	
	# Apply drops
	for resource_type in drops:
		var amount = drops[resource_type]
		match resource_type:
			"coins":
				GameData.coins += amount
				GameData.notify_coins_changed()
			"wood", "stone", "gem", "ingot":
				GameData.add_resource(resource_type, amount)
	
	# Floating text
	var text = ""
	for resource_type in drops:
		text += "+%d %s\n" % [drops[resource_type], resource_type.capitalize()]
	
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color.YELLOW)
	label.add_theme_font_size_override("font_size", 14)
	label.position = enemy.global_position + Vector2(-20, -30)
	label.z_index = 100
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 40, 1.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(label.queue_free)
