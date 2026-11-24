"""Sous-zone des Squelettes : l'Ossuaire de la Première Ombre, à l'ouest de Crasse-Roc (crasse_roc.md)."""
from produire_sous_zone import sort, deg, bonus, ressource

Z = "crasse_roc"
MONO = {"tunique": "4a4a52", "manches": "3a3a42", "pantalon": "2e2e36"}

def monstre(id, nom, desc, palier, pv, pa, pm, init, carac, res, sorts, xp, ecus, butin, ia="basique", **k):
    return {"id": id, "nom": nom, "description": desc, "palier": palier,
            "caracteristiques": {"pv": pv, "pa": pa, "pm": pm, "initiative": init} | carac,
            "resistances": res, "sorts": sorts, "ia": ia, "xp": xp, "butin": butin, "ecus": ecus} | k

def drop(objet, taux, q=None): return {"objet": objet, "taux": taux} | ({"quantite": q} if q else {})

SORTS = [
    sort("os_coup_d_os", "Coup d'os", "Il frappe avec lui-même. Ça fait mal aux deux.", 3, (1, 1), [deg("impie", 3, 5)], 2),
    sort("os_ricochet", "Ricochet", "Il rebondit sur les murs, sur les cailloux, sur vous.", 3, (2, 3), [deg("impie", 2, 4)]),
    sort("pleureuse_larmes_glacees", "Larmes glacées", "Elle vous pleure d'avance. Ça gèle.", 4, (2, 5),
         [deg("givre", 4, 6), {"type": "retrait_pm", "min": 1, "max": 1}]),
    sort("pleureuse_complainte", "Complainte", "Une plainte si triste que les os eux-mêmes frissonnent.", 3, (1, 4),
         [deg("givre", 3, 5, cibles="ennemis")], 1, 2, {"type": "cercle", "taille": 1}),
    sort("veteran_lance_rouillee", "Lance rouillée", "Trois siècles de service, et toujours pas de lance neuve.", 4, (1, 2),
         [deg("acier", 6, 9)], 1, 0, None),
    sort("veteran_javelot_de_service", "Javelot de service", "Le javelot réglementaire. Le même depuis la Première Ombre.", 4, (2, 5),
         [deg("impie", 5, 7)]),
    sort("veteran_garde_a_vous", "Garde-à-vous", "Le dos droit, la mâchoire serrée (elle tient mal).", 2, (0, 0),
         [bonus("resistance", 15, 1, element="acier"), bonus("resistance", 15, 1, element="givre")], 1, 2),
    sort("rotule_appel", "Appel", "« Présent ! » Même les morts répondent.", 2, (0, 4), [{"type": "gain_pa", "min": 1, "max": 1, "cibles": "allies"}], 1, 2),
    sort("rotule_corvee", "Corvée", "Corvée de patates, pour l'éternité.", 3, (1, 4), [deg("impie", 3, 5), {"type": "malus", "carac": "pa", "min": 2, "max": 2, "duree": 1}], 1, 1),
    sort("colonel_sabre_de_parade", "Sabre de parade", "Il ne sert qu'aux défilés. Il défile sur vous.", 4, (1, 1), [deg("acier", 7, 10)], 2),
    sort("colonel_pluie_de_phalanges", "Pluie de phalanges", "Il lance ses propres doigts. Il en a encore beaucoup.", 4, (1, 6),
         [deg("impie", 5, 8, cibles="ennemis")], 1, 0, {"type": "cercle", "taille": 1}, False),
    sort("colonel_rompez_les_rangs", "Rompez les rangs !", "Il s'effondre en tas d'os… et se remonte plus loin.", 2, (1, 4), [{"type": "teleportation"}], 1, 1),
    sort("colonel_etreinte_du_permafrost", "Étreinte du permafrost", "Le froid de trois siècles de garde.", 4, (1, 1),
         [deg("givre", 8, 11), {"type": "retrait_pm", "min": 2, "max": 2}]),
]

RES = [
    ressource("esquille_d_os", "Esquille d'os", "commun", 1, "agilite", "os_errant", Z, "Un éclat d'os errant. Il cherche encore son squelette."),
    ressource("moelle_fossile", "Moelle fossile", "peu_commun", 1, "vitalite", "os_errant", Z, "Trois siècles d'âge. Toujours nourrissante, paraît-il."),
    ressource("larme_gelee", "Larme gelée", "commun", 1, "perception", "pleureuse_de_l_ossuaire", Z, "Une larme de pleureuse. Elle ne fond jamais, elle non plus ne s'arrête pas."),
    ressource("voile_de_deuil", "Voile de deuil", "peu_commun", 1, "vitalite", "pleureuse_de_l_ossuaire", Z, "Noir, léger, et toujours un peu humide."),
    ressource("plaque_rouillee", "Plaque rouillée", "commun", 2, "force", "veteran_de_la_premiere_ombre", Z, "Un morceau d'armure réglementaire, modèle Première Ombre."),
    ressource("medaille_de_service", "Médaille de service", "peu_commun", 2, "intelligence", "veteran_de_la_premiere_ombre", Z, "« Trois siècles de bons et loyaux services. » Aucune pension associée."),
    ressource("epaulette_du_colonel", "Épaulette du Colonel", "rare", 2, "dommages", "colonel_ossature", Z, "Les galons d'un homme qui n'a jamais accepté d'être démobilisé."),
]

MONSTRES = [
    monstre("os_errant", "Os errant", "Un tibia, parfois un fémur, qui se promène seul à la recherche de son squelette.", 1, 14, 5, 4, 65,
            {"agilite": 4}, {"impie": 10, "flamme": -10}, ["os_coup_d_os", "os_ricochet"], 14, [1, 4],
            [drop("esquille_d_os", 0.6, [1, 2]), drop("moelle_fossile", 0.15)], mot="d'Os"),
    monstre("femur_du_general", "Fémur du Général", "Il a appartenu à un général. Il en a gardé les manières.", 1, 32, 6, 4, 85,
            {"agilite": 10}, {"impie": 15, "flamme": -5}, ["os_coup_d_os", "os_ricochet", "rotule_corvee"], 40, [5, 12],
            [drop("esquille_d_os", 0.9, [2, 4]), drop("moelle_fossile", 0.6, [1, 2])], elite=True, famille="os_errant"),
    monstre("pleureuse_de_l_ossuaire", "Pleureuse de l'Ossuaire", "Une veuve fantôme qui pleure tout le monde, même les vivants. Surtout les vivants.", 1, 24, 6, 3, 80,
            {"perception": 8}, {"givre": 20, "impie": 10, "flamme": -15}, ["pleureuse_larmes_glacees", "pleureuse_complainte"], 30, [3, 8],
            [drop("larme_gelee", 0.55, [1, 2]), drop("voile_de_deuil", 0.15)], "distance", mot="de Pleureuse"),
    monstre("grande_pleureuse", "Grande Pleureuse", "Elle pleure si fort que les autres pleureuses pleurent de la voir pleurer.", 1, 50, 7, 3, 100,
            {"perception": 16}, {"givre": 25, "impie": 15, "flamme": -10}, ["pleureuse_larmes_glacees", "pleureuse_complainte", "colonel_pluie_de_phalanges"], 70, [8, 18],
            [drop("larme_gelee", 0.9, [2, 4]), drop("voile_de_deuil", 0.6, [1, 2])], "distance", elite=True, famille="pleureuse_de_l_ossuaire"),
    monstre("veteran_de_la_premiere_ombre", "Vétéran de la Première Ombre", "Soldat squelette qui demande sa retraite depuis trois siècles. Le dossier est en cours.", 2, 50, 6, 3, 100,
            {"force": 18, "agilite": 18}, {"acier": 15, "impie": 10, "flamme": -10, "tempete": -5},
            ["veteran_lance_rouillee", "veteran_javelot_de_service", "veteran_garde_a_vous"], 110, [9, 20],
            [drop("plaque_rouillee", 0.5, [1, 2]), drop("medaille_de_service", 0.12)], mot="de Vétéran"),
    monstre("adjudant_rotule", "Adjudant Rotule", "Il fait l'appel. Tous les matins. Depuis trois cents ans. Personne n'a jamais été absent.", 2, 100, 7, 3, 120,
            {"force": 28, "agilite": 28}, {"acier": 20, "impie": 15, "flamme": -5},
            ["veteran_lance_rouillee", "veteran_javelot_de_service", "rotule_appel", "rotule_corvee"], 230, [20, 40],
            [drop("plaque_rouillee", 0.9, [2, 4]), drop("medaille_de_service", 0.5, [1, 2])], "soutien", elite=True, famille="veteran_de_la_premiere_ombre"),
    monstre("colonel_ossature", "Le Colonel Ossature", "Mort depuis trois siècles, il refuse toute démobilisation. Il a même refusé la sienne.", 2, 300, 7, 3, 95,
            {"force": 20, "agilite": 20}, {"acier": 20, "impie": 20, "givre": 10, "flamme": -20},
            ["colonel_sabre_de_parade", "rotule_appel", "rotule_corvee"], 760, [90, 150],
            [drop("epaulette_du_colonel", 1.0)], boss=True, mot="du Colonel",
            phases=[{"pv": 70, "message": "« Rompez les rangs ! » Le Colonel s'effondre en tas d'os… et se remonte plus loin.",
                     "sorts": ["colonel_pluie_de_phalanges", "colonel_rompez_les_rangs"], "effets": [bonus("portee", 2, 3)]},
                    {"pv": 30, "message": "« Personne ne quitte le front, même pas moi ! » Le givre prend ses os.",
                     "sorts": ["colonel_etreinte_du_permafrost"],
                     "effets": [bonus("pm", 2, 3)] + [bonus("resistance", 20, 3, element=e) for e in ("acier", "flamme", "givre", "tempete")]}]),
]

def pnj(m, id, nom, repliques, art, **k): return {"marqueur": m, "id": id, "nom": nom, "repliques": repliques, "art": art} | k
SQUELETTE = lambda **c: {"rig": "humain", "race": "squelette", "couleurs": MONO | c}

CARTES = [
    {"xy": (0, -1), "nom": "Grille de l'Ossuaire", "depart": True, "vers": {"bas": "crasse_roc_0_0"}, "liens": [(1, -1), (0, -2)],
     "groupes": [{"monstres": ["os_errant"]}, {"monstres": ["os_errant", "os_errant"]}, {"parmi": ["os_errant"], "nombre": [1, 2]}],
     "ressources": [("F", 3), ("U", 2)], "pnj_pos": [(0.42, 0.62), (0.7, 0.58), (0.62, 0.22)],
     "pnj": [pnj("a", "sergent_chef_clavicule", "Sergent-Chef Clavicule", [
                "Garde-à-vous, soldat ! Enfin, ce qu'il en reste. Bienvenue à l'Ossuaire de la Première Ombre.",
                "Ici, on sert. On a toujours servi. Personne ne se souvient de qui, mais on sert.",
                "L'enclume est dans votre maison, derrière la grille. Je vous explique comment on s'en sert ?"],
                SQUELETTE(tunique="6a2a2a", ceinture="c9a04e"), explique="forge"),
             pnj("b", "capitaine_sternum", "Capitaine Sternum, délégué des Voies", [
                "Capitaine Sternum, délégué aux carrières. Les carrières, ici, durent longtemps.",
                "Réputation, maîtrise, changement d'affectation : je vous fais le topo réglementaire ?"],
                SQUELETTE(tunique="2e4a6e", ceinture="e0b860"), explique="voies"),
             pnj("c", "tibia_troc", "Tibia-Troc, marchand d'occasion", [
                "Tout d'occasion, rien de neuf ! Comme nous, en somme."], SQUELETTE(tunique="7a6040"), marchand=True)]},
    {"xy": (1, -1), "nom": "Champ des Croix", "vers": {"bas": "crasse_roc_1_0"}, "liens": [(1, -2)], "obstacles": [("R", 22)],
     "groupes": [{"monstres": ["os_errant", "pleureuse_de_l_ossuaire"]}, {"monstres": ["pleureuse_de_l_ossuaire"]},
                 {"parmi": ["os_errant", "pleureuse_de_l_ossuaire"], "nombre": [2, 3]}, {"monstres": ["os_errant", "os_errant", "os_errant"]}],
     "ressources": [("F", 3), ("C", 1)], "pnj_pos": [(0.35, 0.45)],
     "pnj": [pnj("a", "fossoyeur_pelle_a_vide", "Pelle-à-Vide, fossoyeur", [
                "Je suis fossoyeur. Vivant. Ici. Vous imaginez la gêne.",
                "Chaque fois que je creuse un trou, quelqu'un en sort. Le métier perd tout son sens.",
                "Le Colonel, au fond de la crypte, refuse de partir à la retraite. Si quelqu'un pouvait l'y aider…"],
                {"rig": "humain", "couleurs": {"tunique": "4a4038", "manches": "3a3028", "pantalon": "2e2620", "cheveux": "5a5048"}})]},
    {"xy": (0, -2), "nom": "Catacombes de l'Appel", "liens": [(1, -2), (0, -3)],
     "obstacles": [("R", 16), ("M", 8)],
     "groupes": [{"monstres": ["pleureuse_de_l_ossuaire", "pleureuse_de_l_ossuaire"]},
                 {"monstres": ["pleureuse_de_l_ossuaire", "veteran_de_la_premiere_ombre"]},
                 {"parmi": ["pleureuse_de_l_ossuaire"], "nombre": [1, 3]}],
     "ressources": [("U", 2), ("I", 1)]},
    {"xy": (1, -2), "nom": "Caisse de retraite des Trépassés", "liens": [(1, -3)], "obstacles": [("R", 10), ("M", 10)],
     "groupes": [{"monstres": ["veteran_de_la_premiere_ombre"]}, {"monstres": ["veteran_de_la_premiere_ombre", "veteran_de_la_premiere_ombre"]},
                 {"parmi": ["veteran_de_la_premiere_ombre", "pleureuse_de_l_ossuaire"], "nombre": [2, 3]}],
     "ressources": [("I", 2), ("U", 1)], "pnj_pos": [(0.4, 0.4)],
     "pnj": [pnj("a", "guichetiere_vertebre", "Vertèbre, guichetière de la Caisse", [
                "Caisse de retraite des Trépassés, bonjour. Revenez demain.",
                "Je dis « revenez demain » depuis trois siècles. Personne n'est jamais revenu le bon jour.",
                "Votre dossier ? Il manque une pièce. Il manque toujours une pièce."],
                SQUELETTE(tunique="5a3a6a"))]},
    {"xy": (0, -3), "nom": "Charnier des Gradés", "obstacles": [("R", 20)],
     "groupes": [{"monstres": ["veteran_de_la_premiere_ombre", "veteran_de_la_premiere_ombre"]},
                 {"parmi": ["veteran_de_la_premiere_ombre"], "nombre": [1, 3]},
                 {"monstres": ["veteran_de_la_premiere_ombre", "pleureuse_de_l_ossuaire", "pleureuse_de_l_ossuaire"]}],
     "ressources": [("I", 2)]},
    {"xy": (1, -3), "nom": "Crypte du Colonel", "obstacles": [("R", 6), ("M", 10)], "ressources": [],
     "groupes": [{"monstres": ["colonel_ossature"], "reapparition": [45, 60]},
                 {"monstres": ["veteran_de_la_premiere_ombre", "veteran_de_la_premiere_ombre"]}]},
]

def objectif_vaincre(m, n): return {"type": "vaincre", "monstre": m, "nombre": n}
COND = {"race": "squelette"}
QUETES = [
    {"id": "ossuaire_appel_du_matin", "nom": "Appel du matin", "categorie": "principale", "acte": 1, "niveau": 1,
     "pnj": "sergent_chef_clavicule", "description": "Il vous manque un os. Le Sergent-Chef ne tolère pas une tenue incomplète.",
     "conditions": COND,
     "etapes": [{"objectifs": [objectif_vaincre("os_errant", 3),
                               {"type": "apporter", "objet": "votre_os_manquant", "nombre": 1, "pnj": "sergent_chef_clavicule",
                                "butin": {"monstres": ["os_errant"], "taux": 0.5}}]}],
     "dialogues": {"sergent_chef_clavicule": {
         "proposition": ["Soldat ! Il vous manque un os. Là, à gauche. Non, l'autre gauche.",
                         "Les os errants, dehors, en ont sûrement ramassé un. Récupérez le vôtre. Une tenue incomplète, c'est une tenue indigne."],
         "en_cours": ["Toujours incomplet, soldat. Je vois à travers vous. Littéralement."],
         "fin": ["Voilà. Remis en place. Vous êtes réglementaire. Rompez… mais pas trop."]}},
     "recompenses": {"xp_cr": 3, "ecus": 30}},
    {"id": "ossuaire_dossier_de_retraite", "nom": "Dossier de retraite", "categorie": "principale", "acte": 1, "niveau": 3,
     "pnj": "guichetiere_vertebre", "description": "Un dossier de retraite, en bonne et due forme. Il manque toujours une pièce.",
     "conditions": COND | {"quetes_terminees": ["ossuaire_appel_du_matin"]},
     "etapes": [{"objectifs": [objectif_vaincre("pleureuse_de_l_ossuaire", 3),
                               {"type": "apporter", "objet": "larme_gelee", "nombre": 3, "pnj": "guichetiere_vertebre"}]},
                {"objectifs": [{"type": "recolter", "objet": "bois_de_frene", "nombre": 5, "texte": "Récolter du frêne pour le cercueil réglementaire"},
                               {"type": "parler", "pnj": "guichetiere_vertebre"}]}],
     "dialogues": {"guichetiere_vertebre": {
         "proposition": ["Une demande de retraite ? Il faut le tampon des pleureuses : trois larmes gelées, en guise de signature.",
                         "Et le cercueil réglementaire, en frêne. Ce n'est pas moi qui fais les règles. Enfin si, mais je ne m'en souviens plus."],
         "en_cours": ["Il manque une pièce. Je vous l'avais dit."],
         "objectif": ["Les larmes, bien. Reste le bois du cercueil."],
         "fin": ["Tout est en ordre. Votre dossier est… refusé. Vous n'êtes pas mort assez longtemps. Revenez dans deux siècles."]}},
     "recompenses": {"xp_cr": 4, "ecus": 50}},
    {"id": "ossuaire_reaffectation", "nom": "Réaffectation", "categorie": "principale", "acte": 1, "niveau": 4,
     "pnj": "sergent_chef_clavicule", "description": "Les galeries de Crasse-Roc manquent de bras. Même sans muscles.",
     "conditions": COND | {"quetes_terminees": ["ossuaire_dossier_de_retraite"]},
     "etapes": [{"objectifs": [{"type": "parler", "pnj": "contremaitre_grumm", "texte": "Se présenter à Grumm, à l'Entrée des galeries"}]}],
     "dialogues": {"sergent_chef_clavicule": {
         "proposition": ["Retraite refusée ? Bien. Vous êtes réaffecté. Les gobelins de Crasse-Roc manquent de bras.",
                         "Allez voir le contremaître Grumm, à l'est, à l'Entrée des galeries. Et tenez-vous droit."],
         "en_cours": ["Toujours là ? L'est, soldat. Le soleil se lève de ce côté. Enfin, je crois."]},
                   "contremaitre_grumm": {"fin": ["Un squelette ? Parfait. Ça ne mange pas, ça ne dort pas, ça ne réclame pas. Ah si, ça réclame sa retraite. Bienvenue au club."]}},
     "recompenses": {"xp_cr": 5, "ecus": 60}},
    {"id": "ossuaire_demobilisation", "nom": "Démobilisation", "categorie": "secondaire", "niveau": 12,
     "pnj": "fossoyeur_pelle_a_vide", "description": "Le Colonel Ossature refuse de prendre sa retraite. Il va falloir l'y aider.",
     "conditions": {"une_quete_terminee": ["brumerive_tutoriel", "crasse_roc_tutoriel", "sylvebrume_tutoriel"]},
     "etapes": [{"objectifs": [{"type": "vaincre_groupe", "monstre": "colonel_ossature", "texte": "Démobiliser le Colonel Ossature, au fond de la Crypte"}]},
                {"objectifs": [{"type": "parler", "pnj": "fossoyeur_pelle_a_vide"}]}],
     "dialogues": {"fossoyeur_pelle_a_vide": {
         "proposition": ["Le Colonel, au fond de la crypte. Trois siècles qu'il refuse la quille. Il faudrait… l'aider à se décider."],
         "en_cours": ["Il est toujours là-bas ? Je l'entends crier « Garde-à-vous ! » d'ici."],
         "fin": ["Démobilisé ! Pour un temps, au moins. Il reviendra : ici, tout le monde revient. Mais merci."]}},
     "recompenses": {"xp_cr": 6, "ecus": 120}},
]

OBJETS_QUETE = [{"id": "votre_os_manquant", "nom": "Votre os manquant", "type": "quete", "rarete": "commun", "niveau": 1,
                 "description": "Un os à vous. Vous le reconnaissez à sa forme, et au fait qu'il vous manque."}]

ICONES = {"esquille_d_os": "dent_de_troll", "moelle_fossile": "cendre_tiede", "larme_gelee": "argent_lunaire",
          "voile_de_deuil": "fil_de_brume", "plaque_rouillee": "maillon_de_cotte", "medaille_de_service": "medaille_en_chocolat",
          "epaulette_du_colonel": "ecusson_de_milice", "votre_os_manquant": "dent_de_rat"}

ART = {
    "os_errant": {"image": "rat", "echelle": 0.5, "teinte": "e8e0c8"},
    "femur_du_general": {"image": "rat", "echelle": 0.6, "teinte": "f0d898"},
    "pleureuse_de_l_ossuaire": {"image": "rat", "planche": "sprites/squelette_theologue.png", "echelle": 0.95, "teinte": "a8c8e8"},
    "grande_pleureuse": {"image": "rat", "planche": "sprites/squelette_theologue.png", "echelle": 1.14, "teinte": "88a8e0"},
    "veteran_de_la_premiere_ombre": {"image": "rat", "planche": "sprites/squelette_guerrier.png", "echelle": 1.05},
    "adjudant_rotule": {"image": "rat", "planche": "sprites/squelette_paladin.png", "echelle": 1.26},
    "colonel_ossature": {"image": "rat", "planche": "sprites/squelette_myrmidon.png", "echelle": 1.45, "teinte": "e0e8ff"},
}

SOUS_ZONE = {"id": "ossuaire", "zone": Z, "prefixe": "Crasse-Roc", "palette": "crasse_roc", "bord": "R",
             "obstacles": [("R", 14)], "maison": "maison_ossuaire", "maison_modele": "maison_crasse_roc",
             "camp_depart": "crasse_roc_0_0", "races": ["squelette"],
             "passage": {"id": "crasse_roc_ossuaire", "nom": "Ossuaire de la Première Ombre", "prix": 10},
             "sorts": SORTS, "ressources": RES, "monstres": MONSTRES, "cartes": CARTES, "quetes": QUETES,
             "objets_quete": OBJETS_QUETE, "art_monstres": ART, "icones": ICONES}
