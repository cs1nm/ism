extends Node2D

# World renderer - uses actual texture sprites for tiles

var tiles: Array = []
var tile_size: float = 16.0
var tile_sprites: Array = []

var tex_grass: Texture2D
var tex_water: Texture2D
var tex_sand: Texture2D

func _ready():
	tex_grass = load("res://assets/sprites/world/ground.png")
	tex_water = load("res://assets/sprites/world/water.png")
	tex_sand = load("res://assets/sprites/world/sand.png")

func set_textures(ground: Texture2D, water: Texture2D, sand: Texture2D):
	tex_grass = ground
	tex_water = water
	tex_sand = sand

func set_tiles(new_tiles: Array):
	tiles = new_tiles
	_rebuild_tiles()

func _rebuild_tiles():
	# Remove old sprites
	for child in get_children():
		child.queue_free()
	tile_sprites.clear()
	
	for tile in tiles:
		var pos: Vector2 = tile[0]
		var type: int = tile[1]
		
		var sprite = Sprite2D.new()
		match type:
			0:
				sprite.texture = tex_grass
			1:
				sprite.texture = tex_water
			2:
				sprite.texture = tex_sand
		
		sprite.position = pos + Vector2(tile_size / 2.0, tile_size / 2.0)
		add_child(sprite)
		tile_sprites.append(sprite)
