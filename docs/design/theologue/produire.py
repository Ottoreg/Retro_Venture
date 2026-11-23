"""Théologue (GDD § 4.3) : Voie, 20 sorts (les 5 sorts Sacrés d'origine compris), icônes des 15 nouveaux et du passif
(SVG 44 × 44) et fragment de manifeste `art/manifestes/theologue.json`.

    python3 docs/design/theologue/produire.py      # depuis la racine du dépôt
"""
import json
import os

GAME = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "game")


def dmg(element, low, high, **extra):
    return {"type": "degats", "element": element, "min": low, "max": high, "cibles": "ennemis", **extra}


def spell(sid, name, text, pa, rng, effects, mastery, **extra):
    return {"id": "theologue_" + sid, "nom": name, "description": text, "cout_pa": pa, "portee": {"min": rng[0], "max": rng[1]},
            **extra, "effets": effects, "maitrise": mastery}


def mod(kind, carac, value, turns, targets=None):
    return {"type": kind, "carac": carac, "min": value, "max": value, "duree": turns, **({"cibles": targets} if targets else {})}


HERESY = {"type": "heresie", "min": 1, "max": 1, "cibles": "ennemis"}
CROSS = {"type": "cercle", "taille": 1}
RANGE = {"portee_max": 1}

SACRE = [
    spell("terre_consacree", "Terre consacrée", "Il bénit le sol d'une croix de cinq cases pendant 3 tours : les alliés dessus reçoivent +20 % de soins et de boucliers, les ennemis qui y commencent leur tour se brûlent les pieds.",
          3, (1, 5), [{"type": "glyphe", "duree": 3, "consacree": True, "effets": [dmg("sacre", 5, 7)]}], {"3": RANGE, "5": {"zone_taille": 2}},
          zone=CROSS, relance={"par_tour": 1, "delai": 3}),
    spell("chatiment", "Châtiment", "Un rayon de lumière tombe sur la cible. Le ciel a l'air contrarié.", 4, (2, 5),
          [{"type": "degats", "element": "sacre", "min": 8, "max": 12}], {"3": RANGE, "5": {"critique": 10}}, ligne_de_vue=True, relance={"par_tour": 2}),
    spell("sermon", "Sermon", "Une croix de paroles saintes : les ennemis qui s'y trouvent souffrent, les alliés reprennent courage (et encore plus si le croisement est sur une Terre consacrée).",
          4, (1, 5), [dmg("sacre", 4, 7), {"type": "soin", "element": "sacre", "min": 4, "max": 7, "cibles": "allies", "si_consacree": 50}],
          {"3": RANGE, "5": {"cout_pa": 3}}, ligne_de_vue=True, lancer_en_ligne=True, zone={"type": "croix_latine"}, relance={"par_tour": 1}),
    spell("coup_de_goupillon", "Coup de goupillon", "Un coup d'eau bénite, à température ambiante. Ça pique un peu.", 2, (1, 4),
          [dmg("sacre", 4, 6)], {"3": RANGE, "5": {"critique": 10}}, relance={"par_tour": 3}),
    spell("imposition", "Imposition des mains", "Une main sur l'épaule, une prière, et les plaies se referment. Les remerciements sont facultatifs mais conseillés.",
          3, (0, 3), [{"type": "soin", "element": "sacre", "min": 12, "max": 18}],
          {"3": RANGE, "5": {"effets": [{"type": "retrait_etats", "etats": ["poison"], "cibles": "allies"}]}}, ligne_de_vue=True, relance={"par_tour": 1}),
    spell("rempart", "Rempart de foi", "Un halo doré qui encaisse les coups à votre place jusqu'à votre prochain tour.", 2, (0, 3),
          [{"type": "bouclier", "element": "sacre", "min": 12, "max": 16}], {"3": RANGE, "5": {"delai": 1}}, ligne_de_vue=True, relance={"par_tour": 1, "delai": 2}),
    spell("absolution", "Absolution", "Pardonne aux alliés leurs malus et leurs poisons, retire aux ennemis leurs bonus. Le Théologue prélève une petite commission spirituelle au passage.",
          3, (0, 5), [{"type": "retrait_etats", "etats": ["bonus"], "cibles": "ennemis"}, {"type": "retrait_etats", "etats": ["malus", "poison"], "cibles": "allies"}],
          {"3": RANGE, "5": {"delai": 1}}, ligne_de_vue=True, relance={"par_tour": 1, "delai": 2}, critique=0),
    spell("genuflexion", "Génuflexion", "« À genoux ! » L'ennemi obéit, surpris : −2 PM et −15 % de dégâts infligés pendant 1 tour.", 3, (1, 4),
          [mod("malus", "pm", 2, 1, "ennemis"), mod("malus", "degats_infliges", 15, 1, "ennemis")], {"3": RANGE, "5": {"delai": 1}},
          relance={"par_tour": 1, "delai": 2}),
    spell("procession", "Procession", "Il se rend en procession sur une case libre, ou prend la place d'un allié (qui prend la sienne, en chantant).", 2, (1, 4),
          [{"type": "procession"}], {"3": RANGE, "5": {"delai": 1}}, ligne_de_vue=False, relance={"par_tour": 1, "delai": 2}),
    spell("indulgence", "Indulgence", "Une indulgence plénière, payée d'avance bien sûr : +1 PA et +1 PM pendant 2 tours.", 2, (0, 3),
          [mod("bonus", "pa", 1, 2, "allies"), mod("bonus", "pm", 1, 2, "allies")], {"3": RANGE, "5": {"delai": 3}}, relance={"par_tour": 1, "delai": 4}),
]
FLAMME = [
    spell("accusation", "Accusation", "Il pointe l'ennemi du doigt : +2 crans d'Hérésie. Il y a toujours un coupable.", 2, (1, 6),
          [dict(HERESY, min=2, max=2)], {"3": RANGE, "5": {"effets": [HERESY]}}, relance={"par_tour": 2}),
    spell("tison", "Tison", "Un tison bien choisi dans le brasier du jour. +1 cran d'Hérésie.", 3, (1, 5), [dmg("flamme", 6, 9), HERESY],
          {"3": {"critique": 10}, "5": RANGE}, relance={"par_tour": 3}),
    spell("autodafe", "Autodafé", "On brûle les mauvais livres, et leurs lecteurs avec. +1 cran d'Hérésie à chaque ennemi touché.", 4, (2, 5),
          [dmg("flamme", 5, 8), HERESY], {"3": RANGE, "5": {"cout_pa": 3}}, zone=CROSS, relance={"par_tour": 1}),
    spell("feu_purificateur", "Feu purificateur", "Une colonne de feu qui purifie tout, l'ennemi compris. +1 cran d'Hérésie.", 5, (2, 5),
          [dmg("flamme", 18, 24), HERESY], {"3": {"critique": 10}, "5": {"cout_pa": 4}}, relance={"par_tour": 1}),
    spell("bucher", "Bûcher", "Le procès est terminé : 4 à 6 Flamme par cran d'Hérésie de la cible, qui sont tous consommés.", 4, (1, 4),
          [dmg("flamme", 4, 6, par_heresie=True)], {"3": RANGE, "5": {"critique": 10}}, relance={"par_tour": 1}),
    spell("commandement", "Commandement", "« Tu ne bougeras point. » Pendant 2 tours, chaque case que l'ennemi marche lui coûte une Pénitence (3 Flamme et un cran d'Hérésie).",
          3, (1, 5), [{"type": "etat", "etat": "commandement", "duree": 2, "cibles": "ennemis"}], {"3": RANGE, "5": {"delai": 1}},
          relance={"par_tour": 1, "delai": 2}),
    spell("la_question", "La Question", "Juste quelques questions, posées avec des pinces : −2 PA pendant 1 tour et +1 cran d'Hérésie.", 3, (1, 3),
          [mod("malus", "pa", 2, 1, "ennemis"), HERESY], {"3": RANGE, "5": {"effets": [HERESY]}}, relance={"par_tour": 1, "delai": 2}),
    spell("saut_des_flammes", "Saut des flammes", "Il traverse les flammes d'un bond, la soutane à peine roussie.", 2, (1, 3),
          [{"type": "teleportation"}], {"3": RANGE, "5": {"delai": 1}}, ligne_de_vue=False, relance={"par_tour": 1, "delai": 2}),
    spell("expiation", "Expiation", "Le feu qui purifie soigne aussi, un peu, ceux qui ont déjà avoué.", 2, (0, 3),
          [{"type": "soin", "element": "flamme", "min": 6, "max": 9, "cibles": "allies"}], {"3": RANGE, "5": {"delai": 1}}, relance={"par_tour": 1, "delai": 2}),
    spell("zele", "Zèle", "Un zèle brûlant pour la bonne cause : +40 Intelligence pendant 2 tours.", 2, (0, 3),
          [mod("bonus", "intelligence", 40, 2, "allies")], {"3": RANGE, "5": {"delai": 2}}, relance={"par_tour": 1, "delai": 3}),
]
VOIE = {
    "id": "theologue", "nom": "Théologue",
    "description": "Soigneur sacré. Bénit les alliés, sermonne les ennemis, et cite des textes que personne n'a lus. Le dimanche il soigne ; le reste de la semaine, il instruit des procès en hérésie.",
    "caracteristiques": {"pv": 50, "pa": 6, "pm": 3, "initiative": 100},
    "sorts": [s["id"] for s in SACRE + FLAMME],
    "passif": {"id": "theologue_faire_la_quete", "nom": "Faire la quête", "effet": "faire_la_quete",
               "description": "Débloqué au palier Apprenti. Chaque sort qui blesse un ennemi donne 1 Foi (5 au plus, tout le combat). Le soin ou le bouclier suivant la dépense toute : +6 % par Foi (+1 % par rang). Rang 3 : un ennemi qui désobéit à un Commandement donne aussi 1 Foi. Rang 5 : un soin lancé à 5 Foi soigne aussi de moitié les alliés au contact de ceux qu'il soigne."},
}

# Icônes : Sacré or et blanc, Flamme orange à liseré jaune (couleurs de la classe).
FRAMES = {"s": ("#f4e2a0", "#5a4410", "#fff6d0"), "f": ("#ff9a3a", "#4a1206", "#ffd27a")}
CROSS_PATH = '<path d="M19 6 H25 V14 H33 V20 H25 V38 H19 V20 H11 V14 H19 Z" fill="{c}" stroke="#2a2008" stroke-width="1.4"/>'
FLAME = '<path d="M22 6 Q32 18 28 28 Q34 24 32 18 Q40 30 30 38 H14 Q4 30 12 18 Q10 24 16 28 Q12 18 22 6 Z" fill="{c}" stroke="#4a1206" stroke-width="1.4"/>'
DRAWINGS = {
    "terre_consacree": ("s", '<ellipse cx="22" cy="30" rx="16" ry="7" fill="#ffe27a" stroke="#fff6d0" stroke-width="1.6"/>' + CROSS_PATH.format(c="#fff6d0").replace("V38", "V30")),
    "coup_de_goupillon": ("s", '<path d="M10 34 L26 18" stroke="#6b4a2b" stroke-width="4" stroke-linecap="round"/><circle cx="29" cy="15" r="6" fill="#c9ccd6" stroke="#2a2008" stroke-width="1.4"/>'
                          + "".join(f'<circle cx="{x}" cy="{y}" r="1.8" fill="#8fd0ec"/>' for x, y in [(36, 10), (37, 18), (33, 24)])),
    "genuflexion": ("s", '<circle cx="22" cy="12" r="5" fill="#fff6d0"/><path d="M16 20 H28 L26 28 H32 V34 H14 L16 28 Z" fill="#fff6d0" stroke="#2a2008" stroke-width="1.2"/><path d="M8 38 H36" stroke="#5a4410" stroke-width="2"/>'),
    "procession": ("s", "".join(f'<circle cx="{x}" cy="18" r="3.5" fill="#fff6d0"/><path d="M{x - 4} 32 Q{x - 4} 23 {x} 23 Q{x + 4} 23 {x + 4} 32 Z" fill="#fff6d0"/>' for x in (11, 22, 33))
                   + '<path d="M22 6 V12 M19 8 H25" stroke="#ffe27a" stroke-width="2"/>'),
    "indulgence": ("s", '<rect x="11" y="8" width="22" height="28" rx="2" fill="#fff6d0" stroke="#2a2008" stroke-width="1.4"/><path d="M15 15 H29 M15 20 H29 M15 25 H24" stroke="#5a4410" stroke-width="1.4"/><circle cx="28" cy="31" r="4" fill="#c0392b"/>'),
    "accusation": ("f", '<path d="M6 26 H24 V20 H30 Q34 20 34 24 V30 Q34 34 30 34 H12 Q6 34 6 30 Z" fill="#f0c8a0" stroke="#4a1206" stroke-width="1.4"/><path d="M24 20 L38 12" stroke="#f0c8a0" stroke-width="4" stroke-linecap="round"/>'),
    "tison": ("f", '<path d="M10 36 L28 16" stroke="#3a2416" stroke-width="5" stroke-linecap="round"/>' + FLAME.format(c="#ffd27a").replace("M22 6", "M30 6").replace("Q32 18 28 28", "Q36 14 32 20")),
    "autodafe": ("f", '<rect x="10" y="26" width="24" height="9" rx="1" fill="#8a3b2f" stroke="#4a1206" stroke-width="1.2"/><path d="M12 26 V22 H32 V26" fill="#c9a26a"/>' + FLAME.format(c="#ffb02e").replace("H14", "H18")),
    "feu_purificateur": ("f", '<rect x="16" y="4" width="12" height="36" rx="6" fill="#ffd27a" stroke="#fff6d0" stroke-width="1.6"/><path d="M22 8 V36" stroke="#ff6a1a" stroke-width="3"/>'),
    "bucher": ("f", '<path d="M22 6 V38" stroke="#6b4a2b" stroke-width="3"/><path d="M8 38 L36 30 M8 30 L36 38" stroke="#6b4a2b" stroke-width="3"/>' + FLAME.format(c="#ff6a1a").replace("M22 6", "M22 16")),
    "commandement": ("f", '<path d="M10 36 V14 Q10 6 16 6 Q22 6 22 14 V36 Z M22 36 V14 Q22 6 28 6 Q34 6 34 14 V36 Z" fill="#b8b0a4" stroke="#3a3028" stroke-width="1.4"/><path d="M13 16 H19 M13 21 H19 M25 16 H31 M25 21 H31 M13 26 H19" stroke="#3a3028" stroke-width="1.4"/>'),
    "la_question": ("f", '<path d="M15 14 Q15 6 22 6 Q30 6 30 13 Q30 19 22 22 V27" stroke="#ffd27a" stroke-width="4" fill="none" stroke-linecap="round"/><circle cx="22" cy="34" r="3" fill="#ffd27a"/>'),
    "saut_des_flammes": ("f", '<path d="M6 34 Q22 2 38 34" stroke="#ffd27a" stroke-width="2.4" fill="none" stroke-dasharray="4 3"/>' + FLAME.format(c="#ff6a1a").replace("M22 6", "M22 22")),
    "expiation": ("f", FLAME.format(c="#ff9a3a") + '<path d="M18 26 H26 M22 22 V30" stroke="#fff6d0" stroke-width="3"/>'),
    "zele": ("f", '<circle cx="22" cy="20" r="11" fill="#ffd27a" stroke="#4a1206" stroke-width="1.4"/><path d="M17 18 L21 20 M27 18 L23 20" stroke="#4a1206" stroke-width="2"/>' + FLAME.format(c="#ff6a1a").replace("M22 6", "M22 2").replace("H14", "H30")),
    "faire_la_quete": ("s", '<path d="M10 18 H34 L30 36 H14 Z" fill="#8a5a2b" stroke="#2a2008" stroke-width="1.4"/><path d="M22 18 V6" stroke="#6b4a2b" stroke-width="3"/>'
                       + "".join(f'<circle cx="{x}" cy="16" r="3" fill="#ffe27a" stroke="#5a4410" stroke-width="1"/>' for x in (16, 22, 28))),
}


def write(folder, data):
    with open(os.path.join(GAME, "data", folder, data["id"] + ".json"), "w", encoding="utf-8") as f:
        f.write(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


for data in SACRE + FLAMME:
    write("sorts", data)
write("voies", VOIE)
images = {}
for name, (kind, body) in DRAWINGS.items():
    light, dark, edge = FRAMES[kind]
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="44" height="44" viewBox="0 0 44 44">\n'
           f'<defs><radialGradient id="f" cx="0.35" cy="0.3" r="0.9"><stop offset="0" stop-color="{light}"/><stop offset="1" stop-color="{dark}"/></radialGradient></defs>\n'
           f'<rect x="1.5" y="1.5" width="41" height="41" rx="7" fill="url(#f)" stroke="{edge}" stroke-width="2"/>\n{body}\n</svg>\n')
    with open(os.path.join(GAME, "art", "sorts", f"theologue_{name}.svgt"), "w") as f:
        f.write(svg)
    images[f"sort_theologue_{name}"] = {"fichier": f"sorts/theologue_{name}.svgt", "ancre": [22, 22]}
with open(os.path.join(GAME, "art", "manifestes", "theologue.json"), "w", encoding="utf-8") as f:
    f.write(json.dumps({"images": images}, ensure_ascii=False, indent=2) + "\n")
