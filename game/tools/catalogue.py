#!/usr/bin/env python3
"""Catalogue de tous les objets, monstres et sorts du jeu, tiré des JSON de game/data/.

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
    "vitalite": "Vitalité", "force": "Force", "intelligence": "Intelligence",
    "perception": "Perception", "agilite": "Agilité", "prospection": "Prospection", "initiative": "Initiative",
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
NOMS_SORTS = {}  # id → nom, rempli au chargement (sorts créés par « creer_sort »)
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
    elif t == "etat_elementaire":
        texte = "état élémentaire %s (permanent, 3 au plus)" % element(e)
    elif t == "composition_etats":
        texte = "choisit d'un coup ses 3 états élémentaires parmi %s (permanents)" % " et ".join(
            ELEMENTS.get(x, x) for x in e["elements"])
    elif t == "creer_sort":
        texte = "crée le sort de la combinaison des 3 états : " + " ; ".join(
            "%s → %s" % (" + ".join(ELEMENTS.get(x, x) for x in cle.split("+")), NOMS_SORTS.get(sort, sort))
            for cle, sort in e["combinaisons"].items())
    elif t == "charge":
        texte = "charge en ligne jusqu'au contact (effets suivants au contact seulement)"
    elif t == "retrait_etats":
        texte = "retire %s" % " et ".join({"bonus": "les bonus", "malus": "les malus", "poison": "les poisons"}.get(x, x) for x in e["etats"])
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


ZONES = [("brumerive", "Brumerive (humains)"), ("crasse_roc", "Crasse-Roc (gobelins)"),
         ("sylvebrume", "Sylvebrume (elfes)"), ("hautepierre", "Hautepierre"),
         ("cendre", "La Cendre"), ("", "Ailleurs")]
STATS_MONSTRE = [("pv", "PV"), ("initiative", "Init."), ("xp", "XP"), ("force", "Force"),
                 ("intelligence", "Intel."), ("perception", "Percep."), ("agilite", "Agi.")]


def zone_de_carte(carte_id):
    for z, _ in ZONES:
        if z and carte_id.startswith(z):
            return z
    return ""


def stats_au_niveau(m, niveau):
    """Comme GameData.create_monster : la base, plus « par_niveau » pour chaque niveau au-dessus."""
    pas = niveau - m["niveau"]
    par_niveau = m.get("par_niveau", {})
    c = m["caracteristiques"]
    stats = {k: int(c.get(k, 0)) + pas * int(par_niveau.get(k, 0))
             for k in ("pv", "pa", "pm", "initiative", "force", "intelligence", "perception", "agilite")}
    stats["xp"] = int(m.get("xp", 0)) + pas * int(par_niveau.get("xp", 0))
    resistances = dict(m.get("resistances", {}))
    for e, v in par_niveau.get("resistances", {}).items():
        resistances[e] = resistances.get(e, 0) + pas * v
    stats["resistances"] = resistances
    return stats


def texte_resistances(r):
    return ", ".join("%s %+d %%" % (ELEMENTS.get(e, e), v) for e, v in r.items() if v) or "aucune"


ALERTE_ZONE = 60  # % des dégâts d'une zone dans un seul élément (zones de 3 monstres ou plus)
ALERTE_JEU = 35  # % des dégâts de tout le jeu dans un seul élément


def elements_du_monstre(m, sorts):
    """Part de chaque élément dans les dégâts moyens des sorts du monstre (phases comprises)."""
    parts = {}

    def parcourir(liste):
        for e in liste:
            if e["type"] in ("degats", "poison") and "element" in e and e.get("cibles") != "allies":
                parts[e["element"]] = parts.get(e["element"], 0) + (e["min"] + e["max"]) / 2
            parcourir(e.get("effets", []))

    for i in m.get("sorts", []) + [s for p in m.get("phases", []) for s in p.get("sorts", [])]:
        parcourir(sorts[i]["effets"])
    total = sum(parts.values())
    return {e: v / total for e, v in parts.items()} if total else {}


def section_elements(monstres, sorts, cartes):
    """Répartition des éléments de dégâts par zone et dans tout le jeu (chaque monstre compte pour
    un, dans chaque zone où il vit ; une élite vit dans la zone de sa famille)."""
    zones = {i: set() for i in monstres}
    for carte in cartes.values():
        for g in carte.get("groupes", []):
            for i in g.get("monstres", []) + g.get("parmi", []):
                if i in zones:
                    zones[i].add(zone_de_carte(carte["id"]))
    for m in monstres.values():
        if m.get("elite") and m.get("famille") in zones:
            zones[m["id"]] = zones[m["famille"]]
    par_zone = {z: {} for z, _ in ZONES}
    effectifs = {z: 0 for z, _ in ZONES}
    jeu = {}
    for m in monstres.values():
        parts = elements_du_monstre(m, sorts)
        for e, v in parts.items():
            jeu[e] = jeu.get(e, 0) + v
        for z in zones[m["id"]] or {""}:
            effectifs[z] += 1
            for e, v in parts.items():
                par_zone[z][e] = par_zone[z].get(e, 0) + v

    def pourcents(parts):
        total = sum(parts.values()) or 1
        return {e: round(100 * v / total) for e, v in sorted(parts.items(), key=lambda x: -x[1])}

    lignes = ["## Éléments des dégâts", "",
              "Part de chaque élément dans les dégâts moyens des monstres (chacun compte pour un, dans",
              "chaque zone où il vit). Règle : un élément dominant par zone, sans dépasser %d %% d'une zone"
              % ALERTE_ZONE, "ni %d %% du jeu entier, pour qu'aucune résistance unique ne suffise." % ALERTE_JEU, "",
              "| Zone | Monstres | Répartition |", "|---|---|---|"]
    alertes = []
    for z, nom in ZONES:
        if not effectifs[z]:
            continue
        repartition = pourcents(par_zone[z])
        lignes.append("| %s | %d | %s |" % (nom, effectifs[z], ", ".join(
            "%s %d %%" % (ELEMENTS[e], v) for e, v in repartition.items())))
        if effectifs[z] >= 3 and max(repartition.values()) > ALERTE_ZONE:
            alertes.append("%s : %s au-dessus de %d %%" % (nom, max(repartition, key=repartition.get), ALERTE_ZONE))
    repartition = pourcents(jeu)
    lignes.append("| **Jeu entier** | %d | %s |" % (len(monstres), ", ".join(
        "%s %d %%" % (ELEMENTS[e], v) for e, v in repartition.items())))
    if max(repartition.values()) > ALERTE_JEU:
        alertes.append("jeu entier : %s au-dessus de %d %%" % (max(repartition, key=repartition.get), ALERTE_JEU))
    for a in alertes:
        print("ALERTE éléments, " + a)
    return lignes + [""] + ["**Alerte** : " + a for a in alertes] + ([""] if alertes else [])


def section_monstres(monstres, objets, sorts, cartes):
    # Où vit chaque espèce : groupes des cartes (fixes ou tirés au sort), regroupés par carte.
    par_carte = {i: {} for i in monstres}
    for carte in cartes.values():
        for g in carte.get("groupes", []):
            for i in dict.fromkeys(g.get("monstres", []) + g.get("parmi", [])):
                if i not in par_carte:
                    continue
                details = []
                if "parmi" in g:
                    details.append("au hasard")
                if "apres_boss" in g:
                    details.append("après %s" % monstres.get(g["apres_boss"], {"nom": g["apres_boss"]})["nom"])
                if "reapparition" in g:
                    details.append("réapparition %s s" % plage(*g["reapparition"]))
                par_carte[i].setdefault(carte["id"], (carte["nom"], []))[1].append(", ".join(details))
    # Les élites apparaissent d'elles-mêmes là où vit leur famille.
    for m in monstres.values():
        if m.get("elite") and m.get("famille") in par_carte:
            par_carte[m["id"]] = {c: (nom, ["apparition spontanée"])
                                  for c, (nom, _) in par_carte[m["famille"]].items()}

    def texte_lieu(carte_id, nom, groupes):
        if groupes == ["apparition spontanée"]:
            details = "apparition spontanée"
        else:
            details = "%d groupe%s" % (len(groupes), "s" if len(groupes) > 1 else "")
            precisions = {}
            for g in groupes:
                if g:
                    precisions[g] = precisions.get(g, 0) + 1
            if precisions:
                details += ", dont " + ", ".join("%d %s" % (n, g) for g, n in precisions.items())
        return "%s (`%s`, %s)" % (nom.split(" — ")[-1], carte_id, details)

    lieux = {i: [(c, texte_lieu(c, nom, groupes)) for c, (nom, groupes) in sorted(cartes_.items())]
             for i, cartes_ in par_carte.items()}

    def zone(m):
        ids = [c for c, _ in lieux[m["id"]]]
        for rang, (z, _) in enumerate(ZONES):
            if any(zone_de_carte(c) == z for c in ids):
                return rang
        return len(ZONES) - 1

    def ordre(m):
        famille = m.get("famille") if m.get("elite") else m["id"]
        base = monstres.get(famille, m)
        return (zone(base), base["niveau"], base["nom"], 1 if m.get("elite") else 0)

    lignes = ["## Monstres", "",
              "Stats calculées comme dans le jeu : le niveau de base du fichier, plus « par niveau » pour",
              "chaque niveau au-dessus. PA et PM sont les mêmes à tous les niveaux (sauf mention). Le",
              "niveau ne change jamais le butin. Les élites apparaissent seules toutes les 5 à 6 minutes",
              "sur une carte de leur famille (une à la fois, butin augmenté avec l'ancienneté).", ""]
    zone_courante = None
    for m in sorted(monstres.values(), key=ordre):
        rang = zone(monstres.get(m.get("famille"), m) if m.get("elite") else m)
        if rang != zone_courante:
            zone_courante = rang
            lignes += ["### " + ZONES[rang][1], ""]
        if m.get("boss"):
            nature = "boss"
        elif m.get("elite"):
            nature = "élite de la famille %s" % monstres.get(m["famille"], {"nom": m["famille"]})["nom"]
        elif m.get("corrompu"):
            nature = "variante corrompue de %s" % monstres.get(m["base"], {"nom": m["base"]})["nom"]
        else:
            nature = "famille"
        lignes += ["#### %s *(%s)*" % (m["nom"], nature), "", "*%s*" % m.get("description", ""), ""]
        if "niveaux" in m:
            n = m["niveaux"]
            niveaux = list(range(n["min"], n["max"] + 1))
            total = sum(n["poids"])
            texte_niveau = "%s (tirage : %s)" % (plage(n["min"], n["max"]), ", ".join(
                "niv. %d %d %%" % (v, round(100 * p / total)) for v, p in zip(niveaux, n["poids"])))
        else:
            niveaux = [m["niveau"]]
            texte_niveau = "%d (fixe)" % m["niveau"]
        base = stats_au_niveau(m, niveaux[0])
        haut = stats_au_niveau(m, niveaux[-1])
        pa_pm = "%d PA, %d PM" % (base["pa"], base["pm"])
        if (haut["pa"], haut["pm"]) != (base["pa"], base["pm"]):
            pa_pm += " (niv. %d : %d PA, %d PM)" % (niveaux[-1], haut["pa"], haut["pm"])
        resistances = texte_resistances(base["resistances"])
        if haut["resistances"] != base["resistances"]:
            resistances += " (niv. %d : %s)" % (niveaux[-1], texte_resistances(haut["resistances"]))
        noms_sorts = ", ".join(sorts[i]["nom"] if i in sorts else i for i in m.get("sorts", []))
        lignes += ["- **Niveau** : %s ; **%s** ; IA %s" % (texte_niveau, pa_pm, m.get("ia", "basique")),
                   "- **Résistances** : " + resistances,
                   "- **Sorts** : " + (noms_sorts or "aucun")]
        for k, phase in enumerate(m.get("phases", []), 1):
            morceaux = []
            if phase.get("sorts"):
                morceaux.append("apprend " + ", ".join(sorts[i]["nom"] for i in phase["sorts"]))
            if phase.get("effets"):
                morceaux.append(effets(phase["effets"]))
            lignes.append("- **Phase %d** (à %d %% PV) : %s. Message : %s" % (
                k, phase["pv"], " ; ".join(morceaux), phase["message"]))
        butin = ", ".join("%s %d %%%s" % (
            objets.get(b["objet"], {"nom": b["objet"]})["nom"], round(b["taux"] * 100),
            " (×%s)" % plage(*b["quantite"]) if "quantite" in b else "") for b in m.get("butin", []))
        lignes.append("- **Butin** : %s ; **brumes** %s" % (butin or "aucun", plage(*m["ecus"]) if "ecus" in m else "0"))
        endroits = [texte for _, texte in lieux[m["id"]]]
        lignes.append("- **Où le trouver** : " + (" · ".join(endroits) if endroits else "nulle part sur les cartes"))
        lignes.append("")
        colonnes = [(k, nom) for k, nom in STATS_MONSTRE
                    if k in ("pv", "initiative", "xp") or base[k] or haut[k]]
        lignes += ["| Niv. | " + " | ".join(nom for _, nom in colonnes) + " |",
                   "|---|" + "---|" * len(colonnes)]
        for v in niveaux:
            s = stats_au_niveau(m, v)
            lignes.append("| %d | " % v + " | ".join(str(s[k]) for k, _ in colonnes) + " |")
        lignes.append("")
    return lignes


def main():
    objets = charger("objets")
    sorts = charger("sorts")
    NOMS_SORTS.update({i: s["nom"] for i, s in sorts.items()})
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
        "# Catalogue des objets, des monstres et des sorts",
        "",
        "Généré par `game/tools/catalogue.py` à partir de `game/data/` : ne pas modifier à la main,",
        "relancer `python3 game/tools/catalogue.py` après un changement de contenu.",
        "",
        "Lecture : les plages (8–12) sont des jets aléatoires ; « t. » = tours. Les sorts gagnent en",
        "puissance avec la caractéristique de leur élément (Acier : Force, Flamme : Intelligence,",
        "Givre : Perception, Tempête : Agilité, Sacré : Force et Intelligence, Impie : Agilité et Perception).",
        "Prix de boutique : selon la rareté (revente à 25 %).",
        "",
        "## Sommaire",
        "",
    ]
    lignes += ["- [%s](#%s)" % (titre, titre.lower().replace(" ", "-"))
               for _, titre in TYPES]
    lignes += ["- [Panoplies](#panoplies)", "- [Éléments des dégâts](#éléments-des-dégâts)", "- [Monstres](#monstres)", "- [Sorts des Voies](#sorts-des-voies)",
               "- [Sorts de race](#sorts-de-race)", "- [Sorts des monstres](#sorts-des-monstres)", ""]

    total = {t: sum(1 for o in objets.values() if o["type"] == t) for t, _ in TYPES}
    lignes.append("**%d objets** (%s), **%d monstres** et **%d sorts**." % (
        len(objets), ", ".join("%d %s" % (total[t], titre.lower()) for t, titre in TYPES),
        len(monstres), len(sorts)))
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
                sources.insert(0, "boutique %d brumes" % prix)
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

    cartes = charger("cartes")
    lignes += section_elements(monstres, sorts, cartes)
    lignes += section_monstres(monstres, objets, sorts, cartes)

    def table_sorts(ids, avec_lanceurs=None, titre="Lanceurs"):
        sortie = ["| Sort | Caractéristiques | Effets | %sDescription |" % (
            titre + " | " if avec_lanceurs else ""), "|---|---|---|---|" + ("---|" if avec_lanceurs else "")]
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
    crees = {}  # sort créé → (Voie, combinaison)
    for v in voies.values():
        for i in v["sorts"]:
            for e in sorts[i]["effets"]:
                if e["type"] == "creer_sort":
                    for cle, cree in e["combinaisons"].items():
                        crees[cree] = (v["nom"], " + ".join(ELEMENTS.get(x, x) for x in cle.split("+")))
    for v in voies.values():
        c = v["caracteristiques"]
        lignes += ["### %s" % v["nom"], "",
                   "%s PV %d, PA %d, PM %d, initiative %d. Départ : %s." % (
                       v.get("description", ""), c["pv"], c["pa"], c["pm"], c["initiative"],
                       ", ".join(objets[i]["nom"] for i in v.get("equipement_depart", []) if i in objets)),
                   ""]
        lignes += table_sorts(v["sorts"])
        utilises.update(v["sorts"])
        siens = [i for i, (voie, _) in crees.items() if voie == v["nom"] and i in sorts]
        if siens:
            lignes += ["Sorts créés (*Fusion arcanique*, selon la combinaison des 3 états élémentaires) :", ""]
            lignes += table_sorts(siens, {i: crees[i][1] for i in siens}, "Combinaison")
            utilises.update(siens)

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
        lignes += ["## Sorts sans lanceur", "", "Sorts reliés à aucune Voie, race ou monstre (par exemple les anciens sorts de l'Arcaniste,",
                   "gardés comme trace de sa première version).", ""]
        lignes += table_sorts(orphelins)

    with open(SORTIE, "w", encoding="utf-8") as fichier:
        fichier.write("\n".join(lignes).rstrip() + "\n")
    print("%s : %d objets, %d monstres, %d sorts" % (os.path.relpath(SORTIE, RACINE), len(objets), len(monstres), len(sorts)))


if __name__ == "__main__":
    main()
