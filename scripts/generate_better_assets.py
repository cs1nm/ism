#!/usr/bin/env python3
"""Generate high-quality game assets for Island Idle"""

from PIL import Image, ImageDraw, ImageFilter
import os
import math

BASE = "/home/user/arcade_idle/assets/sprites"

def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, 'PNG')
    print(f"✓ {os.path.basename(path)}")

def add_shadow(img, offset=(3, 3), blur=2):
    """Add drop shadow to sprite"""
    shadow = Image.new('RGBA', img.size, (0, 0, 0, 0))
    for x in range(img.width):
        for y in range(img.height):
            if img.getpixel((x, y))[3] > 128:
                shadow.putpixel((x, y), (0, 0, 0, 100))
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    result = Image.new('RGBA', img.size, (0, 0, 0, 0))
    result.paste(shadow, offset, shadow)
    result.paste(img, (0, 0), img)
    return result

# ===== PLAYER (64x64) - Cute character with backpack =====
def make_player():
    img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # Shadow
    d.ellipse([20, 54, 44, 60], fill=(0, 0, 0, 80))
    
    # Body (blue tunic)
    d.ellipse([22, 28, 42, 50], fill=(70, 130, 180))
    d.ellipse([24, 30, 40, 48], fill=(90, 150, 200))
    
    # Head
    d.ellipse([24, 12, 40, 28], fill=(255, 220, 185))
    d.ellipse([26, 14, 38, 26], fill=(255, 225, 195))
    
    # Hair
    d.ellipse([24, 10, 40, 20], fill=(101, 67, 33))
    d.rectangle([24, 12, 28, 18], fill=(101, 67, 33))
    d.rectangle([36, 12, 40, 18], fill=(101, 67, 33))
    
    # Eyes
    d.ellipse([28, 18, 31, 21], fill=(40, 40, 40))
    d.ellipse([34, 18, 37, 21], fill=(40, 40, 40))
    d.ellipse([29, 19, 30, 20], fill=(255, 255, 255))
    d.ellipse([35, 19, 36, 20], fill=(255, 255, 255))
    
    # Smile
    d.arc([30, 22, 34, 26], 0, 180, fill=(180, 100, 80), width=1)
    
    # Backpack (brown)
    d.rectangle([26, 32, 38, 46], fill=(139, 90, 43))
    d.rectangle([28, 34, 36, 44], fill=(160, 110, 60))
    d.rectangle([30, 36, 34, 40], fill=(120, 70, 30))
    
    # Arms
    d.ellipse([18, 32, 24, 40], fill=(255, 220, 185))
    d.ellipse([40, 32, 46, 40], fill=(255, 220, 185))
    
    # Legs
    d.rectangle([26, 48, 30, 56], fill=(80, 60, 40))
    d.rectangle([34, 48, 38, 56], fill=(80, 60, 40))
    
    save(img, f"{BASE}/player/player.png")

make_player()

# ===== TREE (80x120) - Beautiful stylized tree =====
def make_tree():
    img = Image.new('RGBA', (80, 120), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # Shadow
    d.ellipse([25, 110, 55, 118], fill=(0, 0, 0, 80))
    
    # Trunk
    d.rectangle([34, 70, 46, 115], fill=(101, 67, 33))
    d.rectangle([36, 72, 44, 113], fill=(120, 80, 40))
    
    # Trunk details
    d.line([(38, 80), (38, 90)], fill=(80, 50, 20), width=2)
    d.line([(42, 85), (42, 95)], fill=(80, 50, 20), width=2)
    
    # Foliage layers (back to front)
    # Back layer
    d.ellipse([15, 20, 65, 70], fill=(30, 100, 35))
    # Middle layer
    d.ellipse([10, 10, 70, 65], fill=(40, 130, 50))
    # Front layer
    d.ellipse([20, 5, 60, 55], fill=(60, 160, 70))
    # Highlights
    d.ellipse([25, 15, 45, 35], fill=(80, 180, 90))
    d.ellipse([35, 25, 55, 45], fill=(80, 180, 90))
    
    save(img, f"{BASE}/resources/tree.png")

make_tree()

# ===== ROCK (64x64) - Detailed stone =====
def make_rock():
    img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # Shadow
    d.ellipse([15, 55, 49, 62], fill=(0, 0, 0, 80))
    
    # Main rock shape
    d.polygon([(12, 48), (8, 32), (16, 18), (32, 12), (50, 16), (58, 28), (54, 48), (36, 52)], 
              fill=(130, 130, 140))
    
    # Highlights
    d.polygon([(14, 44), (12, 32), (18, 20), (32, 16), (46, 20), (52, 30), (48, 44)], 
              fill=(150, 150, 160))
    d.polygon([(18, 40), (16, 30), (22, 22), (32, 20), (42, 24), (46, 32), (42, 40)], 
              fill=(170, 170, 180))
    
    # Cracks/details
    d.line([(20, 25), (28, 35)], fill=(100, 100, 110), width=1)
    d.line([(38, 22), (44, 32)], fill=(100, 100, 110), width=1)
    
    save(img, f"{BASE}/resources/rock.png")

make_rock()

# ===== GOLD ORE (64x64) - Rock with gold veins =====
def make_gold_ore():
    img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # Shadow
    d.ellipse([15, 55, 49, 62], fill=(0, 0, 0, 80))
    
    # Main rock
    d.polygon([(12, 48), (8, 32), (16, 18), (32, 12), (50, 16), (58, 28), (54, 48), (36, 52)], 
              fill=(110, 100, 90))
    d.polygon([(14, 44), (12, 32), (18, 20), (32, 16), (46, 20), (52, 30), (48, 44)], 
              fill=(130, 120, 110))
    
    # Gold veins
    d.ellipse([22, 20, 30, 28], fill=(255, 215, 0))
    d.ellipse([24, 22, 28, 26], fill=(255, 235, 80))
    
    d.ellipse([36, 26, 44, 34], fill=(255, 215, 0))
    d.ellipse([38, 28, 42, 32], fill=(255, 235, 80))
    
    d.ellipse([28, 34, 36, 42], fill=(255, 215, 0))
    d.ellipse([30, 36, 34, 40], fill=(255, 235, 80))
    
    # Sparkles
    d.ellipse([25, 23, 27, 25], fill=(255, 255, 200))
    d.ellipse([39, 29, 41, 31], fill=(255, 255, 200))
    
    save(img, f"{BASE}/resources/gold_ore.png")

make_gold_ore()

# ===== BASE BUILDING (96x96) - Cozy house =====
def make_base():
    img = Image.new('RGBA', (96, 96), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # Shadow
    d.ellipse([20, 85, 76, 94], fill=(0, 0, 0, 80))
    
    # Foundation
    d.rectangle([16, 40, 80, 88], fill=(160, 120, 70))
    d.rectangle([18, 42, 78, 86], fill=(180, 140, 80))
    
    # Roof
    d.polygon([(12, 44), (48, 12), (84, 44)], fill=(180, 60, 40))
    d.polygon([(16, 42), (48, 14), (80, 42)], fill=(200, 80, 50))
    
    # Roof details
    d.line([(48, 14), (48, 42)], fill=(160, 50, 30), width=2)
    
    # Door
    d.rectangle([40, 58, 56, 86], fill=(100, 60, 30))
    d.rectangle([42, 60, 54, 84], fill=(120, 70, 35))
    d.ellipse([50, 70, 54, 74], fill=(80, 50, 20))
    
    # Windows
    d.rectangle([22, 50, 34, 62], fill=(180, 220, 255))
    d.rectangle([24, 52, 32, 60], fill=(200, 235, 255))
    d.line([(28, 52), (28, 60)], fill=(80, 80, 80), width=1)
    d.line([(24, 56), (32, 56)], fill=(80, 80, 80), width=1)
    
    d.rectangle([62, 50, 74, 62], fill=(180, 220, 255))
    d.rectangle([64, 52, 72, 60], fill=(200, 235, 255))
    d.line([(68, 52), (68, 60)], fill=(80, 80, 80), width=1)
    d.line([(64, 56), (72, 56)], fill=(80, 80, 80), width=1)
    
    # Chimney
    d.rectangle([60, 20, 68, 32], fill=(140, 100, 60))
    d.rectangle([62, 22, 66, 30], fill=(160, 120, 70))
    
    save(img, f"{BASE}/buildings/base.png")

make_base()

# ===== SHOP (96x96) - Market stall =====
def make_shop():
    img = Image.new('RGBA', (96, 96), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # Shadow
    d.ellipse([18, 85, 78, 94], fill=(0, 0, 0, 80))
    
    # Base structure
    d.rectangle([20, 40, 76, 88], fill=(180, 160, 110))
    d.rectangle([22, 42, 74, 86], fill=(200, 180, 130))
    
    # Awning (striped)
    d.rectangle([16, 32, 80, 44], fill=(220, 60, 60))
    for i in range(0, 80, 8):
        d.rectangle([16 + i, 32, 16 + i + 4, 44], fill=(220, 60, 60))
        d.rectangle([16 + i + 4, 32, 16 + i + 8, 44], fill=(255, 255, 255))
    
    # Counter
    d.rectangle([26, 60, 70, 80], fill=(160, 120, 60))
    d.rectangle([28, 62, 68, 78], fill=(180, 140, 70))
    
    # Items on counter
    d.ellipse([32, 64, 40, 72], fill=(255, 215, 0))  # Gold
    d.rectangle([46, 64, 52, 72], fill=(150, 150, 160))  # Stone
    d.ellipse([58, 64, 66, 72], fill=(100, 60, 30))  # Wood
    
    # Sign
    d.rectangle([36, 20, 60, 30], fill=(140, 100, 60))
    d.rectangle([38, 22, 58, 28], fill=(160, 120, 70))
    d.text((42, 22), "$", fill=(255, 215, 0))
    
    # Poles
    d.rectangle([18, 32, 22, 88], fill=(120, 80, 40))
    d.rectangle([74, 32, 78, 88], fill=(120, 80, 40))
    
    save(img, f"{BASE}/buildings/shop.png")

make_shop()

# ===== GROUND TILE (64x64) - Grass with variation =====
def make_ground():
    img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # Base grass
    d.rectangle([0, 0, 63, 63], fill=(106, 170, 80))
    
    # Grass variation
    import random
    random.seed(42)
    for _ in range(30):
        x = random.randint(2, 60)
        y = random.randint(2, 60)
        shade = random.choice([
            (90, 155, 65),
            (120, 185, 95),
            (80, 140, 55),
            (100, 165, 75)
        ])
        size = random.randint(1, 3)
        d.ellipse([x-size, y-size, x+size, y+size], fill=shade)
    
    # Small grass blades
    for _ in range(15):
        x = random.randint(4, 60)
        y = random.randint(4, 60)
        d.line([(x, y), (x, y-4)], fill=(80, 150, 60), width=1)
    
    save(img, f"{BASE}/world/ground.png")

make_ground()

# ===== WATER TILE (64x64) - Animated-looking water =====
def make_water():
    img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # Base water
    d.rectangle([0, 0, 63, 63], fill=(64, 140, 200))
    
    # Water highlights
    import random
    random.seed(99)
    for _ in range(12):
        x = random.randint(4, 56)
        y = random.randint(4, 56)
        length = random.randint(8, 16)
        d.line([(x, y), (x + length, y)], fill=(100, 170, 220), width=2)
        d.line([(x, y+1), (x + length, y+1)], fill=(80, 160, 210), width=1)
    
    save(img, f"{BASE}/world/water.png")

make_water()

# ===== SAND TILE (64x64) - Beach sand =====
def make_sand():
    img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # Base sand
    d.rectangle([0, 0, 63, 63], fill=(230, 210, 150))
    
    # Sand texture
    import random
    random.seed(77)
    for _ in range(40):
        x = random.randint(2, 60)
        y = random.randint(2, 60)
        shade = random.choice([
            (220, 200, 140),
            (240, 220, 160),
            (210, 190, 130)
        ])
        d.ellipse([x, y, x+2, y+2], fill=shade)
    
    save(img, f"{BASE}/world/sand.png")

make_sand()

print("\n✅ All high-quality assets generated!")
