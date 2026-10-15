"""Production du lot Métiers (chantier 3) : ressources de récolte, recettes et nœuds sur les cartes.

    python3 src/metiers_production.py      (depuis docs/design/chantier3_brouillon)

Ajoute les 6 nouvelles ressources aux métiers (bûcheron, mineur), les recettes au forgeron, les
images des nœuds au fragment de manifeste `metiers`, puis pose sur chaque carte les nœuds que la
conception lui donne (if, hêtre, malorme, étain, argent, obsidienne). Un nœud de bois remplace un
arbre, un nœud de minerai un rocher, déjà présents et à portée de récolte : aucun chemin n'est
coupé, aucune case du calque de placement n'est touchée. Relancer le script ne double rien.
"""
import json
import os
import random

from cartes import JEU, LIGNES, COLONNES, PRATICABLE, cellule, plan_de, verifier

ICI = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(ICI, "..", "chantier3_contenu.json"), encoding="utf-8") as f:
    D = json.load(f)
CHAMPS = ("marqueur", "nom", "objet", "niveau", "quantite", "xp", "repousse", "apparence", "couleur")


def lire(chemin):
    with open(chemin, encoding="utf-8") as f:
        return json.load(f)


def ecrire(chemin, donnees):
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(donnees, f, ensure_ascii=False, indent=2)
        f.write("\n")


def metiers():
    nouveaux = {r["marqueur"] for r in D["recolte"]}
    for metier_id in ("bucheron", "mineur"):
        chemin = os.path.join(JEU, "data", "metiers", metier_id + ".json")
        m = lire(chemin)
        m["ressources"] = [r for r in m["ressources"] if r["marqueur"] not in nouveaux]
        m["ressources"] += [{k: r[k] for k in CHAMPS} for r in D["recolte"] if r["metier"] == metier_id]
        ecrire(chemin, m)
    chemin = os.path.join(JEU, "data", "metiers", "forgeron.json")
    f = lire(chemin)
    deja = {r["objet"] for r in D["recettes"]}
    f["recettes"] = [r for r in f["recettes"] if r["objet"] not in deja] + D["recettes"]
    ecrire(chemin, f)
    chemin = os.path.join(JEU, "art", "manifestes", "metiers.json")
    frag = lire(chemin)
    frag.setdefault("images", {}).update({r["image"]: r["image_manifeste"] for r in D["recolte"]})
    frag["ressources"] = {r["marqueur"]: r["image"] for r in D["recolte"]}
    ecrire(chemin, frag)


def relie(g):
    """Vrai si toutes les cases praticables sont accessibles depuis le départ."""
    texte = ["".join(l) for l in g]
    praticables = {cellule(i, j) for i, l in enumerate(texte) for j, c in enumerate(l)
                   if c in PRATICABLE and not (i % 2 == 1 and j == 0)}
    depart = next(cellule(i, j) for i, l in enumerate(texte) for j, c in enumerate(l) if c == "@")
    vus, pile = {depart}, [depart]
    while pile:
        x, y = pile.pop()
        for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if n in praticables and n not in vus:
                vus.add(n)
                pile.append(n)
    return vus == praticables


def poser_noeuds():
    bois = {r["marqueur"] for r in D["recolte"] if r["apparence"] == "arbre"}
    voulus = {}
    for c in D["cartes"]:
        nouveaux = {k: v for k, v in c.get("ressources", {}).items() if k in {r["marqueur"] for r in D["recolte"]}}
        if nouveaux:
            voulus[c["id"]] = nouveaux
    manque = []
    for carte_id, ressources in sorted(voulus.items()):
        chemin = os.path.join(JEU, "data", "cartes", carte_id + ".json")
        carte = lire(chemin)
        g = [list(l) for l in carte["plan"]]
        reserve = {(i, j) for i, l in enumerate(carte.get("placement", [])) for j, c in enumerate(l) if c in "jm"}
        rng = random.Random(carte_id)
        for marqueur, voulu in sorted(ressources.items()):
            deja = sum(l.count(marqueur) for l in g)
            support = "A" if marqueur in bois else "R"

            def accessible(i, j):
                x, y = cellule(i, j)
                for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    pi, pj = plan_de(*n)
                    if 0 <= pi < LIGNES and 0 <= pj < COLONNES and g[pi][pj] in ".:@":
                        return True
                return False

            candidats = [(i, j) for i in range(1, LIGNES - 1) for j in range(1, COLONNES - 1)
                         if g[i][j] == support and accessible(i, j) and (i, j) not in reserve]
            rng.shuffle(candidats)
            for i, j in candidats[:max(0, voulu - deja)]:
                g[i][j] = marqueur
            # Repli : une case libre, gardée seulement si tout reste accessible depuis le départ.
            libres = [(i, j) for i in range(4, LIGNES - 4) for j in range(2, COLONNES - 2)
                      if g[i][j] == "." and (i, j) not in reserve]
            rng.shuffle(libres)
            for i, j in libres:
                if sum(l.count(marqueur) for l in g) >= voulu:
                    break
                g[i][j] = marqueur
                if not relie(g):
                    g[i][j] = "."
            pose = sum(l.count(marqueur) for l in g)
            if pose < voulu:
                manque.append(f"{carte_id} : {marqueur} {pose}/{voulu}")
        carte["plan"] = ["".join(l) for l in g]
        verifier(carte_id, carte["plan"])
        ecrire(chemin, carte)
    print(f"nœuds posés sur {len(voulus)} cartes" + (" ; manquants : " + ", ".join(manque) if manque else ""))


if __name__ == "__main__":
    metiers()
    poser_noeuds()
