"""Assemble les sprites d'un monstre (pixel art) en une planche pour le jeu.

Entrée : un dossier avec, pour chaque direction (south, south-east, east, north-east, north,
north-west, west, south-west), une image fixe `<direction>.png` et une course en GIF dont le nom
finit par `_<direction>.gif` (4 images). Sans course (monstres fournis en images fixes seulement),
l'image fixe remplit aussi les 4 cases de la course. Export PixelLab en dossiers d'images
(`walking/<direction>/frame_000.png`, `running/<direction>/frame_00N.png`, 84 à 136 px, centrées dans la case) : l'image fixe vient
de `Idle_rotations_8dir.gif` (8 images de 64 px, une par direction dans l'ordre ci-dessus), sinon de la 1re image
de la marche ; une image sur deux de la course (8) en donne 4.
Une direction ouest absente (west, south-west, north-west) est faite en miroir de l'est (`MIRRORS`).
Avec un dossier `strike/` (attaque, 4 diagonales), 6 colonnes de plus : l'attaque, l'image fixe pour les
4 autres directions.
Sortie : une planche PNG de 8 lignes (une par direction, dans cet ordre) et 5 colonnes de
96 × 96 px (144 si l'idle fait 96 px) : l'image fixe, puis les 4 images de la course. Les pieds sont en (48, 80) de
chaque case (aux 5/6 de sa hauteur).

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
STRIKE_FRAMES = 6


def find(folder: str, suffix: str, required: bool = True) -> str:
    """Le fichier du dossier dont le nom (sans préfixe d'envoi « xxxxxxxx- ») finit par `suffix`."""
    for path in sorted(glob.glob(os.path.join(folder, "*"))):
        name = re.sub(r"^[0-9a-f]{8}-", "", os.path.basename(path))
        if name == suffix or name.endswith("_" + suffix):
            return path
    if required:
        sys.exit("introuvable : " + suffix)
    return ""


## Direction ouest absente de l'export : l'est retourné en miroir (animations symétriques).
MIRRORS = {"west": "east", "south-west": "south-east", "north-west": "north-east"}


def animation_frames(folder: str, animation: str, direction: str) -> list:
    """Images d'une animation dans une direction ; à défaut, celles de la direction miroir, retournées."""
    paths = sorted(glob.glob(os.path.join(folder, animation, direction, "frame_*.png")))
    if paths or direction not in MIRRORS:
        return [Image.open(path).convert("RGBA") for path in paths]
    return [image.transpose(Image.Transpose.FLIP_LEFT_RIGHT) for image in animation_frames(folder, animation, MIRRORS[direction])]


def main(folder: str, output: str) -> None:
    frames_dir = os.path.join(folder, "running")
    idle_path = os.path.join(folder, "Idle_rotations_8dir.gif")
    idle = [f.convert("RGBA") for f in ImageSequence.Iterator(Image.open(idle_path))] if os.path.exists(idle_path) else []
    # Personnage plus grand (idle de 96 px au lieu de 64, géante) : cases agrandies d'autant, pieds aux 5/6 de la case.
    cell = CELL * idle[0].width // 64 if idle else CELL
    feet = (cell // 2, cell * 5 // 6)
    strike_dir = os.path.join(folder, "strike")
    columns = 1 + RUN_FRAMES + (STRIKE_FRAMES if os.path.isdir(strike_dir) else 0)
    sheet = Image.new("RGBA", (cell * columns, cell * len(DIRECTIONS)), (0, 0, 0, 0))
    for row, direction in enumerate(DIRECTIONS):
        if os.path.isdir(frames_dir):
            # Images de la course centrées dans la case ; idle, pieds en bas au centre.
            images = ([] if idle else animation_frames(folder, "walking", direction)[:1]) + animation_frames(folder, "running", direction)[::2]
            if idle:
                sheet.alpha_composite(idle[row], (feet[0] - idle[row].width // 2, row * cell + feet[1] - idle[row].height + 1))
            for col, frame in enumerate(images[:RUN_FRAMES + (0 if idle else 1)], 1 if idle else 0):
                sheet.alpha_composite(frame, (col * cell + (cell - frame.width) // 2, row * cell + (cell - frame.height) // 2))
            # Attaque (4 diagonales seulement) : 6 images réparties sur l'animation ; ailleurs, l'image fixe.
            strikes = animation_frames(folder, "strike", direction)
            for col in range(columns - 1 - RUN_FRAMES):
                spot = ((1 + RUN_FRAMES + col) * cell, row * cell)
                if strikes:
                    frame = strikes[round(col * (len(strikes) - 1) / (STRIKE_FRAMES - 1))]
                    sheet.alpha_composite(frame, (spot[0] + (cell - frame.width) // 2, spot[1] + (cell - frame.height) // 2))
                else:
                    sheet.alpha_composite(sheet.crop((0, row * cell, cell, (row + 1) * cell)), spot)
            continue
        still = Image.open(find(folder, direction + ".png")).convert("RGBA")
        # Image fixe en 64 × 64, pieds en bas au centre (32, 62) : recentrée sur les pieds de la course.
        spot = (FEET[0] - still.width // 2, row * CELL + FEET[1] - (still.height - 2))
        sheet.alpha_composite(still, spot)
        run = find(folder, direction + ".gif", required=False)
        if not run:
            for col in range(RUN_FRAMES):
                sheet.alpha_composite(still, (spot[0] + (col + 1) * CELL, spot[1]))
            continue
        frames = [f.convert("RGBA") for f in ImageSequence.Iterator(Image.open(run))]
        if len(frames) != RUN_FRAMES or frames[0].size != (CELL, CELL):
            sys.exit("course %s : %d images de %s, attendu %d de %d px" % (direction, len(frames), frames[0].size, RUN_FRAMES, CELL))
        for col, frame in enumerate(frames):
            sheet.alpha_composite(frame, ((col + 1) * CELL, row * CELL))
    sheet.save(output, optimize=True)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
