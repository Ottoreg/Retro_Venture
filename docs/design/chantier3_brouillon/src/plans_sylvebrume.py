"""Plans des cartes du lot Sylvebrume (production du chantier 3).

    python3 src/plans_sylvebrume.py      (depuis docs/design/chantier3_brouillon)

Écrit les 7 nouvelles cartes et retouche les 2 existantes (sorties, groupes). Les ressources Y et T
viendront avec le lot Métiers ; la porte de l'Orée du Sud vers Hautepierre avec le lot Hautepierre.
"""
from cartes import Plan, conception, ecrire_carte, retoucher

C = conception("sylvebrume")
HORIZ = (0.36, 0.64)
VERT = (0.40, 0.60)
INTERIEUR = lambda u, v: 0.06 < u < 0.94 and 0.06 < v < 0.94


def rond(p, car, cu, cv, ru, rv, sur="."):
    p.peindre(car, lambda u, v: ((u - cu) / ru) ** 2 + ((v - cv) / rv) ** 2 < 1, sur=sur)


def sous_bois():  # 0_1 : forêt dense, clairières rondes, ronds de sorcière, ruisseau
    p = Plan(31)
    p.bord(haut=VERT, droite=HORIZ)
    p.peindre("A", lambda u, v: INTERIEUR(u, v), sur=".")
    for cu, cv in ((0.5, 0.22), (0.25, 0.5), (0.7, 0.5), (0.45, 0.75)):
        rond(p, ".", cu, cv, 0.14, 0.17, sur="A")
    p.peindre(":", lambda u, v: abs(u - 0.5) < 0.03 and v < 0.25, sur="A.")
    # Sentiers horizontaux sur deux lignes : sur une seule, les cases ne se touchent pas.
    p.peindre(":", lambda u, v: abs(v - 0.5) < 0.04 and 0.25 < u < 0.97, sur="A.")
    p.peindre(":", lambda u, v: abs(u - 0.45) < 0.03 and 0.5 < v < 0.75, sur="A.")
    p.peindre(":", lambda u, v: abs(v - 0.36) < 0.04 and 0.25 < u < 0.5 or abs(u - 0.25) < 0.03 and 0.22 < v < 0.36, sur="A.")
    for cu, cv in ((0.5, 0.22), (0.25, 0.5), (0.7, 0.5)):
        p.poser("R", cu, cv)   # ronds de sorcière : un rocher au milieu de la clairière
    p.peindre("E", lambda u, v: 0.85 < v < 0.9 and 0.1 < u < 0.9, sur="A.:")
    p.peindre(".", lambda u, v: 0.84 < v < 0.91 and abs(u - 0.45) < 0.04)
    p.poser("@", 0.5, 0.05)
    p.poser("a", 0.62, 0.24)
    p.poser("1", 0.3, 0.44)
    p.poser("2", 0.74, 0.56)
    p.poser("3", 0.5, 0.8)
    p.semer("F", 3, sur="A")
    p.semer("U", 1)
    return p


def bosquet():  # 2_0 : source et ruisseau, autel (pavillon), couronne d'arbres, sol dégagé
    p = Plan(32)
    p.bord(gauche=HORIZ, bas=VERT)
    p.peindre("A", lambda u, v: INTERIEUR(u, v) and ((u - 0.5) / 0.46) ** 2 + ((v - 0.5) / 0.46) ** 2 > 1, sur=".")
    rond(p, "E", 0.55, 0.22, 0.06, 0.08)
    p.peindre("E", lambda u, v: abs(u - (0.55 + 0.1 * (v - 0.22))) < 0.03 and 0.22 < v < 0.95, sur=".")
    p.peindre(".", lambda u, v: abs(v - 0.55) < 0.035 and 0.5 < u < 0.7)          # gué
    p.decor("pavillon", 0.24, 0.3)
    p.semer("A", 4, lambda u, v: 0.2 < u < 0.8 and 0.2 < v < 0.8)
    p.poser("@", 0.04, 0.5)
    p.poser("a", 0.3, 0.38)
    p.poser("1", 0.3, 0.6)
    p.poser("2", 0.78, 0.35)
    p.poser("3", 0.8, 0.7)
    p.poser("4", 0.4, 0.82)
    p.semer("F", 2, sur="A")
    p.semer("C", 2, sur="A")
    return p


def coupe_rase():  # 1_1 : zone dégagée, souches, piles de troncs, lisière intacte, chemin de débardage
    p = Plan(33)
    p.bord(haut=VERT, bas=VERT, gauche=HORIZ, droite=HORIZ)
    p.peindre("A", lambda u, v: (u < 0.1 or u > 0.9 or v < 0.1 or v > 0.9) and not (0.4 < u < 0.6) and not (0.36 < v < 0.64), sur=".")
    p.peindre(":", lambda u, v: abs(u - 0.5) < 0.02, sur=".")
    p.semer("R", 9, lambda u, v: 0.12 < u < 0.88 and 0.12 < v < 0.88 and abs(u - 0.5) > 0.04)
    for cu, cv in ((0.25, 0.3), (0.72, 0.68)):
        p.mur_h("R", cv, cu - 0.06, cu + 0.06)   # piles de troncs
    p.poser("@", 0.5, 0.05)
    p.poser("a", 0.56, 0.22)
    p.poser("1", 0.3, 0.45)
    p.poser("2", 0.7, 0.3)
    p.poser("3", 0.35, 0.75)
    p.semer("C", 2, sur="A")
    return p


def scierie():  # 2_1 : rivière à droite, scierie au bord de l'eau, planches, enclos de rondins
    p = Plan(34)
    p.bord(haut=VERT, gauche=HORIZ, bas=VERT)
    p.peindre("E", lambda u, v: u > 0.82 and 0.02 < v < 0.98, sur=".")
    p.decor("maison", 0.7, 0.42)
    p.mur_h("M", 0.7, 0.2, 0.45)
    p.mur_h("M", 0.86, 0.2, 0.36)
    p.mur_v("M", 0.2, 0.7, 0.86)
    for u, v in ((0.6, 0.6), (0.62, 0.64), (0.55, 0.25)):
        p.poser("R", u, v)
    p.peindre(":", lambda u, v: abs(v - 0.5) < 0.02 and u < 0.6, sur=".")
    p.peindre(":", lambda u, v: abs(u - 0.5) < 0.02, sur=".")
    p.semer("A", 5, lambda u, v: 0.06 < u < 0.4 and 0.06 < v < 0.94)
    p.poser("@", 0.04, 0.5)
    p.poser("1", 0.3, 0.3)
    p.poser("2", 0.62, 0.78)
    p.poser("3", 0.3, 0.6)
    p.semer("F", 1, sur="A")
    return p


def toiles():  # 1_2 : arbres serrés, couloirs tortueux, clairières, pas de chemin
    p = Plan(35)
    p.bord(haut=VERT, gauche=HORIZ, droite=HORIZ)
    p.peindre("A", INTERIEUR, sur=".")
    trajet = [(0.5, 0.0), (0.5, 0.2), (0.3, 0.3), (0.0, 0.5), (0.25, 0.5), (0.3, 0.7), (0.55, 0.7), (0.7, 0.45), (1.0, 0.5)]
    for (u0, v0), (u1, v1) in zip(trajet, trajet[1:]):
        for k in range(41):
            t = k / 40
            rond(p, ".", u0 + (u1 - u0) * t, v0 + (v1 - v0) * t, 0.035, 0.06, sur="A")
    for cu, cv in ((0.3, 0.3), (0.3, 0.7), (0.7, 0.45), (0.55, 0.75)):
        rond(p, ".", cu, cv, 0.09, 0.12, sur="A")
    p.poser("@", 0.5, 0.05)
    p.poser("1", 0.3, 0.3)
    p.poser("2", 0.3, 0.7)
    p.poser("3", 0.7, 0.45)
    p.poser("4", 0.58, 0.76)
    p.semer("C", 1, sur="A")
    return p


def oree():  # 2_2 : arbres en haut, plaine en bas, tour de guet en ruine, sentier vers le bas
    p = Plan(36)
    p.bord(haut=VERT, gauche=HORIZ, bas=VERT)
    p.peindre("A", lambda u, v: v < 0.32 and INTERIEUR(u, v) and not (abs(u - 0.5) < 0.05), sur=".")
    p.peindre("A", lambda u, v: v < 0.32 and INTERIEUR(u, v) and u < 0.06, sur=".")
    p.peindre("R", lambda u, v: 0.65 < ((u - 0.5) / 0.08) ** 2 + ((v - 0.6) / 0.13) ** 2 < 1 and not (abs(u - 0.5) < 0.03 and v > 0.6), sur=".")
    p.peindre(":", lambda u, v: abs(u - 0.5) < 0.02 and (v < 0.45 or v > 0.75), sur=".")
    p.peindre(":", lambda u, v: abs(v - 0.5) < 0.02 and u < 0.42, sur=".")
    p.semer("A", 4, lambda u, v: 0.06 < u < 0.94 and 0.4 < v < 0.94)
    p.poser("@", 0.5, 0.05)
    p.poser("a", 0.56, 0.86)
    p.poser("1", 0.25, 0.7)
    p.poser("2", 0.78, 0.5)
    p.poser("3", 0.75, 0.82)
    return p


def coeur():  # 0_2 : clairière circulaire cernée d'arbres, cocons, une seule entrée à droite
    p = Plan(37)
    p.bord(droite=HORIZ)
    clairiere = lambda u, v: ((u - 0.45) / 0.3) ** 2 + ((v - 0.5) / 0.4) ** 2 < 1
    p.peindre("A", lambda u, v: INTERIEUR(u, v) and not clairiere(u, v) and not (u > 0.7 and abs(v - 0.5) < 0.07), sur=".")
    for u, v in ((0.32, 0.36), (0.58, 0.34), (0.3, 0.66), (0.6, 0.68), (0.45, 0.22)):
        p.poser("R", u, v)
    p.poser("@", 0.96, 0.5)
    p.poser("1", 0.42, 0.5)
    p.poser("2", 0.8, 0.5)
    return p


if __name__ == "__main__":
    retoucher(C["sylvebrume_0_0"], bas=(6, 8), profondeur=3)
    retoucher(C["sylvebrume_1_0"], droite=(15, 19), bas=(8, 10))
    ok = True
    for carte_id, dessin in (("sylvebrume_0_1", sous_bois), ("sylvebrume_2_0", bosquet), ("sylvebrume_1_1", coupe_rase),
                             ("sylvebrume_2_1", scierie), ("sylvebrume_1_2", toiles), ("sylvebrume_2_2", oree),
                             ("sylvebrume_0_2", coeur)):
        ok = ecrire_carte(C[carte_id], dessin(), palette="sylvebrume") and ok
    print("cartes écrites" + ("" if ok else " (avec des cases isolées)"))
