"""Assemble le document Markdown et le JSON du chantier 3 à partir des modules de zone."""
import importlib, json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
import balance, common
from common import SPELLS, OBJETS

OUT = os.path.join(os.path.dirname(__file__), "..")
ZONE_MODULES = ["brumerive", "crasse_roc", "sylvebrume", "hautepierre"]
zones = []
for name in ZONE_MODULES:
    try:
        zones.append(importlib.import_module(name).ZONE)
    except ModuleNotFoundError:
        pass
extra = {}
for name in ["variantes", "metiers", "transverse"]:
    try:
        extra[name] = importlib.import_module(name)
    except ModuleNotFoundError:
        extra[name] = None

ELEM = {"acier": "Acier", "flamme": "Flamme", "givre": "Givre", "tempete": "Tempête", "sacre": "Sacré", "impie": "Impie"}
CARAC = {"force": "For", "intelligence": "Int", "chance": "Cha", "agilite": "Agi", "pa": "PA", "pm": "PM",
         "portee": "Portée", "dommages": "Dommages", "critique": "% Crit", "resistance": "Rés."}
STAT_FR = {"force": "Force", "intelligence": "Intelligence", "chance": "Chance", "agilite": "Agilité", "vitalite": "Vitalité",
           "sagesse": "Sagesse", "prospection": "Prospection", "initiative": "Initiative", "dommages": "Dommages",
           "portee": "Portée", "pa": "PA", "pm": "PM", "critique": "% Critique"}
RARETE = {"commun": "commun", "peu_commun": "peu commun", "rare": "rare", "epique": "épique", "legendaire": "légendaire"}


def effet_txt(e):
    t = e["type"]
    c = {"ennemis": " (ennemis)", "allies": " (alliés)"}.get(e.get("cibles", ""), "")
    if t == "degats":
        return f"{e['min']}–{e['max']} {ELEM[e['element']]}{c}"
    if t in ("soin", "bouclier"):
        return f"{t} {ELEM[e['element']]} {e['min']}–{e['max']}{c}"
    if t in ("bonus", "malus"):
        el = f" {ELEM[e['element']]}" if e.get("element") else ""
        v = f"{e['min']}" if e['min'] == e['max'] else f"{e['min']}–{e['max']}"
        return f"{'+' if t == 'bonus' else '−'}{v} {CARAC[e['carac']]}{el} ({e['duree']} t){c}"
    if t == "poison":
        return f"poison {ELEM[e['element']]} {e['min']}–{e['max']} ({e['duree']} t){c}"
    if t in ("poussee", "attirance"):
        return f"{t} {e['min']}" + (f"–{e['max']}" if e['max'] != e['min'] else "")
    if t == "retrait_pm":
        return f"−{e['min']} PM (tour suivant)"
    if t == "gain_pa":
        return f"+{e['min']} PA"
    if t == "glyphe":
        return f"glyphe {e['duree']} t : " + ", ".join(effet_txt(x) for x in e["effets"])
    if t == "piege":
        z = e.get("zone", {"type": "case"})
        zz = f" (cercle {z['taille']})" if z["type"] == "cercle" else ""
        return "piège" + zz + " : " + ", ".join(effet_txt(x) for x in e["effets"])
    return t


def sort_txt(sid):
    s = SPELLS.get(sid)
    if not s:
        return f"`{sid}` (existant)"
    z = s.get("zone", {"type": "case"})
    zt = "" if z["type"] == "case" else (f", cercle {z['taille']}" if z["type"] == "cercle" else ", croix latine")
    po = s["portee"]
    p = f"{po['min']}–{po['max']}" if po["max"] != po["min"] else f"{po['min']}"
    flags = []
    if not s.get("ligne_de_vue", True): flags.append("sans ldv")
    if s.get("lancer_en_ligne"): flags.append("en ligne")
    if s.get("lanceur_exclu"): flags.append("lanceur exclu")
    r = s.get("relance", {})
    rel = f"{r.get('par_tour', 0)}/tour" + (f", délai {r['delai']}" if r.get("delai") else "")
    f = (", " + ", ".join(flags)) if flags else ""
    return f"**{s['nom']}** (`{sid}`, nouveau) : {s['cout_pa']} PA, portée {p}{zt}{f}, {rel} — " + " ; ".join(effet_txt(e) for e in s["effets"]) + f". *{s['description']}*"


def butin_txt(b):
    out = []
    for d in b:
        q = d.get("quantite")
        qq = f" ×{q[0]}–{q[1]}" if q else ""
        out.append(f"{d['objet']} {round(d['taux'] * 100, 1):g} %{qq}")
    return ", ".join(out)


def res_txt(r):
    return ", ".join(f"{ELEM[k]} {v:+d}" for k, v in r.items()) or "—"


def carac_txt(c):
    order = ["pv", "pa", "pm", "initiative", "force", "intelligence", "chance", "agilite"]
    names = {"pv": "PV", "pa": "PA", "pm": "PM", "initiative": "Ini", "force": "For", "intelligence": "Int", "chance": "Cha", "agilite": "Agi"}
    return ", ".join(f"{names[k]} {c[k]}" for k in order if k in c)


def pn_txt(p):
    out = []
    for k, v in p.items():
        if k == "resistances":
            out.append("rés. " + ", ".join(f"{ELEM[e]} +{x}" for e, x in v.items()))
        else:
            out.append(f"{k} +{v}")
    return ", ".join(out)


def art_txt(a):
    m = a.get("manifeste", {})
    base = f"rig `{m['rig']}`" if "rig" in m else f"image `{m.get('image')}`"
    extras = []
    if m.get("echelle"): extras.append(f"échelle {m['echelle']}")
    if m.get("teinte"): extras.append(f"teinte #{m['teinte']}")
    if m.get("arme"): extras.append(f"arme {m['arme']}")
    if m.get("accessoires"): extras.append("accessoires " + ", ".join(m["accessoires"]))
    if m.get("couleurs"): extras.append("couleurs " + ", ".join(f"{k} #{v}" for k, v in m["couleurs"].items()))
    s = base + (" (" + " ; ".join(extras) + ")" if extras else "")
    if a.get("nouveau_svg"):
        s += f". **Nouveau dessin** : {a['nouveau_svg']}"
    return s


def niveau_range(f):
    n = f["niveaux"]
    return f"{n['min']}–{n['max']} (poids {'/'.join(str(x) for x in n['poids'])})"


def md_famille(f):
    L = []
    tag = " *(existante, retouchée)*" if f.get("existante") else ""
    L.append(f"#### {f['nom']} (`{f['id']}`){tag} — palier {f['palier']}, famille {f['role']}, gabarit {f['gabarit']}")
    L.append(f"*{f['description']}*")
    L.append("")
    L.append(f"- Niveaux {niveau_range(f)} ; base (niv. {f['niveaux']['min']}) : {carac_txt(f['caracteristiques'])} ; par niveau : {pn_txt(f['par_niveau'])}.")
    L.append(f"- Résistances : {res_txt(f['resistances'])} ; IA `{f['ia']}` ; XP {f['xp']} (+{f['par_niveau']['xp']}/niv.) ; écus {f['ecus'][0]}–{f['ecus'][1]}.")
    L.append("- Sorts : " + " ".join("\n  - " + sort_txt(s["id"]) for s in f["sorts"]))
    L.append(f"- Butin : {butin_txt(f['butin'])}.")
    L.append(f"- Dessin : {art_txt(f['art'])}.")
    if f.get("modifications_existant"):
        L.append(f"- Modifications du fichier existant : {f['modifications_existant']}")
    if f.get("notes"):
        L.append(f"- Note : {f['notes']}")
    e = f["elite"]
    tag = " *(existante)*" if e.get("existante") else ""
    L.append(f"- **Élite : {e['nom']}** (`{e['id']}`){tag}, niveau {e['niveau']} — *{e['description']}* {carac_txt(e['caracteristiques'])} ; rés. {res_txt(e['resistances'])} ; XP {e['xp']} ; écus {e['ecus'][0]}–{e['ecus'][1]}.")
    new = [s["id"] for s in e["sorts"] if s["nouveau"] and s["id"] not in [x["id"] for x in f["sorts"]]]
    L.append("  - Sorts : " + ", ".join(f"`{s['id']}`" for s in e["sorts"]) + ("".join("\n  - " + sort_txt(i) for i in new)))
    L.append(f"  - Butin : {butin_txt(e['butin'])}.")
    L.append(f"  - Dessin : {art_txt(e['art'])}.")
    if e.get("modifications_existant"):
        L.append(f"  - Modifications : {e['modifications_existant']}")
    L.append("")
    return "\n".join(L)


def md_boss(b):
    j = b["json"]
    L = [f"#### Mini-boss : {j['nom']} (`{j['id']}`) — niveau {j['niveau']}, carte `{b['carte']}`",
         f"*{j['description']}*", "",
         f"- {carac_txt(j['caracteristiques'])} ; rés. {res_txt(j['resistances'])} ; IA `{j['ia']}` ; XP {j['xp']} ; écus {j['ecus'][0]}–{j['ecus'][1]}.",
         f"- Groupe fixe : {', '.join(b['groupe'])} ; réapparition {b['reapparition'][0]}–{b['reapparition'][1]} s.",
         "- Sorts : " + "".join("\n  - " + sort_txt(s["id"]) for s in b["sorts"])]
    L.append("- Phases :")
    for p in j["phases"]:
        parts = []
        if p.get("sorts"): parts.append("apprend " + ", ".join(f"`{s}`" for s in p["sorts"]))
        if p.get("effets"): parts.append("sur lui : " + " ; ".join(effet_txt(e) for e in p["effets"]))
        L.append(f"  - **{p['pv']} %** — « {p['message']} » — " + " ; ".join(parts))
    L.append(f"- Butin : {butin_txt(j['butin'])}.")
    L.append(f"- Dessin : {art_txt(b['art'])}.")
    if b.get("equilibrage"):
        L.append(f"- Équilibrage : {b['equilibrage']}")
    L.append("")
    return "\n".join(L)


def md_carte(c):
    sorties = ", ".join(f"{k} → `{v}`" for k, v in c["sorties"].items())
    if c.get("portes"):
        sorties += " ; portes : " + ", ".join(f"`{p}`" for p in c["portes"])
    res = ", ".join(f"{k}×{v}" for k, v in c.get("ressources", {}).items()) or "—"
    grp = []
    for g in c["groupes"]:
        if "monstres" in g:
            s = " + ".join(g["monstres"])
        else:
            s = f"{g['nombre'][0]}–{g['nombre'][1]} parmi {{{', '.join(g['parmi'])}}}"
        if g.get("reapparition"):
            s += f" (réapparition {g['reapparition'][0]}–{g['reapparition'][1]} s)"
        grp.append(s)
    L = [f"**`{c['id']}` — {c['nom'].split('—')[-1].strip()}** ({'existante' if c.get('existante') else 'nouvelle'} ; palier {c.get('palier', '—')} ; x={c['x']}, y={c['y']}{' ; Pierre de Passage' if c.get('pierre') else ''}{' ; **boss**' if c.get('boss') else ''})",
         f"- Sorties : {sorties or '—'}.",
         f"- Ambiance : {c['ambiance']}",
         f"- Plan : {c['elements']}",
         f"- Ressources : {res}" + (f" ({c['ressources_note']})" if c.get("ressources_note") else "") + ".",
         f"- Groupes : " + ("; ".join(f"{i + 1}. {g}" for i, g in enumerate(grp)) if grp else "aucun") + "." + (f" {c['groupes_note']}" if c.get("groupes_note") else "")]
    if c.get("decors"):
        L.append("- Décors : " + ", ".join(c["decors"]) + ".")
    for p in c.get("pnj", []):
        flags = []
        if p.get("marchand"): flags.append("marchand")
        if p.get("atelier"): flags.append(f"atelier {p['atelier']}")
        L.append(f"- PNJ `{p['marqueur']}` **{p['nom']}** (`{p['id']}`{', ' + ', '.join(flags) if flags else ''}) — {p['role']} : " + " / ".join(f"« {r} »" for r in p["repliques"]))
    if c.get("pnj_note"):
        L.append(f"- PNJ : {c['pnj_note']}")
    if c.get("passage_inter_zone"):
        L.append(f"- Lien entre zones : {c['passage_inter_zone']}")
    L.append("")
    return "\n".join(L)


def md_zone(z, num):
    L = [f"## {num}. {z['nom']}", ""]
    p = z["pierre"]
    L.append(f"Palette `{z['palette']}` ; Pierre de Passage `{p['id']}` sur `{p['carte']}` ({p['prix']} écus{', existante' if p.get('existante') else ''}). {len(z['cartes'])} cartes.")
    L.append("")
    L.append("```")
    L += z["plan_zone"]
    L.append("```")
    L.append("")
    L.append(f"**Progression.** {z['progression']}")
    L.append("")
    L.append(f"### {num}.1 Cartes")
    L.append("")
    for c in z["cartes"]:
        L.append(md_carte(c))
    L.append(f"### {num}.2 Familles")
    L.append("")
    L.append("| Famille | Palier | Rôle | Niv. de base : PV / PA / PM | XP base | Élite (niv., PV) |")
    L.append("|---|---|---|---|---|---|")
    for f in z["familles"]:
        c = f["caracteristiques"]
        e = f["elite"]
        L.append(f"| {f['nom']} | {f['palier']} | {f['role']} | {c['pv']} / {c['pa']} / {c['pm']} | {f['xp']} | {e['nom']} ({e['niveau']}, {e['caracteristiques']['pv']}) |")
    L.append("")
    for f in z["familles"]:
        L.append(md_famille(f))
    if z.get("boss"):
        L.append(f"### {num}.3 Boss")
        L.append("")
        L.append(md_boss(z["boss"]))
    if z.get("ville"):
        L.append(f"### {num}.4 La ville")
        L.append("")
        L.append(z["ville"])
        L.append("")
    return "\n".join(L)


def all_monsters_json():
    out = []
    for z in zones:
        for f in z["familles"]:
            out.append(f["json"]); out.append(f["elite"]["json"])
        if z.get("boss"):
            out.append(z["boss"]["json"])
    v = extra["variantes"]
    if v:
        out += [x["json"] for x in v.VARIANTES]
    return out


def write():
    t = extra["transverse"]
    md = [t.intro_md()]
    num = 3
    for z in zones:
        md.append(md_zone(z, num)); num += 1
    for name in ["variantes", "transverse", "metiers"]:
        mod = extra[name]
        if mod and hasattr(mod, "MARKDOWN"):
            md.append(mod.MARKDOWN())
    md.append(t.FIN())
    open(os.path.join(OUT, "chantier3_contenu.md"), "w").write("\n".join(md))


if __name__ == "__main__":
    write()
    if len(sys.argv) > 1 and sys.argv[1] == "json":
        import export_json
        export_json.export(zones, extra)
    print("ok", [z["id"] for z in zones], len(SPELLS), "sorts", len(OBJETS), "objets")
