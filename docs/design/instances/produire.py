"""Instances de métier (GDD § 10.3, demande de l'auteur du 03/11/2026) : le Cadastre près de Hautepierre et les cinq
cartes d'instance (champ, jardin, étang, bosquet, mine) avec leurs emplacements.

    python3 docs/design/instances/produire.py      (depuis la racine du dépôt ; relancer ne double rien)
"""
import os
import sys

RACINE = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
sys.path.insert(0, os.path.join(RACINE, "docs", "design", "chantier3_brouillon", "src"))
sys.path.insert(0, os.path.join(RACINE, "docs", "design", "recolte"))
from cartes import JEU, LIGNES, COLONNES, Plan, cellule, plan_de, verifier, ecran  # noqa: E402
from produire import lire, ecrire, ouvrir  # noqa: E402

CADASTRE = "hautepierre_0_0"
# métier → (id, nom, panneau, palette, sol de la zone, caractère de bord, eau)
INSTANCES = {
    "agriculteur": ("instance_champ", "Champ", "b", "hautepierre", "herbe", "A", False),
    "herboriste": ("instance_jardin", "Jardin", "c", "sylvebrume", "herbe", "A", False),
    "pecheur": ("instance_etang", "Étang", "d", "brumerive", "herbe", "A", True),
    "bucheron": ("instance_bosquet", "Bosquet", "e", "sylvebrume", "herbe", "A", False),
    "mineur": ("instance_mine", "Mine", "f", "crasse_roc", "parquet", "R", False),
}
EMPLACEMENTS = 48  # Plus que le maximum (40) : le joueur choisit où il pose.


def voisins(i, j):
    x, y = cellule(i, j)
    for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
        pi, pj = plan_de(*n)
        if 0 <= pi < LIGNES and 0 <= pj < COLONNES and not (pi % 2 == 1 and pj == 0):
            yield pi, pj


def emplacements(p, eau):
    """Cases d'emplacement : au bord de l'eau (étang), sinon des cases de sol choisies une à une pour que tout reste
    accessible une fois toutes plantées, chacune à côté d'une case praticable."""
    choisies = []
    candidates = [c for c in p.cases() if eau or 0.12 < ecran(*c)[0] < 0.88 and 0.15 < ecran(*c)[1] < 0.8]
    for i, j in sorted(candidates, key=lambda c: (c[0] % 3, c[1] % 2, c)):
        if len(choisies) >= EMPLACEMENTS:
            break
        if eau:
            if p.g[i][j] == "E" and any(p.g[a][b] == "." for a, b in voisins(i, j)):
                choisies.append((i, j))
            continue
        if p.g[i][j] != ".":
            continue
        p.g[i][j] = "A"
        if verifier("essai", p.texte()) and all(any(p.g[a][b] in ".:@" for a, b in voisins(x, y)) for x, y in choisies + [(i, j)]):
            choisies.append((i, j))
        else:
            p.g[i][j] = "."
    for i, j in choisies:
        if not eau:
            p.g[i][j] = "."
    return [[i, j] for i, j in choisies]


def instance(metier, carte_id, nom, _panneau, palette, sol, bord, eau):
    p = Plan(graine=31)
    p.bord(bord)
    if eau:
        p.peindre("E", lambda u, v: ((u - 0.3) / 0.16) ** 2 + ((v - 0.45) / 0.2) ** 2 < 1 or ((u - 0.7) / 0.16) ** 2 + ((v - 0.45) / 0.2) ** 2 < 1)
    p.poser("@", 0.5, 0.92)
    p.poser("a", 0.6, 0.9)
    p.peindre(":", lambda u, v: abs(u - 0.5) < 0.03 and 0.82 < v < 0.9, sur=".")
    p.boucher(bord)
    places = emplacements(p, eau)
    texte = p.texte()
    assert verifier(carte_id, texte), carte_id
    assert len(places) >= 40, (carte_id, len(places))
    carte = {"id": carte_id, "nom": "Instance — " + nom, "metier": metier, "palette": palette, "plan": texte,
             "emplacements": places, "pnj": [{"marqueur": "a", "id": "huissier_du_cadastre", "nom": "Huissier du Cadastre",
                                              "repliques": ["Vous sortez ? Je tamponne votre départ. Deux fois."],
                                              "entree": {"carte": CADASTRE}}]}
    if sol != "herbe":
        carte["sol"] = sol
    ecrire(os.path.join(JEU, "data", "cartes", carte_id + ".json"), carte)


def cadastre():
    p = Plan(graine=29)
    p.bord("A", bas=(0.42, 0.58))
    p.peindre(":", lambda u, v: abs(u - 0.5) < 0.03 and v > 0.5, sur=".")
    p.poser("@", 0.5, 0.94)
    p.poser("a", 0.5, 0.42)
    for n, (metier, (carte_id, nom, panneau, *_)) in enumerate(INSTANCES.items()):
        p.poser(panneau, 0.18 + 0.16 * n, 0.25)
    p.semer("A", 12)
    p.boucher()
    texte = p.texte()
    assert verifier(CADASTRE, texte)
    pnj = [{"marqueur": "a", "id": "notaire_du_cadastre", "nom": "Maître Tamponnet, notaire du Cadastre",
            "repliques": ["Bienvenue au Cadastre. Ici, chaque brin d'herbe a son acte de propriété, tamponné deux fois.",
                          "Un métier de récolte à 2 500 de réputation ? Le panneau de votre métier vous ouvre votre parcelle."],
            "explication": ["Instances de métier : à 2 500 de réputation d'un métier de récolte, son panneau ouvre votre parcelle "
                            "personnelle. Débloquez-y des ressources avec vos points de maîtrise du métier, posez-les sur les "
                            "emplacements : elles repoussent seules, même quand vous êtes ailleurs."]}]
    for metier, (carte_id, nom, panneau, *_) in INSTANCES.items():
        pnj.append({"marqueur": panneau, "id": "commis_" + carte_id, "nom": "Commis du Cadastre (%s)" % nom,
                    "repliques": ["%s : propriété privée. Accès réservé aux titulaires de 2 500 de réputation (%s)." % (nom, metier),
                                  "Revenez avec la réputation. Et le formulaire. Tamponné. Deux fois."],
                    "entree": {"carte": carte_id}})
    ecrire(os.path.join(JEU, "data", "cartes", CADASTRE + ".json"),
           {"id": CADASTRE, "nom": "Hautepierre — Le Cadastre", "sorties": {"bas": "hautepierre_0_1"}, "palette": "hautepierre",
            "plan": texte, "pnj": pnj})
    ouvrir("hautepierre_0_1", "haut", CADASTRE)


def dessins():
    couleurs = ["6a8a3a", "8a5a9a", "3a6a9a", "5a4632", "6a6a72"]
    pnj = {"notaire_du_cadastre": {"rig": "humain", "couleurs": {"tunique": "2e2e3a", "manches": "e8e0c8", "pantalon": "2a2a30",
                                                                  "cheveux": "b8b0a0"}, "accessoires": ["barbe"]},
           "huissier_du_cadastre": {"rig": "humain", "couleurs": {"tunique": "4a3a2a", "manches": "e8e0c8", "pantalon": "2a2a30",
                                                                   "cheveux": "3a2a1a"}}}
    for couleur, (carte_id, *_) in zip(couleurs, INSTANCES.values()):
        pnj["commis_" + carte_id] = {"rig": "humain", "couleurs": {"tunique": couleur, "manches": "e8e0c8", "pantalon": "3a3028",
                                                                    "cheveux": "6a4a2a"}, "accessoires": ["chapeau_paille"]}
    ecrire(os.path.join(JEU, "art", "manifestes", "instances.json"), {"pnj": pnj})


if __name__ == "__main__":
    dessins()
    cadastre()
    for metier, valeurs in INSTANCES.items():
        instance(metier, *valeurs)
