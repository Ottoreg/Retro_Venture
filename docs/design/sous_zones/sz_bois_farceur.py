"""Sous-zone des Mycéliens : le Bois-Farceur (nom provisoire), à l'est de Sylvebrume (sylvebrume.md).

La race n'existe pas encore : les quêtes de race (`race: mycelien`, QUETES_RACE, avec l'objet `ragot_de_limace`) sont
écrites mais pas produites (la validation refuse une race inconnue) ; aucune carte de départ n'est changée (`races` vide).
Quand la race existera : produire QUETES + QUETES_RACE et OBJETS_QUETE, et mettre "mycelien" dans `races`."""
from produire_sous_zone import sort, deg, bonus, ressource, monstre, drop, pnj, objectif_vaincre, TUTORIELS

Z = "sylvebrume"
MYCO = lambda chapeau, **c: {"rig": "humain", "couleurs": {"peau": "e8dcc0", "cheveux": chapeau, "tunique": "6a5a3a", "manches": "5a4a30", "pantalon": "4a3e2a"} | c}
SPORES = {"type": "cercle", "taille": 1}
RAGOT = {"type": "malus", "carac": "degats_infliges", "min": 10, "max": 10, "duree": 2}

SORTS = [
    sort("limace_bave_froide", "Bave froide", "Gluante, glacée, et elle colle aux bottes.", 3, (2, 4),
         [deg("givre", 3, 4), {"type": "retrait_pm", "min": 1, "max": 1}]),
    sort("limace_sucon", "Suçon", "Elle aspire. Vous perdez un peu de dignité.", 3, (1, 1), [deg("givre", 3, 5)], 2),
    sort("vesse_nuage_de_spores", "Nuage de spores", "Elle crache des spores en racontant sa vie. Les deux sont toxiques.", 4, (2, 5),
         [deg("givre", 2, 3, cibles="ennemis"), {"type": "poison", "element": "givre", "min": 1, "max": 2, "duree": 2, "cibles": "ennemis"}], 1, 1, SPORES, False),
    sort("vesse_bavardage", "Bavardage", "« Et là, tu sais pas ce qu'elle m'a dit… » Vous en oubliez d'agir.", 2, (1, 3),
         [{"type": "malus", "carac": "pa", "min": 1, "max": 1, "duree": 1}], 1, 1),
    sort("vesse_ragot", "Ragot", "Un ragot sur vous circule déjà. Vous frappez moins fort, par gêne.", 3, (0, 0),
         [RAGOT | {"cibles": "ennemis"}], 1, 2, {"type": "cercle", "taille": 3}),
    sort("mycelium_filaments", "Filaments", "Des filaments blancs qui vous ramènent vers lui, gentiment, fermement.", 3, (2, 4),
         [deg("acier", 3, 5), {"type": "attirance", "min": 2, "max": 2}]),
    sort("mycelium_etreinte_racinaire", "Étreinte racinaire", "Il vous prend dans ses racines. Il ne compte pas vous lâcher.", 4, (1, 1),
         [deg("acier", 5, 8), {"type": "etat", "etat": "enracine", "duree": 1}]),
    sort("rumeur_on_dit_que", "On dit que…", "Un ragot lancé à la volée. Il touche toujours quelqu'un.", 4, (2, 6), [deg("givre", 6, 9)]),
    sort("rumeur_il_parait_que", "Il paraît que…", "Elle disparaît dans un champignon et ressort d'un autre. Personne ne sait d'où elle vient.", 2, (1, 5),
         [{"type": "teleportation"}], 1, 1),
    sort("rumeur_tout_le_monde_le_sait", "Tout le monde le sait !", "Le ragot vous serre de près, puis de plus près encore.", 4, (1, 2),
         [deg("acier", 7, 10, cibles="ennemis"), {"type": "etat", "etat": "enracine", "duree": 1, "cibles": "ennemis"}], 1, 1, SPORES),
]

RES = [
    ressource("bave_de_limace", "Bave de limace", "commun", 1, "perception", "limace_gourmande", Z, "Froide, gluante et étrangement brillante. Les Mycéliens la détestent."),
    ressource("mucus_epais", "Mucus épais", "peu_commun", 1, "vitalite", "limace_gourmande", Z, "Ça colle. Ça colle vraiment beaucoup."),
    ressource("spores_bavardes", "Spores bavardes", "commun", 1, "intelligence", "vesse_de_loup_bavarde", Z, "En tendant l'oreille, on les entend chuchoter des ragots."),
    ressource("chapeau_de_vesse", "Chapeau de vesse", "peu_commun", 1, "agilite", "vesse_de_loup_bavarde", Z, "Il fait « pouf » quand on appuie dessus. Personne ne résiste."),
    ressource("filament_blanc", "Filament blanc", "commun", 2, "force", "mycelium_errant", Z, "Plus solide qu'une corde. Il pousse encore un peu, la nuit."),
    ressource("motte_d_humus", "Motte d'humus", "peu_commun", 2, "vitalite", "mycelium_errant", Z, "De la terre riche, très riche. On y entend des rumeurs."),
    ressource("echo_de_la_rumeur", "Écho de la Rumeur", "rare", 2, "dommages_givre", "la_rumeur", Z, "Un ragot condensé. Il répète sans fin quelque chose sur vous."),
]

MONSTRES = [
    monstre("limace_gourmande", "Limace gourmande", "Elle mange les Mycéliens, qui en font tout un drame. Et le racontent à tout le monde.", 1, 16, 5, 3, 60,
            {"perception": 4}, {"givre": 15, "flamme": -10}, ["limace_bave_froide", "limace_sucon"], 14, [1, 4],
            [drop("bave_de_limace", 0.6, [1, 2]), drop("mucus_epais", 0.15)], mot="de Limace"),
    monstre("limace_reine", "Limace reine", "Elle a mangé un cèpe entier. Le cèpe ne s'en est jamais remis, elle si.", 1, 34, 6, 3, 80,
            {"perception": 10}, {"givre": 20, "flamme": -5}, ["limace_bave_froide", "limace_sucon", "vesse_bavardage"], 40, [5, 12],
            [drop("bave_de_limace", 0.9, [2, 4]), drop("mucus_epais", 0.6, [1, 2])], elite=True, famille="limace_gourmande"),
    monstre("vesse_de_loup_bavarde", "Vesse-de-loup bavarde", "Champignon sauvage qui crache des spores en racontant sa vie. Elle n'a rien vécu.", 1, 24, 6, 2, 75,
            {"perception": 6, "intelligence": 4}, {"givre": 15, "acier": 5, "flamme": -15},
            ["vesse_nuage_de_spores", "vesse_bavardage"], 30, [3, 8],
            [drop("spores_bavardes", 0.55, [1, 2]), drop("chapeau_de_vesse", 0.15)], "distance", mot="de Vesse"),
    monstre("pied_de_mouton_ancestral", "Pied-de-Mouton ancestral", "Le plus vieux champignon du bois. Il connaît tous les ragots depuis le premier.", 2, 80, 7, 2, 100,
            {"perception": 20, "intelligence": 10}, {"givre": 20, "acier": 10, "flamme": -10},
            ["vesse_nuage_de_spores", "vesse_bavardage", "vesse_ragot"], 150, [12, 26],
            [drop("spores_bavardes", 0.9, [2, 4]), drop("chapeau_de_vesse", 0.6, [1, 2])], "soutien", elite=True, famille="vesse_de_loup_bavarde"),
    monstre("mycelium_errant", "Mycélium errant", "Un réseau de filaments qui s'est perdu. Il cherche à se reconnecter. À vous, de préférence.", 2, 55, 6, 3, 95,
            {"force": 18, "perception": 14}, {"acier": 20, "givre": 10, "flamme": -15},
            ["mycelium_filaments", "mycelium_etreinte_racinaire"], 110, [9, 20],
            [drop("filament_blanc", 0.5, [1, 2]), drop("motte_d_humus", 0.12)], mot="de Mycélium"),
    monstre("grand_reseau_errant", "Grand Réseau errant", "Tout un pan du réseau qui s'est mis à marcher. Il entend tout ce que vous pensez. Ou presque.", 2, 110, 7, 3, 110,
            {"force": 28, "perception": 22}, {"acier": 25, "givre": 15, "flamme": -10},
            ["mycelium_filaments", "mycelium_etreinte_racinaire", "vesse_bavardage"], 230, [20, 40],
            [drop("filament_blanc", 0.9, [2, 4]), drop("motte_d_humus", 0.5, [1, 2])], elite=True, famille="mycelium_errant"),
    monstre("la_rumeur", "La Rumeur", "Un ragot devenu si gros qu'il a pris corps dans le réseau. Personne ne sait d'où il vient. Tout le monde le répète.", 2, 300, 7, 3, 105,
            {"perception": 22, "force": 18}, {"givre": 25, "acier": 15, "flamme": -20},
            ["rumeur_on_dit_que", "vesse_bavardage", "vesse_nuage_de_spores"], 760, [90, 150],
            [drop("echo_de_la_rumeur", 1.0)], "distance", boss=True, mot="de la Rumeur",
            phases=[{"pv": 70, "message": "« Il paraît que… » La Rumeur se faufile de champignon en champignon.",
                     "sorts": ["rumeur_il_parait_que", "vesse_ragot"], "effets": [bonus("portee", 1, 3)]},
                    {"pv": 30, "message": "« Tout le monde le sait ! » La Rumeur vous serre de près.",
                     "sorts": ["rumeur_tout_le_monde_le_sait", "mycelium_etreinte_racinaire"],
                     "effets": [bonus("pm", 1, 3)] + [bonus("resistance", 20, 3, element=e) for e in ("acier", "flamme", "givre", "tempete")]}]),
]

CARTES = [
    {"xy": (3, 0), "nom": "Rond des Rumeurs", "depart": True, "vers": {"gauche": "sylvebrume_2_0"}, "liens": [(4, 0), (3, 1)],
     "groupes": [{"monstres": ["limace_gourmande"]}, {"monstres": ["limace_gourmande", "limace_gourmande"]}, {"parmi": ["limace_gourmande"], "nombre": [1, 2]}],
     "ressources": [("F", 3), ("C", 1)], "pnj_pos": [(0.42, 0.62), (0.7, 0.58), (0.62, 0.22)],
     "pnj": [pnj("a", "doyenne_lamelle", "Doyenne Lamelle", [
                "Bienvenue au Bois-Farceur, petite pousse. On savait que tu venais : on sait toujours tout.",
                "Par nos racines, on entend ce qui se dit partout. On n'en fait rien. Enfin, on le répète, c'est tout.",
                "L'enclume est dans votre maison, sous la souche. Je vous explique comment s'en servir ? Tout le monde le sait déjà, remarquez."],
                MYCO("b0703a", tunique="5a4a2a", ceinture="c9a04e"), explique="forge"),
             pnj("b", "oncle_sporophore", "Oncle Sporophore, délégué des Voies", [
                "Délégué aux Voies. On dit que vous hésitez. On dit beaucoup de choses.",
                "Réputation, maîtrise, changement de Voie : je vous explique ce qu'on en dit ?"],
                MYCO("e8b040", tunique="3a5a3a", ceinture="e0b860"), explique="voies"),
             pnj("c", "commere_girolle", "Commère Girolle, marchande", [
                "Tout est à vendre ! Et pour le même prix, je vous dis ce que votre voisin a acheté."],
                MYCO("e8a030", tunique="7a6040"), marchand=True)]},
    {"xy": (4, 0), "nom": "Sous-bois des Spores", "liens": [(4, 1)], "obstacles": [("A", 18)],
     "groupes": [{"monstres": ["limace_gourmande", "vesse_de_loup_bavarde"]}, {"monstres": ["vesse_de_loup_bavarde"]},
                 {"parmi": ["limace_gourmande", "vesse_de_loup_bavarde"], "nombre": [2, 3]}, {"monstres": ["limace_gourmande", "limace_gourmande", "limace_gourmande"]}],
     "ressources": [("F", 3)], "pnj_pos": [(0.35, 0.45)],
     "pnj": [pnj("a", "tante_volve", "Tante Volve", [
                "Je sais ce que vous allez dire. Vous allez dire bonjour. … Vous voyez ?",
                "La Rumeur, au Cœur du Réseau, raconte des horreurs sur tout le monde. Même sur moi. Surtout sur moi. Et c'est vrai, en plus."],
                MYCO("c03028", tunique="5a3a3a"))]},
    {"xy": (3, 1), "nom": "Souche-Relais", "vers": {"gauche": "sylvebrume_2_1"}, "liens": [(4, 1), (3, 2)], "obstacles": [("A", 14)],
     "groupes": [{"monstres": ["vesse_de_loup_bavarde", "vesse_de_loup_bavarde"]}, {"parmi": ["vesse_de_loup_bavarde", "limace_gourmande"], "nombre": [2, 3]},
                 {"monstres": ["mycelium_errant"]}, {"monstres": ["vesse_de_loup_bavarde", "limace_gourmande"]}],
     "ressources": [], "pnj_pos": [(0.4, 0.4)],
     "pnj": [pnj("a", "facteur_hyphe", "Facteur Hyphe", [
                "Facteur Hyphe, relais officiel des ragots. Un ragot à envoyer ? Tarif normal ou urgent ?",
                "Les vesses brouillent le réseau. On ne s'entend plus médire."], MYCO("c8a060", tunique="3a4a6a"))]},
    {"xy": (4, 1), "nom": "Humus profond", "liens": [(4, 2)], "obstacles": [("A", 12), ("R", 8)],
     "groupes": [{"monstres": ["mycelium_errant"]}, {"monstres": ["mycelium_errant", "vesse_de_loup_bavarde"]},
                 {"parmi": ["mycelium_errant", "vesse_de_loup_bavarde"], "nombre": [2, 3]}],
     "ressources": [("U", 2), ("I", 2)]},
    {"xy": (3, 2), "nom": "Cave à champignons", "liens": [(4, 2)], "obstacles": [("R", 12), ("M", 8)],
     "groupes": [{"monstres": ["mycelium_errant", "mycelium_errant"]}, {"parmi": ["mycelium_errant"], "nombre": [2, 3]},
                 {"monstres": ["mycelium_errant", "vesse_de_loup_bavarde", "vesse_de_loup_bavarde"]}],
     "ressources": [("U", 2), ("I", 1)]},
    {"xy": (4, 2), "nom": "Cœur du Réseau", "obstacles": [("A", 8), ("M", 8)], "ressources": [],
     "groupes": [{"monstres": ["la_rumeur"], "reapparition": [45, 60]},
                 {"monstres": ["mycelium_errant", "mycelium_errant"]}]},
]

COND = {"race": "mycelien"}
QUETES_RACE = [
    {"id": "bois_farceur_premier_ragot", "nom": "Premier ragot", "categorie": "principale", "acte": 1, "niveau": 1,
     "pnj": "doyenne_lamelle", "description": "Les limaces disent des choses sur nous. Il faut savoir quoi.",
     "conditions": COND,
     "etapes": [{"objectifs": [objectif_vaincre("limace_gourmande", 3),
                               {"type": "apporter", "objet": "ragot_de_limace", "nombre": 1, "pnj": "doyenne_lamelle",
                                "butin": {"monstres": ["limace_gourmande"], "taux": 0.5}}]}],
     "dialogues": {"doyenne_lamelle": {
         "proposition": ["Les limaces mangent nos cousins et, en plus, elles parlent sur nous. Allez en battre trois.",
                         "Et rapportez-moi ce qu'elles disaient. Mot pour mot."],
         "en_cours": ["Alors ? Qu'est-ce qu'elles disent ? Je meurs d'envie de savoir. Pas littéralement."],
         "fin": ["« Les cèpes sont trop gros » ? QUELLE INSOLENCE. Merci, petite pousse. Je vais le répéter à tout le monde."]}},
     "recompenses": {"xp_cr": 3, "ecus": 30}},
    {"id": "bois_farceur_relais_en_panne", "nom": "Le relais est en panne", "categorie": "principale", "acte": 1, "niveau": 3,
     "pnj": "facteur_hyphe", "description": "Les vesses brouillent le réseau. Plus aucun ragot ne passe.",
     "conditions": COND | {"quetes_terminees": ["bois_farceur_premier_ragot"]},
     "etapes": [{"objectifs": [objectif_vaincre("vesse_de_loup_bavarde", 3)]},
                {"objectifs": [{"type": "recolter", "objet": "bois_de_frene", "nombre": 5, "texte": "Récolter du frêne pour réparer la Souche-Relais"},
                               {"type": "parler", "pnj": "facteur_hyphe"}]}],
     "dialogues": {"facteur_hyphe": {
         "proposition": ["Trois vesses bavardent si fort qu'elles brouillent le réseau. Faites-les taire.",
                         "Puis rapportez-moi du frêne : la Souche-Relais a besoin d'une rallonge."],
         "en_cours": ["Toujours brouillé. J'ai reçu « …tte …achez qui … » ce matin. Insupportable."],
         "objectif": ["Le réseau respire. Reste le bois pour la souche."],
         "fin": ["Le relais refonctionne ! Premier message reçu : un ragot sur vous. Je vous le lis ?"]}},
     "recompenses": {"xp_cr": 4, "ecus": 50}},
    {"id": "bois_farceur_correspondant", "nom": "Correspondant à la Lisière", "categorie": "principale", "acte": 1, "niveau": 4,
     "pnj": "doyenne_lamelle", "description": "Le réseau a besoin d'un correspondant chez les elfes. Discret. Ou pas.",
     "conditions": COND | {"quetes_terminees": ["bois_farceur_relais_en_panne"]},
     "etapes": [{"objectifs": [{"type": "parler", "pnj": "gardienne_elwyn", "texte": "Écouter les elfes de près, à la Clairière de la Lisière"}]}],
     "dialogues": {"doyenne_lamelle": {
         "proposition": ["Les elfes de la Lisière ne parlent jamais assez fort pour nos racines. Allez les écouter de près.",
                         "Présentez-vous à Elwyn, la gardienne, à l'ouest. Dites que vous êtes là pour aider. C'est presque vrai."],
         "en_cours": ["L'ouest, petite pousse. Là où ça sent le parfum et la condescendance."]},
                   "gardienne_elwyn": {"fin": ["Un Mycélien ? Vous êtes là pour aider, dites-vous. Bien sûr. Et je suis là pour vous surveiller. Bienvenue à la Lisière."]}},
     "recompenses": {"xp_cr": 5, "ecus": 60}},
]
QUETES = [
    {"id": "bois_farceur_dementi", "nom": "Démenti", "categorie": "secondaire", "niveau": 12,
     "pnj": "tante_volve", "description": "La Rumeur raconte des horreurs sur tout le monde. Tante Volve exige un démenti.",
     "conditions": {"une_quete_terminee": TUTORIELS},
     "etapes": [{"objectifs": [{"type": "vaincre_groupe", "monstre": "la_rumeur", "texte": "Démentir la Rumeur, au Cœur du Réseau"}]},
                {"objectifs": [{"type": "parler", "pnj": "tante_volve"}]}],
     "dialogues": {"tante_volve": {
         "proposition": ["La Rumeur dit que j'ai des taches. Des TACHES. Allez au Cœur du Réseau et démentez-la. Fermement."],
         "en_cours": ["Elle le répète encore. Tout le bois le sait maintenant."],
         "fin": ["Démentie ! Bon, elle reviendra : une rumeur revient toujours. Mais merci. … Vous trouvez que j'ai des taches ?"]}},
     "recompenses": {"xp_cr": 6, "ecus": 120}},
]

OBJETS_QUETE = [{"id": "ragot_de_limace", "nom": "Ragot de limace", "type": "quete", "rarete": "commun", "niveau": 1,
                 "description": "Ce que disaient les limaces. C'est méchant, et un peu gluant."}]

ICONES = {"bave_de_limace": "glande_acide", "mucus_epais": "seve_ancienne", "spores_bavardes": "spores_grincheuses",
          "chapeau_de_vesse": "chapeau_de_morille", "filament_blanc": "fil_de_brume", "motte_d_humus": "copeaux_de_bois",
          "echo_de_la_rumeur": "message_intercepte", "ragot_de_limace": "liste_du_heraut"}

ART = {
    "limace_gourmande": {"image": "grouilleur", "echelle": 0.6, "teinte": "a0b090"},
    "limace_reine": {"image": "grouilleur", "echelle": 0.8, "teinte": "c0a0d0"},
    "vesse_de_loup_bavarde": {"image": "morille", "planche": "sprites/morille.png", "echelle": 0.6, "teinte": "f0e8d8"},
    "pied_de_mouton_ancestral": {"image": "morille", "planche": "sprites/morille.png", "echelle": 0.78, "teinte": "f0d8b0"},
    "mycelium_errant": {"image": "arbre_vivant", "echelle": 0.75, "teinte": "f0ece0"},
    "grand_reseau_errant": {"image": "arbre_vivant", "echelle": 0.95, "teinte": "e0d8f0"},
    "la_rumeur": {"image": "morille", "planche": "sprites/morille.png", "echelle": 1.0, "teinte": "c8a0e8"},
}

SOUS_ZONE = {"id": "bois_farceur", "zone": Z, "prefixe": "Sylvebrume", "palette": "sylvebrume", "bord": "A",
             "obstacles": [("A", 14)], "maison": "maison_bois_farceur", "maison_modele": "maison_sylvebrume",
             "camp_depart": "sylvebrume_0_0", "races": [],
             "passage": {"id": "sylvebrume_bois_farceur", "nom": "Bois-Farceur", "prix": 10},
             "sorts": SORTS, "ressources": RES, "monstres": MONSTRES, "cartes": CARTES, "quetes": QUETES,
             "objets_quete": [], "art_monstres": ART, "icones": ICONES}
