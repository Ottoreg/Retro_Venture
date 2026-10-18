#!/usr/bin/env python3
"""Catalogue de tous les objets et sorts du jeu, tiré des JSON de game/data/.

Écrit docs/CATALOGUE.md (à relancer après chaque changement de contenu) :

    python3 game/tools/catalogue.py

Rien n'est à corriger à la main dans le catalogue : il est entièrement regénéré.
"""
import glob
import json
import os

RACINE = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA = os.path.join(RACINE, "game", "data")
SORTIE = os.path.join(RACINE, "docs", "CATALOGUE.md")

# Repris de core/items/item.gd et core/character/character.gd.
STATS = {
    "vitalite": "Vitalité", "sagesse": "Sagesse", "force": "Force", "intelligence": "Intelligence",
    "chance": "Chance", "agilite": "Agilité", "prospection": "Prospection", "initiative": "Initiative",
    "portee": "Portée", "pa": "PA", "pm": "PM", "dommages": "Dommages", "critique": "% Critique",
    "resistance": "Résistance",
}
ELEMENTS = {"acier": "Acier", "flamme": "Flamme", "givre": "Givre", "tempete": "Tempête",
            "sacre": "Sacré", "impie": "Impie"}
RARETES = {"commun": "Commun", "peu_commun": "Peu commun", "rare": "Rare", "epique": "Épique",
           "legendaire": "Légendaire", "relique": "Relique"}
PRIX_EQUIPEMENT = {"commun": 40, "peu_commun": 120, "rare": 350, "epique": 900,
                   "legendaire": 2500, "relique": 6000}
PRIX_RESSOURCE = {"commun": 4, "peu_commun": 12, "rare": 35, "epique": 90, "legendaire": 250,
                  "relique": 600}
TYPES = [("arme", "Armes"), ("coiffe", "Coiffes"), ("cape", "Capes"), ("amulette", "Amulettes"),
         ("anneau", "Anneaux"), ("ceinture", "Ceintures"), ("bottes", "Bottes"),
         ("ressource", "Ressources"), ("quete", "Objets de quête")]
CIBLES = {"ennemis": " aux ennemis", "allies": " aux alliés"}
BUTIN_MAX = 5  # monstres listés par objet (les plus généreux d'abord)


def charger(dossier):
    donnees = {}
    for chemin in sorted(glob.glob(os.path.join(DATA, dossier, "*.json"))):
        with open(chemin, encoding="utf-8") as fichier:
            d = json.load(fichier)
        donnees[d["id"]] = d
    return donnees


def cellule(texte):
    return str(texte).replace("|", "\\|").replace("\n", " ")


def plage(mini, maxi):
    return str(mini) if mini == maxi else "%s–%s" % (mini, maxi)


def element(e):
    return ELEMENTS.get(e.get("element", ""), e.get("element", ""))


def tours(e):
    return " (%d t.)" % e["duree"] if "duree" in e else ""


def effet(e):
    t = e["type"]
    valeur = plage(e.get("min"), e.get("max")) if "min" in e else ""
    cibles = CIBLES.get(e.get("cibles", ""), "")
    if t == "degats":
        texte = "%s %s" % (valeur, element(e))
    elif t == "soin":
        texte = "soin %s (%s)" % (valeur, element(e))
    elif t == "bouclier":
        texte = "bouclier %s (%s)" % (valeur, element(e))
    elif t == "poison":
        texte = "poison %s %s par tour%s" % (valeur, element(e), tours(e))
    elif t in ("bonus", "malus"):
        carac = STATS.get(e["carac"], e["carac"])
        if e["carac"] == "resistance":
            carac += " " + element(e)
        texte = "%s%s %s%s" % ("+" if t == "bonus" else "−", valeur, carac, tours(e))
    elif t == "poussee":
        texte = "poussée de %s case(s)" % valeur
    elif t == "attirance":
        texte = "attire de %s case(s)" % valeur
    elif t == "retrait_pm":
        texte = "−%s PM au prochain tour" % valeur
    elif t == "gain_pa":
        texte = "+%s PA tout de suite" % valeur
    elif t == "teleportation":
        texte = "téléportation sur la case"
    elif t == "glyphe":
        texte = "glyphe%s : [%s]" % (tours(e), effets(e["effets"]))
    elif t == "piege":
        zone_piege = " " + zone(e["zone"]) if "zone" in e else ""
        texte = "piège invisible%s : [%s]" % (zone_piege, effets(e["effets"]))
    else:
        texte = t
    return texte + cibles


def effets(liste):
    return " ; ".join(effet(e) for e in liste)


def zone(z):
    if z.get("type") == "cercle":
        return "cercle de rayon %d" % z.get("taille", 1)
    if z.get("type") == "croix_latine":
        return "croix latine"
    return ""


def caracteristiques_sort(s):
    """Coût, portée et règles de lancer, sur une ligne."""
    portee = s["portee"]
    morceaux = ["%d PA" % s["cout_pa"],
                "portée %s" % ("soi" if portee["max"] == 0 else plage(portee["min"], portee["max"]))]
    if "zone" in s and zone(s["zone"]):
        morceaux.append(zone(s["zone"]) + (" (sans le lanceur)" if s.get("lanceur_exclu") else ""))
    if not s.get("ligne_de_vue", True):
        morceaux.append("sans ligne de vue")
    if s.get("lancer_en_ligne"):
        morceaux.append("en ligne")
    relance = s.get("relance", {})
    if relance.get("par_tour"):
        morceaux.append("%d/tour" % relance["par_tour"])
    if relance.get("delai"):
        morceaux.append("relance %d t." % relance["delai"])
    if "critique" in s:
        morceaux.append("critique %d %%" % s["critique"])
    return ", ".join(morceaux)


def bonus_objet(o):
    return ", ".join("%s %s" % (STATS.get(k, k), plage(*v) if isinstance(v, list) else v)
                     for k, v in o.get("bonus", {}).items())


def conditions_objet(o):
    return ", ".join("%s ≥ %s" % (STATS.get(k, k), v) for k, v in o.get("conditions", {}).items())


def nom_monstre(m):
    if "niveaux" in m:
        niveau = plage(m["niveaux"]["min"], m["niveaux"]["max"])
    else:
        niveau = m.get("niveau", "?")
    etiquette = " (mini-boss)" if m.get("boss") else " (élite)" if m.get("elite") else ""
    return "%s%s niv. %s" % (m["nom"], etiquette, niveau)


def main():
    objets = charger("objets")
    sorts = charger("sorts")
    monstres = charger("monstres")
    voies = charger("voies")
    races = charger("races")
    panoplies = charger("panoplies")
    metiers = charger("metiers")
    quetes = charger("quetes")

    # Comment obtenir chaque objet.
    obtention = {i: [] for i in objets}
    butins = {i: [] for i in objets}
    for m in monstres.values():
        for b in m.get("butin", []):
            butins.setdefault(b["objet"], []).append((b["taux"], m))
    for i, liste in butins.items():
        liste.sort(key=lambda x: -x[0])
        texte = ", ".join("%s %d %%" % (m["nom"], round(t * 100)) for t, m in liste[:BUTIN_MAX])
        if len(liste) > BUTIN_MAX:
            texte += " (+%d autres)" % (len(liste) - BUTIN_MAX)
        if liste:
            obtention[i].append("butin : " + texte)
    for metier in metiers.values():
        for r in metier.get("recettes", []):
            ingredients = ", ".join("%d %s" % (n, objets.get(k, {"nom": k})["nom"])
                                    for k, n in r["ingredients"].items())
            obtention[r["objet"]].append("%s niv. %d (%s)" % (metier["nom"], r["niveau"], ingredients))
        for r in metier.get("ressources", []):
            obtention[r["objet"]].append("%s : %s niv. %d" % (metier["nom"], r["nom"], r["niveau"]))
            if r.get("rare"):
                obtention[r["rare"]].append("%s : %s niv. %d, récolte rare" % (metier["nom"], r["nom"], r["niveau"]))
    for q in quetes.values():
        for r in q.get("recompenses", {}).get("objets", []):
            obtention[r["objet"]].append("récompense de « %s »" % q["nom"])
        for etape in q.get("etapes", []):
            for obj in etape.get("objectifs", []):
                if "butin" in obj:
                    noms = ", ".join(monstres[m]["nom"] for m in obj["butin"]["monstres"] if m in monstres)
                    obtention[obj["objet"]].append("« %s » : sur %s (%d %%)" % (
                        q["nom"], noms, round(obj["butin"]["taux"] * 100)))
    for v in voies.values():
        for i in v.get("equipement_depart", []):
            obtention[i].append("équipement de départ : %s" % v["nom"])
    panoplie_de = {i: p for p in panoplies.values() for i in p["objets"]}

    lignes = [
        "# Catalogue des objets et des sorts",
        "",
        "Généré par `game/tools/catalogue.py` à partir de `game/data/` : ne pas modifier à la main,",
        "relancer `python3 game/tools/catalogue.py` après un changement de contenu.",
        "",
        "Lecture : les plages (8–12) sont des jets aléatoires ; « t. » = tours. Les sorts gagnent en",
        "puissance avec la caractéristique de leur élément (Acier : Force, Flamme : Intelligence,",
        "Givre : Chance, Tempête : Agilité, Sacré : Force et Intelligence, Impie : Agilité et Chance).",
        "Prix de boutique : selon la rareté (revente à 25 %).",
        "",
        "## Sommaire",
        "",
    ]
    lignes += ["- [%s](#%s)" % (titre, titre.lower().replace(" ", "-"))
               for _, titre in TYPES]
    lignes += ["- [Panoplies](#panoplies)", "- [Sorts des Voies](#sorts-des-voies)",
               "- [Sorts de race](#sorts-de-race)", "- [Sorts des monstres](#sorts-des-monstres)", ""]

    total = {t: sum(1 for o in objets.values() if o["type"] == t) for t, _ in TYPES}
    lignes.append("**%d objets** (%s) et **%d sorts**." % (
        len(objets), ", ".join("%d %s" % (total[t], titre.lower()) for t, titre in TYPES), len(sorts)))
    lignes.append("")

    for type_objet, titre in TYPES:
        liste = sorted((o for o in objets.values() if o["type"] == type_objet),
                       key=lambda o: (o["niveau"], o["nom"]))
        lignes += ["## " + titre, ""]
        equipement = type_objet not in ("ressource", "quete")
        if equipement:
            entete = "| Nom | Niv. | Rareté | Bonus | Conditions | %sObtention | Description |" % (
                "Attaque | " if type_objet == "arme" else "")
        else:
            entete = "| Nom | Niv. | Rareté | Obtention | Description |"
        lignes += [entete, "|" + "---|" * (entete.count("|") - 1)]
        for o in liste:
            sources = list(obtention.get(o["id"], []))
            if o["type"] != "quete" and o.get("boutique", True):
                prix = (PRIX_EQUIPEMENT if equipement else PRIX_RESSOURCE)[o["rarete"]]
                sources.insert(0, "boutique %d écus" % prix)
            nom = "**%s**" % o["nom"]
            if o["id"] in panoplie_de:
                nom += " *(%s)*" % panoplie_de[o["id"]]["nom"]
            colonnes = [nom, o["niveau"], RARETES.get(o["rarete"], o["rarete"])]
            if equipement:
                colonnes += [bonus_objet(o) or "—", conditions_objet(o) or "—"]
                if type_objet == "arme":
                    a = o["attaque"]
                    colonnes.append("%s : %s" % (caracteristiques_sort(a), effets(a["effets"])))
            colonnes += ["<br>".join(sources) or "**aucune**", o.get("description", "")]
            lignes.append("| " + " | ".join(cellule(c) for c in colonnes) + " |")
        lignes.append("")

    lignes += ["## Panoplies", "", "| Panoplie | Orientation | Pièces | Bonus par nombre de pièces |",
               "|---|---|---|---|"]
    for p in panoplies.values():
        pieces = ", ".join(objets[i]["nom"] if i in objets else i for i in p["objets"])
        paliers = "<br>".join("%s pièces : %s" % (n, ", ".join("%s +%s" % (STATS.get(k, k), v)
                                                               for k, v in b.items()))
                              for n, b in p["bonus"].items())
        lignes.append("| " + " | ".join(cellule(c) for c in [
            "**%s**" % p["nom"], p.get("orientation", ""), pieces, paliers]) + " |")
    lignes.append("")

    def table_sorts(ids, avec_lanceurs=None):
        sortie = ["| Sort | Caractéristiques | Effets | %sDescription |" % (
            "Lanceurs | " if avec_lanceurs else ""), "|---|---|---|---|" + ("---|" if avec_lanceurs else "")]
        for i in ids:
            s = sorts[i]
            colonnes = ["**%s**" % s["nom"], caracteristiques_sort(s), effets(s["effets"])]
            if avec_lanceurs:
                colonnes.append(avec_lanceurs[i])
            colonnes.append(s.get("description", ""))
            sortie.append("| " + " | ".join(cellule(c) for c in colonnes) + " |")
        return sortie + [""]

    utilises = set()
    lignes += ["## Sorts des Voies", ""]
    for v in voies.values():
        c = v["caracteristiques"]
        lignes += ["### %s" % v["nom"], "",
                   "%s PV %d, PA %d, PM %d, initiative %d. Départ : %s." % (
                       v.get("description", ""), c["pv"], c["pa"], c["pm"], c["initiative"],
                       ", ".join(objets[i]["nom"] for i in v.get("equipement_depart", []) if i in objets)),
                   ""]
        lignes += table_sorts(v["sorts"])
        utilises.update(v["sorts"])

    lignes += ["## Sorts de race", ""]
    lanceurs_race = {}
    for r in races.values():
        if r.get("sort"):
            lanceurs_race[r["sort"]] = r["nom"]
    lignes += table_sorts(sorted(lanceurs_race, key=lambda i: sorts[i]["nom"]), lanceurs_race)
    utilises.update(lanceurs_race)

    lanceurs = {}
    for m in sorted(monstres.values(), key=lambda m: m["nom"]):
        for i in m.get("sorts", []):
            lanceurs.setdefault(i, []).append(nom_monstre(m))
        for n, phase in enumerate(m.get("phases", []), 1):
            for i in phase.get("sorts", []):
                lanceurs.setdefault(i, []).append("%s, phase %d (%d %% PV)" % (nom_monstre(m), n, phase["pv"]))
    lignes += ["## Sorts des monstres", ""]
    lignes += table_sorts(sorted((i for i in lanceurs if i in sorts), key=lambda i: sorts[i]["nom"]),
                          {i: ", ".join(l) for i, l in lanceurs.items()})
    utilises.update(lanceurs)

    orphelins = sorted(set(sorts) - utilises)
    if orphelins:
        lignes += ["## Sorts sans lanceur", ""]
        lignes += table_sorts(orphelins)

    with open(SORTIE, "w", encoding="utf-8") as fichier:
        fichier.write("\n".join(lignes).rstrip() + "\n")
    print("%s : %d objets, %d sorts" % (os.path.relpath(SORTIE, RACINE), len(objets), len(sorts)))


if __name__ == "__main__":
    main()
