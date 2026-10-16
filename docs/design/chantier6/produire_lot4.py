"""Chantier 6, lot 4 : acte II (par camp) et début de l'acte III (conception : ../chantier6_quetes.md).

    python3 docs/design/chantier6/produire_lot4.py      (depuis la racine du dépôt)

Écrit les 11 quêtes (game/data/quetes), les 8 objets nouveaux (game/data/objets ; icônes déjà dans
game/art/objets) et complète le fragment de manifeste game/art/manifestes/quetes.json. Relancer le
script réécrit ces fichiers.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from produire_lot2 import JEU, ecrire, lire, quete  # noqa: E402

OBJETS = [
    {"id": "tampon_officiel", "nom": "Tampon officiel", "type": "quete", "rarete": "peu_commun", "niveau": 14,
     "description": "Le tampon de l'Intendance. Sans lui, aucun laissez-passer n'est valable. Avec lui, non plus, mais c'est plus joli."},
    {"id": "caisse_de_minerai", "nom": "Caisse de minerai", "type": "quete", "rarete": "commun", "niveau": 14,
     "description": "Du minerai pour les forges du Souverain. Sur le couvercle : « colliers, modèle gobelin, taille unique »."},
    {"id": "malle_de_l_ambassadrice", "nom": "Malle de l'ambassadrice", "type": "quete", "rarete": "peu_commun", "niveau": 14,
     "description": "Les bagages d'Ilyndra Tel'Hautaine : trois robes, deux siècles de correspondance et un herbier de feuilles qu'elle trouve vulgaires."},
    {"id": "liste_du_heraut", "nom": "Liste du Héraut", "type": "quete", "rarete": "rare", "niveau": 23,
     "description": "La liste du Héraut Cendré. Première ligne : « Gobelins (rubrique consommables) »."},
    {"id": "insigne_de_la_vieille_garde", "nom": "Insigne de la Vieille Garde", "type": "amulette", "rarete": "rare", "niveau": 23,
     "boutique": False, "bonus": {"force": [10, 15], "vitalite": [20, 30], "sagesse": [5, 8]},
     "description": "Remis par un fantôme qui monte la garde depuis trois cents ans. Il ne l'a jamais quitté : il ne savait pas qu'on pouvait."},
    {"id": "brassard_du_delegue", "nom": "Brassard du délégué", "type": "amulette", "rarete": "rare", "niveau": 23,
     "boutique": False, "bonus": {"agilite": [10, 15], "chance": [8, 12], "prospection": [15, 25]},
     "description": "Brassard rouge du Syndicat des Travailleurs de Crasse-Roc, section « préavis contre le Souverain lui-même »."},
    {"id": "feuille_d_argent_de_l_ambassade", "nom": "Feuille d'argent de l'ambassade", "type": "anneau", "rarete": "rare", "niveau": 25,
     "boutique": False, "bonus": {"intelligence": [10, 15], "agilite": [6, 10], "sagesse": [6, 10]},
     "description": "Le sceau de l'ambassade elfe. On ne la remet qu'aux observateurs qui ont fini par intervenir."},
    {"id": "eclat_de_l_aube", "nom": "Éclat de l'Aube", "type": "anneau", "rarete": "epique", "niveau": 30,
     "boutique": False, "bonus": {"vitalite": [20, 30], "force": [6, 10], "intelligence": [6, 10], "chance": [6, 10], "agilite": [6, 10]},
     "description": "Un éclat de lumière tombé de la Brèche quand Grondin s'est effondré. Il brille comme une Relique. Ce n'en est pas une. Pas encore."},
]

QUETES = [
    # --- Acte II, humains : « Le bureau des laissez-passer » ---
    quete("hautepierre_tampon_officiel", "Le tampon officiel", "principale", 14, "intendant_gaspard",
          [[{"type": "parler", "pnj": "sergent_mordicus", "texte": "Demander au Sergent Mordicus où est passé le tampon"}],
           [{"type": "vaincre", "monstre": "detrousseur", "nombre": 5},
            {"type": "apporter", "objet": "tampon_officiel", "nombre": 1, "pnj": "intendant_gaspard",
             "butin": {"monstres": ["detrousseur", "chef_de_bande"], "taux": 0.3}}]],
          {"intendant_gaspard": {
              "proposition": ["Un laissez-passer signé du bourgmestre Pansu ? Ravissant. Il n'est valable qu'avec le tampon officiel de l'Intendance.",
                              "Le tampon a disparu. Le Sergent Mordicus, à la Porte de l'Ouest, sait peut-être quelque chose. Il sait rarement quelque chose, mais essayez."],
              "en_cours": ["Le tampon ? Sans tampon, je ne peux rien tamponner. Et un Intendant qui ne tamponne pas, c'est un Intendant qui réfléchit. Personne ne veut ça."],
              "fin": ["Le tampon ! Voyons… *poc*. Votre laissez-passer est valable. Le mien aussi, d'ailleurs : il ne l'était plus depuis mardi.",
                      "Pendant que vous y étiez, le Capitaine Aldebert aurait besoin de quelqu'un qui revient vivant de la Route de l'Ouest."]},
           "sergent_mordicus": {
              "objectif": ["Le tampon ? Les détrousseurs l'ont volé avec la caisse de la Garde. Ils volent tout, sauf les laissez-passer.",
                           "Maintenant qu'ils ont le tampon, ils vont s'en faire. Des laissez-passer. Ça m'inquiète."]}},
          {"xp_cr": 5, "ecus": 180, "objets": [{"objet": "bottes_de_grand_chemin", "nombre": 1}]},
          conditions={"camp": "allie", "niveau_min": 12, "quetes_terminees": ["brumerive_palissade"]}, acte=2,
          description="À Hautepierre, rien ne se fait sans le tampon officiel. Et le tampon a disparu."),
    quete("hautepierre_messages_interceptes", "Messages interceptés", "principale", 20, "capitaine_aldebert",
          [[{"type": "vaincre", "monstre": "corbac_espion", "nombre": 5},
            {"type": "apporter", "objet": "message_intercepte", "nombre": 4, "pnj": "archiviste_petronille",
             "butin": {"monstres": ["corbac_espion", "corbac_chef_espion"], "taux": 0.4}}],
           [{"type": "parler", "pnj": "capitaine_aldebert"}]],
          {"capitaine_aldebert": {
              "proposition": ["Des corbacs survolent la ville et repartent vers l'est, les pattes pleines de messages. Ce sont des espions.",
                              "Abattez-en cinq au nord, récupérez leurs messages et portez-les à Pétronille, l'archiviste. Elle lit tout, même le corbac."],
              "en_cours": ["Les corbacs passent toujours. Ils me font des signes en passant. Des signes grossiers."],
              "fin": ["Une diversion ? Les raids gobelins, une diversion ? Et nous qui envoyions toute la Garde à Brumerive…",
                      "S'il cherche la Chevalière Sans-Rouille, il faut savoir comment il compte entrer. Pétronille a une idée. Elle a toujours une idée."]},
           "archiviste_petronille": {
              "objectif": ["Voyons… code corbac, assez simple : un croassement par lettre. « Les raids gobelins occupent les humains. Pendant ce temps, trouvez la Chevalière Sans-Rouille. »",
                           "Signé : un Héraut Cendré. Allez prévenir le Capitaine. Moi, je classe ça. À la lettre H."]}},
          {"xp_cr": 5, "ecus": 270, "objets": [{"objet": "heaume_d_argent", "nombre": 1}]},
          conditions={"camp": "allie", "niveau_min": 18, "quetes_terminees": ["hautepierre_tampon_officiel"]}, acte=2,
          description="Des corbacs espionnent Hautepierre. Que transportent-ils ?"),
    quete("hautepierre_vieille_garde", "La vieille garde", "principale", 23, "archiviste_petronille",
          [[{"type": "aller", "carte": "hautepierre_3_1", "texte": "Aller aux Ruines de la Vieille Garde"},
            {"type": "vaincre", "monstre": "gargouille", "nombre": 4}],
           [{"type": "parler", "pnj": "capitaine_perenne", "texte": "Interroger le Capitaine Pérenne, le fantôme"}],
           [{"type": "parler", "pnj": "archiviste_petronille"}]],
          {"archiviste_petronille": {
              "proposition": ["Aux Ruines de la Vieille Garde, à l'est, un fantôme monte la garde depuis trois cents ans : le Capitaine Pérenne.",
                              "S'il a vu passer le Héraut, il s'en souvient. Les fantômes n'ont rien d'autre à faire que se souvenir. Attention aux gargouilles : elles aussi gardent, mais mal."],
              "en_cours": ["Le Capitaine Pérenne ? Il est aux Ruines. Il ne bouge pas beaucoup. C'est le principe."],
              "fin": ["« Après, les humains. » Alors ce n'était pas les gobelins, le problème. Les gobelins étaient… un symptôme.",
                      "Le Capitaine vous a remis son insigne ? Il ne l'avait jamais retiré. Portez-le bien : les autres camps doivent apprendre ça aussi. Ils vont venir."]},
           "capitaine_perenne": {
              "objectif": ["Garde, à vos postes ! … Ah, c'est vous. Oui, je l'ai vu. Un Héraut, en armure de cendre. Il cherchait la Chevalière.",
                           "Il a dit : « Après, les humains. » Et il a ri. Je n'aime pas qu'on rie dans mes ruines. Prenez mon insigne. Moi, je reste de garde."]}},
          {"xp_cr": 8, "ecus": 345, "objets": [{"objet": "insigne_de_la_vieille_garde", "nombre": 1}]},
          conditions={"camp": "allie", "niveau_min": 21, "quetes_terminees": ["hautepierre_messages_interceptes"]}, acte=2,
          description="Un fantôme a vu passer le Héraut. Encore faut-il qu'il s'en souvienne."),

    # --- Acte II, gobelins : « Le préavis » ---
    quete("hautepierre_convoi_de_brokk", "Le convoi de Brokk", "principale", 14, "caravanier_brokk",
          [[{"type": "vaincre", "monstre": "loup_cendreux", "nombre": 3},
            {"type": "vaincre", "monstre": "detrousseur", "nombre": 3},
            {"type": "apporter", "objet": "caisse_de_minerai", "nombre": 3, "pnj": "caravanier_brokk",
             "butin": {"monstres": ["loup_cendreux", "detrousseur", "chef_de_bande"], "taux": 0.4}}]],
          {"caravanier_brokk": {
              "proposition": ["Un délégué de Crasse-Roc ? Enfin quelqu'un ! Mon convoi s'est fait piller sur la Route de l'Est : des loups qui fument et des détrousseurs qui volent.",
                              "Récupère trois caisses de minerai. C'est pour le Souverain. Enfin, c'était. J'ai ouvert une caisse, par curiosité professionnelle…"],
              "en_cours": ["Trois caisses. Et fais attention : les loups cendreux mordent chaud."],
              "fin": ["Regarde le couvercle : « colliers, modèle gobelin, taille unique ». On transporte le minerai de nos propres colliers.",
                      "Va voir Snagrod, notre délégué, à la Citadelle. Il attend dans l'antichambre depuis trois semaines. Il aura le temps de t'écouter."]}},
          {"xp_cr": 5, "ecus": 180, "objets": [{"objet": "cape_de_loup_cendreux", "nombre": 1}]},
          conditions={"camp": "ennemi", "niveau_min": 12, "quetes_terminees": ["crasse_roc_balourd"]}, acte=2,
          description="Le convoi de Brokk transporte du minerai pour le Souverain. Mais pour en faire quoi ?"),
    quete("hautepierre_droit_de_passage", "Droit de passage", "principale", 17, "snagrod_delegue",
          [[{"type": "vaincre", "monstre": "troll_des_ponts", "nombre": 4},
            {"type": "apporter", "objet": "recette_de_troll", "nombre": 2, "pnj": "snagrod_delegue",
             "butin": {"monstres": ["troll_des_ponts", "troll_gastronome"], "taux": 0.4}}],
           [{"type": "parler", "pnj": "intendant_gaspard", "texte": "Demander audience à l'Intendant pour Snagrod"}],
           [{"type": "parler", "pnj": "snagrod_delegue"}]],
          {"snagrod_delegue": {
              "proposition": ["Des colliers ? Ça ne m'étonne pas. Il faut que l'Intendant nous reçoive. Il ne reçoit que ceux qui apportent un cadeau.",
                              "Les trolls des ponts ont des recettes. Les humains adorent les recettes. Rapporte-m'en deux, et passe chez les trolls : ils ont un péage, nous on n'a même pas de chaise."],
              "en_cours": ["J'attends. Je suis très bon pour attendre. C'est la seule chose qu'on nous ait apprise."],
              "objectif": ["Les recettes ! Parfait. Va demander audience à l'Intendant. Dis-lui que c'est de la part du syndicat. Non, attends : dis-lui que c'est de la part d'un admirateur."],
              "fin": ["Il a gardé les recettes et refusé de me recevoir ? … C'est ce que je pensais. Bon. On passe à la vitesse supérieure."]},
           "intendant_gaspard": {
              "objectif": ["Des recettes de troll ! Quelle délicatesse. Je les garde, merci. Le délégué gobelin ? Je ne reçois pas les gobelins le jeudi.",
                           "Ni les autres jours. Mais remerciez-le pour les recettes."]}},
          {"xp_cr": 5, "ecus": 230, "objets": [{"objet": "ceinture_de_troll", "nombre": 1}]},
          conditions={"camp": "ennemi", "niveau_min": 15, "quetes_terminees": ["hautepierre_convoi_de_brokk"]}, acte=2,
          description="Snagrod veut une audience. L'Intendant veut des cadeaux. Les trolls ont des recettes."),
    quete("hautepierre_registre_des_sacrifies", "Le registre des sacrifiés", "principale", 23, "snagrod_delegue",
          [[{"type": "vaincre", "monstre": "gargouille", "nombre": 4},
            {"type": "apporter", "objet": "liste_du_heraut", "nombre": 1, "pnj": "snagrod_delegue",
             "butin": {"monstres": ["gargouille", "gargouille_de_la_grande_porte"], "taux": 0.3}}]],
          {"snagrod_delegue": {
              "proposition": ["Brokk a entendu dire que le Héraut a confié ses ordres aux gargouilles. Les gargouilles ne lisent pas, donc elles ne trahissent pas.",
                              "Elles gardent un cimetière à l'est et des ruines au nord-est. Trouve-moi ses ordres. Je veux savoir ce qu'il a prévu pour nous."],
              "en_cours": ["Les gargouilles ? Elles sont en pierre. Toi aussi, il va falloir que tu sois en pierre."],
              "fin": ["« Gobelins (rubrique consommables) ». En premier. Avant les humains, avant les elfes. On ne sera pas les derniers, on sera les premiers. À mourir.",
                      "Je dépose un préavis de grève. Contre le Souverain lui-même. Tiens, porte ce brassard : à partir d'aujourd'hui, on ne se laisse plus faire."]}},
          {"xp_cr": 8, "ecus": 345, "objets": [{"objet": "brassard_du_delegue", "nombre": 1}]},
          conditions={"camp": "ennemi", "niveau_min": 21, "quetes_terminees": ["hautepierre_droit_de_passage"]}, acte=2,
          description="Que prévoit le Héraut pour les gobelins ? La réponse est dans ses ordres. Et ses ordres sont chez les gargouilles."),

    # --- Acte II, elfes : « Ce n'est (finalement) pas pas notre guerre » ---
    quete("hautepierre_notes_d_observatrice", "Notes d'observatrice", "principale", 14, "ilyndra_tel_hautaine",
          [[{"type": "parler", "pnj": "clairon_crieur_public", "texte": "Observer Clairon, crieur public (Grand-Place)"},
            {"type": "parler", "pnj": "maitre_ripaille", "texte": "Observer Maître Ripaille, aubergiste (Grand-Place)"},
            {"type": "parler", "pnj": "frere_benitier", "texte": "Observer Frère Bénitier, prêtre (Porte de l'Ouest)"}],
           [{"type": "vaincre", "monstre": "detrousseur", "nombre": 4},
            {"type": "apporter", "objet": "malle_de_l_ambassadrice", "nombre": 1, "pnj": "ilyndra_tel_hautaine",
             "butin": {"monstres": ["detrousseur", "chef_de_bande"], "taux": 0.3}}]],
          {"ilyndra_tel_hautaine": {
              "proposition": ["Ah, l'observatrice de la Lisière. Moi aussi, j'observe. J'écris un rapport sur « les us et coutumes humains » au conseil.",
                              "Va observer un crieur, un aubergiste et un prêtre. Puis retrouve ma malle : des détrousseurs me l'ont prise sur la Route du Nord. Ils ont le goût sûr, au moins."],
              "en_cours": ["Observe. Prends des notes. Et ma malle, si tu y penses entre deux notes."],
              "objectif": ["Un crieur qui crie, un aubergiste qui sert, un prêtre qui bénit son pouce. Fascinant. Le conseil sera horrifié. Maintenant, ma malle."],
              "fin": ["Ma malle ! Mes robes ! Mes deux siècles de correspondance ! … Il manque un herbier. Tant pis, il était vulgaire.",
                      "Merci. Les humains ne sont pas si terribles, finalement. Ils sont bruyants, mais pas terribles."]},
           "clairon_crieur_public": {
              "objectif": ["OYEZ, OYEZ ! Une elfe prend des notes sur moi ! … Pardon. Je crie tout. C'est mon métier, et ma maladie."]},
           "maitre_ripaille": {
              "objectif": ["Une observatrice elfe ? Asseyez-vous ! Une bière ? Non ? Une tisane ? On a de la tisane. Elle sent la bière, mais c'est de la tisane."]},
           "frere_benitier": {
              "objectif": ["J'ai béni la masse, le bouclier, mon pouce, et la porte. Voulez-vous que je bénisse votre carnet ? Ça ne coûte qu'un écu. Deux pour un carnet elfe."]}},
          {"xp_cr": 5, "ecus": 180, "objets": [{"objet": "amulette_chantante", "nombre": 1}]},
          conditions={"camp": "neutre", "niveau_min": 12, "quetes_terminees": ["sylvebrume_mere_toile"]}, acte=2,
          description="Ilyndra Tel'Hautaine rédige un rapport sur les humains. Elle a besoin d'yeux. Et de sa malle."),
    quete("hautepierre_arbres_qui_brulent", "Les arbres qui brûlent", "principale", 20, "ilyndra_tel_hautaine",
          [[{"type": "vaincre", "monstre": "arbre_calcine", "nombre": 4},
            {"type": "apporter", "objet": "cendre_tiede", "nombre": 3, "pnj": "ilyndra_tel_hautaine",
             "butin": {"monstres": ["arbre_calcine"], "taux": 0.5}}]],
          {"ilyndra_tel_hautaine": {
              "proposition": ["Au nord de la ville, au Bois-Corbeau et sur la Colline Pelée, des arbres marchent en brûlant. Des arbres calcinés.",
                              "Va voir, et rapporte-moi de leur cendre. Je veux savoir si c'est la même cendre que celle qui grise la toile de la Mère-Toile."],
              "en_cours": ["Les arbres brûlent toujours ? Les humains disent que c'est « la saison ». Les humains disent beaucoup de choses."],
              "fin": ["La même cendre. Celle du Souverain. Elle gagne les arbres, ici comme chez nous. La forêt ne sera pas épargnée.",
                      "Le conseil croit encore que ce n'est pas notre guerre. Le conseil va devoir délibérer plus vite. Beaucoup plus vite."]}},
          {"xp_cr": 5, "ecus": 270, "objets": [{"objet": "ceinture_d_ecorce_calcinee", "nombre": 1}]},
          conditions={"camp": "neutre", "niveau_min": 18, "quetes_terminees": ["hautepierre_notes_d_observatrice"]}, acte=2,
          description="Des arbres brûlent au nord de Hautepierre. La cendre gagne-t-elle aussi les forêts ?"),
    quete("hautepierre_bal_des_cendrillons", "Le bal des Cendrillons", "principale", 25, "ilyndra_tel_hautaine",
          [[{"type": "vaincre", "monstre": "cendrillon", "nombre": 3},
            {"type": "apporter", "objet": "invitation_au_bal", "nombre": 3, "pnj": "ilyndra_tel_hautaine",
             "butin": {"monstres": ["cendrillon", "marraine_cendree"], "taux": 0.5}}]],
          {"ilyndra_tel_hautaine": {
              "proposition": ["Les Cendrillons campent à l'est, dans la plaine cendrée. Elles préparent un bal. Au service du Souverain, on danse avant de brûler.",
                              "Rapporte-moi trois de leurs invitations. Je veux voir le programme."],
              "en_cours": ["Les Cendrillons dansent toujours ? Elles ont trois pas : avancer, brûler, recommencer."],
              "fin": ["Le programme du bal : « Minuit : embrasement de Sylvebrume. » Notre forêt. En spectacle de clôture.",
                      "Ce n'est pas notre guerre ? Si. C'est la nôtre. Je demande un siège au Conseil des humains. Pour observer de plus près. Et pour frapper, s'il le faut.",
                      "Prends cette feuille d'argent. Elle est réservée aux observateurs qui ont fini par intervenir."]}},
          {"xp_cr": 8, "ecus": 375, "objets": [{"objet": "feuille_d_argent_de_l_ambassade", "nombre": 1}]},
          conditions={"camp": "neutre", "niveau_min": 23, "quetes_terminees": ["hautepierre_arbres_qui_brulent"]}, acte=2,
          description="Les Cendrillons préparent un bal. Que fête-t-on, au service du Souverain ?"),

    # --- Acte III, commun : « L'alliance » (début) ---
    quete("hautepierre_conseil_des_peuples_libres", "Le Conseil des Peuples Libres", "principale", 26, "intendant_gaspard",
          [[{"type": "parler", "pnj": "snagrod_delegue", "texte": "Convaincre Snagrod, délégué gobelin"},
            {"type": "parler", "pnj": "ilyndra_tel_hautaine", "texte": "Convaincre Ilyndra, ambassadrice elfe"}],
           [{"type": "vaincre", "monstre": "olifant_de_guerre", "nombre": 3}],
           [{"type": "parler", "pnj": "intendant_gaspard"}]],
          {"intendant_gaspard": {
              "proposition": ["Les humains, les gobelins et les elfes ont tous découvert la même chose : le Souverain veut tout le monde. Ses propres troupes comprises.",
                              "Il faut un Conseil. Avec les gobelins. Oui, avec les gobelins. Je l'ai dit, c'est fait, ne me le faites pas répéter. Allez convaincre Snagrod et Ilyndra."],
              "en_cours": ["Le Conseil se réunira quand tout le monde sera d'accord. Ou quand tout le monde sera assis. C'est déjà difficile."],
              "objectif": ["Ils acceptent ? Bien. Le Conseil veut une preuve que l'alliance tient au moins un combat. Les olifants de guerre, aux Champs du Pèle-Ennemi. Trois."],
              "fin": ["Trois olifants ! L'alliance tient. Le Conseil des Peuples Libres est fondé. Les gobelins ont apporté leur propre chaise. Les elfes observent la chaise.",
                      "Le Capitaine Aldebert vous attend. La Brèche ne tiendra plus longtemps."]},
           "snagrod_delegue": {
              "objectif": ["Un siège au Conseil ? Pour les gobelins ? … On amène notre chaise. On ne fait pas confiance aux vôtres."]},
           "ilyndra_tel_hautaine": {
              "objectif": ["Un Conseil. Avec des gobelins et des humains. Le conseil de la Lisière va s'évanouir. J'accepte. Pour observer."]}},
          {"xp_cr": 5, "ecus": 390, "objets": [{"objet": "cape_en_cuir_d_olifant", "nombre": 1}]},
          conditions={"niveau_min": 24, "une_quete_terminee": ["hautepierre_vieille_garde", "hautepierre_registre_des_sacrifies",
                                                                "hautepierre_bal_des_cendrillons"]}, acte=3,
          description="Les trois camps ont compris. Reste à les asseoir à la même table."),
    quete("hautepierre_la_breche", "La Brèche", "principale", 30, "capitaine_aldebert",
          [[{"type": "vaincre_groupe", "monstre": "grondin"}],
           [{"type": "parler", "pnj": "archiviste_petronille", "texte": "Faire votre rapport à Pétronille"}]],
          {"capitaine_aldebert": {
              "proposition": ["Grondin, le bélier de siège du Souverain, frappe à la Brèche, au sud-est. Si elle cède, Hautepierre tombe.",
                              "Le Conseil vous envoie. Les humains vous prêtent leurs murs, les gobelins leurs pioches, les elfes… leurs encouragements. Allez-y."],
              "en_cours": ["La Brèche tient encore. Chaque coup de Grondin fait trembler la Tour Blanche. Et l'Intendant."]},
           "archiviste_petronille": {
              "fin": ["Grondin est tombé ! La Brèche tiendra. Mais pendant que tout le monde regardait la Brèche…",
                      "La Chevalière Sans-Rouille a disparu de la Citadelle. Le Héraut l'a prise. La quête des Reliques de l'Aube commence. Pour de bon.",
                      "Gardez cet éclat tombé de la Brèche. Il brille comme une Relique. Un jour, peut-être, vous en porterez une vraie."]}},
          {"xp_cr": 8, "ecus": 450, "objets": [{"objet": "eclat_de_l_aube", "nombre": 1}]},
          conditions={"niveau_min": 28, "quetes_terminees": ["hautepierre_conseil_des_peuples_libres"]}, acte=3,
          description="Grondin frappe à la Brèche. Le Conseil des Peuples Libres livre sa première bataille."),
]


def main():
    for objet in OBJETS:
        ecrire(os.path.join(JEU, "data", "objets", objet["id"] + ".json"), objet)
    for q in QUETES:
        ecrire(os.path.join(JEU, "data", "quetes", q["id"] + ".json"), q)
    fragment_chemin = os.path.join(JEU, "art", "manifestes", "quetes.json")
    fragment = lire(fragment_chemin)
    for objet in OBJETS:
        fragment.setdefault("images", {})["objet_" + objet["id"]] = {"fichier": f"objets/{objet['id']}.svgt", "ancre": [22, 22]}
    ecrire(fragment_chemin, fragment)
    print(f"lot 4 : {len(QUETES)} quêtes, {len(OBJETS)} objets")


if __name__ == "__main__":
    main()
