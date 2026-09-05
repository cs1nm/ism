extends Node2D

# World renderer - draws beautiful island tiles with water animation

var tiles: Array = []
var tile_size: float = 64.0
var time: float = 0.0

func set_tiles(new_tiles: Array):
	tiles = new_tiles
	queue_redraw()

func _process(delta):
	time += delta
	# Redraw every few frames for water animation
	if int(time * 10) % 3 == 0:
		queue_redraw()

func _draw():
	for tile in tiles:
		var pos: Vector2 = tile[0]
		var type: int = tile[1]  # 0=grass, 1=water, 2=sand
		var color: Color
		match type:
			0:  # Grass
				color = Color(0.42, 0.67, 0.31)
				draw_rect(Rect2(pos, Vector2(tile_size, tile_size)), color)
				# Add subtle grass variation
				var noise_val = sin(pos.x * 0.1 + time * 0.5) * cos(pos.y * 0.1)
				var variation = Color(0.45, 0.70, 0.34, 0.3 * abs(noise_val))
				draw_rect(Rect2(pos + Vector2(8, 8), Vector2(tile_size - 16, tile_size - 16)), variation)
				
			1:  # Water
				# Animated water
				var wave = sin(pos.x * 0.05 + time * 2.0) * 0.1 + cos(pos.y * 0.05 + time * 1.5) * 0.1
				var base_blue = 0.55 + wave * 0.15
				color = Color(0.25, base_blue, 0.78)
				draw_rect(Rect2(pos, Vector2(tile_size, tile_size)), color)
				# Water highlights
				var highlight_alpha = 0.2 + sin(time * 3.0 + pos.x * 0.1) * 0.1
				draw_rect(Rect2(pos + Vector2(10, 20), Vector2(20, 3)), Color(0.6, 0.8, 1.0, highlight_alpha))
				draw_rect(Rect2(pos + Vector2(30, 40), Vector2(15, 2)), Color(0.6, 0.8, 1.0, highlight_alpha * 0.7))
				
			2:  # Sand
				color = Color(0.86, 0.78, 0.55)
				draw_rect(Rect2(pos, Vector2(tile_size, tile_size)), color)
				# Sand texture dots
				var noise_val = sin(pos.x * 0.2) * cos(pos.y * 0.2)
				if noise_val > 0:
					draw_rect(Rect2(pos + Vector2(16, 16), Vector2(4, 4)), Color(0.9, 0.82, 0.6, 0.4))
