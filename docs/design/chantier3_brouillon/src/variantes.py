"""Variantes Corrompues : versions plus fortes de familles existantes, touchées par la Cendre."""
from common import *
from balance import pv_monstre, xp_monstre, ecus as ecus_ref

equipement("cape_de_loup_cendreux", "Cape de loup cendreux", "cape", "rare", 15,
           "Elle sent le brûlé et ne sèche jamais vraiment. Le loup non plus, d'ailleurs.",
           {"agilite": 0.4, "vitalite": 0.3, "initiative": 0.3}, "butin:loup_cendreux",
           "cape de fourrure gris anthracite, bordure de braises orange")
equipement("bottes_de_braise", "Bottes de braise", "bottes", "rare", 18,
           "Taillées dans la carapace d'un grouilleur de braise. Chaudes en hiver, en été aussi, toute l'année en fait.",
           {"intelligence": 0.4, "force": 0.3, "initiative": 0.3}, "butin:grouilleur_de_braise",
           "bottes segmentées comme une carapace, rouge sombre, lueurs orange entre les plaques")
equipement("ceinture_d_ecorce_calcinee", "Ceinture d'écorce calcinée", "ceinture", "rare", 21,
           "Elle craque à chaque pas et laisse un peu de cendre partout. Les aubergistes vous détestent.",
           {"vitalite": 0.5, "force": 0.25, "intelligence": 0.25}, "butin:arbre_calcine",
           "ceinture d'écorce noire fendillée, braises dans les fissures, boucle en bois")

sort("cendreux_morsure_brulante", "Morsure brûlante", "Ses crocs gardent la chaleur de la Cendre.",
     3, (1, 1), [dg("flamme", 4, 6), poison("flamme", 2, 3, 2)])
sort("braise_crachat_de_feu", "Crachat de feu", "L'acide a pris feu. Il en est très fier.",
     4, (2, 4), [dg("flamme", 5, 7)], zone={"type": "cercle", "taille": 1})
sort("calcine_cendres", "Pluie de cendres", "Il secoue ses branches mortes ; il en tombe des braises.",
     3, (1, 3), [glyphe(2, [dg("flamme", 4, 6, "ennemis")])], zone={"type": "cercle", "taille": 1}, ldv=False,
     relance={"par_tour": 1, "delai": 2})


def variante(id, nom, base, description, palier, role, pv, pv_pn, pa, pm, init, stats, res, sorts, ia, butin, art, xp_mult=1.1, carte=None):
    a, b = palier
    carac = {"pv": pv, "pa": pa, "pm": pm, "initiative": init}
    par = {"pv": pv_pn, "initiative": 5, "xp": round((xp_monstre(b) - xp_monstre(a)) / (b - a) * xp_mult)}
    for k, v in stats.items():
        carac[k] = v[0]
        par[k] = v[1]
    lo, hi = ecus_ref((a + b) // 2)
    m = {"id": id, "nom": nom, "description": description, "corrompu": True, "base": base, "niveau": a,
         "niveaux": {"min": a, "max": b, "poids": POIDS[role]}, "caracteristiques": carac, "par_niveau": par,
         "resistances": res, "sorts": sorts, "ia": ia, "xp": round(xp_monstre(a) * xp_mult), "butin": butin,
         "ecus": [round(lo * xp_mult), round(hi * xp_mult)]}
    return {"id": id, "base": base, "nom": nom, "palier": f"{a}-{b}", "role": role, "cartes": carte,
            "regle_apparition": "Placée dans les groupes des cartes cendrées de Hautepierre (« cendree »: true) : " + ", ".join(carte) + ".",
            "sorts": ligne_sorts(sorts), "art": art, "json": m}


VARIANTES = [
    variante("loup_cendreux", "Loup cendreux", "loup_des_collines",
             "Un loup des collines qui a mangé quelque chose qu'il n'aurait pas dû, dans la cendre. Il a toujours faim, mais maintenant il fume.",
             (13, 15), "moyen", 69, 5, 6, 4, 130, {"force": (24, 2), "intelligence": (24, 2)},
             {"flamme": 20, "givre": 10, "impie": 15, "acier": 0, "tempete": 0, "sacre": -10},
             ["loup_morsure", "cendreux_morsure_brulante"], "basique",
             [drop("croc_de_loup", 0.5, [1, 2]), drop("cendre_tiede", 0.5, [1, 2]), drop("eclat_de_cendre", 0.03),
              drop("cape_de_loup_cendreux", 0.04)],
             {"type": "image", "reutilise": "loup", "nouveau_svg": None,
              "manifeste": {"image": "loup", "echelle": 0.9, "couleurs": {"pelage": "3a3634", "pelage_ombre": "26221f", "ventre": "c25a2a"}}},
             carte=["hautepierre_4_2"]),
    variante("grouilleur_de_braise", "Grouilleur de braise", "grouilleur",
             "Un grouilleur descendu des mines dans les gorges cendrées. Son acide a pris feu ; ses pattes aussi, un peu.",
             (16, 18), "fort", 85, 6, 6, 3, 90, {"force": (30, 2), "intelligence": (30, 2)},
             {"flamme": 35, "impie": 10, "acier": 0, "givre": -10, "sacre": -10},
             ["grouilleur_pinces", "braise_crachat_de_feu"], "basique",
             [drop("carapace_de_grouilleur", 0.5, [1, 2]), drop("cendre_tiede", 0.5, [1, 2]), drop("eclat_de_cendre", 0.03),
              drop("bottes_de_braise", 0.04)],
             {"type": "image", "reutilise": "grouilleur", "nouveau_svg": None,
              "manifeste": {"image": "grouilleur", "echelle": 0.95, "teinte": "ff9a60"}},
             carte=["hautepierre_2_3", "hautepierre_2_4"]),
    variante("arbre_calcine", "Arbre calciné", "arbre_vivant",
             "Un arbre vivant que la première pluie de cendre a brûlé debout. Il marche encore, il fume, et il est de très mauvaise humeur.",
             (19, 21), "moyen", 140, 8, 7, 1, 40, {"force": (36, 2), "intelligence": (36, 2)},
             {"acier": 25, "flamme": 30, "givre": -20, "tempete": 0, "sacre": -10},
             ["arbre_branche", "arbre_racines", "calcine_cendres"], "basique",
             [drop("ecorce_vivante", 0.5, [1, 2]), drop("cendre_tiede", 0.5, [1, 2]), drop("eclat_de_cendre", 0.03),
              drop("ceinture_d_ecorce_calcinee", 0.04)],
             {"type": "image", "reutilise": "arbre_vivant", "nouveau_svg": None,
              "manifeste": {"image": "arbre_vivant", "echelle": 0.95, "teinte": "6a5a50"}},
             xp_mult=1.3, carte=["hautepierre_1_0", "hautepierre_3_0"]),
]

REGLE = (
    "**Règle simple des Corrompus.** Une variante Corrompue est un monstre à part entière (son propre fichier), marqué `\"corrompu\": true` et `\"base\": \"<famille d'origine>\"`. "
    "Ce n'est pas une famille : **pas d'élite**, pas de `famille`, et le test « un élite par famille » doit l'ignorer. Elle se construit toujours de la même façon :\n\n"
    "1. **Niveau** : environ 10 à 15 niveaux au-dessus de sa base, dans un palier de Hautepierre (13–15, 16–18, 19–21), avec ses propres `niveaux` et poids.\n"
    "2. **Corps** : même dessin que sa base, assombri (`teinte` ou `couleurs`) ; PV ≈ référence du niveau × 1,1 (× 1,5 pour l'arbre, qui reste un tank) ; mêmes PA/PM que sa base.\n"
    "3. **Cendre** : Flamme +20 à +35 en résistance, Sacré −10 (la lumière la blesse), faiblesse Givre ; elle garde **les sorts de sa base** et gagne **un sort de Flamme**.\n"
    "4. **Butin** : la ressource commune de sa base, `cendre_tiede` (50 %), `eclat_de_cendre` (3 %, rare) et un équipement rare qui lui est propre.\n"
    "5. **Apparition** : seulement sur les **cartes cendrées** (`\"cendree\": true` dans la carte : cendre qui tombe, palette `cendree`), placée explicitement dans les `groupes` "
    "(jamais plus d'une variante par groupe fixe ; dans un `parmi`, elle peut être seule). Pas de tirage aléatoire caché : ce qu'on voit dans le fichier de carte est ce qui apparaît.\n\n"
    "Plus tard (hors alpha), la même règle permettra une « contamination » : une carte d'une zone de départ deviendrait cendrée à l'acte II et ses familles y laisseraient la place à leurs variantes.")


def MARKDOWN():
    import build
    L = ["## 7. Variantes Corrompues", "", REGLE, ""]
    L.append("| Variante | Base | Palier | PV / PA / PM (niv. min) | Cartes |")
    L.append("|---|---|---|---|---|")
    for v in VARIANTES:
        c = v["json"]["caracteristiques"]
        L.append(f"| {v['nom']} (`{v['id']}`) | `{v['base']}` | {v['palier']} | {c['pv']} / {c['pa']} / {c['pm']} | {', '.join(v['cartes'])} |")
    L.append("")
    for v in VARIANTES:
        j = v["json"]
        L.append(f"#### {v['nom']} (`{v['id']}`, base `{v['base']}`) — palier {v['palier']}")
        L.append(f"*{j['description']}*")
        L.append("")
        L.append(f"- Niveaux {j['niveaux']['min']}–{j['niveaux']['max']} (poids {'/'.join(map(str, j['niveaux']['poids']))}) ; base : {build.carac_txt(j['caracteristiques'])} ; par niveau : {build.pn_txt(j['par_niveau'])}.")
        L.append(f"- Résistances : {build.res_txt(j['resistances'])} ; IA `{j['ia']}` ; XP {j['xp']} ; écus {j['ecus'][0]}–{j['ecus'][1]}.")
        L.append("- Sorts : " + "".join("\n  - " + build.sort_txt(s["id"]) for s in v["sorts"]))
        L.append(f"- Butin : {build.butin_txt(j['butin'])}.")
        L.append(f"- Dessin : {build.art_txt(v['art'])}.")
        L.append("")
    return "\n".join(L)
