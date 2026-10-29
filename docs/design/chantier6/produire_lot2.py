"""Chantier 6, lot 2 : tutoriels et acte I (conception : ../chantier6_quetes.md).

    python3 docs/design/chantier6/produire_lot2.py      (depuis la racine du dépôt)

Écrit les 15 quêtes (game/data/quetes), les 5 objets nouveaux (game/data/objets ; icônes déjà
dans game/art/objets), place les 2 PNJ nouveaux sur leurs cartes et complète le fragment de
manifeste game/art/manifestes/quetes.json. Relancer le script réécrit ces fichiers.
"""
import json
import os

RACINE = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
JEU = os.path.join(RACINE, "game")


def ecrire(chemin, donnees):
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(donnees, f, ensure_ascii=False, indent=2)
        f.write("\n")


def lire(chemin):
    with open(chemin, encoding="utf-8") as f:
        return json.load(f)


# --- Objets ------------------------------------------------------------------------------------

OBJETS = [
    {"id": "panier_de_pommes", "nom": "Panier de pommes", "type": "quete", "rarete": "commun", "niveau": 6,
     "description": "Les pommes de Mère Pomponne, reprises une à une aux pillards. Il en manque une : la plus belle."},
    {"id": "laissez_passer_de_hautepierre", "nom": "Laissez-passer de Hautepierre", "type": "quete", "rarete": "rare", "niveau": 12,
     "description": "Signé du bourgmestre Pansu, contresigné par personne. À présenter au bureau des laissez-passer, qui exige un laissez-passer pour y entrer."},
    {"id": "echarpe_du_heros_de_brumerive", "nom": "Écharpe du Héros de Brumerive", "type": "cape", "rarete": "rare", "niveau": 12,
     "boutique": False, "bonus": {"vitalite": [20, 30], "force": [5, 8], "intelligence": [5, 8]},
     "description": "Brodée « Au héros de Brumerive » par le bourgmestre, qui en a commandé une pour lui aussi. Par précaution."},
    {"id": "carte_du_syndicat", "nom": "Carte du syndicat", "type": "amulette", "rarete": "rare", "niveau": 12,
     "boutique": False, "bonus": {"agilite": [6, 10], "perception": [6, 10], "prospection": [10, 20]},
     "description": "Carte de délégué provisoire du Syndicat des Travailleurs de Crasse-Roc. Donne droit à une pause par décennie."},
    {"id": "broche_de_la_lisiere", "nom": "Broche de la Lisière", "type": "amulette", "rarete": "rare", "niveau": 12,
     "boutique": False, "bonus": {"intelligence": [6, 10], "agilite": [6, 10], "sagesse": [4, 8]},
     "description": "Remise aux observateurs du conseil elfe. On ne l'a remise qu'une fois en trois siècles : à vous."},
]

# --- PNJ nouveaux ------------------------------------------------------------------------------

PNJ = [
    {"carte": "brumerive_0_0", "ligne": 19, "colonne": 13,
     "pnj": {"marqueur": "d", "id": "bourgmestre_pansu", "nom": "Fortunat Pansu, bourgmestre",
             "repliques": ["Brumerive vous remercie ! Enfin, je vous remercie au nom de Brumerive. C'est pareil.",
                           "Un jour, on écrira des chansons sur moi. J'ai déjà écrit les paroles."]},
     "art": {"rig": "humain", "couleurs": {"tunique": "7a2a32", "manches": "6a2028", "pantalon": "3a2e28",
                                           "cheveux": "8a8070", "bottes": "2e2620", "etole": "d8b048"},
             "accessoires": ["barbe", "etole"]}},
    {"carte": "brumerive_2_2", "ligne": 17, "colonne": 12,
     "pnj": {"marqueur": "a", "id": "pere_pomponne", "nom": "Père Pomponne, « prisonnier »",
             "repliques": ["Chut ! Ils m'ont capturé. Enfin, ils m'ont proposé un contrat.",
                           "Ici, le déjeuner dure deux heures. Deux heures !"]},
     "art": {"rig": "humain", "couleurs": {"tunique": "8a7a4a", "manches": "7a6a3a", "pantalon": "5a4632",
                                           "cheveux": "c8c0b0", "chapeau": "c8a860"},
             "accessoires": ["chapeau_paille"]}},
]


# --- Quêtes ------------------------------------------------------------------------------------

def quete(id, nom, categorie, niveau, pnj, etapes, dialogues, recompenses, conditions=None, acte=None,
          description="", donne=None):
    q = {"id": id, "nom": nom, "categorie": categorie, "niveau": niveau, "pnj": pnj, "description": description}
    if acte:
        q["acte"] = acte
    if conditions:
        q["conditions"] = conditions
    if donne:
        q["donne"] = donne
    q["etapes"] = [{"objectifs": e} for e in etapes]
    q["dialogues"] = dialogues
    q["recompenses"] = recompenses
    return q


def tutoriel(zone, camp, pnj, monstre, ressource, nombre, forgeron, textes, donne, equiper):
    return quete(
        f"{zone}_tutoriel", textes["nom"], "tutoriel", 1, pnj,
        [
            [{"type": "equiper", "objet": "bonnet_de_berger", "texte": equiper}],
            [{"type": "vaincre", "monstre": monstre, "nombre": 2}],
            [{"type": "recolter", "objet": ressource, "nombre": nombre}],
            [{"type": "fabriquer", "metier": "forgeron", "texte": f"Fabriquer un objet chez {forgeron}"}],
            [{"type": "parler", "pnj": pnj}],
        ],
        {pnj: textes["dialogues"]},
        {"xp_cr": 5, "ecus": 20},
        conditions={"camp": camp}, description=textes["description"], donne=donne)


QUETES = [
    tutoriel("brumerive", "allie", "alric_le_berger", "loup_des_collines", "minerai_de_cuivre", 4, "Célébrimbert", {
        "nom": "Bienvenue à Brumerive",
        "description": "Alric le berger a besoin d'un héros. Faute de mieux, il vous a choisi.",
        "dialogues": {
            "proposition": ["Ah, un aventurier ! Enfin ! Brumerive manque de héros : le dernier est parti chercher du pain il y a six ans.",
                            "Tenez, mettez ce bonnet. Il était à mon père, qui ne l'a jamais porté. Puis chassez deux loups, ramassez du cuivre et faites-vous forger quelque chose chez Célébrimbert. Un héros, ça s'équipe."],
            "en_cours": ["Les loups, le cuivre, la forge. Dans l'ordre. Les héros ont besoin d'ordre, sinon ils improvisent."],
            "fin": ["Bonnet, loups, cuivre, forge : vous êtes officiellement un héros de Brumerive. Le bourgmestre voudra vous voir. Il veut voir tous les héros. Il les compte."],
        }}, [{"objet": "bonnet_de_berger", "nombre": 1}], "Mettre le bonnet d'Alric"),
    tutoriel("crasse_roc", "ennemi", "contremaitre_grumm", "rat_des_galeries", "minerai_de_cuivre", 4, "Krogma", {
        "nom": "Fiche d'embauche",
        "description": "Grumm vous embauche. Vous n'avez rien signé, mais c'est déjà fait.",
        "dialogues": {
            "proposition": ["Encore un nouveau ? Fiche d'embauche, alinéa un : mettre le casque réglementaire. Le budget casques est épuisé, donc c'est un bonnet.",
                            "Alinéa deux : dératiser, deux rats. Alinéa trois : miner du cuivre. Alinéa quatre : te faire forger un truc chez Krogma. Alinéa cinq : revenir pointer."],
            "en_cours": ["T'as pas pointé. Tant que t'as pas pointé, t'as pas travaillé. C'est le règlement."],
            "fin": ["Pointé. Bienvenue à Crasse-Roc, matricule… euh… on verra. Va voir s'il reste du travail. Il en reste toujours."],
        }}, [{"objet": "bonnet_de_berger", "nombre": 1}], "Mettre le casque réglementaire (un bonnet, budget oblige)"),
    tutoriel("sylvebrume", "neutre", "gardienne_elwyn", "morille_grincheuse", "bois_de_frene", 5, "Aelthar", {
        "nom": "Les premiers pas de la jeune pousse",
        "description": "Elwyn vous apprend à vivre à la Lisière. Lentement.",
        "dialogues": {
            "proposition": ["Bienvenue sous les branches, jeune pousse. Ce bonnet est une couronne de feuilles. Elle a trois siècles, elle est neuve.",
                            "Chasse deux morilles grincheuses, avec respect. Ramasse du bois de frêne, mort, évidemment. Je te donne le cuivre : Aelthar saura persuader le métal."],
            "en_cours": ["Prends ton temps. Nous avons des siècles. Toi, un peu moins."],
            "fin": ["Tu as fait tout cela en une seule saison ? Quelle précipitation. C'est très bien. Ne le refais pas trop souvent."],
        }}, [{"objet": "bonnet_de_berger", "nombre": 1}, {"objet": "minerai_de_cuivre", "nombre": 1}], "Mettre la couronne de feuilles (un bonnet)"),

    # --- Acte I, humains : « Le raid gobelin » ---
    quete("brumerive_aux_armes", "Aux armes, citoyens (surtout vous)", "principale", 3, "bourgmestre_pansu",
          [[{"type": "vaincre", "monstre": "gobelin_frondeur", "nombre": 4},
            {"type": "apporter", "objet": "fiche_de_paie_gobeline", "nombre": 3, "pnj": "bourgmestre_pansu",
             "butin": {"monstres": ["gobelin_frondeur", "frondeur_veteran"], "taux": 0.5}}]],
          {"bourgmestre_pansu": {
              "proposition": ["Ah ! Le nouveau héros ! Je suis Fortunat Pansu, bourgmestre, et accessoirement le premier héros de Brumerive.",
                              "Les gobelins nous harcèlent depuis les champs de l'est. Allez en chasser quatre et rapportez-moi des preuves. Moi, je coordonne."],
              "en_cours": ["Je coordonne toujours. C'est épuisant."],
              "fin": ["Des fiches de paie ? Ils sont PAYÉS ?! Nous, on nous paie en remerciements. Enfin, je vous remercie. Voilà."]}},
          {"xp_cr": 5, "ecus": 55, "objets": [{"objet": "bottes_de_marche", "nombre": 1}]},
          conditions={"camp": "allie", "niveau_min": 2, "quetes_terminees": ["brumerive_tutoriel"]}, acte=1,
          description="Le bourgmestre veut des preuves que les gobelins existent. Et qu'ils sont méchants, de préférence."),
    quete("brumerive_verger", "Le verger de Mère Pomponne", "principale", 6, "mere_pomponne",
          [[{"type": "vaincre", "monstre": "gobelin_pillard", "nombre": 4},
            {"type": "apporter", "objet": "panier_de_pommes", "nombre": 5, "pnj": "mere_pomponne",
             "butin": {"monstres": ["gobelin_pillard", "pillard_emerite"], "taux": 0.4}}],
           [{"type": "parler", "pnj": "pere_pomponne", "texte": "Retrouver le Père Pomponne au camp du raid"}],
           [{"type": "parler", "pnj": "mere_pomponne"}]],
          {"mere_pomponne": {
              "proposition": ["Ils ont pris mes pommes, mes poules et mon mari. Rapportez-moi au moins les pommes.",
                              "Et si vous croisez mon mari au camp des gobelins… dites-lui que le dîner refroidit. Depuis trois semaines."],
              "en_cours": ["Mes pommes ! Et mon mari, si ça ne vous dérange pas."],
              "objectif": ["Mes pommes ! Il en manque une, la plus belle. Bon. Et mon mari ? Allez voir au camp du raid, au sud-est."],
              "fin": ["Il ne rentre pas ? Des congés payés ? … Dites, ils embauchent, ces gobelins ?"]},
           "pere_pomponne": {
              "objectif": ["Rentrer ? Ici on a une pause déjeuner de deux heures, une mutuelle et un comité d'entreprise.",
                           "Dites à ma femme que je suis prisonnier. Prisonnier volontaire, mais prisonnier."]}},
          {"xp_cr": 5, "ecus": 90, "objets": [{"objet": "ceinturon_rivete", "nombre": 1}]},
          conditions={"camp": "allie", "niveau_min": 5, "quetes_terminees": ["brumerive_aux_armes"]}, acte=1,
          description="Les pillards ont vidé le verger. Et emmené le Père Pomponne, qui n'a pas beaucoup résisté."),
    quete("brumerive_ordres_du_raid", "Les ordres du raid", "principale", 9, "sentinelle_hubert",
          [[{"type": "apporter", "objet": "ordre_de_raid", "nombre": 3, "pnj": "sentinelle_hubert",
             "butin": {"monstres": ["gobelin_briseur", "gobelin_pillard", "defonceur_de_portes", "pillard_emerite"], "taux": 0.35}}],
           [{"type": "parler", "pnj": "grizzik_le_deserteur", "texte": "Faire lire les ordres à Grizzik, le gobelin « en pause »"}],
           [{"type": "parler", "pnj": "bourgmestre_pansu", "texte": "Rendre compte au bourgmestre Pansu"}]],
          {"sentinelle_hubert": {
              "proposition": ["Les gobelins reçoivent des ordres écrits. Personne ici ne lit le gobelin. Personne ici ne lit beaucoup, d'ailleurs.",
                              "Rapportez-moi trois ordres de raid, des briseurs ou des pillards. On trouvera bien quelqu'un pour les lire."],
              "en_cours": ["Trois ordres. Gobelins. Écrits. C'est tout ce que je sais."],
              "objectif": ["Ça, c'est de l'écriture ? On dirait des traces de poule. Il paraît qu'un gobelin se cache aux champs de l'est. Grizzik. Il est « en pause »."]},
           "grizzik_le_deserteur": {
              "objectif": ["Fais voir… « Raid sur Brumerive, signé : un Héraut ». Et en bas, en tout petit : « Les gobelins ne reviendront pas. »",
                           "Ne reviendront pas ?! Moi, je reste en pause. Toi, va dire ça à ton bourgmestre."]},
           "bourgmestre_pansu": {
              "fin": ["Un Héraut ? Un vrai Héraut, avec un grand H ? Alors c'est sérieux. Alors j'avais raison. J'ai toujours raison, mais là, c'est sérieux."]}},
          {"xp_cr": 5, "ecus": 125, "objets": [{"objet": "chevaliere_du_cogneur", "nombre": 1}]},
          conditions={"camp": "allie", "niveau_min": 8, "quetes_terminees": ["brumerive_verger"]}, acte=1,
          description="Qui donne les ordres aux gobelins ? Hubert veut savoir. Il ne sait pas lire, mais il veut savoir."),
    quete("brumerive_palissade", "La palissade de Krasbouk", "principale", 12, "bourgmestre_pansu",
          [[{"type": "vaincre_groupe", "monstre": "krasbouk"}],
           [{"type": "parler", "pnj": "bourgmestre_pansu"}]],
          {"bourgmestre_pansu": {
              "proposition": ["Krasbouk, le chef du raid, s'est retranché derrière sa palissade, au bout du gué. Il faut l'en déloger.",
                              "Je vous accompagnerais bien, mais quelqu'un doit rester ici pour recevoir les félicitations."],
              "en_cours": ["Krasbouk tient toujours ? Courage ! Je vous soutiens moralement, de très près."],
              "fin": ["Krasbouk vaincu ! Grâce à mon plan ! Voici l'écharpe du Héros de Brumerive, et un laissez-passer pour Hautepierre.",
                      "Vous n'en aurez pas besoin, vous êtes avec moi. Mais au cas où on vous demanderait qui vous envoie : c'est moi."]}},
          {"xp_cr": 8, "ecus": 165, "objets": [{"objet": "echarpe_du_heros_de_brumerive", "nombre": 1},
                                               {"objet": "laissez_passer_de_hautepierre", "nombre": 1}]},
          conditions={"camp": "allie", "niveau_min": 11, "quetes_terminees": ["brumerive_ordres_du_raid"]}, acte=1,
          description="Le raid a un chef, le chef a une palissade, et Brumerive a vous."),

    # --- Acte I, gobelins : « Le grand raid » ---
    quete("crasse_roc_productivite", "Objectifs de productivité", "principale", 3, "contremaitre_grumm",
          [[{"type": "vaincre", "monstre": "rat_des_galeries", "nombre": 6},
            {"type": "apporter", "objet": "queue_de_rat", "nombre": 5, "pnj": "contremaitre_grumm",
             "butin": {"monstres": ["rat_des_galeries", "rat_roi"], "taux": 0.5}}]],
          {"contremaitre_grumm": {
              "proposition": ["Note de service : les rats mangent plus de minerai que les mineurs. La direction veut un quota.",
                              "Six rats, cinq queues comme justificatif. Pas de queue, pas de rat. Pas de rat, pas de prime. Y a pas de prime, mais c'est pour l'exemple."],
              "en_cours": ["Le quota, c'est le quota. Le quota, c'est sacré. Le quota, c'est moi qui l'ai inventé."],
              "fin": ["Cinq queues, quota atteint. La direction te félicite. Enfin, elle félicite le service. Enfin, elle me félicite."]}},
          {"xp_cr": 5, "ecus": 55, "objets": [{"objet": "bottes_feutrees", "nombre": 1}]},
          conditions={"camp": "ennemi", "niveau_min": 2, "quetes_terminees": ["crasse_roc_tutoriel"]}, acte=1,
          description="Les rats mangent le minerai. Le minerai, c'est pour le Souverain. Le Souverain n'aime pas partager."),
    quete("crasse_roc_heures_sup", "Heures supplémentaires (non payées)", "principale", 6, "contremaitre_grumm",
          [[{"type": "vaincre", "monstre": "vampipistrelle", "nombre": 4},
            {"type": "apporter", "objet": "guano_luisant", "nombre": 3, "pnj": "gnark_guanoculteur",
             "butin": {"monstres": ["vampipistrelle", "vampipistrelle_comtesse"], "taux": 0.5}}],
           [{"type": "parler", "pnj": "contremaitre_grumm"}]],
          {"contremaitre_grumm": {
              "proposition": ["Le puits des vampipistrelles bloque la production. Va en chasser quatre. C'est en dehors de tes heures, donc c'est gratuit.",
                              "Et rapporte du guano à Gnark, il le revend pour moi. Pour le service. Pour moi."],
              "en_cours": ["Tu fais des heures sup ? Bien. Elles ne comptent pas, mais c'est bien."],
              "fin": ["Gnark m'a payé. Je veux dire, il a payé le service. Tiens, ta part : c'est la mienne, mais je suis généreux aujourd'hui."]},
           "gnark_guanoculteur": {
              "objectif": ["Du guano luisant ! De l'or qui sent mauvais ! Grumm en prend la moitié, la direction l'autre moitié, et moi je garde l'odeur."]}},
          {"xp_cr": 5, "ecus": 90, "objets": [{"objet": "cape_de_vampipistrelle", "nombre": 1}]},
          conditions={"camp": "ennemi", "niveau_min": 5, "quetes_terminees": ["crasse_roc_productivite"]}, acte=1,
          description="Des heures supplémentaires, c'est comme des heures, mais en plus."),
    quete("crasse_roc_inspection", "Inspection surprise", "principale", 9, "contremaitre_grumm",
          [[{"type": "vaincre", "monstre": "milicien_de_hautepierre", "nombre": 4},
            {"type": "apporter", "objet": "ecusson_de_milice", "nombre": 3, "pnj": "grizzlok_le_pacifiste",
             "butin": {"monstres": ["milicien_de_hautepierre", "sergent_de_milice"], "taux": 0.5}}],
           [{"type": "parler", "pnj": "contremaitre_grumm"}]],
          {"contremaitre_grumm": {
              "proposition": ["La milice de Hautepierre est venue inspecter la carrière. On n'aime pas les inspections. Surtout les nôtres.",
                              "Chasse-les. Rapporte des écussons à Grizzlok, c'est lui qui tient le registre des incidents. Il lit tout, même les ordres de mission."],
              "en_cours": ["La milice inspecte encore ? Inspecte-la, toi."],
              "fin": ["Diversion ? Pas de retour ? … Bah. Les ordres, c'est les ordres. Mais je vais quand même les relire. Lentement."]},
           "grizzlok_le_pacifiste": {
              "objectif": ["Des écussons… Pauvres gars. J'ai lu l'ordre de mission en entier, moi. Personne ne le lit en entier.",
                           "Le raid sur Brumerive est une diversion, ordonnée par un Héraut. Et personne n'a prévu de retour. Va dire ça à Grumm."]}},
          {"xp_cr": 5, "ecus": 125, "objets": [{"objet": "casque_cabosse", "nombre": 1}]},
          conditions={"camp": "ennemi", "niveau_min": 8, "quetes_terminees": ["crasse_roc_heures_sup"]}, acte=1,
          description="La milice humaine inspecte la carrière. Grumm déteste les inspections, sauf quand c'est lui qui inspecte."),
    quete("crasse_roc_balourd", "Le Balourd des Abîmes", "principale", 12, "contremaitre_grumm",
          [[{"type": "vaincre_groupe", "monstre": "balourd_des_abimes"}],
           [{"type": "parler", "pnj": "contremaitre_grumm"}]],
          {"contremaitre_grumm": {
              "proposition": ["Le Balourd des Abîmes bloque la grande galerie. La direction veut la galerie. La direction ne veut pas le Balourd.",
                              "Descends à l'Abîme et règle ça. Si tu reviens, je te nomme délégué. Si tu ne reviens pas, je nomme quelqu'un d'autre."],
              "en_cours": ["Le Balourd est toujours là. Je le sais : la galerie fume encore."],
              "fin": ["Tu es revenu ! Bon, alors tu es délégué provisoire. Voici ta carte du syndicat.",
                      "Première mission : porter notre préavis à Hautepierre. En main propre au Souverain, ou à quelqu'un de proche. Bon courage."]}},
          {"xp_cr": 8, "ecus": 165, "objets": [{"objet": "carte_du_syndicat", "nombre": 1}]},
          conditions={"camp": "ennemi", "niveau_min": 11, "quetes_terminees": ["crasse_roc_inspection"]}, acte=1,
          description="La grande galerie est bloquée par un Balourd. Un gros."),

    # --- Acte I, elfes : « Ce n'est pas notre guerre » ---
    quete("sylvebrume_observer", "Observer sans intervenir", "principale", 3, "gardienne_elwyn",
          [[{"type": "aller", "carte": "sylvebrume_1_0", "texte": "Observer la Futaie ancienne"},
            {"type": "aller", "carte": "sylvebrume_1_1", "texte": "Observer la Coupe rase"}],
           [{"type": "parler", "pnj": "druide_feuillemorte"}]],
          {"gardienne_elwyn": {
              "proposition": ["Les humains et les gobelins se battent. Ce n'est pas notre guerre. Mais il faut bien la regarder pour savoir que ce n'est pas la nôtre.",
                              "Va observer la Futaie ancienne et la Coupe rase, puis parle à Feuillemorte. Observer, c'est déjà agir. Lentement."],
              "en_cours": ["Tu observes ? Observe mieux. Plus lentement."]},
           "druide_feuillemorte": {
              "fin": ["Tu as vu ? Ils ont coupé Vieux-Branchu. Mille ans. Il me devait de l'argent.",
                      "Elwyn dit que ce n'est pas notre guerre. La forêt, elle, n'a pas été consultée."]}},
          {"xp_cr": 5, "ecus": 55, "objets": [{"objet": "bottes_de_mousse", "nombre": 1}]},
          conditions={"camp": "neutre", "niveau_min": 2, "quetes_terminees": ["sylvebrume_tutoriel"]}, acte=1,
          description="Elwyn veut savoir ce qui se passe dans la forêt, sans que personne ne fasse rien."),
    quete("sylvebrume_arbres_nerveux", "Les arbres sont nerveux", "principale", 6, "druide_feuillemorte",
          [[{"type": "vaincre", "monstre": "arbre_vivant", "nombre": 4},
            {"type": "apporter", "objet": "seve_ancienne", "nombre": 3, "pnj": "druide_feuillemorte",
             "butin": {"monstres": ["arbre_vivant", "arbre_millenaire"], "taux": 0.5}}]],
          {"druide_feuillemorte": {
              "proposition": ["Depuis qu'on a coupé Vieux-Branchu, les arbres vivants sont nerveux. Ils marchent. Ils ne devraient pas marcher.",
                              "Calme-en quatre, fermement. Et rapporte-moi de la sève ancienne : je ferai un baume pour la souche de Vieux-Branchu."],
              "en_cours": ["Les arbres marchent toujours ? Calme-les. Ils ont le temps, eux. Pas nous."],
              "fin": ["Le baume prendra. Dans un siècle ou deux, une pousse. Vieux-Branchu serait fier. Il me devait toujours de l'argent, cela dit."]}},
          {"xp_cr": 5, "ecus": 90, "objets": [{"objet": "cape_d_ecorce", "nombre": 1}]},
          conditions={"camp": "neutre", "niveau_min": 5, "quetes_terminees": ["sylvebrume_observer"]}, acte=1,
          description="Les arbres de la forêt s'agitent depuis qu'on a coupé le plus vieux d'entre eux."),
    quete("sylvebrume_coupe_rase", "Coupe rase", "principale", 9, "druide_feuillemorte",
          [[{"type": "vaincre", "monstre": "bucheron_de_brumerive", "nombre": 5},
            {"type": "apporter", "objet": "bon_de_coupe", "nombre": 3, "pnj": "druide_feuillemorte",
             "butin": {"monstres": ["bucheron_de_brumerive", "abatteur_en_chef"], "taux": 0.5}}],
           [{"type": "parler", "pnj": "gardienne_elwyn", "texte": "Rendre compte à Elwyn"}]],
          {"druide_feuillemorte": {
              "proposition": ["Les bûcherons de Brumerive coupent sans demander. Ils ont des papiers, paraît-il : des bons de coupe.",
                              "Chasse-en cinq et rapporte-moi trois de ces bons. Je veux savoir qui signe la mort des arbres."],
              "en_cours": ["Des bons de coupe. Trois. Et les bûcherons qui vont avec, pour la forme."],
              "objectif": ["Signés de Hautepierre : du bois pour des palissades contre les gobelins. Et les gobelins sont poussés par un « Héraut ».",
                           "Tout le monde a une bonne raison. C'est bien le problème. Va dire ça à Elwyn."]},
           "gardienne_elwyn": {
              "fin": ["Un Héraut… Le conseil va devoir délibérer. Il délibère depuis trois siècles sur l'opportunité de délibérer. Ça va aller vite, pour une fois."]}},
          {"xp_cr": 5, "ecus": 125, "objets": [{"objet": "couronne_de_ramure", "nombre": 1}]},
          conditions={"camp": "neutre", "niveau_min": 8, "quetes_terminees": ["sylvebrume_arbres_nerveux"]}, acte=1,
          description="Qui signe les bons de coupe des bûcherons humains ?"),
    quete("sylvebrume_mere_toile", "La Mère-Toile", "principale", 12, "gardienne_elwyn",
          [[{"type": "vaincre_groupe", "monstre": "mere_toile"}],
           [{"type": "parler", "pnj": "gardienne_elwyn"}]],
          {"gardienne_elwyn": {
              "proposition": ["Au cœur de la Toile, la Mère-Toile tisse gris. Ses fils sentent la cendre. Ça, c'est notre guerre.",
                              "Va au cœur de la Toile, au nord-ouest. Le conseil délibère pendant ce temps. Ne l'attends pas."],
              "en_cours": ["La toile est toujours grise. Le conseil délibère toujours. Rien ne change, c'est rassurant et inquiétant à la fois."],
              "fin": ["La Mère-Toile est tombée. Le conseil a décidé, après trois siècles : il envoie une observatrice à Hautepierre. Toi.",
                      "Voici la Broche de la Lisière. On ne l'a remise qu'une fois. Ne la perds pas : il faudrait délibérer pour la remplacer."]}},
          {"xp_cr": 8, "ecus": 165, "objets": [{"objet": "broche_de_la_lisiere", "nombre": 1}]},
          conditions={"camp": "neutre", "niveau_min": 11, "quetes_terminees": ["sylvebrume_coupe_rase"]}, acte=1,
          description="La toile de la Mère-Toile devient grise. La cendre gagne la forêt."),
]


def placer_pnj(spec):
    chemin = os.path.join(JEU, "data", "cartes", spec["carte"] + ".json")
    carte = lire(chemin)
    pnj = spec["pnj"]
    carte["pnj"] = [p for p in carte.get("pnj", []) if p["id"] != pnj["id"]]
    ligne = carte["plan"][spec["ligne"]]
    deja = ligne[spec["colonne"]]
    assert deja in (".", pnj["marqueur"]), f"{spec['carte']} : case occupée ({deja})"
    assert all(p["marqueur"] != pnj["marqueur"] for p in carte["pnj"]), "marqueur déjà pris"
    carte["plan"][spec["ligne"]] = ligne[:spec["colonne"]] + pnj["marqueur"] + ligne[spec["colonne"] + 1:]
    carte["pnj"].append(pnj)
    ecrire(chemin, carte)


def main():
    for objet in OBJETS:
        ecrire(os.path.join(JEU, "data", "objets", objet["id"] + ".json"), objet)
    for q in QUETES:
        ecrire(os.path.join(JEU, "data", "quetes", q["id"] + ".json"), q)
    for spec in PNJ:
        placer_pnj(spec)
    fragment_chemin = os.path.join(JEU, "art", "manifestes", "quetes.json")
    fragment = lire(fragment_chemin)
    for objet in OBJETS:
        fragment.setdefault("images", {})["objet_" + objet["id"]] = {"fichier": f"objets/{objet['id']}.svgt", "ancre": [22, 22]}
    for spec in PNJ:
        fragment.setdefault("pnj", {})[spec["pnj"]["id"]] = spec["art"]
    ecrire(fragment_chemin, fragment)
    print(f"lot 2 : {len(QUETES)} quêtes, {len(OBJETS)} objets, {len(PNJ)} PNJ")


if __name__ == "__main__":
    main()
