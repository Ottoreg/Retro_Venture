"""Sous-zone des Arkhés : les Sources primordiales, au nord de Sylvebrume (sylvebrume.md). Éléments mélangés."""
from produire_sous_zone import sort, deg, bonus, ressource, monstre, drop, pnj, objectif_vaincre, TUTORIELS

Z = "sylvebrume"
ARKHE = lambda race="arkhe", **c: {"rig": "humain", "race": race, "couleurs": c}
CROIX = {"type": "cercle", "taille": 1}
TOUTES = ("acier", "flamme", "givre", "tempete")

SORTS = [
    sort("etincelle_crepitement", "Crépitement", "Elle crépite, elle claque, elle brûle un peu, elle électrise beaucoup.", 3, (1, 1),
         [deg("flamme", 2, 3), deg("tempete", 1, 2)], 2),
    sort("etincelle_saut", "Saut", "Une étincelle ne marche pas. Elle saute.", 2, (1, 2), [{"type": "teleportation"}], 1, 1),
    sort("mal_eclos_jet_de_flamme", "Jet de flamme", "Il voulait faire de l'eau. C'est sorti en feu.", 3, (2, 4), [deg("flamme", 3, 5)]),
    sort("mal_eclos_jet_de_givre", "Jet de givre", "Il voulait faire du feu. C'est sorti en glace.", 3, (2, 4), [deg("givre", 3, 5)]),
    sort("mal_eclos_crise_d_identite", "Crise d'identité", "Il ne sait plus ce qu'il est. Vos résistances non plus.", 3, (0, 0),
         [{"type": "malus", "carac": "resistance", "element": e, "min": 10, "max": 10, "duree": 2, "cibles": "ennemis"} for e in ("flamme", "givre")],
         1, 2, {"type": "cercle", "taille": 2}),
    sort("gardien_coup_de_source", "Coup de source", "Un coup chargé de tout ce que la source a de solide.", 4, (1, 1), [deg("acier", 6, 9)], 2),
    sort("gardien_jaillissement", "Jaillissement", "La source jaillit d'un coup, droit devant, glacée.", 4, (1, 5),
         [deg("givre", 4, 7, cibles="ennemis")], 1, 1, {"type": "ligne"}, en_ligne=True),
    sort("indecis_coup_d_acier", "Coup d'acier", "« Je suis l'Acier ! » Pour l'instant.", 4, (1, 1), [deg("acier", 8, 11)], 2),
    sort("indecis_bourrasque", "Bourrasque", "« Non, la Tempête ! » Un coup de vent pour vous éloigner.", 4, (2, 6),
         [deg("tempete", 5, 8), {"type": "poussee", "min": 2, "max": 2}]),
    sort("indecis_finalement_le_feu", "Finalement, le feu !", "Il a choisi. Il le regrette déjà, mais vous plus encore.", 4, (1, 1),
         [deg("flamme", 7, 10), {"type": "poison", "element": "flamme", "min": 2, "max": 3, "duree": 2}], 2),
]

RES = [
    ressource("etincelle_captive", "Étincelle captive", "commun", 1, "agilite", "etincelle_folle", Z, "Elle saute dans le bocal. Ne l'ouvrez pas près des cheveux."),
    ressource("braise_vive", "Braise vive", "peu_commun", 1, "vitalite", "etincelle_folle", Z, "Elle ne s'éteint jamais. Elle boude, parfois."),
    ressource("fragment_indecis", "Fragment indécis", "commun", 1, "intelligence", "elementaire_mal_eclos", Z, "Un bout d'élémentaire qui change de couleur quand on ne le regarde pas."),
    ressource("larme_de_source", "Larme de source", "peu_commun", 1, "perception", "elementaire_mal_eclos", Z, "Une goutte des quatre sources à la fois. Elle ne sait pas si elle est chaude ou froide."),
    ressource("galet_de_source", "Galet de source", "commun", 2, "force", "gardien_de_source", Z, "Poli par les quatre éléments. Très dur, très lisse, très fier."),
    ressource("noyau_de_gardien", "Noyau de gardien", "peu_commun", 2, "vitalite", "gardien_de_source", Z, "Le cœur d'un gardien. Il bat encore, lentement."),
    ressource("coeur_de_l_indecis", "Cœur de l'Indécis", "rare", 2, "dommages_flamme", "l_indecis", Z, "Il change d'élément toutes les dix secondes. Il est revenu au feu."),
]

MONSTRES = [
    monstre("etincelle_folle", "Étincelle folle", "Un élémentaire si petit qu'il n'a pas eu le temps de choisir entre le feu et l'orage. Alors il fait les deux.", 1, 14, 5, 4, 90,
            {"intelligence": 3, "agilite": 3}, {"flamme": 15, "tempete": 15, "givre": -15}, ["etincelle_crepitement", "etincelle_saut"], 14, [1, 4],
            [drop("etincelle_captive", 0.6, [1, 2]), drop("braise_vive", 0.15)], mot="d'Étincelle"),
    monstre("grande_etincelle", "Grande Étincelle", "Elle a réuni trois étincelles. Elles ne sont toujours pas d'accord.", 1, 30, 6, 4, 110,
            {"intelligence": 8, "agilite": 8}, {"flamme": 20, "tempete": 20, "givre": -10}, ["etincelle_crepitement", "etincelle_saut", "mal_eclos_jet_de_flamme"], 40, [5, 12],
            [drop("etincelle_captive", 0.9, [2, 4]), drop("braise_vive", 0.6, [1, 2])], elite=True, famille="etincelle_folle"),
    monstre("elementaire_mal_eclos", "Élémentaire mal éclos", "Un Arkhé raté qui hésite encore. Il hésite en vous frappant.", 1, 26, 6, 3, 80,
            {"intelligence": 6, "perception": 6}, {"flamme": 10, "givre": 10, "acier": -10, "tempete": -10},
            ["mal_eclos_jet_de_flamme", "mal_eclos_jet_de_givre"], 30, [3, 8],
            [drop("fragment_indecis", 0.55, [1, 2]), drop("larme_de_source", 0.15)], "distance", mot="d'Éclosion"),
    monstre("grand_mal_eclos", "Grand Mal-Éclos", "Il a essayé les quatre éléments. Il les a tous ratés, mais en grand.", 2, 85, 7, 3, 105,
            {"intelligence": 18, "perception": 18}, {"flamme": 15, "givre": 15, "acier": 5, "tempete": 5},
            ["mal_eclos_jet_de_flamme", "mal_eclos_jet_de_givre", "mal_eclos_crise_d_identite"], 150, [12, 26],
            [drop("fragment_indecis", 0.9, [2, 4]), drop("larme_de_source", 0.6, [1, 2])], "distance", elite=True, famille="elementaire_mal_eclos"),
    monstre("gardien_de_source", "Gardien de source", "Il garde la source depuis toujours. Il ne sait plus contre qui.", 2, 55, 6, 3, 95,
            {"force": 18, "perception": 14}, {"acier": 25, "givre": 15, "flamme": -15},
            ["gardien_coup_de_source", "gardien_jaillissement"], 110, [9, 20],
            [drop("galet_de_source", 0.5, [1, 2]), drop("noyau_de_gardien", 0.12)], mot="de Source"),
    monstre("gardien_du_puits", "Gardien du Puits", "Le plus ancien des gardiens. Il a vu naître le premier Arkhé, et s'en souvient mal.", 2, 115, 7, 3, 110,
            {"force": 28, "perception": 22}, {"acier": 30, "givre": 20, "flamme": -10},
            ["gardien_coup_de_source", "gardien_jaillissement", "mal_eclos_crise_d_identite"], 230, [20, 40],
            [drop("galet_de_source", 0.9, [2, 4]), drop("noyau_de_gardien", 0.5, [1, 2])], elite=True, famille="gardien_de_source"),
    monstre("l_indecis", "L'Indécis", "Le premier Arkhé, qui n'a jamais choisi son élément. Il y réfléchit encore. Depuis l'aube des temps.", 2, 300, 7, 3, 100,
            {"force": 20, "intelligence": 20}, {"acier": 30, "flamme": 15, "givre": 15, "tempete": 15},
            ["indecis_coup_d_acier", "gardien_jaillissement"], 760, [90, 150],
            [drop("coeur_de_l_indecis", 1.0)], boss=True, mot="de l'Indécis",
            phases=[{"pv": 70, "message": "« Non… la Tempête ! Ou le Givre ? » L'Indécis recule pour réfléchir.",
                     "sorts": ["indecis_bourrasque", "mal_eclos_jet_de_givre"], "effets": [bonus("portee", 1, 3)]},
                    {"pv": 30, "message": "« Finalement, le feu ! » L'Indécis a choisi. Enfin.",
                     "sorts": ["indecis_finalement_le_feu"], "effets": [bonus("pm", 2, 3), bonus("degats_infliges", 20, 3)]}]),
]

SAGE = lambda m, id, nom, repliques, race: pnj(m, id, nom, repliques, ARKHE(race))
CARTES = [
    {"xy": (0, -1), "nom": "Bassin des Éclosions", "depart": True, "vers": {"bas": "sylvebrume_0_0"}, "liens": [(1, -1), (0, -2)],
     "groupes": [{"monstres": ["etincelle_folle"]}, {"monstres": ["etincelle_folle", "etincelle_folle"]}, {"parmi": ["etincelle_folle"], "nombre": [1, 2]}],
     "ressources": [("F", 3), ("U", 1)], "pnj_pos": [(0.42, 0.62), (0.7, 0.58), (0.62, 0.22)],
     "pnj": [pnj("a", "ancienne_prima", "Ancienne Prima", [
                "Bienvenue aux Sources primordiales. Tu viens d'éclore. Ne t'inquiète pas : la première fois, tout le monde fume un peu.",
                "Quatre sources, quatre éléments, quatre Sages qui ne sont jamais d'accord. On appelle ça un équilibre.",
                "L'enclume est dans ta maison. Je t'explique comment t'en servir, avant que tu ne la fasses fondre ?"],
                ARKHE(), explique="forge"),
             pnj("b", "eclat_premier", "Éclat-Premier, délégué des Voies", [
                "Délégué aux Voies. Les Voies, c'est comme les éléments : il faut choisir. Ou pas, regarde l'Indécis.",
                "Réputation, maîtrise, changement de Voie : je t'explique ?"], ARKHE("arkhe_tempete"), explique="voies"),
             pnj("c", "fondeuse_aluna", "Fondeuse Aluna, marchande", [
                "Tout est garanti à l'épreuve du feu. Le reste, on verra."], ARKHE("arkhe_acier"), marchand=True)]},
    {"xy": (1, -1), "nom": "Forge source", "vers": {"bas": "sylvebrume_1_0"}, "liens": [(1, -2)], "obstacles": [("R", 14), ("M", 6)],
     "groupes": [{"monstres": ["etincelle_folle", "elementaire_mal_eclos"]}, {"monstres": ["elementaire_mal_eclos"]},
                 {"parmi": ["etincelle_folle", "elementaire_mal_eclos"], "nombre": [2, 3]}, {"monstres": ["etincelle_folle", "etincelle_folle", "etincelle_folle"]}],
     "ressources": [("U", 3)], "pnj_pos": [(0.35, 0.45)],
     "pnj": [SAGE("a", "sage_ferrugine", "Sage Ferrugine", [
                "L'Acier est le meilleur élément. Il est dur, il est fiable, il ne discute pas. Contrairement aux autres Sages.",
                "Les mal-éclos ? Ils n'ont pas choisi l'Acier. Voilà leur problème."], "arkhe_acier")]},
    {"xy": (0, -2), "nom": "Brasier source", "liens": [(1, -2), (0, -3)], "obstacles": [("R", 12), ("A", 6)],
     "groupes": [{"monstres": ["elementaire_mal_eclos", "elementaire_mal_eclos"]}, {"parmi": ["elementaire_mal_eclos", "etincelle_folle"], "nombre": [2, 3]},
                 {"monstres": ["gardien_de_source"]}, {"monstres": ["elementaire_mal_eclos", "etincelle_folle"]}],
     "ressources": [("F", 2)], "pnj_pos": [(0.4, 0.4)],
     "pnj": [SAGE("a", "sage_cendrine", "Sage Cendrine", [
                "Le Feu est le meilleur élément. Ferrugine dit l'Acier ? L'Acier, ça fond. Je ne dis que ça.",
                "Personne ne m'écoute. C'est parce que je brûle un peu ceux qui s'approchent."], "arkhe")]},
    {"xy": (1, -2), "nom": "Orage source", "liens": [(1, -3)], "obstacles": [("R", 16)],
     "groupes": [{"monstres": ["gardien_de_source"]}, {"monstres": ["gardien_de_source", "elementaire_mal_eclos"]},
                 {"parmi": ["gardien_de_source", "elementaire_mal_eclos"], "nombre": [2, 3]}],
     "ressources": [("U", 2), ("I", 2)], "pnj_pos": [(0.4, 0.4)],
     "pnj": [SAGE("a", "sage_fulgur", "Sage Fulgur", [
                "La Tempête est le meil… quoi ? Non, laissez-moi finir ! LA TEMPÊTE EST LE MEILLEUR ÉLÉMENT !",
                "Pardon. Je coupe la parole à tout le monde. Même à moi."], "arkhe_tempete")]},
    {"xy": (0, -3), "nom": "Glacier source", "liens": [(1, -3)], "obstacles": [("R", 18)],
     "groupes": [{"monstres": ["gardien_de_source", "gardien_de_source"]}, {"parmi": ["gardien_de_source"], "nombre": [2, 3]},
                 {"monstres": ["gardien_de_source", "elementaire_mal_eclos", "elementaire_mal_eclos"]}],
     "ressources": [("I", 2), ("U", 1)], "pnj_pos": [(0.4, 0.4)],
     "pnj": [SAGE("a", "sage_frimaire", "Sage Frimaire", [
                "Le Givre est le meilleur élément. Je ne m'énerve pas pour le dire. Je ne m'énerve jamais.",
                "L'Indécis, au Puits des Origines, n'a toujours pas choisi. Ça m'agace. Calmement."], "arkhe_givre")]},
    {"xy": (1, -3), "nom": "Puits des Origines", "obstacles": [("R", 8), ("M", 8)], "ressources": [],
     "groupes": [{"monstres": ["l_indecis"], "reapparition": [45, 60]},
                 {"monstres": ["gardien_de_source", "gardien_de_source"]}]},
]

COND = {"race": "arkhe"}  # les variantes (arkhe_acier…) remplissent aussi la condition
QUETES = [
    {"id": "sources_eclosion", "nom": "Éclosion", "categorie": "principale", "acte": 1, "niveau": 1,
     "pnj": "ancienne_prima", "description": "Tu viens d'éclore. Montre que tu tiens debout.",
     "conditions": COND,
     "etapes": [{"objectifs": [objectif_vaincre("etincelle_folle", 3)]},
                {"objectifs": [{"type": "parler", "pnj": "ancienne_prima"}]}],
     "dialogues": {"ancienne_prima": {
         "proposition": ["Tu viens d'éclore, et tu fumes encore. Va calmer trois étincelles folles : elles sautent sur tout ce qui vient de naître.",
                         "Reviens me voir ensuite. Si tu fumes moins, c'est que tu as grandi."],
         "en_cours": ["Les étincelles sautent toujours. Toi aussi, d'ailleurs."],
         "fin": ["Tu ne fumes presque plus. Te voilà un vrai Arkhé. Enfin, un jeune."]}},
     "recompenses": {"xp_cr": 3, "ecus": 30}},
    {"id": "sources_debat_des_sages", "nom": "Le débat des Sages", "categorie": "principale", "acte": 1, "niveau": 3,
     "pnj": "sage_ferrugine", "description": "Les quatre Sages se disputent : quel élément est le meilleur ? Il faut les départager.",
     "conditions": COND | {"quetes_terminees": ["sources_eclosion"]},
     "etapes": [{"objectifs": [objectif_vaincre("elementaire_mal_eclos", 2),
                               {"type": "recolter", "objet": "minerai_de_cuivre", "nombre": 5, "texte": "Récolter du cuivre à la Forge source, pour la preuve"}]},
                {"objectifs": [{"type": "parler", "pnj": "sage_cendrine", "texte": "Montrer la preuve à Sage Cendrine, au Brasier"},
                               {"type": "parler", "pnj": "sage_fulgur", "texte": "Montrer la preuve à Sage Fulgur, à l'Orage"},
                               {"type": "parler", "pnj": "sage_frimaire", "texte": "Montrer la preuve à Sage Frimaire, au Glacier"}]},
                {"objectifs": [{"type": "parler", "pnj": "sage_ferrugine"}]}],
     "dialogues": {"sage_ferrugine": {
         "proposition": ["Départage-nous. Bats deux mal-éclos, qui n'ont pas choisi l'Acier, et rapporte du cuivre : la preuve que le métal est le meilleur.",
                         "Puis montre la preuve aux trois autres Sages. Ils seront obligés d'admettre. Évidemment."],
         "en_cours": ["Alors ? Ils ont admis ? Non ? Ils admettront."],
         "fin": ["Ils n'ont pas admis ? Évidemment. Bon, on recommence demain. Merci, tu as fait de ton mieux. Moins bien que l'Acier, mais de ton mieux."]},
                   "sage_cendrine": {"objectif": ["Du cuivre ? Ça fond. Tu vois ? Le Feu gagne."]},
                   "sage_fulgur": {"objectif": ["Du cuivre ? Ça conduit l'éclair ! Donc la Tempête gagne. Ne me coupe pas !"]},
                   "sage_frimaire": {"objectif": ["Du cuivre. Froid au toucher. Le Givre gagne. Calmement."]}},
     "recompenses": {"xp_cr": 4, "ecus": 50}},
    {"id": "sources_ouverture_au_monde", "nom": "Ouverture au monde", "categorie": "principale", "acte": 1, "niveau": 4,
     "pnj": "ancienne_prima", "description": "Les autres peuples font la guerre. Va voir comment ils vivent, et pourquoi.",
     "conditions": COND | {"quetes_terminees": ["sources_debat_des_sages"]},
     "etapes": [{"objectifs": [{"type": "parler", "pnj": "gardienne_elwyn", "texte": "Rencontrer Elwyn, à la Clairière de la Lisière"}]}],
     "dialogues": {"ancienne_prima": {
         "proposition": ["Les autres peuples se font la guerre pour des choses bien petites. Va voir comment ils vivent.",
                         "Commence par les elfes : Elwyn, à la Clairière de la Lisière, au sud. Ne mets pas le feu à la forêt."],
         "en_cours": ["Le sud, jeune Arkhé. Là où les arbres ne brûlent pas encore."]},
                   "gardienne_elwyn": {"fin": ["Un Arkhé ? Tant mieux, nous manquions de… chaleur. Restez à distance des arbres. Bienvenue à la Lisière."]}},
     "recompenses": {"xp_cr": 5, "ecus": 60}},
    {"id": "sources_choisis_toi", "nom": "Choisis-toi", "categorie": "secondaire", "niveau": 12,
     "pnj": "sage_frimaire", "description": "L'Indécis n'a jamais choisi son élément. Sage Frimaire voudrait qu'il se décide.",
     "conditions": {"une_quete_terminee": TUTORIELS},
     "etapes": [{"objectifs": [{"type": "vaincre_groupe", "monstre": "l_indecis", "texte": "Aider l'Indécis à se décider, au Puits des Origines"}]},
                {"objectifs": [{"type": "parler", "pnj": "sage_frimaire"}]}],
     "dialogues": {"sage_frimaire": {
         "proposition": ["L'Indécis hésite depuis l'aube des temps. Va l'aider à choisir. Calmement. Ou pas."],
         "en_cours": ["Il hésite encore ? Je ne m'énerve pas. Je ne m'énerve pas."],
         "fin": ["Il a choisi le feu ? … Je ne m'énerve pas. Merci quand même."]}},
     "recompenses": {"xp_cr": 6, "ecus": 120}},
]

ICONES = {"etincelle_captive": "eclat_de_cendre", "braise_vive": "cendre_tiede", "fragment_indecis": "fragment_de_cendre",
          "larme_de_source": "argent_lunaire", "galet_de_source": "coeur_de_pierre", "noyau_de_gardien": "eclat_de_gargouille",
          "coeur_de_l_indecis": "sacre_coeur"}

ART = {
    "etincelle_folle": {"image": "rat", "planche": "sprites/arkhe.png", "echelle": 0.5, "teinte": "ffe080"},
    "grande_etincelle": {"image": "rat", "planche": "sprites/arkhe.png", "echelle": 0.65, "teinte": "fff0a0"},
    "elementaire_mal_eclos": {"image": "rat", "planche": "sprites/arkhe_givre.png", "echelle": 0.85, "teinte": "e0c0ff"},
    "grand_mal_eclos": {"image": "rat", "planche": "sprites/arkhe_tempete.png", "echelle": 1.05, "teinte": "d0b0ff"},
    "gardien_de_source": {"image": "rat", "planche": "sprites/arkhe_acier_myrmidon.png", "echelle": 0.95},
    "gardien_du_puits": {"image": "rat", "planche": "sprites/arkhe_acier_myrmidon.png", "echelle": 1.15, "teinte": "c0e0ff"},
    "l_indecis": {"image": "rat", "planche": "sprites/arkhe_paladin.png", "echelle": 1.3, "teinte": "f0e0ff"},
}

SOUS_ZONE = {"id": "sources", "zone": Z, "prefixe": "Sylvebrume", "palette": "sylvebrume", "bord": "R",
             "obstacles": [("R", 14)], "maison": "maison_sources", "maison_modele": "maison_sylvebrume",
             "camp_depart": "sylvebrume_0_0", "races": ["arkhe", "arkhe_acier", "arkhe_givre", "arkhe_tempete"],
             "passage": {"id": "sylvebrume_sources", "nom": "Sources primordiales", "prix": 10},
             "sorts": SORTS, "ressources": RES, "monstres": MONSTRES, "cartes": CARTES, "quetes": QUETES,
             "objets_quete": [], "art_monstres": ART, "icones": ICONES}
