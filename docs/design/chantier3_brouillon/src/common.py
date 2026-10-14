"""Aides communes : calcul des monstres, sorts et objets d'après le modèle d'équilibrage."""
from balance import pv_monstre, stat_monstre, xp_monstre, ecus as ecus_ref, budget_objet

POIDS = {"faible": [6, 3, 1], "moyen": [3, 4, 3], "fort": [1, 3, 6]}
# gabarit : (multiplicateur PV, multiplicateur XP et écus)
GABARITS = {"frele": (0.8, 0.85), "standard": (1.0, 1.0), "costaud": (1.3, 1.2),
            "tank": (1.7, 1.3), "tireur": (0.85, 0.95), "soutien": (0.9, 1.05)}

SPELLS = {}      # id -> json complet (nouveaux sorts)
REUSED = set()   # sorts existants réutilisés


def sort(id, nom, description, cout_pa, portee, effets, relance=None, zone=None, ldv=True,
         en_ligne=False, lanceur_exclu=False, critique=None):
    d = {"id": id, "nom": nom, "description": description, "cout_pa": cout_pa,
         "portee": {"min": portee[0], "max": portee[1]}, "ligne_de_vue": ldv}
    if en_ligne:
        d["lancer_en_ligne"] = True
    if zone:
        d["zone"] = zone
    if lanceur_exclu:
        d["lanceur_exclu"] = True
    d["relance"] = relance or {"par_tour": 1}
    if critique is not None:
        d["critique"] = critique
    d["effets"] = effets
    assert id not in SPELLS, id
    SPELLS[id] = d
    return id


def dg(element, mn, mx, cibles=None):
    e = {"type": "degats", "element": element, "min": mn, "max": mx}
    if cibles: e["cibles"] = cibles
    return e


def soin(element, mn, mx, cibles=None):
    e = {"type": "soin", "element": element, "min": mn, "max": mx}
    if cibles: e["cibles"] = cibles
    return e


def bouclier(element, mn, mx, cibles=None):
    e = {"type": "bouclier", "element": element, "min": mn, "max": mx}
    if cibles: e["cibles"] = cibles
    return e


def bonus(carac, mn, mx, duree, element=None, cibles=None, malus=False):
    e = {"type": "malus" if malus else "bonus", "carac": carac, "min": mn, "max": mx, "duree": duree}
    if element: e["element"] = element
    if cibles: e["cibles"] = cibles
    return e


def malus(carac, mn, mx, duree, element=None, cibles=None):
    return bonus(carac, mn, mx, duree, element, cibles, malus=True)


def poison(element, mn, mx, duree, cibles=None):
    e = {"type": "poison", "element": element, "min": mn, "max": mx, "duree": duree}
    if cibles: e["cibles"] = cibles
    return e


def simple(type_, mn, mx, cibles=None):
    e = {"type": type_, "min": mn, "max": mx}
    if cibles: e["cibles"] = cibles
    return e


def glyphe(duree, effets):
    return {"type": "glyphe", "duree": duree, "effets": effets}


def piege(effets, zone=None):
    e = {"type": "piege", "effets": effets}
    if zone: e["zone"] = zone
    return e


def ligne_sorts(ids):
    out = []
    for i in ids:
        if i in SPELLS:
            out.append({"id": i, "nouveau": True, "json": SPELLS[i]})
        else:
            REUSED.add(i)
            out.append({"id": i, "nouveau": False})
    return out


def famille(id, nom, description, palier, role, gabarit, pa, pm, initiative, elements, resistances, sorts, ia,
            butin, art, elite, existante=False, pv=None, pv_pn=None, xp=None, xp_pn=None, ecus=None,
            stats_base=None, stats_pn=None, res_pn=None, init_pn=5, modifications=None, notes=None):
    a, b = palier
    gpv, gxp = GABARITS[gabarit]
    base_pv = pv if pv is not None else round(pv_monstre(a) * gpv)
    pn_pv = pv_pn if pv_pn is not None else max(2, round((pv_monstre(b) - pv_monstre(a)) / max(1, b - a) * gpv))
    base_xp = xp if xp is not None else round(xp_monstre(a) * gxp)
    pn_xp = xp_pn if xp_pn is not None else round((xp_monstre(b) - xp_monstre(a)) / max(1, b - a) * gxp)
    carac = {"pv": base_pv, "pa": pa, "pm": pm, "initiative": initiative}
    par = {"pv": pn_pv, "initiative": init_pn, "xp": pn_xp}
    for stat, share in elements.items():
        sb = (stats_base or {}).get(stat, round(stat_monstre(a) * share))
        if sb:
            carac[stat] = sb
        par[stat] = (stats_pn or {}).get(stat, max(1, round(4 * share)))
    if res_pn:
        par["resistances"] = res_pn
    if ecus is None:
        mid = (a + b) // 2
        lo, hi = ecus_ref(mid)
        ecus = [max(1, round(lo * gxp)), round(hi * gxp)]
    m = {"id": id, "nom": nom, "description": description, "niveau": a}
    if b > a:
        m["niveaux"] = {"min": a, "max": b, "poids": POIDS[role] if b - a == 2 else [1] * (b - a + 1)}
    m.update({"caracteristiques": carac, "par_niveau": par, "resistances": resistances,
              "sorts": [s for s in sorts], "ia": ia, "xp": base_xp, "butin": butin, "ecus": ecus})
    fam = {"id": id, "nom": nom, "description": description, "palier": f"{a}-{b}", "role": role,
           "gabarit": gabarit, "existante": existante,
           "niveaux": m.get("niveaux", {"min": a, "max": b, "poids": [1]}),
           "caracteristiques": carac, "par_niveau": par, "resistances": resistances,
           "sorts": ligne_sorts(sorts), "ia": ia, "xp": base_xp, "ecus": ecus, "butin": butin, "art": art,
           "json": m}
    if modifications:
        fam["modifications_existant"] = modifications
    if notes:
        fam["notes"] = notes
    e = dict(elite)
    e.setdefault("famille", id)
    fam["elite"] = construire_elite(e, fam, palier, gabarit)
    return fam


def construire_elite(e, fam, palier, gabarit):
    a, b = palier
    gpv, gxp = GABARITS[gabarit]
    lvl = e.get("niveau", b + 3)
    base = fam["caracteristiques"]
    pv = e.get("pv") or max(2 * base["pv"] + 4, round(pv_monstre(lvl) * gpv * 2.0))
    carac = {"pv": pv, "pa": e.get("pa", base["pa"] + 1), "pm": e.get("pm", base["pm"]),
             "initiative": e.get("initiative", base["initiative"] + 30)}
    for stat in ("force", "intelligence", "chance", "agilite"):
        if stat in fam["par_niveau"]:
            share = fam["par_niveau"][stat] / 4
            carac[stat] = e.get("stats", {}).get(stat, round(stat_monstre(lvl) * share) + 10)
    xp = e.get("xp") or round(xp_monstre(lvl) * gxp * 1.8)
    lo, hi = fam["ecus"]
    ecus = e.get("ecus") or [round(lo * 2.5), round(hi * 2.5)]
    butin = e.get("butin")
    if butin is None:
        butin = []
        for d in fam["butin"]:
            nd = dict(d)
            q = d.get("quantite", [1, 1])
            r = d["taux"]
            if r >= 0.3:
                nd["taux"] = min(0.9, round(r * 1.6, 2))
                nd["quantite"] = [q[0] + 1, q[1] + 2]
            else:
                nd["taux"] = min(0.6, round(max(r * 4, r + 0.1), 2))
                if q != [1, 1]:
                    nd["quantite"] = q
                else:
                    nd.pop("quantite", None)
            butin.append(nd)
        butin += e.get("butin_extra", [])
    res = e.get("resistances") or {k: v + 10 if v >= 0 else v + 5 for k, v in fam["resistances"].items()}
    m = {"id": e["id"], "nom": e["nom"], "description": e["description"], "famille": fam["id"], "elite": True,
         "niveau": lvl, "caracteristiques": carac, "resistances": res, "sorts": e["sorts"],
         "ia": e.get("ia", fam["ia"]), "xp": xp, "butin": butin, "ecus": ecus}
    return {"id": e["id"], "nom": e["nom"], "description": e["description"], "niveau": lvl,
            "existante": e.get("existante", False), "caracteristiques": carac, "resistances": res,
            "sorts": ligne_sorts(e["sorts"]), "ia": m["ia"], "xp": xp, "ecus": ecus, "butin": butin,
            "art": e["art"], "json": m, **({"modifications_existant": e["modifications"]} if e.get("modifications") else {})}


def drop(objet, taux, quantite=None):
    d = {"objet": objet, "taux": taux}
    if quantite:
        d["quantite"] = quantite
    return d


# ---------- objets ----------
OBJETS = {}
POIDS_STAT = {"force": 1, "intelligence": 1, "chance": 1, "agilite": 1, "vitalite": 0.5, "sagesse": 1,
              "prospection": 0.25, "initiative": 0.1, "dommages": 4, "portee": 15, "pa": 30, "pm": 25, "critique": 2}
ARME_MULT = {"commun": 1, "peu_commun": 1.08, "rare": 1.16, "epique": 1.25, "legendaire": 1.35}


def ressource(id, nom, rarete, description, source, icone):
    o = {"id": id, "nom": nom, "type": "ressource", "rarete": rarete, "niveau": 1, "description": description,
         "source": source, "icone": icone}
    assert id not in OBJETS, id
    OBJETS[id] = o
    return id


def equipement(id, nom, type_, rarete, niveau, description, repartition, source, icone, conditions=None,
               attaque=None, fixe=None, boutique=True):
    """repartition : {stat: part du budget}. fixe : {stat: [min,max]} imposé."""
    budget = budget_objet(niveau, rarete) * (0.6 if type_ == "arme" else 1.0)
    bonus_ = {}
    for stat, part in repartition.items():
        v = budget * part / POIDS_STAT[stat]
        lo, hi = max(1, round(v * 0.8)), max(1, round(v * 1.15))
        if stat in ("pa", "pm", "portee"):
            lo = hi = max(1, round(v))
        bonus_[stat] = [lo, hi]
    if fixe:
        bonus_.update(fixe)
    o = {"id": id, "nom": nom, "type": type_, "rarete": rarete, "niveau": niveau, "description": description,
         "bonus": bonus_}
    if conditions:
        o["conditions"] = conditions
    if attaque:
        o["attaque"] = attaque
    o["source"] = source
    o["icone"] = icone
    if not boutique:
        o["boutique"] = False
    assert id not in OBJETS, id
    OBJETS[id] = o
    return id


def attaque(niveau, rarete, element, cout_pa, portee, par_tour=1, ldv=True, zone=None, extra=None, en_ligne=False):
    moy = (2.2 + 0.08 * niveau) * ARME_MULT[rarete] * cout_pa
    a = {"cout_pa": cout_pa, "portee": {"min": portee[0], "max": portee[1]}}
    if not ldv:
        a["ligne_de_vue"] = False
    if en_ligne:
        a["lancer_en_ligne"] = True
    if zone:
        a["zone"] = zone
        moy *= 0.75
    a["relance"] = {"par_tour": par_tour}
    a["effets"] = [{"type": "degats", "element": element, "min": round(moy * 0.8), "max": round(moy * 1.2)}] + (extra or [])
    return a
