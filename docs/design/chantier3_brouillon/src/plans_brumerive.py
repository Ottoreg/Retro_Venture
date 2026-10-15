"""Plans des cartes du lot Brumerive (production du chantier 3).

    python3 src/plans_brumerive.py      (depuis docs/design/chantier3_brouillon)

Écrit les 8 nouvelles cartes dans game/data/cartes et retouche les 2 existantes (sortie bas,
groupes). Les ressources Y et T (if, étain…) viendront avec le lot Métiers ; la porte du Gué vers
Hautepierre avec le lot Hautepierre.
"""
import json
import os

from cartes import JEU, Plan, conception, ecrire_carte

C = conception("brumerive")
HORIZ = (0.36, 0.64)   # ouvertures gauche / droite (en v)
VERT = (0.40, 0.60)    # ouvertures haut / bas (en u)


def retoucher(carte_id, ouvrir_bas):
    chemin = os.path.join(JEU, "data", "cartes", carte_id + ".json")
    with open(chemin, encoding="utf-8") as f:
        carte = json.load(f)
    plan = carte["plan"]
    if ouvrir_bas:
        derniere = list(plan[-1])
        for j in range(7, 12):
            derniere[j] = "."
        plan[-1] = "".join(derniere)
        avant = list(plan[-2])
        for j in range(7, 12):
            if avant[j] in "ARM":
                avant[j] = "."
        plan[-2] = "".join(avant)
    carte["sorties"] = C[carte_id]["sorties"]
    carte["groupes"] = C[carte_id]["groupes"]
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(carte, f, ensure_ascii=False, indent=2)
        f.write("\n")


def rives():  # 0_1 : rivière en diagonale, gué au milieu
    p = Plan(11)
    p.bord(haut=VERT, droite=HORIZ)
    riviere = lambda u, v: abs(v - (0.08 + 0.95 * u)) < 0.085 and 0.03 < u < 0.97
    p.peindre("E", riviere, sur=".")
    p.peindre(".", lambda u, v: 0.44 < u < 0.56 and riviere(u, v))           # gué
    p.peindre(":", lambda u, v: abs(u - 0.5) < 0.03 and v < 0.5, sur=".")    # chemin vers le gué
    p.peindre(":", lambda u, v: abs(v - 0.42 + 0.0 * u) < 0.02 and 0.56 < u < 0.97, sur=".")
    p.semer("A", 10, lambda u, v: 0.06 < u < 0.94 and 0.06 < v < 0.94 and abs(v - (0.08 + 0.95 * u)) < 0.16)
    p.semer("R", 4)
    p.poser("@", 0.5, 0.06)
    p.poser("a", 0.4, 0.62)
    p.poser("1", 0.75, 0.25)
    p.poser("2", 0.25, 0.72)
    p.poser("3", 0.55, 0.85)
    p.semer("F", 3, lambda u, v: 0.06 < u < 0.94 and 0.08 < v < 0.92 and v > 0.08 + 0.95 * u + 0.1)
    p.semer("U", 2)
    return p


def moulin():  # 1_1 : moulin sur sa butte, champs labourés, mare
    p = Plan(12)
    p.bord(haut=VERT, bas=VERT, gauche=HORIZ, droite=HORIZ)
    p.decor("maison", 0.5, 0.32)
    p.mur_h("M", 0.36, 0.34, 0.44)
    p.mur_h("M", 0.36, 0.56, 0.66)
    p.peindre("R", lambda u, v: ((u - 0.72) / 0.07) ** 2 + ((v - 0.58) / 0.12) ** 2 < 1 and not (0.70 < u < 0.74), sur=".")
    p.peindre(":", lambda u, v: abs(u - 0.5) < 0.02 and v > 0.36, sur=".")
    p.peindre(":", lambda u, v: abs(v - 0.5) < 0.02, sur=".")
    p.peindre("E", lambda u, v: 0.12 < u < 0.22 and 0.72 < v < 0.86, sur=".")
    p.semer("A", 6)
    p.poser("@", 0.5, 0.08)
    p.poser("a", 0.42, 0.42)
    p.poser("1", 0.3, 0.25)
    p.poser("2", 0.8, 0.3)
    p.poser("3", 0.35, 0.65)
    p.poser("4", 0.82, 0.8)
    p.semer("F", 2)
    p.semer("C", 2)
    p.semer("I", 1)
    return p


def verger():  # 2_0 : rangées de pommiers, ferme en haut à droite, enclos
    p = Plan(13)
    p.bord(gauche=HORIZ, bas=VERT)
    for i, j in p.cases():
        if i % 4 == 2 and j % 3 == 1 and 2 < i < 30 and 1 < j < 12:
            p.g[i][j] = "A"
    p.decor("maison", 0.8, 0.34)
    p.mur_h("M", 0.53, 0.66, 0.93)
    p.mur_v("M", 0.66, 0.40, 0.47)
    p.peindre(":", lambda u, v: abs(v - 0.5) < 0.025 and u < 0.62, sur=".")
    p.peindre(":", lambda u, v: abs(u - 0.6) < 0.02 and 0.5 < v, sur=".")
    p.peindre(":", lambda u, v: abs(v - 0.42) < 0.02 and 0.62 < u < 0.72, sur=".")
    p.semer("R", 3)
    p.poser("@", 0.06, 0.5)
    p.poser("a", 0.72, 0.46)
    p.poser("1", 0.3, 0.22)
    p.poser("2", 0.4, 0.78)
    p.poser("3", 0.8, 0.7)
    p.poser("4", 0.2, 0.62)
    p.semer("F", 3)
    p.semer("C", 2)
    return p


def lande():  # 2_1 : lande ouverte, îlots de rochers, muret en arc, chemins en croix
    p = Plan(14)
    p.bord(haut=VERT, bas=VERT, gauche=HORIZ, droite=HORIZ)
    p.peindre(":", lambda u, v: abs(u - 0.5) < 0.02 or abs(v - 0.5) < 0.02, sur=".")
    p.peindre("M", lambda u, v: ((u - 0.5) / 0.15) ** 2 + ((v - 0.5) / 0.24) ** 2 < 1
              and ((u - 0.5) / 0.10) ** 2 + ((v - 0.5) / 0.15) ** 2 > 1 and v < 0.44 and abs(u - 0.5) > 0.04, sur=".")
    for cu, cv in ((0.22, 0.25), (0.78, 0.72), (0.25, 0.78)):
        p.peindre("R", lambda u, v, cu=cu, cv=cv: ((u - cu) / 0.04) ** 2 + ((v - cv) / 0.07) ** 2 < 1, sur=".")
    p.semer("A", 4)
    p.poser("@", 0.04, 0.5)
    p.poser("1", 0.35, 0.3)
    p.poser("2", 0.7, 0.3)
    p.poser("3", 0.35, 0.72)
    p.poser("4", 0.68, 0.62)
    p.semer("C", 2)
    p.semer("I", 2)
    return p


def bles():  # 1_2 : labyrinthe de blé (rangées de rochers bas), grange, clairière centrale
    p = Plan(15)
    p.bord(haut=VERT, droite=HORIZ)
    for k, i in enumerate(range(4, 31, 4)):
        trous = {2 + (k * 5) % 13, 9 + (k * 3) % 7}
        for j in range(1, 18):
            if j not in trous and j + 1 not in trous:
                p.g[i][j] = "R"
    p.peindre(".", lambda u, v: abs(u - 0.5) < 0.14 and abs(v - 0.5) < 0.17)   # clairière
    p.peindre(".", lambda u, v: abs(u - 0.5) < 0.04 and v < 0.4)               # allée du haut
    p.peindre(".", lambda u, v: u > 0.6 and abs(v - 0.5) < 0.06)              # allée vers la droite
    p.decor("cabane", 0.18, 0.84)
    p.poser("@", 0.5, 0.05)
    p.poser("a", 0.3, 0.88)
    p.poser("1", 0.5, 0.5)
    p.poser("2", 0.2, 0.25)
    p.poser("3", 0.8, 0.8)
    p.semer("F", 2)
    return p


def camp():  # 2_2 : tentes, palissade en U ouverte à droite, feux de camp
    p = Plan(16)
    p.bord(haut=VERT, gauche=HORIZ, droite=HORIZ)
    p.mur_h("M", 0.22, 0.2, 0.7)
    p.mur_h("M", 0.8, 0.2, 0.7)
    p.mur_v("M", 0.2, 0.22, 0.42)
    p.mur_v("M", 0.2, 0.58, 0.8)
    p.peindre(":", lambda u, v: abs(v - 0.5) < 0.02, sur=".")
    p.peindre(":", lambda u, v: abs(u - 0.5) < 0.02 and v < 0.22, sur=".")
    p.decor("cabane", 0.35, 0.42)
    p.decor("cabane", 0.55, 0.72)
    for u, v in ((0.5, 0.36), (0.3, 0.64), (0.82, 0.3)):
        p.poser("R", u, v)
    p.semer("A", 5, lambda u, v: (u > 0.74 or u < 0.17 or v < 0.18 or v > 0.84) and 0.04 < u < 0.96)
    p.poser("@", 0.04, 0.5)
    p.poser("1", 0.62, 0.36)
    p.poser("2", 0.42, 0.6)
    p.poser("3", 0.85, 0.62)
    p.poser("4", 0.12, 0.25)
    p.semer("I", 2)
    return p


def gue():  # 3_1 : rivière verticale au tiers droit, gué de pierres, poste de garde
    p = Plan(17)
    p.bord(gauche=HORIZ, bas=VERT, droite=HORIZ)
    p.peindre("E", lambda u, v: 0.62 < u < 0.74 and 0.02 < v < 0.98, sur=".")
    p.peindre(":", lambda u, v: abs(v - 0.5) < 0.05 and 0.6 < u < 0.76)      # gué
    p.peindre(":", lambda u, v: abs(v - 0.5) < 0.02, sur=".")
    p.peindre(":", lambda u, v: abs(u - 0.5) < 0.02 and v > 0.5, sur=".")
    p.decor("cabane", 0.86, 0.36)
    p.semer("A", 6, lambda u, v: 0.06 < u < 0.58 and 0.06 < v < 0.94)
    p.semer("R", 3, lambda u, v: 0.06 < u < 0.58 and 0.06 < v < 0.94)
    p.poser("@", 0.04, 0.5)
    p.poser("a", 0.84, 0.56)
    p.poser("1", 0.3, 0.28)
    p.poser("2", 0.35, 0.75)
    p.poser("3", 0.86, 0.8)
    p.semer("I", 1)
    return p


def palissade():  # 3_2 : palissade du chef, grande tente, arène, tours de guet
    p = Plan(18)
    p.bord(haut=VERT, gauche=HORIZ)
    dans = lambda u, v: 0.16 < u < 0.84 and 0.16 < v < 0.86
    p.mur_h("M", 0.18, 0.18, 0.44)
    p.mur_h("M", 0.18, 0.56, 0.82)
    p.mur_h("M", 0.84, 0.18, 0.82)
    p.mur_v("M", 0.18, 0.18, 0.42)
    p.mur_v("M", 0.18, 0.58, 0.84)
    p.mur_v("M", 0.82, 0.18, 0.84)
    p.decor("auberge", 0.7, 0.36)
    p.peindre("R", lambda u, v: ((u - 0.2) / 0.03) ** 2 + ((v - 0.2) / 0.05) ** 2 < 1 or ((u - 0.8) / 0.03) ** 2 + ((v - 0.84) / 0.05) ** 2 < 1)
    p.peindre(":", lambda u, v: (abs(v - 0.5) < 0.02 and u < 0.3) or (abs(u - 0.5) < 0.02 and v < 0.3), sur=".")
    p.semer("A", 6, lambda u, v: not dans(u, v) and 0.04 < u < 0.96 and 0.04 < v < 0.96)
    p.poser("@", 0.04, 0.5)
    p.poser("1", 0.52, 0.56)
    p.poser("2", 0.08, 0.3)
    return p


if __name__ == "__main__":
    retoucher("brumerive_0_0", True)
    retoucher("brumerive_1_0", True)
    ok = True
    for carte_id, dessin in (("brumerive_0_1", rives), ("brumerive_1_1", moulin), ("brumerive_2_0", verger),
                             ("brumerive_2_1", lande), ("brumerive_1_2", bles), ("brumerive_2_2", camp),
                             ("brumerive_3_1", gue), ("brumerive_3_2", palissade)):
        ok = ecrire_carte(C[carte_id], dessin()) and ok
    print("cartes écrites" + ("" if ok else " (avec des cases isolées)"))
