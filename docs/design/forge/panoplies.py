"""Panoplies d'objets forgés (GDD § 10.4, 11/11/2026) : mot de chaque famille (champ `mot` des monstres),
famille et zone de chaque ressource de monstre (champs `famille`, `zone`), ressources partagées séparées
(une ressource n'appartient qu'à une famille). Idempotent : python3 docs/design/forge/panoplies.py"""
import collections, glob, json, os, re

RACINE = os.path.join(os.path.dirname(__file__), "..", "..", "..", "game")
MOTS = {"ange": "d'Ange", "arbre_calcine": "d'Arbre calciné", "arbre_vivant": "d'Arbre vivant", "archange_raphael": "de Raphaël",
        "balourd_des_abimes": "du Balourd", "bucheron_de_brumerive": "de Bûcheron", "cendrillon": "de Cendrillon", "cerf_enchante": "de Cerf",
        "colombe_baptiste": "de Colombe", "contremaitre_zele": "de Contremaître", "corbac_espion": "de Corbac", "cupidon": "de Cupidon",
        "detrousseur": "de Détrousseur", "epouvantail_demotive": "d'Épouvantail", "gargouille": "de Gargouille", "gobelin_briseur": "de Briseur",
        "gobelin_frondeur": "de Frondeur", "gobelin_pillard": "de Pillard", "grondin": "de Grondin", "grouilleur": "de Grouilleur",
        "grouilleur_de_braise": "de Grouilleur de braise", "krasbouk": "de Krasbouk", "lion_de_juda": "de Lion", "loup_cendreux": "de Loup des cendres",
        "loup_des_collines": "de Loup", "mere_toile": "de la Mère-Toile", "milicien_de_hautepierre": "de Milicien", "morille_grincheuse": "de Morille",
        "olifant_de_guerre": "d'Olifant", "rat_des_galeries": "de Rat", "souverain_cendre": "du Souverain", "tisseuse_de_brume": "de Tisseuse",
        "troll_des_ponts": "de Troll", "vampipistrelle": "de Vampipistrelle"}
ZONES = ["brumerive", "crasse_roc", "sylvebrume", "hautepierre", "tour_celeste"]
# Nouvelles ressources : id → (nom, rareté, palier, caractéristique, description, dessin repris, famille, remplace dans son butin).
NOUVELLES = {
    "croc_de_loup_des_cendres": ("Croc de loup des cendres", "commun", 3, "intelligence", "Encore chaud. Il mord même arraché.", "croc_de_loup", "loup_cendreux", "croc_de_loup"),
    "poil_roussi": ("Poil roussi", "commun", 3, "force", "Sent le chien mouillé tombé dans un feu de camp.", "cendre_tiede", "loup_cendreux", "cendre_tiede"),
    "croc_ardent": ("Croc ardent", "rare", 3, "dommages_flamme", "Le loup l'a perdu en mordant une braise. La braise a perdu aussi.", "eclat_de_cendre", "loup_cendreux", "eclat_de_cendre"),
    "ecorce_calcinee": ("Écorce calcinée", "commun", 3, "resistance_flamme", "Elle s'effrite en reproches.", "ecorce_vivante", "arbre_calcine", "ecorce_vivante"),
    "seve_brulante": ("Sève brûlante", "commun", 3, "agilite", "Coule vite, colle fort, brûle un peu.", "cendre_tiede", "arbre_calcine", "cendre_tiede"),
    "noeud_de_braise": ("Nœud de braise", "rare", 3, "dommages_flamme", "Le cœur de l'arbre n'a pas fini de brûler.", "eclat_de_cendre", "arbre_calcine", "eclat_de_cendre"),
    "braise_de_grouilleur": ("Braise de grouilleur", "commun", 3, "initiative", "Il en crachait ; vous la ramassez. Chacun son métier.", "cendre_tiede", "grouilleur_de_braise", "cendre_tiede"),
    "carapace_fumante": ("Carapace fumante", "commun", 3, "vitalite", "Elle fume encore, comme son ancien propriétaire.", "carapace_de_grouilleur", "grouilleur_de_braise", "carapace_de_grouilleur"),
    "glande_incandescente": ("Glande incandescente", "rare", 3, "dommages_flamme", "À ne pas presser à mains nues.", "eclat_de_cendre", "grouilleur_de_braise", "eclat_de_cendre"),
    "plan_de_casse": ("Plan de casse", "peu_commun", 2, "perception", "Tout y est : la porte, la masse, l'heure de la pause.", "ordre_de_raid", "gobelin_briseur", "ordre_de_raid"),
    "louche_de_krasbouk": ("Louche de Krasbouk", "rare", 2, "vitalite", "Elle a servi la soupe et assommé des héros. Parfois les deux.", "sac_de_rapine", "krasbouk", "sac_de_rapine"),
}
RETIRER = {"krasbouk": ["ordre_de_raid"], "mere_toile": ["fil_de_brume"], "balourd_des_abimes": ["registre_des_heures"]}


def charger(dossier):
    return {f: json.load(open(f)) for f in sorted(glob.glob(os.path.join(RACINE, "data", dossier, "**", "*.json"), recursive=True))}


def ecrire(f, d):
    open(f, "w").write(json.dumps(d, ensure_ascii=False, indent=2) + "\n")


monstres = charger("monstres")
objets = {d["id"]: (f, d) for f, d in charger("objets").items() if isinstance(d, dict)}
for oid, (nom, rarete, palier, carac, desc, dessin, famille, remplace) in NOUVELLES.items():
    f = os.path.join(RACINE, "data", "objets", oid + ".json")
    ecrire(f, {"id": oid, "nom": nom, "type": "ressource", "rarete": rarete, "niveau": palier, "description": desc, "caracteristique": carac})
    objets[oid] = (f, json.load(open(f)))
    for mf, m in monstres.items():
        if m.get("famille", m["id"]) == famille:
            for b in m["butin"]:
                if b["objet"] == remplace:
                    b["objet"] = oid
for mf, m in monstres.items():
    m["butin"] = [b for b in m["butin"] if b["objet"] not in RETIRER.get(m["id"], [])]
    if m["id"] in MOTS:
        m["mot"] = MOTS[m["id"]]
# Zone de chaque famille : celle de la plupart des cartes où elle vit (tour céleste et Cendre à part).
zones = collections.defaultdict(collections.Counter)
for f in glob.glob(os.path.join(RACINE, "data", "cartes", "**", "*.json"), recursive=True):
    texte, carte = open(f).read(), os.path.basename(f)[:-5]
    z = "tour_celeste" if "celeste" in carte else "hautepierre" if carte.startswith("cendre") else re.sub(r"_-?\d+_-?\d+$", "", carte)
    for m in monstres.values():
        if '"%s"' % m["id"] in texte and z in ZONES:
            zones[m.get("famille", m["id"])][z] += 1
familles = collections.defaultdict(set)
for m in monstres.values():
    for b in m["butin"]:
        familles[b["objet"]].add(m.get("famille", m["id"]))
for oid, (f, o) in objets.items():
    if o.get("type") == "ressource" and o.get("caracteristique") and oid in familles:
        assert len(familles[oid]) == 1, (oid, familles[oid])
        fam = next(iter(familles[oid]))
        o["famille"], o["zone"] = fam, zones[fam].most_common(1)[0][0]
        ecrire(f, o)
for mf, m in monstres.items():
    ecrire(mf, m)
# Dessins : les nouvelles ressources reprennent celui d'une ressource proche.
manifeste = {"images": {"objet_" + oid: {"fichier": "objets/%s.svgt" % v[5], "ancre": [22, 22]} for oid, v in NOUVELLES.items()}}
ecrire(os.path.join(RACINE, "art", "manifestes", "panoplies_forgees.json"), manifeste)
print({fam: dict(c) for fam, c in zones.items()})
