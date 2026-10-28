"""Recolore les planches de pixel art des races aux couleurs de chaque Voie.

Pour chaque race d'`art/art.json` qui a une « planche » et une « recoloration », écrit une planche
par Voie (`tenues`) : `art/sprites/<race>_<voie>.png`. Les pixels du vêtement (choisis par leur
teinte, saturation et valeur, voir « recoloration ») prennent la couleur de tunique de la Voie,
en gardant leurs ombres et lumières ; `force` mélange avec la couleur d'origine (1 : tout recolorer).

    python3 tools/couleurs_sprites.py        # depuis game/, après tout changement de planche ou de tenue
"""
import colorsys
import json
import os

from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "art")


def luminance(rgb):
    return 0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]


def in_hue(h: float, low: float, high: float) -> bool:
    return low <= h <= high if low <= high else (h >= low or h <= high)


def selected(pixel, recipe) -> bool:
    if pixel[3] < 16:
        return False
    h, s, v = colorsys.rgb_to_hsv(*[q / 255 for q in pixel[:3]])
    return (in_hue(h * 360, *recipe["teinte"]) and recipe["saturation"][0] <= s <= recipe["saturation"][1]
            and recipe["valeur"][0] <= v <= recipe["valeur"][1])


def recolor(sheet: Image.Image, recipe: dict, target_hex: str) -> Image.Image:
    target = tuple(int(target_hex[i:i + 2], 16) for i in (0, 2, 4))
    pixels = list(sheet.getdata())
    chosen = [i for i, p in enumerate(pixels) if selected(p, recipe)]
    # Luminance moyenne du vêtement : elle prend la couleur de la Voie, le reste s'éclaircit ou
    # s'assombrit autour.
    reference = sum(luminance(pixels[i]) for i in chosen) / max(1, len(chosen))
    target_lum = max(1.0, luminance(target))
    force = float(recipe.get("force", 1.0))
    out = list(pixels)
    for i in chosen:
        p = pixels[i]
        ratio = luminance(p) / max(1.0, reference)
        tinted = [min(255.0, c * ratio) for c in target]
        # Une cible très claire (Théologue) éclaircit aussi les ombres, sans les effacer.
        if target_lum > 160:
            tinted = [min(255.0, c * (0.45 + 0.55 * ratio)) for c in target]
        out[i] = tuple(int(round(p[k] * (1 - force) + tinted[k] * force)) for k in range(3)) + (p[3],)
    result = Image.new("RGBA", sheet.size)
    result.putdata(out)
    return result


def main() -> None:
    with open(os.path.join(ROOT, "art.json"), encoding="utf-8") as f:
        manifest = json.load(f)
    for race, spec in manifest["races"].items():
        if "planche" not in spec or "recoloration" not in spec:
            continue
        sheet = Image.open(os.path.join(ROOT, spec["planche"])).convert("RGBA")
        stem = os.path.splitext(spec["planche"])[0]
        for voie, outfit in manifest["tenues"].items():
            path = os.path.join(ROOT, "%s_%s.png" % (stem, voie))
            recolor(sheet, spec["recoloration"], outfit["couleurs"]["tunique"]).save(path, optimize=True)
            print(os.path.relpath(path, ROOT))


if __name__ == "__main__":
    main()
