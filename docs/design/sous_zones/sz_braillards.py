"""Sous-zone des Orcs : la Fosse aux Braillards, à l'est de Crasse-Roc (crasse_roc.md)."""
from produire_sous_zone import sort, deg, bonus, ressource, monstre, drop, pnj, objectif_vaincre, TUTORIELS

Z = "crasse_roc"
ORC = lambda **c: {"rig": "humain", "race": "orc", "couleurs": {"tunique": "6a3a22", "manches": "5a2e1a", "pantalon": "3e2a1e"} | c}

SORTS = [
    sort("goret_ruade", "Ruade", "Un cochon de guerre ne recule jamais. Il rue.", 3, (1, 1), [deg("flamme", 3, 5)], 2),
    sort("goret_groin_brulant", "Groin brûlant", "Il s'est roulé dans les braises. Il vous en fait profiter.", 3, (1, 2),
         [deg("flamme", 2, 3), {"type": "poison", "element": "flamme", "min": 1, "max": 2, "duree": 1}]),
    sort("braillard_coup_de_tete", "Coup de tête", "La méthode orque : tête d'abord, réflexion jamais.", 3, (1, 1), [deg("flamme", 4, 6)], 2),
    sort("braillard_caillou_d_echauffement", "Caillou d'échauffement", "On s'échauffe la voix, et le bras.", 3, (2, 4), [deg("acier", 3, 5)]),
    sort("braillard_cri_d_encouragement", "Cri d'encouragement", "« ALLEZ ! » L'allié n'a rien compris, mais il tape plus fort.", 2, (0, 4),
         [bonus("degats_infliges", 10, 2, cibles="allies")], 1, 2),
    sort("gueulard_hurlement", "Hurlement", "Si fort que vos jambes refusent d'avancer vers lui.", 3, (0, 0),
         [{"type": "malus", "carac": "pm", "min": 1, "max": 1, "duree": 1, "cibles": "ennemis"}], 1, 2, {"type": "cercle", "taille": 2}),
    sort("ferrailleur_masse_de_ferraille", "Masse de ferraille", "Une masse faite de tout ce qui traînait. Surtout de l'enclume.", 4, (1, 1),
         [deg("acier", 6, 9), {"type": "poussee", "min": 1, "max": 1}]),
    sort("ferrailleur_boulon_chauffe", "Boulon chauffé à blanc", "Il sort du four. Il y retourne, à travers vous.", 4, (2, 5), [deg("flamme", 5, 7)]),
    sort("gorgrak_coup_de_poing_de_seance", "Coup de poing de séance", "La séance est ouverte. Votre arcade aussi.", 4, (1, 1), [deg("flamme", 8, 11)], 2),
    sort("gorgrak_marmite_de_braise", "Marmite de braise", "Le repas de la réunion. Servi brûlant, sur la tête.", 4, (2, 6),
         [deg("flamme", 5, 8, cibles="ennemis")], 1, 0, {"type": "cercle", "taille": 1}, False),
    sort("gorgrak_vote_a_main_levee", "Vote à main levée", "La main est levée. Puis elle redescend, sur vous.", 3, (1, 1),
         [deg("flamme", 6, 9), {"type": "retrait_pm", "min": 1, "max": 1}], 2),
]

RES = [
    ressource("soie_de_goret", "Soie de goret", "commun", 1, "intelligence", "goret_de_braise", Z, "Un poil de cochon de guerre, roussi au bout. Il sent la grillade."),
    ressource("defense_de_goret", "Défense de goret", "peu_commun", 1, "vitalite", "goret_de_braise", Z, "Une défense de goret. La troisième, celle de l'élite, vaut plus cher."),
    ressource("bandeau_de_braillard", "Bandeau de braillard", "commun", 1, "agilite", "apprenti_braillard", Z, "Il empêche la sueur de couler dans les yeux pendant qu'on crie."),
    ressource("cloche_de_poche", "Cloche de poche", "peu_commun", 1, "perception", "apprenti_braillard", Z, "Pour s'entraîner à crier plus fort qu'elle. Elle a perdu."),
    ressource("boulon_tordu", "Boulon tordu", "commun", 2, "force", "ferrailleur_orc", Z, "Un boulon de ferrailleur. Il a été droit, une fois, peut-être."),
    ressource("tole_noircie", "Tôle noircie", "peu_commun", 2, "vitalite", "ferrailleur_orc", Z, "Un morceau d'armure de récupération. Récupéré, puis récupéré encore."),
    ressource("machoire_de_gorgrak", "Mâchoire de Gorgrak", "rare", 2, "dommages_flamme", "gorgrak_la_grande_gueule", Z, "Une mâchoire de rechange du chef. Elle claque encore toute seule."),
]

MONSTRES = [
    monstre("goret_de_braise", "Goret de braise", "Cochon de guerre qui se roule dans les braises pour sentir bon. Il n'y arrive pas.", 1, 16, 5, 4, 70,
            {"intelligence": 4}, {"flamme": 15, "givre": -10}, ["goret_ruade", "goret_groin_brulant"], 14, [1, 4],
            [drop("soie_de_goret", 0.6, [1, 2]), drop("defense_de_goret", 0.15)], mot="de Goret"),
    monstre("goret_trois_defenses", "Goret à trois défenses", "La troisième défense lui pousse au milieu du front. Il en est très fier.", 1, 36, 6, 4, 90,
            {"intelligence": 10}, {"flamme": 20, "givre": -5}, ["goret_ruade", "goret_groin_brulant", "braillard_coup_de_tete"], 40, [5, 12],
            [drop("soie_de_goret", 0.9, [2, 4]), drop("defense_de_goret", 0.6, [1, 2])], elite=True, famille="goret_de_braise"),
    monstre("apprenti_braillard", "Apprenti braillard", "Jeune orc en formation au cri. Il est déjà très bon, surtout la nuit.", 1, 26, 6, 3, 80,
            {"intelligence": 8, "force": 4}, {"flamme": 15, "acier": 5, "givre": -15},
            ["braillard_coup_de_tete", "braillard_caillou_d_echauffement", "braillard_cri_d_encouragement"], 30, [3, 8],
            [drop("bandeau_de_braillard", 0.55, [1, 2]), drop("cloche_de_poche", 0.15)], "soutien", mot="de Braillard"),
    monstre("grand_gueulard", "Grand Gueulard", "Major de sa promotion de cri. On l'entend de Hautepierre. On l'entend de partout.", 2, 80, 7, 3, 110,
            {"intelligence": 22, "force": 10}, {"flamme": 20, "acier": 10, "givre": -10},
            ["braillard_coup_de_tete", "braillard_caillou_d_echauffement", "braillard_cri_d_encouragement", "gueulard_hurlement"], 150, [12, 26],
            [drop("bandeau_de_braillard", 0.9, [2, 4]), drop("cloche_de_poche", 0.6, [1, 2])], "soutien", elite=True, famille="apprenti_braillard"),
    monstre("ferrailleur_orc", "Ferrailleur orc", "Il porte une armure de récupération : un peu de tout, beaucoup de casseroles.", 2, 50, 6, 3, 100,
            {"force": 18, "intelligence": 18}, {"acier": 20, "flamme": 10, "givre": -10, "tempete": -10},
            ["ferrailleur_masse_de_ferraille", "ferrailleur_boulon_chauffe"], 110, [9, 20],
            [drop("boulon_tordu", 0.5, [1, 2]), drop("tole_noircie", 0.12)], mot="de Ferraille"),
    monstre("ferrailleur_blinde", "Ferrailleur blindé", "Il a récupéré tant de ferraille qu'il ne voit plus où il va. Ça ne l'arrête pas.", 2, 100, 7, 3, 115,
            {"force": 28, "intelligence": 28}, {"acier": 30, "flamme": 15, "tempete": -10},
            ["ferrailleur_masse_de_ferraille", "ferrailleur_boulon_chauffe", "braillard_cri_d_encouragement"], 230, [20, 40],
            [drop("boulon_tordu", 0.9, [2, 4]), drop("tole_noircie", 0.5, [1, 2])], elite=True, famille="ferrailleur_orc"),
    monstre("gorgrak_la_grande_gueule", "Gorgrak la Grande Gueule", "Chef de guerre qui tient des réunions… de hurlements. Il gagne tous les votes.", 2, 300, 7, 3, 100,
            {"intelligence": 22, "force": 18}, {"flamme": 25, "acier": 15, "givre": -20},
            ["gorgrak_coup_de_poing_de_seance", "braillard_caillou_d_echauffement"], 760, [90, 150],
            [drop("machoire_de_gorgrak", 1.0)], boss=True, mot="de Gorgrak",
            phases=[{"pv": 70, "message": "« Motion de hurlement ! Qui est pour ? Je n'entends rien ! » Gorgrak recule pour mieux crier.",
                     "sorts": ["gorgrak_marmite_de_braise", "gueulard_hurlement"], "effets": [bonus("portee", 1, 3)]},
                    {"pv": 30, "message": "« Adopté à l'unanimité de moi ! » Gorgrak entre en frénésie.",
                     "sorts": ["gorgrak_vote_a_main_levee"], "effets": [bonus("pm", 2, 3), bonus("degats_infliges", 20, 3)]}]),
]

CARTES = [
    {"xy": (3, 0), "nom": "Porte des Hurleurs", "depart": True, "vers": {"gauche": "crasse_roc_2_0"}, "liens": [(4, 0), (3, 1)],
     "groupes": [{"monstres": ["goret_de_braise"]}, {"monstres": ["goret_de_braise", "goret_de_braise"]}, {"parmi": ["goret_de_braise"], "nombre": [1, 2]}],
     "ressources": [("F", 3), ("C", 1)], "pnj_pos": [(0.42, 0.62), (0.7, 0.58), (0.62, 0.22)],
     "pnj": [pnj("a", "instructeur_krouk", "Instructeur Krouk", [
                "BIENVENUE À LA FOSSE AUX BRAILLARDS ! Pardon. C'est ma voix normale.",
                "Ici, on règle tout à qui crie le plus fort. Le Souverain Cendré nous a engagés pour le bruit. On n'a pas écouté la suite.",
                "L'ENCLUME est dans votre maison, derrière la porte. Je vous explique comment on s'en sert ?"],
                ORC(tunique="8a2a1a", ceinture="c9a04e"), explique="forge"),
             pnj("b", "grande_voix_ourga", "Grande-Voix Ourga, déléguée des Voies", [
                "Grande-Voix Ourga, déléguée aux Voies. Je parle doucement : ça fait peur, ici.",
                "Réputation, maîtrise, changement de Voie : je vous explique, en chuchotant ?"],
                ORC(tunique="3a4a6e", ceinture="e0b860"), explique="voies"),
             pnj("c", "troc_le_sourd", "Troc le Sourd, marchand", [
                "QUOI ? ACHETER ? OUI ! TOUT EST À VENDRE ! PARLEZ PLUS FORT !"], ORC(tunique="7a6040"), marchand=True)]},
    {"xy": (4, 0), "nom": "Fours à ferraille", "liens": [(4, 1)], "obstacles": [("R", 16), ("M", 6)],
     "groupes": [{"monstres": ["goret_de_braise", "apprenti_braillard"]}, {"monstres": ["apprenti_braillard"]},
                 {"parmi": ["goret_de_braise", "apprenti_braillard"], "nombre": [2, 3]}, {"monstres": ["goret_de_braise", "goret_de_braise", "goret_de_braise"]}],
     "ressources": [("U", 3), ("I", 1)], "pnj_pos": [(0.35, 0.45)],
     "pnj": [pnj("a", "machefer_forgeronne", "Mâchefer, forgeronne", [
                "Ça ne marche pas ? Je tape plus fort. Ça ne marche toujours pas ? Je tape encore plus fort.",
                "J'ai réparé l'enclume de l'arène trois fois cette semaine. Elle a fini en deux morceaux. C'est réparé : il y en a deux."],
                ORC(tunique="4a3a32", ceinture="8a6a40"))]},
    {"xy": (3, 1), "nom": "Arène des Gueulards", "vers": {"gauche": "crasse_roc_2_1"}, "liens": [(4, 1), (3, 2)], "obstacles": [("R", 12)],
     "groupes": [{"monstres": ["apprenti_braillard", "apprenti_braillard"]}, {"parmi": ["apprenti_braillard"], "nombre": [2, 3]},
                 {"monstres": ["ferrailleur_orc"]}, {"monstres": ["apprenti_braillard", "goret_de_braise"]}],
     "ressources": [], "pnj_pos": [(0.4, 0.4)],
     "pnj": [pnj("a", "arbitre_gnarl", "Arbitre Gnarl", [
                "Les règles de l'arène sont simples : le gagnant, c'est celui que j'entends.",
                "Les sourds ont un léger avantage. On y travaille."], ORC(tunique="2a2a2a", ceinture="e0e0e0"))]},
    {"xy": (4, 1), "nom": "Coulée de scories", "liens": [(4, 2)], "obstacles": [("R", 14), ("M", 8)],
     "groupes": [{"monstres": ["ferrailleur_orc"]}, {"monstres": ["ferrailleur_orc", "apprenti_braillard"]},
                 {"parmi": ["ferrailleur_orc", "apprenti_braillard"], "nombre": [2, 3]}],
     "ressources": [("U", 2), ("I", 2)]},
    {"xy": (3, 2), "nom": "Camp des Grognards", "liens": [(4, 2)], "obstacles": [("R", 18)],
     "groupes": [{"monstres": ["ferrailleur_orc", "ferrailleur_orc"]}, {"parmi": ["ferrailleur_orc"], "nombre": [2, 3]},
                 {"monstres": ["ferrailleur_orc", "apprenti_braillard", "apprenti_braillard"]}],
     "ressources": [("F", 2), ("C", 2)], "pnj_pos": [(0.4, 0.4)],
     "pnj": [pnj("a", "vieux_ronchon", "Vieux Ronchon", [
                "Je suis à la retraite. Je ne crie plus. Les autres trouvent ça scandaleux.",
                "Gorgrak, là-haut, sur sa tribune : trente ans qu'il hurle. Un peu de silence, ça ferait du bien à tout le monde."],
                ORC(tunique="5a5a4a", cheveux="c8c8c0"))]},
    {"xy": (4, 2), "nom": "Tribune du Chef", "obstacles": [("R", 6), ("M", 10)], "ressources": [],
     "groupes": [{"monstres": ["gorgrak_la_grande_gueule"], "reapparition": [45, 60]},
                 {"monstres": ["ferrailleur_orc", "ferrailleur_orc"]}]},
]

COND = {"race": "orc"}
QUETES = [
    {"id": "braillards_premier_cri", "nom": "Premier cri", "categorie": "principale", "acte": 1, "niveau": 1,
     "pnj": "instructeur_krouk", "description": "Un orc qui n'a jamais crié devant un ennemi n'est pas un orc. C'est un gobelin.",
     "conditions": COND,
     "etapes": [{"objectifs": [objectif_vaincre("goret_de_braise", 3)]},
                {"objectifs": [{"type": "parler", "pnj": "instructeur_krouk", "texte": "Revenir crier devant Krouk"}]}],
     "dialogues": {"instructeur_krouk": {
         "proposition": ["RECRUE ! Ton premier cri, ça se fait au combat. Va battre trois gorets de braise, dehors.",
                         "Et crie. Fort. Les gorets n'ont peur que de ça. Et des grillades."],
         "en_cours": ["Je ne t'ai pas entendu. Donc tu n'as rien fait."],
         "fin": ["CE CRI ! J'en ai mal aux oreilles. Bravo, recrue : tu es un vrai braillard."]}},
     "recompenses": {"xp_cr": 3, "ecus": 30}},
    {"id": "braillards_reunion_de_hurlements", "nom": "Réunion de hurlements", "categorie": "principale", "acte": 1, "niveau": 3,
     "pnj": "arbitre_gnarl", "description": "La cloche de l'arène ne sonne pas assez fort. Il faut la refondre, et prouver qu'on la mérite.",
     "conditions": COND | {"quetes_terminees": ["braillards_premier_cri"]},
     "etapes": [{"objectifs": [objectif_vaincre("apprenti_braillard", 4)]},
                {"objectifs": [{"type": "recolter", "objet": "minerai_de_cuivre", "nombre": 5, "texte": "Récolter du cuivre aux Fours pour la cloche de l'arène"},
                               {"type": "parler", "pnj": "arbitre_gnarl"}]}],
     "dialogues": {"arbitre_gnarl": {
         "proposition": ["Tu veux entrer à l'arène ? Bats quatre apprentis. Je compterai ceux que j'entends tomber.",
                         "Et rapporte du cuivre des Fours : on refond la cloche. Elle ne sonnait pas assez fort. Personne ne l'entendait, à cause des cris."],
         "en_cours": ["Je n'entends rien. Donc il ne se passe rien."],
         "objectif": ["Quatre apprentis, j'ai entendu. Maintenant, le cuivre."],
         "fin": ["Belle cloche ! On ne l'entendra pas non plus, mais elle est belle. Tu as gagné ta place."]}},
     "recompenses": {"xp_cr": 4, "ecus": 50}},
    {"id": "braillards_mutation_disciplinaire", "nom": "Mutation disciplinaire", "categorie": "principale", "acte": 1, "niveau": 4,
     "pnj": "instructeur_krouk", "description": "Tu cries trop bien. Le Chef se sent menacé.",
     "conditions": COND | {"quetes_terminees": ["braillards_reunion_de_hurlements"]},
     "etapes": [{"objectifs": [{"type": "parler", "pnj": "contremaitre_grumm", "texte": "Se présenter à Grumm, à l'Entrée des galeries"}]}],
     "dialogues": {"instructeur_krouk": {
         "proposition": ["Mauvaise nouvelle, recrue : tu cries trop bien. Gorgrak se sent menacé.",
                         "Tu es muté aux galeries de Crasse-Roc. Va voir le contremaître Grumm, à l'ouest, à l'Entrée des galeries. Et crie en partant, pour la forme."],
         "en_cours": ["Toujours là ? L'OUEST ! Par le Puits, puis tout droit !"]},
                   "contremaitre_grumm": {"fin": ["Un orc ? Parfait, on manquait de bruit. Les gobelins travaillent mieux quand quelqu'un hurle. Enfin, ils le disent."]}},
     "recompenses": {"xp_cr": 5, "ecus": 60}},
    {"id": "braillards_la_grande_gueule", "nom": "La Grande Gueule", "categorie": "secondaire", "niveau": 12,
     "pnj": "vieux_ronchon", "description": "Gorgrak hurle depuis trente ans sur sa tribune. Le Vieux Ronchon voudrait un peu de silence.",
     "conditions": {"une_quete_terminee": TUTORIELS},
     "etapes": [{"objectifs": [{"type": "vaincre_groupe", "monstre": "gorgrak_la_grande_gueule", "texte": "Faire taire Gorgrak, sur la Tribune du Chef"}]},
                {"objectifs": [{"type": "parler", "pnj": "vieux_ronchon"}]}],
     "dialogues": {"vieux_ronchon": {
         "proposition": ["Gorgrak, sur la tribune. Trente ans qu'il hurle. Va lui clouer le bec, que j'entende enfin les oiseaux."],
         "en_cours": ["Je l'entends encore. Les oiseaux aussi, et ils sont partis."],
         "fin": ["Le silence ! … Ah, non, il recommence. Bon, c'était bien pendant une minute. Merci."]}},
     "recompenses": {"xp_cr": 6, "ecus": 120}},
]

ICONES = {"soie_de_goret": "poil_scintillant", "defense_de_goret": "croc_de_loup", "bandeau_de_braillard": "tunique_dechiree_de_raphael",
          "cloche_de_poche": "sifflet_de_contremaitre", "boulon_tordu": "maillon_de_cotte", "tole_noircie": "fer_meteorique",
          "machoire_de_gorgrak": "corne_du_balourd"}

ART = {
    "goret_de_braise": {"image": "loup", "echelle": 0.7, "teinte": "c87050"},
    "goret_trois_defenses": {"image": "loup", "echelle": 0.85, "teinte": "e05030"},
    "apprenti_braillard": {"image": "rat", "planche": "sprites/orc_guerrier.png", "echelle": 0.95},
    "grand_gueulard": {"image": "rat", "planche": "sprites/orc_paladin.png", "echelle": 1.2},
    "ferrailleur_orc": {"image": "rat", "planche": "sprites/orc_myrmidon.png", "echelle": 1.05},
    "ferrailleur_blinde": {"image": "rat", "planche": "sprites/orc_myrmidon.png", "echelle": 1.26, "teinte": "a0a0b0"},
    "gorgrak_la_grande_gueule": {"image": "rat", "planche": "sprites/orc_demoniste.png", "echelle": 1.45, "teinte": "ffd0b0"},
}

SOUS_ZONE = {"id": "braillards", "zone": Z, "prefixe": "Crasse-Roc", "palette": "crasse_roc", "bord": "R",
             "obstacles": [("R", 14)], "maison": "maison_braillards", "maison_modele": "maison_crasse_roc",
             "camp_depart": "crasse_roc_0_0", "races": ["orc"],
             "passage": {"id": "crasse_roc_braillards", "nom": "Fosse aux Braillards", "prix": 10},
             "sorts": SORTS, "ressources": RES, "monstres": MONSTRES, "cartes": CARTES, "quetes": QUETES,
             "objets_quete": [], "art_monstres": ART, "icones": ICONES}
