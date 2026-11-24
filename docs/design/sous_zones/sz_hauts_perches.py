"""Sous-zone des Géants : les Hauts-Perchés, à l'ouest de Brumerive (brumerive.md)."""
from produire_sous_zone import sort, deg, bonus, ressource, monstre, drop, pnj, objectif_vaincre, TUTORIELS

Z = "brumerive"
GEANT = lambda **c: {"rig": "humain", "race": "geant", "couleurs": {"tunique": "5a6a4a", "manches": "4a5a3e", "pantalon": "3e4a36"} | c}
VENT = {"type": "cercle", "taille": 1}

SORTS = [
    sort("agneau_coup_de_tete", "Coup de tête", "Un agneau, c'est mignon. Un agneau de la taille d'un cheval, c'est un bélier qui s'ignore.", 3, (1, 1),
         [deg("acier", 3, 5), {"type": "poussee", "min": 1, "max": 1}], 2),
    sort("agneau_belement", "Bêlement", "Un « bêê » si grave que le sol tremble. Vos jambes aussi.", 2, (1, 2),
         [{"type": "malus", "carac": "pm", "min": 1, "max": 1, "duree": 1}], 1, 1),
    sort("belier_charge_laineuse", "Charge laineuse", "Trois cases d'élan, une tonne de laine, une étincelle au bout.", 4, (2, 3),
         [{"type": "charge"}, deg("tempete", 5, 7)], 1, 1, en_ligne=True),
    sort("belier_toison_electrique", "Toison électrique", "La laine frotte, ça crépite. Ne caressez pas.", 2, (0, 0),
         [bonus("epines_tempete_fixes", 3, 2)], 1, 2),
    sort("belier_coup_de_corne", "Coup de corne", "Le classique.", 3, (1, 1), [deg("tempete", 4, 6)], 2),
    sort("esprit_rafale", "Rafale", "Un vent qui a pris de mauvaises habitudes. Il pousse.", 4, (2, 6),
         [deg("tempete", 4, 6), {"type": "poussee", "min": 2, "max": 2}]),
    sort("esprit_tourbillon", "Tourbillon", "Il tourne sur lui-même. Tout ce qui est autour aussi.", 3, (0, 0),
         [deg("tempete", 4, 6, cibles="ennemis")], 1, 1, VENT),
    sort("doyen_coup_de_baton", "Coup de bâton", "Il lève le bâton. Lentement. Très lentement. Puis très vite.", 5, (1, 1), [deg("acier", 10, 13)], 1),
    sort("doyen_pietinement", "Piétinement", "Il change de pied. Toute la montagne le sent.", 4, (0, 0),
         [deg("acier", 6, 9, cibles="ennemis")], 1, 1, VENT),
    sort("doyen_souffle_des_cimes", "Souffle des cimes", "Il reprend son souffle. Puis il vous le rend, d'un coup.", 4, (1, 6),
         [deg("tempete", 5, 8, cibles="ennemis"), {"type": "poussee", "min": 3, "max": 3, "cibles": "ennemis"}], 1, 1,
         {"type": "ligne"}, en_ligne=True),
    sort("doyen_grele", "Grêle", "Des grêlons gros comme des moutons. Ce sont peut-être des moutons.", 4, (2, 6),
         [deg("tempete", 5, 8, cibles="ennemis")], 1, 0, VENT, False),
    sort("doyen_et_donc_degage", "…et donc… DÉGAGE !", "Il a enfin fini sa phrase. Il ne la répétera pas.", 4, (1, 1),
         [deg("acier", 9, 12), {"type": "poussee", "min": 2, "max": 2}], 1),
]

RES = [
    ressource("laine_d_agneau_geant", "Laine d'agneau géant", "commun", 1, "force", "agneau_geant", Z, "Assez pour un pull. Un pull de géant, donc un seul brin."),
    ressource("sabot_d_agneau", "Sabot d'agneau", "peu_commun", 1, "vitalite", "agneau_geant", Z, "De la taille d'une enclume. Il en a le poids aussi."),
    ressource("toison_crepitante", "Toison crépitante", "commun", 1, "agilite", "belier_des_cimes", Z, "Elle grésille encore. Ne la portez pas sous l'orage."),
    ressource("corne_spiralee", "Corne spiralée", "peu_commun", 1, "perception", "belier_des_cimes", Z, "En y collant l'oreille, on entend le vent. Et un bêlement lointain."),
    ressource("souffle_en_bouteille", "Souffle en bouteille", "commun", 2, "intelligence", "esprit_des_bourrasques", Z, "Une bourrasque mise en bouteille. Ouvrez-la dehors."),
    ressource("plume_de_bourrasque", "Plume de bourrasque", "peu_commun", 2, "vitalite", "esprit_des_bourrasques", Z, "Elle ne tombe jamais. Elle remonte."),
    ressource("barbe_du_doyen", "Mèche de barbe du Doyen", "rare", 2, "dommages_tempete", "doyen_lentissime", Z, "Il a mis trois jours à remarquer qu'elle manquait."),
]

MONSTRES = [
    monstre("agneau_geant", "Agneau géant", "Un « agneau » de la taille d'un cheval. Il veut jouer. Vous ne voulez pas.", 1, 20, 5, 4, 65,
            {"force": 4}, {"acier": 15, "flamme": -10}, ["agneau_coup_de_tete", "agneau_belement"], 14, [1, 4],
            [drop("laine_d_agneau_geant", 0.6, [1, 2]), drop("sabot_d_agneau", 0.15)], mot="d'Agneau"),
    monstre("agneau_montagne", "Agneau-Montagne", "On l'a d'abord pris pour une colline. Puis la colline a bêlé.", 1, 42, 6, 4, 85,
            {"force": 10}, {"acier": 20, "flamme": -5}, ["agneau_coup_de_tete", "agneau_belement", "belier_coup_de_corne"], 40, [5, 12],
            [drop("laine_d_agneau_geant", 0.9, [2, 4]), drop("sabot_d_agneau", 0.6, [1, 2])], elite=True, famille="agneau_geant"),
    monstre("belier_des_cimes", "Bélier des cimes", "Il se frotte aux nuages d'orage pour charger sa laine. Il charge, d'ailleurs.", 1, 30, 6, 3, 80,
            {"agilite": 8}, {"tempete": 20, "givre": -15}, ["belier_charge_laineuse", "belier_coup_de_corne", "belier_toison_electrique"], 30, [3, 8],
            [drop("toison_crepitante", 0.55, [1, 2]), drop("corne_spiralee", 0.15)], mot="de Bélier"),
    monstre("grand_belier_corne_de_brume", "Grand Bélier Corne-de-Brume", "Ses cornes percent la brume. Et le reste.", 2, 85, 7, 3, 105,
            {"agilite": 22, "force": 8}, {"tempete": 25, "acier": 10, "givre": -10},
            ["belier_charge_laineuse", "belier_coup_de_corne", "belier_toison_electrique", "agneau_belement"], 150, [12, 26],
            [drop("toison_crepitante", 0.9, [2, 4]), drop("corne_spiralee", 0.6, [1, 2])], elite=True, famille="belier_des_cimes"),
    monstre("esprit_des_bourrasques", "Esprit des bourrasques", "Un vent qui a pris de mauvaises habitudes : il entre sans frapper.", 2, 45, 6, 4, 110,
            {"agilite": 18, "intelligence": 10}, {"tempete": 25, "acier": 10, "flamme": -15},
            ["esprit_rafale", "esprit_tourbillon"], 110, [9, 20],
            [drop("souffle_en_bouteille", 0.5, [1, 2]), drop("plume_de_bourrasque", 0.12)], "distance", mot="de Bourrasque"),
    monstre("grand_esprit_des_cimes", "Grand Esprit des cimes", "Le vent dominant. Il le fait savoir, en soufflant les toits.", 2, 95, 7, 4, 120,
            {"agilite": 28, "intelligence": 16}, {"tempete": 30, "acier": 15, "flamme": -10},
            ["esprit_rafale", "esprit_tourbillon", "agneau_belement"], 230, [20, 40],
            [drop("souffle_en_bouteille", 0.9, [2, 4]), drop("plume_de_bourrasque", 0.5, [1, 2])], "distance", elite=True, famille="esprit_des_bourrasques"),
    monstre("doyen_lentissime", "Le Doyen Lentissime", "Ancien gardien géant, devenu fou d'impatience… envers lui-même. Il n'a jamais fini une phrase.", 2, 300, 6, 2, 60,
            {"force": 20, "agilite": 20}, {"acier": 20, "tempete": 20, "flamme": -20},
            ["doyen_coup_de_baton", "doyen_pietinement"], 760, [90, 150],
            [drop("barbe_du_doyen", 1.0)], boss=True, mot="du Doyen",
            phases=[{"pv": 70, "message": "« Jeune… voyageur… le vent… » Le Doyen appelle les bourrasques, faute de mots.",
                     "sorts": ["doyen_souffle_des_cimes", "doyen_grele"], "effets": [bonus("portee", 1, 3)]},
                    {"pv": 30, "message": "« …et donc… DÉGAGE ! » Le Doyen a enfin fini sa phrase.",
                     "sorts": ["doyen_et_donc_degage"], "effets": [bonus("pm", 3, 3), bonus("degats_infliges", 25, 3)]}]),
]

CARTES = [
    {"xy": (-1, 0), "nom": "Seuil des Géants", "depart": True, "vers": {"droite": "brumerive_0_0"}, "liens": [(-2, 0), (-1, 1)],
     "groupes": [{"monstres": ["agneau_geant"]}, {"monstres": ["agneau_geant", "agneau_geant"]}, {"parmi": ["agneau_geant"], "nombre": [1, 2]}],
     "ressources": [("F", 3), ("C", 1)], "pnj_pos": [(0.42, 0.62), (0.7, 0.58), (0.62, 0.22)],
     "pnj": [pnj("a", "gardienne_haute_borne", "Gardienne Haute-Borne", [
                "Bienvenue aux Hauts-Perchés, petit. Pardon : tout le monde est petit, d'ici.",
                "Ici, on garde la Brume d'en haut. On la voit mieux. Les humains d'en bas aussi, on les voit très bien. Ils sont mignons.",
                "L'enclume est dans votre maison. Baissez-vous en entrant, la porte est à taille humaine. Je vous explique comment s'en servir ?"],
                GEANT(tunique="3a5a7a", ceinture="c9a04e"), explique="forge"),
             pnj("b", "grand_toise_marbre", "Grand-Toise Marbre, délégué des Voies", [
                "Délégué aux Voies. Je mesure les progrès. En toises, évidemment.",
                "Réputation, maîtrise, changement de Voie : je vous explique, de haut ?"],
                GEANT(tunique="6a3a5a", ceinture="e0b860"), explique="voies"),
             pnj("c", "troque_montagne", "Troque-Montagne, marchande", [
                "Tout est en grande taille. Pour les petits, on plie en quatre."], GEANT(tunique="7a6040"), marchand=True)]},
    {"xy": (-2, 0), "nom": "Corniche aux Moutons", "liens": [(-2, 1)], "obstacles": [("A", 12), ("R", 8)],
     "groupes": [{"monstres": ["agneau_geant", "belier_des_cimes"]}, {"monstres": ["belier_des_cimes"]},
                 {"parmi": ["agneau_geant", "belier_des_cimes"], "nombre": [2, 3]}, {"monstres": ["agneau_geant", "agneau_geant", "agneau_geant"]}],
     "ressources": [("F", 3)], "pnj_pos": [(0.35, 0.45)],
     "pnj": [pnj("a", "berger_petit_pas", "Berger Petit-Pas", [
                "Je suis berger. Humain. Ici. Mes moutons me prennent pour un agneau.",
                "Le Doyen, là-bas sur son aire, a commencé une phrase quand j'étais enfant. Il ne l'a pas finie."],
                {"rig": "humain", "couleurs": {"tunique": "8a7a5a", "manches": "6a5a40", "pantalon": "4a4030", "cheveux": "6a4a2a"}})]},
    {"xy": (-1, 1), "nom": "Bergerie trop basse", "vers": {"droite": "brumerive_0_1"}, "liens": [(-2, 1), (-1, 2)], "obstacles": [("A", 10), ("R", 6)],
     "groupes": [{"monstres": ["belier_des_cimes", "belier_des_cimes"]}, {"parmi": ["belier_des_cimes", "agneau_geant"], "nombre": [2, 3]},
                 {"monstres": ["esprit_des_bourrasques"]}, {"monstres": ["belier_des_cimes", "agneau_geant"]}],
     "ressources": [], "pnj_pos": [(0.4, 0.4)],
     "pnj": [pnj("a", "charpentier_toise", "Charpentier Toisé", [
                "Le toit de la bergerie est trop bas. Je le remonte. Encore un peu. Encore un peu plus.",
                "Les béliers l'ont défoncé trois fois. Ils sont trop grands. Ou le toit trop petit. On ne sait plus."],
                GEANT(tunique="7a5a3a", ceinture="5a4a30"))]},
    {"xy": (-2, 1), "nom": "Falaise du Vent", "liens": [(-2, 2)], "obstacles": [("R", 16), ("M", 6)],
     "groupes": [{"monstres": ["esprit_des_bourrasques"]}, {"monstres": ["esprit_des_bourrasques", "belier_des_cimes"]},
                 {"parmi": ["esprit_des_bourrasques", "belier_des_cimes"], "nombre": [2, 3]}],
     "ressources": [("U", 2), ("I", 2)]},
    {"xy": (-1, 2), "nom": "Col des Bourrasques", "liens": [(-2, 2)], "obstacles": [("R", 18)],
     "groupes": [{"monstres": ["esprit_des_bourrasques", "esprit_des_bourrasques"]}, {"parmi": ["esprit_des_bourrasques"], "nombre": [2, 3]},
                 {"monstres": ["esprit_des_bourrasques", "belier_des_cimes", "belier_des_cimes"]}],
     "ressources": [("U", 2), ("I", 1)]},
    {"xy": (-2, 2), "nom": "Aire du Doyen", "obstacles": [("R", 8), ("M", 8)], "ressources": [],
     "groupes": [{"monstres": ["doyen_lentissime"], "reapparition": [45, 60]},
                 {"monstres": ["esprit_des_bourrasques", "esprit_des_bourrasques"]}]},
]

COND = {"race": "geant"}
QUETES = [
    {"id": "hauts_perches_compte_des_moutons", "nom": "Le compte des moutons", "categorie": "principale", "acte": 1, "niveau": 1,
     "pnj": "gardienne_haute_borne", "description": "Trois agneaux géants se sont échappés. À votre taille, ça se rattrape.",
     "conditions": COND,
     "etapes": [{"objectifs": [objectif_vaincre("agneau_geant", 3)]},
                {"objectifs": [{"type": "parler", "pnj": "gardienne_haute_borne"}]}],
     "dialogues": {"gardienne_haute_borne": {
         "proposition": ["Petit, je compte les moutons. Il en manque trois. Ce sont des agneaux : ils sont seulement de la taille d'un cheval.",
                         "Ramenez-les à la raison. Un combat suffit, en général. Ils sont têtus, pas méchants."],
         "en_cours": ["J'en compte toujours trois de moins. Ou alors je me suis endormie en comptant."],
         "fin": ["Le compte est bon. Vous avez la carrure, et le reste viendra."]}},
     "recompenses": {"xp_cr": 3, "ecus": 30}},
    {"id": "hauts_perches_plafond_trop_bas", "nom": "Plafond trop bas", "categorie": "principale", "acte": 1, "niveau": 3,
     "pnj": "charpentier_toise", "description": "Les béliers ont encore défoncé le toit de la bergerie. Il faut le remonter. Encore.",
     "conditions": COND | {"quetes_terminees": ["hauts_perches_compte_des_moutons"]},
     "etapes": [{"objectifs": [objectif_vaincre("belier_des_cimes", 2)]},
                {"objectifs": [{"type": "recolter", "objet": "bois_de_frene", "nombre": 5, "texte": "Récolter du frêne pour remonter le toit"},
                               {"type": "parler", "pnj": "charpentier_toise"}]}],
     "dialogues": {"charpentier_toise": {
         "proposition": ["Deux béliers ont défoncé le toit. Encore. Calmez-les, s'il vous plaît.",
                         "Puis rapportez-moi du frêne : je remonte le toit. Encore un peu plus haut."],
         "en_cours": ["Le toit est toujours troué. Les béliers sont toujours fiers."],
         "objectif": ["Les béliers sont calmés. Maintenant, le bois."],
         "fin": ["Voilà un toit à bonne hauteur ! Enfin, pour cette semaine."]}},
     "recompenses": {"xp_cr": 4, "ecus": 50}},
    {"id": "hauts_perches_ambassade", "nom": "Ambassade", "categorie": "principale", "acte": 1, "niveau": 4,
     "pnj": "gardienne_haute_borne", "description": "Les humains d'en bas ont peur des géants. Il faut aller les rassurer. Doucement.",
     "conditions": COND | {"quetes_terminees": ["hauts_perches_plafond_trop_bas"]},
     "etapes": [{"objectifs": [{"type": "parler", "pnj": "bourgmestre_pansu", "texte": "Rassurer le bourgmestre, sur la Place du village"}]}],
     "dialogues": {"gardienne_haute_borne": {
         "proposition": ["Les humains de Brumerive nous voient arriver et se cachent sous leurs tables. Allez les rassurer.",
                         "Le bourgmestre Pansu, sur la Place du village, à l'est. Baissez-vous en entrant, et parlez doucement."],
         "en_cours": ["L'est, petit. Là où les maisons sont toutes petites."]},
                   "bourgmestre_pansu": {"fin": ["Un g… géant ? Ah, vous êtes gentil. Très bien. Très, très bien. Brumerive a toujours besoin de bras. Et de hauteur."]}},
     "recompenses": {"xp_cr": 5, "ecus": 60}},
    {"id": "hauts_perches_mot_de_la_fin", "nom": "Le mot de la fin", "categorie": "secondaire", "niveau": 12,
     "pnj": "berger_petit_pas", "description": "Le Doyen Lentissime n'a jamais fini sa phrase. Quelqu'un doit l'y aider.",
     "conditions": {"une_quete_terminee": TUTORIELS},
     "etapes": [{"objectifs": [{"type": "vaincre_groupe", "monstre": "doyen_lentissime", "texte": "Aider le Doyen à finir sa phrase, sur son aire"}]},
                {"objectifs": [{"type": "parler", "pnj": "berger_petit_pas"}]}],
     "dialogues": {"berger_petit_pas": {
         "proposition": ["Le Doyen, sur son aire, a commencé une phrase il y a quarante ans. Ça rend tout le monde nerveux. Aidez-le à la finir."],
         "en_cours": ["Il en est toujours à « Jeune… voyageur… »."],
         "fin": ["Il l'a finie ? « Dégage » ? Quarante ans pour ça. Bon. Merci quand même."]}},
     "recompenses": {"xp_cr": 6, "ecus": 120}},
]

ICONES = {"laine_d_agneau_geant": "fil_de_brume", "sabot_d_agneau": "coeur_de_pierre", "toison_crepitante": "poil_scintillant",
          "corne_spiralee": "corne_du_balourd", "souffle_en_bouteille": "gnole_de_raid", "plume_de_bourrasque": "plume_de_corbac",
          "barbe_du_doyen": "poil_de_criniere_leonin"}

ART = {
    "agneau_geant": {"image": "loup", "echelle": 0.8, "teinte": "f4f0e0"},
    "agneau_montagne": {"image": "loup", "echelle": 1.0, "teinte": "e0d8c0"},
    "belier_des_cimes": {"image": "cerf", "echelle": 0.8, "teinte": "d0d8e8"},
    "grand_belier_corne_de_brume": {"image": "cerf", "echelle": 1.0, "teinte": "b0c0e0"},
    "esprit_des_bourrasques": {"image": "rat", "planche": "sprites/arkhe_tempete_arcaniste.png", "echelle": 0.95, "teinte": "c8e0ff"},
    "grand_esprit_des_cimes": {"image": "rat", "planche": "sprites/arkhe_tempete_arcaniste.png", "echelle": 1.15, "teinte": "a8c8ff"},
    "doyen_lentissime": {"image": "rat", "planche": "sprites/geant_paladin.png", "echelle": 1.1, "teinte": "e8e8f0"},
}

SOUS_ZONE = {"id": "hauts_perches", "zone": Z, "prefixe": "Brumerive", "palette": "", "bord": "A",
             "obstacles": [("A", 14)], "maison": "maison_hauts_perches", "maison_modele": "maison_joueur",
             "camp_depart": "brumerive_0_0", "races": ["geant"],
             "passage": {"id": "brumerive_hauts_perches", "nom": "Hauts-Perchés", "prix": 10},
             "sorts": SORTS, "ressources": RES, "monstres": MONSTRES, "cartes": CARTES, "quetes": QUETES,
             "objets_quete": [], "art_monstres": ART, "icones": ICONES}
