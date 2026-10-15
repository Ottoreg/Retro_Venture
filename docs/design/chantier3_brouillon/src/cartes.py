"""Outils de dessin des plans de cartes pour la production du chantier 3 (voir plans_<lot>.py).

Un plan fait 19 caractères × 33 lignes ; les lignes impaires commencent par un espace (demi-case).
On dessine en coordonnées d'écran normalisées : u de 0 (bord gauche) à 1 (bord droit), v de 0
(haut) à 1 (bas), ce qui rend les formes (rivière en diagonale, rangées, enclos) faciles à placer.
"""
import json
import os
import random
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
JEU = os.path.normpath(os.path.join(ICI, "..", "..", "..", "..", "game"))
sys.path.insert(0, os.path.join(JEU, "tools"))
from placement import proposer  # noqa: E402

LIGNES, COLONNES = 33, 19
W, H = 64 * (COLONNES - 1), 16 * (LIGNES - 1)
PRATICABLE = set(".:@+") | set("123456789") | set("abcdefghijklmnopqrstuvwxyz")


def ecran(i, j):
    return (64 * j - 32 * (i % 2)) / W, (16 * i) / H


def cellule(i, j):
    """Case de la grille du jeu (comme GameMap.plan_cell)."""
    row = i + 1
    half = 2 * j + row % 2
    return ((row + half) // 2, (row - half) // 2)


def plan_de(x, y):
    row, half = x + y, x - y
    return row - 1, (half - row % 2) // 2


class Plan:
    def __init__(self, graine=1):
        self.g = [[" " if (i % 2 == 1 and j == 0) else "." for j in range(COLONNES)] for i in range(LIGNES)]
        self.rng = random.Random(graine)
        self.decors = []

    def cases(self):
        for i in range(LIGNES):
            for j in range(COLONNES):
                if not (i % 2 == 1 and j == 0):
                    yield i, j

    def peindre(self, car, test, sur=None):
        """Met `car` sur chaque case où test(u, v) est vrai (seulement sur les caractères `sur`)."""
        for i, j in self.cases():
            u, v = ecran(i, j)
            if test(u, v) and (sur is None or self.g[i][j] in sur):
                self.g[i][j] = car

    def bord(self, car="A", haut=None, bas=None, gauche=None, droite=None):
        """Bordure d'arbres ; ouvertures en u (haut, bas) ou en v (gauche, droite) : (min, max)."""
        for i, j in self.cases():
            u, v = ecran(i, j)
            au_bord = i == 0 or i == LIGNES - 1 or u <= 0.03 or u >= 0.97
            if not au_bord:
                continue
            ouvert = ((i == 0 and haut and haut[0] <= u <= haut[1]) or
                      (i == LIGNES - 1 and bas and bas[0] <= u <= bas[1]) or
                      (u <= 0.03 and gauche and gauche[0] <= v <= gauche[1]) or
                      (u >= 0.97 and droite and droite[0] <= v <= droite[1]))
            self.g[i][j] = "." if ouvert else car

    def mur_h(self, car, v, u0, u1, sur="."):
        """Mur horizontal à l'écran : une ligne du plan (infranchissable en déplacement)."""
        self.peindre(car, lambda u, vv: abs(vv - v) <= 8 / H and u0 <= u <= u1, sur)

    def mur_v(self, car, u, v0, v1, sur="."):
        """Mur vertical à l'écran : une case par ligne, lignes paires et impaires (sans trou)."""
        self.peindre(car, lambda uu, v: abs(uu - u) < 32 / W and v0 <= v <= v1, sur)

    def boucher(self, car="A"):
        """Remplit les cases praticables coupées du départ ; signale les groupes ou PNJ coupés."""
        texte = self.texte()
        praticables = {cellule(i, j): (i, j) for i, j in self.cases() if texte[i][j] in PRATICABLE}
        depart = next(cellule(i, j) for i, j in self.cases() if texte[i][j] == "@")
        vus, pile = {depart}, [depart]
        while pile:
            x, y = pile.pop()
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if n in praticables and n not in vus:
                    vus.add(n)
                    pile.append(n)
        for c, (i, j) in praticables.items():
            if c not in vus:
                if self.g[i][j] in ".:":
                    self.g[i][j] = car
                else:
                    print(f"  « {self.g[i][j]} » coupé du départ en ligne {i}, colonne {j}")

    def poser(self, car, u, v, sur="."):
        """Pose `car` sur la case libre la plus proche de (u, v) ; renvoie (ligne, colonne)."""
        meilleure = min((c for c in self.cases() if self.g[c[0]][c[1]] in sur),
                        key=lambda c: (ecran(*c)[0] - u) ** 2 + ((ecran(*c)[1] - v) * H / W) ** 2)
        self.g[meilleure[0]][meilleure[1]] = car
        return meilleure

    def semer(self, car, n, zone=lambda u, v: 0.06 < u < 0.94 and 0.08 < v < 0.92, sur="."):
        libres = [c for c in self.cases() if self.g[c[0]][c[1]] in sur and zone(*ecran(*c))]
        for i, j in self.rng.sample(libres, min(n, len(libres))):
            self.g[i][j] = car

    def decor(self, image, u, v):
        """Grand décor 3 × 3 (maison, auberge, cabane…) dont la case avant est près de (u, v)."""
        i, j = self.poser("#", u, v, sur=".:")
        x, y = cellule(i, j)
        for dx in range(3):
            for dy in range(3):
                pi, pj = plan_de(x - dx, y - dy)
                self.g[pi][pj] = "#"
        self.decors.append({"image": image, "case": [i, j]})
        return i, j

    def texte(self):
        return ["".join(ligne) for ligne in self.g]


def verifier(nom, plan):
    """Toutes les cases praticables accessibles depuis le départ (comme le test du jeu)."""
    praticables = {cellule(i, j) for i, ligne in enumerate(plan) for j, c in enumerate(ligne)
                   if c in PRATICABLE and not (i % 2 == 1 and j == 0)}
    depart = next(cellule(i, j) for i, ligne in enumerate(plan) for j, c in enumerate(ligne) if c == "@")
    vus, pile = {depart}, [depart]
    while pile:
        x, y = pile.pop()
        for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if n in praticables and n not in vus:
                vus.add(n)
                pile.append(n)
    isolees = praticables - vus
    if isolees:
        print(f"{nom} : {len(isolees)} case(s) praticable(s) isolée(s) : {sorted(plan_de(*c) for c in isolees)[:8]}")
    return not isolees


def ecrire_carte(conception, plan, decors=(), portes=None, compter=True):
    """Carte du jeu d'après la conception (nom, sorties, groupes, PNJ) et le plan dessiné."""
    if isinstance(plan, Plan):
        plan.boucher()
    texte = plan.texte() if isinstance(plan, Plan) else plan
    ok = verifier(conception["id"], texte)
    if compter:
        voulu = {k: v for k, v in conception.get("ressources", {}).items() if k in "FCUI"}
        compte = {k: sum(ligne.count(k) for ligne in texte) for k in voulu}
        if compte != voulu:
            print(f"{conception['id']} : ressources {compte} au lieu de {voulu}")
    carte = {"id": conception["id"], "nom": conception["nom"], "sorties": conception["sorties"]}
    if portes:
        carte["portes"] = portes
    carte["plan"] = texte
    if conception.get("groupes"):
        carte["groupes"] = conception["groupes"]
    pnj = [{k: p[k] for k in ("marqueur", "id", "nom", "repliques")} for p in conception.get("pnj", [])]
    if pnj:
        carte["pnj"] = pnj
    tous_decors = list(decors) + (plan.decors if isinstance(plan, Plan) else [])
    if tous_decors:
        carte["decors"] = tous_decors
    if conception.get("groupes"):
        carte["placement"] = proposer(texte)
    chemin = os.path.join(JEU, "data", "cartes", conception["id"] + ".json")
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(carte, f, ensure_ascii=False, indent=2)
        f.write("\n")
    return ok


def conception(lot):
    with open(os.path.join(ICI, "..", "chantier3_contenu.json"), encoding="utf-8") as f:
        d = json.load(f)
    return {c["id"]: c for c in d["cartes"] if c["zone"] == lot}
