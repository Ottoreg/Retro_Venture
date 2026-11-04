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
sort("archange_jugement", "Jugement dernier", "Seul, l'Archange frappe tout ce qui l'entoure.", 3, (0, 0),
     [degats("sacre", 25, cibles="ennemis")], zone={"type": "cercle", "taille": 1}, lanceur_exclu=True)
sort("archange_exorcisme", "Exorcisme", "La cible sera achevée par les prochains dégâts Sacré.", 3, (1, 1),
     [{"type": "etat", "etat": "exorcisme", "duree": 2, "cibles": "ennemis"}])

ecrire("objets", {"id": "cle_celeste", "nom": "Clé céleste", "type": "quete", "rarete": "rare", "niveau": 1,
                  "description": "Saint Pierrot la réclame pour ouvrir la Tour céleste. Cupidon en a toujours une sur lui."})
ecrire("objets", {"id": "calice_toujours_ruisselant", "nom": "Calice toujours ruisselant", "type": "ressource", "rarete": "rare",
                  "niveau": 18, "boutique": False,
                  "description": "Remis par l'Archange Raphaël au sommet de la tour. Gravé sous le pied : « Un disciple aux "
                                 "trente brumes garde une coupe vide pour les visiteurs. Il sait déjà ce qu'il y versera. »"})
ecrire("passages", {"id": "tour_celeste", "nom": "Tour céleste", "carte": "celeste_0_0", "prix": 0, "toujours_connue": True})


SACRE = ["force", "intelligence"]
RESSOURCES = {  # monstre → [(id, nom, rareté, taux, caractéristique, valeur, description)] (demande de l'auteur du 04/11/2026)
    "colombe_baptiste": [
        ("plume_de_colombe", "Plume de colombe", "commun", 0.5, SACRE, 1, "Blanche comme une âme avant le premier mensonge."),
        ("bec_de_colombe", "Bec de colombe", "rare", 0.1, "dommages_sacre", 3, "Il a béni bien des crânes."),
        ("squelette_de_colombe", "Squelette de colombe", "legendaire", 0.005, "pm", 1, "Léger, si léger qu'il vole encore un peu.")],
    "ange": [
        ("plume_d_ange", "Plume d'ange", "commun", 0.35, SACRE, 3, "Tombée pendant une prière un peu trop agitée."),
        ("glaive_brise_d_ange", "Glaive brisé d'ange", "rare", 0.12, "dommages_acier", 3, "La paix, oui, mais armée."),
        ("sacre_coeur", "Sacré cœur", "legendaire", 0.005, SACRE, 30, "Il bat encore, et il juge.")],
    "lion_de_juda": [
        ("poil_de_criniere_leonin", "Poil de crinière léonin", "commun", 0.25, "dommages_sacre", 3, "Doré, soyeux, et plein de puces bénites."),
        ("croc_de_lion_feroce", "Croc de lion féroce", "rare", 0.05, "dommages_sacre", 9, "Il ne mordait que les pécheurs. Enfin, surtout."),
        ("cortex_feral", "Cortex féral", "legendaire", 0.005, "degats_devastateurs", 10, "Une colère sainte, en conserve.")],
    "archange_raphael": [
        ("tunique_dechiree_de_raphael", "Tunique déchirée de Raphaël", "commun", 0.55, "resistance_impie", 3, "L'Archange en a d'autres, il les fait laver au ciel."),
        ("aile_de_raphael", "Aile de Raphaël", "rare", 0.1, "soins_sacre", 10, "Elle guérit tout, sauf l'orgueil."),
        ("sacre_coeur_de_raphael", "Sacré cœur de Raphaël", "legendaire", 0.005, "soins", 30, "Un cœur qui soigne tout ce qu'il touche.")],
}
NIVEAUX = {"colombe_baptiste": 6, "ange": 9, "lion_de_juda": 15, "archange_raphael": 18}
for monstre_id, ressources in RESSOURCES.items():
    for id, nom, rarete, _, carac, valeur, description in ressources:
        ecrire("objets", {"id": id, "nom": nom, "type": "ressource", "rarete": rarete, "niveau": NIVEAUX[monstre_id],
                          "description": description, "caracteristique": carac, "valeur": valeur, "boutique": False})


def butin(monstre_id):
    return [{"objet": r[0], "taux": r[3]} for r in RESSOURCES.get(monstre_id, [])]


def monstre(id, nom, description, niveau, pv, pa, pm, initiative, sorts, ia, xp, ecus, **autres):
    ecrire("monstres", {"butin": butin(id), "id": id, "nom": nom, "description": description, **autres, "niveau": niveau,
                        "caracteristiques": {"pv": pv, "pa": pa, "pm": pm, "initiative": initiative},
                        "sorts": sorts, "ia": ia, "xp": xp, "ecus": ecus})


monstre("cupidon", "Cupidon", "Un angelot à l'arc rouge. Il garde la clé de la tour et ne vise jamais le cœur.",
        3, 25, 4, 3, 90, ["cupidon_fleche_cupide"], "tireur", 30, [2, 6], donjon=True,
        butin=[{"objet": "cle_celeste", "taux": 1.0, "par_joueur": True}])
monstre("ange", "Ange", "Il a fait vœu de paix. Il a aussi un glaive.", 9, 50, 6, 4, 100,
        ["ange_trait_de_lumiere", "ange_glaive"], "corps_a_corps", 110, [8, 18], donjon=True)
monstre("colombe_baptiste", "Colombe baptiste", "Elle bénit d'un coup de bec, puis s'enfuit à tire-d'aile.", 6, 30, 4, 10, 140,
        ["colombe_bapteme"], "distance", 70, [5, 12], donjon=True)
monstre("lion_de_juda", "Lion de Juda", "Il ne mange que les pécheurs. Les plus faibles d'abord.", 15, 150, 5, 3, 70,
        ["lion_griffe_de_juda", "lion_bond"], "chasseur", 200, [15, 35], donjon=True)
monstre("archange_raphael", "Archange Raphaël", "Le chef de chœur de la tour : il soigne les siens et exorcise les autres.",
        18, 120, 6, 5, 110, ["archange_benediction", "archange_exorcisme"], "corps_a_corps", 400, [40, 80], boss=True,
        seul={"message": "« Plus personne à bénir ? Alors, jugement ! »", "remplace": {"archange_benediction": "archange_jugement"}})


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
SORTIE = {"marqueur": "s", "id": "gardien_celeste", "nom": "Gardien des marches",  # Un par salle : on sort sans rien garder de l'avancée.
          "repliques": ["Trop de lumière ? Je vous raccompagne au parvis. Il faudra une autre clé pour remonter."],
          "entree": {"carte": "celeste_0_0"}}
piliers = {(12, 5): "M", (12, 13): "M", (20, 5): "M", (20, 13): "M"}
for n, (nom, monstres) in enumerate(SALLES, 1):
    # Groupe de nouveau là 5 à 10 s après le début du combat : les salles restent partagées.
    carte(f"tour_celeste_{n}", f"Tour céleste — {nom}", plan(15.5, True, {**piliers, (15, 9): "1", (27, 9): "@", (27, 11): "s"}),
          groupes=[{"monstres": monstres, "reapparition": [5, 10], "reapparition_au_combat": True}], pnj=[SORTIE],
          etage_suivant=f"tour_celeste_{n + 1}" if n < 5 else "tour_celeste_sommet")
carte("tour_celeste_sommet", "Tour céleste — Chœur de Raphaël", plan(15.5, True, {**piliers, (13, 9): "r", (27, 9): "@", (27, 11): "s"}),
      pnj=[SORTIE, {"marqueur": "r", "id": "raphael_sommet", "nom": "Archange Raphaël", "don": "calice_toujours_ruisselant",
                    "repliques": ["Bien combattu. Prenez ce calice : il ne se vide jamais, c'est bien là le problème.",
                                  "Plus haut, quelqu'un vous attend avec une coupe. Méfiez-vous de ceux qui comptent leurs pièces."]}])
