"""Métiers d'agriculteur, d'herboriste et de pêcheur (demande de l'auteur du 02/11/2026).

    python3 docs/design/recolte/produire.py      (depuis la racine du dépôt)

Écrit les trois métiers et leurs 30 ressources (une rare par nœud), les images (fragment
`art/manifestes/recolte.json`), trois cartes de récolte autour de Hautepierre (champs, prés, jardins
du fleuve) reliées à leurs voisines, et des coins de pêche sur chaque point d'eau des cartes
(poissons du palier des monstres de la carte). Relancer le script ne double rien.
"""
import json
import os
import sys

RACINE = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
sys.path.insert(0, os.path.join(RACINE, "docs", "design", "chantier3_brouillon", "src"))
from cartes import JEU, LIGNES, COLONNES, Plan, cellule, plan_de, verifier  # noqa: E402

PALIERS = [1, 3, 8, 15, 22]
QUANTITES = [[1, 3], [1, 2], [1, 2], [1, 2], [1, 2]]
XP = [5, 8, 12, 18, 25]
REPOUSSES = [[60, 120], [60, 120], [90, 150], [90, 150], [120, 180]]
PECHE = ["Â", "Ê", "Î", "Ô", "Û"]
# métier → (nom, description, apparence, icône, [(marqueur, id, nom, couleurs, matière, texte,
#   id rare, nom rare, texte rare)])
METIERS = {
    "agriculteur": ("Agriculteur", "Fauche les champs sauvages : céréales et fibres.", "champ", "gerbe", [
        ("B", "ble", "Blé", {"epi": "e8c860", "tige": "c8a848"}, "",
         "Du blé. Les humains en font du pain, les gobelins des projectiles.",
         "epi_dore", "Épi doré", "Un épi qui brille au soleil. Personne ne sait s'il se mange ou s'il se porte."),
        ("J", "lin", "Lin", {"epi": "8aa8e0", "tige": "7a9a58"}, "tissu",
         "Fibre souple et bleutée : la base des chemises qui grattent.",
         "lin_des_fees", "Lin des fées", "Si fin qu'on le voit à peine. Les elfes jurent l'avoir inventé."),
        ("K", "avoine", "Avoine", {"epi": "d8d0a0", "tige": "a8a070"}, "",
         "Les chevaux en raffolent, les aventuriers s'en contentent.",
         "avoine_du_champion", "Avoine du Champion", "Un cheval en a mangé une fois. Il a gagné une course qu'il ne courait pas."),
        ("S", "seigle", "Seigle", {"epi": "a88a58", "tige": "8a7448"}, "",
         "Un grain sombre qui tient au corps et à la mâchoire.",
         "seigle_ergote", "Seigle ergoté", "Taché de noir. À ne pas manger, à moins d'aimer les visions de troll dansant."),
        ("V", "chanvre", "Chanvre", {"epi": "6a9a3a", "tige": "4a7a2a"}, "tissu",
         "Fibre solide : cordes, licols, et sacs qui ne craquent pas.",
         "chanvre_d_acier", "Chanvre d'acier", "Une corde tressée avec ça a déjà retenu un olifant. Il s'en souvient."),
    ]),
    "herboriste": ("Herboriste", "Cueille les plantes des prés et des berges.", "plante", "brin", [
        ("O", "ortie", "Ortie", {"feuille": "4a8a3a", "fleur": "c8d890"}, "",
         "Elle pique. C'est sa façon de dire bonjour.",
         "ortie_royale", "Ortie royale", "Elle pique avec distinction, et exige qu'on la cueille avec des gants brodés."),
        ("Q", "trefle", "Trèfle", {"feuille": "5aa84a", "fleur": "f0f0f0"}, "",
         "Trois feuilles. Toujours trois. On a compté.",
         "trefle_a_quatre_feuilles", "Trèfle à quatre feuilles", "La chance en personne. Elle a pourtant mis du temps à se montrer."),
        ("P", "menthe_poivree", "Menthe poivrée", {"feuille": "3ac0a0", "fleur": "c8a8e8"}, "",
         "Fraîche au nez, brûlante au palais. Indécise, comme un elfe au marché.",
         "menthe_glaciale", "Menthe glaciale", "Une feuille et l'haleine gèle. Les dragons la détestent."),
        ("W", "sauge", "Sauge", {"feuille": "8aa898", "fleur": "8a6ac8"}, "",
         "La plante des sages. Elle ne rend pas sage, mais elle sent bon.",
         "sauge_des_anciens", "Sauge des Anciens", "Cueillie au pied d'une tour en ruine. Elle radote un peu."),
        ("Z", "piment_des_forges", "Piment des forges", {"feuille": "3a6a2a", "fleur": "e04020"}, "",
         "Il pousse près des fours. Les forgerons s'en servent pour se réveiller.",
         "piment_du_dragon", "Piment du Dragon", "Croqué une fois par un gobelin. On l'a retrouvé de l'autre côté de la rivière."),
    ]),
    "pecheur": ("Pêcheur", "Pêche depuis la berge, dans les remous des points d'eau.", "peche", "poisson", [
        ("Â", "goujon", "Goujon", {"ecaille": "a8a890", "ventre": "e8e0c8"}, "",
         "Petit, gris, et persuadé d'être un brochet.",
         "goujon_dore", "Goujon doré", "Un goujon qui a réussi. Il ne parle plus aux autres."),
        ("Ê", "perche", "Perche", {"ecaille": "8aa84a", "ventre": "e8c870"}, "",
         "Rayée comme un garde de la Citadelle, et aussi aimable.",
         "perche_arc_en_ciel", "Perche arc-en-ciel", "Toutes les couleurs à la fois. Les elfes la trouvent vulgaire."),
        ("Î", "truite", "Truite", {"ecaille": "7a8a6a", "ventre": "e8b0a0"}, "",
         "Elle remonte le courant par principe.",
         "truite_saumonee", "Truite saumonée", "Elle se prend pour un saumon. On n'ose pas la contrarier."),
        ("Ô", "brochet", "Brochet", {"ecaille": "5a7a4a", "ventre": "d8d8a8"}, "",
         "Des dents partout. Il mord l'hameçon, puis le pêcheur.",
         "brochet_centenaire", "Brochet centenaire", "Il a mangé trois cannes à pêche et un pêcheur distrait."),
        ("Û", "anguille_des_galeries", "Anguille des galeries", {"ecaille": "4a4a5a", "ventre": "8a8a7a"}, "",
         "Elle glisse entre les doigts et entre les lois du Syndicat.",
         "anguille_electrique", "Anguille électrique", "Elle pique comme une ortie royale, mais en plus vexée."),
    ]),
}
DECORS = {"champ": ("epis", "chaume", [25, 42]), "plante": ("plante", "plante_coupee", [22, 34]),
          "peche": ("remous", "remous_calme", [30, 15])}
CARTES = [  # id, nom, voisine, côté vers la voisine, ressources (marqueur, nombre), eau
    ("hautepierre_0_1", "Hautepierre — Champs de l'Ouest", "hautepierre_0_2", "bas",
     [("B", 6), ("J", 5), ("K", 4), ("S", 3), ("V", 2)], "etang"),
    ("hautepierre_0_3", "Hautepierre — Prés aux Simples", "hautepierre_0_2", "haut",
     [("O", 6), ("Q", 5), ("P", 4), ("W", 3), ("Z", 2)], "ruisseau"),
    ("hautepierre_1_4", "Hautepierre — Jardins du Fleuve", "hautepierre_2_4", "droite",
     [("K", 2), ("S", 3), ("V", 3), ("W", 3), ("Z", 3)], "fleuve"),
]
OPPOSE = {"haut": "bas", "bas": "haut", "gauche": "droite", "droite": "gauche"}


def lire(chemin):
    with open(chemin, encoding="utf-8") as f:
        return json.load(f)


def ecrire(chemin, donnees):
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(donnees, f, ensure_ascii=False, indent=2)
        f.write("\n")


def metiers_et_objets():
    images = {}
    for metier_id, (nom, description, apparence, icone, noeuds) in METIERS.items():
        ressources = []
        for k, (marqueur, oid, onom, couleurs, matiere, texte, rid, rnom, rtexte) in enumerate(noeuds):
            for i, n, t, rarete in ((oid, onom, texte, "commun"), (rid, rnom, rtexte, "rare")):
                objet = {"id": i, "nom": n, "type": "ressource", "rarete": rarete, "niveau": PALIERS[k], "description": t}
                if rarete == "rare":
                    objet["boutique"] = False
                if matiere:
                    objet["matiere"] = matiere
                ecrire(os.path.join(JEU, "data", "objets", i + ".json"), objet)
                clair = {c: v for c, v in couleurs.items()}
                if rarete == "rare":  # La version rare, plus vive : reflets dorés.
                    clair = {c: ("f0c040" if c in ("epi", "fleur", "ecaille") else v) for c, v in couleurs.items()}
                images["objet_" + i] = {"fichier": f"objets/{icone}.svgt", "ancre": [22, 22], "couleurs": clair}
            noeud_nom = onom.split(" ")[0] if metier_id != "pecheur" else "Remous (" + onom.lower() + ")"
            ressources.append({"marqueur": marqueur, "nom": noeud_nom, "objet": oid, "niveau": PALIERS[k],
                               "quantite": QUANTITES[k], "xp": XP[k], "repousse": REPOUSSES[k], "apparence": apparence,
                               "couleur": next(iter(couleurs.values())), "rare": rid})
            dessin, _, ancre = DECORS[apparence]
            images["noeud_" + oid] = {"fichier": f"decor/{dessin}.svgt", "ancre": ancre, "couleurs": couleurs}
        ecrire(os.path.join(JEU, "data", "metiers", metier_id + ".json"),
               {"id": metier_id, "nom": nom, "type": "recolte", "description": description, "ressources": ressources})
    for apparence, (_, vide, ancre) in DECORS.items():
        images[vide] = {"fichier": f"decor/{vide}.svgt", "ancre": ancre}
    ecrire(os.path.join(JEU, "art", "manifestes", "recolte.json"), {
        "images": images,
        "ressources": {n[0]: "noeud_" + n[1] for m in METIERS.values() for n in m[4]},
        "epuisees": {a: v[1] for a, v in DECORS.items()},
    })


def noeuds():
    return {n[0]: (k, m) for m, v in METIERS.items() for k, n in enumerate(v[4])}


def accessible(g, i, j):
    x, y = cellule(i, j)
    for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
        pi, pj = plan_de(*n)
        if 0 <= pi < LIGNES and 0 <= pj < COLONNES and g[pi][pj] in ".:@":
            return True
    return False


def cartes():
    for numero, (carte_id, nom, voisine, cote, ressources, eau) in enumerate(CARTES):
        p = Plan(graine=11 + numero)
        ouverture = (0.42, 0.58)
        p.bord("A", **{cote: ouverture})
        if eau == "etang":
            p.peindre("E", lambda u, v: ((u - 0.75) / 0.14) ** 2 + ((v - 0.35) / 0.12) ** 2 < 1)
        elif eau == "ruisseau":
            p.peindre("E", lambda u, v: abs(v - 0.62 - 0.12 * (u - 0.5)) < 0.035 and 0.06 < u < 0.94 and not 0.44 < u < 0.56)
        else:
            p.peindre("E", lambda u, v: abs(u + v - 1.25) < 0.08 and u > 0.04 and v > 0.06 and not 0.5 < u < 0.62)
        p.peindre(":", lambda u, v: abs(u - 0.5) < 0.03 if cote in ("haut", "bas") else abs(v - 0.5) < 0.03, sur=".")
        p.poser("@", *{"haut": (0.5, 0.06), "bas": (0.5, 0.94), "gauche": (0.06, 0.5), "droite": (0.94, 0.5)}[cote])
        p.semer("A", 10)
        for marqueur, nombre in ressources:  # `semer` ne vérifie l'accès qu'aux marqueurs « F… » : on passe par F.
            p.semer("F", nombre)
            p.g = [[marqueur if c == "F" else c for c in ligne] for ligne in p.g]
        p.boucher()
        texte = p.texte()
        verifier(carte_id, texte)
        ecrire(os.path.join(JEU, "data", "cartes", carte_id + ".json"),
               {"id": carte_id, "nom": nom, "sorties": {cote: voisine}, "palette": "hautepierre", "plan": texte})
        ouvrir(voisine, OPPOSE[cote], carte_id)


def ouvrir(carte_id, cote, vers):
    """Ouvre le bord `cote` de la carte au milieu (arbres, rochers et murs seulement)."""
    chemin = os.path.join(JEU, "data", "cartes", carte_id + ".json")
    carte = lire(chemin)
    g = [list(l) for l in carte["plan"]]
    if cote in ("haut", "bas"):
        cases = [(i, j) for i in (range(2) if cote == "haut" else range(LIGNES - 2, LIGNES)) for j in range(8, 11)]
    else:
        cases = [(i, j) for i in range(15, 18) for j in ((COLONNES - 1, COLONNES - 2) if cote == "droite" else (0, 1, 2))]
    for i, j in cases:
        if g[i][j] in "ARM":
            g[i][j] = "."
    carte["plan"] = ["".join(l) for l in g]
    carte["sorties"][cote] = vers
    verifier(carte_id, carte["plan"])
    ecrire(chemin, carte)


def niveau_de_carte(carte, monstres):
    niveaux = [lire(monstres[m]).get("niveau", 1) if m in monstres else 1
               for groupe in carte.get("groupes", []) for m in groupe.get("monstres", groupe.get("parmi", []))]
    return sum(niveaux) / len(niveaux) if niveaux else 1


def peche():
    """Deux ou trois coins de pêche par point d'eau : cases d'eau au bord d'une case praticable."""
    monstres = {}
    for racine, _, fichiers in os.walk(os.path.join(JEU, "data", "monstres")):
        for f in fichiers:
            monstres[f[:-5]] = os.path.join(racine, f)
    for f in sorted(os.listdir(os.path.join(JEU, "data", "cartes"))):
        chemin = os.path.join(JEU, "data", "cartes", f)
        carte = lire(chemin)
        g = [[("E" if c in PECHE else c) for c in l] for l in carte["plan"]]
        if len(g) != LIGNES or any(len(l) != COLONNES for l in g):
            continue  # Intérieur (maison) : pas d'eau.
        eaux = [(i, j) for i in range(LIGNES) for j in range(COLONNES) if g[i][j] == "E" and accessible(g, i, j)]
        if not eaux:
            continue
        niveau = niveau_de_carte(carte, monstres)
        if carte["id"].startswith("hautepierre_"):
            niveau = max(niveau, 12)
        haut = max([k for k, p in enumerate(PALIERS) if p <= niveau + 2] or [0])
        points, vus = [], set()
        for c in eaux:  # Points d'eau : cases d'eau voisines regroupées.
            if c in vus:
                continue
            groupe, pile = [], [c]
            vus.add(c)
            while pile:
                i, j = pile.pop()
                groupe.append((i, j))
                for d in eaux:
                    if d not in vus and abs(d[0] - i) <= 2 and abs(d[1] - j) <= 1:
                        vus.add(d)
                        pile.append(d)
            points.append(groupe)
        for groupe in points:
            nombre = min(len(groupe), 2 if len(groupe) < 12 else 3)
            pas = max(1, len(groupe) // nombre)
            for n, (i, j) in enumerate(groupe[::pas][:nombre]):
                g[i][j] = PECHE[max(0, haut - (n % 2))]
        carte["plan"] = ["".join(l) for l in g]
        ecrire(chemin, carte)


if __name__ == "__main__":
    metiers_et_objets()
    cartes()
    peche()
    print("Fait.")
