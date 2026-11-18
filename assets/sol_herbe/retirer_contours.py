"""Retire le contour noir des tuiles d'herbe : chaque pixel presque noir prend la couleur moyenne
de ses voisins opaques non noirs (répété jusqu'à ce qu'il n'en reste plus).
Usage : python3 retirer_contours.py  (planche_originale.png → planche_sans_contour.png)"""
from pathlib import Path
from PIL import Image

ICI = Path(__file__).parent
image = Image.open(ICI / "planche_originale.png").convert("RGBA")
px = image.load()
noir = lambda p: p[3] and max(p[:3]) < 0x18
restants = {(x, y) for x in range(image.width) for y in range(image.height) if noir(px[x, y])}
while restants:
    remplis = {}
    for x, y in restants:
        voisins = [px[x + dx, y + dy] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                   if 0 <= x + dx < image.width and 0 <= y + dy < image.height
                   and (x + dx, y + dy) not in restants and px[x + dx, y + dy][3]]
        if voisins:
            remplis[x, y] = tuple(sum(c[i] for c in voisins) // len(voisins) for i in range(3)) + (255,)
    if not remplis:  # pixels noirs entourés de vide : on les efface
        remplis = {c: (0, 0, 0, 0) for c in restants}
    for c, couleur in remplis.items():
        px[c] = couleur
    restants -= remplis.keys()
image.save(ICI / "planche_sans_contour.png")
