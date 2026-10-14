"""Hautepierre et ses environs (terrain commun, niveaux 12 à 30)."""
from common import *

# ---------------- objets ----------------
ressource("bourse_vide", "Bourse vide", "commun",
          "Vide. Comme toutes celles qu'il a volées, apparemment. Il ne comprend pas non plus.", "butin:detrousseur",
          "petite bourse de cuir dégonflée, cordon dénoué")
ressource("carte_au_tresor_douteuse", "Carte au trésor douteuse", "peu_commun",
          "Une croix rouge, une flèche, et la mention « à peu près par là ».", "butin:detrousseur",
          "parchemin jauni, croix rouge et pointillés, coin déchiré")
ressource("dent_de_troll", "Dent de troll", "commun",
          "Grosse comme un poing, jaune comme un vieux fromage. Le troll en a d'autres.", "butin:troll_des_ponts",
          "grosse molaire jaunâtre ébréchée")
ressource("recette_de_troll", "Recette de troll", "peu_commun",
          "« Aventurier rôti, trois façons. » Il manque la troisième, heureusement.", "butin:troll_des_ponts",
          "feuille tachée de gras, dessin maladroit d'un personnage sur une broche")
ressource("plume_de_corbac", "Plume de corbac", "commun",
          "Noire, luisante, et elle a l'air de vous écouter.", "butin:corbac_espion",
          "longue plume noire aux reflets bleus")
ressource("message_intercepte", "Message intercepté", "peu_commun",
          "« Rapport n° 412 : RAS. Rapport n° 413 : toujours RAS. Rapport n° 414 : j'ai faim. »", "butin:corbac_espion",
          "petit rouleau de papier attaché par un fil rouge, cachet noir")
ressource("eclat_de_gargouille", "Éclat de gargouille", "commun",
          "Un morceau de gargouille. Il grimace encore.", "butin:gargouille",
          "éclat de pierre grise avec un œil sculpté")
ressource("coeur_de_pierre", "Cœur de pierre", "peu_commun",
          "Il bat une fois par heure. On ne sait pas pour qui.", "butin:gargouille",
          "pierre en forme de cœur, veinée de bleu, légère lueur")
ressource("cendre_tiede", "Cendre tiède", "commun",
          "Elle tombe de l'est depuis quelques mois. Elle ne refroidit jamais tout à fait.",
          "butin:cendrillon|variantes corrompues", "petit tas de cendre grise avec deux braises orange")
ressource("invitation_au_bal", "Invitation au bal", "peu_commun",
          "« Bal du Souverain, minuit. Tenue cendrée exigée. Les citrouilles ne sont pas admises. »", "butin:cendrillon",
          "carton noir bordé d'or, lettres argentées, coin roussi")
ressource("cuir_d_olifant", "Cuir d'olifant", "commun",
          "Épais comme un mur de Hautepierre, et presque aussi gris.", "butin:olifant_de_guerre",
          "carré de cuir gris épais et ridé")
ressource("ivoire_d_olifant", "Ivoire d'olifant", "peu_commun",
          "Un morceau de défense. On en fait des cors ; l'olifant n'a pas été consulté.", "butin:olifant_de_guerre",
          "défense d'ivoire courbe, pointe cassée")
ressource("eclat_de_cendre", "Éclat de cendre", "rare",
          "Un fragment noir qui brûle sans flamme. Les Corrompus en ont plein le corps.",
          "butin:variantes corrompues|boss:grondin", "éclat de pierre noire anguleux, fissures rouge vif")

equipement("capuche_de_detrousseur", "Capuche de détrousseur", "coiffe", "peu_commun", 13,
           "On ne voit pas votre visage. On voit très bien vos intentions.",
           {"agilite": 0.4, "chance": 0.3, "prospection": 0.3}, "butin:detrousseur",
           "capuche vert sombre rabattue, masque de tissu sur le bas")
equipement("dague_de_detrousseur", "Dague de détrousseur", "arme", "peu_commun", 14,
           "Équilibrée pour le lancer, et pour le retour : elle a une ficelle.",
           {"agilite": 0.7, "initiative": 0.3}, "butin:detrousseur",
           "dague fine à lame triangulaire, ficelle rouge enroulée au manche",
           attaque=attaque(14, "peu_commun", "tempete", 3, (1, 3), par_tour=2))
equipement("bottes_de_grand_chemin", "Bottes de grand chemin", "bottes", "peu_commun", 14,
           "Elles connaissent toutes les routes, et surtout tous les fossés pour se cacher.",
           {"agilite": 0.4, "vitalite": 0.3, "initiative": 0.3}, "butin:detrousseur",
           "bottes souples à revers, couvertes de poussière de route")
equipement("ceinture_de_troll", "Ceinture de troll", "ceinture", "peu_commun", 16,
           "Une corde de pont, nouée deux fois. Elle fait trois fois votre tour de taille.",
           {"vitalite": 0.6, "force": 0.4}, "butin:troll_des_ponts",
           "grosse corde de chanvre nouée, un morceau de planche encore accroché")
equipement("anneau_de_nez_de_troll", "Anneau de nez de troll", "anneau", "peu_commun", 17,
           "Il fait le tour du doigt. Et de la main. Et un peu du poignet.",
           {"force": 0.5, "vitalite": 0.3, "sagesse": 0.2}, "butin:troll_des_ponts",
           "gros anneau de fer brut, légèrement verdâtre")
equipement("massue_de_troll", "Massue de troll", "arme", "rare", 17,
           "Un tronc d'arbre avec un clou. Le clou, c'est pour l'élégance.",
           {"force": 0.6, "vitalite": 0.4}, "butin:troll_des_ponts",
           "énorme massue de bois noueux, un clou de fer planté en travers",
           attaque=attaque(17, "rare", "acier", 5, (1, 1), extra=[simple("poussee", 1, 1)]), conditions={"force": 40})
equipement("chapeau_a_plume_de_corbac", "Chapeau à plume de corbac", "coiffe", "peu_commun", 19,
           "La plume tourne la tête quand quelqu'un parle de vous.",
           {"agilite": 0.5, "prospection": 0.25, "initiative": 0.25}, "butin:corbac_espion",
           "chapeau de feutre gris à large bord, longue plume noire")
equipement("amulette_oeil_de_corbac", "Amulette œil-de-corbac", "amulette", "rare", 20,
           "Un œil de verre noir qui voit ce qui brille. Surtout ce qui brille dans les poches des autres.",
           {"agilite": 0.4, "prospection": 0.3, "sagesse": 0.3}, "butin:corbac_espion",
           "perle de verre noir brillante sertie d'argent, cordon de cuir")
equipement("cape_de_plumes_noires", "Cape de plumes noires", "cape", "rare", 21,
           "Elle bruisse comme une volée de corbeaux. Les vrais corbeaux la trouvent vulgaire.",
           {"agilite": 0.5, "vitalite": 0.3, "initiative": 0.2}, "butin:corbac_chef_espion",
           "cape faite de plumes noires superposées, col en plumes dressées")
equipement("anneau_de_granit", "Anneau de granit", "anneau", "peu_commun", 22,
           "Taillé dans une gargouille. Lourd, solide, un peu grimaçant.",
           {"vitalite": 0.5, "force": 0.25, "chance": 0.25}, "butin:gargouille",
           "anneau épais de pierre grise mouchetée")
equipement("hallebarde_de_la_vieille_garde", "Hallebarde de la Vieille Garde", "arme", "rare", 22,
           "Arme des gardes d'il y a trois siècles. Les gargouilles l'ont gardée, par habitude.",
           {"force": 0.5, "vitalite": 0.3, "sagesse": 0.2}, "butin:gargouille",
           "hallebarde à fer en croissant, hampe longue en diagonale, ruban bleu délavé",
           attaque=attaque(22, "rare", "acier", 4, (1, 2)))
equipement("bottes_de_gargouille", "Bottes de gargouille", "bottes", "rare", 23,
           "On ne court pas avec. On ne tombe pas non plus.",
           {"vitalite": 0.4, "force": 0.3, "chance": 0.3}, "butin:gargouille",
           "bottes de pierre grise aux griffes sculptées sur la pointe")
equipement("amulette_coeur_de_pierre", "Amulette cœur-de-pierre", "amulette", "rare", 24,
           "Elle bat une fois par heure, contre votre poitrine. On s'y fait.",
           {"vitalite": 0.5, "chance": 0.3, "sagesse": 0.2}, "butin:gargouille_de_la_grande_porte",
           "pendentif en forme de cœur de pierre veiné de bleu, chaîne d'argent")
equipement("pantoufles_de_cendre", "Pantoufles de cendre", "bottes", "rare", 25,
           "Il n'y en a qu'une paire, mais elles ne vont à personne. Sauf à vous, bizarrement.",
           {"intelligence": 0.4, "agilite": 0.3, "initiative": 0.3}, "butin:cendrillon",
           "paire de pantoufles grises scintillantes, braises sur les pointes")
equipement("masque_de_cendrillon", "Masque de Cendrillon", "coiffe", "rare", 26,
           "Un loup de bal noir. Personne ne vous reconnaît, surtout pas vous.",
           {"intelligence": 0.5, "vitalite": 0.3, "sagesse": 0.2}, "butin:cendrillon",
           "loup de bal noir à paillettes argentées, petite plume grise")
equipement("baguette_de_cendrillon", "Baguette de Cendrillon", "arme", "rare", 26,
           "Pas magique. Enfin, pas comme on l'espérait.",
           {"intelligence": 0.6, "sagesse": 0.2, "vitalite": 0.2}, "butin:cendrillon",
           "baguette noire fine terminée par une étoile de cendre rougeoyante",
           attaque=attaque(26, "rare", "flamme", 4, (2, 6)))
equipement("bague_de_minuit", "Bague de minuit", "anneau", "rare", 27,
           "Elle sonne douze coups. Ensuite, tout redevient citrouille.",
           {"intelligence": 0.4, "dommages": 0.2, "vitalite": 0.3, "critique": 0.1}, "butin:cendrillon",
           "bague d'argent sertie d'un petit cadran d'horloge aux aiguilles sur 12")
equipement("cape_en_cuir_d_olifant", "Cape en cuir d'olifant", "cape", "rare", 28,
           "Lourde, raide, increvable. On a l'air d'une tente, mais d'une tente blindée.",
           {"vitalite": 0.5, "force": 0.3, "sagesse": 0.2}, "butin:olifant_de_guerre",
           "cape épaisse grise ridée, bordure rouge brodée")
equipement("semelles_d_olifant", "Semelles d'olifant", "bottes", "rare", 29,
           "Chaque pas fait trembler le plancher. Chaque plancher s'en souvient.",
           {"vitalite": 0.5, "force": 0.3, "initiative": 0.2}, "butin:olifant_de_guerre",
           "grosses bottes rondes grises aux semelles épaisses comme des pattes d'éléphant")
equipement("cor_d_olifant", "Cor d'olifant", "amulette", "epique", 29,
           "Un cor taillé dans une défense. Quand on souffle dedans, quelqu'un, quelque part, accourt. Ou fuit.",
           {"force": 0.3, "vitalite": 0.3, "dommages": 0.2, "sagesse": 0.2}, "butin:olifant_de_guerre",
           "cor d'ivoire recourbé cerclé d'or, en bandoulière sur un lacet rouge", boutique=False)
equipement("heaume_du_belier", "Heaume du Bélier", "coiffe", "epique", 30,
           "Taillé dans la tête de Grondin. Les portes s'ouvrent devant vous. Souvent en morceaux.",
           {"force": 0.4, "vitalite": 0.4, "dommages": 0.2}, "boss:grondin",
           "heaume de fer noir en forme de tête de loup, yeux rouges", boutique=False)
equipement("marteau_de_grondin", "Marteau de Grondin", "arme", "legendaire", 30,
           "Le dernier morceau du bélier. Il frappe toujours trois coups, même quand on n'en demande qu'un.",
           {"force": 0.45, "vitalite": 0.25, "dommages": 0.3}, "boss:grondin",
           "gros marteau de guerre à tête de loup en fer noir, manche cerclé, braises dans les yeux",
           attaque=attaque(30, "legendaire", "acier", 5, (1, 1), extra=[simple("poussee", 1, 1)]),
           conditions={"force": 80}, fixe={"pa": [1, 1]}, boutique=False)
equipement("anneau_du_gond", "Anneau du Gond", "anneau", "epique", 30,
           "Un gond de la Grande Porte de Hautepierre, arraché par Grondin. Il tient toujours.",
           {"force": 0.3, "intelligence": 0.3, "vitalite": 0.2, "dommages": 0.2}, "boss:grondin",
           "gros anneau de fer forgé en forme de gond, rivet doré", boutique=False)

# ---------------- sorts ----------------
sort("detrousseur_surin", "Coup de surin", "Dans l'ombre, sans prévenir, sans facture.",
     3, (1, 1), [dg("impie", 5, 7)], relance={"par_tour": 2})
sort("detrousseur_la_bourse_ou_la_vie", "La bourse ou la vie", "Vous choisissez la bourse. Il prend quand même un peu de la vie.",
     3, (1, 2), [dg("tempete", 3, 5), malus("chance", 15, 15, 2)])
sort("chef_de_bande_embuscade", "Embuscade", "Ils étaient cachés dans le fossé. Ils y sont toujours, d'ailleurs.",
     3, (1, 4), [piege([dg("impie", 9, 13, "ennemis"), malus("pm", 2, 2, 1, cibles="ennemis")])], ldv=False,
     relance={"par_tour": 1, "delai": 2})
sort("troll_coup_de_massue", "Coup de massue", "Pas de technique, beaucoup de massue.",
     4, (1, 1), [dg("acier", 8, 11), simple("poussee", 1, 1)])
sort("troll_rocher", "Lancer de rocher", "Il arrache un morceau de pont et vous le rend.",
     4, (2, 5), [dg("acier", 5, 8)])
sort("gastronome_marinade", "Marinade", "Il vous assaisonne avant cuisson. Le feu vous fera plus mal ensuite.",
     3, (1, 2), [poison("flamme", 4, 6, 3), malus("resistance", 10, 10, 3, element="flamme")])
sort("corbac_bec", "Coup de bec", "Toujours dans l'œil. Il vise bien, il a de l'entraînement.",
     3, (1, 1), [dg("acier", 5, 7)])
sort("corbac_pique", "Piqué", "Il tombe du ciel comme un mauvais présage, et c'en est un.",
     4, (2, 5), [dg("tempete", 6, 9)])
sort("chef_espion_rapport", "Rapport détaillé", "Il a tout noté. Vos faiblesses aussi.",
     3, (1, 6), [malus("resistance", 15, 15, 2, element="tempete"), malus("portee", 1, 1, 1)])
sort("gargouille_griffes", "Griffes de pierre", "Trois siècles à garder une gouttière, ça aiguise les griffes.",
     4, (1, 1), [dg("acier", 7, 10)])
sort("gargouille_gargouillis", "Gargouillis", "Elle crache l'eau de pluie de la semaine. Glacée.",
     3, (2, 4), [dg("givre", 5, 7)])
sort("gargouille_petrification", "Regard de pierre", "Un regard figé. Vos jambes suivent l'exemple.",
     3, (1, 3), [dg("givre", 3, 5), malus("pm", 2, 2, 1), malus("pa", 1, 1, 1)], relance={"par_tour": 1, "delai": 2})
sort("cendrillon_cendres_ardentes", "Cendres ardentes", "Une poignée de cendre du Souverain, jetée au visage. Ça ne part pas.",
     4, (2, 5), [dg("flamme", 6, 9)])
sort("cendrillon_bal_de_minuit", "Bal de minuit", "Une valse de cendre qui referme les plaies d'un fidèle.",
     3, (0, 3), [soin("flamme", 7, 10, "allies")], relance={"par_tour": 1, "delai": 1})
sort("marraine_coup_de_baguette", "Coup de baguette", "Un geste gracieux, une citrouille qui explose.",
     4, (1, 4), [dg("flamme", 6, 8), malus("pa", 1, 1, 1)], zone={"type": "cercle", "taille": 1})
sort("olifant_charge", "Charge d'olifant", "Trois tonnes de bonne humeur, lancées droit sur vous.",
     5, (1, 1), [dg("acier", 9, 13), simple("poussee", 2, 2)])
sort("olifant_barrissement", "Barrissement", "Le cor d'origine. Les oreilles saignent, les jambes flanchent.",
     3, (0, 0), [dg("tempete", 3, 5, "ennemis"), malus("pm", 1, 1, 1, cibles="ennemis")],
     zone={"type": "cercle", "taille": 2}, ldv=False, lanceur_exclu=True, relance={"par_tour": 1, "delai": 1})
sort("olifant_pietinement", "Piétinement", "Il danse. Personne n'a envie d'être son cavalier.",
     5, (0, 0), [dg("acier", 10, 13)], zone={"type": "cercle", "taille": 1}, ldv=False, lanceur_exclu=True)
sort("grondin_coup_de_belier", "Coup de bélier", "Le coup qui a fait trembler la Grande Porte. Vous êtes moins solide qu'une porte.",
     5, (1, 1), [dg("acier", 12, 16), simple("poussee", 2, 2)])
sort("grondin_eclats_de_porte", "Éclats de porte", "Il crache les morceaux des portes qu'il a déjà enfoncées.",
     3, (2, 5), [dg("acier", 4, 6)], zone={"type": "cercle", "taille": 1})
sort("grondin_elan", "Élan", "Les roues grincent, les chaînes claquent : il recule pour mieux frapper.",
     2, (0, 0), [bonus("pm", 2, 2, 1)], ldv=False, relance={"par_tour": 1, "delai": 2})
sort("grondin_souffle_de_forge", "Souffle de forge", "La tête de loup crache le feu de la forge où on l'a coulée.",
     4, (1, 4), [dg("flamme", 8, 11)], zone={"type": "cercle", "taille": 1})

# ---------------- familles ----------------
DETROUSSEUR = famille(
    "detrousseur", "Détrousseur des grands chemins", "Il vole les riches pour donner aux pauvres. Il est pauvre. La boucle est bouclée.",
    (13, 15), "moyen", "standard", 6, 4, 130, {"agilite": 0.5, "chance": 0.5},
    {"tempete": 10, "givre": 5, "acier": 0, "flamme": 0, "sacre": -10},
    ["detrousseur_surin", "detrousseur_la_bourse_ou_la_vie"], "basique",
    [drop("bourse_vide", 0.55, [1, 2]), drop("carte_au_tresor_douteuse", 0.12), drop("capuche_de_detrousseur", 0.04),
     drop("dague_de_detrousseur", 0.03), drop("bottes_de_grand_chemin", 0.04)],
    {"type": "rig", "reutilise": "humain", "nouveau_svg": "accessoire « capuche » (capuche de tissu rabattue sur la tête, 2 vues, couleur {{chapeau}})",
     "manifeste": {"rig": "humain", "couleurs": {"tunique": "3a4a32", "manches": "2e3a28", "pantalon": "3a3028", "bottes": "2e2620", "ceinture": "5a3a22", "cheveux": "2e2418", "chapeau": "2e3a28"},
                   "arme": "epee", "accessoires": ["capuche"]}},
    {"id": "chef_de_bande", "nom": "Chef de bande", "description": "Il se fait appeler « le Prince des voleurs ». Ses hommes l'appellent « le patron » ; sa mère, « Gérard ».",
     "sorts": ["detrousseur_surin", "detrousseur_la_bourse_ou_la_vie", "chef_de_bande_embuscade"],
     "art": {"type": "rig", "reutilise": "humain_grand", "nouveau_svg": None,
             "manifeste": {"rig": "humain_grand", "couleurs": {"tunique": "4a2a3a", "manches": "3a2030", "pantalon": "2a2420", "bottes": "1e1a17", "ceinture": "c9a04e", "cheveux": "1e1a16", "chapeau": "4a2a3a"},
                           "arme": "epee", "accessoires": ["capuche"]}}},
    notes="Humains hors-la-loi (aucun camp) : les routes autour de Hautepierre ne sont pas sûres, quel que soit le camp du joueur.")

TROLL = famille(
    "troll_des_ponts", "Troll des ponts", "Il garde un pont qui ne mène nulle part et réclame un péage que personne ne paie. Il a donc beaucoup de temps libre, et faim.",
    (16, 18), "fort", "tank", 6, 2, 50, {"force": 1},
    {"acier": 25, "givre": 15, "tempete": 0, "flamme": -20, "sacre": -10},
    ["troll_coup_de_massue", "troll_rocher"], "basique",
    [drop("dent_de_troll", 0.55, [1, 2]), drop("recette_de_troll", 0.12), drop("ceinture_de_troll", 0.04),
     drop("anneau_de_nez_de_troll", 0.04), drop("massue_de_troll", 0.03)],
    {"type": "rig", "reutilise": "troll",
     "nouveau_svg": "têtes « tete_troll » et « tete_troll_dos » (grosse tête ronde au nez énorme, petites oreilles pointues, deux crocs du bas, front bas ; peau {{peau}}) pour le nouvel assemblage « troll » (base humain, échelle 1.15) ; arme « massue » (gourdin noueux avec un clou)",
     "manifeste": {"rig": "troll", "couleurs": {"peau": "8a8a6a", "tunique": "6a5030", "manches": "8a8a6a", "pantalon": "5a4630", "bottes": "8a8a6a", "ceinture": "3a2a1a", "cheveux": "4a4a3a"}, "arme": "massue"}},
    {"id": "troll_gastronome", "nom": "Troll gastronome", "description": "Il a lu un livre de cuisine. Un seul. Il l'applique à tout le monde.",
     "sorts": ["troll_coup_de_massue", "troll_rocher", "gastronome_marinade"],
     "art": {"type": "rig", "reutilise": "troll_grand", "nouveau_svg": None,
             "manifeste": {"rig": "troll_grand", "couleurs": {"peau": "7a7a5a", "tunique": "e8e0d0", "manches": "7a7a5a", "pantalon": "4a3a28", "bottes": "7a7a5a", "ceinture": "3a2a1a", "cheveux": "3a3a2a", "tablier": "f2ecdc"},
                           "arme": "massue", "accessoires": ["tablier"]}}},
    notes="Tank lent (2 PM) qui craint la Flamme et le Sacré : les théologues et pyromanes ont l'avantage.")

CORBAC = famille(
    "corbac_espion", "Corbac espion", "Un corbeau au service de la Cendre, avec une longue-vue en bandoulière. Il note tout ce que vous faites, surtout les bêtises.",
    (19, 21), "faible", "tireur", 6, 5, 150, {"agilite": 1},
    {"tempete": 25, "flamme": 5, "givre": 0, "acier": -10}, ["corbac_bec", "corbac_pique"], "distance",
    [drop("plume_de_corbac", 0.55, [1, 3]), drop("message_intercepte", 0.12), drop("chapeau_a_plume_de_corbac", 0.04),
     drop("amulette_oeil_de_corbac", 0.02)],
    {"type": "image", "reutilise": None,
     "nouveau_svg": "monstre/corbac.svgt, ~44×42 px : gros corbeau noir aux reflets bleus ({{pelage}}/{{pelage_ombre}}), ailes à demi déployées, bec épais gris, œil rouge, petite longue-vue en laiton en bandoulière ; perché au sol, ancre entre les pattes.",
     "manifeste": {"image": "corbac", "echelle": 0.9}},
    {"id": "corbac_chef_espion", "nom": "Corbac chef espion", "description": "Il dirige un réseau de quatre cents corbeaux. Il connaît votre adresse, votre taille de chapeau et votre plat préféré.",
     "sorts": ["corbac_bec", "corbac_pique", "chef_espion_rapport"],
     "butin_extra": [drop("cape_de_plumes_noires", 0.15)],
     "art": {"type": "image", "reutilise": "corbac", "nouveau_svg": None, "manifeste": {"image": "corbac", "echelle": 1.15, "teinte": "c0b0d8"}}},
    notes="Tireur rapide (5 PM, IA distance) : il faut le coincer contre les obstacles. Faible à l'Acier.")

GARGOUILLE = famille(
    "gargouille", "Gargouille", "Elle a gardé une gouttière de Hautepierre pendant trois siècles. Depuis que la Cendre tombe, elle garde rancune.",
    (22, 24), "moyen", "costaud", 6, 3, 70, {"force": 0.5, "chance": 0.5},
    {"acier": 30, "flamme": 20, "givre": 10, "tempete": -15}, ["gargouille_griffes", "gargouille_gargouillis"], "basique",
    [drop("eclat_de_gargouille", 0.55, [1, 3]), drop("coeur_de_pierre", 0.12), drop("anneau_de_granit", 0.04),
     drop("bottes_de_gargouille", 0.03), drop("hallebarde_de_la_vieille_garde", 0.03)],
    {"type": "image", "reutilise": None,
     "nouveau_svg": "monstre/gargouille.svgt, ~54×60 px : gargouille de pierre grise ({{pierre}}) accroupie, petites ailes de chauve-souris repliées, cornes courtes, gueule grande ouverte en gouttière, griffes ; taches de mousse ; ancre aux pieds.",
     "manifeste": {"image": "gargouille", "echelle": 0.9}},
    {"id": "gargouille_de_la_grande_porte", "nom": "Gargouille de la Grande Porte", "description": "La plus vieille de la ville. Elle a vu passer trois rois, deux sièges et un nombre incalculable de pigeons.",
     "sorts": ["gargouille_griffes", "gargouille_gargouillis", "gargouille_petrification"],
     "butin_extra": [drop("amulette_coeur_de_pierre", 0.15)],
     "art": {"type": "image", "reutilise": "gargouille", "nouveau_svg": None, "manifeste": {"image": "gargouille", "echelle": 1.15, "teinte": "d8d0c0"}}},
    notes="Très résistante à l'Acier et à la Flamme, faible à la Tempête : la famille qui oblige les guerriers à varier.")

CENDRILLON = famille(
    "cendrillon", "Cendrillon", "Adepte du Souverain Cendré. Ils dansent dans la cendre et doivent rentrer avant minuit, sinon ils redeviennent des gens normaux.",
    (25, 27), "moyen", "soutien", 6, 3, 110, {"intelligence": 1},
    {"flamme": 30, "impie": 15, "acier": 0, "givre": -20, "sacre": -15},
    ["cendrillon_cendres_ardentes", "cendrillon_bal_de_minuit"], "soutien",
    [drop("cendre_tiede", 0.55, [1, 3]), drop("invitation_au_bal", 0.12), drop("pantoufles_de_cendre", 0.03),
     drop("masque_de_cendrillon", 0.04), drop("baguette_de_cendrillon", 0.03), drop("bague_de_minuit", 0.03)],
    {"type": "rig", "reutilise": "humain", "nouveau_svg": None,
     "manifeste": {"rig": "humain", "couleurs": {"peau": "d8c8c0", "tunique": "3a302c", "manches": "2a2420", "pantalon": "1e1a17", "bottes": "141110", "ceinture": "8a2a1a", "cheveux": "8a8a8a"},
                   "arme": "sceptre", "accessoires": ["cape_cendre"]}},
    {"id": "marraine_cendree", "nom": "Marraine Cendrée", "description": "Elle exauce les vœux. Le vôtre était de rentrer chez vous ; elle l'a mal compris.",
     "sorts": ["cendrillon_cendres_ardentes", "cendrillon_bal_de_minuit", "marraine_coup_de_baguette"],
     "art": {"type": "rig", "reutilise": "humain_grand", "nouveau_svg": None,
             "manifeste": {"rig": "humain_grand", "couleurs": {"peau": "e0d0c8", "tunique": "5a4a6a", "manches": "3a2e4a", "pantalon": "2a2236", "bottes": "141110", "ceinture": "c9a04e", "cheveux": "e8e8e8", "etole": "c9a04e"},
                           "arme": "sceptre", "accessoires": ["cape_cendre", "etole"]}}},
    notes="IA soutien : soigne les autres Cendrillons et les olifants qu'ils accompagnent. Faibles au Givre et au Sacré.")

OLIFANT = famille(
    "olifant_de_guerre", "Olifant de guerre", "Trois tonnes, quatre défenses, et un caparaçon rouge brodé « Armée du Souverain ». Il ne sait pas lire, heureusement pour lui.",
    (28, 30), "fort", "tank", 7, 3, 60, {"force": 1},
    {"acier": 30, "tempete": 20, "flamme": 10, "givre": -15}, ["olifant_charge", "olifant_barrissement"], "basique",
    [drop("cuir_d_olifant", 0.55, [1, 2]), drop("ivoire_d_olifant", 0.12), drop("cape_en_cuir_d_olifant", 0.04),
     drop("semelles_d_olifant", 0.03), drop("cor_d_olifant", 0.015)],
    {"type": "image", "reutilise": None,
     "nouveau_svg": "monstre/olifant.svgt, ~86×70 px : éléphant de guerre gris ({{pelage}}/{{pelage_ombre}}) vu de 3/4, quatre défenses, grandes oreilles, caparaçon rouge à bordure dorée sur le dos, petite tête de mort cendrée brodée ; ancre entre les pattes.",
     "manifeste": {"image": "olifant", "echelle": 0.9}},
    {"id": "olifant_a_tour", "nom": "Olifant-tour", "niveau": 33, "description": "Un olifant qui porte une tour sur le dos. Dans la tour, personne. Il l'a gardée par habitude.",
     "sorts": ["olifant_charge", "olifant_barrissement", "olifant_pietinement"],
     "art": {"type": "image", "reutilise": "olifant", "nouveau_svg": None, "manifeste": {"image": "olifant", "echelle": 1.12, "teinte": "c8b8a8"}}},
    notes="Le monstre normal le plus solide de l'alpha. Ses groupes viennent avec des Cendrillons qui le soignent.")

GRONDIN = {
    "id": "grondin", "nom": "Grondin, Bélier de la Brèche",
    "description": "Un bélier de siège à tête de loup, forgé dans les Marches Cendrées. Il avance tout seul. Personne ne veut savoir comment.",
    "boss": True, "niveau": 30,
    "caracteristiques": {"pv": 600, "pa": 8, "pm": 2, "initiative": 80, "force": 40},
    "resistances": {"acier": 35, "flamme": 25, "tempete": 10, "givre": -20, "sacre": -10},
    "sorts": ["grondin_coup_de_belier", "grondin_eclats_de_porte", "grondin_elan"],
    "ia": "basique", "xp": 3600,
    "phases": [
        {"pv": 75, "message": "« Grondin ! Grondin ! » scandent des voix dans la cendre. Le bélier prend de l'élan.",
         "effets": [bonus("force", 30, 30, 3)]},
        {"pv": 50, "message": "La tête de loup du bélier s'embrase. Les chaînes rougissent.",
         "sorts": ["grondin_souffle_de_forge"], "effets": [bouclier("acier", 80, 80)]},
        {"pv": 20, "message": "« Trois coups ! On frappe toujours trois coups ! »",
         "effets": [simple("gain_pa", 3, 3), bonus("dommages", 8, 8, 2)]}],
    "butin": [drop("eclat_de_cendre", 1.0, [1, 2]), drop("heaume_du_belier", 0.15), drop("anneau_du_gond", 0.15),
              drop("marteau_de_grondin", 0.06)],
    "ecus": [300, 500]}


def C(id, nom, x, y, sorties, palier, ambiance, elements, ressources, groupes, pnj=None, **kw):
    d = {"id": id, "existante": False, "nom": nom, "x": x, "y": y, "sorties": sorties, "palier": palier,
         "ambiance": ambiance, "elements": elements, "ressources": ressources, "groupes": groupes, "pnj": pnj or [],
         "pierre": False, "boss": False}
    d.update(kw)
    return d


def P(m, id, nom, role, repliques, art, **kw):
    d = {"marqueur": m, "id": id, "nom": nom, "role": role, "repliques": repliques, "art": art}
    d.update(kw)
    return d


VILLE = (
    "Hautepierre est la cité des humains bâtie sur un éperon rocheux blanc : remparts, Tour Blanche, Arbre Blanc (mort depuis deux siècles, repeint chaque printemps), "
    "et une administration qui délivre des laissez-passer à ceux qui ont déjà un laissez-passer. Terrain commun des trois camps : à l'acte II, les gardes "
    "tolèrent gobelins et elfes « en visite » (plus tard : gardes hostiles avant l'acte III, voir TODO) ; à l'acte III, la salle du Conseil des Peuples Libres s'ouvre dans la Citadelle.\n\n"
    "- **4 cartes de ville**, palette `hautepierre` (herbe tirant vers le gris-vert des pavés, murs clairs), sans monstres : la Grand-Place (Pierre de Passage, marchande, forgeron, auberge), "
    "la Citadelle de la Tour Blanche (PNJ de l'histoire), la Porte de l'Ouest (temple) et la Porte de l'Est (vers les terres cendrées).\n"
    "- **Remparts** : lignes de murs (M) sur les bords des cartes de ville, percées aux sorties ; chaque Porte a un passage de 3 cases encadré de deux tours (décor `tour_de_garde`).\n"
    "- **Nouveaux décors** (3×3 sauf mention) : `tour_blanche` (tour haute, toit d'ardoise bleue, bannière à tour blanche ; emprise 3×3 mais dessinée haute), `temple` (fronton, colonnes, soleil doré), "
    "`tour_de_garde`, et en 1×1 `fontaine` (bassin rond, statue d'un héros dont personne ne se rappelle le nom), `etal` (étal de marché à toile rayée), `poteau_indicateur` (pour les passages entre zones, voir § 2).\n"
    "- **Pierre de Passage** `hautepierre` sur la Grand-Place, **20 écus** (plus loin que les zones de départ), à découvrir.\n"
    "- Pas de maison du joueur à Hautepierre pour l'alpha (on garde celle de sa zone de départ ; la Pierre y ramène).")

ZONE = {
    "id": "hautepierre", "nom": "Hautepierre et ses environs", "palette": "hautepierre", "camp": "commun",
    "pierre": {"id": "hautepierre", "carte": "hautepierre_2_2", "prix": 20, "existante": False,
               "json": {"id": "hautepierre", "nom": "Hautepierre", "carte": "hautepierre_2_2", "prix": 20}},
    "plan_zone": [
        "            x=0                    x=1                       x=2                        x=3                        x=4",
        "                                                      +══ Sylvebrume 2_2",
        "y=0                         [Bois-Corbeau 19-21] ── [Route du Nord 13-15] ── [Colline Pelée 19-21 ✦]",
        "                                   │                        │                          │",
        "y=1                         [Vigie aux Corbacs 19-21] ─ (Citadelle) ──────── [Ruines Vieille Garde 22-24] ── [Cimetière des Gargouilles 22-24]",
        "                                   │                        │                          │                          │",
        "y=2  [Route de l'Ouest 13-15] ── (Porte de l'Ouest) ─── (Grand-Place *) ───── (Porte de l'Est) ──────── [Route de l'Est 13-15 ✦]",
        " Brumerive 3_1 ══+                 │                        │                          │                          │ +══ Crasse-Roc 0_2",
        "y=3                         [Rives du Fleuve Gris 16-18] ─ [Pont des Trolls 16-18] ─ [Camp des Cendrillons 25-27 ✦] ─ [Plaine Cendrée 25-27 ✦]",
        "                                                            │                          │                          │",
        "y=4                                                  [Gorges du Troll 16-18 ✦] ─ [Champs du Pèle-Ennemi 28-30 ✦] ─ [La Brèche ☠ 30 ✦]",
        "",
        "( ) = ville, sans monstres ; ✦ = carte cendrée (« cendree »: true, variantes Corrompues possibles)"],
    "cartes": [
        # ---- ville ----
        C("hautepierre_2_2", "Hautepierre — Grand-Place", 2, 2,
          {"gauche": "hautepierre_1_2", "droite": "hautepierre_3_2", "haut": "hautepierre_2_1", "bas": "hautepierre_2_3"}, "ville",
          "Le cœur de la cité : pavés, fontaine, étals, l'auberge Au Heaume Fendu et la Pierre de Passage au milieu.",
          "Grande place dégagée en chemins (:) qui figurent les pavés ; fontaine (1×1) au centre et Pierre « * » juste au sud ; auberge (décor « auberge ») en haut-gauche, forge (décor « maison ») en haut-droite, 4 étals (1×1) ; murs (M) de façades le long des bords sauf aux 4 sorties (3 cases chacune).",
          {}, [],
          [P("a", "clairon_crieur_public", "Clairon, crieur public", "PNJ d'ambiance (nouvelles de la guerre)",
             ["Oyez, oyez ! La cendre tombe à l'est ! Le Conseil se réunira dès qu'il aura fini de se réunir pour décider quand se réunir !",
              "Oyez ! Un bélier géant aurait été vu près de la Brèche ! On recommande aux citoyens de ne pas être une porte !",
              "Oyez ! Les gobelins sont autorisés en ville, à condition de ne rien toucher. Les elfes aussi, à condition de ne rien critiquer. Bonne chance à tous."],
             {"rig": "humain", "couleurs": {"tunique": "4a6a9a", "manches": "e8e0c8", "pantalon": "3a3a4a", "cheveux": "c9783a", "ceinture": "c9a04e"}, "accessoires": ["chapeau_paille"]}),
           P("b", "rosemonde_beurrefondu", "Rosemonde Beurrefondu, marchande", "Marchande (maison mère du Poney Essoufflé)",
             ["Bienvenue au Poney Essoufflé, la maison mère ! Mon neveu Barlimon tient la succursale de Brumerive. Il vous a parlé de moi ? Il parle trop."],
             {"rig": "humain", "couleurs": {"tunique": "8a3a5a", "manches": "e2d4b0", "pantalon": "5a4632", "cheveux": "d8d0c0", "tablier": "f2ecdc"}, "accessoires": ["tablier"]}, marchand=True),
           P("c", "gontran_batenclume", "Gontran Batenclume, forgeron de la Garde", "Atelier forgeron",
             ["Je forge pour la Garde depuis trente ans. Épées, heaumes, et surtout des laissez-passer en fer : ça ne se perd pas."],
             {"rig": "humain", "couleurs": {"tunique": "4e4e58", "manches": "3e3e46", "pantalon": "3a3028", "cheveux": "8a8478", "barbe": "8a8478", "tablier": "6b4a2b"}, "accessoires": ["tablier", "barbe"]}, atelier="forgeron"),
           P("d", "maitre_ripaille", "Maître Ripaille, aubergiste", "PNJ d'ambiance (rumeurs)",
             ["Au Heaume Fendu, on sert la meilleure bière de Hautepierre. Et la seule, depuis que les trolls ont bloqué le pont des brasseurs.",
              "Un conseil : ne commandez jamais la « spécialité du troll ». C'est le troll qui la commande.",
              "Les Cendrillons ? Ils viennent boire ici avant minuit. Après, ils ne payent plus : ils ont oublié qui ils sont."],
             {"rig": "humain", "couleurs": {"tunique": "c9a04e", "manches": "e2d4b0", "pantalon": "5a4632", "cheveux": "5a3a22", "tablier": "f2ecdc"}, "accessoires": ["tablier"]})],
          pierre=True, palette="hautepierre", decors=["auberge", "maison (forge)", "fontaine", "etal ×4"]),
        C("hautepierre_2_1", "Hautepierre — Citadelle de la Tour Blanche", 2, 1,
          {"haut": "hautepierre_2_0", "bas": "hautepierre_2_2", "gauche": "hautepierre_1_1", "droite": "hautepierre_3_1"}, "ville",
          "La haute ville : la Tour Blanche, l'Arbre Blanc (mort, repeint), les PNJ de l'histoire et la future salle du Conseil.",
          "Cour d'honneur dégagée ; Tour Blanche (décor « tour_blanche ») au centre-haut, Arbre Blanc (décor « arbre_mort » sur une case #) devant ; deux décors « maison » (salle du Conseil, archives) ; murs (M) d'enceinte avec les 4 ouvertures.",
          {}, [],
          [P("a", "intendant_gaspard", "Gaspard le Sobre, Intendant de Hautepierre", "PNJ de l'histoire (acte II humain)",
             ["Le roi ? Il reviendra. En attendant, c'est moi qui gouverne, et qui mange les tomates cerises. Une par décision.",
              "La Cendre ? Une rumeur. Les gobelins ? Une nuisance. Les elfes ? Une opinion. Hautepierre tiendra.",
              "Si vous voulez vous rendre utile, allez voir le capitaine. Il adore les volontaires : ils coûtent moins cher."],
             {"rig": "humain", "couleurs": {"tunique": "2a2a3a", "manches": "4a4a5a", "pantalon": "1e1e26", "cheveux": "a8a29a", "ceinture": "c9a04e"}}),
           P("b", "capitaine_aldebert", "Capitaine Aldebert", "PNJ de l'histoire (garde)",
             ["On n'entre pas comme ça dans les Marches Cendrées. Il faut d'abord remplir le formulaire B-12. En trois exemplaires.",
              "Un bélier de siège géant rôde à la Brèche, à l'est. Si vous êtes assez fou pour y aller, prenez au moins un casque.",
              "Les trolls bloquent le pont du sud. Les corbacs nous espionnent au nord. Et l'Intendant compte ses tomates."],
             {"rig": "humain", "couleurs": {"tunique": "2e4a7a", "manches": "a8aeb6", "pantalon": "2a2a36", "bottes": "1e1a17", "ceinture": "e0b860", "cheveux": "5a3a22"}, "arme": "epee", "accessoires": ["casque"]}),
           P("c", "archiviste_petronille", "Pétronille, archiviste", "PNJ de lore (Reliques)",
             ["Huit Reliques de l'Aube, huit bagues. La nôtre, la Chevalière Sans-Rouille, a disparu il y a trois siècles. On a gardé l'écrin. Il est très beau.",
              "D'après les archives, chaque Relique est portée par un Héraut Cendré. D'après les mêmes archives, les Hérauts n'existent pas. Je vais devoir réécrire les archives.",
              "Ne touchez pas aux parchemins du fond. Ce sont des factures de l'Âge de l'Aube. Toujours impayées."],
             {"rig": "humain", "couleurs": {"tunique": "6a4a2a", "manches": "8a6a4a", "pantalon": "3a3028", "cheveux": "c8c0b0", "etole": "c9a04e"}, "accessoires": ["etole"]}),
           P("d", "snagrod_delegue", "Snagrod, délégué syndical gobelin", "PNJ de l'histoire (acte III en germe)",
             ["J'attends dans l'antichambre depuis trois semaines. On m'a promis un siège au Conseil. Pour l'instant, j'ai un tabouret.",
              "Les gobelins veulent trois choses : des chaises, des pauses, et ne plus être sacrifiés en premier. Dans cet ordre.",
              "Si le Conseil se forme un jour, je réclamerai la présidence. On ne sait jamais, ça peut marcher."],
             {"rig": "gobelin", "couleurs": {"peau": "7c9a48", "tunique": "8a2a1a", "manches": "6e2e22", "pantalon": "3e3226", "cheveux": "2a2018", "ceinture": "c9a04e"}}),
           P("e", "ilyndra_tel_hautaine", "Ilyndra Tel'Hautaine, ambassadrice elfe", "PNJ de l'histoire (acte II elfe)",
             ["Je suis ici en observatrice. J'observe. C'est très humain, tout ça. Très bruyant.",
              "Le Conseil de la Lisière m'a envoyée pour décider s'il fallait envoyer quelqu'un. J'ai décidé que oui. On m'a donc envoyée.",
              "La Cendre touche nos arbres. Ce n'est plus seulement votre guerre. Ne le répétez pas."],
             {"rig": "humain", "couleurs": {"peau": "f3dcc4", "tunique": "c9d4e0", "manches": "9fb4c8", "pantalon": "5a6a7a", "cheveux": "f0e6c0", "ceinture": "c9a04e"}, "accessoires": ["oreilles_elfe", "etole"]})],
          palette="hautepierre", decors=["tour_blanche", "arbre_mort (Arbre Blanc)", "maison ×2"]),
        C("hautepierre_1_2", "Hautepierre — Porte de l'Ouest", 1, 2,
          {"gauche": "hautepierre_0_2", "droite": "hautepierre_2_2", "haut": "hautepierre_1_1", "bas": "hautepierre_1_3"}, "ville",
          "La porte des routes de l'ouest (vers Brumerive) et le temple de la cité.",
          "Rempart (M) sur le bord gauche percé d'une porte de 3 cases entre deux « tour_de_garde » ; temple (décor « temple ») au centre-haut ; ruelles en chemins (:) ; quelques maisons (décor « maison »).",
          {}, [],
          [P("a", "sergent_mordicus", "Sergent Mordicus", "Garde de la porte",
             ["Halte ! Laissez-passer ? … Pas de laissez-passer ? … Bon, passez, mais je vous ai à l'œil.",
              "À l'ouest, la route de Brumerive. Pleine de détrousseurs. Ils volent tout, sauf les laissez-passer : ça, ils n'en veulent pas."],
             {"rig": "humain", "couleurs": {"tunique": "4a6a9a", "manches": "8a8f96", "pantalon": "3a3a4a", "bottes": "2e2620", "ceinture": "c9a04e", "cheveux": "2e2418"}, "arme": "epee", "accessoires": ["casque"]}),
           P("b", "frere_benitier", "Frère Bénitier, prêtre", "PNJ d'ambiance (Théologues)",
             ["J'ai béni la Masse bénite trois fois : le manche, la tête… et mon pouce. Il guérit très bien, merci.",
              "Le Sacré, c'est la Force et l'Intelligence réunies. Comme moi. Enfin, comme moi les bons jours.",
              "Les trolls craignent la lumière. Les Cendrillons aussi. Moi, je crains les trolls. Tout le monde craint quelque chose."],
             {"rig": "humain", "couleurs": {"tunique": "ece4cc", "manches": "d8cfb4", "pantalon": "cfc4a6", "cheveux": "8a6a3a", "etole": "c9a04e"}, "arme": "sceptre", "accessoires": ["etole"]}),
           P("c", "fulbert_l_authentique", "Fulbert l'Authentique, colporteur", "PNJ d'ambiance (humour)",
             ["Véritable Relique de l'Aube ! Garantie d'origine ! Enfin, garantie… d'origine. D'une origine.",
              "Celle-ci, c'est l'Anneau-Lanterne ! Il éclaire ! Si on le met près d'une bougie.",
              "Je ne vends rien aujourd'hui, la Garde m'a confisqué le stock. Mais je reprends les commandes."],
             {"rig": "humain", "couleurs": {"tunique": "8a6a2a", "manches": "6a4a1a", "pantalon": "4a3a28", "cheveux": "3a2a1a"}, "accessoires": ["chapeau_paille"]})],
          palette="hautepierre", decors=["temple", "tour_de_garde ×2", "maison ×2"]),
        C("hautepierre_3_2", "Hautepierre — Porte de l'Est", 3, 2,
          {"gauche": "hautepierre_2_2", "droite": "hautepierre_4_2", "haut": "hautepierre_3_1", "bas": "hautepierre_3_3"}, "ville",
          "La porte qui regarde vers l'est et la Cendre : réfugiés, barricades, gardes nerveux.",
          "Rempart (M) sur le bord droit percé d'une porte de 3 cases entre deux « tour_de_garde » ; barricades (R) ; tentes de réfugiés (décor « cabane ») ; un peu de cendre au sol (taches de palette).",
          {}, [],
          [P("a", "sergente_brisetout", "Sergente Brisetout", "Garde de la porte",
             ["À l'est, la Route des Charrois vers Crasse-Roc, et la Brèche. Au sud-est, les terres cendrées. Je déconseille les deux.",
              "Des gobelins arrivent par la Route de l'Est. Ils disent qu'ils fuient. Ils fuient quoi ? Ils ne savent pas l'expliquer. Ça m'inquiète."],
             {"rig": "humain", "couleurs": {"tunique": "4a6a9a", "manches": "8a8f96", "pantalon": "3a3a4a", "bottes": "2e2620", "ceinture": "c9a04e", "cheveux": "8a3a1a"}, "arme": "epee", "accessoires": ["casque"]}),
           P("b", "melisande_la_refugiee", "Mélisande, réfugiée", "PNJ d'ambiance (acte II)",
             ["Ma ferme était dans la plaine, à l'est. Maintenant, c'est une plaine de cendre. Et une ferme de cendre.",
              "Il y avait des gens en noir qui dansaient dans la cendre en riant. À minuit, ils se sont arrêtés et ont pleuré. Je n'ai pas compris."],
             {"rig": "humain", "couleurs": {"tunique": "7a7a6a", "manches": "6a6a5a", "pantalon": "5a5a4a", "cheveux": "6a4a2a"}})],
          palette="hautepierre", decors=["tour_de_garde ×2", "cabane ×2"]),
        # ---- 13-15 ----
        C("hautepierre_0_2", "Hautepierre — Route de l'Ouest", 0, 2, {"droite": "hautepierre_1_2"}, "13-15",
          "La grand-route qui monte de Brumerive : bornes, auberge en ruine, détrousseurs embusqués dans les fossés.",
          "Route (:) de 2 cases de large de la gauche à la droite, bordée de haies (A) et de fossés (E étroits) ; auberge en ruine (décor « maison ») ; au bord gauche, le passage « + » (porte vers brumerive_3_1) avec un « poteau_indicateur ».",
          {"C": 2, "Y": 2, "T": 1},
          [{"monstres": ["detrousseur"]}, {"monstres": ["detrousseur", "detrousseur"]}, {"parmi": ["detrousseur"], "nombre": [2, 3]}],
          portes=["brumerive_3_1"],
          passage_inter_zone="Porte « + » sur le bord gauche vers brumerive_3_1 (réciproque ajoutée sur le Gué de Brume-Haute par ce lot)."),
        C("hautepierre_2_0", "Hautepierre — Route du Nord", 2, 0,
          {"bas": "hautepierre_2_1", "gauche": "hautepierre_1_0", "droite": "hautepierre_3_0"}, "13-15",
          "La route qui descend de la Lisière : champs de blé, moulins, pèlerins perdus.",
          "Route (:) du haut vers le bas ; passage « + » sur le bord haut (porte vers sylvebrume_2_2) avec « poteau_indicateur » ; champs (zones dégagées) et bosquets (A) ; un moulin (décor « maison ») à droite.",
          {"F": 2, "C": 2, "Y": 1},
          [{"monstres": ["detrousseur", "detrousseur"]}, {"monstres": ["detrousseur"]}, {"parmi": ["detrousseur"], "nombre": [1, 3]}],
          [P("a", "pelerin_egare", "Anselme, pèlerin égaré", "PNJ d'ambiance",
             ["Je cherche le chemin de Hautepierre. … C'est en bas ? Depuis tout ce temps ? Je tournais autour.",
              "Les détrousseurs m'ont tout pris. Sauf ma foi. Ils l'ont regardée, et ils l'ont reposée."],
             {"rig": "humain", "couleurs": {"tunique": "8a7a5a", "manches": "7a6a4a", "pantalon": "5a4a3a", "cheveux": "a8a29a"}, "arme": "baton"})],
          portes=["sylvebrume_2_2"],
          passage_inter_zone="Porte « + » sur le bord haut vers sylvebrume_2_2 (réciproque ajoutée sur l'Orée du Sud par ce lot)."),
        C("hautepierre_4_2", "Hautepierre — Route de l'Est", 4, 2,
          {"gauche": "hautepierre_3_2", "haut": "hautepierre_4_1", "bas": "hautepierre_4_3"}, "13-15",
          "La route des charrois qui arrive des montagnes gobelines ; la cendre commence à griser les talus.",
          "Carte cendrée (palette `cendree`). Route (:) de la droite vers la gauche ; passage « + » sur le bord droit (porte vers crasse_roc_0_2) avec « poteau_indicateur » ; charrettes abandonnées (R) ; arbres grisés (A).",
          {"I": 2, "T": 2, "C": 1},
          [{"monstres": ["detrousseur", "detrousseur"]}, {"parmi": ["loup_cendreux"], "nombre": [1, 2]},
           {"monstres": ["detrousseur", "loup_cendreux"]}, {"monstres": ["detrousseur"]}],
          [P("a", "caravanier_brokk", "Brokk, caravanier gobelin", "PNJ d'ambiance (acte II gobelin)",
             ["On transporte du minerai pour le Souverain. Enfin, on transportait. Le Souverain a fait brûler la dernière caravane « pour l'exemple ».",
              "L'exemple de quoi ? Personne n'a su me dire. Alors je fais une pause. Une longue."],
             {"rig": "gobelin", "couleurs": {"peau": "7a9a42", "tunique": "6a5a3a", "manches": "5a4a30", "pantalon": "3e3226", "cheveux": "2a2018"}, "accessoires": ["chapeau_paille"]})],
          portes=["crasse_roc_0_2"], cendree=True, palette="cendree",
          passage_inter_zone="Porte « + » sur le bord droit vers crasse_roc_0_2 (réciproque ajoutée sur la Route des Charrois par ce lot)."),
        # ---- 16-18 ----
        C("hautepierre_1_3", "Hautepierre — Rives du Fleuve Gris", 1, 3, {"haut": "hautepierre_1_2", "droite": "hautepierre_2_3"}, "16-18",
          "Le fleuve qui coule au pied de la cité ; lavoirs abandonnés, barques échouées, et des trolls qui pêchent à mains nues.",
          "Fleuve (E) large sur le bas de la carte, berge praticable de 4 à 6 lignes ; lavoir (décor « cabane ») ; roseaux (A bas) ; un ponton.",
          {"H": 2, "Y": 1, "G": 1},
          [{"monstres": ["troll_des_ponts"]}, {"monstres": ["troll_des_ponts", "troll_des_ponts"]}, {"monstres": ["troll_des_ponts", "detrousseur"]}],
          [P("a", "passeur_caron", "Caron, passeur", "PNJ d'ambiance",
             ["Un écu l'aller, deux le retour. Le pont des trolls ? Gratuit. Enfin, ça dépend pour qui.",
              "Les trolls ne savent pas nager. Moi non plus. On a ça en commun, on en parle parfois."],
             {"rig": "humain", "couleurs": {"tunique": "3a3a3a", "manches": "2a2a2a", "pantalon": "2a2a2a", "cheveux": "e8e8e8", "barbe": "e8e8e8"}, "arme": "baton", "accessoires": ["barbe"]})]),
        C("hautepierre_2_3", "Hautepierre — Pont des Trolls", 2, 3,
          {"haut": "hautepierre_2_2", "gauche": "hautepierre_1_3", "bas": "hautepierre_2_4", "droite": "hautepierre_3_3"}, "16-18",
          "Le vieux pont de pierre au sud de la cité, squatté par une famille de trolls qui réclame un péage en nature.",
          "Fleuve (E) horizontal au milieu de la carte, pont de pierre de 3 cases de large du haut vers le bas ; piles du pont (R) ; berges dégagées des deux côtés ; un feu de camp de troll (R) sous le pont.",
          {"H": 2, "G": 2},
          [{"monstres": ["troll_des_ponts"]}, {"monstres": ["troll_des_ponts", "troll_des_ponts"]},
           {"parmi": ["troll_des_ponts", "grouilleur_de_braise"], "nombre": [2, 3]}, {"monstres": ["troll_des_ponts"]}]),
        C("hautepierre_2_4", "Hautepierre — Gorges du Troll", 2, 4, {"haut": "hautepierre_2_3", "droite": "hautepierre_3_4"}, "16-18",
          "Des gorges encaissées où la cendre s'accumule ; les grouilleurs venus des mines y ont muté en grouilleurs de braise.",
          "Carte cendrée (palette `cendree`). Falaises (R) sur les bords, défilé central de 4 à 6 cases ; éboulis (R) ; petit torrent (E) qui serpente.",
          {"G": 2, "H": 1, "T": 1},
          [{"parmi": ["grouilleur_de_braise"], "nombre": [1, 3]}, {"monstres": ["troll_des_ponts", "grouilleur_de_braise"]},
           {"monstres": ["troll_des_ponts", "troll_des_ponts"]}],
          cendree=True, palette="cendree"),
        # ---- 19-21 ----
        C("hautepierre_1_0", "Hautepierre — Bois-Corbeau", 1, 0, {"droite": "hautepierre_2_0", "bas": "hautepierre_1_1"}, "19-21",
          "Un bois sombre aux arbres noirs où nichent les corbacs espions du Souverain ; on se sent observé, et on l'est.",
          "Arbres (A) serrés, troncs morts (arbre_mort via la palette ou A), clairières reliées ; nids (R) au pied des arbres ; aucun chemin tracé.",
          {"H": 2, "Y": 2},
          [{"monstres": ["corbac_espion", "corbac_espion"]}, {"monstres": ["corbac_espion"]},
           {"parmi": ["corbac_espion"], "nombre": [2, 3]}, {"monstres": ["corbac_espion", "arbre_calcine"]}]),
        C("hautepierre_1_1", "Hautepierre — Vigie aux Corbacs", 1, 1,
          {"haut": "hautepierre_1_0", "droite": "hautepierre_2_1", "bas": "hautepierre_1_2"}, "19-21",
          "Une ancienne tour de vigie de la cité, abandonnée, dont les corbacs ont fait leur quartier général.",
          "Tour en ruine (décor « tour_de_garde ») au centre ; murets écroulés (M bas) en cercle ; prairie autour ; pigeonnier (décor « cabane »).",
          {"H": 1, "G": 2},
          [{"monstres": ["corbac_espion"]}, {"monstres": ["corbac_espion", "corbac_espion"]}, {"parmi": ["corbac_espion", "troll_des_ponts"], "nombre": [2, 3]}]),
        C("hautepierre_3_0", "Hautepierre — Colline Pelée", 3, 0, {"gauche": "hautepierre_2_0", "bas": "hautepierre_3_1"}, "19-21",
          "Une colline brûlée par la première pluie de cendre ; les arbres y sont devenus des arbres calcinés qui marchent.",
          "Carte cendrée (palette `cendree`). Colline : anneaux de rochers (R) en terrasses ; arbres morts (A) ; cratères de cendre (taches) ; vue dégagée au sommet.",
          {"H": 1, "G": 1, "L": 1},
          [{"parmi": ["arbre_calcine"], "nombre": [1, 2]}, {"monstres": ["arbre_calcine", "corbac_espion"]},
           {"monstres": ["corbac_espion", "corbac_espion"]}],
          cendree=True, palette="cendree"),
        # ---- 22-24 ----
        C("hautepierre_3_1", "Hautepierre — Ruines de la Vieille Garde", 3, 1,
          {"haut": "hautepierre_3_0", "gauche": "hautepierre_2_1", "droite": "hautepierre_4_1", "bas": "hautepierre_3_2"}, "22-24",
          "Les ruines de l'ancienne enceinte, trois siècles plus vieille que la cité actuelle ; les gargouilles des anciens toits s'y sont réveillées.",
          "Pans de murs (M) en ruine formant des salles ouvertes ; colonnes (R) ; dalles (chemins :) ; une porte monumentale effondrée au centre.",
          {"G": 2, "L": 1, "D": 1},
          [{"monstres": ["gargouille"]}, {"monstres": ["gargouille", "gargouille"]}, {"parmi": ["gargouille", "corbac_espion"], "nombre": [2, 3]}],
          [P("a", "capitaine_perenne", "Capitaine Pérenne (fantôme)", "PNJ d'ambiance",
             ["Garde, à vos postes ! … Ah. Pardon. Je suis de garde depuis trois cents ans. On a oublié de me relever.",
              "Les gargouilles ? Elles gardaient les gouttières de mon temps. La Cendre les a réveillées. Elles gardent encore, mais contre tout le monde."],
             {"rig": "humain", "couleurs": {"peau": "c8d8e8", "tunique": "8aa0c0", "manches": "a8b8d0", "pantalon": "6a80a0", "bottes": "5a6a8a", "cheveux": "e8f0f8", "ceinture": "a8b8d0"}, "arme": "epee", "accessoires": ["casque"]})]),
        C("hautepierre_4_1", "Hautepierre — Cimetière des Gargouilles", 4, 1, {"gauche": "hautepierre_3_1", "bas": "hautepierre_4_2"}, "22-24",
          "Le cimetière où l'on entassait les gargouilles cassées des toits de la ville. Elles n'ont pas aimé.",
          "Tombes et statues (R) en rangées ; caveau (décor « temple » recoloré ou « maison ») ; allées (:) ; un if noir (Y) dans un coin.",
          {"G": 1, "L": 1, "D": 1},
          [{"monstres": ["gargouille", "gargouille"]}, {"monstres": ["gargouille"]}, {"parmi": ["gargouille"], "nombre": [2, 3]}]),
        # ---- 25-27 ----
        C("hautepierre_3_3", "Hautepierre — Camp des Cendrillons", 3, 3,
          {"haut": "hautepierre_3_2", "gauche": "hautepierre_2_3", "droite": "hautepierre_4_3", "bas": "hautepierre_3_4"}, "25-27",
          "Le campement des adeptes de la Cendre, aux portes de la ville : tentes noires, piste de danse cendrée, horloge arrêtée à minuit moins cinq.",
          "Carte cendrée (palette `cendree`). Tentes (décor « cabane » ×2) ; cercle de danse dégagé au centre (7×7) entouré de braseros (R) ; horloge (décor « tour_de_garde ») en haut.",
          {"L": 1, "D": 2},
          [{"monstres": ["cendrillon"]}, {"monstres": ["cendrillon", "cendrillon"]}, {"parmi": ["cendrillon", "gargouille"], "nombre": [2, 3]},
           {"monstres": ["cendrillon", "olifant_de_guerre"]}],
          cendree=True, palette="cendree"),
        C("hautepierre_4_3", "Hautepierre — Plaine Cendrée", 4, 3, {"haut": "hautepierre_4_2", "gauche": "hautepierre_3_3", "bas": "hautepierre_4_4"}, "25-27",
          "Une plaine agricole recouverte de cendre ; des fermes vides, des épouvantails noirs, des Cendrillons qui y valsent.",
          "Carte cendrée (palette `cendree`). Terrain ouvert, champs grisés, fermes (décor « maison ») abandonnées, clôtures (murets) ; peu d'obstacles (les olifants ont de la place).",
          {"L": 2, "D": 1, "G": 1},
          [{"monstres": ["cendrillon", "cendrillon"]}, {"monstres": ["cendrillon"]}, {"parmi": ["cendrillon"], "nombre": [2, 3]}],
          cendree=True, palette="cendree"),
        # ---- 28-30 ----
        C("hautepierre_3_4", "Hautepierre — Champs du Pèle-Ennemi", 3, 4,
          {"haut": "hautepierre_3_3", "gauche": "hautepierre_2_4", "droite": "hautepierre_4_4"}, "28-30",
          "Le grand champ de bataille au sud-est de la cité, où l'armée du Souverain masse ses olifants avant l'assaut.",
          "Carte cendrée (palette `cendree`). Immense plaine ouverte ; carcasses de catapultes (R) ; tranchées (E étroites et peu nombreuses) ; étendards noirs (R isolés).",
          {"L": 2, "D": 2},
          [{"monstres": ["olifant_de_guerre"]}, {"monstres": ["olifant_de_guerre", "cendrillon"]}, {"monstres": ["olifant_de_guerre", "olifant_de_guerre"]},
           {"parmi": ["olifant_de_guerre", "cendrillon"], "nombre": [2, 3]}],
          [P("a", "veteran_clopin", "Clopin, vétéran", "PNJ d'ambiance",
             ["J'étais là au dernier siège. On a gagné. Enfin, on a survécu, c'est pareil à la fin.",
              "Le bélier, Grondin, frappe toujours trois coups. Au troisième, tenez-vous loin. Ou loin de loin."],
             {"rig": "humain", "couleurs": {"tunique": "5a6a8a", "manches": "8a8f96", "pantalon": "3a3a4a", "cheveux": "d8d0c0", "barbe": "d8d0c0"}, "arme": "baton", "accessoires": ["barbe", "casque"]})],
          cendree=True, palette="cendree"),
        C("hautepierre_4_4", "Hautepierre — La Brèche", 4, 4, {"gauche": "hautepierre_3_4", "haut": "hautepierre_4_3"}, "28-30",
          "La brèche ouverte dans la grande muraille extérieure, d'où descend la Cendre ; Grondin y attend la prochaine porte à enfoncer.",
          "Palette `cendre` (comme le Trône de Cendre). Muraille éventrée (M) en diagonale avec une brèche de 5 cases ; arène dégagée (8×8) devant ; braises (taches) ; débris (R) en couverts.",
          {"D": 1},
          [{"monstres": ["grondin"], "reapparition": [1800, 2400]}, {"monstres": ["olifant_de_guerre", "cendrillon"]}],
          groupes_note="Groupe 1 : Grondin seul, fixe, réapparition 30 à 40 min.", boss=True, cendree=True, palette="cendre"),
    ],
    "familles": [DETROUSSEUR, TROLL, CORBAC, GARGOUILLE, CENDRILLON, OLIFANT],
    "boss": {"id": "grondin", "carte": "hautepierre_4_4", "groupe": ["grondin"], "reapparition": [1800, 2400], "json": GRONDIN,
             "sorts": ligne_sorts(["grondin_coup_de_belier", "grondin_eclats_de_porte", "grondin_elan", "grondin_souffle_de_forge"]),
             "art": {"type": "image", "reutilise": None,
                     "nouveau_svg": "monstre/grondin.svgt, ~112×76 px : bélier de siège sur 4 roues, poutre de bois noir cerclée de fer, tête de loup en fer forgé à l'avant aux yeux rouge braise, chaînes pendantes, toit de planches roussies ; ancre au centre bas (≈ [56, 72]). Pas d'équipage : il avance seul.",
                     "manifeste": {"image": "grondin", "echelle": 1.0}},
             "equilibrage": "Pour un niveau 29–30 seul (~285 PV, ~60 dégâts/tour) : ~680 PV effectifs (600 + bouclier 80, sous les 900 du Souverain), 11 tours ; ~28 dégâts/tour (poussées comprises), ~40 à 20 %. Faible au Givre (−20) et au Sacré (−10)."},
    "ville": VILLE,
    "progression": ("Chaque race arrive par sa propre route (Brumerive à l'ouest, Sylvebrume au nord, Crasse-Roc à l'est), toutes au palier 13–15 (détrousseurs ; loups cendreux sur la route de l'Est). "
                    "Puis : 16–18 au sud (trolls du pont, grouilleurs de braise dans les gorges), 19–21 au nord (corbacs, arbres calcinés), 22–24 au nord-est (gargouilles des ruines), "
                    "25–27 au sud-est (Cendrillons), 28–30 au champ de bataille (olifants) et Grondin à la Brèche. La progression tourne autour de la ville, qu'on retraverse souvent "
                    "(Pierre, forge, marchande). Une famille par palier, complétée par une variante Corrompue sur les trois premiers paliers."),
}
