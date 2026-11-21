"""Paladin (GDD § 4.3) : Voie, 20 sorts et icônes (SVG 44 × 44), fragment de manifeste `art/manifestes/paladin.json`.

    python3 docs/design/paladin/produire.py      # depuis la racine du dépôt
"""
import json
import os

GAME = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "game")


def dmg(element, low, high, targets="ennemis", **extra):
    return {"type": "degats", "element": element, "min": low, "max": high, "cibles": targets, **extra}


def bonus(carac, value, turns=1, **extra):
    return {"type": "bonus", "carac": carac, "min": value, "max": value, "duree": turns, **extra}


def spell(sid, name, text, pa, rng, effects, mastery, **extra):
    return {"id": sid, "nom": name, "description": text, "cout_pa": pa, "portee": {"min": rng[0], "max": rng[1]},
            **extra, "effets": effects, "maitrise": mastery}


ARC = [dmg("tempete", 6, 9)]  # Coup d'un arc entre deux balises.
AURA_NOTE = " Une seule aura à la fois : la nouvelle remplace l'ancienne. Rang 5 : un tour de plus."
SACRE = [
    spell("paladin_aura_de_bravoure", "Aura de bravoure", "Une aura dorée de 2 cases qui le suit pendant 3 tours : ses alliés dedans (lui compris) font +15 % de dégâts. Persuadés d'être des héros, ils frappent comme tels." + AURA_NOTE,
          2, (0, 0), [{"type": "aura", "taille": 2, "duree": 3, "effets": [bonus("degats_infliges", 15, cibles="allies")]}],
          {"3": {"cout_pa": 1}, "5": {"duree_aura": 1}}),
    spell("paladin_coup_beni", "Coup béni", "Un coup d'épée béni en série : le prêtre a signé la lame à la chaîne.", 3, (1, 1), [dmg("sacre", 9, 12)],
          {"3": {"critique": 10}, "5": {"effets": [bonus("pm", 1, sur_lanceur=True)]}}, relance={"par_tour": 2}),
    spell("paladin_marteau_lance", "Marteau lancé", "Il lance son marteau béni. Il revient toujours (un écuyer court le chercher).", 3, (2, 5), [dmg("sacre", 7, 10)],
          {"3": {"portee_max": 1}, "5": {"critique": 10}}, relance={"par_tour": 2}),
    spell("paladin_jugement", "Jugement", "Le jugement divin tombe d'un seul coup, sans appel ni avocat.", 5, (1, 1), [dmg("sacre", 20, 26)],
          {"3": {"critique": 10}, "5": {"cout_pa": 4}}, relance={"par_tour": 1}),
    spell("paladin_onde_sacree", "Onde sacrée", "Une onde de lumière part de lui et frappe chaque ennemi dans son aura (à 1 case sans aura).", 4, (0, 0),
          [dmg("sacre", 8, 11)], {"3": {"cout_pa": 3}, "5": {"critique": 10}}, zone_aura=True, lanceur_exclu=True, relance={"par_tour": 1}),
    spell("paladin_coup_de_bouclier", "Coup de bouclier", "Un grand coup de bouclier, blason en avant : l'ennemi recule de 2 cases.", 3, (1, 1),
          [dmg("sacre", 5, 7), {"type": "poussee", "min": 2, "max": 2, "cibles": "ennemis"}],
          {"3": {"cout_pa": 2}, "5": {"effets": [{"type": "malus", "carac": "pm", "min": 1, "max": 1, "duree": 1, "cibles": "ennemis"}]}}, relance={"par_tour": 1}),
    spell("paladin_sceau_de_penitence", "Sceau de pénitence", "Un sceau de pénitence sur le front de l'ennemi : −2 PM à son prochain tour, le temps de réfléchir à ses fautes.", 3, (1, 4),
          [{"type": "retrait_pm", "min": 2, "max": 2, "cibles": "ennemis"}],
          {"3": {"portee_max": 1}, "5": {"effets": [{"type": "malus", "carac": "pa", "min": 1, "max": 1, "duree": 1, "cibles": "ennemis"}]}}, relance={"delai": 2}),
    spell("paladin_ruee_sainte", "Ruée sainte", "Il fonce en ligne droite jusqu'à la case visée ou au contact du premier combattant, sans frapper ; son aura le suit.", 2, (2, 5),
          [{"type": "charge"}], {"3": {"portee_max": 1}, "5": {"effets": [bonus("pm", 1, sur_lanceur=True)]}}, lancer_en_ligne=True, relance={"delai": 2}),
    spell("paladin_aura_de_protection", "Aura de protection", "Une aura argentée de 2 cases qui le suit pendant 3 tours : ses alliés dedans (lui compris) ont +10 % de résistance à tous les éléments." + AURA_NOTE,
          2, (0, 0), [{"type": "aura", "taille": 2, "duree": 3, "effets": [bonus("resistance", 10, element=e, cibles="allies") for e in ("acier", "flamme", "givre", "tempete")]}],
          {"3": {"cout_pa": 1}, "5": {"duree_aura": 1}}),
    spell("paladin_benediction", "Bénédiction", "Une bénédiction en bonne et due forme : +30 Force et +30 Intelligence pendant 2 tours.", 2, (0, 3),
          [bonus("force", 30, 2, cibles="allies"), bonus("intelligence", 30, 2, cibles="allies")], {"3": {"portee_max": 1}, "5": {"delai": 2}}, relance={"delai": 3}),
]
TEMPETE = [
    spell("paladin_balise", "Balise", "Plante une balise sur une case libre (3 au plus, la plus ancienne part). Deux balises alignées à 6 cases au plus se relient par un arc qui frappe les ennemis qui y entrent ou y commencent leur tour. Un ennemi la casse en marchant dessus ou en la frappant.",
          2, (1, 5), [{"type": "balise", "effets": ARC}], {"3": {"portee_max": 1}, "5": {"cout_pa": 1}}),
    spell("paladin_etincelle", "Étincelle", "Une étincelle tirée au loin. Projectile : +25 % par arc traversé (2 au plus).", 3, (2, 6), [dmg("tempete", 7, 10)],
          {"3": {"portee_max": 1}, "5": {"critique": 10}}, projectile=True, relance={"par_tour": 2}),
    spell("paladin_chaine_d_eclairs", "Chaîne d'éclairs", "Un éclair qui saute sur l'ennemi le plus proche (2 cases). La foudre ne tombe jamais deux fois au même endroit ; elle va à côté.", 4, (2, 5),
          [dmg("tempete", 7, 10), {"type": "rebond", "element": "tempete", "min": 7, "max": 10, "distance": 2}], {"3": {"cout_pa": 3}, "5": {"critique": 10}},
          relance={"par_tour": 1}),
    spell("paladin_foudre_celeste", "Foudre céleste", "Il lève l'épée au ciel et le ciel répond. Projectile : +25 % par arc traversé (2 au plus).", 5, (3, 6), [dmg("tempete", 18, 24)],
          {"3": {"critique": 10}, "5": {"portee_max": 1}}, projectile=True, relance={"par_tour": 1}),
    spell("paladin_surtension", "Surtension", "Surcharge une de ses balises : chaque ennemi sur un de ses arcs ou à son contact subit les dégâts de l'arc × 1,5.", 3, (1, 8),
          [{"type": "surtension", "multiplicateur": 150}], {"3": {"cout_pa": 2}, "5": {"portee_max": 2}}, ligne_de_vue=False, relance={"par_tour": 1}),
    spell("paladin_aimantation", "Aimantation", "Un champ magnétique attire l'ennemi de 3 cases vers lui, à travers ses arcs s'il le faut.", 3, (2, 5),
          [{"type": "attirance", "min": 3, "max": 3, "cibles": "ennemis"}], {"3": {"portee_max": 1}, "5": {"effets": [{"type": "retrait_pm", "min": 1, "max": 1, "cibles": "ennemis"}]}},
          relance={"par_tour": 1}),
    spell("paladin_electrocution", "Électrocution", "Une décharge qui raidit les jambes : −2 PM, et −1 PA de plus si l'ennemi est sur un arc.", 3, (1, 5),
          [dmg("tempete", 4, 6), {"type": "retrait_pm", "min": 2, "max": 2, "cibles": "ennemis"},
           {"type": "malus", "carac": "pa", "min": 1, "max": 1, "duree": 1, "cibles": "ennemis", "sur_arc": True}],
          {"3": {"portee_max": 1}, "5": {"critique": 10}}, relance={"par_tour": 1}),
    spell("paladin_saut_d_eclair", "Saut d'éclair", "Il échange sa place avec une de ses balises, dans un éclair (et une odeur de brûlé).", 2, (1, 8),
          [{"type": "saut_balise"}], {"3": {"cout_pa": 1}, "5": {"delai": 1}}, ligne_de_vue=False, relance={"delai": 2}),
    spell("paladin_bouclier_statique", "Bouclier statique", "Un bouclier qui crépite : il absorbe les coups et pique qui frappe au contact (3 épines Tempête).", 2, (0, 0),
          [{"type": "bouclier", "element": "tempete", "min": 12, "max": 16}, bonus("epines_tempete_fixes", 3)],
          {"3": {"cout_pa": 1}, "5": {"effets": [bonus("resistance", 10, element="tempete")]}}, relance={"par_tour": 1}),
    spell("paladin_paratonnerre_vivant", "Paratonnerre vivant", "La cible (lui ou un allié) sert de balise pendant 2 tours, avec ses arcs, et gagne 1 PM. Elle a signé une décharge.", 2, (0, 4),
          [{"type": "paratonnerre", "duree": 2, "cibles": "allies", "effets": ARC}, bonus("pm", 1, cibles="allies")],
          {"3": {"portee_max": 1}, "5": {"delai": 2}}, relance={"delai": 3}),
]
VOIE = {
    "id": "paladin", "nom": "Paladin",
    "description": "Paladin breveté de l'Ordre du Saint Paratonnerre. Béni par les dieux, foudroyé par eux aussi (souvent). Persuadé d'être l'Élu, comme les 214 autres Élus de sa promotion.",
    "caracteristiques": {"pv": 50, "pa": 6, "pm": 3, "initiative": 100},
    "sorts": [s["id"] for s in SACRE + TEMPETE],
    "passif": {"id": "paladin_saint_paratonnerre", "nom": "Saint Paratonnerre", "effet": "saint_paratonnerre",
               "description": "Débloqué au palier Apprenti. +6 % de dégâts (+1 % par rang) pour lui et ses alliés dans son aura ou debout sur un de ses arcs. Rang 3 : rayon de l'aura +1. Rang 5 : une 4e balise en même temps."},
}

# Icônes : Sacré or à liseré blanc, Tempête bleu électrique à liseré or (couleurs de la classe).
FRAMES = {"s": ("#e8c860", "#5a4210", "#f4f1e6"), "t": ("#4a8ae8", "#0c1a3a", "#e8c860")}
BOLT = '<path d="M25 5 L13 24 H21 L17 39 L31 18 H23 Z" fill="#ffe27a" stroke="#1a2a5a" stroke-width="1.2"/>'
SWORD = '<path d="M22 5 L25 9 V27 H19 V9 Z" fill="#e8ecf4" stroke="#3a3a46" stroke-width="1"/><path d="M14 27 H30 V30 H14 Z M20 30 H24 V38 H20 Z" fill="#c9a04e" stroke="#3a2a10" stroke-width="1"/>'
SHIELD = '<path d="M22 6 L35 11 Q35 28 22 38 Q9 28 9 11 Z" fill="{c}" stroke="#3a2a10" stroke-width="1.6"/><path d="M22 12 V32 M15 19 H29" stroke="#c9a04e" stroke-width="2.4"/>'
HALO = '<ellipse cx="22" cy="22" rx="15" ry="7" fill="none" stroke="{c}" stroke-width="2.6"/><ellipse cx="22" cy="22" rx="9" ry="4" fill="none" stroke="{c}" stroke-width="1.4" opacity="0.7"/>'
POLE = '<path d="M22 8 V36" stroke="#dfe3ea" stroke-width="3"/><circle cx="22" cy="9" r="4" fill="#8ad4ff" stroke="#1a2a5a"/><path d="M15 36 H29" stroke="#5a5a66" stroke-width="3"/>'
DRAWINGS = {
    "aura_de_bravoure": ("s", HALO.format(c="#ffe27a") + SWORD.replace('M22 5', 'M22 9')),
    "coup_beni": ("s", SWORD + '<circle cx="31" cy="11" r="3" fill="#fff6c0"/>'),
    "marteau_lance": ("s", '<rect x="12" y="10" width="16" height="9" rx="2" fill="#c9ccd6" stroke="#3a3a46"/><path d="M20 19 L28 36" stroke="#8a5a2b" stroke-width="3.4" stroke-linecap="round"/><path d="M33 8 q4 4 0 8" stroke="#fff6c0" stroke-width="1.6" fill="none"/>'),
    "jugement": ("s", '<path d="M22 4 L26 16 L38 16 L28 23 L32 36 L22 28 L12 36 L16 23 L6 16 L18 16 Z" fill="#fff6c0" stroke="#7a5a10" stroke-width="1.2"/>'),
    "onde_sacree": ("s", "".join(f'<circle cx="22" cy="22" r="{r}" fill="none" stroke="#fff6c0" stroke-width="{w}" opacity="{o}"/>' for r, w, o in ((5, 3, 1), (11, 2.4, 0.8), (17, 1.8, 0.55)))),
    "coup_de_bouclier": ("s", SHIELD.format(c="#e8ecf4") + '<path d="M36 14 L42 10 M36 22 H43 M36 30 L42 34" stroke="#fff6c0" stroke-width="1.6"/>'),
    "sceau_de_penitence": ("s", '<circle cx="22" cy="22" r="12" fill="#a0302a" stroke="#5a1010" stroke-width="1.6"/><path d="M22 14 V30 M15 20 H29" stroke="#ffe27a" stroke-width="2.4"/>'),
    "ruee_sainte": ("s", SHIELD.format(c="#e8ecf4").replace('M22 6', 'M28 6') + '<path d="M4 16 H14 M2 22 H12 M4 28 H14" stroke="#fff6c0" stroke-width="2"/>'),
    "aura_de_protection": ("s", HALO.format(c="#dfe3ea") + SHIELD.format(c="#c9ccd6").replace('stroke-width="1.6"', 'stroke-width="1.2" transform="translate(7 7) scale(0.68)"')),
    "benediction": ("s", '<path d="M14 36 Q14 20 18 16 L18 8 Q20 6 22 8 V16 Q23 7 26 8 V18 Q30 16 30 22 Q30 32 26 36 Z" fill="#f0c8a0" stroke="#5a3a20"/><circle cx="22" cy="5" r="3" fill="#fff6c0"/>'),
    "balise": ("t", POLE),
    "etincelle": ("t", '<path d="M22 8 L25 19 L36 22 L25 25 L22 36 L19 25 L8 22 L19 19 Z" fill="#ffe27a" stroke="#1a2a5a" stroke-width="1"/>'),
    "chaine_d_eclairs": ("t", '<path d="M6 12 L16 22 L13 25 L24 30 L21 33 L38 38" stroke="#ffe27a" stroke-width="2.6" fill="none" stroke-linejoin="round"/><circle cx="16" cy="22" r="2.4" fill="#8ad4ff"/><circle cx="24" cy="30" r="2.4" fill="#8ad4ff"/>'),
    "foudre_celeste": ("t", '<ellipse cx="22" cy="10" rx="14" ry="5" fill="#3a4a6a"/>' + BOLT.replace('M25 5', 'M25 12')),
    "surtension": ("t", POLE + '<path d="M8 12 L14 16 M36 12 L30 16 M8 30 L14 26 M36 30 L30 26" stroke="#ffe27a" stroke-width="2.2"/>'),
    "aimantation": ("t", '<path d="M10 10 V24 A12 12 0 0 0 34 24 V10 H27 V24 A5 5 0 0 1 17 24 V10 Z" fill="#c2402a" stroke="#1a1a1a" stroke-width="1.2"/><rect x="10" y="8" width="7" height="5" fill="#dfe3ea"/><rect x="27" y="8" width="7" height="5" fill="#dfe3ea"/>'),
    "electrocution": ("t", '<circle cx="22" cy="20" r="7" fill="#f0c8a0" stroke="#3a2a10"/><path d="M14 13 L10 6 M22 12 V4 M30 13 L34 6" stroke="#ffe27a" stroke-width="2"/>' + BOLT.replace('M25 5', 'M24 24').replace(' L13 24 H21 L17 39 L31 18 H23 Z', ' L19 33 H23 L21 41 L28 30 H24 Z')),
    "saut_d_eclair": ("t", POLE.replace('M22 8 V36', 'M32 14 V36').replace('cx="22" cy="9"', 'cx="32" cy="15"').replace('M15 36 H29', 'M27 36 H37') + '<path d="M6 30 Q16 4 28 14" stroke="#ffe27a" stroke-width="2.2" fill="none" stroke-dasharray="3 2"/>'),
    "bouclier_statique": ("t", SHIELD.format(c="#8ad4ff") + '<path d="M6 8 L10 12 M38 8 L34 12 M6 34 L10 30 M38 34 L34 30" stroke="#ffe27a" stroke-width="2"/>'),
    "paratonnerre_vivant": ("t", '<circle cx="22" cy="18" r="5" fill="#f0c8a0"/><path d="M14 38 Q15 25 22 24 Q29 25 30 38 Z" fill="#eef1f6" stroke="#3a3a46"/><path d="M22 4 V13" stroke="#dfe3ea" stroke-width="2.4"/>' + BOLT.replace('M25 5', 'M30 2').replace(' L13 24 H21 L17 39 L31 18 H23 Z', ' L26 9 H29 L27 15 L33 7 H30 Z')),
    "saint_paratonnerre": ("s", POLE.replace('#8ad4ff', '#ffe27a') + HALO.format(c="#fff6c0").replace('cy="22"', 'cy="9"').replace('rx="15" ry="7"', 'rx="9" ry="3"').replace('rx="9" ry="4"', 'rx="5" ry="2"')),
}


def write(folder, data):
    with open(os.path.join(GAME, "data", folder, data["id"] + ".json"), "w", encoding="utf-8") as f:
        f.write(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


for data in SACRE + TEMPETE:
    write("sorts", data)
write("voies", VOIE)
images = {}
for name, (kind, body) in DRAWINGS.items():
    light, dark, edge = FRAMES[kind]
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="44" height="44" viewBox="0 0 44 44">\n'
           f'<defs><radialGradient id="f" cx="0.35" cy="0.3" r="0.9"><stop offset="0" stop-color="{light}"/><stop offset="1" stop-color="{dark}"/></radialGradient></defs>\n'
           f'<rect x="1.5" y="1.5" width="41" height="41" rx="7" fill="url(#f)" stroke="{edge}" stroke-width="2"/>\n{body}\n</svg>\n')
    with open(os.path.join(GAME, "art", "sorts", f"paladin_{name}.svgt"), "w") as f:
        f.write(svg)
    images[f"sort_paladin_{name}"] = {"fichier": f"sorts/paladin_{name}.svgt", "ancre": [22, 22]}
with open(os.path.join(GAME, "art", "manifestes", "paladin.json"), "w", encoding="utf-8") as f:
    f.write(json.dumps({"images": images}, ensure_ascii=False, indent=2) + "\n")
