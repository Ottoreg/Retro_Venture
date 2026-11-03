#!/usr/bin/env python3
"""Matières de récolte orientées (demandes de l'auteur du 03/11/2026). Minerais et bois communs : une
caractéristique élémentaire (les quatre par matière), pour choisir sa matière selon l'objet voulu ; leurs
variantes rares renforcent cet élément : dommages de l'élément (minerais) ou résistance (bois). Tissus
récoltés : chanvre Initiative, lin Prospection, leurs rares +1 Portée. Les tissus de monstres donnent une
caractéristique élémentaire (fil de brume : Perception, échangée avec le registre des heures, qui passe
en Dommages, pour garder les éléments à égalité). À lancer depuis la racine du dépôt.
"""
import json

ELEMENTS = {"force": "acier", "intelligence": "flamme", "perception": "givre", "agilite": "tempete"}
MINERAIS = {"minerai_de_cuivre": ("intelligence", "cuivre_vert_de_gris"), "minerai_de_fer": ("force", "fer_meteorique"),
            "minerai_d_etain": ("agilite", "etain_chantant"), "minerai_d_argent": ("perception", "argent_lunaire"),
            "obsidienne": ("force", "obsidienne_sanglante")}
BOIS = {"bois_de_frene": ("agilite", "coeur_de_frene"), "bois_de_chene": ("force", "chene_des_anciens"),
        "bois_d_if": ("perception", "if_funebre"), "bois_de_hetre": ("force", "hetre_centenaire"),
        "bois_de_malorme": ("intelligence", "malorme_ensorcelee")}
CARACS = {"chanvre": "initiative", "lin": "prospection", "chanvre_d_acier": "portee", "lin_des_fees": "portee",
          "fil_de_brume": "perception", "registre_des_heures": "dommages"}
for prefixe, matieres in (("dommages_", MINERAIS), ("resistance_", BOIS)):
    for commun, (stat, rare) in matieres.items():
        CARACS[commun], CARACS[rare] = stat, prefixe + ELEMENTS[stat]
for item_id, stat in CARACS.items():
    path = f"game/data/objets/{item_id}.json"
    d = json.load(open(path, encoding="utf-8"))
    d["caracteristique"] = stat
    open(path, "w", encoding="utf-8").write(json.dumps(d, ensure_ascii=False, indent=2) + "\n")

# Tissus : seulement ceux de la récolte (lin, chanvre) ; les ressources de monstres (poils, paille, fils, soie,
# plumes) gardent leur caractéristique mais ne sont plus du tissu. Les plans de coiffe et de cape qui n'ont plus
# de tissu prennent un lin (un chanvre au palier 22 et plus).
lire = lambda p: json.load(open(p, encoding="utf-8"))
ecrire = lambda p, d: open(p, "w", encoding="utf-8").write(json.dumps(d, ensure_ascii=False, indent=2) + "\n")
for item_id in ["poil_scintillant", "paille_ensorcelee", "fil_de_brume", "soie_de_la_mere_toile", "plume_de_corbac"]:
    d = lire(f"game/data/objets/{item_id}.json")
    d.pop("matiere", None)
    ecrire(f"game/data/objets/{item_id}.json", d)
import glob
for path in glob.glob("game/data/objets/plan_*.json"):
    d = lire(path)
    recette = d["recette"]
    tissu = any(lire(f"game/data/objets/{r}.json").get("matiere") == "tissu" for r in recette["ressources"])
    if recette["type"] in ("coiffe", "cape") and not tissu:
        recette["ressources"]["chanvre" if d.get("niveau", 1) >= 22 else "lin"] = 1
        ecrire(path, d)
