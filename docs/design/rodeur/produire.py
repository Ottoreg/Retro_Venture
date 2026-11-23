"""Rôdeur (GDD § 4.3) : Voie, 20 sorts (10 Acier, 10 Flamme), icônes des 15 nouveaux sorts et du passif (SVG 44 × 44)
et fragment de manifeste `art/manifestes/rodeur.json`. Les icônes des 5 sorts d'origine restent dans `art.json`.

    python3 docs/design/rodeur/produire.py      # depuis la racine du dépôt
"""
import json
import os

GAME = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "game")


def dmg(element, low, high, **extra):
    return {"type": "degats", "element": element, "min": low, "max": high, "cibles": "ennemis", **extra}


def spell(sid, name, text, pa, rng, effects, mastery, **extra):
    return {"id": "rodeur_" + sid, "nom": name, "description": text, "cout_pa": pa, "portee": {"min": rng[0], "max": rng[1]},
            **extra, "effets": effects, "maitrise": mastery}


def trace(n=1):
    return {"type": "trace", "min": n, "max": n, "cibles": "ennemis"}


def buff(carac, value, turns=2, **extra):
    return {"type": "bonus", "carac": carac, "min": value, "max": value, "duree": turns, "cibles": "allies", **extra}


def malus(carac, value, turns=1, **extra):
    return {"type": "malus", "carac": carac, "min": value, "max": value, "duree": turns, "cibles": "ennemis", **extra}


def trap(effects, zone=None):
    return {"type": "piege", "effets": effects, **({"zone": zone} if zone else {})}


MINE = {"type": "detonateur", "piege": "rodeur_mine"}
PM = {"type": "retrait_pm", "min": 1, "max": 1, "cibles": "ennemis"}
CIRCLE = {"type": "cercle", "taille": 1}
ACIER = [
    spell("pister", "Pister", "Il relève les traces, les brindilles cassées et les miettes de pain : +2 Traces sur la cible (3 au plus, 3 tours).",
          2, (1, 8), [trace(2)], {"3": {"portee_max": 2}, "5": {"effets": [trace()]}}, ligne_de_vue=False, relance={"par_tour": 1}),
    spell("fleche", "Flèche", "Une flèche bien droite. Enfin, à peu près. +1 Trace.", 3, (2, 6), [dmg("acier", 5, 8), trace()],
          {"3": {"portee_max": 1}, "5": {"par_tour": 3}}, ligne_de_vue=True, relance={"par_tour": 2}),
    spell("tir_percant", "Tir perçant", "Une flèche lourde à pointe d'acier. Traverse les armures, et parfois le chapeau d'un voisin. +1 Trace.",
          4, (3, 7), [dmg("acier", 8, 11), trace()],
          {"3": {"effets": [dmg("acier", 10, 14, derriere=True)]}, "5": {"modifie": {"degats": {"perce_resistance": 20}}}},
          ligne_de_vue=True, relance={"par_tour": 1}),
    spell("tir_de_grace", "Tir de grâce", "Il vise longtemps, retient son souffle et ne rate (presque) jamais.", 5, (3, 7), [dmg("acier", 15, 20)],
          {"3": {"modifie": {"degats": {"execution": 30}}}, "5": {"modifie": {"degats": {"relance_si_tue": True}}}}, ligne_de_vue=True,
          relance={"par_tour": 1}),
    spell("dague", "Coup de dague", "Pour ceux qui s'approchent trop près, et pour ceux qu'il a pistés : +30 % par Trace de la cible, qui partent toutes.",
          2, (1, 1), [dmg("acier", 3, 5, par_trace=30)], {"3": {"modifie": {"degats": {"par_trace": 40}}}, "5": {"modifie": {"degats": {"pm_par_trace": 1}}}},
          relance={"par_tour": 2}),
    spell("collet", "Collet", "Un nœud coulant caché dans l'herbe. Le premier ennemi qui passe y laisse un bout de cheville et la moitié de son élan.",
          3, (1, 4), [trap([dmg("acier", 7, 10), dict(PM, min=2, max=2)])], {"3": {"effets_au_sol": [PM]}, "5": {"pieges_max": 1}},
          ligne_de_vue=False, pieges_max=1, relance={"par_tour": 1, "delai": 2}),
    spell("fleche_de_rabat", "Flèche de rabat", "Une flèche qui pousse le gibier droit vers le piège. +1 Trace.", 3, (2, 6),
          [dmg("acier", 3, 5), {"type": "poussee", "min": 2, "max": 2, "cibles": "ennemis"}, trace()],
          {"3": {"effets": [{"type": "poussee", "min": 1, "max": 1, "cibles": "ennemis"}]}, "5": {"modifie": {"poussee": {"attire_au_dela": 3}}}},
          ligne_de_vue=True, relance={"par_tour": 1}),
    spell("roulade", "Roulade", "Une roulade élégante vers une case libre, pour reprendre ses distances.", 2, (1, 2), [{"type": "teleportation"}],
          {"3": {"portee_max": 1}, "5": {"delai": 1}}, ligne_de_vue=False, relance={"par_tour": 1, "delai": 2}),
    spell("couvert", "Couvert", "Derrière un buisson, un tronc ou un voisin : −25 % de dégâts reçus à distance (2 cases ou plus) pendant 2 tours.",
          2, (0, 0), [buff("reduction_distance", 25)], {"3": {"effets": [buff("reduction_distance", 10)]}, "5": {"zone_taille": 1}},
          zone={"type": "cercle", "taille": 0}, relance={"par_tour": 1, "delai": 3}),
    spell("oeil_de_faucon", "Œil de faucon", "Il plisse les yeux comme un faucon (ou comme un myope) : +2 de portée et +10 % de critique pendant 2 tours.",
          2, (0, 5), [buff("portee", 2), buff("critique", 10)], {"3": {"duree": 1}, "5": {"effets": [buff("critique", 5, 3)]}},
          relance={"par_tour": 1, "delai": 4}),
]
FLAMME = [
    spell("mine", "Mine", "Un petit pot de poudre enterré : il saute (cercle de 1) au premier ennemi qui y entre, ou au Détonateur. 2 Mines à la fois.",
          2, (1, 5), [trap([dmg("flamme", 6, 8)], CIRCLE)], {"3": {"pieges_max": 1}, "5": {"zone_piege": 1}}, ligne_de_vue=False,
          pieges_max=2, relance={"par_tour": 2}),
    spell("fleche_enflammee", "Flèche enflammée", "Une flèche trempée dans la poix. Il prétend que c'est pour y voir clair.", 3, (2, 6),
          [dmg("flamme", 5, 8)], {"3": {"portee_max": 1}, "5": {"effets": [dict(MINE, rayon=1)]}}, ligne_de_vue=True, relance={"par_tour": 2}),
    spell("bombe_artisanale", "Bombe artisanale", "Une gourde de poudre et une mèche trop courte, lancée par-dessus les obstacles.", 4, (2, 5),
          [dmg("flamme", 7, 10)], {"3": {"portee_max": 1}, "5": {"par_tour": 2}}, ligne_de_vue=False, zone=CIRCLE, relance={"par_tour": 1}),
    spell("fleche_explosive", "Flèche explosive", "Elle explose à l'arrivée : gros dégâts à la cible, moitié autour.", 5, (3, 7),
          [dmg("flamme", 7, 9), dmg("flamme", 7, 9, centre_seul=True)],
          {"3": {"effets": [{"type": "poussee", "min": 1, "max": 1, "cibles": "ennemis", "depuis_centre": True}]},
           "5": {"modifie": {"degats": {"bonus_pct": 20}}}}, ligne_de_vue=True, zone=CIRCLE, relance={"par_tour": 1}),
    spell("detonateur", "Détonateur", "Il tire sur la ficelle : toutes ses Mines sautent d'un coup, +10 % par Mine qui saute.", 3, (0, 0),
          [dict(MINE, bonus=10)], {"3": {"modifie": {"detonateur": {"bonus": 15}}}, "5": {"modifie": {"detonateur": {"pa_par_piege": 1}}}},
          ligne_de_vue=False, relance={"par_tour": 1}),
    spell("machoire_de_loup", "Mâchoire de loup", "Un piège à loup bien graissé : la victime y reste enchaînée, à 3 cases au plus du piège, pendant 3 tours.",
          3, (1, 4), [trap([dmg("flamme", 6, 9), {"type": "etat", "etat": "enchaine", "duree": 3, "cibles": "ennemis"}])],
          {"3": {"duree": 1}, "5": {"effets_au_sol": [{"type": "poison", "element": "flamme", "min": 3, "max": 3, "duree": 4, "cibles": "ennemis"}]}},
          ligne_de_vue=False, pieges_max=1, relance={"par_tour": 1, "delai": 2}),
    spell("piege_a_fil", "Piège à fil", "Deux fils tendus en travers du chemin, un explosif à chaque bout : traverser un fil ou marcher sur un explosif fait tout sauter.",
          4, (2, 5), [trap([dmg("flamme", 8, 11)], {"type": "fil", "taille": 2})], {"3": {"effets_au_sol": [PM]}, "5": {"zone_piege": 2}},
          ligne_de_vue=False, pieges_max=1, relance={"par_tour": 1, "delai": 2}),
    spell("saut_a_la_poudre", "Saut à la poudre", "Une pincée de poudre sous les bottes, et le voilà plus loin, les sourcils en moins.", 3, (2, 4),
          [{"type": "teleportation"}, dmg("flamme", 4, 6, au_depart=True, taille=1)],
          {"3": {"portee_max": 1}, "5": {"effets": [dict(trap([dmg("flamme", 6, 8)], CIRCLE), au_depart=True, sort_piege="rodeur_mine")]}},
          ligne_de_vue=False, relance={"par_tour": 1, "delai": 2}),
    spell("ecran_de_fumee", "Écran de fumée", "Un nuage de fumée autour de lui pendant 2 tours : personne ne voit au travers (lui non plus).", 2, (0, 0),
          [{"type": "glyphe", "duree": 2, "fumee": True, "effets": []}], {"3": {"duree": 1}, "5": {"effets_au_sol": [malus("pm", 1)]}},
          zone=CIRCLE, relance={"par_tour": 1, "delai": 3}),
    spell("fusee_eclairante", "Fusée éclairante", "Une fusée qui éclaire tout (cercle de 3) : pièges ennemis et invisibles révélés, ennemis +15 % de dégâts Flamme reçus pendant 2 tours.",
          2, (1, 7), [{"type": "revelation"}, malus("resistance", 15, 2, element="flamme")], {"3": {"zone_taille": 4}, "5": {"effets": [malus("resistance", 10, 2, element="flamme")]}},
          ligne_de_vue=False, zone={"type": "cercle", "taille": 3}, relance={"par_tour": 1, "delai": 2}),
]
VOIE = {
    "id": "rodeur", "nom": "Rôdeur",
    "description": "Tire de loin, file entre les arbres et prétend toujours connaître un raccourci.",
    "caracteristiques": {"pv": 50, "pa": 6, "pm": 3, "initiative": 100},
    "sorts": [s["id"] for s in ACIER + FLAMME],
    "passif": {"id": "rodeur_rabatteur", "nom": "Rabatteur", "effet": "rabatteur",
               "description": "Débloqué au palier Apprenti. Un ennemi poussé ou attiré sur un piège du Rôdeur subit +20 % de dégâts du piège (+4 % par rang, 40 % au rang 5). Rang 3 : il est aussi immobilisé (0 PM) à son prochain tour. Rang 5 : le Rôdeur récupère 1 PA, une fois par tour."},
}

# Icônes : Acier vert forêt à liseré brun (comme les 5 sorts d'origine), Flamme orange à liseré brun.
FRAMES = {"a": ("#86d65a", "#2a6a24", "#2a1c10"), "f": ("#ffb347", "#8a2a0a", "#2a1c10")}
ARROW = '<path d="M8 34 L32 10" stroke="#2a1c10" stroke-width="3.6" stroke-linecap="round"/><path d="M8 34 L32 10" stroke="{c}" stroke-width="2" stroke-linecap="round"/><path d="M34 8 L24 11 L31 18 Z" fill="#fff4dc" stroke="#2a1c10" stroke-width="1.4"/>'
POT = '<ellipse cx="22" cy="28" rx="10" ry="8" fill="#5a3a20" stroke="#2a1c10" stroke-width="1.4"/><path d="M22 20 Q26 12 30 10" stroke="#fff4dc" stroke-width="1.6" fill="none"/><circle cx="31" cy="9" r="2.4" fill="#ffe27a"/>'
BLAST = '<path d="M22 6 L25 16 L35 12 L28 21 L38 26 L27 27 L30 37 L22 30 L14 37 L17 27 L6 26 L16 21 L9 12 L19 16 Z" fill="#ffe27a" stroke="#a83a0a" stroke-width="1.4"/>'
DRAWINGS = {
    "pister": ("a", "".join(f'<ellipse cx="{x}" cy="{y}" rx="3.4" ry="5" fill="#2a1c10" transform="rotate(-20 {x} {y})"/>' for x, y in [(12, 32), (20, 24), (26, 16), (33, 9)])),
    "tir_de_grace": ("a", '<circle cx="22" cy="22" r="13" fill="none" stroke="#fff4dc" stroke-width="2"/><circle cx="22" cy="22" r="3" fill="#c0392b"/><path d="M22 5 V13 M22 31 V39 M5 22 H13 M31 22 H39" stroke="#fff4dc" stroke-width="2"/>'),
    "fleche_de_rabat": ("a", ARROW.format(c="#c99a5a") + '<path d="M30 30 H40 M36 26 L40 30 L36 34" stroke="#fff4dc" stroke-width="2" fill="none"/>'),
    "couvert": ("a", '<path d="M6 36 Q8 14 22 10 Q36 14 38 36 Z" fill="#3f7a2a" stroke="#2a1c10" stroke-width="1.4"/><circle cx="16" cy="22" r="4" fill="#5aa03a"/><circle cx="27" cy="18" r="5" fill="#5aa03a"/>'),
    "oeil_de_faucon": ("a", '<path d="M5 22 Q22 8 39 22 Q22 36 5 22 Z" fill="#fff4dc" stroke="#2a1c10" stroke-width="1.6"/><circle cx="22" cy="22" r="6" fill="#c99a2a"/><circle cx="22" cy="22" r="2.6" fill="#2a1c10"/>'),
    "mine": ("f", POT),
    "fleche_enflammee": ("f", ARROW.format(c="#ff7a2a") + '<path d="M10 30 Q6 24 12 20 Q12 26 16 26" fill="#ffe27a"/>'),
    "bombe_artisanale": ("f", '<circle cx="20" cy="26" r="10" fill="#3a2a20" stroke="#2a1c10" stroke-width="1.4"/><path d="M26 18 Q30 10 36 9" stroke="#fff4dc" stroke-width="1.6" fill="none"/><circle cx="36" cy="8" r="2.4" fill="#ffe27a"/>'),
    "fleche_explosive": ("f", BLAST + ARROW.format(c="#c99a5a").replace("M8 34 L32 10", "M8 34 L22 20")),
    "detonateur": ("f", '<rect x="10" y="20" width="24" height="16" rx="2" fill="#7a3a1a" stroke="#2a1c10" stroke-width="1.4"/><path d="M22 20 V8 M16 8 H28" stroke="#2a1c10" stroke-width="3"/>'),
    "machoire_de_loup": ("f", '<path d="M6 26 Q22 6 38 26" stroke="#d8d8d8" stroke-width="3" fill="none"/>' + "".join(f'<path d="M{x} 22 l3 6 l3 -6" fill="#d8d8d8"/>' for x in (10, 17, 24, 31)) + '<path d="M22 28 V38" stroke="#7a7a7a" stroke-width="2" stroke-dasharray="2 2"/>'),
    "piege_a_fil": ("f", '<path d="M8 32 L36 12" stroke="#fff4dc" stroke-width="1.4"/><circle cx="8" cy="32" r="5" fill="#5a3a20" stroke="#2a1c10"/><circle cx="36" cy="12" r="5" fill="#5a3a20" stroke="#2a1c10"/><circle cx="8" cy="32" r="2" fill="#ffe27a"/><circle cx="36" cy="12" r="2" fill="#ffe27a"/>'),
    "saut_a_la_poudre": ("f", '<path d="M8 36 Q20 4 36 14" stroke="#fff4dc" stroke-width="2.4" fill="none" stroke-dasharray="4 3"/><path d="M4 38 L10 30 L14 38 Z" fill="#ffe27a"/>'),
    "ecran_de_fumee": ("f", "".join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#b8b8b8" stroke="#6a6a6a"/>' for x, y, r in [(14, 26, 8), (26, 22, 9), (20, 14, 7), (31, 30, 7)])),
    "fusee_eclairante": ("f", '<path d="M22 38 V20" stroke="#fff4dc" stroke-width="2" stroke-dasharray="3 2"/><circle cx="22" cy="14" r="7" fill="#fff6b0" stroke="#ffe27a" stroke-width="2"/><path d="M22 3 V6 M11 14 H14 M30 14 H33 M14 6 l2 2 M30 6 l-2 2" stroke="#fff6b0" stroke-width="2"/>'),
    "rabatteur": ("a", '<path d="M8 22 H28 M23 16 L29 22 L23 28" stroke="#fff4dc" stroke-width="3" fill="none"/><path d="M28 30 Q34 22 40 30" stroke="#d8d8d8" stroke-width="2.4" fill="none"/>'),
}


def write(folder, data):
    with open(os.path.join(GAME, "data", folder, data["id"] + ".json"), "w", encoding="utf-8") as f:
        f.write(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


for data in ACIER + FLAMME:
    write("sorts", data)
write("voies", VOIE)
images = {}
for name, (kind, body) in DRAWINGS.items():
    light, dark, edge = FRAMES[kind]
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="44" height="44" viewBox="0 0 44 44">\n'
           f'<defs><radialGradient id="f" cx="0.35" cy="0.3" r="0.9"><stop offset="0" stop-color="{light}"/><stop offset="1" stop-color="{dark}"/></radialGradient></defs>\n'
           f'<rect x="1.5" y="1.5" width="41" height="41" rx="7" fill="url(#f)" stroke="{edge}" stroke-width="2"/>\n{body}\n</svg>\n')
    with open(os.path.join(GAME, "art", "sorts", f"rodeur_{name}.svgt"), "w") as f:
        f.write(svg)
    images[f"sort_rodeur_{name}"] = {"fichier": f"sorts/rodeur_{name}.svgt", "ancre": [22, 22]}
with open(os.path.join(GAME, "art", "manifestes", "rodeur.json"), "w", encoding="utf-8") as f:
    f.write(json.dumps({"images": images}, ensure_ascii=False, indent=2) + "\n")
