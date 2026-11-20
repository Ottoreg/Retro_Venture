"""Démoniste (GDD § 4.3) : Voie, 20 sorts, 7 sorts de serviteurs, icônes (SVG 44 × 44) et fragment de manifeste
`art/manifestes/demoniste.json` (icônes, serviteurs dessinés d'après des monstres existants, recoloriés).

    python3 docs/design/demoniste/produire.py      # depuis la racine du dépôt
"""
import json
import os

GAME = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "game")


def dmg(element, low, high, targets="ennemis", **extra):
    return {"type": "degats", "element": element, "min": low, "max": high, "cibles": targets, **extra}


def spell(sid, name, text, pa, rng, effects, mastery, **extra):
    return {"id": sid, "nom": name, "description": text, "cout_pa": pa, "portee": {"min": rng[0], "max": rng[1]},
            **extra, "effets": effects, "maitrise": mastery}


def servant(sid, name, hp, pa, pm, spells, rank5, **extra):
    return {"type": "invocation", "serviteur": {"id": sid, "nom": name, "pv": hp, "pa": pa, "pm": pm, "sorts": spells,
                                                 "sorts_rang_5": rank5, **extra}}


CIRCLE = {"type": "cercle", "taille": 1}
SERVANT_NOTE = " Rang 3 : il arrive avec 1 PM de plus. Rang 5 : il connaît un sort de plus."
IMPIE = [
    spell("demoniste_appel_du_diablotin", "Appel du Diablotin", "Invoque un Diablotin stagiaire, payé en expérience : il pique à la fourche et crache du soufre." + SERVANT_NOTE,
          3, (1, 2), [servant("diablotin", "Diablotin stagiaire", 30, 4, 3, ["diablotin_fourche"], ["diablotin_crachat_de_soufre"])], {},
          relance={"delai": 1}),
    spell("demoniste_trait_impie", "Trait impie", "Un trait de malédiction, signé en bas à droite.", 3, (1, 6), [dmg("impie", 7, 9)],
          {"3": {"portee_max": 1}, "5": {"critique": 10}}, relance={"par_tour": 2}),
    spell("demoniste_nuee_de_chauves_souris", "Nuée de chauves-souris", "Une nuée qui mord tout ce qui passe, sauf les alliés (elles ont signé une charte).",
          4, (2, 6), [dmg("impie", 6, 8)], {"3": {"cout_pa": 3}, "5": {"effets": [{"type": "malus", "carac": "portee", "min": 1, "max": 1, "duree": 1, "cibles": "ennemis"}]}},
          zone=CIRCLE, relance={"par_tour": 1}),
    spell("demoniste_main_du_malin", "Main du Malin", "Une main griffue sort du sol : +20 % de dégâts par serviteur vivant du Démoniste.",
          5, (1, 3), [dmg("impie", 14, 18, par_serviteur=20)], {"3": {"portee_max": 1}, "5": {"critique": 15}}, relance={"par_tour": 1}),
    spell("demoniste_sacrifice", "Sacrifice", "Fait exploser un de ses serviteurs : dégâts autour de lui, plus la moitié de ses PV restants. Rupture de contrat sans préavis.",
          2, (1, 6), [{"type": "sacrifice", "element": "impie", "min": 8, "max": 10, "part_pv": 50}],
          {"3": {"cout_pa": 1}, "5": {"effets": [{"type": "soin", "element": "impie", "min": 10, "max": 10, "pourcent_pv": True, "sur_lanceur": True}]}},
          ligne_de_vue=False, relance={"par_tour": 1}),
    spell("demoniste_chaines_infernales", "Chaînes infernales", "Des chaînes brûlantes aux chevilles : l'ennemi ira moins loin.", 3, (1, 5),
          [{"type": "retrait_pm", "min": 2, "max": 2, "cibles": "ennemis"}],
          {"3": {"portee_max": 1}, "5": {"effets": [{"type": "malus", "carac": "pa", "min": 1, "max": 1, "duree": 1, "cibles": "ennemis"}]}}),
    spell("demoniste_effroi", "Effroi", "Une vision des Enfers (avec la musique d'ascenseur) : l'ennemi recule et perd ses moyens.", 3, (1, 4),
          [{"type": "poussee", "min": 2, "max": 2, "cibles": "ennemis"}, {"type": "malus", "carac": "pa", "min": 1, "max": 1, "duree": 1, "cibles": "ennemis"}],
          {"3": {"cout_pa": 2}, "5": {"effets": [dmg("impie", 5, 7)]}}, relance={"par_tour": 1}),
    spell("demoniste_permutation", "Permutation", "Échange sa place avec un de ses serviteurs : c'est dans le contrat, page 66.", 1, (1, 8),
          [{"type": "permutation"}], {"3": {"portee_max": 2}, "5": {"effets": [{"type": "bonus", "carac": "pm", "min": 1, "max": 1, "duree": 1, "sur_lanceur": True}]}},
          ligne_de_vue=False, relance={"par_tour": 1}),
    spell("demoniste_appel_du_molosse", "Appel du Molosse", "Invoque un Molosse de garde, en CDI : beaucoup de PV, ne lâche rien (surtout pas ses congés)." + SERVANT_NOTE,
          4, (1, 2), [servant("molosse", "Molosse de garde", 80, 4, 3, ["molosse_morsure"], ["molosse_grognement"], stats_combat={"tacle": 10})], {},
          relance={"delai": 2}),
    spell("demoniste_appel_de_la_succube", "Appel de la Succube", "Invoque la Succube des ressources humaines : elle soigne et motive. Vos plaintes seront traitées sous 666 jours." + SERVANT_NOTE,
          3, (1, 2), [servant("succube", "Succube des RH", 40, 4, 3, ["succube_soin_rh", "succube_prime_de_motivation"], ["succube_pause_cafe"])], {},
          relance={"delai": 2}),
]
FLAMME = [
    spell("demoniste_mise_a_feu", "Mise à feu", "Allume tout autour : embrase les cases de 2 niveaux d'un coup. Sur une case calcinée, les cendres s'envolent : −1 PM aux ennemis.",
          2, (1, 6), [dmg("flamme", 3, 4)], {"3": {"portee_max": 1}, "5": {"embrase": 1}}, zone=CIRCLE, embrase=2,
          calcinee={"effets": [{"type": "retrait_pm", "min": 1, "max": 1, "cibles": "ennemis"}]}, relance={"par_tour": 1}),
    spell("demoniste_escarbille", "Escarbille", "Une petite boule de feu qui saute partout. Sur une case calcinée, elle rend 1 PA.", 2, (1, 7),
          [dmg("flamme", 5, 6)], {"3": {"critique": 10}, "5": {"portee_max": 1}}, embrase=1,
          calcinee={"effets": [{"type": "gain_pa", "min": 1, "max": 1, "sur_lanceur": True}]}, relance={"par_tour": 3}),
    spell("demoniste_pluie_de_soufre", "Pluie de soufre", "Il pleut du soufre, et pas qu'un peu. Sur une case calcinée, ça brûle encore 2 tours.", 4, (3, 8),
          [dmg("flamme", 7, 9)], {"3": {"cout_pa": 3}, "5": {"critique": 10}}, zone=CIRCLE, embrase=1,
          calcinee={"effets": [{"type": "poison", "element": "flamme", "min": 3, "max": 4, "duree": 2, "cibles": "ennemis"}]}, relance={"par_tour": 1}),
    spell("demoniste_fournaise", "Fournaise", "La porte du four s'ouvre en grand. Sur une case calcinée : +50 % de dégâts.", 5, (1, 4),
          [dmg("flamme", 13, 16)], {"3": {"portee_max": 1}, "5": {"embrase": 1}}, zone=CIRCLE, embrase=1, calcinee={"bonus": 50},
          relance={"par_tour": 1}),
    spell("demoniste_explosion_de_cendres", "Explosion de cendres", "Souffle sur les braises de la zone : dégâts pour chaque niveau d'embrasement (une case calcinée compte 4), puis tout s'éteint.",
          3, (1, 6), [{"type": "cendres", "element": "flamme", "min": 2, "max": 3, "cibles": "ennemis"}], {"3": {"cout_pa": 2}, "5": {"critique": 10}},
          zone={"type": "cercle", "taille": 2}, embrase=0, relance={"par_tour": 1}),
    spell("demoniste_mur_de_flammes", "Mur de flammes", "Un mur de feu en travers : il brûle ceux qui y commencent leur tour, un tour de plus par niveau d'embrasement. Sur une case calcinée, il ne tient pas mais brûle bien plus fort tout de suite.",
          3, (2, 5), [{"type": "glyphe", "duree": 1, "duree_embrasement": True, "effets": [dmg("flamme", 6, 8)]}],
          {"3": {"portee_max": 1}, "5": {"zone_taille": 2}}, zone={"type": "mur", "taille": 1}, embrase=1,
          calcinee={"seuls": True, "effets": [dmg("flamme", 12, 15)]}, relance={"par_tour": 1}),
    spell("demoniste_fumees_acres", "Fumées âcres", "Une fumée qui pique les yeux et coupe les jambes. Sur une case calcinée, on n'y voit plus rien : −2 de portée.", 3, (1, 5),
          [{"type": "retrait_pm", "min": 2, "max": 2, "cibles": "ennemis"}],
          {"3": {"portee_max": 1}, "5": {"effets": [{"type": "malus", "carac": "pa", "min": 1, "max": 1, "duree": 1, "cibles": "ennemis"}]}}, embrase=1,
          calcinee={"effets": [{"type": "malus", "carac": "portee", "min": 2, "max": 2, "duree": 1, "cibles": "ennemis"}]}, relance={"par_tour": 1}),
    spell("demoniste_pas_de_braise", "Pas de braise", "Disparaît dans une gerbe d'étincelles. Portée 6 vers une case embrasée ; sur une case calcinée, +1 PM.", 2, (1, 3),
          [{"type": "teleportation"}], {"3": {"cout_pa": 1}, "5": {"portee_max": 1}}, ligne_de_vue=False, embrase=1, portee_embrasee=6,
          calcinee={"effets": [{"type": "bonus", "carac": "pm", "min": 1, "max": 1, "duree": 1, "sur_lanceur": True}]}, relance={"par_tour": 1}),
    spell("demoniste_peau_de_cendre", "Peau de cendre", "Une croûte de cendre chaude qui absorbe les coups (+10 % par niveau de sa case). Sur une case calcinée, elle brûle qui la frappe.",
          2, (0, 0), [{"type": "bouclier", "element": "flamme", "min": 8, "max": 10}],
          {"3": {"cout_pa": 1}, "5": {"effets": [{"type": "bonus", "carac": "resistance", "element": "flamme", "min": 10, "max": 10, "duree": 1}]}}, embrase=1,
          calcinee={"effets": [{"type": "bonus", "carac": "epines_flamme", "min": 15, "max": 15, "duree": 1}]}, relance={"par_tour": 1}),
    spell("demoniste_feu_de_camp", "Feu de camp", "On se réchauffe ensemble (serviteurs compris, ils ont insisté). Sur une case calcinée : soins doublés, sans rallumer.", 3, (0, 4),
          [{"type": "soin", "element": "flamme", "min": 5, "max": 7, "cibles": "allies"}],
          {"3": {"portee_max": 1}, "5": {"effets": [{"type": "bonus", "carac": "dommages", "min": 5, "max": 5, "duree": 1, "cibles": "allies"}]}}, zone=CIRCLE,
          embrase=1, calcinee={"bonus": 100, "embrase": 0}, relance={"par_tour": 1}),
]
SERVANTS = [
    spell("diablotin_fourche", "Coup de fourche", "Un petit coup de fourche, pas bien méchant mais très insistant.", 2, (1, 4), [dmg("impie", 5, 7)], {}, relance={"par_tour": 2}),
    spell("diablotin_crachat_de_soufre", "Crachat de soufre", "Un crachat qui éclabousse les voisins.", 2, (2, 4), [dmg("impie", 4, 5)], {}, zone=CIRCLE, relance={"par_tour": 1}),
    spell("molosse_morsure", "Morsure", "Il mord, et ne lâche pas avant la pause.", 3, (1, 1), [dmg("impie", 7, 9)], {}, relance={"par_tour": 1}),
    spell("molosse_grognement", "Grognement", "Un grognement qui fait venir l'ennemi à lui.", 1, (2, 4), [{"type": "attirance", "min": 2, "max": 2, "cibles": "ennemis"}], {},
          relance={"par_tour": 1}),
    spell("succube_soin_rh", "Soin des RH", "Un soin réglementaire, formulaire rempli en trois exemplaires.", 2, (1, 4),
          [{"type": "soin", "element": "impie", "min": 6, "max": 8, "cibles": "allies"}], {}, relance={"par_tour": 1}),
    spell("succube_prime_de_motivation", "Prime de motivation", "+5 Dommages pendant 2 tours. Non reconductible.", 2, (0, 4),
          [{"type": "bonus", "carac": "dommages", "min": 5, "max": 5, "duree": 2, "cibles": "allies"}], {}, relance={"par_tour": 1}),
    spell("succube_pause_cafe", "Pause café", "Tout le monde autour souffle un peu.", 3, (0, 3), [{"type": "soin", "element": "impie", "min": 4, "max": 6, "cibles": "allies"}], {},
          zone=CIRCLE, relance={"par_tour": 1}),
]
VOIE = {
    "id": "demoniste", "nom": "Démoniste",
    "description": "Démoniste agréé, ancien sous-traitant du Mordor. Ses démons pointent à l'heure (pas une minute de plus, la convention collective des Enfers est formelle) ; lui brûle tout ce qui refuse de signer.",
    "caracteristiques": {"pv": 50, "pa": 6, "pm": 3, "initiative": 100},
    "sorts": [s["id"] for s in IMPIE + FLAMME],
    "passif": {"id": "demoniste_pacte_de_feu", "nom": "Pacte de feu", "effet": "pacte_de_feu",
               "description": "Débloqué au palier Apprenti. +6 % de dégâts (+1 % par rang), pour lui et ses serviteurs, contre une cible sur une case embrasée ou calcinée. Rang 3 : un serviteur invoqué sur une case embrasée a +20 % de PV. Rang 5 : un 3e serviteur en même temps."},
}

# Icônes : Impie violet à liseré vert, Flamme orange à liseré noir (couleurs de la classe).
FRAMES = {"i": ("#6a3a8a", "#140a1e", "#8ad46a"), "f": ("#e07a2a", "#2a0c04", "#1a1a1a")}
FIRE = '<path d="M22 36 Q12 34 13 24 Q14 18 19 14 Q18 20 22 21 Q21 14 26 8 Q27 16 31 20 Q34 27 30 33 Q27 36 22 36 Z" fill="#ffb02e" stroke="#7a2a08" stroke-width="1"/><path d="M22 34 Q17 32 18 27 Q20 24 22 25 Q23 21 26 19 Q29 26 26 31 Z" fill="#ffe27a"/>'
IMP = '<circle cx="22" cy="22" r="8" fill="{c}"/><path d="M15 17 L13 9 L19 15 Z M29 17 L31 9 L25 15 Z" fill="{c}"/><circle cx="19" cy="21" r="1.4" fill="#ffe27a"/><circle cx="25" cy="21" r="1.4" fill="#ffe27a"/>'
CHAIN = '<g fill="none" stroke="#c9ccd6" stroke-width="2.4"><ellipse cx="13" cy="22" rx="5" ry="3.4"/><ellipse cx="22" cy="22" rx="5" ry="3.4" transform="rotate(90 22 22)"/><ellipse cx="31" cy="22" rx="5" ry="3.4"/></g>'
DRAWINGS = {
    "appel_du_diablotin": ("i", IMP.format(c="#c2402a") + '<path d="M33 10 V32 M30 10 L33 6 L36 10" stroke="#dfe3ea" stroke-width="1.8" fill="none"/>'),
    "trait_impie": ("i", '<path d="M7 33 L33 11" stroke="#8ad46a" stroke-width="3.4" stroke-linecap="round"/><path d="M33 11 L26 12 L32 18 Z" fill="#8ad46a"/>'),
    "nuee_de_chauves_souris": ("i", "".join(f'<path d="M{x} {y} q3 -4 6 0 q3 -4 6 0 q-3 1 -6 4 q-3 -3 -6 -4 Z" fill="#1a0f24" stroke="#b48ad4" stroke-width="0.8"/>' for x, y in [(8, 14), (22, 10), (15, 25), (27, 26)])),
    "main_du_malin": ("i", '<path d="M12 36 V22 Q12 18 15 19 V14 Q15 11 18 12 V10 Q19 7 22 9 V11 Q24 9 26 11 V14 Q29 13 29 17 V26 Q29 32 24 36 Z" fill="#4a2a5e" stroke="#8ad46a" stroke-width="1.4"/>'),
    "sacrifice": ("i", IMP.format(c="#7a3a9a") + '<path d="M22 4 L24 12 L32 8 L27 15 L36 18 L27 20" stroke="#ffb02e" stroke-width="1.8" fill="none"/>'),
    "chaines_infernales": ("i", CHAIN),
    "effroi": ("i", '<path d="M10 14 Q22 4 34 14 Q36 28 22 36 Q8 28 10 14 Z" fill="#e8e0d0"/><ellipse cx="17" cy="19" rx="3" ry="4" fill="#140a1e"/><ellipse cx="27" cy="19" rx="3" ry="4" fill="#140a1e"/><ellipse cx="22" cy="29" rx="3" ry="4" fill="#140a1e"/>'),
    "permutation": ("i", '<path d="M8 16 H30 L26 11 M36 28 H14 L18 33" stroke="#8ad46a" stroke-width="2.6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'),
    "appel_du_molosse": ("i", '<path d="M9 30 Q8 18 16 15 L19 9 L22 15 Q31 14 35 22 Q36 27 31 28 L27 26 Q22 32 9 30 Z" fill="#8a2a1e" stroke="#140a1e" stroke-width="1.2"/><circle cx="28" cy="20" r="1.6" fill="#ffe27a"/>'),
    "appel_de_la_succube": ("i", '<circle cx="22" cy="15" r="5" fill="#e0a0b0"/><path d="M15 36 Q16 22 22 21 Q28 22 29 36 Z" fill="#a02a4a"/><path d="M15 22 Q6 16 7 28 Q11 24 15 26 Z M29 22 Q38 16 37 28 Q33 24 29 26 Z" fill="#4a1a2e"/>'),
    "mise_a_feu": ("f", FIRE + '<path d="M8 10 L14 16" stroke="#dfe3ea" stroke-width="2.4" stroke-linecap="round"/>'),
    "escarbille": ("f", '<circle cx="22" cy="22" r="6" fill="#ffb02e" stroke="#7a2a08"/><circle cx="12" cy="14" r="2" fill="#ffe27a"/><circle cx="33" cy="12" r="1.6" fill="#ffe27a"/><circle cx="31" cy="32" r="2" fill="#ffe27a"/>'),
    "pluie_de_soufre": ("f", '<ellipse cx="22" cy="12" rx="13" ry="5" fill="#5a4a3a"/>' + "".join(f'<path d="M{x} 20 l-3 8" stroke="#ffe27a" stroke-width="2.2" stroke-linecap="round"/>' for x in (13, 20, 27, 34))),
    "fournaise": ("f", '<rect x="9" y="12" width="26" height="22" rx="3" fill="#3a2a22" stroke="#1a1a1a" stroke-width="1.4"/><rect x="13" y="18" width="18" height="12" rx="2" fill="#ff7a1e"/>' + FIRE.replace('fill="#ffb02e"', 'fill="#ffb02e" transform="translate(11 9) scale(0.5)"').replace('fill="#ffe27a"/>', 'fill="#ffe27a" transform="translate(11 9) scale(0.5)"/>')),
    "explosion_de_cendres": ("f", '<path d="M22 6 L25 17 L36 14 L28 22 L37 30 L25 27 L22 38 L19 27 L7 30 L16 22 L8 14 L19 17 Z" fill="#8a8a8a" stroke="#ffb02e" stroke-width="1.4"/>'),
    "mur_de_flammes": ("f", "".join(FIRE.replace("<path", f'<path transform="translate({dx} 6) scale(0.62)"') for dx in (-1, 9, 19))),
    "fumees_acres": ("f", '<path d="M10 32 Q6 24 13 22 Q12 14 20 15 Q24 8 30 14 Q38 15 35 24 Q39 31 31 32 Z" fill="#7a6a5a" stroke="#2a1a10" stroke-width="1"/>'),
    "pas_de_braise": ("f", '<ellipse cx="14" cy="31" rx="5" ry="3" fill="#ffb02e" opacity="0.7"/><ellipse cx="29" cy="20" rx="4" ry="6" fill="#ffe27a"/><circle cx="20" cy="26" r="1.4" fill="#ffe27a"/><circle cx="24" cy="23" r="1.2" fill="#ffe27a"/>'),
    "peau_de_cendre": ("f", '<path d="M22 7 L34 12 Q34 28 22 37 Q10 28 10 12 Z" fill="#5a4a42" stroke="#ffb02e" stroke-width="2"/><path d="M16 18 l4 3 l-2 4 M26 15 l-2 5 l4 3" stroke="#ff7a1e" stroke-width="1.4" fill="none"/>'),
    "feu_de_camp": ("f", FIRE + '<path d="M10 37 L34 31 M10 31 L34 37" stroke="#6b4a2b" stroke-width="3" stroke-linecap="round"/>'),
    "pacte_de_feu": ("f", '<rect x="11" y="8" width="22" height="28" rx="2" fill="#efe2c0" stroke="#1a1a1a" stroke-width="1.2"/><path d="M15 15 H29 M15 20 H29 M15 25 H24" stroke="#5a4a3a" stroke-width="1.4"/><circle cx="28" cy="31" r="4" fill="#c2402a"/>'),
}
SERVANT_ICONS = {"diablotin_fourche": "appel_du_diablotin", "diablotin_crachat_de_soufre": "sacrifice", "molosse_morsure": "appel_du_molosse",
                 "molosse_grognement": "effroi", "succube_soin_rh": "appel_de_la_succube", "succube_prime_de_motivation": "appel_de_la_succube",
                 "succube_pause_cafe": "appel_de_la_succube"}
# Serviteurs : dessins de monstres existants recoloriés en attendant leurs planches PixelLab (assets/demoniste/PROMPTS.md).
MONSTERS = {"diablotin": {"image": "gargouille", "echelle": 0.6, "teinte": "ff6a4a"},
            "molosse": {"image": "loup", "echelle": 1.0, "couleurs": {"pelage": "6a1a12", "pelage_ombre": "3a0c08", "ventre": "ff8a2a"}},
            "succube": {"rig": "humain", "couleurs": {"peau": "e0a0b0", "tunique": "a02a4a", "manches": "7a1a34", "pantalon": "4a1a2e", "bottes": "2a0c18",
                                                      "ceinture": "c9a04e", "cheveux": "1a0a12"}, "arme": "sceptre", "accessoires": ["ailes"]}}


def write(folder, data):
    with open(os.path.join(GAME, "data", folder, data["id"] + ".json"), "w", encoding="utf-8") as f:
        f.write(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


for data in IMPIE + FLAMME + SERVANTS:
    write("sorts", data)
write("voies", VOIE)
images = {}
for name, (kind, body) in DRAWINGS.items():
    light, dark, edge = FRAMES[kind]
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="44" height="44" viewBox="0 0 44 44">\n'
           f'<defs><radialGradient id="f" cx="0.35" cy="0.3" r="0.9"><stop offset="0" stop-color="{light}"/><stop offset="1" stop-color="{dark}"/></radialGradient></defs>\n'
           f'<rect x="1.5" y="1.5" width="41" height="41" rx="7" fill="url(#f)" stroke="{edge}" stroke-width="2"/>\n{body}\n</svg>\n')
    with open(os.path.join(GAME, "art", "sorts", f"demoniste_{name}.svgt"), "w") as f:
        f.write(svg)
    images[f"sort_demoniste_{name}"] = {"fichier": f"sorts/demoniste_{name}.svgt", "ancre": [22, 22]}
for spell_id, icon in SERVANT_ICONS.items():
    images[f"sort_{spell_id}"] = images[f"sort_demoniste_{icon}"]
with open(os.path.join(GAME, "art", "manifestes", "demoniste.json"), "w", encoding="utf-8") as f:
    f.write(json.dumps({"images": images, "monstres": MONSTERS}, ensure_ascii=False, indent=2) + "\n")
