"""Arcaniste (GDD § 4.3) : 8 sorts utilitaires, passif « Virtuose », rangs 3 et 5 des 10 sorts créés, icônes (SVG 44 × 44)
et fragment de manifeste `art/manifestes/arcaniste.json`.

    python3 docs/design/arcaniste/produire.py      # depuis la racine du dépôt
"""
import json
import os

GAME = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "game")
FOES = {"cibles": "ennemis"}


def spell(sid, name, text, pa, rng, effects, mastery, **extra):
    return {"id": "arcaniste_" + sid, "nom": name, "description": text, "cout_pa": pa, "portee": {"min": rng[0], "max": rng[1]},
            **extra, "effets": effects, "maitrise": mastery}


def bonus(carac, value, turns, **extra):
    return {"type": "bonus", "carac": carac, "min": value, "max": value, "duree": turns, **extra}


UTILITAIRES = [
    spell("clignement", "Clignement", "Un clignement d'yeux et il est ailleurs. Affinité Tempête : +1 portée.", 2, (1, 3),
          [{"type": "teleportation"}], {"3": {"delai": 1}, "5": {"portee_max": 1}}, relance={"par_tour": 1, "delai": 2},
          affinite={"element": "tempete", "portee_max": 1}),
    spell("retropropulsion", "Rétropropulsion", "Une petite explosion sous le nez de l'ennemi, et l'Arcaniste recule de 3 cases. Affinité Flamme : recule de 4.",
          2, (1, 1), [{"type": "degats", "element": "flamme", "min": 3, "max": 5, **FOES}, {"type": "recul", "min": 3, "max": 3, **FOES}],
          {"3": {"cout_pa": 1}, "5": {"effets": [{"type": "degats", "element": "flamme", "min": 3, "max": 5, "cibles": "ennemis", "autour_du_lanceur": True}]}},
          relance={"par_tour": 1, "delai": 2}, affinite={"element": "flamme", "effet": "recul", "valeur": 1}),
    spell("pieds_geles", "Pieds gelés", "Les pieds pris dans la glace : −2 PM. Affinité Givre : −3 PM.", 2, (1, 5),
          [{"type": "retrait_pm", "min": 2, "max": 2, **FOES}],
          {"3": {"portee_max": 1}, "5": {"effets": [{"type": "etat", "etat": "enracine", "duree": 1, **FOES}]}},
          relance={"par_tour": 2}, affinite={"element": "givre", "effet": "retrait_pm", "valeur": 1}),
    spell("appel_d_air", "Appel d'air", "Un courant d'air qui ramène l'ennemi de 3 cases vers lui. Affinité Tempête : 4 cases.", 3, (2, 6),
          [{"type": "attirance", "min": 3, "max": 3, "voisins": 0, **FOES}], {"3": {"cout_pa": 2}, "5": {"valeurs": {"voisins": 1}}},
          lancer_en_ligne=True, relance={"par_tour": 1, "delai": 1}, affinite={"element": "tempete", "effet": "attirance", "valeur": 1}),
    spell("mur_de_glace", "Mur de glace", "Trois blocs de glace en travers : on ne passe pas, on ne voit pas à travers (2 tours). Affinité Givre : +1 tour.",
          3, (1, 4), [{"type": "mur_de_glace", "duree": 2}], {"3": {"zone_taille": 2}, "5": {"delai": 2}}, zone={"type": "mur", "taille": 1},
          relance={"par_tour": 1, "delai": 3}, affinite={"element": "givre", "effet": "mur_de_glace", "duree": 1}),
    spell("manteau_de_braises", "Manteau de braises", "Un manteau de braises : −4 dégâts subis et 3 à 5 Flamme renvoyés à qui le frappe, 2 tours. Affinité Flamme : −6 dégâts subis.",
          2, (0, 0), [bonus("reduction_degats", 4, 2), {"type": "bonus", "carac": "epines_flamme_fixes", "min": 3, "max": 5, "duree": 2}],
          {"3": {"cout_pa": 1}, "5": {"valeurs": {"duree": 3}}}, relance={"par_tour": 1, "delai": 3},
          affinite={"element": "flamme", "effet": "bonus", "carac": "reduction_degats", "valeur": 2}),
    spell("conduction", "Conduction", "Il prête ses éléments : +15 dans la caractéristique de chacun de ses états (Flamme : Intelligence, Givre : Perception, Tempête : Agilité), 2 tours.",
          2, (0, 4), [{"type": "conduction", "min": 15, "max": 15, "duree": 2, "cibles": "allies"}], {"3": {"portee_max": 1}, "5": {"delai": 2}},
          relance={"par_tour": 1, "delai": 3}),
    spell("echo_arcanique", "Écho arcanique", "La formule résonne encore : crée le sort de ses états actuels, comme Fusion arcanique, même si elle a déjà servi ce tour.",
          2, (0, 0), [{"type": "creer_sort", "combinaisons": {}}], {"3": {"delai": 2}, "5": {"remise": 1}}, ligne_de_vue=False,
          relance={"par_tour": 1, "delai": 3}),
]
# Rangs 3 et 5 des sorts créés (en plus du +10 % par rang).
FOES_PM = {"type": "retrait_pm", "min": 1, "max": 1, **FOES}
CREATED = {
    "fournaise": {"3": {"valeurs": {"duree": 3}}, "5": {"portee_max": 1}},
    "choc_thermique": {"3": {"effets": [{"type": "malus", "carac": "resistance", "element": "flamme", "min": 5, "max": 5, "duree": 2}]}, "5": {"critique": 10}},
    "armure_de_givre": {"3": {"portee_max": 1}, "5": {"effets": [bonus("perception", 20, 2, cibles="allies")]}},
    "blizzard": {"3": {"effets": [FOES_PM]}, "5": {"zone_taille": 2}},
    "foudre_en_chaine": {"3": {"valeurs": {"distance": 3}}, "5": {"effets": [{"type": "rebond", "element": "tempete", "min": 2, "max": 3, "distance": 3}]}},
    "fulgurance": {"3": {"portee_max": 1}, "5": {"delai": 0}},
    "vent_arriere": {"3": {"effets": [bonus("pm", 1, 1, cibles="allies")]}, "5": {"delai": 0}},
    "feu_de_brousse": {"3": {"valeurs": {"duree": 3}}, "5": {"portee_max": 1}},
    "bourrasque_glacee": {"3": {"effets": [{"type": "poussee", "min": 1, "max": 1}]}, "5": {"effets": [FOES_PM]}},
    "cataclysme": {"3": {"delai": 1}, "5": {"effets": [FOES_PM]}},
}
PASSIF = {"id": "arcaniste_virtuose", "nom": "Virtuose", "effet": "virtuose",
          "description": "Débloqué au palier Apprenti. Chaque sort créé lancé dont la combinaison diffère de celle du sort créé précédent donne 1 cran de Virtuosité (3 au plus, jusqu'à la fin de son tour suivant) : +3 % de dégâts par cran (+1 % par rang). Rang 3 : à 3 crans, Fusion arcanique coûte 0 PA. Rang 5 : le 3e cran donne +1 PM pour le tour."}

# Icônes : Flamme orange, Givre bleu, Tempête vert, comme les sorts créés.
FRAMES = {"f": ("#ffb36b", "#7a2a0e"), "g": ("#a8e2ff", "#1c3f7a"), "t": ("#9ef0a8", "#1a5a2e"), "a": ("#d8b8ff", "#3a1c6a")}
DRAWINGS = {
    "clignement": ("t", '<path d="M8 22 Q22 8 36 22 Q22 36 8 22 Z" fill="none" stroke="#f0fff2" stroke-width="2.4"/><circle cx="22" cy="22" r="4" fill="#f0fff2"/><path d="M34 8 l-4 6 h4 l-4 6" stroke="#ffe27a" stroke-width="2" fill="none"/>'),
    "retropropulsion": ("f", '<circle cx="30" cy="24" r="7" fill="#ffd27a" stroke="#fff3c8" stroke-width="1.6"/><path d="M22 24 H8 M12 19 L7 24 L12 29" stroke="#fff3c8" stroke-width="2.6" fill="none"/>'),
    "pieds_geles": ("g", '<path d="M12 34 h8 v-8 h-5 z M24 34 h8 v-8 h-5 z" fill="#3a2a1c"/><path d="M8 32 H36" stroke="#e8fbff" stroke-width="5" opacity="0.8"/><path d="M14 14 L22 8 L30 14" stroke="#e8fbff" stroke-width="2" fill="none"/>'),
    "appel_d_air": ("t", '<path d="M36 14 Q20 14 20 22 Q20 30 36 30" stroke="#f0fff2" stroke-width="2.4" fill="none"/><path d="M8 22 H22 M13 17 L8 22 L13 27" stroke="#f0fff2" stroke-width="2.6" fill="none"/>'),
    "mur_de_glace": ("g", '<rect x="7" y="16" width="9" height="18" fill="#cfefff" stroke="#ffffff" stroke-width="1.2"/><rect x="17.5" y="12" width="9" height="22" fill="#bfe4f4" stroke="#ffffff" stroke-width="1.2"/><rect x="28" y="16" width="9" height="18" fill="#cfefff" stroke="#ffffff" stroke-width="1.2"/>'),
    "manteau_de_braises": ("f", '<path d="M14 10 Q22 6 30 10 L34 36 H10 Z" fill="#8a2a10" stroke="#ffd27a" stroke-width="1.6"/>' + "".join(f'<circle cx="{x}" cy="{y}" r="2" fill="#ffb02e"/>' for x, y in [(16, 20), (26, 16), (22, 28), (30, 30), (14, 32)])),
    "conduction": ("a", '<circle cx="12" cy="30" r="5" fill="#ff8a3a"/><circle cx="22" cy="12" r="5" fill="#7ac8e8"/><circle cx="32" cy="30" r="5" fill="#5ad06a"/><path d="M12 30 L22 12 L32 30 Z" fill="none" stroke="#ffffff" stroke-width="1.6" stroke-dasharray="3 2"/>'),
    "echo_arcanique": ("a", '<circle cx="22" cy="22" r="5" fill="#ffffff"/>' + "".join(f'<circle cx="22" cy="22" r="{r}" fill="none" stroke="#f4eaff" stroke-width="1.6" opacity="{o}"/>' for r, o in [(10, 0.9), (14, 0.6), (18, 0.3)])),
    "virtuose": ("a", '<path d="M10 32 Q16 10 22 22 Q28 34 34 12" stroke="#ffffff" stroke-width="2.6" fill="none"/><circle cx="10" cy="32" r="3" fill="#ff8a3a"/><circle cx="22" cy="22" r="3" fill="#7ac8e8"/><circle cx="34" cy="12" r="3" fill="#5ad06a"/>'),
}


def path(folder, sid):
    return os.path.join(GAME, "data", folder, sid + ".json")


def write(folder, data):
    with open(path(folder, data["id"]), "w", encoding="utf-8") as f:
        f.write(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


with open(path("sorts", "arcaniste_creer_un_sort"), encoding="utf-8") as f:
    UTILITAIRES[-1]["effets"][0]["combinaisons"] = json.load(f)["effets"][0]["combinaisons"]
for data in UTILITAIRES:
    write("sorts", data)
for name, mastery in CREATED.items():
    with open(path("sorts", "arcaniste_" + name), encoding="utf-8") as f:
        data = json.load(f)
    data["maitrise"] = mastery
    write("sorts", data)
with open(path("voies", "arcaniste"), encoding="utf-8") as f:
    voie = json.load(f)
voie["sorts"] = ["arcaniste_composition", "arcaniste_creer_un_sort"] + [s["id"] for s in UTILITAIRES]
voie["passif"] = PASSIF
write("voies", voie)
images = {}
for name, (kind, body) in DRAWINGS.items():
    light, dark = FRAMES[kind]
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="44" height="44" viewBox="0 0 44 44">\n'
           f'<defs><radialGradient id="f" cx="0.35" cy="0.3" r="0.9"><stop offset="0" stop-color="{light}"/><stop offset="1" stop-color="{dark}"/></radialGradient></defs>\n'
           f'<rect x="1.5" y="1.5" width="41" height="41" rx="7" fill="url(#f)" stroke="#2a1c10" stroke-width="2"/>\n{body}\n</svg>\n')
    with open(os.path.join(GAME, "art", "sorts", f"arcaniste_{name}.svgt"), "w") as f:
        f.write(svg)
    images[f"sort_arcaniste_{name}"] = {"fichier": f"sorts/arcaniste_{name}.svgt", "ancre": [22, 22]}
with open(os.path.join(GAME, "art", "manifestes", "arcaniste.json"), "w", encoding="utf-8") as f:
    f.write(json.dumps({"images": images}, ensure_ascii=False, indent=2) + "\n")
