"""Sous-zone des Nains : le Comptoir de Barbe-Fendue, au nord de Brumerive (brumerive.md)."""
from produire_sous_zone import sort, deg, bonus, ressource, monstre, drop, pnj, objectif_vaincre, TUTORIELS

Z = "brumerive"
NAIN = lambda **c: {"rig": "humain", "race": "nain", "couleurs": {"tunique": "6a4a2a", "manches": "5a3e22", "pantalon": "3e3226"} | c}
CROIX = {"type": "cercle", "taille": 1}
FACTURE = {"type": "malus", "carac": "pa", "min": 1, "max": 1, "duree": 1}

SORTS = [
    sort("taupe_griffe_pioche", "Griffe-pioche", "Elle creuse plus vite que les nains. Ils lui en veulent.", 3, (1, 1), [deg("acier", 3, 5)], 2),
    sort("taupe_galerie", "Galerie", "Elle s'enterre ici et ressort là. Sans payer le péage.", 2, (1, 3), [{"type": "teleportation"}], 1, 1),
    sort("mineur_coup_de_pioche", "Coup de pioche", "Stage non payé, coups bien appuyés.", 3, (1, 1), [deg("acier", 4, 6)], 2),
    sort("mineur_lancer_de_lampe", "Lancer de lampe", "La lampe était éteinte. Elle ne l'est plus.", 3, (2, 4), [deg("tempete", 3, 5)]),
    sort("mineur_facture", "Facture", "« Pour la consultation. » Vous n'avez rien demandé.", 2, (1, 3), [FACTURE], 1, 1),
    sort("controleur_facture_groupee", "Facture groupée", "Une seule facture pour tout le monde. Montant : tout.", 3, (0, 0),
         [FACTURE | {"cibles": "ennemis"}], 1, 2, {"type": "cercle", "taille": 2}),
    sort("controleur_pesee", "Pesée", "Il pèse l'allié, le trouve trop léger, et le lui reproche. Ça motive.", 2, (0, 4),
         [bonus("degats_infliges", 10, 2, cibles="allies")], 1, 2),
    sort("golem_poing_de_roche", "Poing de roche", "Un poing en minerai brut. Non raffiné, non poli, non négociable.", 4, (1, 1),
         [deg("acier", 6, 9), {"type": "poussee", "min": 1, "max": 1}]),
    sort("golem_eboulis", "Éboulis", "Il secoue les épaules. Il en tombe des cailloux.", 4, (2, 5), [deg("acier", 4, 6, cibles="ennemis")], 1, 0, CROIX),
    sort("orbaril_marteau_tampon", "Marteau-tampon", "« Payé. » Le tampon s'imprime sur votre front.", 4, (1, 1), [deg("acier", 8, 11)], 2),
    sort("orbaril_pluie_de_pieces", "Pluie de pièces", "Il jette l'argent par les fenêtres. Sur vous.", 4, (2, 6),
         [deg("tempete", 5, 8, cibles="ennemis"), FACTURE | {"cibles": "ennemis"}], 1, 0, CROIX, False),
    sort("orbaril_tout_doit_disparaitre", "Tout doit disparaître !", "Liquidation totale. Vous compris.", 3, (1, 1),
         [deg("acier", 6, 9), {"type": "retrait_pm", "min": 1, "max": 1}], 2),
]

RES = [
    ressource("griffe_de_taupe", "Griffe de taupe", "commun", 1, "force", "taupe_pioche", Z, "Plus solide qu'une pioche naine. Ne le dites pas aux nains."),
    ressource("velours_de_taupe", "Velours de taupe", "peu_commun", 1, "vitalite", "taupe_pioche", Z, "Doux comme la terre meuble. Sent aussi la terre meuble."),
    ressource("meche_de_lampe", "Mèche de lampe", "commun", 1, "agilite", "apprenti_mineur", Z, "Elle grésille encore. Facturée à la minute d'éclairage."),
    ressource("carnet_de_factures", "Carnet de factures", "peu_commun", 1, "intelligence", "apprenti_mineur", Z, "Toutes adressées à « Monsieur Quelqu'un ». Toutes impayées."),
    ressource("pepite_animee", "Pépite animée", "commun", 2, "perception", "golem_de_minerai", Z, "Elle bouge encore. Elle cherche le reste du golem."),
    ressource("contrat_de_golem", "Contrat de golem", "peu_commun", 2, "vitalite", "golem_de_minerai", Z, "« Le golem s'engage à travailler pour l'éternité, pauses non comprises. »"),
    ressource("sceau_du_tresorier", "Sceau du Trésorier", "rare", 2, "dommages_acier", "grand_tresorier_orbaril", Z, "Le sceau qui valide toutes les factures. Il en a validé trop."),
]

MONSTRES = [
    monstre("taupe_pioche", "Taupe-pioche", "Une taupe qui creuse plus vite que les nains. Ils lui facturent la différence.", 1, 18, 5, 4, 70,
            {"force": 4}, {"acier": 15, "tempete": -10}, ["taupe_griffe_pioche", "taupe_galerie"], 14, [1, 4],
            [drop("griffe_de_taupe", 0.6, [1, 2]), drop("velours_de_taupe", 0.15)], mot="de Taupe"),
    monstre("taupe_contremaitresse", "Taupe contremaîtresse", "Elle a creusé la moitié de la mine. Elle réclame la moitié des parts.", 1, 38, 6, 4, 90,
            {"force": 10}, {"acier": 20, "tempete": -5}, ["taupe_griffe_pioche", "taupe_galerie", "mineur_coup_de_pioche"], 40, [5, 12],
            [drop("griffe_de_taupe", 0.9, [2, 4]), drop("velours_de_taupe", 0.6, [1, 2])], elite=True, famille="taupe_pioche"),
    monstre("apprenti_mineur", "Apprenti mineur", "Nain en stage non payé. Il se rattrape en facturant les autres.", 1, 24, 6, 3, 80,
            {"agilite": 8, "force": 4}, {"tempete": 15, "acier": 5, "givre": -15},
            ["mineur_coup_de_pioche", "mineur_lancer_de_lampe", "mineur_facture"], 30, [3, 8],
            [drop("meche_de_lampe", 0.55, [1, 2]), drop("carnet_de_factures", 0.15)], mot="de Mineur"),
    monstre("controleur_des_poids_et_mesures", "Contrôleur des Poids et Mesures", "Il vérifie tout. Il a trouvé que vous pesiez trop lourd. Amende.", 2, 80, 7, 3, 110,
            {"agilite": 22, "force": 10}, {"tempete": 20, "acier": 10, "givre": -10},
            ["mineur_lancer_de_lampe", "controleur_facture_groupee", "controleur_pesee", "mineur_coup_de_pioche"], 150, [12, 26],
            [drop("meche_de_lampe", 0.9, [2, 4]), drop("carnet_de_factures", 0.6, [1, 2])], "soutien", elite=True, famille="apprenti_mineur"),
    monstre("golem_de_minerai", "Golem de minerai", "Un tas de minerai animé par contrat. Il a lu toutes les clauses.", 2, 60, 6, 2, 90,
            {"force": 20, "perception": 14}, {"acier": 30, "flamme": 10, "givre": -15},
            ["golem_poing_de_roche", "golem_eboulis"], 110, [9, 20],
            [drop("pepite_animee", 0.5, [1, 2]), drop("contrat_de_golem", 0.12)], mot="de Golem"),
    monstre("golem_de_filon", "Golem de filon d'or", "Le seul golem que la guilde n'a jamais réussi à faire travailler : il vaut trop cher.", 2, 120, 7, 2, 100,
            {"force": 30, "perception": 22}, {"acier": 35, "flamme": 15, "givre": -10},
            ["golem_poing_de_roche", "golem_eboulis", "mineur_facture"], 230, [20, 40],
            [drop("pepite_animee", 0.9, [2, 4]), drop("contrat_de_golem", 0.5, [1, 2])], elite=True, famille="golem_de_minerai"),
    monstre("grand_tresorier_orbaril", "Grand Trésorier Orbaril", "Il compte tout, surtout ce qu'on lui doit. Vous lui devez quelque chose, c'est certain.", 2, 300, 7, 3, 95,
            {"force": 20, "agilite": 20}, {"acier": 25, "tempete": 15, "givre": -20},
            ["orbaril_marteau_tampon", "mineur_facture"], 760, [90, 150],
            [drop("sceau_du_tresorier", 1.0)], boss=True, mot="du Trésorier",
            phases=[{"pv": 70, "message": "« Recouvrement ! Vous me devez des PV. » Orbaril recule derrière son comptoir.",
                     "sorts": ["orbaril_pluie_de_pieces"], "effets": [bonus("portee", 1, 3)]},
                    {"pv": 30, "message": "« Faillite ! Tout doit disparaître ! » Orbaril saute par-dessus le comptoir.",
                     "sorts": ["orbaril_tout_doit_disparaitre"], "effets": [bonus("pm", 2, 3), bonus("degats_infliges", 20, 3)]}]),
]

CARTES = [
    {"xy": (1, -1), "nom": "Carreau de la mine", "depart": True, "vers": {"bas": "brumerive_1_0"}, "liens": [(2, -1), (1, -2)],
     "groupes": [{"monstres": ["taupe_pioche"]}, {"monstres": ["taupe_pioche", "taupe_pioche"]}, {"parmi": ["taupe_pioche"], "nombre": [1, 2]}],
     "ressources": [("U", 3), ("F", 1)], "pnj_pos": [(0.42, 0.62), (0.7, 0.58), (0.62, 0.22)],
     "pnj": [pnj("a", "maitre_mineur_durgrim", "Maître-Mineur Durgrim", [
                "Bienvenue au Comptoir de Barbe-Fendue ! L'entrée est gratuite. La sortie, on en reparle.",
                "Nous sommes venus faire affaire avec les humains. Ils ne savent pas encore quelle affaire. Nous non plus, mais elle sera bonne.",
                "L'enclume est dans votre maison. Son usage est compris dans le loyer. Je vous explique comment s'en servir ?"],
                NAIN(tunique="3a4a6a", ceinture="c9a04e"), explique="forge"),
             pnj("b", "doyenne_brisepierre", "Doyenne Brisepierre, déléguée des Voies", [
                "Déléguée aux Voies. Les conseils sont gratuits. Les bons conseils, c'est une autre ligne du tarif.",
                "Réputation, maîtrise, changement de Voie : je vous fais le devis ?"],
                NAIN(tunique="6a2a3a", ceinture="e0b860"), explique="voies"),
             pnj("c", "fendoir_le_negociant", "Fendoir le Négociant, marchand", [
                "Tout est à vendre, même ce qui n'est pas à moi. Surtout ce qui n'est pas à moi."], NAIN(tunique="7a6040"), marchand=True)]},
    {"xy": (2, -1), "nom": "Terril aux Taupes", "vers": {"bas": "brumerive_2_0"}, "liens": [(2, -2)], "obstacles": [("R", 18)],
     "groupes": [{"monstres": ["taupe_pioche", "apprenti_mineur"]}, {"monstres": ["apprenti_mineur"]},
                 {"parmi": ["taupe_pioche", "apprenti_mineur"], "nombre": [2, 3]}, {"monstres": ["taupe_pioche", "taupe_pioche", "taupe_pioche"]}],
     "ressources": [("U", 3)], "pnj_pos": [(0.35, 0.45)],
     "pnj": [pnj("a", "brunhild_comptable", "Brunhild, comptable", [
                "Chaque caillou a un prix. Celui-ci : trois brumes. Celui-là aussi. Vous venez de marcher dessus : six brumes.",
                "Les taupes creusent sans payer. Les apprentis piochent sans payer. Personne ne paie, ici, à part moi. Et je ne paie pas."],
                NAIN(tunique="4a3a5a", ceinture="8a6a40"))]},
    {"xy": (1, -2), "nom": "Galerie des Péages", "liens": [(2, -2), (1, -3)], "obstacles": [("R", 14), ("M", 6)],
     "groupes": [{"monstres": ["apprenti_mineur", "apprenti_mineur"]}, {"parmi": ["apprenti_mineur", "taupe_pioche"], "nombre": [2, 3]},
                 {"monstres": ["golem_de_minerai"]}, {"monstres": ["apprenti_mineur", "taupe_pioche"]}],
     "ressources": [("F", 2), ("C", 1)], "pnj_pos": [(0.4, 0.4)],
     "pnj": [pnj("a", "peagiste_barbe_grise", "Péagiste Barbe-Grise", [
                "Péage ! Une brume pour passer. Deux pour repasser. Trois pour me demander pourquoi.",
                "Vous me devez trois brumes."], NAIN(tunique="5a5a4a", barbe="c8c8c0"))]},
    {"xy": (2, -2), "nom": "Monte-charges", "liens": [(2, -3)], "obstacles": [("R", 16), ("M", 8)],
     "groupes": [{"monstres": ["golem_de_minerai"]}, {"monstres": ["golem_de_minerai", "apprenti_mineur"]},
                 {"parmi": ["golem_de_minerai", "apprenti_mineur"], "nombre": [2, 3]}],
     "ressources": [("U", 2), ("I", 2)]},
    {"xy": (1, -3), "nom": "Front de taille", "liens": [(2, -3)], "obstacles": [("R", 20)],
     "groupes": [{"monstres": ["golem_de_minerai", "golem_de_minerai"]}, {"parmi": ["golem_de_minerai"], "nombre": [2, 3]},
                 {"monstres": ["golem_de_minerai", "apprenti_mineur", "apprenti_mineur"]}],
     "ressources": [("I", 2), ("U", 1)], "pnj_pos": [(0.4, 0.4)],
     "pnj": [pnj("a", "vieux_tordbras", "Vieux Tordbras", [
                "Je creuse vers l'or depuis quatre-vingts ans. En ligne droite. Je dois être tout près.",
                "Orbaril, dans la Salle des Comptes, dit que je lui dois quatre-vingts ans de loyer. Je creuse aussi pour lui échapper."],
                NAIN(tunique="4a4038", barbe="e0e0e0"))]},
    {"xy": (2, -3), "nom": "Salle des Comptes", "obstacles": [("R", 6), ("M", 10)], "ressources": [],
     "groupes": [{"monstres": ["grand_tresorier_orbaril"], "reapparition": [45, 60]},
                 {"monstres": ["golem_de_minerai", "golem_de_minerai"]}]},
]

COND = {"race": "nain"}
QUETES = [
    {"id": "barbe_fendue_contrat_d_embauche", "nom": "Contrat d'embauche", "categorie": "principale", "acte": 1, "niveau": 1,
     "pnj": "maitre_mineur_durgrim", "description": "Pas de travail sans contrat. Pas de contrat sans période d'essai.",
     "conditions": COND,
     "etapes": [{"objectifs": [objectif_vaincre("taupe_pioche", 3)]},
                {"objectifs": [{"type": "parler", "pnj": "maitre_mineur_durgrim", "texte": "Signer le contrat en bas, chez Durgrim"}]}],
     "dialogues": {"maitre_mineur_durgrim": {
         "proposition": ["Période d'essai : chassez trois taupes-pioches du carreau. Elles creusent sans contrat, c'est de la concurrence déloyale.",
                         "Revenez ensuite signer en bas. Et en bas du bas. Et au dos."],
         "en_cours": ["Les taupes creusent toujours. Gratuitement. C'est insupportable."],
         "fin": ["Période d'essai concluante. Signez ici. Et ici. Bienvenue dans la guilde : votre première cotisation est due hier."]}},
     "recompenses": {"xp_cr": 3, "ecus": 30}},
    {"id": "barbe_fendue_facture_impayee", "nom": "Facture impayée", "categorie": "principale", "acte": 1, "niveau": 3,
     "pnj": "brunhild_comptable", "description": "Deux apprentis ont pioché sans payer. Brunhild veut son dû, en minerai.",
     "conditions": COND | {"quetes_terminees": ["barbe_fendue_contrat_d_embauche"]},
     "etapes": [{"objectifs": [objectif_vaincre("apprenti_mineur", 2)]},
                {"objectifs": [{"type": "recolter", "objet": "minerai_de_cuivre", "nombre": 5, "texte": "Récolter du cuivre au Terril pour solder la facture"},
                               {"type": "parler", "pnj": "brunhild_comptable"}]}],
     "dialogues": {"brunhild_comptable": {
         "proposition": ["Deux apprentis ont pioché sans payer. Raisonnez-les. Fermement.",
                         "Puis rapportez-moi cinq minerais de cuivre. Pour solder la facture. Et les intérêts. Et les frais de dossier."],
         "en_cours": ["La facture court toujours. Les intérêts aussi."],
         "objectif": ["Les apprentis ont compris. Reste le paiement."],
         "fin": ["Facture soldée. Voici votre reçu. Il vous coûtera une brume."]}},
     "recompenses": {"xp_cr": 4, "ecus": 50}},
    {"id": "barbe_fendue_delocalisation", "nom": "Délocalisation", "categorie": "principale", "acte": 1, "niveau": 4,
     "pnj": "maitre_mineur_durgrim", "description": "La guilde vous envoie développer le marché humain.",
     "conditions": COND | {"quetes_terminees": ["barbe_fendue_facture_impayee"]},
     "etapes": [{"objectifs": [{"type": "parler", "pnj": "bourgmestre_pansu", "texte": "Développer le marché humain avec le bourgmestre, sur la Place du village"}]}],
     "dialogues": {"maitre_mineur_durgrim": {
         "proposition": ["La guilde a voté : vous êtes délocalisé. Allez développer le marché humain.",
                         "Le bourgmestre Pansu, sur la Place du village, au sud-ouest. Vendez-lui… quelque chose. N'importe quoi. Nous-mêmes, peut-être."],
         "en_cours": ["Toujours là ? Le marché humain n'attend pas. Enfin si, il attend, mais il ne paie pas en attendant."]},
                   "bourgmestre_pansu": {"fin": ["Un nain ? Venu faire affaire ? Très bien, très bien. Brumerive a besoin de bras. Combien ça coûte ? … Ah. Tant que ça."]}},
     "recompenses": {"xp_cr": 5, "ecus": 60}},
    {"id": "barbe_fendue_controle_fiscal", "nom": "Contrôle fiscal", "categorie": "secondaire", "niveau": 12,
     "pnj": "vieux_tordbras", "description": "Le Grand Trésorier Orbaril réclame quatre-vingts ans de loyer au Vieux Tordbras. Un contrôle s'impose.",
     "conditions": {"une_quete_terminee": TUTORIELS},
     "etapes": [{"objectifs": [{"type": "vaincre_groupe", "monstre": "grand_tresorier_orbaril", "texte": "Contrôler les comptes d'Orbaril, dans la Salle des Comptes"}]},
                {"objectifs": [{"type": "parler", "pnj": "vieux_tordbras"}]}],
     "dialogues": {"vieux_tordbras": {
         "proposition": ["Orbaril me réclame quatre-vingts ans de loyer. Allez contrôler ses comptes, dans la Salle des Comptes. À coups de pioche, s'il le faut."],
         "en_cours": ["Il compte encore ? Je l'entends d'ici : « …et un, et deux… »"],
         "fin": ["Ses comptes étaient faux ? Je le savais ! Bon, je lui dois quand même trois brumes. Ne le lui dites pas."]}},
     "recompenses": {"xp_cr": 6, "ecus": 120}},
]

ICONES = {"griffe_de_taupe": "crochet_d_araignee", "velours_de_taupe": "peau_de_loup", "meche_de_lampe": "brin",
          "carnet_de_factures": "registre_des_heures", "pepite_animee": "cuivre_vert_de_gris", "contrat_de_golem": "bon_de_coupe",
          "sceau_du_tresorier": "tampon_officiel"}

ART = {
    "taupe_pioche": {"image": "taupe", "echelle": 0.85, "couleurs": {"pelage": "5a4a44", "pelage_ombre": "3a302c"}},
    "taupe_contremaitresse": {"image": "taupe", "echelle": 1.05, "couleurs": {"pelage": "7a5a3a", "pelage_ombre": "4a3626"}},
    "apprenti_mineur": {"image": "rat", "planche": "sprites/nain_guerrier.png", "echelle": 0.95},
    "controleur_des_poids_et_mesures": {"image": "rat", "planche": "sprites/nain_paladin.png", "echelle": 1.15},
    "golem_de_minerai": {"image": "gargouille", "echelle": 1.0, "teinte": "b08a60"},
    "golem_de_filon": {"image": "gargouille", "echelle": 1.2, "teinte": "f0c860"},
    "grand_tresorier_orbaril": {"image": "rat", "planche": "sprites/nain_myrmidon.png", "echelle": 1.35, "teinte": "fff0c0"},
}

SOUS_ZONE = {"id": "barbe_fendue", "zone": Z, "prefixe": "Brumerive", "palette": "", "bord": "R",
             "obstacles": [("R", 14)], "maison": "maison_barbe_fendue", "maison_modele": "maison_joueur",
             "camp_depart": "brumerive_0_0", "races": ["nain"],
             "passage": {"id": "brumerive_barbe_fendue", "nom": "Comptoir de Barbe-Fendue", "prix": 10},
             "sorts": SORTS, "ressources": RES, "monstres": MONSTRES, "cartes": CARTES, "quetes": QUETES,
             "objets_quete": [], "art_monstres": ART, "icones": ICONES,
             "images": {"taupe": {"fichier": "monstre/taupe.svgt", "ancre": [31, 42]}}}
