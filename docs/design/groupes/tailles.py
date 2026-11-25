"""Tailles des groupes (demande de l'auteur du 25/11/2026) : chaque carte à monstres, hors donjons, a un petit
groupe (1 à 2 monstres), un moyen (3 à 4) et un grand (5 à 6). Les autres règles d'apparition ne changent pas.
Groupes ordinaires seulement : ni mini-boss, ni groupe rare (« reapparition » propre), ni variante « apres_boss ».
Le plus grand groupe devient le grand, le suivant le moyen, le plus petit le petit (un groupe fixe déjà à la bonne
taille reste tel quel, sinon il tire sa taille parmi ses propres monstres) ; s'il en manque, un groupe des espèces
ordinaires de la carte est posé sur la case libre la plus éloignée des autres. Les autres groupes ne changent pas.
Usage, depuis la racine du dépôt, après tout script qui produit des cartes : python3 docs/design/groupes/tailles.py"""
import glob, os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "sous_zones"))
from produire_sous_zone import lire, ecrire, verifier  # noqa: E402
from cartes import ecran, JEU  # noqa: E402

TAILLES = [[5, 6], [3, 4], [1, 2]]  # grand, moyen, petit
BOSS = {m["id"] for m in map(lire, [os.path.relpath(f, JEU) for f in glob.glob(os.path.join(JEU, "data/monstres/*.json"))]) if m.get("boss")}


def especes(g):
    return g.get("monstres") or g["parmi"]


def taille(g):
    return g["nombre"][1] if "parmi" in g else len(g["monstres"])


def ordinaire(g):
    return not ({"reapparition", "apres_boss", "reapparition_au_combat"} & g.keys()) and not BOSS & set(especes(g))


def ajuster(g, nombre):
    if "monstres" in g and nombre[0] <= len(g["monstres"]) <= nombre[1]:
        return
    g["parmi"], g["nombre"] = especes(g), nombre
    g.pop("monstres", None)


def poser(plan, chiffre):
    """Case libre la plus éloignée des groupes, de l'arrivée et des PNJ (hors bords de carte)."""
    g = [list(l) for l in plan]
    pris = [ecran(i, j) for i, l in enumerate(g) for j, ch in enumerate(l) if ch.isdigit() or ch.isalpha() and ch.islower() or ch == "@"]
    libres = [(i, j) for i, l in enumerate(g) for j, ch in enumerate(l) if ch == "." and 2 < i < len(g) - 3 and 1 < j < len(l) - 2]
    i, j = max(libres, key=lambda c: min((ecran(*c)[0] - x) ** 2 + (ecran(*c)[1] - y) ** 2 for x, y in pris))
    g[i][j] = chiffre
    return ["".join(l) for l in g]


for chemin in sorted(glob.glob(os.path.join(JEU, "data/cartes/*.json"))):
    carte = lire(os.path.relpath(chemin, JEU))
    if carte.get("donjon") or carte.get("etage_suivant") or carte["id"].startswith(("tour_celeste", "grange_")):
        continue
    groupes = [g for g in carte.get("groupes", []) if ordinaire(g)]
    if not groupes:
        continue
    avant = repr(carte)
    triés = sorted(groupes, key=taille, reverse=True)
    roles = TAILLES[-len(triés):] if len(triés) < 3 else TAILLES
    for g, nombre in zip(triés, roles):
        ajuster(g, nombre)
    pool = [m for g in groupes for m in especes(g)]
    for nombre in TAILLES[:3 - len(triés)] if len(triés) < 3 else []:
        carte["groupes"].append({"parmi": pool, "nombre": nombre})
        carte["plan"] = poser(carte["plan"], str(len(carte["groupes"])))
    if repr(carte) != avant:
        verifier(carte["id"], carte["plan"])
        ecrire(os.path.relpath(chemin, JEU), carte)
        print(carte["id"], [g.get("nombre", len(g.get("monstres", []))) for g in carte["groupes"]])
