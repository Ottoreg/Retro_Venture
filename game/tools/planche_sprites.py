"""Assemble les sprites d'un monstre (pixel art) en une planche pour le jeu.

Entrée : un dossier avec, pour chaque direction (south, south-east, east, north-east, north,
north-west, west, south-west), une image fixe `<direction>.png` et une course en GIF dont le nom
finit par `_<direction>.gif` (4 images).
Sortie : une planche PNG de 8 lignes (une par direction, dans cet ordre) et 5 colonnes de
96 × 96 px : l'image fixe, puis les 4 images de la course. Les pieds sont en (48, 80) de chaque case.

    python3 tools/planche_sprites.py dossier/ art/sprites/gobelin.png
"""
import glob
import os
import re
import sys

from PIL import Image, ImageSequence

DIRECTIONS = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
CELL = 96
FEET = (48, 80)
RUN_FRAMES = 4


def find(folder: str, suffix: str) -> str:
    """Le fichier du dossier dont le nom (sans préfixe d'envoi « xxxxxxxx- ») finit par `suffix`."""
    for path in sorted(glob.glob(os.path.join(folder, "*"))):
        name = re.sub(r"^[0-9a-f]{8}-", "", os.path.basename(path))
        if name == suffix or name.endswith("_" + suffix):
            return path
    sys.exit("introuvable : " + suffix)


def main(folder: str, output: str) -> None:
    sheet = Image.new("RGBA", (CELL * (1 + RUN_FRAMES), CELL * len(DIRECTIONS)), (0, 0, 0, 0))
    for row, direction in enumerate(DIRECTIONS):
        still = Image.open(find(folder, direction + ".png")).convert("RGBA")
        # Image fixe en 64 × 64, pieds en bas au centre (32, 62) : recentrée sur les pieds de la course.
        sheet.alpha_composite(still, (FEET[0] - still.width // 2, row * CELL + FEET[1] - (still.height - 2)))
        frames = [f.convert("RGBA") for f in ImageSequence.Iterator(Image.open(find(folder, direction + ".gif")))]
        if len(frames) != RUN_FRAMES or frames[0].size != (CELL, CELL):
            sys.exit("course %s : %d images de %s, attendu %d de %d px" % (direction, len(frames), frames[0].size, RUN_FRAMES, CELL))
        for col, frame in enumerate(frames):
            sheet.alpha_composite(frame, ((col + 1) * CELL, row * CELL))
    sheet.save(output, optimize=True)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
