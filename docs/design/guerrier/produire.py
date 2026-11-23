"""Guerrier (GDD § 4.3) : Voie complète (10 sorts Acier + 10 Impie, passif Rancune), icônes (SVG 44 × 44) et fragment
de manifeste `art/manifestes/guerrier.json`. Les 7 sorts Acier d'origine restent dans leurs JSON (Fendoir y gagne la
dépense de Rancune, Cri de guerre et Fendoir perdent la mention « Sort de rang II »).

    python3 docs/design/guerrier/produire.py      # depuis la racine du dépôt
"""
import json
import os

GAME = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "game")


def dmg(element, low, high, **extra):
    return {"type": "degats", "element": element, "min": low, "max": high, "cibles": extra.pop("cibles", "ennemis"), **extra}


def spell(sid, name, text, pa, rng, effects, mastery, **extra):
    return {"id": "guerrier_" + sid, "nom": name, "description": text, "cout_pa": pa, "portee": {"min": rng[0], "max": rng[1]},
            **extra, "effets": effects, "maitrise": mastery}


def malus(carac, value, turns, **extra):
    return {"type": "malus", "carac": carac, "min": value, "max": value, "duree": turns, "cibles": "ennemis", **extra}


PM = {"type": "retrait_pm", "min": 1, "max": 1, "cibles": "ennemis"}
ACIER = [
    spell("croc_en_jambe", "Croc-en-jambe", "Un pied qui traîne, comme par hasard. L'ennemi perd 2 PM à son prochain tour.", 2, (1, 1),
          [dmg("acier", 3, 5), dict(PM, min=2, max=2)], {"3": {"effets": [PM]}, "5": {"delai": 1}}, relance={"par_tour": 1, "delai": 2}),
    spell("crochet", "Crochet", "Un crochet au bout d'une chaîne : l'ennemi vient au contact, qu'il le veuille ou non.", 3, (2, 4),
          [{"type": "attirance", "min": 3, "max": 3, "cibles": "ennemis"}], {"3": {"portee_max": 1}, "5": {"effets": [dmg("acier", 4, 6)]}},
          lancer_en_ligne=True, relance={"par_tour": 1, "delai": 2}),
    spell("recul_strategique", "Recul stratégique", "Ce n'est pas une fuite, c'est un repositionnement héroïque. Saute sur une case libre sans être taclé.",
          2, (1, 3), [{"type": "teleportation"}], {"3": {"portee_max": 1}, "5": {"delai": 2}}, ligne_de_vue=False, relance={"par_tour": 1, "delai": 3}),
]
IMPIE = [
    spell("serment_de_sang", "Serment de sang", "Il signe de son sang un contrat qu'il n'a pas lu : 15 % de ses PV max contre 2 PA ce tour.", 1, (0, 0),
          [{"type": "gain_pa", "min": 2, "max": 2}], {"3": {"cout_pv": 12}, "5": {"delai": 1}}, cout_pv=15, ligne_de_vue=False,
          relance={"par_tour": 1, "delai": 2}),
    spell("lame_impie", "Lame impie", "Une lame maudite qui boit pour deux. Vole 30 % des PV qu'elle ôte.", 3, (1, 1),
          [dmg("impie", 7, 11, vol=30)], {"3": {"valeurs": {"vol": 40}}, "5": {"critique": 5}}, cout_pv=3, relance={"par_tour": 2}),
    spell("onde_funebre", "Onde funèbre", "Une onde de malheur autour de la cible. Les alliés aussi : c'est un chevalier maudit, pas un chevalier servant.",
          4, (2, 4), [dmg("impie", 6, 9, cibles="tous")], {"3": {"portee_max": 1}, "5": {"cout_pa": 3}}, cout_pv=5,
          zone={"type": "cercle", "taille": 1}, relance={"par_tour": 1}),
    spell("execution", "Exécution", "La sentence tombe, sans appel : +30 % de dégâts contre une cible sous 30 % de ses PV.", 5, (1, 1),
          [dmg("impie", 15, 21, execution=30)], {"3": {"critique": 5}, "5": {"cout_pa": 4}}, cout_pv=8, relance={"par_tour": 1}),
    spell("rage_du_damne", "Rage du damné", "Plus il saigne, plus il frappe : +1 % par % de PV manquant (60 % au plus), et dépense sa Rancune (+6 % par cran).",
          4, (1, 1), [dmg("impie", 10, 14, par_pv_manquant=60, par_rancune=6)], {"3": {"valeurs": {"par_pv_manquant": 70}}, "5": {"cout_pa": 3}},
          relance={"par_tour": 1}),
    spell("regard_du_damne", "Regard du damné", "Un regard qui glace le sang (le sien est déjà froid) : −2 PA à la cible pendant son prochain tour.", 2, (1, 4),
          [malus("pa", 2, 1)], {"3": {"valeurs": {"min": 3, "max": 3}}, "5": {"delai": 1}}, cout_pv=3, relance={"par_tour": 1, "delai": 2}),
    spell("etreinte_de_la_tombe", "Étreinte de la tombe", "Des mains d'outre-tombe l'attirent d'une case, lui retirent 3 PM et lui volent des PV.", 3, (1, 2),
          [{"type": "attirance", "min": 1, "max": 1, "cibles": "ennemis"}, dict(PM, min=3, max=3), dmg("impie", 4, 6, vol=True)],
          {"3": {"delai": 2}, "5": {"effets": [PM]}}, cout_pv=5, relance={"par_tour": 1, "delai": 3}),
    spell("pas_du_spectre", "Pas du spectre", "Il traverse un bout de l'au-delà et ressort plus loin, sans ligne de vue ni tacle.", 2, (1, 4),
          [{"type": "teleportation"}], {"3": {"portee_max": 1}, "5": {"cout_pv": 0}}, cout_pv=5, ligne_de_vue=False, relance={"par_tour": 1, "delai": 2}),
    spell("armure_de_sang", "Armure de sang", "Le sang versé fait une armure : un bouclier d'au moins deux fois les PV payés ce tour.", 2, (0, 0),
          [{"type": "bouclier", "element": "impie", "min": 8, "max": 8, "par_pv_payes": 200}], {"3": {"valeurs": {"par_pv_payes": 250}}, "5": {"delai": 2}},
          ligne_de_vue=False, relance={"par_tour": 1, "delai": 3}),
    spell("malediction", "Malédiction", "Une malédiction de famille, transmissible : la cible perd 15 % de résistance Acier et Impie pendant 2 tours.", 3, (1, 5),
          [malus("resistance", 15, 2, element="acier"), malus("resistance", 15, 2, element="impie")],
          {"3": {"valeurs": {"min": 20, "max": 20}}, "5": {"valeurs": {"duree": 3}}}, cout_pv=5, relance={"par_tour": 1, "delai": 3}),
]
ORIGINAL = ["guerrier_frappe", "guerrier_hache", "guerrier_tourbillon", "guerrier_second_souffle", "guerrier_charge", "guerrier_cri_de_guerre", "guerrier_fendoir"]
VOIE = {
    "id": "guerrier", "nom": "Guerrier",
    "description": "Au contact, il encaisse et rend les coups. Réfléchit après, de préférence. Voie Impie : chevalier d'un ordre dissous pour faute grave, il paie chaque coup de son propre sang, puis se rembourse sur l'adversaire.",
    "caracteristiques": {"pv": 50, "pa": 6, "pm": 3, "initiative": 100},
    "sorts": ORIGINAL + [s["id"] for s in ACIER + IMPIE],
    "passif": {"id": "guerrier_rancune", "nom": "Rancune", "effet": "rancune",
               "description": "Débloqué au palier Apprenti. Chaque tranche de 5 PV perdus (coups reçus ou PV payés) donne un cran de Rancune, gardé tout le combat : +3 % de dégâts par cran. 5 crans au plus (6 au rang 2, 8 au rang 3, 9 au rang 4, 10 au rang 5). Rang 3 : les dégâts absorbés par un bouclier comptent aussi. Rang 5 : au 10e cran, son prochain coup de mêlée est critique. Fendoir et Rage du damné dépensent les crans."},
}

# Icônes : Acier brun cuir comme les sorts d'origine, Impie violet à liseré pourpre.
FRAMES = {"a": ("#c08a4a", "#5e3a1c", "#2a1c10"), "i": ("#8a4ab0", "#2a0e3a", "#d8a0ff")}
BLADE = '<path d="M10 33 L28 15" stroke="#1a0a20" stroke-width="5.6" stroke-linecap="round"/><path d="M10 33 L28 15" stroke="{c}" stroke-width="3.4" stroke-linecap="round"/>'
DROP = '<path d="M{x} {y} q4 6 0 9 q-4 -3 0 -9 z" fill="#c0203a" stroke="#1a0a20" stroke-width="0.8"/>'
DRAWINGS = {
    "croc_en_jambe": ("a", '<path d="M8 30 H22 L26 24" stroke="#fff4dc" stroke-width="3" fill="none" stroke-linecap="round"/><circle cx="31" cy="16" r="4" fill="#fff4dc"/><path d="M30 20 L34 32" stroke="#fff4dc" stroke-width="2.4"/>'),
    "crochet": ("a", '<path d="M8 22 H24" stroke="#d9b45a" stroke-width="2" stroke-dasharray="3 2"/><path d="M26 14 Q36 14 36 22 Q36 30 28 30" stroke="#fff4dc" stroke-width="3" fill="none" stroke-linecap="round"/>'),
    "recul_strategique": ("a", '<path d="M34 30 Q22 6 10 26" stroke="#fff4dc" stroke-width="2.6" fill="none" stroke-dasharray="4 3"/><path d="M10 26 L8 19 M10 26 L16 23" stroke="#fff4dc" stroke-width="2.6" stroke-linecap="round"/>'),
    "serment_de_sang": ("i", '<rect x="11" y="9" width="18" height="24" rx="2" fill="#efe3c8" stroke="#1a0a20" stroke-width="1.2"/><path d="M14 15 H26 M14 19 H26 M14 23 H22" stroke="#8a7a60" stroke-width="1.2"/>' + DROP.format(x=28, y=24)),
    "lame_impie": ("i", BLADE.format(c="#d8a0ff") + DROP.format(x=12, y=26)),
    "onde_funebre": ("i", '<circle cx="22" cy="22" r="5" fill="#d8a0ff"/><circle cx="22" cy="22" r="10" fill="none" stroke="#d8a0ff" stroke-width="2" opacity="0.8"/><circle cx="22" cy="22" r="15" fill="none" stroke="#d8a0ff" stroke-width="1.6" opacity="0.5"/>'),
    "execution": ("i", '<path d="M14 8 H30 L28 20 H16 Z" fill="#b0b0c0" stroke="#1a0a20" stroke-width="1.4"/><rect x="21" y="20" width="3" height="16" fill="#5a3a20"/><path d="M8 36 H36" stroke="#c0203a" stroke-width="2.4"/>'),
    "rage_du_damne": ("i", '<path d="M8 34 L14 14 L20 26 L24 8 L30 26 L36 16 L34 34 Z" fill="#c0203a" stroke="#1a0a20" stroke-width="1.2"/><path d="M14 30 L22 22 L30 30" stroke="#ffd0e0" stroke-width="2" fill="none"/>'),
    "regard_du_damne": ("i", '<path d="M6 22 Q22 8 38 22 Q22 36 6 22 Z" fill="#efe3c8" stroke="#1a0a20" stroke-width="1.4"/><circle cx="22" cy="22" r="6" fill="#c0203a"/><circle cx="22" cy="22" r="2.4" fill="#1a0a20"/>'),
    "etreinte_de_la_tombe": ("i", '<rect x="6" y="30" width="32" height="8" fill="#4a3a2a"/>' + "".join(f'<path d="M{x} 31 V18 M{x - 3} 21 V15 M{x + 3} 21 V15" stroke="#c8d8b0" stroke-width="2.2" stroke-linecap="round"/>' for x in (14, 30))),
    "pas_du_spectre": ("i", '<path d="M14 34 Q10 20 16 12 Q22 6 28 12 Q34 20 30 34 L26 30 L22 34 L18 30 Z" fill="#d8c8f0" opacity="0.85" stroke="#1a0a20" stroke-width="1.2"/><circle cx="19" cy="18" r="2" fill="#1a0a20"/><circle cx="25" cy="18" r="2" fill="#1a0a20"/>'),
    "armure_de_sang": ("i", '<path d="M22 6 L35 11 Q35 27 22 38 Q9 27 9 11 Z" fill="#8a1028" stroke="#d8a0ff" stroke-width="2"/>' + DROP.format(x=22, y=14)),
    "malediction": ("i", '<path d="M22 8 L26 18 L36 18 L28 25 L31 35 L22 29 L13 35 L16 25 L8 18 L18 18 Z" fill="none" stroke="#d8a0ff" stroke-width="2.2" stroke-linejoin="round"/><circle cx="22" cy="22" r="3" fill="#c0203a"/>'),
    "rancune": ("i", '<path d="M10 34 Q8 18 22 10 Q36 18 34 34 Z" fill="#5a1020" stroke="#d8a0ff" stroke-width="1.6"/><path d="M15 22 L20 25 M29 22 L24 25" stroke="#ffb02e" stroke-width="2.4" stroke-linecap="round"/><path d="M16 31 Q22 27 28 31" stroke="#ffb02e" stroke-width="2" fill="none"/>'),
}


def path(folder, name):
    return os.path.join(GAME, "data", folder, name + ".json")


def write(folder, data):
    with open(path(folder, data["id"]), "w", encoding="utf-8") as f:
        f.write(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


for data in ACIER + IMPIE:
    write("sorts", data)
for sid in ["guerrier_fendoir", "guerrier_cri_de_guerre"]:
    with open(path("sorts", sid), encoding="utf-8") as f:
        data = json.load(f)
    data["description"] = data["description"].replace(" Sort de rang II.", "")
    if sid == "guerrier_fendoir":
        data["description"] = "Le grand coup qu'on garde pour la fin, avec toute sa rancune : +6 % de dégâts par cran de Rancune, qui sont dépensés."
        data["effets"][0]["par_rancune"] = 6
    write("sorts", data)
write("voies", VOIE)
images = {}
for name, (kind, body) in DRAWINGS.items():
    light, dark, edge = FRAMES[kind]
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="44" height="44" viewBox="0 0 44 44">\n'
           f'<defs><radialGradient id="f" cx="0.35" cy="0.3" r="0.9"><stop offset="0" stop-color="{light}"/><stop offset="1" stop-color="{dark}"/></radialGradient></defs>\n'
           f'<rect x="1.5" y="1.5" width="41" height="41" rx="7" fill="url(#f)" stroke="{edge}" stroke-width="2"/>\n{body}\n</svg>\n')
    with open(os.path.join(GAME, "art", "sorts", f"guerrier_{name}.svgt"), "w") as f:
        f.write(svg)
    images[f"sort_guerrier_{name}"] = {"fichier": f"sorts/guerrier_{name}.svgt", "ancre": [22, 22]}
with open(os.path.join(GAME, "art", "manifestes", "guerrier.json"), "w", encoding="utf-8") as f:
    f.write(json.dumps({"images": images}, ensure_ascii=False, indent=2) + "\n")
