"""Chronomancien (GDD § 4.3) : Voie (20 sorts et passif « Temps volé »), rangs 3 et 5 des 6 sorts Impie existants, 14 sorts
nouveaux, icônes (SVG 44 × 44) et fragment de manifeste `art/manifestes/chronomancien.json`.

    python3 docs/design/chronomancien/produire.py      # depuis la racine du dépôt
"""
import json
import os

GAME = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "game")


def path(folder, name):
    return os.path.join(GAME, "data", folder, name + ".json")


def dmg(element, low, high, **extra):
    return {"type": "degats", "element": element, "min": low, "max": high, **extra}


def change(carac, value, turns, kind="bonus", **extra):
    return {"type": kind, "carac": carac, "min": value, "max": value, "duree": turns, **extra}


def spell(sid, name, text, pa, rng, effects, mastery, **extra):
    return {"id": "chronomancien_" + sid, "nom": name, "description": text, "cout_pa": pa, "portee": {"min": rng[0], "max": rng[1]},
            **extra, "effets": effects, "maitrise": mastery}


# Rangs 3 et 5 des 6 sorts Impie existants (à la place des +5 % de critique partout).
RANKS = {
    "horloge": {"3": {"duree_horloge": 1}, "5": {"portee_max": 1}},
    "tic": {"3": {"par_tour": 3}, "5": {"effets": [{"type": "decalage_horaire", "heures": 1, "si_critique": True}]}},
    "tac": {"3": {"par_tour": 3}, "5": {"effets": [{"type": "decalage_horaire", "heures": -1, "si_critique": True}]}},
    "avance_rapide": {"3": {"critique": 10}, "5": {"cout_pa": 3}},
    "retour_en_arriere": {"3": {"critique": 10}, "5": {"cout_pa": 3}},
    "contretemps": {"3": {"delai": 1}, "5": {"cout_pa": 2}},
}
OLD = []
for sid, mastery in RANKS.items():
    with open(path("sorts", "chronomancien_" + sid), encoding="utf-8") as f:
        data = json.load(f)
    data["maitrise"] = mastery
    OLD.append(data)

IMPIE = [
    spell("arret_sur_image", "Arrêt sur image", "« On la refait au ralenti ? » La cible subit de nouveau l'effet de la dernière heure atteinte sur son horloge, sans bouger.",
          2, (1, 6), [{"type": "arret_sur_image", "cibles": "ennemis"}], {"3": {"cout_pa": 1}, "5": {"delai": 0}}, relance={"par_tour": 1, "delai": 1}),
    spell("rendez_vous", "Rendez-vous", "Il arrive toujours à l'heure du rendez-vous des autres : échange de place avec un combattant, allié ou ennemi.",
          2, (1, 5), [{"type": "permutation", "tous": True}], {"3": {"portee_max": 1}, "5": {"delai": 1}}, ligne_de_vue=False, relance={"par_tour": 1, "delai": 2}),
    spell("sursis", "Sursis", "Il rembobine un peu ses blessures : rend 50 % des PV perdus depuis le début de son tour précédent.",
          3, (0, 0), [{"type": "sursis", "pourcent": 50}], {"3": {"cout_pa": 2}, "5": {"delai": 2}}, relance={"par_tour": 1, "delai": 3}),
    spell("acceleration", "Accélération", "Tout va plus vite, sauf les files d'attente : +1 PM, +20 Agilité et +20 Perception pendant 2 tours.",
          2, (0, 3), [change("pm", 1, 2, cibles="allies"), change("agilite", 20, 2, cibles="allies"), change("perception", 20, 2, cibles="allies")],
          {"3": {"portee_max": 1}, "5": {"delai": 2}}, relance={"par_tour": 1, "delai": 3}),
]
GIVRE = [
    spell("pulsion_temporelle", "Pulsion temporelle", "Une pulsion de temps gelé qui attend son heure : elle explose au début du 2e tour de la cible (3 au plus, ne peut pas être retirée).",
          3, (1, 6), [{"type": "pulsion", "element": "givre", "min": 12, "max": 16, "delai": 2, "cibles": "ennemis"}],
          {"3": {"critique": 10}, "5": {"cout_pa": 2}}, relance={"par_tour": 2}),
    spell("seconde_glacee", "Seconde glacée", "Une seconde de froid absolu, pas une de plus (le reste est facturé).", 2, (1, 6), [dmg("givre", 4, 6)],
          {"3": {"critique": 10}, "5": {"portee_max": 1}}, relance={"par_tour": 3}),
    spell("hiver_eternel", "Hiver éternel", "Un hiver qui ne finit jamais, sur la cible et ses voisins.", 4, (2, 6), [dmg("givre", 6, 8, cibles="ennemis")],
          {"3": {"cout_pa": 3}, "5": {"effets": [change("pm", 1, 1, "malus", cibles="ennemis")]}}, zone={"type": "cercle", "taille": 1}, relance={"par_tour": 1}),
    spell("fin_des_temps", "Fin des temps", "La fin des temps, en avant-première, pour un seul spectateur.", 5, (1, 4), [dmg("givre", 18, 24)],
          {"3": {"portee_max": 1}, "5": {"cout_pa": 4}}, relance={"par_tour": 1}),
    spell("echo_du_passe", "Écho du passé", "Le passé revient toujours : 3 à 4 Givre par manipulation temporelle déjà subie par la cible (6 au plus).",
          3, (1, 6), [dmg("givre", 3, 4, par_manipulation=6)], {"3": {"critique": 10}, "5": {"cout_pa": 2}}, relance={"par_tour": 1}),
    spell("deja_vu", "Déjà-vu", "« J'ai l'impression d'être déjà passé par là. » Ramène la cible à sa case d'il y a 1 tour et lui retire 1 PM.",
          3, (1, 6), [{"type": "retour", "tours": 1, "cibles": "ennemis"}, change("pm", 1, 1, "malus", cibles="ennemis")],
          {"3": {"delai": 1}, "5": {"effets": [change("pa", 1, 1, "malus", cibles="ennemis")]}}, relance={"par_tour": 1, "delai": 2}),
    spell("saut_dans_le_futur", "Saut dans le futur", "Envoie un ennemi 2 tours dans le futur : ses effets en cours s'écoulent d'un coup (bonus et malus finis, poisons et pulsions infligés), mais ses sorts reviennent plus tôt. Un boss n'écoule que ses poisons et ses pulsions.",
          3, (1, 5), [{"type": "futur", "tours": 2, "cibles": "ennemis"}], {"3": {"portee_max": 1}, "5": {"delai": 2}}, relance={"par_tour": 1, "delai": 3}),
    spell("point_de_depart", "Point de départ", "Il revient à sa case du début de ce tour, comme s'il n'était jamais parti (il l'était).",
          1, (0, 0), [{"type": "retour", "tours": 1}], {"3": {"delai": 1}, "5": {"effets": [change("pm", 1, 1)]}}, relance={"par_tour": 1, "delai": 2}),
    spell("cristal_du_temps", "Cristal du temps", "Figé dans un cristal de temps : bouclier de Givre, et inamovible jusqu'à son prochain tour (ni poussé, ni attiré, ni échangé).",
          2, (0, 0), [{"type": "bouclier", "element": "givre", "min": 12, "max": 16}, {"type": "etat", "etat": "inamovible", "duree": 1}],
          {"3": {"cout_pa": 1}, "5": {"effets": [change("resistance", 10, 1, element="givre")]}}, relance={"par_tour": 1, "delai": 2}),
    spell("heure_d_avance", "Heure d'avance", "Une heure d'avance sur tout le monde : lui ou un allié avance de 1 tour (relances −1, malus et poisons écoulés de 1 tour).",
          2, (0, 4), [{"type": "futur", "tours": 1, "cibles": "allies"}], {"3": {"portee_max": 1}, "5": {"delai": 2}}, relance={"par_tour": 1, "delai": 3}),
]
NEW = IMPIE + GIVRE
VOIE = {
    "id": "chronomancien", "nom": "Chronomancien",
    "description": "Dérègle le temps avec des pouvoirs impies. Toujours en avance, ou en retard, mais jamais à l'heure.",
    "caracteristiques": {"pv": 50, "pa": 6, "pm": 3, "initiative": 100},
    "sorts": [s["id"] for s in OLD[:6] + IMPIE + GIVRE],
    "passif": {"id": "chronomancien_temps_vole", "nom": "Temps volé", "effet": "temps_vole",
               "description": "Débloqué au palier Apprenti. Chaque manipulation temporelle infligée à un ennemi (heure atteinte, pulsion posée, retour, envoi dans le futur) lui vole une seconde (5 au plus, jusqu'à la fin de son prochain tour) : +2 % de dommages par seconde (+1 % par rang). Rang 3 : à 5 secondes, il les dépense pour +1 PA au début de son prochain tour (une fois par tour). Rang 5 : 7 secondes au plus."},
}

# Icônes : Impie violet à liseré mauve, Givre bleu glacier à liseré blanc.
FRAMES = {"i": ("#8a5ab0", "#1e0f2c", "#e0c8f0"), "g": ("#7ac8e8", "#0e2a3a", "#f0faff")}
DIAL = '<circle cx="22" cy="22" r="13" fill="{c}" stroke="#1a1020" stroke-width="1.6"/>'
HOURGLASS = '<path d="M13 7 H31 L22 22 L31 37 H13 L22 22 Z" fill="{c}" stroke="#0e2a3a" stroke-width="1.6" stroke-linejoin="round"/>'
DRAWINGS = {
    "arret_sur_image": ("i", DIAL.format(c="#d8c4ea") + '<rect x="16" y="15" width="4" height="14" fill="#3a1f52"/><rect x="24" y="15" width="4" height="14" fill="#3a1f52"/>'),
    "rendez_vous": ("i", '<path d="M8 16 H32 L27 11 M36 28 H12 L17 33" stroke="#e0c8f0" stroke-width="2.6" fill="none" stroke-linecap="round"/>'),
    "sursis": ("i", DIAL.format(c="#d8c4ea") + '<path d="M22 22 V13 M22 22 L16 26" stroke="#3a1f52" stroke-width="2.2"/><path d="M8 12 A16 16 0 0 1 20 6 L18 2" stroke="#ff8fb0" stroke-width="2" fill="none"/>'),
    "acceleration": ("i", '<path d="M8 12 L20 22 L8 32 Z M20 12 L32 22 L20 32 Z" fill="#e0c8f0" stroke="#1a1020" stroke-width="1.4"/>'),
    "pulsion_temporelle": ("g", HOURGLASS.format(c="#bfe4f4") + '<circle cx="22" cy="22" r="4" fill="#ffffff"/>'),
    "seconde_glacee": ("g", '<path d="M22 6 V38 M8 14 L36 30 M8 30 L36 14" stroke="#f0faff" stroke-width="2.6" stroke-linecap="round"/><circle cx="22" cy="22" r="4" fill="#7ac8e8" stroke="#f0faff"/>'),
    "hiver_eternel": ("g", '<circle cx="22" cy="22" r="14" fill="none" stroke="#f0faff" stroke-width="2" stroke-dasharray="4 3"/><path d="M22 12 V32 M13 17 L31 27 M13 27 L31 17" stroke="#f0faff" stroke-width="2"/>'),
    "fin_des_temps": ("g", HOURGLASS.format(c="#bfe4f4") + '<path d="M10 38 L34 6" stroke="#ff6a4a" stroke-width="2.6"/>'),
    "echo_du_passe": ("g", ''.join(f'<circle cx="{x}" cy="22" r="{r}" fill="none" stroke="#f0faff" stroke-width="2" opacity="{o}"/>' for x, r, o in [(16, 8, 1), (22, 10, 0.7), (28, 12, 0.4)])),
    "deja_vu": ("g", '<circle cx="15" cy="20" r="6" fill="#f0faff" opacity="0.45"/><circle cx="27" cy="22" r="6" fill="#f0faff"/><path d="M30 34 Q18 40 10 30" stroke="#f0faff" stroke-width="2" fill="none"/>'),
    "saut_dans_le_futur": ("g", HOURGLASS.format(c="#bfe4f4") + '<path d="M30 14 L38 22 L30 30" stroke="#f0faff" stroke-width="2.6" fill="none"/>'),
    "point_de_depart": ("g", '<path d="M12 36 V8 L30 13 L12 19" stroke="#f0faff" stroke-width="2.4" fill="#7ac8e8" stroke-linejoin="round"/><path d="M34 34 Q24 26 18 32" stroke="#f0faff" stroke-width="2" fill="none"/>'),
    "cristal_du_temps": ("g", '<path d="M22 5 L34 16 L22 39 L10 16 Z" fill="#bfe4f4" stroke="#f0faff" stroke-width="2"/><path d="M22 14 V24 L27 27" stroke="#0e2a3a" stroke-width="1.8" fill="none"/>'),
    "heure_d_avance": ("g", DIAL.format(c="#bfe4f4") + '<path d="M22 22 V12 M22 22 L29 25" stroke="#0e2a3a" stroke-width="2.2"/><path d="M33 9 L38 6 L37 12" stroke="#f0faff" stroke-width="2" fill="none"/>'),
    "temps_vole": ("i", HOURGLASS.format(c="#d8c4ea").replace("#0e2a3a", "#1a1020") + '<path d="M28 30 Q36 30 36 22" stroke="#ffe27a" stroke-width="2.2" fill="none"/><circle cx="36" cy="20" r="2.4" fill="#ffe27a"/>'),
}


def write(folder, data):
    with open(path(folder, data["id"]), "w", encoding="utf-8") as f:
        f.write(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


for data in OLD + NEW:
    write("sorts", data)
write("voies", VOIE)
images = {f"sort_chronomancien_{sid}": {"fichier": f"sorts/chronomancien_{sid}.svgt", "ancre": [22, 22]} for sid in RANKS}
for name, (kind, body) in DRAWINGS.items():
    light, dark, edge = FRAMES[kind]
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="44" height="44" viewBox="0 0 44 44">\n'
           f'<defs><radialGradient id="f" cx="0.35" cy="0.3" r="0.9"><stop offset="0" stop-color="{light}"/><stop offset="1" stop-color="{dark}"/></radialGradient></defs>\n'
           f'<rect x="1.5" y="1.5" width="41" height="41" rx="7" fill="url(#f)" stroke="{edge}" stroke-width="2"/>\n{body}\n</svg>\n')
    with open(os.path.join(GAME, "art", "sorts", f"chronomancien_{name}.svgt"), "w") as f:
        f.write(svg)
    images[f"sort_chronomancien_{name}"] = {"fichier": f"sorts/chronomancien_{name}.svgt", "ancre": [22, 22]}
with open(os.path.join(GAME, "art", "manifestes", "chronomancien.json"), "w", encoding="utf-8") as f:
    f.write(json.dumps({"images": images}, ensure_ascii=False, indent=2) + "\n")
