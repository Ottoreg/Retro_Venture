"""Décors propres à Hautepierre : remplace les bâtiments provisoires par leurs vrais dessins.

    python3 src/decors_ville.py      (depuis docs/design/chantier3_brouillon)

Tour Blanche (Citadelle), temple (Porte de l'Ouest), tours de garde (portes de la ville, Vigie,
horloge du camp des Cendrillons), fontaine et étals (Grand-Place), Arbre Blanc, et un poteau
indicateur à côté de chacune des 6 portes entre Hautepierre et les zones de départ. Les décors
d'une case sont posés sur une case « # » ; tout reste accessible (vérifié). Relancer ne double rien.
"""
import json
import os

from cartes import JEU, cellule, ecran, plan_de, verifier


def charger(carte_id):
    with open(os.path.join(JEU, "data", "cartes", carte_id + ".json"), encoding="utf-8") as f:
        return json.load(f)


def sauver(carte):
    verifier(carte["id"], carte["plan"])
    with open(os.path.join(JEU, "data", "cartes", carte["id"] + ".json"), "w", encoding="utf-8") as f:
        json.dump(carte, f, ensure_ascii=False, indent=2)
        f.write("\n")


def emprise(case, taille=3):
    x, y = cellule(*case)
    return [plan_de(x - dx, y - dy) for dx in range(taille) for dy in range(taille)]


def remplacer_decor(carte, ancienne, nouvelle, rang=0, une_case=False):
    """Change l'image du `rang`-ième décor `ancienne` ; un décor d'une case libère le reste de l'emprise."""
    trouves = [d for d in carte["decors"] if d["image"] in (ancienne, nouvelle)]
    d = trouves[rang]
    if d["image"] == ancienne and une_case:
        g = [list(l) for l in carte["plan"]]
        for i, j in emprise(d["case"]):
            if [i, j] != d["case"]:
                g[i][j] = "."
        carte["plan"] = ["".join(l) for l in g]
    d["image"] = nouvelle


def poser(carte, image, i, j):
    """Décor d'une case en (ligne, colonne), sur une case « # »."""
    if any(d["case"] == [i, j] for d in carte.get("decors", [])):
        return
    g = [list(l) for l in carte["plan"]]
    g[i][j] = "#"
    carte["plan"] = ["".join(l) for l in g]
    carte.setdefault("decors", []).append({"image": image, "case": [i, j]})


def proche(carte, car, u, v):
    cases = [(i, j) for i, l in enumerate(carte["plan"]) for j, c in enumerate(l) if c == car and not (i % 2 and j == 0)]
    return min(cases, key=lambda c: (ecran(*c)[0] - u) ** 2 + ((ecran(*c)[1] - v) * 0.44) ** 2) if cases else None


def tour_dans_amas(carte, u, v):
    """Remplace l'amas de rochers près de (u, v) par une tour de garde (les autres rochers s'en vont)."""
    centre = proche(carte, "R", u, v)
    if centre is None:
        return
    g = [list(l) for l in carte["plan"]]
    for i, l in enumerate(g):
        for j, c in enumerate(l):
            if c == "R" and abs(ecran(i, j)[0] - ecran(*centre)[0]) < 0.06 and abs(ecran(i, j)[1] - ecran(*centre)[1]) < 0.1:
                g[i][j] = "."
    carte["plan"] = ["".join(l) for l in g]
    poser(carte, "tour_de_garde", *centre)


def main():
    c = charger("hautepierre_2_2")                     # Grand-Place : fontaine et étals
    fontaine = proche(c, "E", 0.5, 0.48)
    if fontaine:
        poser(c, "fontaine", *fontaine)
    g = c["plan"]
    for i, l in enumerate(g):
        for j, ch in enumerate(l):
            if ch == "M" and 0.15 < ecran(i, j)[0] < 0.85 and 0.6 < ecran(i, j)[1] < 0.85:
                poser(c, "etal", i, j)
    sauver(c)
    c = charger("hautepierre_2_1")                     # Citadelle : Tour Blanche et Arbre Blanc
    remplacer_decor(c, "pavillon", "tour_blanche")
    arbre = proche(c, "A", 0.5, 0.42)
    if arbre and ecran(*arbre)[1] < 0.6:
        poser(c, "arbre_mort", *arbre)
    sauver(c)
    c = charger("hautepierre_1_2")                     # Porte de l'Ouest : temple, tours de garde
    remplacer_decor(c, "pavillon", "temple")
    for v in (0.34, 0.66):
        tour_dans_amas(c, 0.12, v)
    sauver(c)
    c = charger("hautepierre_3_2")                     # Porte de l'Est : tours de garde
    for v in (0.34, 0.66):
        tour_dans_amas(c, 0.88, v)
    sauver(c)
    c = charger("hautepierre_1_1")                     # Vigie aux Corbacs : la tour en ruine
    remplacer_decor(c, "cabane", "tour_de_garde", rang=0, une_case=True)
    sauver(c)
    c = charger("hautepierre_3_3")                     # Camp des Cendrillons : l'horloge
    remplacer_decor(c, "pavillon", "tour_de_garde", une_case=True)
    sauver(c)
    # Poteaux indicateurs à côté des portes entre la ville et les zones de départ.
    for carte_id, (i, j) in {"hautepierre_0_2": (14, 1), "hautepierre_4_2": (14, 17), "hautepierre_2_0": (1, 8),
                             "brumerive_3_1": (14, 17), "crasse_roc_0_2": (14, 1), "sylvebrume_2_2": (31, 8)}.items():
        c = charger(carte_id)
        if c["plan"][i][j] in ".:" and c.get("placement", ["." * 19] * 33)[i][j] not in "jm":
            poser(c, "poteau_indicateur", i, j)
            sauver(c)
        else:
            print(f"{carte_id} : pas de place pour le poteau en {i}, {j} ({c['plan'][i][j]})")
    print("décors de ville posés")


if __name__ == "__main__":
    main()
