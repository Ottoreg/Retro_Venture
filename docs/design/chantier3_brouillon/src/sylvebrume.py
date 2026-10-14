"""Lisière de Sylvebrume (elfes, camp neutre)."""
from common import *

# ---------------- objets ----------------
ressource("chapeau_de_morille", "Chapeau de morille", "commun",
          "Alvéolé, parfumé, vexé. Il continue de bouder même détaché.", "butin:morille_grincheuse",
          "chapeau de morille alvéolé brun-beige, petits sourcils froncés dessinés dans les alvéoles")
ressource("spores_grincheuses", "Spores grincheuses", "peu_commun",
          "Une pincée suffit à gâcher une fête. Les elfes en mettent dans les lettres de refus.", "butin:morille_grincheuse",
          "petite fiole bouchée remplie de poussière vert-gris qui tourbillonne")
ressource("copeaux_de_bois", "Copeaux de bois", "commun",
          "Ce qui reste d'un arbre quand un bûcheron est passé. Les elfes les ramassent en pleurant.", "butin:bucheron_de_brumerive",
          "poignée de copeaux blonds en spirale")
ressource("bon_de_coupe", "Bon de coupe", "peu_commun",
          "Autorisation de couper « quelques arbres ». Le mot « quelques » a été rayé.", "butin:bucheron_de_brumerive",
          "feuillet tamponné « Hautepierre — Bois et Forêts », un mot raturé à l'encre rouge")
ressource("fil_de_brume", "Fil de brume", "commun",
          "Un fil d'araignée si fin qu'on le voit seulement quand il fait humide. Il fait toujours humide.", "butin:tisseuse_de_brume",
          "pelote de fil gris perle presque transparente, gouttelettes de rosée")
ressource("crochet_d_araignee", "Crochet d'araignée", "peu_commun",
          "Encore une goutte de venin au bout. Ne pas s'en servir comme cure-dent.", "butin:tisseuse_de_brume",
          "crochet noir recourbé, goutte bleu pâle à la pointe")
ressource("soie_de_la_mere_toile", "Soie de la Mère-Toile", "rare",
          "Un écheveau tissé depuis l'Âge de l'Aube. Elle n'a jamais fini un seul napperon.", "boss:mere_toile",
          "écheveau de soie argentée aux reflets violets, enroulé sur un fuseau d'os")

equipement("bottes_de_mousse", "Bottes de mousse", "bottes", "commun", 2,
           "Douces, silencieuses, un peu humides. Les champignons poussent dessus si on ne marche pas assez.",
           {"chance": 0.5, "vitalite": 0.5}, "butin:morille_grincheuse",
           "petites bottes vert mousse, deux minuscules champignons sur la tige")
equipement("hache_de_bucheron", "Hache de bûcheron", "arme", "peu_commun", 9,
           "Une cognée honnête. Elle a abattu Vieux-Branchu ; elle n'en est pas fière.",
           {"force": 0.6, "vitalite": 0.4}, "butin:bucheron_de_brumerive",
           "hache à fer large et manche de frêne, petite entaille sur la lame",
           attaque=attaque(9, "peu_commun", "acier", 4, (1, 1)))
equipement("ceinture_de_bucheron", "Ceinture de bûcheron", "ceinture", "commun", 9,
           "Larges bretelles, larges épaules, petit esprit de conservation.",
           {"force": 0.5, "vitalite": 0.5}, "butin:bucheron_de_brumerive",
           "ceinture de cuir avec une boucle carrée et un étui à hachette vide")
equipement("cape_de_soie_grise", "Cape de soie grise", "cape", "peu_commun", 11,
           "Tissée par les tisseuses de brume. Elle colle un peu, mais elle protège du froid et des regards.",
           {"chance": 0.5, "sagesse": 0.2, "vitalite": 0.3}, "butin:tisseuse_de_brume",
           "cape gris perle à motif de toile d'araignée argentée")
equipement("fuseau_de_la_mere_toile", "Fuseau de la Mère-Toile", "arme", "epique", 12,
           "Elle tissait avec ; vous frappez avec. Le fil gèle tout ce qu'il touche.",
           {"chance": 0.5, "vitalite": 0.3, "dommages": 0.2}, "boss:mere_toile",
           "long fuseau d'os blanc enroulé de fil argenté, givre bleu à la pointe",
           attaque=attaque(12, "epique", "givre", 4, (2, 5)), boutique=False)
equipement("anneau_aux_huit_yeux", "Anneau aux huit yeux", "anneau", "rare", 12,
           "Huit pierres noires qui vous regardent. Avec, vous voyez plus loin ; eux aussi.",
           {"chance": 0.25, "agilite": 0.15}, "boss:mere_toile",
           "anneau d'argent serti de huit petites pierres noires en cercle", fixe={"portee": [1, 1]}, boutique=False)

# ---------------- sorts ----------------
sort("morille_spores", "Spores", "Un nuage de mauvaise humeur, très contagieux.",
     3, (1, 3), [dg("givre", 2, 4), poison("givre", 1, 2, 2)], ldv=False)
sort("morille_bouderie", "Bouderie", "Elle boude. C'est étonnamment efficace.",
     2, (0, 0), [bouclier("givre", 4, 6)], ldv=False, relance={"par_tour": 1, "delai": 2})
sort("rancune_nuage_de_spores", "Nuage de rancune", "Elle n'oublie rien. Vos poumons non plus.",
     4, (1, 3), [poison("givre", 2, 3, 3), malus("portee", 1, 1, 1)], zone={"type": "cercle", "taille": 1}, ldv=False)
sort("bucheron_cognee", "Coup de cognée", "Bien droit, comme pour un chêne. Vous n'êtes pas un chêne.",
     4, (1, 1), [dg("acier", 7, 10)])
sort("bucheron_ca_tombe", "Attention, ça tombe !", "Il crie toujours avant. Personne n'écoute jamais.",
     4, (2, 4), [dg("acier", 5, 7)], zone={"type": "croix_latine"}, en_ligne=True, ldv=False,
     relance={"par_tour": 1, "delai": 1})
sort("abatteur_souche_piegee", "Souche piégée", "Une souche, des pointes, et un abatteur qui sourit.",
     3, (1, 4), [piege([dg("acier", 7, 10, "ennemis"), malus("pm", 2, 2, 1, cibles="ennemis")], zone={"type": "cercle", "taille": 1})],
     ldv=False, relance={"par_tour": 1, "delai": 2})
sort("tisseuse_morsure", "Morsure glacée", "Le venin des tisseuses gèle le sang. Et l'humeur.",
     3, (1, 1), [dg("givre", 4, 6), poison("givre", 2, 3, 2)])
sort("tisseuse_toile", "Toile collante", "On se débat, on s'emmêle, on reste là.",
     3, (2, 5), [dg("givre", 2, 4), malus("pm", 2, 2, 1)])
sort("tisseuse_cocon", "Cocon", "Elle vous emballe pour plus tard.",
     4, (1, 4), [dg("givre", 6, 9), malus("pa", 2, 2, 1)], relance={"par_tour": 1, "delai": 1})
sort("meretoile_venin", "Venin ancestral", "Une seule morsure, et l'hiver s'installe dans vos veines.",
     4, (1, 1), [dg("givre", 7, 10), poison("givre", 3, 4, 3)])
sort("meretoile_toile_geante", "Toile géante", "Toute la clairière devient un piège.",
     4, (2, 5), [glyphe(2, [dg("givre", 2, 4, "ennemis"), malus("pm", 2, 2, 1, cibles="ennemis")])],
     zone={"type": "cercle", "taille": 2}, ldv=False, relance={"par_tour": 1, "delai": 3})

# ---------------- familles ----------------
MORILLE = famille(
    "morille_grincheuse", "Morille grincheuse", "Elle pousse à l'ombre, elle râle à l'ombre, elle mord à l'ombre.",
    (1, 3), "faible", "frele", 5, 2, 40, {"chance": 1},
    {"givre": 15, "tempete": 10, "acier": 0, "flamme": -20}, ["morille_spores", "morille_bouderie"], "basique",
    [drop("chapeau_de_morille", 0.6, [1, 2]), drop("spores_grincheuses", 0.12), drop("bottes_de_mousse", 0.05),
     drop("coiffe_mauvais_oeil", 0.02), drop("cape_mauvais_oeil", 0.02), drop("amulette_mauvais_oeil", 0.02)],
    {"type": "image", "reutilise": None,
     "nouveau_svg": "monstre/morille.svgt, ~34×42 px : morille debout, chapeau conique alvéolé brun-beige ({{pelage}}/{{pelage_ombre}}), pied blanc trapu servant de corps, deux petits bras, sourcils froncés et bouche boudeuse, petites jambes ; ancre aux pieds.",
     "manifeste": {"image": "morille", "echelle": 0.8}},
    {"id": "vieille_morille_rancuniere", "nom": "Vieille Morille rancunière", "description": "Elle se souvient de chaque pied qui l'a écrasée depuis trois siècles. Elle a une liste.",
     "sorts": ["morille_spores", "morille_bouderie", "rancune_nuage_de_spores"],
     "art": {"type": "image", "reutilise": "morille", "nouveau_svg": None, "manifeste": {"image": "morille", "echelle": 1.1, "teinte": "a08060"}}},
    xp=8, xp_pn=5,
    notes="2 PM, peu de dégâts mais des poisons : une première famille lente et sûre, peu d'XP (gabarit frêle).")

CERF = famille(
    "cerf_enchante", "Cerf enchanté", "Ses bois luisent au crépuscule. Il charge aussi, au crépuscule et le reste du temps.",
    (4, 6), "moyen", "standard", 7, 4, 110, {"force": 0.5, "agilite": 0.5},
    {"tempete": 20, "flamme": -10}, ["cerf_ramure", "cerf_eclat_sylvestre"], "basique",
    [drop("poil_scintillant", 0.5, [1, 2]), drop("bois_de_cerf_enchante", 0.2), drop("couronne_de_ramure", 0.04),
     drop("coiffe_courant_d_air", 0.03), drop("cape_courant_d_air", 0.03), drop("amulette_courant_d_air", 0.03)],
    {"type": "image", "reutilise": "cerf", "nouveau_svg": None, "manifeste": {"image": "cerf", "echelle": 0.8}},
    {"id": "grand_cerf", "nom": "Grand cerf de la Lisière", "description": "Les elfes le saluent, les humains le chassent, les poètes lui écrivent. Il n'aime aucun des trois.",
     "existante": True, "niveau": 9, "pv": 90, "pa": 8, "pm": 5, "initiative": 150, "stats": {"force": 20, "agilite": 20},
     "resistances": {"tempete": 30, "flamme": -5, "acier": 10}, "sorts": ["cerf_ramure", "cerf_eclat_sylvestre", "grand_cerf_charge"],
     "xp": 150, "ecus": [12, 30],
     "butin": [drop("poil_scintillant", 0.9, [2, 4]), drop("bois_de_cerf_enchante", 0.6, [1, 2]), drop("couronne_de_ramure", 0.18),
               drop("coiffe_courant_d_air", 0.08), drop("cape_courant_d_air", 0.08), drop("amulette_courant_d_air", 0.08)],
     "modifications": "Ajouter Force 20 et Agilité 20, et les pièces Courant d'Air au butin.",
     "art": {"type": "image", "reutilise": "cerf", "nouveau_svg": None, "manifeste": {"image": "cerf", "echelle": 1.05, "teinte": "f0e0c0"}}},
    existante=True, pv=36, pv_pn=4, xp=45, xp_pn=6, ecus=[4, 10], stats_base={"force": 0, "agilite": 0},
    stats_pn={"force": 2, "agilite": 2},
    modifications="Tranche 4–6 (poids 3/4/3) à partir de ses valeurs actuelles (niveau 4). Ajouter Force et Agilité par niveau, et les pièces Courant d'Air (coiffe, cape, amulette) au butin.")

ARBRE = famille(
    "arbre_vivant", "Arbre vivant", "Un vieux chêne qui en a assez qu'on lui coupe les branches.",
    (4, 6), "fort", "tank", 7, 1, 35, {"force": 0.75},
    {"acier": 25, "givre": 15, "flamme": -25}, ["arbre_branche", "arbre_racines"], "basique",
    [drop("ecorce_vivante", 0.6, [1, 3]), drop("seve_ancienne", 0.1), drop("cape_d_ecorce", 0.04)],
    {"type": "image", "reutilise": "arbre_vivant", "nouveau_svg": None, "manifeste": {"image": "arbre_vivant", "echelle": 0.85}},
    {"id": "arbre_millenaire", "nom": "Arbre millénaire", "description": "Il a vu naître Sylvebrume. Il compte bien la voir disparaître, sans se presser.",
     "existante": True, "niveau": 10, "pv": 150, "pa": 8, "pm": 1, "initiative": 50, "stats": {"force": 25},
     "resistances": {"acier": 35, "givre": 25, "flamme": -20},
     "sorts": ["arbre_branche", "arbre_racines", "millenaire_ronces", "millenaire_cercle_de_seve"], "xp": 180, "ecus": [15, 35],
     "butin": [drop("ecorce_vivante", 0.9, [2, 5]), drop("seve_ancienne", 0.4, [1, 2]), drop("cape_d_ecorce", 0.18)],
     "modifications": "Ajouter Force 25 ; le reste ne change pas.",
     "art": {"type": "image", "reutilise": "arbre_vivant", "nouveau_svg": None, "manifeste": {"image": "arbre_vivant", "echelle": 1.12, "teinte": "a89a88"}}},
    existante=True, pv=52, pv_pn=8, xp=52, xp_pn=8, ecus=[5, 12], stats_base={"force": 0}, stats_pn={"force": 3}, init_pn=5,
    modifications="Niveau de base 4 (tranche 4–6, poids 1/3/6) : 52 PV et 52 XP au niveau 4, +8 par niveau (au niveau 5, ses valeurs actuelles : 60 PV, 60 XP) ; initiative 35 (+5/niveau) ; Force +3 par niveau.")

BUCHERON = famille(
    "bucheron_de_brumerive", "Bûcheron de Brumerive", "Il a un bon de coupe signé à Hautepierre et une hache aiguisée. Les elfes ont des flèches. Le débat est ouvert.",
    (7, 9), "fort", "costaud", 6, 3, 85, {"force": 1},
    {"acier": 10, "givre": 5, "flamme": 0, "tempete": -10}, ["bucheron_cognee", "bucheron_ca_tombe"], "basique",
    [drop("copeaux_de_bois", 0.55, [1, 3]), drop("bon_de_coupe", 0.12), drop("hache_de_bucheron", 0.04),
     drop("ceinture_de_bucheron", 0.04), drop("anneau_enfant_de_choeur", 0.03), drop("ceinture_enfant_de_choeur", 0.03),
     drop("bottes_enfant_de_choeur", 0.03)],
    {"type": "rig", "reutilise": "humain", "nouveau_svg": "arme « hache » (fer large, manche clair ; partagée avec le briseur)",
     "manifeste": {"rig": "humain", "couleurs": {"tunique": "a83a2a", "manches": "7a2a20", "pantalon": "3a4a6a", "bottes": "4a3424", "ceinture": "3d2b1f", "cheveux": "5a3a22", "barbe": "5a3a22"},
                   "arme": "hache", "accessoires": ["barbe"]}},
    {"id": "abatteur_en_chef", "nom": "Abatteur en chef", "description": "Il a abattu Vieux-Branchu, mille ans d'âge, en une matinée. Il en a fait un banc. Personne ne s'assoit dessus.",
     "sorts": ["bucheron_cognee", "bucheron_ca_tombe", "abatteur_souche_piegee"],
     "art": {"type": "rig", "reutilise": "humain_grand", "nouveau_svg": None,
             "manifeste": {"rig": "humain_grand", "couleurs": {"tunique": "7a1e16", "manches": "5a1610", "pantalon": "2a3a5a", "bottes": "2e2620", "ceinture": "1e1a17", "cheveux": "2e2418", "barbe": "2e2418"},
                           "arme": "hache", "accessoires": ["barbe", "casque"]}}},
    notes="Les humains (camp allié) envahisseurs de la Lisière : « Attention, ça tombe ! » frappe en croix latine (l'arbre qui tombe).")

TISSEUSE = famille(
    "tisseuse_de_brume", "Tisseuse de brume", "Une araignée grosse comme un poney, qui tisse le brouillard de Sylvebrume. Les elfes disent que c'est poétique. De loin.",
    (10, 12), "moyen", "standard", 6, 4, 110, {"chance": 1},
    {"givre": 20, "impie": 10, "acier": 0, "flamme": -15}, ["tisseuse_morsure", "tisseuse_toile"], "basique",
    [drop("fil_de_brume", 0.55, [1, 3]), drop("crochet_d_araignee", 0.12), drop("cape_de_soie_grise", 0.04),
     drop("coiffe_bonhomme_de_neige", 0.03), drop("cape_bonhomme_de_neige", 0.03), drop("amulette_bonhomme_de_neige", 0.03)],
    {"type": "image", "reutilise": None,
     "nouveau_svg": "monstre/araignee.svgt, ~60×38 px : araignée vue de 3/4, abdomen gris perle ({{pelage}}) à motif de toile bleu pâle, céphalothorax plus sombre ({{pelage_ombre}}), 8 pattes fines articulées, 6 petits yeux noirs brillants, crochets ; ancre au centre entre les pattes. Recolorable pour la Mère-Toile.",
     "manifeste": {"image": "araignee", "echelle": 0.85}},
    {"id": "grande_tisseuse", "nom": "Grande Tisseuse", "description": "Sa toile couvre trois clairières. Elle a oublié où elle a rangé la dernière proie.",
     "sorts": ["tisseuse_morsure", "tisseuse_toile", "tisseuse_cocon"],
     "art": {"type": "image", "reutilise": "araignee", "nouveau_svg": None, "manifeste": {"image": "araignee", "echelle": 1.1, "teinte": "b8c0d8"}}},
    notes="Retrait de PM et poisons : il faut frapper fort et vite. Faible à la Flamme.")

MERE_TOILE = {
    "id": "mere_toile", "nom": "La Mère-Toile",
    "description": "Elle tisse depuis l'Âge de l'Aube et n'a jamais fini un seul napperon. Depuis que la Cendre tombe, elle tisse plus vite, et plus noir.",
    "boss": True, "niveau": 12,
    "caracteristiques": {"pv": 270, "pa": 7, "pm": 4, "initiative": 130, "chance": 25},
    "resistances": {"givre": 30, "impie": 15, "tempete": 10, "acier": 5, "flamme": -20},
    "sorts": ["meretoile_venin", "tisseuse_morsure", "tisseuse_toile"],
    "ia": "basique", "xp": 720,
    "phases": [
        {"pv": 65, "message": "La Mère-Toile se retire dans son cocon et tisse la clairière entière.",
         "sorts": ["meretoile_toile_geante"], "effets": [bouclier("givre", 60, 60)]},
        {"pv": 35, "message": "« Mes petites ! … Ah, non : elles sont toutes à la Lisière, à embêter les elfes. »",
         "effets": [bonus("chance", 40, 40, 3)]},
        {"pv": 10, "message": "Elle file un dernier fil… et s'en sert pour recoudre ses plaies.",
         "effets": [soin("givre", 50, 50)]}],
    "butin": [drop("soie_de_la_mere_toile", 1.0), drop("fil_de_brume", 0.9, [2, 4]), drop("anneau_aux_huit_yeux", 0.2),
              drop("fuseau_de_la_mere_toile", 0.12)],
    "ecus": [80, 140]}

ZONE = {
    "id": "sylvebrume", "nom": "Lisière de Sylvebrume", "palette": "sylvebrume", "camp": "neutre",
    "pierre": {"id": "sylvebrume", "carte": "sylvebrume_0_0", "prix": 10, "existante": True},
    "plan_zone": [
        "          x=0                          x=1                         x=2",
        "y=0  [Clairière de la Lisière 1-3 *] ── [Futaie ancienne 4-6] ── [Bosquet des Cerfs 4-6]",
        "          │                               │                         │",
        "y=1  [Sous-bois moussu 1-3] ────────── [Coupe rase 7-9] ──────── [Scierie de Brumerive 7-9]",
        "                                          │                         │",
        "y=2  [Cœur de la Toile ☠ 12] ────────── [Toiles grises 10-12] ──── [Orée du Sud 10-12]",
        "                                                               +══ porte vers Hautepierre 2_0"],
    "cartes": [
        {"id": "sylvebrume_0_0", "existante": True, "nom": "Sylvebrume — Clairière de la Lisière", "x": 0, "y": 0,
         "sorties": {"droite": "sylvebrume_1_0", "bas": "sylvebrume_0_1"}, "palier": "1-3",
         "ambiance": "Le village elfe de départ, inchangé.",
         "elements": "Retouche : ouvrir les trois dernières lignes aux colonnes 6 à 8 (un passage entre les arbres) pour la sortie bas.",
         "ressources": {"F": 4, "C": 3}, "ressources_note": "inchangées",
         "groupes": [{"monstres": ["morille_grincheuse"]}, {"parmi": ["morille_grincheuse"], "nombre": [2, 3]}],
         "groupes_note": "Le cerf et l'arbre (palier 4–6) laissent la place aux morilles : il n'y avait rien au palier 1–3 chez les elfes.",
         "pnj": [], "pnj_note": "Elwyn, Lindorë et Aelthar restent.", "pierre": True, "boss": False},
        {"id": "sylvebrume_1_0", "existante": True, "nom": "Sylvebrume — Futaie ancienne", "x": 1, "y": 0,
         "sorties": {"gauche": "sylvebrume_0_0", "droite": "sylvebrume_2_0", "bas": "sylvebrume_1_1"}, "palier": "4-6",
         "ambiance": "Inchangée : grands arbres et étang.",
         "elements": "Retouches : remplacer par « . » les deux derniers caractères des lignes 15 à 19 (bord droit) et 3 cases des deux dernières lignes (colonnes 8 à 10) pour les sorties droite et bas.",
         "ressources": {"F": 5, "C": 3}, "ressources_note": "inchangées",
         "groupes": [{"parmi": ["cerf_enchante", "arbre_vivant"], "nombre": [2, 3]}, {"monstres": ["arbre_vivant", "cerf_enchante"]},
                     {"monstres": ["arbre_vivant"]}, {"monstres": ["cerf_enchante"]}],
         "groupes_note": "inchangés", "pnj": [], "pierre": False, "boss": False},
        {"id": "sylvebrume_0_1", "existante": False, "nom": "Sylvebrume — Sous-bois moussu", "x": 0, "y": 1,
         "sorties": {"haut": "sylvebrume_0_0", "droite": "sylvebrume_1_1"}, "palier": "1-3",
         "ambiance": "Un sous-bois de mousse épaisse et de ronds de sorcière, où les morilles tiennent conseil (elles boudent).",
         "elements": "Forêt dense (A) sur les bords, clairières rondes reliées par des sentiers (:) ; trois « ronds de sorcière » (cercles de 6 cases praticables autour d'un rocher R) ; un ruisseau (E) étroit au bas.",
         "ressources": {"F": 3, "U": 1},
         "groupes": [{"monstres": ["morille_grincheuse", "morille_grincheuse"]}, {"monstres": ["morille_grincheuse"]},
                     {"parmi": ["morille_grincheuse"], "nombre": [1, 3]}],
         "pnj": [{"marqueur": "a", "id": "tantine_champignolle", "nom": "Tantine Champignolle, cueilleuse", "role": "PNJ d'ambiance",
                  "repliques": ["Celle-là est comestible. Celle-là aussi. Celle-là vous insulte : laissez-la.",
                                "Les morilles grincheuses ? Elles n'aiment pas qu'on les cueille. Personne n'aime, remarquez.",
                                "Si vous trouvez des spores grincheuses, ne les respirez pas. Sauf si vous voulez bouder toute la journée."],
                  "art": {"rig": "humain", "couleurs": {"peau": "f3dcc4", "tunique": "8a6a3a", "manches": "6a5a2a", "pantalon": "5a6a4a", "cheveux": "c8c0b0", "tablier": "d8c8a0"}, "accessoires": ["oreilles_elfe", "tablier"]}}],
         "pierre": False, "boss": False},
        {"id": "sylvebrume_2_0", "existante": False, "nom": "Sylvebrume — Bosquet des Cerfs", "x": 2, "y": 0,
         "sorties": {"gauche": "sylvebrume_1_0", "bas": "sylvebrume_2_1"}, "palier": "4-6",
         "ambiance": "Un bosquet sacré où les cerfs enchantés viennent boire ; un petit autel elfe couvert de lierre.",
         "elements": "Source (E) au centre-haut qui descend en ruisseau vers le bas ; autel : décor « pavillon » en haut-gauche ; arbres (A) en couronne, sol dégagé (les cerfs ont 4 PM, il faut de la place).",
         "ressources": {"F": 2, "C": 2, "Y": 1},
         "groupes": [{"monstres": ["cerf_enchante"]}, {"monstres": ["cerf_enchante", "cerf_enchante"]},
                     {"monstres": ["cerf_enchante", "arbre_vivant"]}, {"monstres": ["arbre_vivant"]}],
         "pnj": [{"marqueur": "a", "id": "poete_lyriandel", "nom": "Lyriandel, poète", "role": "PNJ d'ambiance",
                  "repliques": ["J'écris une ode au Grand Cerf. Quatre cents strophes. Il en manque une : la rime en « -erf ».",
                                "« Ô cerf, ô ramure, ô… » non. Encore raté.",
                                "Le Grand Cerf est passé ce matin. Il a mangé mon brouillon. Je crois que c'était une critique."],
                  "art": {"rig": "humain", "couleurs": {"peau": "f3dcc4", "tunique": "6a4a8a", "manches": "8a6aa8", "pantalon": "4a4a6a", "cheveux": "f0e6c0", "ceinture": "c9a04e"}, "accessoires": ["oreilles_elfe"]}}],
         "pierre": False, "boss": False},
        {"id": "sylvebrume_1_1", "existante": False, "nom": "Sylvebrume — Coupe rase", "x": 1, "y": 1,
         "sorties": {"haut": "sylvebrume_1_0", "gauche": "sylvebrume_0_1", "droite": "sylvebrume_2_1", "bas": "sylvebrume_1_2"}, "palier": "7-9",
         "ambiance": "Une coupe à blanc en pleine forêt : souches, troncs empilés, quelques arbres rescapés. Les bûcherons de Brumerive y travaillent sans relâche.",
         "elements": "Grande zone dégagée semée de souches (rochers R, ou un décor « souche » si on l'ajoute) ; piles de troncs (R alignés par 3) ; lisière d'arbres (A) intacte sur les bords ; chemin de débardage (:) du haut vers le bas.",
         "ressources": {"Y": 2, "C": 2},
         "groupes": [{"monstres": ["bucheron_de_brumerive"]}, {"monstres": ["bucheron_de_brumerive", "bucheron_de_brumerive"]},
                     {"parmi": ["bucheron_de_brumerive", "arbre_vivant"], "nombre": [2, 3]}],
         "pnj": [{"marqueur": "a", "id": "druide_feuillemorte", "nom": "Feuillemorte, druide", "role": "PNJ d'ambiance (acte I elfe)",
                  "repliques": ["Ils ont coupé Vieux-Branchu. Il avait mille ans. Il me devait de l'argent.",
                                "Les humains ont un papier qui les autorise. Nous avons des flèches qui ne les autorisent pas.",
                                "Le Conseil de la Lisière délibère sur l'opportunité de délibérer. Pendant ce temps, faites quelque chose."],
                  "art": {"rig": "humain", "couleurs": {"peau": "f0d8bc", "tunique": "5a6a3a", "manches": "7a5a2a", "pantalon": "4a3a28", "cheveux": "b8b0a0", "barbe": "b8b0a0"}, "arme": "baton", "accessoires": ["oreilles_elfe", "barbe"]}}],
         "pierre": False, "boss": False},
        {"id": "sylvebrume_2_1", "existante": False, "nom": "Sylvebrume — Scierie de Brumerive", "x": 2, "y": 1,
         "sorties": {"haut": "sylvebrume_2_0", "gauche": "sylvebrume_1_1", "bas": "sylvebrume_2_2"}, "palier": "7-9",
         "ambiance": "Une scierie humaine montée sur la rivière, avec sa roue à aubes et son panneau « Bois de Sylvebrume — prix d'usine ».",
         "elements": "Rivière (E) verticale à droite ; scierie : décor « maison » au bord de l'eau ; tas de planches (R) ; enclos de rondins (murets) ; terrain plat à gauche.",
         "ressources": {"Y": 2, "F": 1},
         "groupes": [{"monstres": ["bucheron_de_brumerive", "bucheron_de_brumerive"]}, {"monstres": ["bucheron_de_brumerive"]},
                     {"parmi": ["bucheron_de_brumerive"], "nombre": [2, 3]}],
         "pnj": [], "pierre": False, "boss": False},
        {"id": "sylvebrume_1_2", "existante": False, "nom": "Sylvebrume — Toiles grises", "x": 1, "y": 2,
         "sorties": {"haut": "sylvebrume_1_1", "gauche": "sylvebrume_0_2", "droite": "sylvebrume_2_2"}, "palier": "10-12",
         "ambiance": "Une partie de la forêt où la brume a pris consistance : des toiles géantes tendues entre les troncs, des cocons qui pendent.",
         "elements": "Arbres (A) serrés formant des couloirs tortueux ; quelques arbres morts (décor arbre_mort via la palette ou en A) ; clairières de 4×4 pour combattre ; pas de chemin tracé.",
         "ressources": {"Y": 2, "C": 1},
         "groupes": [{"monstres": ["tisseuse_de_brume"]}, {"monstres": ["tisseuse_de_brume", "tisseuse_de_brume"]},
                     {"parmi": ["tisseuse_de_brume"], "nombre": [1, 3]}, {"monstres": ["tisseuse_de_brume", "bucheron_de_brumerive"]}],
         "pnj": [], "pierre": False, "boss": False},
        {"id": "sylvebrume_2_2", "existante": False, "nom": "Sylvebrume — Orée du Sud", "x": 2, "y": 2,
         "sorties": {"haut": "sylvebrume_2_1", "gauche": "sylvebrume_1_2"}, "portes": ["hautepierre_2_0"], "palier": "10-12",
         "ambiance": "La forêt s'ouvre sur les plaines du sud ; une tour de guet elfe en ruine surveille la route de Hautepierre.",
         "elements": "Arbres (A) en haut, plaine dégagée en bas ; tour de guet en ruine (rochers R en cercle) au centre ; sentier (:) jusqu'au passage « + » sur le bord bas (porte vers hautepierre_2_0, décor « poteau_indicateur » à côté).",
         "ressources": {"Y": 1, "T": 1},
         "groupes": [{"monstres": ["tisseuse_de_brume", "tisseuse_de_brume"]}, {"monstres": ["tisseuse_de_brume"]},
                     {"parmi": ["tisseuse_de_brume"], "nombre": [1, 2]}],
         "pnj": [{"marqueur": "a", "id": "eclaireuse_sylphine", "nom": "Sylphine, éclaireuse", "role": "PNJ d'ambiance, annonce Hautepierre",
                  "repliques": ["Au sud, Hautepierre. Des humains, des murs, du bruit. Je déconseille.",
                                "Mais vous irez quand même. Les jeunes vont toujours voir les humains. Ça leur passe vers trois cents ans.",
                                "Les toiles avancent vers la Lisière. Quelque chose les pousse. Quelque chose de gris, qui sent le brûlé."],
                  "art": {"rig": "humain", "couleurs": {"peau": "f3dcc4", "tunique": "3f6a4a", "manches": "5a7a4a", "pantalon": "4a5a3a", "bottes": "6b5236", "cheveux": "c89a5a"}, "arme": "arc", "accessoires": ["oreilles_elfe"]}}],
         "passage_inter_zone": "Porte « + » vers hautepierre_2_0 (route), posée par le lot Hautepierre avec sa réciproque.",
         "pierre": False, "boss": False},
        {"id": "sylvebrume_0_2", "existante": False, "nom": "Sylvebrume — Cœur de la Toile", "x": 0, "y": 2,
         "sorties": {"droite": "sylvebrume_1_2"}, "palier": "10-12",
         "ambiance": "Une clairière entièrement tendue de soie grise, au centre de laquelle trône la Mère-Toile.",
         "elements": "Clairière circulaire (9×9 praticable) cernée d'arbres (A) épais ; cocons (R) répartis dans la clairière comme couverts ; une seule entrée à droite.",
         "ressources": {},
         "groupes": [{"monstres": ["mere_toile"], "reapparition": [900, 1200]}, {"monstres": ["tisseuse_de_brume", "tisseuse_de_brume"]}],
         "groupes_note": "Groupe 1 : la Mère-Toile seule, fixe, réapparition 15 à 20 min ; groupe 2 à l'entrée.",
         "pnj": [], "pierre": False, "boss": True}],
    "familles": [MORILLE, CERF, ARBRE, BUCHERON, TISSEUSE],
    "boss": {"id": "mere_toile", "carte": "sylvebrume_0_2", "groupe": ["mere_toile"], "reapparition": [900, 1200],
             "json": MERE_TOILE,
             "sorts": ligne_sorts(["meretoile_venin", "tisseuse_morsure", "tisseuse_toile", "meretoile_toile_geante"]),
             "art": {"type": "image", "reutilise": "araignee", "nouveau_svg": None,
                     "manifeste": {"image": "araignee", "echelle": 1.5, "teinte": "d8c8f0"}},
             "equilibrage": "~330 PV effectifs (270 + bouclier 60), ~16 dégâts/tour avec poisons, retrait de PM : un combat de placement. Faible à la Flamme (−20)."},
    "progression": ("Elfes : « lent au début, riche au milieu ». Palier 1–3 maigre : une seule famille faible (morilles, peu d'XP, 2 PM) sur 2 cartes — l'elfe démarre lentement mais sans risque. "
                    "Palier 4–6 riche et costaud : cerfs et arbres vivants (les deux familles historiques) sur 3 cartes (Futaie, Bosquet, et quelques arbres à la Coupe rase) — beaucoup d'XP et de butin rare. "
                    "Palier 7–9 : les bûcherons humains (envahisseurs de l'acte I) sur 2 cartes. Palier 10–12 : tisseuses de brume sur 2 cartes, puis la Mère-Toile. "
                    "Asymétrie : départ le plus lent des trois zones, milieu le plus riche, beaucoup de contrôle (PM retirés, poisons) qui récompense la portée de l'Œil perçant."),
}
