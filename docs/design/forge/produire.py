#!/usr/bin/env python3
"""Forge personnalisée (demande de l'auteur du 02/11/2026) : passe unique sur les données.

- supprime les équipements hors panoplies (et leur butin, leurs dessins) et les recettes du forgeron ;
- donne à chaque ressource de monstre un palier (niveau du plus faible monstre qui la lâche), une
  caractéristique répartie équitablement et, pour certaines, une matière (cuir, tissu) ;
- crée les modèles de la forge (`forge_<type>`) et des plans (`plan_<ancien objet>`) : récompenses des
  quêtes qui donnaient un objet supprimé, et quelques plans vendus par les marchands ;
- enclume dans les maisons, forgerons qui l'indiquent et expliquent la forge.

À lancer une seule fois depuis la racine du dépôt (les objets supprimés n'existent plus ensuite).
"""
import glob, json, os, re

G = "game"
def lire(p): return json.load(open(p, encoding="utf-8"))
def ecrire(p, d): open(p, "w", encoding="utf-8").write(json.dumps(d, ensure_ascii=False, indent=2) + "\n")

items = {lire(f)["id"]: lire(f) for f in glob.glob(f"{G}/data/objets/*.json")}
pano = {i for f in glob.glob(f"{G}/data/panoplies/*.json") for i in lire(f)["objets"]}
supprimes = {i for i, d in items.items() if d["type"] not in ("ressource", "quete") and i not in pano}
monstres = {f: lire(f) for f in glob.glob(f"{G}/data/monstres/*.json")}
quetes = {f: lire(f) for f in glob.glob(f"{G}/data/quetes/*.json")}

# --- Ressources de monstres : palier, caractéristique, matière -------------------------------------
recolte, palier_recolte = set(), {}
for f in glob.glob(f"{G}/data/metiers/*.json"):
    for n in lire(f).get("ressources", []):
        recolte |= {n["objet"], n.get("rare")}
        for r in (n["objet"], n.get("rare")): palier_recolte[r] = n.get("niveau", 1)
palier = {}
for m in monstres.values():
    for b in m.get("butin", []):
        if items.get(b["objet"], {}).get("type") == "ressource" and b["objet"] not in recolte:
            palier[b["objet"]] = min(palier.get(b["objet"], 999), m["niveau"])
# PA, PM et Portée : très rares, sur les butins de mini-boss.
FIXES = {"corne_du_balourd": "pa", "soie_de_la_mere_toile": "pm", "fragment_de_cendre": "pa", "eclat_de_cendre": "portee"}
# Fréquence relative : élémentaires à égalité, puis Vitalité, Initiative, Prospection, Dommages, Critique.
POIDS = {"force": 6, "intelligence": 6, "perception": 6, "agilite": 6, "vitalite": 4, "initiative": 3,
         "prospection": 2, "dommages": 2, "critique": 1}
courant = {s: 0 for s in POIDS}
def suivante():  # tourniquet pondéré lisse : chaque caractéristique revient à intervalles réguliers
    for s in POIDS: courant[s] += POIDS[s]
    s = max(courant, key=lambda k: courant[k]); courant[s] -= sum(POIDS.values()); return s
carac = dict(FIXES)
for r in sorted(palier, key=lambda r: (palier[r], r)):
    if r not in carac: carac[r] = suivante()
MATIERES = {"cuir": ["peau_de_loup", "cuir_d_olifant", "aile_de_vampipistrelle", "queue_de_rat"],
            "tissu": ["poil_scintillant", "paille_ensorcelee", "fil_de_brume", "soie_de_la_mere_toile", "plume_de_corbac"]}
matiere = {r: m for m, rs in MATIERES.items() for r in rs}
for r in recolte - {None}:
    matiere[r] = "bois" if r.startswith(("bois_", "chene_", "coeur_de_frene", "if_", "hetre_", "malorme_")) else "minerai"
for r, d in items.items():
    if r in palier: d["niveau"], d["caracteristique"] = palier[r], carac[r]
    if r in matiere: d["matiere"] = matiere[r]
    if r in palier_recolte: d["niveau"] = palier_recolte[r]
    if r in palier or r in matiere: ecrire(f"{G}/data/objets/{r}.json", d)

# --- Modèles de la forge ---------------------------------------------------------------------------
ARMES = {  # forme → (nom, élément, PA, portée min, portée max, dégâts min, max, ligne de vue, relance)
    "epee": ("Épée", "acier", 4, 1, 1, 7, 11, False, 1), "arc": ("Arc", "tempete", 4, 2, 5, 5, 8, True, 1),
    "baton": ("Bâton", "givre", 3, 1, 2, 4, 7, True, 1), "dague": ("Dague", "impie", 3, 1, 1, 5, 8, False, 2),
    "masse": ("Masse", "sacre", 4, 1, 1, 7, 11, False, 1), "sceptre": ("Sceptre", "flamme", 4, 2, 5, 5, 8, False, 1)}
NOMS = {"coiffe": "Coiffe", "cape": "Cape", "amulette": "Amulette", "anneau": "Anneau", "ceinture": "Ceinture", "bottes": "Bottes"}
DESSIN = {"coiffe": "bonnet_de_berger", "cape": "cape_en_peau_de_loup", "amulette": "amulette_croc", "anneau": "anneau_de_cuivre",
          "ceinture": "ceinture_de_corde", "bottes": "bottes_de_marche", "epee": "epee_de_fer", "arc": "arc_de_frene",
          "baton": "baton_de_novice", "dague": "dague_du_mauvais_oeil", "masse": "masse_cerclee", "sceptre": "sceptre_de_novice"}
for t, nom in list(NOMS.items()) + [(k, v[0]) for k, v in ARMES.items()]:
    d = {"id": f"forge_{t}", "nom": nom, "type": t if t in NOMS else "arme", "rarete": "commun", "niveau": 1, "boutique": False,
         "description": "Objet forgé à l'enclume."}
    if t in ARMES:
        _, el, pa, pmin, pmax, dmin, dmax, ldv, rel = ARMES[t]
        d["attaque"] = {"cout_pa": pa, "portee": {"min": pmin, "max": pmax}, "relance": {"par_tour": rel},
                        "effets": [{"type": "degats", "element": el, "min": dmin, "max": dmax}]}
        if ldv: d["attaque"]["ligne_de_vue"] = True
    ecrire(f"{G}/data/objets/forge_{t}.json", d)

# --- Plans : récompenses de quêtes et boutique -----------------------------------------------------
def forme(d):
    if d["type"] != "arme": return d["type"]
    for mot, f in [("arc", "arc"), ("fronde", "arc"), ("baton", "baton"), ("fuseau", "baton"), ("dague", "dague"), ("coutelas", "dague"),
                   ("masse", "masse"), ("massue", "masse"), ("marteau", "masse"), ("sceptre", "sceptre"), ("baguette", "sceptre"), ("fouet", "sceptre")]:
        if d["id"].startswith(mot): return f
    return "epee"
OBLIGATOIRES = {"coiffe": ["tissu"], "cape": ["tissu"], "ceinture": ["cuir"], "bottes": ["cuir"], "amulette": ["minerai"],
                "anneau": ["minerai"], **{k: ["minerai", "bois"] for k in ARMES}}
MAX_RESSOURCES = 6
def moins_cher(m, p):  # ressource de la matière la plus proche du palier, sans le dépasser si possible
    cands = [r for r, v in matiere.items() if v == m and items[r].get("boutique", True)]
    return min(cands, key=lambda r: (items[r]["niveau"] > p, abs(items[r]["niveau"] - p), r))
def plan(old_id, vendu):
    d = items[old_id]; t = forme(d); p = d.get("niveau", 1)
    res = {}
    for m in OBLIGATOIRES[t]: r = moins_cher(m, p); res[r] = res.get(r, 0) + 1
    stats = [s for s in d.get("bonus", {}) if s not in ("pa", "pm", "portee")] or ["vitalite"]
    reste = MAX_RESSOURCES - sum(res.values())
    for i, s in enumerate(stats):
        cands = [r for r in palier if carac[r] == s and items[r].get("boutique", True)]
        if not cands: continue
        r = min(cands, key=lambda r: (palier[r] > p, abs(palier[r] - p), r))
        n = reste // len(stats) + (1 if i < reste % len(stats) else 0)
        if n: res[r] = res.get(r, 0) + n
    pid = f"plan_{old_id}"
    ecrire(f"{G}/data/objets/{pid}.json", {"id": pid, "nom": f"Plan : {d['nom']}", "type": "recette",
        "rarete": "rare" if vendu else "peu_commun", "niveau": p, "boutique": vendu,
        "description": f"Plan de forge : {d['nom']}. {d.get('description', '')}".strip(),
        "recette": {"nom": d["nom"], "type": t, "ressources": res}})
    return pid

for f, q in quetes.items():
    s = json.dumps(q, ensure_ascii=False)
    for o in q.get("recompenses", {}).get("objets", []):
        if o["objet"] in supprimes: o["objet"] = plan(o["objet"], False)
    if "bonnet_de_berger" in s:  # tutoriels : la coiffe du Fouineur remplace le bonnet
        for o in q.get("donne", []) + [ob for e in q["etapes"] for ob in e["objectifs"]]:
            if o.get("objet") == "bonnet_de_berger": o["objet"] = "coiffe_fouineur"
            if o.get("texte", "").startswith("Mettre le bonnet"): o["texte"] = o["texte"].replace("le bonnet", "la coiffe")
            if o.get("type") == "fabriquer": o["texte"] = "Forger un objet à l'enclume de votre maison"
        for lignes in q.get("dialogues", {}).values():
            for k, v in lignes.items():
                lignes[k] = [l.replace("ce bonnet", "cette coiffe").replace("Bonnet,", "Coiffe,")
                             .replace("faites-vous forger quelque chose chez", "forgez-vous quelque chose : demandez à") for l in v]
    ecrire(f, q)
for old in ["anneau_de_cuivre", "amulette_croc", "ceinture_de_corde", "casque_cabosse", "cape_en_peau_de_loup", "epee_de_fer",
            "arc_de_frene", "baton_de_novice", "dague_du_mauvais_oeil", "masse_cerclee", "sceptre_de_novice"]:
    plan(old, True)

# --- Suppressions ----------------------------------------------------------------------------------
for f, m in monstres.items():
    m["butin"] = [b for b in m.get("butin", []) if b["objet"] not in supprimes]
    ecrire(f, m)
for i in supprimes: os.remove(f"{G}/data/objets/{i}.json")
job = lire(f"{G}/data/metiers/forgeron.json"); job.pop("recettes", None)
job["description"] = "Forge armes et équipements à l'enclume, à partir des ressources de monstres, du minerai et du bois."
ecrire(f"{G}/data/metiers/forgeron.json", job)
forge_art = {"images": {"enclume": {"fichier": "meuble/enclume.svgt", "ancre": [22, 30]},
                        "objet_plan": {"fichier": "objets/ordre_de_raid.svgt", "ancre": [22, 22]}},
             "icones_armes": {f"forge_{k}": f"sort_arme_{k}" if k != "dague" else "sort_arme_dague_impie" for k in ARMES}}
for p in [f"{G}/art/art.json"] + glob.glob(f"{G}/art/manifestes/*.json"):
    a = lire(p)
    for i in supprimes:
        e = a.get("images", {}).pop(f"objet_{i}", None)
        a.get("icones_armes", {}).pop(i, None)
        if not e: continue
        t = next((k for k, v in DESSIN.items() if v == i), None)
        if t:
            os.rename(f"{G}/art/{e['fichier']}", f"{G}/art/objets/forge_{t}.svgt")
            forge_art["images"][f"objet_forge_{t}"] = {**e, "fichier": f"objets/forge_{t}.svgt"}
        elif os.path.exists(f"{G}/art/{e['fichier']}"): os.remove(f"{G}/art/{e['fichier']}")
    ecrire(p, a)
icones = lire(f"{G}/art/art.json")["images"]
for k in ARMES:  # sorts d'arme déjà dessinés, sinon l'épée
    if forge_art["icones_armes"][f"forge_{k}"] not in icones: forge_art["icones_armes"][f"forge_{k}"] = "sort_arme_epee"
ecrire(f"{G}/art/manifestes/forge.json", forge_art)

# --- Enclume et forgerons --------------------------------------------------------------------------
for c in ["maison_joueur", "maison_crasse_roc", "maison_sylvebrume"]:
    p = f"{G}/data/cartes/{c}.json"; d = lire(p)
    d["plan"][1] = d["plan"][1][:5] + "&" + d["plan"][1][6:]
    ecrire(p, d)
EXPLICATION = [
    "À l'enclume, on choisit d'abord le type d'objet : coiffe, bottes, épée… Chaque type demande sa matière : du tissu pour les coiffes et les capes, du cuir pour les bottes et les ceintures, du minerai pour les anneaux et les amulettes, du minerai et du bois pour les armes.",
    "Ensuite on ajoute des ressources de monstres, six au plus. Chacune donne une caractéristique, d'autant plus forte que la bête était coriace. PA et PM : une ligne par objet, et c'est rare.",
    "Les débutants forgent à l'aveugle : c'est en forgeant qu'on apprend à lire les ressources, les plus faibles d'abord. Un plan, lui, dit tout d'avance.",
    "L'enclume montre l'objet avant de le forger : ses lignes, ses jets possibles et un nom, que vous pouvez changer avec les mots proposés. Votre nom sera gravé dessus. Le jet, lui, c'est la surprise.",
]
for c in ["brumerive_0_0", "crasse_roc_0_0", "sylvebrume_0_0", "hautepierre_2_2"]:
    p = f"{G}/data/cartes/{c}.json"; d = lire(p)
    for n in d.get("pnj", []):
        if n.pop("atelier", None):
            n["repliques"] = [n["repliques"][0], "Je ne forge plus pour les autres : il y a une enclume chez vous, dans votre maison de la zone de départ. Vous voulez que je vous explique comment on s'en sert ?"]
            n["explication"] = EXPLICATION
    ecrire(p, d)
print(len(supprimes), "objets supprimés,", len(palier), "ressources de monstres")
