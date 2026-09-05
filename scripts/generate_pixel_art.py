#!/usr/bin/env python3
"""Generate Terraria-style pixel art assets for Island Idle"""

from PIL import Image, ImageDraw
import os

BASE = "/home/user/arcade_idle/assets/sprites"

def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, 'PNG')
    print(f"✓ {os.path.basename(path)}")

def draw_pixel_outline(draw, x, y, color, outline_color=(30, 30, 30)):
    """Draw a pixel with outline"""
    draw.rectangle([x-1, y-1, x+1, y+1], fill=outline_color)
    draw.point((x, y), fill=color)

# ===== PLAYER (32x48) - Terraria-style character =====
def make_player():
    img = Image.new('RGBA', (32, 48), (0, 0, 0, 0))
    pixels = img.load()
    
    # Helper to set pixel
    def px(x, y, color):
        if 0 <= x < 32 and 0 <= y < 48:
            pixels[x, y] = color
    
    outline = (30, 30, 30, 255)
    skin = (255, 220, 185, 255)
    skin_dark = (220, 180, 140, 255)
    hair = (101, 67, 33, 255)
    tunic = (70, 130, 180, 255)
    tunic_dark = (50, 100, 140, 255)
    tunic_light = (90, 150, 200, 255)
    boots = (80, 60, 40, 255)
    backpack = (139, 90, 43, 255)
    backpack_dark = (100, 60, 20, 255)
    
    # Hair (top)
    for x in range(12, 20):
        px(x, 6, hair)
        px(x, 7, hair)
    for x in range(11, 21):
        px(x, 8, hair)
        px(x, 9, hair)
    
    # Head
    for y in range(10, 16):
        for x in range(12, 20):
            px(x, y, skin)
    # Face details
    px(14, 12, (40, 40, 40, 255))  # Left eye
    px(17, 12, (40, 40, 40, 255))  # Right eye
    px(15, 14, (200, 100, 80, 255))  # Mouth
    
    # Body (tunic)
    for y in range(16, 28):
        for x in range(11, 21):
            if y < 20:
                px(x, y, tunic)
            elif y < 24:
                px(x, y, tunic_dark if x < 16 else tunic)
            else:
                px(x, y, tunic_dark)
    # Tunic shading
    for x in range(11, 21):
        px(x, 16, tunic_light)
    
    # Backpack
    for y in range(18, 26):
        for x in range(19, 23):
            px(x, y, backpack)
    for y in range(19, 25):
        for x in range(20, 22):
            px(x, y, backpack_dark)
    
    # Arms
    for y in range(18, 24):
        px(10, y, skin)
        px(21, y, skin)
    px(10, 24, skin_dark)
    px(21, 24, skin_dark)
    
    # Legs
    for y in range(28, 38):
        px(13, y, tunic_dark)
        px(14, y, tunic_dark)
        px(17, y, tunic_dark)
        px(18, y, tunic_dark)
    
    # Boots
    for y in range(38, 42):
        for x in range(12, 16):
            px(x, y, boots)
        for x in range(16, 20):
            px(x, y, boots)
    # Boot soles
    for x in range(11, 16):
        px(x, 42, outline)
    for x in range(16, 21):
        px(x, 42, outline)
    
    # Outline
    for y in range(6, 43):
        for x in range(10, 24):
            if pixels[x, y][3] > 0:
                # Check neighbors
                if x > 0 and pixels[x-1, y][3] == 0:
                    pass  # Left edge - already has outline
                if x < 31 and pixels[x+1, y][3] == 0:
                    pass  # Right edge
    
    save(img, f"{BASE}/player/player.png")

make_player()

# ===== TREE (32x48) - Terraria-style tree =====
def make_tree():
    img = Image.new('RGBA', (32, 48), (0, 0, 0, 0))
    pixels = img.load()
    
    def px(x, y, color):
        if 0 <= x < 32 and 0 <= y < 48:
            pixels[x, y] = color
    
    outline = (30, 30, 30, 255)
    trunk = (101, 67, 33, 255)
    trunk_dark = (80, 50, 20, 255)
    trunk_light = (120, 80, 40, 255)
    leaves = (40, 130, 50, 255)
    leaves_dark = (30, 100, 35, 255)
    leaves_light = (60, 160, 70, 255)
    
    # Trunk
    for y in range(30, 46):
        for x in range(14, 18):
            if x == 14 or x == 17:
                px(x, y, trunk_dark)
            else:
                px(x, y, trunk)
    # Trunk details
    px(15, 32, trunk_light)
    px(16, 36, trunk_light)
    px(15, 40, trunk_light)
    
    # Leaves (layered circles)
    # Bottom layer
    for y in range(20, 32):
        for x in range(8, 24):
            dist = ((x - 16) ** 2 + (y - 26) ** 2) ** 0.5
            if dist < 8:
                px(x, y, leaves_dark)
    
    # Middle layer
    for y in range(14, 28):
        for x in range(6, 26):
            dist = ((x - 16) ** 2 + (y - 21) ** 2) ** 0.5
            if dist < 10:
                px(x, y, leaves)
    
    # Top layer
    for y in range(8, 22):
        for x in range(10, 22):
            dist = ((x - 16) ** 2 + (y - 15) ** 2) ** 0.5
            if dist < 6:
                px(x, y, leaves_light)
    
    # Highlights
    px(12, 12, (80, 180, 90, 255))
    px(18, 14, (80, 180, 90, 255))
    px(14, 18, (80, 180, 90, 255))
    
    save(img, f"{BASE}/resources/tree.png")

make_tree()

# ===== ROCK (32x32) - Terraria-style stone =====
def make_rock():
    img = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    pixels = img.load()
    
    def px(x, y, color):
        if 0 <= x < 32 and 0 <= y < 32:
            pixels[x, y] = color
    
    outline = (30, 30, 30, 255)
    stone = (140, 140, 150, 255)
    stone_dark = (110, 110, 120, 255)
    stone_light = (170, 170, 180, 255)
    stone_highlight = (200, 200, 210, 255)
    
    # Main rock shape
    for y in range(8, 28):
        for x in range(6, 26):
            # Irregular shape
            if y < 12 and (x < 10 or x > 22):
                continue
            if y > 24 and (x < 8 or x > 24):
                continue
            
            # Shading based on position
            if y < 14 and x < 16:
                px(x, y, stone_light)
            elif y > 20 or x > 20:
                px(x, y, stone_dark)
            else:
                px(x, y, stone)
    
    # Highlights
    px(10, 12, stone_highlight)
    px(11, 13, stone_highlight)
    px(14, 11, stone_highlight)
    
    # Cracks
    for i in range(3):
        px(12 + i * 4, 16 + i, outline)
    
    save(img, f"{BASE}/resources/rock.png")

make_rock()

# ===== BASE BUILDING (48x48) - Terraria-style house =====
def make_base():
    img = Image.new('RGBA', (48, 48), (0, 0, 0, 0))
    pixels = img.load()
    
    def px(x, y, color):
        if 0 <= x < 48 and 0 <= y < 48:
            pixels[x, y] = color
    
    outline = (30, 30, 30, 255)
    wood = (160, 120, 70, 255)
    wood_dark = (120, 80, 40, 255)
    wood_light = (180, 140, 90, 255)
    roof = (180, 60, 40, 255)
    roof_dark = (140, 40, 25, 255)
    roof_light = (200, 80, 50, 255)
    window = (180, 220, 255, 255)
    door = (100, 60, 30, 255)
    
    # Foundation/walls
    for y in range(24, 44):
        for x in range(8, 40):
            if x < 12 or x > 36:
                px(x, y, wood_dark)
            else:
                px(x, y, wood)
    
    # Wall details
    for y in range(24, 44, 4):
        for x in range(8, 40):
            px(x, y, wood_dark)
    
    # Roof
    for y in range(10, 26):
        width = 24 - (y - 10) * 1.5
        for x in range(int(24 - width), int(24 + width)):
            if y < 14:
                px(x, y, roof_light)
            elif y < 20:
                px(x, y, roof)
            else:
                px(x, y, roof_dark)
    
    # Roof tiles
    for y in range(12, 26, 3):
        for x in range(12, 36, 2):
            px(x, y, roof_dark)
    
    # Door
    for y in range(30, 44):
        for x in range(20, 28):
            px(x, y, door)
    px(26, 36, (80, 50, 20, 255))  # Doorknob
    
    # Windows
    for y in range(28, 34):
        for x in range(12, 18):
            px(x, y, window)
        for x in range(30, 36):
            px(x, y, window)
    # Window frames
    for x in range(12, 18):
        px(x, 31, outline)
    for y in range(28, 34):
        px(15, y, outline)
    
    for x in range(30, 36):
        px(x, 31, outline)
    for y in range(28, 34):
        px(33, y, outline)
    
    save(img, f"{BASE}/buildings/base.png")

make_base()

# ===== SHOP (48x48) - Terraria-style market =====
def make_shop():
    img = Image.new('RGBA', (48, 48), (0, 0, 0, 0))
    pixels = img.load()
    
    def px(x, y, color):
        if 0 <= x < 48 and 0 <= y < 48:
            pixels[x, y] = color
    
    outline = (30, 30, 30, 255)
    wood = (180, 160, 110, 255)
    wood_dark = (140, 120, 70, 255)
    awning_red = (220, 60, 60, 255)
    awning_white = (255, 255, 255, 255)
    counter = (160, 120, 60, 255)
    
    # Base structure
    for y in range(24, 44):
        for x in range(10, 38):
            px(x, y, wood)
    for y in range(24, 44, 3):
        for x in range(10, 38):
            px(x, y, wood_dark)
    
    # Awning (striped)
    for y in range(16, 26):
        for x in range(8, 40):
            if (x // 4) % 2 == 0:
                px(x, y, awning_red)
            else:
                px(x, y, awning_white)
    
    # Counter
    for y in range(32, 40):
        for x in range(14, 34):
            px(x, y, counter)
    
    # Items on counter
    # Gold coins
    for y in range(28, 32):
        for x in range(16, 20):
            px(x, y, (255, 215, 0, 255))
    # Stone
    for y in range(28, 32):
        for x in range(22, 26):
            px(x, y, (150, 150, 160, 255))
    # Wood
    for y in range(28, 32):
        for x in range(28, 32):
            px(x, y, (120, 80, 40, 255))
    
    # Poles
    for y in range(16, 44):
        px(9, y, wood_dark)
        px(10, y, wood_dark)
        px(37, y, wood_dark)
        px(38, y, wood_dark)
    
    save(img, f"{BASE}/buildings/shop.png")

make_shop()

# ===== GROUND TILE (16x16) - Terraria-style grass =====
def make_ground():
    img = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
    pixels = img.load()
    
    def px(x, y, color):
        if 0 <= x < 16 and 0 <= y < 16:
            pixels[x, y] = color
    
    grass = (106, 170, 80, 255)
    grass_dark = (90, 150, 65, 255)
    grass_light = (120, 185, 95, 255)
    
    # Base grass
    for y in range(16):
        for x in range(16):
            px(x, y, grass)
    
    # Variation
    import random
    random.seed(42)
    for _ in range(20):
        x = random.randint(0, 15)
        y = random.randint(0, 15)
        px(x, y, grass_dark if random.random() > 0.5 else grass_light)
    
    # Grass blades
    for _ in range(8):
        x = random.randint(1, 14)
        y = random.randint(1, 14)
        px(x, y, grass_light)
        px(x, y-1, grass_light)
    
    save(img, f"{BASE}/world/ground.png")

make_ground()

# ===== WATER TILE (16x16) - Terraria-style water =====
def make_water():
    img = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
    pixels = img.load()
    
    def px(x, y, color):
        if 0 <= x < 16 and 0 <= y < 16:
            pixels[x, y] = color
    
    water = (64, 140, 200, 255)
    water_dark = (50, 120, 180, 255)
    water_light = (100, 170, 220, 255)
    
    # Base water
    for y in range(16):
        for x in range(16):
            px(x, y, water)
    
    # Waves
    for y in range(0, 16, 4):
        for x in range(2, 14, 3):
            px(x, y, water_light)
            px(x+1, y, water_light)
    
    # Darker areas
    for y in range(2, 16, 4):
        for x in range(0, 16, 4):
            px(x, y, water_dark)
    
    save(img, f"{BASE}/world/water.png")

make_water()

# ===== SAND TILE (16x16) - Terraria-style sand =====
def make_sand():
    img = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
    pixels = img.load()
    
    def px(x, y, color):
        if 0 <= x < 16 and 0 <= y < 16:
            pixels[x, y] = color
    
    sand = (230, 210, 150, 255)
    sand_dark = (210, 190, 130, 255)
    sand_light = (240, 220, 160, 255)
    
    # Base sand
    for y in range(16):
        for x in range(16):
            px(x, y, sand)
    
    # Variation
    import random
    random.seed(77)
    for _ in range(30):
        x = random.randint(0, 15)
        y = random.randint(0, 15)
        px(x, y, sand_dark if random.random() > 0.5 else sand_light)
    
    save(img, f"{BASE}/world/sand.png")

make_sand()

print("\n✅ All Terraria-style pixel art assets generated!")
