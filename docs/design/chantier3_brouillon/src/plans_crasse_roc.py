"""Plans des cartes du lot Crasse-Roc (production du chantier 3).

    python3 src/plans_crasse_roc.py      (depuis docs/design/chantier3_brouillon)

Écrit les 8 nouvelles cartes et retouche les 2 existantes (sorties, groupes). Les ressources T
(étain) viendront avec le lot Métiers ; la porte de la Route des Charrois vers Hautepierre avec le
lot Hautepierre.
"""
from cartes import Plan, conception, ecrire_carte, retoucher

C = conception("crasse_roc")
HORIZ = (0.36, 0.64)
VERT = (0.40, 0.60)


def rataillerie():  # 0_1 : cuvette de ferraille, îlots, flaque, atelier de Mamie Ratine
    p = Plan(21)
    p.bord("R", haut=VERT, droite=HORIZ)
    p.peindre("R", lambda u, v: (u < 0.07 or u > 0.93 or v < 0.07 or v > 0.93)
              and not (0.4 < u < 0.6 and v < 0.1) and not (u > 0.9 and 0.36 < v < 0.64), sur=".")
    p.decor("cabane", 0.22, 0.3)
    p.peindre("E", lambda u, v: ((u - 0.52) / 0.07) ** 2 + ((v - 0.55) / 0.1) ** 2 < 1, sur=".")
    for cu, cv in ((0.35, 0.45), (0.68, 0.35), (0.3, 0.72), (0.7, 0.72), (0.52, 0.8), (0.82, 0.55)):
        p.peindre("R", lambda u, v, cu=cu, cv=cv: ((u - cu) / 0.035) ** 2 + ((v - cv) / 0.05) ** 2 < 1, sur=".")
    p.peindre(":", lambda u, v: abs(u - 0.5) < 0.02 and v < 0.42, sur=".")
    p.poser("@", 0.5, 0.08)
    p.poser("a", 0.26, 0.38)
    p.poser("1", 0.72, 0.22)
    p.poser("2", 0.2, 0.6)
    p.poser("3", 0.45, 0.68)
    p.poser("4", 0.82, 0.82)
    p.semer("U", 3)
    p.semer("F", 1)
    return p


def puits():  # 2_0 : gouffre central, corniche, entrée de mine, stalagmites
    p = Plan(22)
    p.bord("R", gauche=HORIZ, bas=VERT)
    p.peindre("R", lambda u, v: ((u - 0.5) / 0.2) ** 2 + ((v - 0.52) / 0.3) ** 2 < 1, sur=".")
    p.peindre("E", lambda u, v: ((u - 0.5) / 0.15) ** 2 + ((v - 0.52) / 0.24) ** 2 < 1)
    p.decor("galerie", 0.82, 0.25)
    p.semer("R", 6, lambda u, v: 0.06 < u < 0.94 and 0.06 < v < 0.94 and ((u - 0.5) / 0.26) ** 2 + ((v - 0.52) / 0.38) ** 2 > 1)
    p.poser("@", 0.04, 0.5)
    p.poser("a", 0.72, 0.34)
    p.poser("1", 0.2, 0.22)
    p.poser("2", 0.82, 0.62)
    p.poser("3", 0.35, 0.86)
    p.semer("U", 2)
    p.semer("I", 2)
    return p


def galerie():  # 1_1 : deux couloirs de rails, éboulis, poutres ; fermée en bas
    p = Plan(23)
    p.bord("R", haut=VERT, gauche=HORIZ, droite=HORIZ)
    p.peindre(":", lambda u, v: abs(v - 0.32) < 0.02 or abs(v - 0.62) < 0.02, sur=".")
    p.peindre(":", lambda u, v: abs(u - 0.5) < 0.02 and v < 0.32, sur=".")
    p.peindre("R", lambda u, v: abs(v - 0.47) < 0.05 and not (0.22 < u < 0.28 or 0.7 < u < 0.76), sur=".")
    p.peindre("R", lambda u, v: v > 0.8 and (u * 7 + v * 3) % 1 < 0.6, sur=".")
    p.semer("A", 8, lambda u, v: 0.06 < u < 0.94 and (abs(v - 0.22) < 0.04 or abs(v - 0.72) < 0.04))
    p.poser("@", 0.5, 0.06)
    p.poser("1", 0.3, 0.3)
    p.poser("2", 0.75, 0.62)
    p.poser("3", 0.4, 0.68)
    p.semer("I", 2)
    p.semer("U", 1)
    return p


def poste():  # 2_1 : palissade carrée au centre-droit ouverte en bas, corps de garde
    p = Plan(24)
    p.bord("R", haut=VERT, gauche=HORIZ, bas=VERT)
    p.mur_h("M", 0.24, 0.5, 0.86)
    p.mur_v("M", 0.5, 0.24, 0.7)
    p.mur_v("M", 0.86, 0.24, 0.7)
    p.mur_h("M", 0.7, 0.5, 0.6)
    p.mur_h("M", 0.7, 0.76, 0.86)
    p.decor("maison", 0.68, 0.48)
    for u, v in ((0.56, 0.32), (0.8, 0.62), (0.42, 0.8)):
        p.poser("R", u, v)
    p.peindre(":", lambda u, v: abs(v - 0.5) < 0.02 and u < 0.5, sur=".")
    p.peindre(":", lambda u, v: abs(u - 0.5) < 0.02 and v < 0.24, sur=".")
    p.peindre(":", lambda u, v: abs(u - 0.68) < 0.02 and v > 0.66, sur=".")
    p.poser("@", 0.04, 0.5)
    p.poser("1", 0.25, 0.3)
    p.poser("2", 0.3, 0.7)
    p.poser("3", 0.62, 0.84)
    p.poser("4", 0.6, 0.62)
    p.semer("I", 2)
    return p


def carriere():  # 2_2 : gradins de rochers percés de rampes, treuil
    p = Plan(25)
    p.bord("R", haut=VERT, gauche=HORIZ)
    for k, v0 in enumerate((0.28, 0.5, 0.72)):
        rampe = (0.25, 0.75, 0.5)[k]
        p.peindre("R", lambda u, v, v0=v0, rampe=rampe: abs(v - v0) < 0.03 and abs(u - rampe) > 0.06 and 0.04 < u < 0.96, sur=".")
    p.decor("cabane", 0.18, 0.88)
    p.poser("@", 0.5, 0.06)
    p.poser("a", 0.32, 0.86)
    p.poser("1", 0.7, 0.18)
    p.poser("2", 0.35, 0.4)
    p.poser("3", 0.7, 0.6)
    p.semer("I", 2)
    return p


def forges():  # 1_2 : deux rigoles de lave en diagonale, passerelles d'une case, cheminées
    p = Plan(26)
    p.bord("R", gauche=HORIZ, droite=HORIZ, bas=VERT)
    for c in (0.3, 0.68):
        p.peindre("E", lambda u, v, c=c: abs(u - (c + 0.18 * (v - 0.5))) < 0.035 and 0.03 < u < 0.97, sur=".")
        for vv in (0.25, 0.75):
            # Passerelle sur deux lignes : en isométrique, une seule ligne ne se traverse pas.
            p.peindre(":", lambda u, v, c=c, vv=vv: abs(v - vv) < 0.035 and abs(u - (c + 0.18 * (v - 0.5))) < 0.06)
    p.decor("galerie", 0.16, 0.22)
    p.decor("galerie", 0.84, 0.22)
    p.semer("R", 6)
    p.poser("@", 0.04, 0.5)
    p.poser("1", 0.12, 0.72)
    p.poser("2", 0.5, 0.35)
    p.poser("3", 0.52, 0.72)
    p.poser("4", 0.86, 0.6)
    p.semer("I", 2)
    return p


def route():  # 0_2 : route de l'est à l'ouest, charrettes renversées, falaises, péage
    p = Plan(27)
    p.bord("R", droite=HORIZ, gauche=HORIZ)
    p.peindre("R", lambda u, v: v < 0.18 or v > 0.82, sur=".")
    p.peindre(":", lambda u, v: abs(v - 0.5) < 0.05, sur=".")
    for u, v in ((0.3, 0.42), (0.62, 0.58), (0.78, 0.4)):
        p.poser("R", u, v)
    p.semer("A", 3, lambda u, v: 0.06 < u < 0.94 and 0.2 < v < 0.8)
    p.poser("@", 0.96, 0.5)
    p.poser("a", 0.2, 0.46)
    p.poser("1", 0.45, 0.3)
    p.poser("2", 0.6, 0.7)
    p.poser("3", 0.15, 0.68)
    p.semer("I", 1)
    return p


def abime():  # 1_3 : lac de lave, plate-forme centrale reliée par un pont, piliers
    p = Plan(28)
    p.bord("R", haut=VERT)
    plateforme = lambda u, v: abs(u - 0.5) < 0.2 and abs(v - 0.6) < 0.22
    pont = lambda u, v: abs(u - 0.5) < 0.045 and v < 0.4
    p.peindre("E", lambda u, v: v > 0.25 and not plateforme(u, v) and not pont(u, v) and 0.03 < u < 0.97 and v < 0.97, sur=".")
    p.peindre(":", pont)
    for u, v in ((0.38, 0.5), (0.62, 0.5), (0.4, 0.74), (0.6, 0.74)):
        p.poser("R", u, v, sur=".")
    p.semer("R", 3, lambda u, v: 0.06 < u < 0.94 and 0.05 < v < 0.22)
    p.poser("@", 0.5, 0.05)
    p.poser("1", 0.5, 0.62)
    p.poser("2", 0.25, 0.15)
    return p


if __name__ == "__main__":
    retoucher(C["crasse_roc_0_0"], bas=(7, 9))
    retoucher(C["crasse_roc_1_0"], droite=(15, 19), bas=(8, 10))
    ok = True
    for carte_id, dessin, palette in (("crasse_roc_0_1", rataillerie, "crasse_roc"), ("crasse_roc_2_0", puits, "crasse_roc"),
                                      ("crasse_roc_1_1", galerie, "crasse_roc"), ("crasse_roc_2_1", poste, "crasse_roc"),
                                      ("crasse_roc_2_2", carriere, "crasse_roc"), ("crasse_roc_1_2", forges, "forges"),
                                      ("crasse_roc_0_2", route, "crasse_roc"), ("crasse_roc_1_3", abime, "forges")):
        ok = ecrire_carte(C[carte_id], dessin(), palette=palette) and ok
    print("cartes écrites" + ("" if ok else " (avec des cases isolées)"))
