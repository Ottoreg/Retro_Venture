"""Myrmidon (GDD § 4.3) : Voie, 20 sorts, icônes (SVG 44 × 44) et fragment de manifeste `art/manifestes/myrmidon.json`.

    python3 docs/design/myrmidon/produire.py      # depuis la racine du dépôt
"""
import json
import os

GAME = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "game")


def dmg(element, low, high, **extra):
    return {"type": "degats", "element": element, "min": low, "max": high, "cibles": "ennemis", **extra}


def spell(sid, name, text, pa, rng, effects, mastery, **extra):
    return {"id": "myrmidon_" + sid, "nom": name, "description": text, "cout_pa": pa, "portee": {"min": rng[0], "max": rng[1]},
            **extra, "effets": effects, "maitrise": mastery}


ARMOR = {"type": "blindage", "min": 1, "max": 1, "sur_lanceur": True}
FROST = {"type": "gelure", "min": 1, "max": 1, "cibles": "ennemis"}
CIRCLE = {"type": "cercle", "taille": 1}


def malus(carac, value):
    return {"type": "malus", "carac": carac, "min": value, "max": value, "duree": 1, "cibles": "ennemis"}


ACIER = [
    spell("serrer_les_rangs", "Serrer les rangs", "Il serre les dents, le bouclier et les rangs (seul, c'est plus facile) : +2 crans de Blindage, +4 % de résistance à tout par cran.",
          1, (0, 0), [dict(ARMOR, min=2, max=2)], {"3": {"effets": [ARMOR]}, "5": {"effets": [{"type": "bonus", "carac": "reduction_degats", "min": 3, "max": 3, "duree": 2}]}},
          relance={"par_tour": 1}),
    spell("coup_de_bouclier", "Coup de bouclier", "Le bouclier sert aussi à ça, le règlement est formel. +1 cran de Blindage.", 3, (1, 1),
          [dmg("acier", 8, 11), ARMOR], {"3": {"critique": 5}, "5": {"effets": [malus("pm", 1)]}}, relance={"par_tour": 2}),
    spell("bouclier_lance", "Bouclier lancé", "Il lance son bouclier, qui rebondit sur un deuxième ennemi et revient (en général). +1 cran de Blindage.", 4, (2, 5),
          [dmg("acier", 6, 9), {"type": "rebond", "element": "acier", "min": 4, "max": 6, "distance": 2}, ARMOR], {"3": {"portee_max": 1}, "5": {"cout_pa": 3}},
          relance={"par_tour": 1}),
    spell("ecrasement", "Écrasement", "Tout son poids, réglementaire, sur un seul ennemi. +1 cran de Blindage.", 5, (1, 1),
          [dmg("acier", 16, 21), ARMOR], {"3": {"critique": 5}, "5": {"cout_pa": 4}}, relance={"par_tour": 1}),
    spell("retour_a_l_envoyeur", "Retour à l'envoyeur", "Rend tous les coups encaissés d'un seul : +20 % de dégâts par cran de Blindage, qui sont tous dépensés.",
          4, (1, 1), [dmg("acier", 10, 13, par_blindage=20)], {"3": {"critique": 5}, "5": {"portee_max": 1}}, relance={"par_tour": 1}),
    spell("coup_d_epaule", "Coup d'épaule", "Un coup d'épaule qui envoie l'ennemi deux cases plus loin, sans s'excuser. +1 cran de Blindage.", 2, (1, 1),
          [dmg("acier", 3, 5), {"type": "poussee", "min": 2, "max": 2, "cibles": "ennemis"}, ARMOR], {"3": {"effets": [malus("pm", 1)]}, "5": {"cout_pa": 1}},
          relance={"par_tour": 1}),
    spell("demolition", "Démolition", "Démolit un arbre ou un rocher pour le reste du combat ; les débris blessent les ennemis autour. +1 cran de Blindage.", 3, (1, 2),
          [{"type": "demolition"}, dmg("acier", 7, 9), ARMOR], {"3": {"portee_max": 1}, "5": {"zone_taille": 2}}, zone=CIRCLE, relance={"par_tour": 1, "delai": 1}),
    spell("belier", "Bélier", "Il charge en ligne jusqu'au contact, en renversant le premier arbre ou rocher du chemin. +1 cran de Blindage.", 3, (2, 5),
          [{"type": "charge", "demolit": True}, dmg("acier", 5, 7), ARMOR], {"3": {"portee_max": 1}, "5": {"delai": 1}},
          ligne_de_vue=False, lancer_en_ligne=True, relance={"par_tour": 1, "delai": 2}),
    spell("peau_de_fer", "Peau de fer", "Une peau si dure que les coups rebondissent : 5 de réduction de dégâts pendant 2 tours.", 2, (0, 0),
          [{"type": "bonus", "carac": "reduction_degats", "min": 5, "max": 5, "duree": 2}], {"3": {"delai": 2}, "5": {"effets": [ARMOR]}},
          relance={"par_tour": 1, "delai": 3}),
    spell("garde", "Garde", "Il se met devant un allié : pendant 2 tours, la moitié des dégâts de sort qu'il subit est prise par le Myrmidon, avec ses propres résistances.",
          2, (1, 3), [{"type": "etat", "etat": "garde", "duree": 2, "cibles": "allies"}],
          {"3": {"portee_max": 1}, "5": {"effets": [{"type": "bouclier", "element": "acier", "min": 6, "max": 8, "cibles": "allies"}]}},
          ligne_de_vue=False, relance={"par_tour": 1, "delai": 2}),
]
GIVRE = [
    spell("morsure_du_froid", "Morsure du froid", "Un froid qui mord les orteils : +1 Gelure (−1 PM au début de chacun de ses tours ; à 3 Gelures, gelé sur place un tour).",
          2, (1, 2), [dmg("givre", 4, 6), FROST], {"3": {"portee_max": 1}, "5": {"effets": [FROST]}}, relance={"par_tour": 2}),
    spell("coup_glace", "Coup glacé", "Un coup de lame givrée. +1 Gelure.", 3, (1, 1), [dmg("givre", 8, 11), FROST],
          {"3": {"critique": 5}, "5": {"effets": [{"type": "retrait_pm", "min": 1, "max": 1, "cibles": "ennemis"}]}}, relance={"par_tour": 2}),
    spell("souffle_hivernal", "Souffle hivernal", "Un souffle glacé qui traverse la ligne, blesse les ennemis et gèle l'eau sur son passage. +1 Gelure.", 4, (1, 3),
          [dmg("givre", 6, 8), FROST, {"type": "gel"}], {"3": {"portee_max": 1}, "5": {"cout_pa": 3}},
          zone={"type": "ligne"}, lancer_en_ligne=True, relance={"par_tour": 1}),
    spell("avalanche", "Avalanche", "Toute la neige de la montagne, sur la cible et ses voisins. +1 Gelure.", 5, (1, 1), [dmg("givre", 13, 17), FROST],
          {"3": {"critique": 5}, "5": {"cout_pa": 4}}, zone=CIRCLE, relance={"par_tour": 1}),
    spell("bris_de_glace", "Bris de glace", "Fait voler la glace en éclats : +25 % de dégâts par Gelure de la cible, qui tombent toutes.", 4, (1, 1),
          [dmg("givre", 9, 12, par_gelure=25)], {"3": {"critique": 5}, "5": {"portee_max": 1}}, relance={"par_tour": 1}),
    spell("entrave", "Entrave", "Des fers de glace aux chevilles : −2 PM et +1 Gelure.", 2, (1, 4),
          [{"type": "retrait_pm", "min": 2, "max": 2, "cibles": "ennemis"}, FROST], {"3": {"portee_max": 1}, "5": {"effets": [malus("pa", 1)]}},
          relance={"par_tour": 1}),
    spell("coup_sur_le_casque", "Coup sur le casque", "Bong. L'ennemi passe son prochain tour à compter les étoiles (une fois par ennemi et par combat ; un boss perd 3 PA à la place).",
          3, (1, 1), [dmg("givre", 3, 5), {"type": "etat", "etat": "assomme", "duree": 1, "cibles": "ennemis"}], {"3": {"delai": 4}, "5": {"effets": [FROST]}},
          relance={"par_tour": 1, "delai": 5}),
    spell("glissade", "Glissade", "Il glisse en ligne jusqu'au contact, en gelant l'eau sur son chemin (3 tours ; qui est dessus au dégel est mis au sec).",
          3, (2, 5), [{"type": "charge", "gele": True}], {"3": {"portee_max": 1}, "5": {"delai": 1}}, lancer_en_ligne=True,
          relance={"par_tour": 1, "delai": 2}),
    spell("carapace_de_glace", "Carapace de glace", "Une carapace de glace qui absorbe les coups ; qui le frappe au contact y gagne une Gelure.", 2, (0, 0),
          [{"type": "bouclier", "element": "givre", "min": 8, "max": 10}, {"type": "etat", "etat": "carapace_de_glace", "duree": 2}],
          {"3": {"cout_pa": 1}, "5": {"effets": [{"type": "bonus", "carac": "resistance", "element": "givre", "min": 10, "max": 10, "duree": 2}]}},
          relance={"par_tour": 1, "delai": 1}),
    spell("defi", "Défi", "« C'est à moi qu'il faut parler ! » Attire l'ennemi de 2 cases et le provoque 2 tours (son IA le vise ; −20 % de dégâts contre tout autre que le Myrmidon).",
          2, (1, 5), [{"type": "attirance", "min": 2, "max": 2, "cibles": "ennemis"}, {"type": "etat", "etat": "provoque", "duree": 2, "cibles": "ennemis"}],
          {"3": {"portee_max": 1}, "5": {"delai": 1}}, relance={"par_tour": 1, "delai": 2}),
]
VOIE = {
    "id": "myrmidon", "nom": "Myrmidon",
    "description": "Myrmidon de la Légion des Boucliers Réglementaires. A juré de ne jamais reculer, surtout parce qu'on ne lui a jamais appris la marche arrière.",
    "caracteristiques": {"pv": 50, "pa": 6, "pm": 3, "initiative": 100},
    "sorts": [s["id"] for s in ACIER + GIVRE],
    "passif": {"id": "myrmidon_point_de_mire", "nom": "Point de mire", "effet": "point_de_mire",
               "description": "Débloqué au palier Apprenti. Aura de 2 cases : un ennemi qui y commence son tour est provoqué pendant ce tour (son IA vise le Myrmidon ; −20 % de dégâts, +2 % par rang, contre tout autre que lui ; moitié moins pour un boss, qui reste libre). Rang 3 : aura de 3 cases. Rang 5 : un ennemi provoqué qui le frappe au contact subit un contrecoup de 10 % des dégâts."},
}

# Icônes : Acier gris à liseré clair, Givre bleu glacier à liseré blanc (couleurs de la classe).
FRAMES = {"a": ("#9aa4b0", "#22262e", "#dfe3ea"), "g": ("#7ac8e8", "#0e2a3a", "#f0faff")}
SHIELD = '<path d="M22 6 L35 11 Q35 27 22 38 Q9 27 9 11 Z" fill="{c}" stroke="#1a1d22" stroke-width="1.6"/><path d="M22 10 V34" stroke="#1a1d22" stroke-width="1" opacity="0.5"/>'
FLAKE = '<g stroke="#f0faff" stroke-width="2.2" stroke-linecap="round"><path d="M22 8 V36 M10 15 L34 29 M10 29 L34 15"/></g>'
ROCK = '<path d="M8 34 L12 22 L20 16 L30 18 L36 30 L32 35 Z" fill="#7a7068" stroke="#2a2420" stroke-width="1.4"/>'
DRAWINGS = {
    "serrer_les_rangs": ("a", SHIELD.format(c="#b8c0ca").replace("M22 6", "M16 6").replace("L35 11", "L29 11") + SHIELD.format(c="#8a929c").replace("M22 6", "M28 8")),
    "coup_de_bouclier": ("a", SHIELD.format(c="#b8c0ca") + '<path d="M36 8 l-4 5 M38 14 l-6 2" stroke="#ffe27a" stroke-width="2"/>'),
    "bouclier_lance": ("a", '<ellipse cx="18" cy="24" rx="9" ry="7" fill="#b8c0ca" stroke="#1a1d22" stroke-width="1.4"/><path d="M27 20 Q34 12 38 20" stroke="#dfe3ea" stroke-width="2" fill="none" stroke-dasharray="3 2"/>'),
    "ecrasement": ("a", '<rect x="12" y="6" width="20" height="12" rx="2" fill="#8a929c" stroke="#1a1d22" stroke-width="1.4"/><rect x="20" y="18" width="4" height="10" fill="#6b4a2b"/><path d="M8 36 H36" stroke="#ffe27a" stroke-width="2.4"/>'),
    "retour_a_l_envoyeur": ("a", SHIELD.format(c="#b8c0ca") + '<path d="M30 30 Q40 20 30 12 L33 18 M30 12 L36 13" stroke="#ffb02e" stroke-width="2.2" fill="none"/>'),
    "coup_d_epaule": ("a", '<circle cx="16" cy="22" r="8" fill="#8a929c" stroke="#1a1d22" stroke-width="1.4"/><path d="M26 22 H38 M33 17 L38 22 L33 27" stroke="#dfe3ea" stroke-width="2.4" fill="none"/>'),
    "demolition": ("a", ROCK + '<path d="M22 6 L24 16 L18 20 L26 26" stroke="#ffe27a" stroke-width="2" fill="none"/>'),
    "belier": ("a", '<path d="M6 22 H26" stroke="#dfe3ea" stroke-width="3" stroke-dasharray="4 3"/>' + SHIELD.format(c="#b8c0ca").replace("M22 6", "M28 8")),
    "peau_de_fer": ("a", '<circle cx="22" cy="22" r="13" fill="#8a929c" stroke="#dfe3ea" stroke-width="2"/><path d="M15 18 L29 18 M15 23 L29 23 M15 28 L29 28" stroke="#4a5058" stroke-width="1.6"/>'),
    "garde": ("a", '<circle cx="14" cy="16" r="5" fill="#dfe3ea"/><path d="M8 34 Q8 23 14 23 Q20 23 20 34 Z" fill="#dfe3ea"/>' + SHIELD.format(c="#8a929c").replace("M22 6", "M28 10")),
    "morsure_du_froid": ("g", '<path d="M10 14 L16 26 L22 14 L28 26 L34 14" stroke="#f0faff" stroke-width="3" fill="none" stroke-linejoin="round"/>'),
    "coup_glace": ("g", '<path d="M10 34 L32 10" stroke="#e8f6ff" stroke-width="4" stroke-linecap="round"/><path d="M28 8 L36 6 L34 14 Z" fill="#e8f6ff"/>'),
    "souffle_hivernal": ("g", '<path d="M6 16 Q20 10 36 16 M6 24 Q22 18 38 24 M6 32 Q20 26 34 32" stroke="#f0faff" stroke-width="2.4" fill="none"/>'),
    "avalanche": ("g", '<path d="M6 36 L22 8 L38 36 Z" fill="#e8f6ff" stroke="#0e2a3a" stroke-width="1.4"/><circle cx="16" cy="30" r="3" fill="#bfe4f4"/><circle cx="27" cy="27" r="4" fill="#bfe4f4"/>'),
    "bris_de_glace": ("g", '<path d="M22 6 L26 18 L36 14 L28 24 L36 34 L22 28 L10 36 L16 24 L8 14 L18 18 Z" fill="#bfe4f4" stroke="#f0faff" stroke-width="1.4"/>'),
    "entrave": ("g", '<g fill="none" stroke="#f0faff" stroke-width="2.4"><ellipse cx="13" cy="22" rx="5" ry="3.4"/><ellipse cx="22" cy="22" rx="5" ry="3.4" transform="rotate(90 22 22)"/><ellipse cx="31" cy="22" rx="5" ry="3.4"/></g>'),
    "coup_sur_le_casque": ("g", '<path d="M10 28 Q10 12 22 12 Q34 12 34 28 Z" fill="#9aa4b0" stroke="#1a1d22" stroke-width="1.4"/>' + "".join(f'<path d="M{x} {y} l2 -4 l2 4 l-4 -2 h4 z" fill="#ffe27a"/>' for x, y in [(10, 10), (22, 6), (32, 10)])),
    "glissade": ("g", '<path d="M6 32 H38" stroke="#bfe4f4" stroke-width="4"/><path d="M12 26 L30 26 M16 20 L34 20" stroke="#f0faff" stroke-width="2" stroke-dasharray="4 3"/>'),
    "carapace_de_glace": ("g", '<path d="M22 6 L35 11 Q35 27 22 38 Q9 27 9 11 Z" fill="#bfe4f4" stroke="#f0faff" stroke-width="2"/>' + FLAKE.replace("2.2", "1.4")),
    "defi": ("g", '<path d="M14 8 V36 M14 8 L32 13 L14 19" stroke="#f0faff" stroke-width="2.6" fill="#7ac8e8" stroke-linejoin="round"/>'),
    "point_de_mire": ("a", '<circle cx="22" cy="22" r="13" fill="none" stroke="#ff6a4a" stroke-width="2.4"/><circle cx="22" cy="22" r="6" fill="none" stroke="#ff6a4a" stroke-width="2"/><path d="M22 4 V12 M22 32 V40 M4 22 H12 M32 22 H40" stroke="#ff6a4a" stroke-width="2"/>'),
}


def write(folder, data):
    with open(os.path.join(GAME, "data", folder, data["id"] + ".json"), "w", encoding="utf-8") as f:
        f.write(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


for data in ACIER + GIVRE:
    write("sorts", data)
write("voies", VOIE)
images = {}
for name, (kind, body) in DRAWINGS.items():
    light, dark, edge = FRAMES[kind]
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="44" height="44" viewBox="0 0 44 44">\n'
           f'<defs><radialGradient id="f" cx="0.35" cy="0.3" r="0.9"><stop offset="0" stop-color="{light}"/><stop offset="1" stop-color="{dark}"/></radialGradient></defs>\n'
           f'<rect x="1.5" y="1.5" width="41" height="41" rx="7" fill="url(#f)" stroke="{edge}" stroke-width="2"/>\n{body}\n</svg>\n')
    with open(os.path.join(GAME, "art", "sorts", f"myrmidon_{name}.svgt"), "w") as f:
        f.write(svg)
    images[f"sort_myrmidon_{name}"] = {"fichier": f"sorts/myrmidon_{name}.svgt", "ancre": [22, 22]}
with open(os.path.join(GAME, "art", "manifestes", "myrmidon.json"), "w", encoding="utf-8") as f:
    f.write(json.dumps({"images": images}, ensure_ascii=False, indent=2) + "\n")
