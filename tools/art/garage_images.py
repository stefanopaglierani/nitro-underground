"""Prepares the garage pictures of the game from Stefano's garage image (v0.17).

    python3 tools/art/garage_images.py <stefano's garage png>

Writes into assets/ui/:
- loading_garage.jpg: the whole picture, the background of the loading page (the roller door
  as it is in the picture = loading finished);
- loading_door.png: the roller door alone, made as tall as the whole doorway, which the loading
  page slides up as the loading goes on (scripts/hud.gd, LoadingDoor);
- garage_bg.jpg: the inside of the garage without the bonnet in the foreground, the background
  of the garage screen (scripts/menu.gd).
"""
import sys
from PIL import Image

SRC = sys.argv[1]
OUT = "assets/ui/"
im = Image.open(SRC).convert("RGB")
assert im.size == (1672, 941), im.size

im.save(OUT + "loading_garage.jpg", quality=88, optimize=True)

# The roller door: columns 388..1332; in the picture its bottom bar ends at row 258. Closed, it
# reaches the floor at row 590. Built bottom up: the real bottom of the door (rows 150..258) and
# above it the same slat (rows 174..198, 24 px apart) repeated up to the full height.
L, R = 388, 1332
BOTTOM, CLOSED = 258, 590
door_h = CLOSED + 10
door = Image.new("RGB", (R - L, door_h))
low = im.crop((L, 150, R, BOTTOM))
door.paste(low, (0, door_h - low.height))
slat = im.crop((L, 174, R, 198))
y = door_h - low.height
while y > 0:
    y -= slat.height
    door.paste(slat, (0, y))
door.save(OUT + "loading_door.png", optimize=True)

# Garage screen: the same garage without the bonnet, 16:9.
im.crop((196, 0, 1476, 720)).save(OUT + "garage_bg.jpg", quality=88, optimize=True)
print("ok")
