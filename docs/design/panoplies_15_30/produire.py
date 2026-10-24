#!/usr/bin/env python3
"""Panoplies élémentaires de niveau 15 et 30 (7 pièces, arme comprise).

Écrit les objets (`game/data/objets/`), les panoplies (`game/data/panoplies/`), les icônes
(`game/art/objets/`, dérivées des pièces de niveau 3 et d'armes existantes, recolorées, avec une
gemme d'argent au niveau 15 et d'or au niveau 30), le fragment de manifeste
`game/art/manifestes/panoplies_15_30.json` et les lignes de butin des monstres. Relançable : les
fichiers sont réécrits et une ligne de butin déjà présente n'est pas doublée.

Depuis la racine du dépôt : python3 docs/design/panoplies_15_30/produire.py
"""

import colorsys
import json
import re
from pathlib import Path

RACINE = Path(__file__).resolve().parents[3]
JEU = RACINE / "game"
OBJETS = JEU / "data" / "objets"
PANOPLIES = JEU / "data" / "panoplies"
MONSTRES = JEU / "data" / "monstres"
ICONES = JEU / "art" / "objets"
FRAGMENT = JEU / "art" / "manifestes" / "panoplies_15_30.json"

ELEMENTS = {
    # élément : caractéristiques, panoplie de niveau 3 dont on reprend les icônes
    "acier": (["force"], "forgeron_hargneux"),
    "flamme": (["intelligence"], "pyromane_repenti"),
    "givre": (["chance"], "bonhomme_de_neige"),
    "tempete": (["agilite"], "courant_d_air"),
    "sacre": (["force", "intelligence"], "enfant_de_choeur"),
    "impie": (["agilite", "chance"], "mauvais_oeil"),
}

# id, nom (avec article), élément, description, arme (type, source de l'icône),
# butin : (monstres de la coiffe, de la cape, de l'amulette et de l'arme), (des trois autres)
PANOS = {
    15: [
        ("enclume_rancuniere", "de l'Enclume Rancunière", "acier",
         "Forgée par un forgeron qui n'a jamais digéré qu'on lui demande un rabais.",
         ("Marteau", "masse_cerclee"),
         ["defonceur_de_portes", "gobelin_briseur"], ["troll_gastronome", "troll_des_ponts"]),
        ("pyromane_recidiviste", "du Pyromane Récidiviste", "flamme",
         "Il avait juré de ne plus rien brûler. Il a tenu trois semaines. Ses vêtements l'avaient prévenu.",
         ("Sceptre", "sceptre_de_hautepierre"),
         ["contremaitre_en_chef", "contremaitre_zele"], ["grouilleur_de_braise"]),
        ("yeti_frileux", "du Yéti Frileux", "givre",
         "Le yéti la portait par-dessus sa fourrure, avec une écharpe. Il avait quand même froid.",
         ("Bâton", "baton_gele"),
         ["grande_tisseuse", "tisseuse_de_brume"], ["arbre_calcine"]),
        ("coup_de_vent", "du Coup de Vent", "tempete",
         "Taillée pour aller vite. Les boutons, eux, sont partis devant.",
         ("Arc", "arc_d_if"),
         ["loup_cendreux"], ["corbac_chef_espion", "corbac_espion"]),
        ("bedeau_zele", "du Bedeau Zélé", "sacre",
         "Il sonne les cloches à l'heure, mouche les cierges à l'heure et frappe les hérétiques à l'heure.",
         ("Masse", "masse_benite"),
         ["abatteur_en_chef", "bucheron_de_brumerive"], ["pillard_emerite", "gobelin_pillard"]),
        ("chat_noir", "du Chat Noir", "impie",
         "Elle vous croise la route à chaque pas. Vos ennemis, eux, n'ont plus aucune chance.",
         ("Dague", "dague_du_mauvais_oeil"),
         ["chef_de_bande", "detrousseur"], ["grand_epouvantail", "epouvantail_demotive"]),
    ],
    30: [
        ("seigneur_des_enclumes", "du Seigneur des Enclumes", "acier",
         "Une enclume pour les gouverner toutes. Et dans le métal, les marteler.",
         ("Marteau", "masse_meteorique"),
         ["grondin"], ["olifant_a_tour", "olifant_de_guerre"]),
        ("dragon_retraite", "du Dragon Retraité", "flamme",
         "La garde-robe d'un dragon parti à la retraite. Il touche une pension en or et ne crache plus que sur la météo.",
         ("Sceptre", "sceptre_de_malorme"),
         ["marraine_cendree", "cendrillon"], ["souverain_cendre"]),
        ("hiver_qui_vient", "de l'Hiver Qui Vient", "givre",
         "On l'annonce depuis des années. Il est enfin arrivé, et il a apporté ses affaires.",
         ("Bâton", "fuseau_de_la_mere_toile"),
         ["gargouille_de_la_grande_porte", "gargouille"], ["troll_gastronome"]),
        ("tornade_mal_lunee", "de la Tornade Mal Lunée", "tempete",
         "Elle se lève du mauvais pied et emporte tout le monde avec elle.",
         ("Arc", "arc_de_malorme"),
         ["olifant_a_tour", "olifant_de_guerre"], ["corbac_chef_espion"]),
        ("inquisiteur_bienveillant", "de l'Inquisiteur Bienveillant", "sacre",
         "Il pose ses questions gentiment. Puis il insiste. Toujours avec bienveillance.",
         ("Masse", "masse_benite"),
         ["souverain_cendre"], ["grondin"]),
        ("porte_malheur", "du Porte-Malheur", "impie",
         "Tout ce qui peut mal tourner tourne mal. Pour les autres, surtout.",
         ("Dague", "dague_d_obsidienne"),
         ["chef_de_bande"], ["gargouille_de_la_grande_porte", "gargouille"]),
    ],
}

TYPES_A = ["coiffe", "cape", "amulette", "arme"]
TYPES_B = ["anneau", "ceinture", "bottes"]
NOMS_TYPES = {"coiffe": "Coiffe", "cape": "Cape", "amulette": "Amulette", "anneau": "Anneau",
              "ceinture": "Ceinture", "bottes": "Bottes"}

# Jets de la caractéristique principale et lignes secondaires, par niveau et emplacement.
PRINCIPALE = {
    15: {"coiffe": (9, 13), "cape": (8, 12), "amulette": (6, 9), "anneau": (7, 10),
         "ceinture": (8, 12), "bottes": (7, 10), "arme": (6, 9)},
    30: {"coiffe": (16, 22), "cape": (14, 20), "amulette": (10, 14), "anneau": (12, 17),
         "ceinture": (14, 20), "bottes": (10, 14), "arme": (12, 17)},
}
SECONDAIRES = {
    15: {"coiffe": {"vitalite": [12, 18]}, "cape": {"sagesse": [4, 6]}, "amulette": {"pa": [1, 1]},
         "anneau": {"vitalite": [8, 12]}, "ceinture": {"vitalite": [12, 18]},
         "bottes": {"initiative": [25, 40]}, "arme": {"vitalite": [8, 12]}},
    30: {"coiffe": {"vitalite": [25, 35]}, "cape": {"sagesse": [7, 10]}, "amulette": {"pa": [1, 1]},
         "anneau": {"vitalite": [15, 22]}, "ceinture": {"vitalite": [25, 35]},
         "bottes": {"pm": [1, 1]}, "arme": {"vitalite": [15, 22]}},
}
RARETE = {15: "peu_commun", 30: "rare"}

# Attaque des armes : coût, portée, relance, ligne de vue, dégâts.
ATTAQUES = {
    15: {"acier": (4, 1, 1, 1, False, 14, 20), "flamme": (4, 2, 6, 1, False, 12, 17),
         "givre": (3, 1, 4, 2, False, 10, 14), "tempete": (4, 2, 6, 1, True, 12, 17),
         "sacre": (4, 1, 1, 1, False, 14, 20), "impie": (3, 1, 1, 2, False, 9, 13)},
    30: {"acier": (4, 1, 1, 1, False, 21, 30), "flamme": (4, 2, 6, 1, False, 17, 25),
         "givre": (3, 1, 4, 2, False, 14, 20), "tempete": (4, 2, 7, 1, True, 17, 25),
         "sacre": (4, 1, 1, 1, False, 21, 30), "impie": (3, 1, 1, 2, False, 13, 19)},
}
ICONES_ATTAQUE = {"acier": "sort_arme_masse", "flamme": "sort_arme_sceptre", "givre": "sort_arme_baton",
                  "tempete": "sort_arme_arc", "sacre": "sort_arme_masse_benite",
                  "impie": "sort_arme_dague_impie"}

# Paliers du bonus de panoplie (2 à 7 pièces) : caractéristique principale (partagée en deux pour
# le Sacré et l'Impie), puis les autres bonus.
PALIERS = {
    15: [(15, {}), (30, {"dommages": 3}), (45, {"dommages": 6, "vitalite": 30}),
         (60, {"dommages": 9, "vitalite": 45, "portee": 1}),
         (80, {"dommages": 12, "vitalite": 60, "pm": 1, "portee": 1}),
         (100, {"dommages": 15, "vitalite": 80, "pa": 1, "pm": 1, "portee": 1})],
    30: [(30, {}), (60, {"dommages": 5}), (90, {"dommages": 10, "vitalite": 60}),
         (120, {"dommages": 15, "vitalite": 90, "portee": 1}),
         (160, {"dommages": 20, "vitalite": 120, "pa": 1, "pm": 1, "portee": 1}),
         (200, {"dommages": 25, "vitalite": 160, "pa": 2, "pm": 1, "portee": 2})],
}

# Taux de butin : famille, élite, élite ou boss seul (l'arme tombe aux trois quarts).
TAUX = {15: (0.03, 0.13, 0.04), 30: (0.02, 0.10, 0.08)}

# Teinte des icônes : assombries au niveau 15, plus saturées et profondes au niveau 30.
GEMMES = {15: ("#d8dde6", "#8a93a3"), 30: ("#ffd34a", "#b07a12")}


def ecrire(chemin, donnees):
    chemin.write_text(json.dumps(donnees, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def jets(lo, hi, part):
    return [max(1, round(lo * part)), max(1, round(hi * part))]


def bonus_objet(niveau, emplacement, stats):
    lo, hi = PRINCIPALE[niveau][emplacement]
    part = 1.0 if len(stats) == 1 else 0.55
    bonus = {stat: jets(lo, hi, part) for stat in stats}
    bonus.update(json.loads(json.dumps(SECONDAIRES[niveau][emplacement])))
    return bonus


def attaque(niveau, element):
    cout, pmin, pmax, relance, ldv, dmin, dmax = ATTAQUES[niveau][element]
    data = {"cout_pa": cout, "portee": {"min": pmin, "max": pmax}}
    if ldv:
        data["ligne_de_vue"] = True
    data["relance"] = {"par_tour": relance}
    data["effets"] = [{"type": "degats", "element": element, "min": dmin, "max": dmax}]
    return data


def teinte(svg, niveau):
    def couleur(m):
        hexa = m.group(1)
        if len(hexa) == 3:
            hexa = "".join(c * 2 for c in hexa)
        r, g, b = (int(hexa[i:i + 2], 16) / 255 for i in (0, 2, 4))
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        if niveau == 15:
            l, s = l * 0.82, min(1.0, s * 1.1)
        else:
            l, s = l * 0.9, min(1.0, s * 1.35 + 0.05)
            h = (h - 0.02) % 1.0
        r, g, b = colorsys.hls_to_rgb(h, l, s)
        return "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))
    svg = re.sub(r"#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b", couleur, svg)
    clair, sombre = GEMMES[niveau]
    gemme = ('<path d="M36 3 L40.5 7.5 L36 12 L31.5 7.5Z" fill="%s" stroke="#2a1c10" stroke-width="1.2" '
             'stroke-linejoin="round"/><path d="M36 3 L40.5 7.5 L36 7.5Z" fill="%s"/>' % (clair, sombre))
    if niveau == 30:
        gemme += '<circle cx="36" cy="7.5" r="0.9" fill="#ffffff"/>'
    return svg.replace("</svg>", gemme + "\n</svg>")


def main():
    images, icones_armes = {}, {}
    butin = {}  # monstre : lignes à ajouter
    for niveau, panos in PANOS.items():
        famille, elite, seul = TAUX[niveau]
        for set_id, nom, element, description, (nom_arme, source_arme), sources_a, sources_b in panos:
            stats, pano3 = ELEMENTS[element]
            objets = []
            for emplacement in TYPES_A[:3] + TYPES_B[:1] + TYPES_B[1:] + ["arme"]:
                item_id = "%s_%s" % ("arme" if emplacement == "arme" else emplacement, set_id)
                nom_objet = "%s %s" % (nom_arme if emplacement == "arme" else NOMS_TYPES[emplacement], nom)
                if emplacement == "arme":
                    item_id = "%s_%s" % (nom_arme.lower().replace("â", "a"), set_id)
                objet = {"id": item_id, "nom": nom_objet, "type": emplacement, "rarete": RARETE[niveau],
                         "niveau": niveau, "description": description,
                         "bonus": bonus_objet(niveau, emplacement, stats)}
                if emplacement == "arme":
                    objet["attaque"] = attaque(niveau, element)
                    icones_armes[item_id] = ICONES_ATTAQUE[element]
                ecrire(OBJETS / (item_id + ".json"), objet)
                objets.append(item_id)
                source = source_arme if emplacement == "arme" else "%s_%s" % (emplacement, pano3)
                svg = (ICONES / (source + ".svgt")).read_text(encoding="utf-8")
                (ICONES / (item_id + ".svgt")).write_text(teinte(svg, niveau), encoding="utf-8")
                images["objet_" + item_id] = {"fichier": "objets/%s.svgt" % item_id, "ancre": [22, 22]}
                sources = sources_b if emplacement in TYPES_B else sources_a
                for monstre in sources:
                    data = json.loads((MONSTRES / (monstre + ".json")).read_text(encoding="utf-8"))
                    if len(sources) == 1:
                        taux = seul
                    else:
                        taux = elite if data.get("elite", False) else famille
                    if emplacement == "arme":
                        taux = round(taux * 0.75, 4)
                    butin.setdefault(monstre, []).append({"objet": item_id, "taux": taux})
            bonus = {}
            for pieces, (valeur, autres) in enumerate(PALIERS[niveau], start=2):
                palier = {stat: -(-valeur // len(stats)) for stat in stats}
                palier.update(autres)
                bonus[str(pieces)] = palier
            ecrire(PANOPLIES / (set_id + ".json"),
                   {"id": set_id, "nom": "Panoplie " + nom, "orientation": element,
                    "objets": objets, "bonus": bonus})
    for monstre, lignes in butin.items():
        chemin = MONSTRES / (monstre + ".json")
        data = json.loads(chemin.read_text(encoding="utf-8"))
        presents = {ligne["objet"]: ligne for ligne in data["butin"]}
        for ligne in lignes:
            if ligne["objet"] in presents:
                presents[ligne["objet"]]["taux"] = ligne["taux"]
            else:
                data["butin"].append(ligne)
        ecrire(chemin, data)
    ecrire(FRAGMENT, {"images": images, "icones_armes": icones_armes})


if __name__ == "__main__":
    main()
