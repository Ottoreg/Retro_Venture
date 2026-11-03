#!/usr/bin/env python3
"""Matières de récolte orientées (demande de l'auteur du 03/11/2026) : chaque minerai, bois et tissu
récolté donne une caractéristique élémentaire, pour qu'un artisan choisisse sa matière selon l'objet
voulu (un minerai de Force pour une bague de Force). À chaque palier, la ressource commune et la rare
donnent deux éléments différents ; chaque matière offre les quatre. À lancer depuis la racine du dépôt.
"""
import json

CARACS = {
    # Minerai : cuivre (Flamme), fer (Acier), étain (Tempête), argent (Acier), obsidienne (Flamme).
    "minerai_de_cuivre": "intelligence", "cuivre_vert_de_gris": "perception",
    "minerai_de_fer": "force", "fer_meteorique": "agilite",
    "minerai_d_etain": "agilite", "etain_chantant": "intelligence",
    "minerai_d_argent": "force", "argent_lunaire": "perception",
    "obsidienne": "intelligence", "obsidienne_sanglante": "force",
    # Bois : frêne souple (Tempête), chêne (Acier), if (Givre), hêtre (Acier), malorme (Tempête).
    "bois_de_frene": "agilite", "coeur_de_frene": "perception",
    "bois_de_chene": "force", "chene_des_anciens": "intelligence",
    "bois_d_if": "perception", "if_funebre": "agilite",
    "bois_de_hetre": "force", "hetre_centenaire": "perception",
    "bois_de_malorme": "agilite", "malorme_ensorcelee": "intelligence",
    # Tissu.
    "lin": "agilite", "lin_des_fees": "intelligence", "chanvre": "perception", "chanvre_d_acier": "force",
}
for item_id, stat in CARACS.items():
    path = f"game/data/objets/{item_id}.json"
    d = json.load(open(path, encoding="utf-8"))
    d["caracteristique"] = stat
    open(path, "w", encoding="utf-8").write(json.dumps(d, ensure_ascii=False, indent=2) + "\n")
