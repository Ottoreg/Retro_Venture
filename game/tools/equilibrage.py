#!/usr/bin/env python3
"""Documents d'équilibrage tirés du code et des données : docs/METIERS.md et docs/CLASSES.md.

    python3 game/tools/equilibrage.py

Les constantes sont lues dans les scripts GDScript (`const NOM := …`) et les chiffres dans
game/data/ : à relancer après tout changement de métier, de forge, de sort, de Voie ou de race.
Les formules (valeur d'une ressource à la forge, réputation, dégâts) sont recopiées des scripts
nommés en commentaire : à suivre s'ils changent.
"""
import ast
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from catalogue import (CARACS, ELEMENTS, NOMS_SORTS, RACINE, STATS, caracteristiques_sort, cellule, charger, effet, effets,
                       nom_monstre, plage)

CORE = os.path.join(RACINE, "game", "core")
DOCS = os.path.join(RACINE, "docs")


def constante(script, nom, noms=None):
    """Valeur de `const nom := …` dans game/core/<script> (les identifiants de `noms` sont remplacés)."""
    with open(os.path.join(CORE, script), encoding="utf-8") as f:
        texte = f.read()
    debut = re.search(r"^const %s\s*(?::\s*\w+\s*)?:?=\s*" % nom, texte, re.M).end()
    profondeur, fin = 0, debut
    while fin < len(texte) and (profondeur or texte[fin] != "\n"):
        profondeur += {"[": 1, "{": 1, "(": 1, "]": -1, "}": -1, ")": -1}.get(texte[fin], 0)
        fin += 1
    expression = re.sub(r"##.*", "", texte[debut:fin]).replace("true", "True").replace("false", "False")
    for ident, valeur in (noms or {}).items():
        expression = re.sub(r"\b%s\b" % ident, repr(valeur), expression)
    return ast.literal_eval(expression)


def table(entete, lignes):
    return ["| " + " | ".join(entete) + " |", "|" + "---|" * len(entete)] + [
        "| " + " | ".join(cellule(c) for c in ligne) + " |" for ligne in lignes] + [""]


def nombre(x):
    return ("%.2f" % x).rstrip("0").rstrip(".").replace(".", ",") if isinstance(x, float) else str(x)


# Progression (core/character/progression.gd), partagée par les classes et les métiers.
TAUX_ANCIEN = constante("character/progression.gd", "OLD_XP_RATE")
NIVEAU_MAX = constante("character/progression.gd", "MAX_EQUIVALENT_LEVEL")
POINTS_DIFFICULTE = constante("character/progression.gd", "DIFFICULTY_POINTS")
PALIERS_REPUTATION = constante("character/character.gd", "REPUTATION_TIERS")
REPUTATION_PAR_POINT = constante("character/character.gd", "REPUTATION_PER_MASTERY_POINT")
RANG_MAX = constante("character/character.gd", "SPELL_MAX_RANK")
POINTS_PAR_PALIER = constante("character/character.gd", "CLASS_POINTS_PER_TIER")


def points_gagnes(reputation, metier):
    """`Character.earned_points` : un point par tranche pour un métier, 20 par palier pour une classe."""
    if metier:
        return reputation // REPUTATION_PAR_POINT
    points, pas = 0, 1
    for (bas, _), (haut, _) in zip(PALIERS_REPUTATION, PALIERS_REPUTATION[1:]):
        pas = (haut - bas) // POINTS_PAR_PALIER
        points += min(max(0, reputation - bas), pas * POINTS_PAR_PALIER) // pas
    return points + max(0, reputation - PALIERS_REPUTATION[-1][0]) // pas


def seuils_niveaux():
    """Réputation qu'il faut pour chaque niveau équivalent (Progression.equivalent_level)."""
    seuils, besoin = [0], 0.0
    for niveau in range(1, NIVEAU_MAX):
        besoin += (60.0 * niveau + 20.0 * niveau * niveau) / TAUX_ANCIEN
        seuils.append(besoin)
    return seuils


SEUILS = seuils_niveaux()


def niveau_equivalent(reputation):
    return max(n for n, s in enumerate(SEUILS, 1) if reputation >= s)


def difficulte(menace, force):
    """Progression.difficulty pour un seul monstre et un seul joueur."""
    rapport = max(1.0, menace) / max(1.0, force)
    if rapport <= POINTS_DIFFICULTE[0][0]:
        return POINTS_DIFFICULTE[0][1]
    for (r0, f0), (r1, f1) in zip(POINTS_DIFFICULTE, POINTS_DIFFICULTE[1:]):
        if rapport <= r1:
            return f0 + (f1 - f0) * (rapport - r0) / (r1 - r0)
    return POINTS_DIFFICULTE[-1][1]


def section_reputation(quoi):
    """Paliers, points de maîtrise et niveaux équivalents (communs aux classes et aux métiers)."""
    cout_total = RANG_MAX * (RANG_MAX + 1) // 2
    lignes = ["## Réputation et maîtrise", "",
              "Même modèle pour chaque %s (`core/character/character.gd`) : la réputation est un total cumulé" % quoi,
              "qui débloque et donne des **points de maîtrise** à répartir : " + (
                  "**%d** par palier (`CLASS_POINTS_PER_TIER`), puis au rythme du dernier palier, sans plafond."
                  % POINTS_PAR_PALIER if quoi == "classe" else "un par tranche de **%d** de réputation." % REPUTATION_PAR_POINT),
              "Monter au rang *n* coûte *n* points : rang %d = **%d points** par sort ou compétence." % (RANG_MAX, cout_total), ""]
    lignes += table(["Palier", "Réputation", "Points de maîtrise gagnés", "Niveau équivalent"],
                    [[n, r, points_gagnes(r, quoi != "classe"), niveau_equivalent(r)] for r, n in PALIERS_REPUTATION])
    lignes += ["**Niveau équivalent** (`Progression.equivalent_level`, jamais affiché) : la force tirée de la",
               "réputation, l'ancienne courbe d'XP divisée par %s (passer de *n* à *n*+1 coûte (60·*n* + 20·*n*²) / %s)."
               % (nombre(TAUX_ANCIEN), nombre(TAUX_ANCIEN)),
               "Il sert au **facteur de difficulté** : rapport niveau (monstre ou palier) / niveau équivalent,",
               "interpolé entre les points %s (rapport → facteur), borné aux extrémités." % ", ".join(
                   "%s → %s" % (nombre(r), nombre(f)) for r, f in POINTS_DIFFICULTE), ""]
    niveaux = [1, 2, 3, 5, 8, 10, 12, 15, 20, 25, 30, 40, 50, NIVEAU_MAX]
    lignes += table(["Niveau équivalent"] + [str(n) for n in niveaux],
                    [["Réputation"] + [str(round(SEUILS[n - 1])) for n in niveaux]])
    return lignes


# ---------------------------------------------------------------------------- métiers

def metiers_md():
    objets, metiers, monstres, quetes, cartes = (charger(d) for d in ("objets", "metiers", "monstres", "quetes", "cartes"))
    prof = "jobs/profession.gd"
    noms = {"TYPE_HARVEST": "recolte", "TYPE_CRAFT": "artisanat"}
    competences = constante(prof, "SKILLS", noms)
    rare = constante(prof, "RARE_CHANCE")
    t_base, t_palier, t_min = (constante(prof, n) for n in ("HARVEST_BASE_TIME", "HARVEST_TIME_PER_TIER", "HARVEST_MIN_TIME"))
    forge = "items/forge.gd"
    max_res, jet_bas, rep_palier = (constante(forge, n) for n in ("MAX_SLOTS", "ROLL_LOW", "REPUTATION_PER_TIER"))
    fixes, poids, types = constante(forge, "FIXED_STATS"), constante(forge, "STAT_WEIGHTS"), constante(forge, "TYPES")
    facteur_rare = constante(forge, "RARE_FACTOR")
    score_palier, palier_max, max_lignes = (constante(forge, n) for n in ("LINE_SCORE_PER_TIER", "MAX_TIER", "MAX_LINES"))

    def temps(palier, rang=0):  # Profession.harvest_time
        return max(t_min, (t_base + t_palier * palier) * (1 - competences["recolte"]["celerite"][2] * rang / 100))

    def gain(base, palier, niveau):  # Profession.reputation_gain (sans bonus de race)
        return round(base * 2 * difficulte(palier, niveau))

    def valeur(carac, palier, rare=False):  # Forge.value
        return 1 if carac in fixes else max(1, int(palier * poids[carac] + 0.5)) * (facteur_rare if rare else 1)

    def plafond(carac, palier):  # Forge.line_cap
        return int(fixes[carac] <= score_palier * palier) if carac in fixes else int(score_palier * palier * poids[carac])

    def caracs(o):  # Forge.stats_of
        c = o.get("caracteristique", [])
        return c if isinstance(c, list) else [c]

    # Où sont les nœuds de récolte : marqueur → { carte : nombre }.
    marqueurs = {r["marqueur"]: r for m in metiers.values() for r in m.get("ressources", [])}
    places = {k: {} for k in marqueurs}
    for c in cartes.values():
        for ligne in c.get("plan", []):
            for car in ligne:
                if car in places:
                    places[car][c["id"]] = places[car].get(c["id"], 0) + 1
    butins = {}
    for m in monstres.values():
        for b in m.get("butin", []):
            butins.setdefault(b["objet"], []).append((b["taux"], m, b.get("quantite", [1, 1])))
    recompenses = {}
    for q in quetes.values():
        for r in q.get("recompenses", {}).get("objets", []):
            recompenses.setdefault(r["objet"], []).append(q["nom"])

    lignes = ["# Métiers et forge : toutes les variables", "",
              "Généré par `game/tools/equilibrage.py` à partir du code (`core/jobs/profession.gd`,",
              "`core/items/forge.gd`, `core/character/`) et de `game/data/` : ne pas modifier à la main.",
              "Vue d'ensemble pour l'équilibrage ; les règles sont dans le GDD (§ 10.2 à 10.4), le détail des",
              "objets et des monstres dans [CATALOGUE.md](CATALOGUE.md), les classes dans [CLASSES.md](CLASSES.md).", "",
              "## Principe", "",
              "Tous les métiers sont ouverts dès le début, sans niveau : on gagne de la **réputation de métier** à",
              "chaque récolte ou objet forgé, selon la difficulté (palier de ce qu'on fait contre niveau",
              "équivalent de sa réputation), et des **points de maîtrise** à placer dans des compétences qui",
              "améliorent la qualité, sans jamais faire échouer. Métiers codés : %s." % ", ".join(
                  "%s (%s)" % (m["nom"], m["type"]) for m in metiers.values()), ""]
    lignes += section_reputation("métier")
    lignes += ["### Réputation gagnée", "",
               "`Profession.reputation_gain` : base × 2 × facteur de difficulté (palier contre niveau équivalent)",
               "× (100 + bonus de race) / 100. Base : le champ `xp` du nœud pour une récolte, **%d × palier de" % rep_palier,
               "l'objet** pour une forge. Passif humain : +10 % (« reputation_metier »). Pour une base de 10 :", ""]
    paliers = [1, 3, 5, 10, 15, 20]
    lignes += table(["Palier \\ niveau équivalent"] + [str(n) for n in paliers],
                    [[p] + [gain(10, p, n) for n in paliers] for p in paliers])

    lignes += ["## Compétences", ""]
    lignes += table(["Type", "Compétence", "Effet", "Rang 1", "Rang 2", "Rang 3", "Rang 4", "Rang 5"],
                    [[t, c[0], c[1] % "x"] + [nombre(c[2] * r) for r in range(1, RANG_MAX + 1)]
                     for t, liste in competences.items() for c in liste.values()])
    lignes += ["- Récolte : quantité tirée dans [min, max], **+1** si le jet d'Abondance passe. Ressource rare :",
               "  chance de base **%s %%** + Œil exercé, un seul exemplaire à la place de la récolte." % nombre(rare * 100),
               "- Temps de récolte (`Profession.harvest_time`) : (%s + %s × palier) s × (1 − Célérité), %s s au moins ;"
               % (nombre(t_base), nombre(t_palier), nombre(t_min)),
               "  le personnage récolte sans bouger, la ressource lui est réservée.",
               "- Forge : chaque ligne de total *T* se tire entre *T* × (%s + Précision) et *T*." % nombre(jet_bas), ""]

    lignes += ["## Métiers de récolte", "",
               "Colonnes : palier (`niveau` du nœud) ; quantité par récolte ; réputation de base (`xp`) et",
               "réputation gagnée à niveau équivalent = palier (facteur 0,5) ; repousse en secondes ; temps de",
               "récolte sans Célérité / au rang 5 ; ressource rare ; forge (caractéristique et matière de la",
               "ressource récoltée) ; nombre de nœuds par carte.", ""]
    for m in metiers.values():
        if m["type"] != "recolte":
            continue
        lignes += ["### %s" % m["nom"], "", "*%s*" % m.get("description", ""), ""]
        rangs = []
        for r in sorted(m["ressources"], key=lambda r: r["niveau"]):
            o = objets[r["objet"]]
            forge_txt = ", ".join(x for x in [CARACS.get(o.get("caracteristique"), ""), o.get("matiere", "")] if x) or "—"
            rare_txt = objets[r["rare"]]["nom"] if r.get("rare") in objets else "—"
            ou = ", ".join("%s ×%d" % (c, n) for c, n in sorted(places[r["marqueur"]].items())) or "**aucune carte**"
            rangs.append(["**%s** (%s)" % (r["nom"], r["marqueur"]), r["niveau"], o["nom"], plage(*r.get("quantite", [1, 1])),
                          r.get("xp", 0), gain(r.get("xp", 0), r["niveau"], r["niveau"]), plage(*r["repousse"]),
                          "%s / %s" % (nombre(temps(r["niveau"])), nombre(temps(r["niveau"], RANG_MAX))), rare_txt,
                          forge_txt, ou])
        lignes += table(["Nœud", "Palier", "Objet", "Qté", "Rép. base", "Rép. à sa mesure", "Repousse (s)",
                         "Temps (s)", "Rare", "Forge", "Cartes"], rangs)

    lignes += ["## Forge personnalisée", "",
               "`core/items/forge.gd` (GDD § 10.4). À l'enclume de la maison, on choisit un type d'objet et on y",
               "pose **%d ressources différentes au plus** (les cases de la recette, quantité libre), matières obligatoires comprises. Chaque ressource de monstre donne" % max_res,
               "une caractéristique (plusieurs pour certaines ressources de haut palier, chacune à sa valeur pleine)",
               "selon son palier. Une ligne vaut au plus **%d points de score par palier de forge** (`Forge.line_cap`, palier de" % score_palier,
               "réputation de forgeron : Apprenti 1 à Légende %d, Inconnu compté 1 ; %s : perdus avant leur palier)" % (palier_max, ", ".join(
                   "%s %d points de score" % (CARACS[c], s) for c, s in fixes.items())),
               "et un objet a au plus **%d lignes**. Le palier de l'objet est la moyenne des paliers (pondérée" % max_lignes,
               "par les quantités) ; les jets sont tirés entre %d %% et 100 %% du total (plus avec Précision)." % round(jet_bas * 100),
               "%s : 1 par ressource quel que soit le palier, 1 au plus par objet. La caractéristique d'une ressource" % ", ".join(
                   CARACS[c] for c in fixes),
               "n'est lisible qu'après un premier objet forgé, et seulement si le palier de réputation",
               "de forgeron atteint son palier (`Forge.reveals`). Réputation : %d × palier de l'objet en base." % rep_palier, "",
               "### Valeur d'une ressource", "",
               "`Forge.value` : max(1, arrondi(palier × poids)) (palier 1 à 5), **× %d pour une ressource rare** ; poids = points de" % facteur_rare,
               "la caractéristique pour un point de score (le tableau donne la valeur d'une ressource non rare).", ""]
    paliers_res = sorted({o["niveau"] for o in objets.values() if o.get("caracteristique")} | {1})
    plafonds = lambda c: " / ".join(str(plafond(c, p)) for p in range(1, palier_max + 1))
    lignes += table(["Caractéristique", "Poids", "Plafond d'une ligne (paliers de forge 1 à %d)" % palier_max] + ["P%d" % p for p in paliers_res],
                    [[CARACS[c], nombre(float(w)), plafonds(c)] + [valeur(c, p) for p in paliers_res] for c, w in poids.items()]
                    + [[CARACS[c], "fixe", plafonds(c)] + [1] * len(paliers_res) for c in fixes])
    lignes += ["### Types d'objets", ""]
    modeles = []
    for t, d in types.items():
        o = objets.get("forge_" + t, {})
        attaque = ""
        if "attaque" in o:
            a = o["attaque"]
            degats = [e for e in a["effets"] if e["type"] == "degats"]
            attaque = "%s ; %s" % (caracteristiques_sort(a), " / ".join(  # Forge.scaled_attack
                "P%d : %s" % (p, ", ".join("%s %s" % (plage(round(e["min"] * (1 + (p - 1) / 20)), round(e["max"] * (1 + (p - 1) / 20))),
                                                     ELEMENTS.get(e.get("element"), "")) for e in degats)) for p in (1, 5, 10, 20, 30)))
        modeles.append([t, ", ".join(d["matieres"]), ", ".join(n for n, _ in d["noms"]), attaque or "—"])
    lignes += table(["Type", "Matières obligatoires", "Noms proposés", "Attaque (dégâts selon le palier : × (1 + (P − 1) / 20) ; élément de la carac. élémentaire la plus forte, Sacré / Impie si leurs deux caracs sont à 10 % près)"],
                    modeles)

    lignes += ["### Ressources", "",
               "Toutes les ressources qui servent à la forge (caractéristique ou matière), par palier.", ""]
    ressources = sorted((o for o in objets.values() if o["type"] == "ressource" and (o.get("caracteristique") or o.get("matiere"))),
                        key=lambda o: (o["niveau"], o["nom"]))
    recolte = {r["objet"]: "%s (%s)" % (m["nom"], r["nom"]) for m in metiers.values() for r in m.get("ressources", [])}
    recolte.update({r["rare"]: "%s (%s, rare)" % (m["nom"], r["nom"]) for m in metiers.values() for r in m.get("ressources", []) if r.get("rare")})
    rangs = []
    for o in ressources:
        cs = caracs(o)
        sources = ([recolte[o["id"]]] if o["id"] in recolte else []) + [
            "%s %d %%%s" % (nom_monstre(m), round(t * 100), " ×%s" % plage(*q) if q != [1, 1] else "")
            for t, m, q in sorted(butins.get(o["id"], []), key=lambda x: -x[0])]
        rangs.append(["**%s**" % o["nom"], o["niveau"], o["rarete"], ", ".join(CARACS[c] for c in cs) or "—",
                      ", ".join("+%d" % valeur(c, o["niveau"], o["rarete"] == "rare") for c in cs) or "—", o.get("matiere", "—"), "<br>".join(sources) or "**aucune**"])
    lignes += table(["Ressource", "Palier", "Rareté", "Caractéristique", "Valeur", "Matière", "Obtention"], rangs)
    total = {}
    for o in ressources:
        for c in caracs(o):
            total[c] = total.get(c, 0) + 1
    lignes += ["Ressources par caractéristique : %s." % ", ".join("%s %d" % (CARACS[c], n) for c, n in sorted(total.items(), key=lambda x: -x[1])), ""]

    lignes += ["### Plans", "",
               "Un plan (objet de type « recette ») donne d'avance le type, les ressources et le nom ; l'aperçu",
               "montre tout. Bonus calculés comme `Forge.preview` sans Précision (plage du jet), au palier de forge %d." % palier_max, ""]
    rangs = []
    for o in sorted((o for o in objets.values() if o["type"] == "recette"), key=lambda o: (o["niveau"], o["nom"])):
        r = o["recette"]
        bonus, somme, nb = {}, 0, 0
        for i, n in r["ressources"].items():
            res = objets.get(i, {})
            somme, nb = somme + n * res.get("niveau", 1), nb + n
            for c in caracs(res):
                bonus[c] = bonus.get(c, 0) + n * valeur(c, res.get("niveau", 1), res.get("rarete") == "rare")
        bonus = {c: min(plafond(c, palier_max), v) for c, v in bonus.items()}
        jets = ", ".join("%s %s" % (CARACS[c], "1" if c in fixes else plage(max(1, int(v * jet_bas + 0.5)), v)) for c, v in bonus.items())
        if len(bonus) > max_lignes:
            jets += " (**trop de lignes**)"
        obtention = (["boutique"] if o.get("boutique", True) else []) + ["« %s »" % q for q in recompenses.get(o["id"], [])]
        rangs.append(["**%s**" % r["nom"], r.get("type", "objet : " + objets.get(r.get("objet"), {}).get("nom", "?")), max(1, int(somme / max(1, nb) + 0.5)), ", ".join(
            "%d %s" % (n, objets.get(i, {"nom": i})["nom"]) for i, n in r["ressources"].items()), jets or "—",
                      ", ".join(obtention) or "**aucune**"])
    lignes += table(["Plan", "Type", "Palier", "Ressources", "Jets", "Obtention"], rangs)
    return lignes


# ---------------------------------------------------------------------------- classes et races

def moyennes(liste):
    """Valeurs moyennes de base des effets chiffrés directs : { dégâts / soin / bouclier : moyenne }."""
    sommes = {}
    for e in liste:
        if e["type"] in ("degats", "soin", "bouclier") and "min" in e:
            nom = {"degats": "dégâts"}.get(e["type"], e["type"])
            sommes[nom] = sommes.get(nom, 0) + (e["min"] + e["max"]) / 2
    return sommes


def texte_maitrise(s):
    morceaux = []
    for rang, ch in sorted(s.get("maitrise", {}).items()):
        detail = []
        for k, v in ch.items():
            detail.append({"critique": "+%s %% critique", "portee_max": "+%s portée", "cout_pa": "coût %s PA",
                           "delai": "relance %s t.", "zone_taille": "zone de taille %s"}.get(k, k + " %s") % v
                          if k != "effets" else "ajoute " + effets(v))
        morceaux.append("rang %s : %s" % (rang, ", ".join(detail)))
    return "<br>".join(morceaux) or "—"


def classes_md():
    voies, races, sorts = charger("voies"), charger("races"), charger("sorts")
    NOMS_SORTS.update({i: s["nom"] for i, s in sorts.items()})
    prog, perso, sort = "character/progression.gd", "character/character.gd", "combat/spell.gd"
    stats_perso = constante(perso, "STATS")
    plafond, plafond_vita = constante(perso, "STAT_CAP"), constante(perso, "VITALITY_CAP")
    bonus_rang = constante(sort, "MASTERY_BONUS_PER_RANK")
    elements_stats = constante("combat/fighter.gd", "ELEMENT_STATS")
    composes = constante(sort, "COMPOSITE_ELEMENTS")
    crit, crit_mult = constante(sort, "DEFAULT_CRIT_CHANCE"), constante(sort, "CRIT_MULTIPLIER")
    etat_max, etat_bonus = constante("combat/fighter.gd", "ELEMENT_STATE_MAX"), constante("combat/fighter.gd", "ELEMENT_STATE_BONUS")
    p = {n: constante(prog, n) for n in ("REPUTATION_PER_PA", "UTILITY_SHARE", "KILL_REPUTATION_PER_TIER", "STAT_PER_PA", "VITALITY_PER_HP",
                                         "MAX_PA_PER_COMBAT", "MAX_HP_PER_COMBAT", "MIN_STAT_PACE")}

    lignes = ["# Classes et races : toutes les variables", "",
              "Généré par `game/tools/equilibrage.py` à partir du code (`core/character/`, `core/combat/`) et",
              "de `game/data/` (`voies/`, `races/`, `sorts/`) : ne pas modifier à la main. Vue d'ensemble pour",
              "l'équilibrage ; règles dans le GDD (§ 4), métiers dans [METIERS.md](METIERS.md), monstres dans",
              "[CATALOGUE.md](CATALOGUE.md).", "",
              "## Principe", "",
              "Pas de niveau (GDD § 4.5) : une classe (Voie) active à la fois, changée hors combat. Chaque classe",
              "a sa réputation et ses points de maîtrise ; les caractéristiques se gagnent par la pratique et",
              "suivent le personnage d'une classe à l'autre. Pas de bonus de caractéristiques de race ni",
              "d'équipement de départ : une race donne un passif et un sort.", "",
              "## Caractéristiques", "",
              "- Gagnées par la pratique : %s ; plafond **%d** par caractéristique (Vitalité %d), le reste vient"
              % (", ".join(CARACS[s] for s in stats_perso), plafond, plafond_vita),
              "  de l'équipement et des panoplies.",
              "- Élément → caractéristique : %s ; %s." % (", ".join("%s → %s" % (ELEMENTS[e], CARACS[s]) for e, s in elements_stats.items()),
                                                          ", ".join("%s = %s + %s" % (ELEMENTS[e], ELEMENTS[a], ELEMENTS[b]) for e, (a, b) in composes.items())),
              "- Puissance d'un élément = sa caractéristique (somme des deux pour un élément composé) + %d par" % etat_bonus,
              "  état élémentaire de cet élément (Arcaniste, %d états au plus)." % etat_max,
              "- **Dégâts** (`Combat.damage_value`) : jet × (100 + puissance) / 100 × (1 + % dégâts infligés)",
              "  × (100 − résistance de la cible) / 100 + Dommages. Soins, boucliers, poisons : jet × (100 + puissance) / 100.",
              "- Critique : %d %% par défaut (+ « critique » du sort et de l'équipement), × %s sur la valeur tirée." % (crit, nombre(crit_mult)),
              "- PV = PV de la Voie + Vitalité ; initiative = celle de la Voie + Force + Intelligence + Perception",
              "  + Agilité + équipement ; prospection = 100 + équipement + passif de race.", ""]
    lignes += section_reputation("classe")
    lignes += ["Une nouvelle classe s'ouvre quand une classe a **%d** de réputation (`NEW_CLASS_REPUTATION`) ;" % constante(perso, "NEW_CLASS_REPUTATION"),
               "elle part de zéro. Maîtrise d'un sort : chaque rang ajoute **%d %%** aux valeurs de base de ses" % bonus_rang,
               "effets élémentaires (dégâts, soins, boucliers, poisons), plus les changements de son champ",
               "`maitrise` aux rangs indiqués (colonne Maîtrise ci-dessous).", "",
               "### Gains d'un combat (`core/character/progression.gd`)", ""]
    lignes += table(["Variable", "Valeur", "Rôle"], [
        ["REPUTATION_PER_PA", nombre(p["REPUTATION_PER_PA"]), "réputation par PA d'un sort à effet réel (dégâts, soin de PV perdus, bouclier qui absorbe)"],
        ["UTILITY_SHARE", nombre(p["UTILITY_SHARE"]), "part pour un sort utilitaire qui touche quelqu'un"],
        ["KILL_REPUTATION_PER_TIER", nombre(p["KILL_REPUTATION_PER_TIER"]), "réputation par palier d'un monstre vaincu, au facteur de difficulté, partagée entre les joueurs"],
        ["STAT_PER_PA", nombre(p["STAT_PER_PA"]), "points de la caractéristique de l'élément par PA à effet réel"],
        ["VITALITY_PER_HP", nombre(p["VITALITY_PER_HP"]), "Vitalité par PV réellement perdu"],
        ["MAX_PA_PER_COMBAT", nombre(p["MAX_PA_PER_COMBAT"]), "PA comptés au plus par combat"],
        ["MAX_HP_PER_COMBAT", nombre(p["MAX_HP_PER_COMBAT"]), "PV perdus comptés au plus par combat"],
        ["MIN_STAT_PACE", nombre(p["MIN_STAT_PACE"]), "rythme minimal près du plafond : × max(%s, 1 − points / plafond)" % nombre(p["MIN_STAT_PACE"])]])
    lignes += ["Tout est multiplié par le facteur de difficulté (somme des paliers des monstres / somme des",
               "paliers de réputation des joueurs, Inconnu compté 1). Exemple : %d PA à effet réel à facteur 1 = %d de réputation et %s"
               % (p["MAX_PA_PER_COMBAT"], p["MAX_PA_PER_COMBAT"] * p["REPUTATION_PER_PA"], nombre(p["MAX_PA_PER_COMBAT"] * p["STAT_PER_PA"])),
               "point(s) de caractéristique (avant ralentissement).", ""]

    lignes += ["## Races", ""]
    lignes += table(["Race", "Camp", "Départ", "Passif", "Effets du passif", "Sort de race"],
                    [["**%s**" % r["nom"], r.get("camp", ""), r.get("carte_depart", ""), r.get("passif", {}).get("nom", "—"),
                      ", ".join("%s %+d" % (e["type"], e["valeur"]) for e in r.get("passif", {}).get("effets", [])),
                      sorts[r["sort"]]["nom"] if r.get("sort") in sorts else "—"] for r in races.values()])
    lignes += table(["Sort de race", "Caractéristiques", "Effets", "Maîtrise"],
                    [["**%s**" % sorts[r["sort"]]["nom"], caracteristiques_sort(sorts[r["sort"]]), effets(sorts[r["sort"]]["effets"]),
                      texte_maitrise(sorts[r["sort"]])] for r in races.values() if r.get("sort") in sorts])

    lignes += ["## Voies", ""]
    lignes += table(["Voie", "PV", "PA", "PM", "Initiative", "Sorts de rang I", "Sorts de rang II"],
                    [["**%s**" % v["nom"]] + [v["caracteristiques"].get(k, 0) for k in ("pv", "pa", "pm", "initiative")]
                     + [len(v["sorts"]), len(v.get("sorts_rang_2", {}))] for v in voies.values()])
    lignes += ["Colonnes des sorts : *Moy.* = valeurs moyennes de base des dégâts, soins et boucliers directs (hors",
               "horloge, glyphe et piège) ; *Moy./PA* ; *Rang %d* = moyenne avec +%d %% de maîtrise. À multiplier par"
               % (RANG_MAX, bonus_rang * RANG_MAX), "(100 + puissance) / 100 en combat.", ""]
    for v in voies.values():
        lignes += ["### %s" % v["nom"], "", "*%s*" % v.get("description", ""), ""]
        ids = [(i, "I") for i in v["sorts"]] + [(i, "II (%d rép.)" % r) for i, r in v.get("sorts_rang_2", {}).items()]
        crees = {c: "+".join(ELEMENTS.get(x, x) for x in k.split("+")) for i, _ in ids for e in sorts[i]["effets"]
                 if e["type"] == "creer_sort" for k, c in e["combinaisons"].items()}
        ids += [(i, "créé (%s)" % k) for i, k in crees.items() if i in sorts]
        rangs = []
        for i, rang in ids:
            s = sorts[i]
            moy = moyennes(s["effets"])

            def texte(facteur):
                return ", ".join("%s %s" % (nombre(v * facteur), k) for k, v in moy.items()) or "—"
            rangs.append(["**%s**" % s["nom"], rang, caracteristiques_sort(s), effets(s["effets"]), texte(1),
                          texte(1 / s["cout_pa"]) if s["cout_pa"] else "—", texte(1 + bonus_rang * RANG_MAX / 100), texte_maitrise(s)])
        lignes += table(["Sort", "Rang", "Caractéristiques", "Effets", "Moy.", "Moy./PA", "Rang %d" % RANG_MAX, "Maîtrise"], rangs)
    return lignes


def main():
    for nom, lignes in (("METIERS.md", metiers_md()), ("CLASSES.md", classes_md())):
        with open(os.path.join(DOCS, nom), "w", encoding="utf-8") as f:
            f.write("\n".join(lignes).rstrip() + "\n")
        print("docs/%s : %d lignes" % (nom, len(lignes)))


if __name__ == "__main__":
    main()
