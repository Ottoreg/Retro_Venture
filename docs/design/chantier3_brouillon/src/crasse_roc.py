"""Galeries de Crasse-Roc (gobelins, camp ennemi)."""
from common import *

# ---------------- objets ----------------
ressource("aile_de_vampipistrelle", "Aile de vampipistrelle", "commun",
          "Fine comme du papier, solide comme du cuir, et elle sent la cave.", "butin:vampipistrelle",
          "aile de chauve-souris violette dépliée, nervures sombres, petite griffe au coude")
ressource("guano_luisant", "Guano luisant", "peu_commun",
          "De l'or, d'après Gnark. De l'or qui sent mauvais, mais de l'or.", "butin:vampipistrelle",
          "petit tas grisâtre posé dans une coupelle, trois points verts phosphorescents")
ressource("maillon_de_cotte", "Maillon de cotte", "commun",
          "Un anneau de cotte de mailles. Il en faut beaucoup pour faire une cotte, et un milicien pour la remplir.",
          "butin:milicien_de_hautepierre", "trois anneaux de fer entrelacés, reflet gris-bleu")
ressource("ecusson_de_milice", "Écusson de milice", "peu_commun",
          "Une tour blanche sur fond bleu. Les gobelins le collectionnent, les miliciens le regrettent.",
          "butin:milicien_de_hautepierre", "écusson en tissu bleu, tour blanche brodée, fil qui pend")
ressource("sifflet_de_contremaitre", "Sifflet de contremaître", "commun",
          "Trois coups : au travail. Deux coups : plus vite. Un coup : vous êtes viré.", "butin:contremaitre_zele",
          "sifflet de laiton terni au bout d'un cordon rouge")
ressource("registre_des_heures", "Registre des heures", "peu_commun",
          "Toutes les heures supplémentaires y sont notées. Aucune n'a été payée.", "butin:contremaitre_zele",
          "gros carnet relié de cuir, pages cornées, une plume coincée dedans")
ressource("corne_du_balourd", "Corne du Balourd", "rare",
          "Encore tiède. Si on la porte à l'oreille, on entend les galeries s'effondrer.", "boss:balourd_des_abimes",
          "corne noire recourbée aux veines rouge braise, pointe incandescente")

equipement("cape_de_vampipistrelle", "Cape de vampipistrelle", "cape", "peu_commun", 5,
           "Cousue d'ailes. On ne vole pas avec, mais on a l'air de pouvoir.",
           {"agilite": 0.4, "chance": 0.3, "initiative": 0.3}, "butin:vampipistrelle",
           "cape violette découpée en festons d'aile de chauve-souris, col haut")
equipement("epee_de_milicien", "Épée de milicien", "arme", "commun", 8,
           "Modèle réglementaire de Hautepierre. Gravée « Propriété de la milice — ne pas perdre ». Perdue.",
           {"force": 0.6, "vitalite": 0.4}, "butin:milicien_de_hautepierre",
           "épée droite à garde en croix, pommeau bleu orné d'une petite tour blanche",
           attaque=attaque(8, "commun", "acier", 4, (1, 1)))
equipement("bottes_de_milicien", "Bottes de milicien", "bottes", "peu_commun", 10,
           "Cirées pour la parade, crottées pour la patrouille.",
           {"vitalite": 0.5, "force": 0.3, "initiative": 0.2}, "butin:milicien_de_hautepierre",
           "bottes de cuir noir montantes, boucles de fer, revers bleu")
equipement("amulette_sifflet", "Amulette-sifflet", "amulette", "peu_commun", 11,
           "Un sifflet de contremaître porté en pendentif. Les gobelins sursautent quand vous respirez fort.",
           {"initiative": 0.3, "agilite": 0.4, "sagesse": 0.3}, "butin:contremaitre_zele",
           "sifflet de laiton suspendu à une chaînette, petite pierre verte incrustée")
equipement("fouet_du_balourd", "Fouet du Balourd", "arme", "epique", 12,
           "Une lanière de feu qui ne s'éteint pas. Ne pas ranger dans le sac à côté des parchemins.",
           {"intelligence": 0.5, "vitalite": 0.3, "dommages": 0.2}, "boss:balourd_des_abimes",
           "fouet noir enroulé dont la lanière se termine en flamme orange, manche en corne",
           attaque=attaque(12, "epique", "flamme", 4, (1, 3)), boutique=False)
equipement("cape_de_fumee", "Cape de fumée", "cape", "rare", 12,
           "Taillée dans la fumée du Balourd. Elle sent le roussi, mais elle a de l'allure.",
           {"intelligence": 0.4, "agilite": 0.3, "vitalite": 0.3}, "boss:balourd_des_abimes",
           "cape gris anthracite aux bords qui se dissipent en volutes, braises rouges dans les plis", boutique=False)

# ---------------- sorts ----------------
sort("vampipistrelle_sucon", "Suçon", "Une petite morsure, très affectueuse, très impie.",
     3, (1, 1), [dg("impie", 4, 6)], relance={"par_tour": 2})
sort("vampipistrelle_ultrason", "Ultrason", "Un cri si aigu qu'on ne vise plus droit.",
     3, (1, 4), [dg("tempete", 3, 5), malus("portee", 1, 1, 1)], ldv=False)
sort("comtesse_nuee", "Nuée de la comtesse", "Toute la famille vient dîner. Vous êtes le dîner.",
     5, (1, 4), [dg("impie", 5, 7)], zone={"type": "cercle", "taille": 1})
sort("milicien_coup_d_epee", "Coup d'épée réglementaire", "Exécuté selon le manuel de la milice, page 12.",
     4, (1, 1), [dg("acier", 7, 10)])
sort("milicien_bouclier_leve", "Bouclier levé", "Position de garde numéro 3. Il ne connaît que celle-là, mais il la connaît bien.",
     2, (0, 0), [bouclier("acier", 8, 12)], ldv=False, relance={"par_tour": 1, "delai": 2})
sort("sergent_rappel_a_l_ordre", "Rappel à l'ordre", "« Vous, là ! Approchez ! » On approche, c'est plus fort que soi.",
     3, (2, 4), [simple("attirance", 2, 2), dg("acier", 4, 6)], en_ligne=True, relance={"par_tour": 1, "delai": 1})
sort("contremaitre_coup_de_baton", "Coup de bâton", "Motivation par l'exemple. Et par le bâton.",
     3, (1, 2), [dg("acier", 5, 7)], relance={"par_tour": 2})
sort("contremaitre_heures_sup", "Heures sup'", "Un collègue gagne 2 PA tout de suite. Non payés, évidemment.",
     2, (1, 4), [simple("gain_pa", 2, 2, "allies")], relance={"par_tour": 1, "delai": 2})
sort("contremaitre_retenue_sur_salaire", "Retenue sur salaire", "Vos dégâts sont retenus à la source.",
     3, (2, 5), [dg("tempete", 4, 6), malus("dommages", 3, 3, 2)])
sort("chef_licenciement", "Licenciement", "« Vous êtes viré ! » La porte, c'est par là. Loin.",
     4, (1, 2), [dg("acier", 6, 9), simple("poussee", 3, 3)])
sort("balourd_lame_de_braise", "Lame de braise", "Une épée faite de feu. Ou un feu en forme d'épée : il n'a jamais su.",
     4, (1, 1), [dg("flamme", 8, 11)])
sort("balourd_fouet", "Fouet de flammes", "Il vous ramène vers lui, poliment, par le cou.",
     4, (1, 3), [dg("flamme", 6, 9), simple("attirance", 1, 1)])
sort("balourd_crachat_de_lave", "Crachat de lave", "Il n'a pas de manières. Il a de la lave.",
     3, (2, 6), [dg("flamme", 4, 6)], zone={"type": "cercle", "taille": 1})
sort("balourd_pluie_de_braises", "Pluie de braises", "Le plafond de la galerie s'embrase. Personne ne va aimer la suite.",
     3, (1, 5), [glyphe(2, [dg("flamme", 3, 5, "ennemis")])], zone={"type": "cercle", "taille": 2}, ldv=False,
     relance={"par_tour": 1, "delai": 3})

# ---------------- familles ----------------
RAT = famille(
    "rat_des_galeries", "Rat des galeries", "Il vivait là avant les gobelins. Il compte bien y vivre après.",
    (1, 3), "faible", "frele", 5, 4, 60, {"force": 1},
    {"tempete": -10}, ["rat_morsure", "rat_grignotage"], "basique",
    [drop("queue_de_rat", 0.6, [1, 2]), drop("dent_de_rat", 0.3), drop("bottes_feutrees", 0.05),
     drop("coiffe_fouineur", 0.02), drop("amulette_fouineur", 0.02), drop("cape_fouineur", 0.02)],
    {"type": "image", "reutilise": "rat", "nouveau_svg": None, "manifeste": {"image": "rat", "echelle": 0.8}},
    {"id": "rat_roi", "nom": "Rat-roi", "description": "Douze rats noués par la queue, un seul trône, beaucoup d'opinions.",
     "existante": True, "niveau": 5, "pv": 40, "pa": 6, "pm": 4, "initiative": 90, "stats": {"force": 0},
     "resistances": {"tempete": -5, "acier": 5}, "sorts": ["rat_morsure", "rat_grignotage", "rat_roi_morsure_royale"],
     "xp": 60, "ecus": [5, 15],
     "butin": [drop("queue_de_rat", 0.9, [2, 4]), drop("dent_de_rat", 0.7, [1, 2]), drop("bottes_feutrees", 0.2),
               drop("coiffe_fouineur", 0.06), drop("amulette_fouineur", 0.06), drop("cape_fouineur", 0.06)],
     "modifications": "Ajouter les trois pièces du Fouineur au butin ; rien d'autre.",
     "art": {"type": "image", "reutilise": "rat", "nouveau_svg": None, "manifeste": {"image": "rat", "echelle": 1.15, "teinte": "c9b9a0"}}},
    existante=True, pv=14, pv_pn=3, xp=12, xp_pn=4, ecus=[1, 4], stats_base={"force": 0}, stats_pn={"force": 5},
    modifications="Stats inchangées (déjà en tranche 1–3, poids 6/3/1). Ajouter les pièces du Fouineur (coiffe, amulette, cape) au butin : un fouineur chez les rats, évidemment.")

GROUILLEUR = famille(
    "grouilleur", "Grouilleur", "Un mille-pattes vert de la taille d'un chien, qui crache et qui ne compte pas ses pattes.",
    (1, 3), "fort", "standard", 6, 3, 60, {"force": 0.75, "intelligence": 0.75},
    {"givre": 6, "flamme": 6, "acier": -5}, ["grouilleur_pinces", "grouilleur_crachat"], "basique",
    [drop("carapace_de_grouilleur", 0.5, [1, 2]), drop("glande_acide", 0.15), drop("ceinture_de_carapace", 0.05),
     drop("anneau_presse", 0.02), drop("bottes_presse", 0.02), drop("ceinture_presse", 0.02)],
    {"type": "image", "reutilise": "grouilleur", "nouveau_svg": None, "manifeste": {"image": "grouilleur", "echelle": 0.85}},
    {"id": "grouilleur_ancestral", "nom": "Grouilleur ancestral", "description": "Il a plus de pattes que d'années, et il a beaucoup d'années.",
     "existante": True, "niveau": 7, "pv": 65, "pa": 7, "pm": 3, "initiative": 90, "stats": {"force": 0, "intelligence": 0},
     "resistances": {"givre": 20, "flamme": 20, "acier": 0}, "sorts": ["grouilleur_pinces", "grouilleur_crachat", "ancestral_jet_d_acide"],
     "xp": 100, "ecus": [8, 20],
     "butin": [drop("carapace_de_grouilleur", 0.9, [2, 4]), drop("glande_acide", 0.5, [1, 2]), drop("ceinture_de_carapace", 0.2),
               drop("anneau_presse", 0.06), drop("bottes_presse", 0.06), drop("ceinture_presse", 0.06)],
     "modifications": "Ajouter les trois pièces du Pressé (il a beaucoup de pattes, il est toujours pressé) au butin.",
     "art": {"type": "image", "reutilise": "grouilleur", "nouveau_svg": None, "manifeste": {"image": "grouilleur", "echelle": 1.15, "teinte": "b8a878"}}},
    existante=True, pv=18, pv_pn=4, xp=16, xp_pn=7, ecus=[3, 8], stats_base={"force": 0, "intelligence": 0},
    stats_pn={"force": 3, "intelligence": 3}, res_pn={"givre": 2, "flamme": 2},
    modifications="Stats inchangées (tranche 1–3, poids 1/3/6). Ajouter les pièces du Pressé (anneau, bottes, ceinture) au butin.")

VAMPI = famille(
    "vampipistrelle", "Vampipistrelle", "Une pipistrelle qui s'est prise pour un vampire. Personne n'a osé la contredire.",
    (4, 6), "moyen", "frele", 6, 5, 120, {"agilite": 0.5, "chance": 0.5},
    {"tempete": 20, "givre": 5, "acier": -10, "flamme": -5}, ["vampipistrelle_sucon", "vampipistrelle_ultrason"], "basique",
    [drop("aile_de_vampipistrelle", 0.55, [1, 2]), drop("guano_luisant", 0.12), drop("cape_de_vampipistrelle", 0.04),
     drop("anneau_bonhomme_de_neige", 0.03), drop("ceinture_bonhomme_de_neige", 0.03), drop("bottes_bonhomme_de_neige", 0.03)],
    {"type": "image", "reutilise": None,
     "nouveau_svg": "monstre/vampipistrelle.svgt, ~44×34 px : chauve-souris en vol stationnaire vue de 3/4, corps rond brun-violet ({{pelage}}), grandes ailes membraneuses violet sombre déployées en V, grandes oreilles pointues, deux petits crocs blancs, yeux rouges ; ombre au sol décollée (ellipse à ~8 px sous les pieds, l'ancre au centre de l'ombre).",
     "manifeste": {"image": "vampipistrelle", "echelle": 0.85}},
    {"id": "vampipistrelle_comtesse", "nom": "Vampipistrelle comtesse", "description": "Elle exige qu'on l'appelle « Madame la Comtesse ». Elle mord ceux qui oublient.",
     "sorts": ["vampipistrelle_sucon", "vampipistrelle_ultrason", "comtesse_nuee"], "pm": 5,
     "art": {"type": "image", "reutilise": "vampipistrelle", "nouveau_svg": None,
             "manifeste": {"image": "vampipistrelle", "echelle": 1.1, "teinte": "d8a0b8"}}},
    notes="Vole au-dessus du sol (5 PM) : elle vient chercher les tireurs. Faible à l'Acier.")

MILICIEN = famille(
    "milicien_de_hautepierre", "Milicien de Hautepierre", "Envoyé « sécuriser » les galeries. Il sécurise surtout les tonneaux de bière du poste.",
    (7, 9), "fort", "standard", 6, 3, 95, {"force": 1},
    {"acier": 20, "flamme": 5, "tempete": 0, "givre": -10, "sacre": 5}, ["milicien_coup_d_epee", "milicien_bouclier_leve"], "basique",
    [drop("maillon_de_cotte", 0.5, [1, 3]), drop("ecusson_de_milice", 0.12), drop("casque_cabosse", 0.04),
     drop("epee_de_milicien", 0.04), drop("bottes_de_milicien", 0.04),
     drop("cape_forgeron_hargneux", 0.03), drop("ceinture_forgeron_hargneux", 0.03), drop("bottes_forgeron_hargneux", 0.03)],
    {"type": "rig", "reutilise": "humain", "nouveau_svg": "accessoire « casque » (casque rond de fer à nasal, 2 vues ; partagé avec plusieurs familles)",
     "manifeste": {"rig": "humain", "couleurs": {"tunique": "4a6a9a", "manches": "8a8f96", "pantalon": "3a3a4a", "bottes": "2e2620", "ceinture": "c9a04e", "cheveux": "5a3a22"},
                   "arme": "epee", "accessoires": ["casque"]}},
    {"id": "sergent_de_milice", "nom": "Sergent de la milice", "description": "Vingt ans de service, trois promotions, aucune bataille. Ça va changer, croit-il.",
     "sorts": ["milicien_coup_d_epee", "milicien_bouclier_leve", "sergent_rappel_a_l_ordre"],
     "art": {"type": "rig", "reutilise": "humain_grand", "nouveau_svg": None,
             "manifeste": {"rig": "humain_grand", "couleurs": {"tunique": "2e4a7a", "manches": "a8aeb6", "pantalon": "2a2a36", "bottes": "1e1a17", "ceinture": "e0b860", "cheveux": "8a8478", "barbe": "8a8478"},
                           "arme": "epee", "accessoires": ["casque", "barbe"]}}},
    notes="Des humains combattus par des gobelins : la milice d'Hautepierre (camp allié) est l'ennemie de l'acte I des gobelins. Armure : forte résistance Acier, faible au Givre.")

CONTREMAITRE = famille(
    "contremaitre_zele", "Contremaître zélé", "Il fait travailler les autres avec une énergie qu'il n'a jamais mise à travailler lui-même.",
    (10, 12), "moyen", "soutien", 6, 3, 100, {"force": 0.5, "agilite": 0.5},
    {"acier": 10, "tempete": 10, "flamme": -10, "givre": -5},
    ["contremaitre_coup_de_baton", "contremaitre_heures_sup", "contremaitre_retenue_sur_salaire"], "soutien",
    [drop("sifflet_de_contremaitre", 0.5, [1, 2]), drop("registre_des_heures", 0.12), drop("amulette_sifflet", 0.04),
     drop("anneau_pyromane_repenti", 0.03), drop("ceinture_pyromane_repenti", 0.03), drop("bottes_pyromane_repenti", 0.03)],
    {"type": "rig", "reutilise": "gobelin_veteran", "nouveau_svg": None,
     "manifeste": {"rig": "gobelin_veteran", "couleurs": {"peau": "7c9a48", "tunique": "5e4a32", "manches": "4a3a28", "pantalon": "3e3226", "cheveux": "2a2018", "ceinture": "c9a04e", "tablier": "3a3028"},
                   "arme": "baton", "accessoires": ["casque", "tablier"]}},
    {"id": "contremaitre_en_chef", "nom": "Contremaître en chef", "description": "Il a un bureau, un tampon et un sifflet en or. Il ne descend jamais dans les galeries, sauf pour licencier.",
     "sorts": ["contremaitre_coup_de_baton", "contremaitre_heures_sup", "contremaitre_retenue_sur_salaire", "chef_licenciement"],
     "art": {"type": "rig", "reutilise": "gobelin_chef", "nouveau_svg": None,
             "manifeste": {"rig": "gobelin_chef", "couleurs": {"peau": "6a8a3a", "tunique": "2a2a32", "manches": "1e1e26", "pantalon": "2a2420", "cheveux": "1e1a16", "ceinture": "e0b860", "tablier": "5a2a1a"},
                           "arme": "baton", "accessoires": ["casque", "tablier", "barbe"]}}},
    notes="IA soutien : se tient à distance, donne des PA aux autres contremaîtres et retient vos Dommages. Les groupes de 2–3 sont les plus durs de la zone.")

BALOURD = {
    "id": "balourd_des_abimes", "nom": "Le Balourd des Abîmes",
    "description": "Les gobelins ont creusé trop profond. Le contremaître dit que c'est la faute des ouvriers. Le Balourd dit que c'est la faute de tout le monde.",
    "boss": True, "niveau": 12,
    "caracteristiques": {"pv": 300, "pa": 7, "pm": 3, "initiative": 90, "intelligence": 20},
    "resistances": {"flamme": 40, "acier": 15, "tempete": 0, "givre": -25},
    "sorts": ["balourd_lame_de_braise", "balourd_fouet", "balourd_crachat_de_lave"],
    "ia": "basique", "xp": 760,
    "phases": [
        {"pv": 70, "message": "« Qui a creusé ici ? Je veux le nom du contremaître ! » Sa peau de roche se referme, fissure par fissure.",
         "effets": [bonus("resistance", 25, 25, 3, element="givre"), bonus("resistance", 15, 15, 3, element="acier")]},
        {"pv": 40, "message": "Le Balourd s'embrase et le plafond de la galerie prend feu.",
         "sorts": ["balourd_pluie_de_braises"], "effets": [bonus("intelligence", 30, 30, 3)]},
        {"pv": 15, "message": "« Bon. On peut peut-être négocier ? » Il ne négocie pas : il déploie ses ailes de fumée.",
         "effets": [bonus("pm", 3, 3, 3), bonus("portee", 2, 2, 3)]}],
    "butin": [drop("corne_du_balourd", 1.0), drop("cape_de_fumee", 0.2), drop("fouet_du_balourd", 0.12),
              drop("registre_des_heures", 0.5, [1, 2])],
    "ecus": [90, 150]}

ZONE = {
    "id": "crasse_roc", "nom": "Galeries de Crasse-Roc", "palette": "crasse_roc", "camp": "ennemi",
    "pierre": {"id": "crasse_roc", "carte": "crasse_roc_0_0", "prix": 10, "existante": True},
    "plan_zone": [
        "          x=0                       x=1                        x=2",
        "y=0  [Entrée des galeries 1-3 *] ── [Le Crassier 1-3] ── [Puits des Vampipistrelles 4-6]",
        "          │                            │                          │",
        "y=1  [La Rataillerie 1-3] ──────── [Galerie effondrée 4-6] ── [Poste avancé de la Milice 7-9]",
        "                                                                  │",
        "y=2  [Route des Charrois 10-12] ── [Forges noires 10-12] ──── [Carrière aux Échos 7-9]",
        "   +══ porte vers Hautepierre 4_2      │",
        "y=3                              [L'Abîme du Balourd ☠ 12]"],
    "cartes": [
        {"id": "crasse_roc_0_0", "existante": True, "nom": "Crasse-Roc — Entrée des galeries", "x": 0, "y": 0,
         "sorties": {"droite": "crasse_roc_1_0", "bas": "crasse_roc_0_1"}, "palier": "1-3",
         "ambiance": "Le campement de départ des gobelins, inchangé.",
         "elements": "Retouche : ouvrir 3 cases de la dernière ligne (colonnes 7 à 9, sous le chemin) pour la sortie bas.",
         "ressources": {"U": 3, "I": 4}, "ressources_note": "inchangées",
         "groupes": [{"monstres": ["rat_des_galeries", "rat_des_galeries"]}, {"parmi": ["grouilleur", "rat_des_galeries"], "nombre": [1, 2]}],
         "groupes_note": "inchangés", "pnj": [], "pnj_note": "Grumm, Zogrub et Krogma restent.", "pierre": True, "boss": False},
        {"id": "crasse_roc_1_0", "existante": True, "nom": "Crasse-Roc — Le Crassier", "x": 1, "y": 0,
         "sorties": {"gauche": "crasse_roc_0_0", "droite": "crasse_roc_2_0", "bas": "crasse_roc_1_1"}, "palier": "1-3",
         "ambiance": "Inchangé : terrils et galerie.",
         "elements": "Retouches : remplacer par « . » le dernier caractère des lignes 15 à 19 (bord droit) pour la sortie droite, et 3 cases de la dernière ligne (colonnes 8 à 10) pour la sortie bas ; vérifier l'accessibilité.",
         "ressources": {"U": 3, "I": 3}, "ressources_note": "inchangées",
         "groupes": [{"monstres": ["rat_des_galeries", "rat_des_galeries", "rat_des_galeries"]}, {"monstres": ["grouilleur", "rat_des_galeries"]},
                     {"parmi": ["grouilleur", "rat_des_galeries"], "nombre": [2, 3]}, {"monstres": ["grouilleur"]}],
         "groupes_note": "inchangés", "pnj": [], "pierre": False, "boss": False},
        {"id": "crasse_roc_0_1", "existante": False, "nom": "Crasse-Roc — La Rataillerie", "x": 0, "y": 1,
         "sorties": {"haut": "crasse_roc_0_0", "droite": "crasse_roc_1_1"}, "palier": "1-3",
         "ambiance": "Une décharge de galerie où les rats ont fondé une ville : tas de ferraille, nids de chiffons, pièges à rats tous déclenchés.",
         "elements": "Cuvette entourée de rochers (R) épais sur 2 rangées, nombreux petits îlots de R (tas de ferraille) qui forment des couloirs ; une flaque (E) au centre ; décor « cabane » (atelier de Mamie Ratine) en haut-gauche.",
         "ressources": {"U": 3, "F": 1},
         "groupes": [{"monstres": ["rat_des_galeries", "rat_des_galeries"]}, {"parmi": ["rat_des_galeries"], "nombre": [3, 3]},
                     {"monstres": ["rat_des_galeries", "grouilleur"]}, {"monstres": ["grouilleur", "grouilleur"]}],
         "pnj": [{"marqueur": "a", "id": "mamie_ratine", "nom": "Mamie Ratine, éleveuse de rats (retraitée)", "role": "PNJ d'ambiance",
                  "repliques": ["Avant, j'élevais des rats pour les courses. Puis les rats ont gagné, et ils sont partis avec la caisse.",
                                "Le Rat-roi ? Douze rats noués par la queue. Je leur avais dit de ne pas jouer à la ronde.",
                                "Si tu ramènes des queues de rat, garde-les. Ça peut toujours servir. Je ne sais pas à quoi."],
                  "art": {"rig": "gobelin", "couleurs": {"peau": "8a9a5a", "tunique": "6a4a5a", "manches": "5a3a4a", "pantalon": "4a3a28", "cheveux": "d8d0c0", "tablier": "a89a80"}, "accessoires": ["tablier"]}}],
         "pierre": False, "boss": False},
        {"id": "crasse_roc_2_0", "existante": False, "nom": "Crasse-Roc — Puits des Vampipistrelles", "x": 2, "y": 0,
         "sorties": {"gauche": "crasse_roc_1_0", "bas": "crasse_roc_2_1"}, "palier": "4-6",
         "ambiance": "Un ancien puits d'aération effondré en gouffre, plein de vampipistrelles qui dorment la tête en bas… sauf quand on passe.",
         "elements": "Grand gouffre (E, eau noire) de 5×7 au centre, bordé de rochers ; corniche praticable tout autour (2 à 3 cases de large) ; décor « galerie » (entrée de mine) en haut-droite ; stalagmites (R) isolées qui coupent les lignes de vue.",
         "ressources": {"U": 2, "I": 2},
         "groupes": [{"monstres": ["vampipistrelle"]}, {"monstres": ["vampipistrelle", "vampipistrelle"]},
                     {"parmi": ["vampipistrelle"], "nombre": [2, 3]}],
         "pnj": [{"marqueur": "a", "id": "gnark_guanoculteur", "nom": "Gnark, guano-culteur", "role": "PNJ d'ambiance",
                  "repliques": ["Le guano de vampipistrelle, c'est de l'or ! De l'or qui sent mauvais, mais de l'or !",
                                "La Comtesse ? Une vampipistrelle grosse comme un chien. Elle se croit noble. Elle mord comme une roturière.",
                                "Ne regarde pas en l'air en parlant. Crois-moi."],
                  "art": {"rig": "gobelin", "couleurs": {"peau": "6f8a3e", "tunique": "5a5040", "manches": "4a4030", "pantalon": "3e3226", "cheveux": "2a2018"}, "accessoires": ["chapeau_paille"]}}],
         "pierre": False, "boss": False},
        {"id": "crasse_roc_1_1", "existante": False, "nom": "Crasse-Roc — Galerie effondrée", "x": 1, "y": 1,
         "sorties": {"haut": "crasse_roc_1_0", "gauche": "crasse_roc_0_1", "droite": "crasse_roc_2_1"}, "palier": "4-6",
         "ambiance": "Une galerie dont le plafond s'est écroulé : rails tordus, wagonnets renversés, poutres.",
         "elements": "Deux longs couloirs de rails (chemins « : » rectilignes) séparés par des éboulis (R) ; quelques poutres de soutènement (A) ; le bas de la carte est fermé par l'éboulement (pas de sortie bas).",
         "ressources": {"I": 2, "U": 1, "T": 1},
         "groupes": [{"monstres": ["vampipistrelle", "vampipistrelle"]}, {"monstres": ["vampipistrelle"]},
                     {"parmi": ["vampipistrelle", "grouilleur"], "nombre": [2, 3]}],
         "pnj": [], "pierre": False, "boss": False},
        {"id": "crasse_roc_2_1", "existante": False, "nom": "Crasse-Roc — Poste avancé de la Milice", "x": 2, "y": 1,
         "sorties": {"haut": "crasse_roc_2_0", "gauche": "crasse_roc_1_1", "bas": "crasse_roc_2_2"}, "palier": "7-9",
         "ambiance": "Les humains de Hautepierre ont planté un poste fortifié à l'entrée des galeries : palissade, tente, étendard à tour blanche.",
         "elements": "Palissade de murs (M) en carré au centre-droit, ouverte en bas ; décor « maison » (corps de garde) dedans ; tonneaux (R) ; terrain dégagé à gauche pour combattre.",
         "ressources": {"I": 2, "T": 2},
         "groupes": [{"monstres": ["milicien_de_hautepierre"]}, {"monstres": ["milicien_de_hautepierre", "milicien_de_hautepierre"]},
                     {"monstres": ["milicien_de_hautepierre", "vampipistrelle"]}, {"parmi": ["milicien_de_hautepierre"], "nombre": [1, 3]}],
         "pnj": [], "pierre": False, "boss": False},
        {"id": "crasse_roc_2_2", "existante": False, "nom": "Crasse-Roc — Carrière aux Échos", "x": 2, "y": 2,
         "sorties": {"haut": "crasse_roc_2_1", "gauche": "crasse_roc_1_2"}, "palier": "7-9",
         "ambiance": "Une carrière en gradins où chaque coup de pioche résonne trois fois. Les miliciens y « inspectent » le travail des gobelins.",
         "elements": "Gradins : 3 bandes horizontales de rochers (R) percées de rampes de 2 cases ; veines de minerai le long des gradins ; un treuil (décor « cabane ») en bas-gauche.",
         "ressources": {"T": 3, "I": 2},
         "groupes": [{"monstres": ["milicien_de_hautepierre", "milicien_de_hautepierre"]}, {"monstres": ["milicien_de_hautepierre"]},
                     {"parmi": ["milicien_de_hautepierre"], "nombre": [2, 3]}],
         "pnj": [{"marqueur": "a", "id": "grizzlok_le_pacifiste", "nom": "Grizzlok, gobelin pacifiste", "role": "PNJ d'ambiance (acte II en germe)",
                  "repliques": ["J'ai déposé un préavis de grève. Le contremaître a déposé un préavis de coups de bâton.",
                                "Les humains disent qu'on est les méchants. Le contremaître dit que ce sont eux. Et si c'était le contremaître ?",
                                "Un jour, il y aura un syndicat des gobelins. Avec des chaises. Des vraies."],
                  "art": {"rig": "gobelin", "couleurs": {"peau": "7a9a4a", "tunique": "a8a080", "manches": "8a8060", "pantalon": "4a3a28", "cheveux": "3a2a1a"}}}],
         "pierre": False, "boss": False},
        {"id": "crasse_roc_1_2", "existante": False, "nom": "Crasse-Roc — Forges noires", "x": 1, "y": 2, "palette": "forges",
         "sorties": {"droite": "crasse_roc_2_2", "gauche": "crasse_roc_0_2", "bas": "crasse_roc_1_3"}, "palier": "10-12",
         "ambiance": "Les forges du Souverain : rigoles de lave, enclumes, cheminées. Les contremaîtres y comptent les minutes de pause (zéro).",
         "elements": "Palette « forges » (eau = lave). Deux rigoles de lave (E) en diagonale qui découpent la carte en 3 zones reliées par des passerelles d'une case ; enclumes et soufflets en rochers (R) ; deux décors « galerie » (cheminées) en haut.",
         "ressources": {"I": 2, "T": 2},
         "groupes": [{"monstres": ["contremaitre_zele"]}, {"monstres": ["contremaitre_zele", "contremaitre_zele"]},
                     {"parmi": ["contremaitre_zele", "milicien_de_hautepierre"], "nombre": [2, 3]}, {"monstres": ["contremaitre_zele", "vampipistrelle"]}],
         "pnj": [], "pierre": False, "boss": False},
        {"id": "crasse_roc_0_2", "existante": False, "nom": "Crasse-Roc — Route des Charrois", "x": 0, "y": 2,
         "sorties": {"droite": "crasse_roc_1_2"}, "portes": ["hautepierre_4_2"], "palier": "10-12",
         "ambiance": "La route par où sortent les charrois de minerai, vers l'ouest et Hautepierre ; un péage gobelin improvisé.",
         "elements": "Route (:) large de l'est (vers les forges) à l'ouest, jusqu'au passage « + » sur le bord gauche (porte vers hautepierre_4_2, décor « poteau_indicateur » à côté) ; charrettes renversées (R) ; falaises (R) en haut et en bas.",
         "ressources": {"T": 2, "I": 1},
         "groupes": [{"monstres": ["contremaitre_zele", "contremaitre_zele"]}, {"monstres": ["contremaitre_zele"]},
                     {"parmi": ["contremaitre_zele"], "nombre": [1, 2]}],
         "pnj": [{"marqueur": "a", "id": "zibeline_la_peagere", "nom": "Zibeline, péagère", "role": "PNJ d'ambiance",
                  "repliques": ["Péage ! Deux brumes pour passer. Trois pour repasser. Quatre si vous avez l'air content.",
                                "Hautepierre, c'est tout droit. Les humains y ont des murs blancs et des idées noires sur nous.",
                                "Vous ne payez pas ? Bon. Je note. Je note toujours. Je ne fais rien après, mais je note."],
                  "art": {"rig": "gobelin", "couleurs": {"peau": "8a9a4a", "tunique": "c9a04e", "manches": "8a6a2a", "pantalon": "4a3a28", "cheveux": "5a3a1a", "ceinture": "3a2a1a"}}}],
         "passage_inter_zone": "Porte « + » vers hautepierre_4_2 (route), posée par le lot Hautepierre avec sa réciproque.",
         "pierre": False, "boss": False},
        {"id": "crasse_roc_1_3", "existante": False, "nom": "Crasse-Roc — L'Abîme du Balourd", "x": 1, "y": 3, "palette": "forges",
         "sorties": {"haut": "crasse_roc_1_2"}, "palier": "10-12",
         "ambiance": "Le fond des galeries, là où on a creusé trop profond : un lac de lave, un pont de pierre, et quelque chose de très grand qui attend.",
         "elements": "Palette « forges ». Lac de lave (E) sur tout le bas et les côtés ; une plate-forme centrale (7×7 praticable) reliée au haut par un pont de 2 cases de large ; piliers (R) sur la plate-forme pour s'abriter du Crachat de lave.",
         "ressources": {},
         "groupes": [{"monstres": ["balourd_des_abimes"], "reapparition": [45, 60]}, {"monstres": ["contremaitre_zele", "contremaitre_zele"]}],
         "groupes_note": "Groupe 1 : le Balourd seul, fixe, réapparition en 1 min au plus ; groupe 2 près du pont (les contremaîtres « surveillent les travaux »).",
         "pnj": [], "pierre": False, "boss": True}],
    "familles": [RAT, GROUILLEUR, VAMPI, MILICIEN, CONTREMAITRE],
    "boss": {"id": "balourd_des_abimes", "carte": "crasse_roc_1_3", "groupe": ["balourd_des_abimes"], "reapparition": [45, 60],
             "json": BALOURD,
             "sorts": ligne_sorts(["balourd_lame_de_braise", "balourd_fouet", "balourd_crachat_de_lave", "balourd_pluie_de_braises"]),
             "art": {"type": "image", "reutilise": None,
                     "nouveau_svg": "monstre/balourd.svgt, ~96×104 px : démon massif de roche noire fissurée de lave orange, deux cornes recourbées, ailes de fumée grise en lambeaux, épée de braise dans la main droite et fouet de flamme dans la gauche ; yeux jaunes ; ancre aux pieds (≈ [48, 100]). Le plus grand monstre des zones de départ.",
                     "manifeste": {"image": "balourd", "echelle": 1.0}},
             "equilibrage": "Profil défensif puis éruptif. Plus dur que les deux autres mini-boss (zone « rude à la fin ») : 300 PV, et sa faiblesse au Givre (−25) est couverte pendant 3 tours à 70 % ; ~17 dégâts/tour puis ~25 avec +30 Int et la glyphe de braises ; à 15 %, +3 PM et +2 portée : il ne se laisse plus coincer. Les arcanistes de Givre et les gobelins Chance s'en sortent mieux, à condition de garder leurs coups pour après la carapace."},
    "progression": ("Gobelins : « des rats à volonté, puis la dèche ». Palier 1–3 très généreux : deux familles (rats faibles, grouilleurs forts) sur trois cartes (Entrée, Crassier, Rataillerie), "
                    "des groupes de 3 — avec le passif Chapardeur, le gobelin s'équipe vite (Fouineur, Pressé). Palier 4–6 maigre : une seule famille volante (vampipistrelles) sur 2 cartes, "
                    "pénible pour les tireurs. Palier 7–9 : la milice humaine (armure, résistance Acier) sur 2 cartes : il faut changer d'élément ou s'équiper (Forgeron Hargneux). "
                    "Palier 10–12 : contremaîtres en soutien (groupes qui se donnent des PA) et le Balourd, le plus dur des trois mini-boss. Asymétrie : départ le plus rapide, fin la plus rude ; "
                    "la sortie vers Hautepierre (Route des Charrois) est au palier 10–12."),
}
