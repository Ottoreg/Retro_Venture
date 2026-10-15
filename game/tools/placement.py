#!/usr/bin/env python3
"""Propose un calque « placement » (cases de départ en combat) pour une carte JSON.

    python3 tools/placement.py data/cartes/brumerive_0_0.json [--ecrire] [--cases 6]

Façon Dofus : les joueurs à gauche, les monstres à droite, à mi-hauteur, chaque camp sur des cases
praticables non voisines (pour qu'on puisse choisir sa place). Le calque n'est qu'une proposition :
à retoucher à la main si le décor s'y prête mal (le jeu vérifie seulement qu'il est valide). Sans
--ecrire, affiche le calque ; avec, l'écrit dans le fichier (sans toucher à un calque existant,
sauf avec --remplacer).
"""
import json
import sys

SOL = set(".@:") | set("123456789")
# Ancres à l'écran, en fraction de la largeur et de la hauteur de la carte.
ANCRES = {"j": (0.27, 0.5), "m": (0.73, 0.5)}


def ecran(i, j):
    # Ligne i, caractère j : les lignes impaires (décalées) commencent une demi-case plus à gauche.
    return (64 * j - 32 * (i % 2), 16 * i)


def proposer(plan, cases=6):
    hauteur, largeur = len(plan), len(plan[0])
    libres = [(i, j) for i in range(2, hauteur - 2) for j in range(1, largeur - 1)
              if not (i % 2 == 1 and j == 0) and plan[i][j] in SOL]
    calque = [list("." * largeur) for _ in range(hauteur)]
    for i in range(1, hauteur, 2):
        calque[i][0] = " "
    pris = set()
    for marque, (fx, fy) in ANCRES.items():
        ax, ay = 64 * (largeur - 1) * fx, 16 * (hauteur - 1) * fy
        tri = sorted(libres, key=lambda c: (ecran(*c)[0] - ax) ** 2 + (ecran(*c)[1] - ay) ** 2)
        choisies = []
        for c in tri:
            if c in pris:
                continue
            x, y = ecran(*c)
            # Pas deux cases voisines (écart d'au moins une case en diagonale à l'écran).
            if all(abs(x - ecran(*d)[0]) + 2 * abs(y - ecran(*d)[1]) > 64 for d in choisies):
                choisies.append(c)
            if len(choisies) == cases:
                break
        for i, j in choisies:
            calque[i][j] = marque
            pris.add((i, j))
    return ["".join(ligne) for ligne in calque]


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    cases = 6
    if "--cases" in sys.argv:
        cases = int(sys.argv[sys.argv.index("--cases") + 1])
        args = [a for a in args if a != str(cases)]
    for chemin in args:
        with open(chemin, encoding="utf-8") as f:
            donnees = json.load(f)
        if "placement" in donnees and "--remplacer" not in sys.argv:
            print(f"{chemin} : calque déjà présent (--remplacer pour l'écraser)")
            continue
        calque = proposer(donnees["plan"], cases)
        if "--ecrire" in sys.argv:
            donnees["placement"] = calque
            with open(chemin, "w", encoding="utf-8") as f:
                json.dump(donnees, f, ensure_ascii=False, indent=2)
                f.write("\n")
            print(f"{chemin} : calque écrit")
        else:
            print(chemin)
            for ligne_plan, ligne in zip(donnees["plan"], calque):
                print(f"  {ligne_plan}   {ligne}")


if __name__ == "__main__":
    main()
