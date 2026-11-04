#!/usr/bin/env python3
"""Tour céleste réduite (demande de l'auteur, 04/11/2026) : écrit les monstres, sorts, la clé, la
Pierre de Passage et les cartes (parvis + 5 étages) dans game/data. Depuis la racine du dépôt :

    python3 docs/design/tour_celeste/produire.py && (cd game && for f in data/cartes/*celeste*.json; do python3 tools/placement.py $f --ecrire; done)
"""
import json
from pathlib import Path

DATA = Path(__file__).resolve().parents[3] / "game" / "data"


def ecrire(dossier, contenu):
    (DATA / dossier / f"{contenu['id']}.json").write_text(json.dumps(contenu, ensure_ascii=False, indent=2) + "\n")


def sort(id, nom, description, pa, portee, effets, par_tour=1, delai=0, **autres):
    ecrire("sorts", {"id": id, "nom": nom, "description": description, "cout_pa": pa,
                     "portee": {"min": portee[0], "max": portee[1]}, "ligne_de_vue": True,
                     "relance": {"par_tour": par_tour, "delai": delai}, **autres, "effets": effets})


def degats(element, valeur, maxi=None, **autres):
    return {"type": "degats", "element": element, "min": valeur, "max": maxi or valeur, **autres}


sort("cupidon_fleche_cupide", "Flèche cupide", "Elle ne rend personne amoureux, mais elle vole quelques PV.",
     4, (1, 5), [degats("flamme", 10, vol=True)])
sort("ange_trait_de_lumiere", "Trait de lumière", "Un rayon sacré, tiré de loin par prudence.", 4, (2, 7), [degats("sacre", 25)])
sort("ange_glaive", "Glaive", "Deux coups de glaive valent mieux qu'un sermon.", 3, (1, 1), [degats("acier", 20)], par_tour=2)
sort("colombe_bapteme", "Baptême express", "Un coup de bec bénit, puis elle s'envole.", 4, (1, 2), [degats("sacre", 10)])
sort("lion_griffe_de_juda", "Griffe de Juda", "Un coup de patte imprévisible.", 5, (1, 1), [degats("sacre", 1, 50)])
sort("lion_bond", "Bond", "Le lion saute sur sa proie (un tour sur deux).", 4, (1, 3), [{"type": "teleportation"}], delai=2)
sort("archange_benediction", "Bénédiction de Raphaël", "Une croix de lumière qui soigne les alliés.", 3, (1, 5),
     [{"type": "soin", "element": "sacre", "min": 20, "max": 20, "cibles": "allies"}],
     lancer_en_ligne=True, zone={"type": "croix_latine"})
sort("archange_exorcisme", "Exorcisme", "La cible sera achevée par les prochains dégâts Sacré.", 3, (1, 1),
     [{"type": "etat", "etat": "exorcisme", "duree": 2, "cibles": "ennemis"}])

ecrire("objets", {"id": "cle_celeste", "nom": "Clé céleste", "type": "quete", "rarete": "rare", "niveau": 1,
                  "description": "Saint Pierrot la réclame pour ouvrir la Tour céleste. Cupidon en a toujours une sur lui."})
ecrire("passages", {"id": "tour_celeste", "nom": "Tour céleste", "carte": "celeste_0_0", "prix": 0, "toujours_connue": True})


def monstre(id, nom, description, niveau, pv, pa, pm, initiative, sorts, ia, xp, ecus, **autres):
    ecrire("monstres", {"id": id, "nom": nom, "description": description, **autres, "niveau": niveau,
                        "caracteristiques": {"pv": pv, "pa": pa, "pm": pm, "initiative": initiative},
                        "sorts": sorts, "ia": ia, "xp": xp, "ecus": ecus})


monstre("cupidon", "Cupidon", "Un angelot à l'arc rouge. Il garde la clé de la tour et ne vise jamais le cœur.",
        3, 25, 4, 3, 90, ["cupidon_fleche_cupide"], "distance", 30, [2, 6], donjon=True,
        butin=[{"objet": "cle_celeste", "taux": 1.0}])
monstre("ange", "Ange", "Il a fait vœu de paix. Il a aussi un glaive.", 9, 50, 6, 4, 100,
        ["ange_trait_de_lumiere", "ange_glaive"], "corps_a_corps", 110, [8, 18], donjon=True)
monstre("colombe_baptiste", "Colombe baptiste", "Elle bénit d'un coup de bec, puis s'enfuit à tire-d'aile.", 6, 30, 4, 10, 140,
        ["colombe_bapteme"], "distance", 70, [5, 12], donjon=True)
monstre("lion_de_juda", "Lion de Juda", "Il ne mange que les pécheurs. Les plus faibles d'abord.", 15, 150, 5, 3, 70,
        ["lion_griffe_de_juda", "lion_bond"], "chasseur", 200, [15, 35], donjon=True)
monstre("archange_raphael", "Archange Raphaël", "Le chef de chœur de la tour : il soigne les siens et exorcise les autres.",
        18, 120, 6, 5, 110, ["archange_benediction", "archange_exorcisme"], "corps_a_corps", 400, [40, 80], boss=True)


def plan(rang, bord, poser):
    """Ellipse de sol au milieu du ciel (E) ; `bord` : rangée de murs (M) sur son pourtour ; `poser` : {(ligne, colonne): caractère}."""
    lignes = []
    for i in range(33):
        ligne = ""
        for j in range(19):
            if i % 2 == 1 and j == 0:
                ligne += " "
                continue
            x, y = (64 * j - 32 * (i % 2) - 576) / 560, (16 * i - 256) / (rang * 16)
            d = x * x + y * y
            ligne += poser.get((i, j), "E" if d > 1 else ("M" if bord and d > 0.72 else "."))
        lignes.append(ligne)
    return lignes


def carte(id, nom, lignes, groupes=(), pnj=(), etage_suivant=None):
    contenu = {"id": id, "nom": nom, "palette": "celeste", "plan": lignes}
    if groupes:
        contenu["groupes"] = list(groupes)
    if pnj:
        contenu["pnj"] = list(pnj)
    if etage_suivant:
        contenu["etage_suivant"] = etage_suivant
    ecrire("cartes", contenu)


tour = {(i, j): "M" for i in range(3, 9) for j in range(7, 12)}
carte("celeste_0_0", "Tour céleste — Parvis des nuées",
      plan(15.5, False, {**tour, (10, 9): "a", (6, 4): "R", (20, 15): "R", (24, 3): "R", (17, 14): "1", (25, 5): "*", (27, 9): "@"}),
      groupes=[{"monstres": ["cupidon"], "reapparition": [20, 30]}],
      pnj=[{"marqueur": "a", "id": "saint_pierrot", "nom": "Saint Pierrot, portier céleste",
            "repliques": ["Halte ! Pas de clé, pas de tour. Le règlement, c'est le règlement.",
                          "Le petit Cupidon en garde toujours une. Il ne la lâche qu'aux plus convaincants."],
            "entree": {"carte": "tour_celeste_1", "cle": "cle_celeste"}}])
SALLES = [
    ("Premier étage", ["colombe_baptiste", "colombe_baptiste", "colombe_baptiste", "ange"]),
    ("Deuxième étage", ["lion_de_juda", "ange", "ange", "colombe_baptiste"]),
    ("Troisième étage", ["lion_de_juda", "lion_de_juda", "lion_de_juda", "colombe_baptiste"]),
    ("Quatrième étage", ["ange", "ange", "ange", "lion_de_juda"]),
    ("Sommet, salle de l'Archange", ["archange_raphael", "ange", "lion_de_juda", "colombe_baptiste"]),
]
for n, (nom, monstres) in enumerate(SALLES, 1):
    piliers = {(12, 5): "M", (12, 13): "M", (20, 5): "M", (20, 13): "M"}
    carte(f"tour_celeste_{n}", f"Tour céleste — {nom}", plan(15.5, True, {**piliers, (15, 9): "1", (27, 9): "@"}),
          groupes=[{"monstres": monstres, "reapparition": [60, 60] if n == 5 else [30, 45]}],
          etage_suivant=f"tour_celeste_{n + 1}" if n < 5 else "celeste_0_0")
