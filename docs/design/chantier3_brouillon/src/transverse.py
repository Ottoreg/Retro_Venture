"""Sections transverses : résumé, objets, équilibrage, dessins, lots de production."""
import balance
from common import OBJETS, SPELLS, REUSED

TYPES = ["arme", "coiffe", "cape", "amulette", "anneau", "ceinture", "bottes", "ressource"]
ABR = {"force": "For", "intelligence": "Int", "perception": "Per", "agilite": "Agi", "vitalite": "Vit", "sagesse": "Sag",
       "prospection": "Pro", "initiative": "Ini", "dommages": "Dom", "portee": "PO", "pa": "PA", "pm": "PM", "critique": "Crit"}
PLURIEL = {"arme": "armes", "coiffe": "coiffes", "cape": "capes", "amulette": "amulettes", "anneau": "anneaux",
           "ceinture": "ceintures", "bottes": "bottes", "ressource": "ressources"}
RAR = {"commun": "commun", "peu_commun": "peu commun", "rare": "rare", "epique": "épique", "legendaire": "légendaire"}
ELEM = {"acier": "Acier", "flamme": "Flamme", "givre": "Givre", "tempete": "Tempête", "sacre": "Sacré", "impie": "Impie"}


def _zones():
    import build
    return build.zones, build.extra


def proprietaires():
    """id de monstre -> lot (id de zone ou « variantes »)."""
    zones, extra = _zones()
    out = {}
    for z in zones:
        for f in z["familles"]:
            out[f["id"]] = z["id"]; out[f["elite"]["id"]] = z["id"]
        if z.get("boss"):
            out[z["boss"]["json"]["id"]] = z["id"]
    for v in (extra["variantes"].VARIANTES if extra["variantes"] else []):
        out[v["json"]["id"]] = "variantes"
    return out


def lot_objet(o):
    """Lot du premier monstre cité dans la source (« butin:a|boss:b » → lot de a)."""
    kind, _, who = o["source"].split("|")[0].partition(":")
    if kind in ("butin", "boss"):
        return proprietaires().get(who.split()[0], "variantes" if who.startswith("variantes") else "?")
    return "metiers"


def _bonus(o):
    return ", ".join(f"{ABR[k]} {v[0]}" + (f"–{v[1]}" if v[1] != v[0] else "") for k, v in o.get("bonus", {}).items())


def _attaque(o):
    a = o.get("attaque")
    if not a:
        return ""
    d = a["effets"][0]
    po = a["portee"]
    return f" ; attaque {a['cout_pa']} PA, PO {po['min']}–{po['max']}, {d['min']}–{d['max']} {ELEM[d['element']]}"


def objets_md():
    L = ["## 8. Objets", "",
         f"{len(OBJETS)} nouveaux objets : " + ", ".join(f"{sum(1 for o in OBJETS.values() if o['type'] == t)} {PLURIEL[t]}" for t in TYPES) + ". "
         "Les bonus suivent le budget `(3 + 0,8 × niveau) × rareté` (commun 1 ; peu commun 1,2 ; rare 1,45 ; épique 1,8 ; légendaire 2,2), "
         "pondéré par stat (Vitalité 0,5 ; Prospection 0,25 ; Initiative 0,1 ; Dommages 4 ; Critique 2) ; les armes prennent 60 % du budget, le reste est dans l'attaque. "
         "Chaque objet a besoin d'une icône (description dans le JSON, champ `icone`).", ""]
    for t in TYPES:
        objs = sorted((o for o in OBJETS.values() if o["type"] == t), key=lambda o: (o["niveau"], o["id"]))
        if not objs:
            continue
        L += [f"### 8.{TYPES.index(t) + 1} {PLURIEL[t].capitalize()} ({len(objs)})", ""]
        if t == "ressource":
            L += ["| Ressource | Rareté | Source |", "|---|---|---|"]
            for o in objs:
                L.append(f"| {o['nom']} (`{o['id']}`) | {RAR[o['rarete']]} | {o['source']} |")
        else:
            L += ["| Objet | Niv. | Rareté | Bonus | Source |", "|---|---|---|---|---|"]
            for o in objs:
                L.append(f"| {o['nom']} (`{o['id']}`) | {o['niveau']} | {RAR[o['rarete']]} | {_bonus(o)}{_attaque(o)} | {o['source']} |")
        L.append("")
    return "\n".join(L)


def equilibrage_md():
    j = {x["niveau"]: x for x in balance.joueurs}
    m = {x["niveau"]: x for x in balance.monstres}
    total = sum(balance.minutes_niveau(n) for n in range(1, 30)) / 60
    depart = sum(balance.minutes_niveau(n) for n in range(1, 12)) / 60
    combats_depart = sum(balance.minutes_niveau(n) / balance.minutes_combat(n) for n in range(1, 12))
    combats_haut = sum(balance.minutes_niveau(n) / balance.minutes_combat(n) for n in range(12, 30))
    L = ["## 10. Récapitulatif d'équilibrage", "",
         "Référence : un joueur seul contre un groupe de 2 monstres de son niveau. Le combat dure `2 + niveau/10` tours du joueur "
         "et lui coûte environ 40 % de ses PV. Formules dans `src/balance.py`.", "",
         "| Niv. | XP pour passer | PV joueur | Carac. principale | Dégâts joueur / tour | PV monstre | Dégâts / sort monstre | XP monstre | Écus | Combats pour le niveau |",
         "|---|---|---|---|---|---|---|---|---|---|"]
    for n in (1, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30):
        a, b = j[n], m[n]
        L.append(f"| {n} | {a['xp_pour_suivant'] or '—'} | {a['pv']} | {a['carac_principale']} | {a['degats_par_tour']} | {b['pv']} | "
                 f"{b['degats_moyens_par_sort']} | {b['xp']} | {b['ecus'][0]}–{b['ecus'][1]} | {a['combats_pour_ce_niveau'] or '—'} |")
    L += ["",
          f"- **Durée visée** : {total:.1f} h de combat du niveau 1 au niveau 30, dont {depart:.1f} h dans la zone de départ (1 → 12, "
          f"~{combats_depart:.0f} combats) et ~{combats_haut:.0f} combats dans Hautepierre (12 → 30).",
          f"- **Alpha 1** : l'XP de combat est multipliée par {balance.XP_ALPHA} (`Character.XP_RATE`) ; tout le contenu (1 → 30) "
          f"se fait alors en ~{total / balance.XP_ALPHA:.1f} h de combat, ~4 à 5 h avec les déplacements. On revient à ×1 "
          "(~15 h pour les 30 premiers niveaux) quand on testera la vraie progression.",
          "- **Élites** : niveau = max de la famille + 3, PV ≥ 2× la base, XP × 1,8, brumes × 2,5, butin plus fréquent ; "
          "**mini-boss** : groupe fixe, réapparition en 60 s au plus (alpha : on doit pouvoir retester ses mécaniques), 2 ou 3 phases "
          "de profils différents tirés de son thème (agressif, défensif, mobilité, contrôle), **jamais de soin** à un changement de phase "
          "(risque de combat sans fin), trophée de recette.",
          "- **Variantes corrompues** : +10 % d'XP, éléments Flamme, apparaissent après le mini-boss de leur zone (voir §7).",
          "- **À valider en jeu** : la durée réelle des combats (le modèle suppose 70 % de coups portés) et la vitesse de progression de chaque race, "
          "puisque les paliers sont asymétriques entre zones.", ""]
    return "\n".join(L)


def dessins():
    zones, extra = _zones()
    out = []
    for z in zones:
        for f in z["familles"]:
            out.append((z["id"], f["nom"], f["art"])); out.append((z["id"], f["elite"]["nom"], f["elite"]["art"]))
        if z.get("boss"):
            out.append((z["id"], z["boss"]["json"]["nom"], z["boss"]["art"]))
    for v in (extra["variantes"].VARIANTES if extra["variantes"] else []):
        out.append(("variantes", v["json"]["nom"], v.get("art", {})))
    return out


def dessins_md():
    arts = dessins()
    nouveaux = [(z, n, a) for z, n, a in arts if a.get("nouveau_svg")]
    L = ["## 11. Dessins à faire", "",
         f"- **{len(nouveaux)} nouveaux dessins** de monstres, armes ou accessoires (liste ci-dessous) ; les {len(arts) - len(nouveaux)} autres monstres "
         "réutilisent un rig ou une image existante (recoloration, échelle, accessoires) décrits dans leur fiche.",
         f"- **{len(OBJETS)} icônes d'objets** (une par nouvel objet, description dans le JSON).",
         "- **Ressources de récolte** : aucun nouveau dessin, recoloration de `arbre_haut`, `arbre_large` et `minerai` (§9).",
         "- **Décors des cartes** : réutilisation des décors existants, recolorés par la palette de zone ; les éléments propres à une carte sont décrits dans son « Plan ».", "",
         "| Zone | Pour | Dessin |", "|---|---|---|"]
    for z, n, a in nouveaux:
        L.append(f"| {z} | {n} | {a['nouveau_svg']} |")
    L.append("")
    return "\n".join(L)


def lots_md():
    zones, extra = _zones()
    prop = proprietaires()
    import build
    mons_json = {j["id"]: j for j in build.all_monsters_json()}
    arts = dessins()
    lignes = []
    for lot in [z["id"] for z in zones] + ["variantes", "metiers"]:
        mons = [k for k, v in prop.items() if v == lot]
        sorts = set()
        for k in mons:
            j = mons_json[k]
            sorts |= {s for s in j.get("sorts", []) if s in SPELLS}
            for p in j.get("phases", []):
                sorts |= {s for s in p.get("sorts", []) if s in SPELLS}
        objs = [i for i, o in OBJETS.items() if lot_objet(o) == lot]
        cartes = [c for z in zones if z["id"] == lot for c in z["cartes"] if not c.get("existante")]
        svg = sum(1 for zz, _, a in arts if zz == lot and a.get("nouveau_svg"))
        lignes.append((lot, len(cartes), len(mons), len(sorts), len(objs), svg))
    L = ["## 12. Lots de production", "",
         "Chaque lot ne touche que ses propres fichiers : `game/data/<type>/<id>.json` pour ses ids, son fragment d'images "
         "`game/art/manifestes/<lot>.json`, ses dessins et ses icônes. Les lots de zone peuvent donc avancer en parallèle ; "
         "variantes et métiers viennent après, car ils réutilisent les butins des zones.", "",
         "| Lot | Cartes nouvelles | Monstres | Sorts nouveaux | Objets | Dessins nouveaux | Dépend de |", "|---|---|---|---|---|---|---|"]
    dep = {"variantes": "lots de zone", "metiers": "lots de zone + variantes"}
    for lot, c, m, s, o, d in lignes:
        L.append(f"| {lot} | {c} | {m} | {s} | {o} | {d} | {dep.get(lot, '—')} |")
    L += ["",
          "Ordre proposé :",
          "1. **Lots de zone** Brumerive, Crasse-Roc, Sylvebrume, puis Hautepierre (le plus gros : on peut le couper en deux, cartes et ville d'un côté, monstres et boss de l'autre).",
          "2. **Variantes et métiers** (ressources, nœuds de récolte, recettes, sources des panoplies).",
          "3. **Intégration** : tests de chargement des données, combat simulé par palier pour vérifier le modèle d'équilibrage, captures d'écran, GDD, TODO et guide des testeurs.",
          f"\nLes {len(REUSED)} sorts existants réutilisés ne sont pas modifiés.", ""]
    return "\n".join(L)


def intro_md():
    zones, extra = _zones()
    import build
    mons = build.all_monsters_json()
    nb_cartes = sum(len(z["cartes"]) for z in zones)
    nb_nouvelles = sum(1 for z in zones for c in z["cartes"] if not c.get("existante"))
    arts = dessins()
    L = ["# Chantier 3 — Contenu du monde", "",
         "Document de conception, généré par `src/build.py` (contrôle de cohérence : `src/controle.py`). Brouillon à valider avant toute production.", "",
         "## 1. Résumé", "",
         f"- **{nb_cartes} cartes** ({nb_nouvelles} nouvelles), **{len(mons)} monstres** (familles, élites, mini-boss, variantes), "
         f"**{len(SPELLS)} sorts nouveaux** ({len(REUSED)} réutilisés), **{len(OBJETS)} objets**, "
         f"**{sum(1 for _, _, a in arts if a.get('nouveau_svg'))} nouveaux dessins** et {len(OBJETS)} icônes.", "",
         "| Zone | Cartes | Niveaux | Familles par palier | Mini-boss |", "|---|---|---|---|---|"]
    for z in zones:
        pals = {}
        for f in z["familles"]:
            pals.setdefault(f["palier"], []).append(f["nom"])
        fam = " ; ".join(f"{p} : {', '.join(n)}" for p, n in sorted(pals.items(), key=lambda kv: int(kv[0].split('-')[0])))
        lv = [f["niveaux"]["min"] for f in z["familles"]] + [f["niveaux"]["max"] for f in z["familles"]]
        b = z.get("boss")
        boss = f"{b['json']['nom']} (niv. {b['json']['niveau']})" if b else "—"
        L.append(f"| {z['nom']} | {len(z['cartes'])} | {min(lv)}–{max(lv)} | {fam} | {boss} |")
    v = extra["variantes"]
    if v:
        L.append(f"| Variantes corrompues | — | — | " + ", ".join(x["json"]["nom"] for x in v.VARIANTES) + " | — |")
    L += ["",
          "**Ce que le joueur vit.** Chaque race commence dans sa zone (1 → 12) : quatre paliers de familles, une élite par famille, "
          "un mini-boss au bout, puis des variantes corrompues. Vers le niveau 12, il rejoint Hautepierre (13 → 30) : la ville, "
          "ses environs et le boss Grondin. Les nouveaux métiers (if, hêtre, malorme ; étain, argent, obsidienne) et les recettes "
          "demandent des butins de plusieurs zones, ce qui pousse à voyager.", "",
          "## 2. Règles suivies", "",
          "- Paliers 1–3 / 4–6 / 7–9 / 10–12 dans chaque zone de départ, asymétriques entre zones ; niveau variable dans une famille, pondéré (faible 6/3/1, moyen 3/4/3, fort 1/3/6).",
          "- Le niveau d'un monstre change ses stats, pas son butin ; PA/PM fixes par famille sauf mécanique spéciale.",
          "- Élites : niveau > max de la famille, PV ≥ 2× la base, butin non commun plus fréquent.",
          "- Formats de données : ceux de `game/data/README.md` ; ids nouveaux sans collision avec `game/data` (vérifié par `src/controle.py`).", ""]
    return "\n".join(L)


def MARKDOWN():
    return objets_md()


def FIN():
    return "\n".join([equilibrage_md(), dessins_md(), lots_md()])
