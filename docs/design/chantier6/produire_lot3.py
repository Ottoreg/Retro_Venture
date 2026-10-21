"""Chantier 6, lot 3 : quêtes secondaires des zones de départ (conception : ../chantier6_quetes.md § 4).

    python3 docs/design/chantier6/produire_lot3.py      (depuis la racine du dépôt)

Écrit les 15 quêtes secondaires (5 par zone de départ) dans game/data/quetes. Ouvertes à tous les
camps une fois un tutoriel terminé ; récompense de 3 combats de référence. Relancer le script
réécrit ces fichiers.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from produire_lot2 import JEU, ecrire, quete  # noqa: E402

TUTORIELS = ["brumerive_tutoriel", "crasse_roc_tutoriel", "sylvebrume_tutoriel"]


def ecus(niveau):
    """Cinq fois le butin moyen en brumes d'un monstre du niveau (voir balance.py)."""
    return round(5 * (2 + 1.2 * niveau))


def secondaire(id, nom, niveau, pnj, etapes, dialogues, description, objets=None):
    recompenses = {"xp_cr": 3, "ecus": ecus(niveau)}
    if objets:
        recompenses["objets"] = [{"objet": o, "nombre": 1} for o in objets]
    return quete(id, nom, "secondaire", niveau, pnj, etapes, dialogues, recompenses,
                 conditions={"niveau_min": max(1, niveau - 1), "une_quete_terminee": TUTORIELS},
                 description=description)


def apporter(objet, nombre, pnj, monstres, taux=0.5):
    return {"type": "apporter", "objet": objet, "nombre": nombre, "pnj": pnj, "butin": {"monstres": monstres, "taux": taux}}


QUETES = [
    # --- Brumerive ---
    secondaire("brumerive_moutons_d_alric", "Les moutons d'Alric", 2, "alric_le_berger",
               [[{"type": "vaincre", "monstre": "loup_des_collines", "nombre": 5},
                 apporter("peau_de_loup", 3, "alric_le_berger", ["loup_des_collines", "loup_alpha"])]],
               {"alric_le_berger": {
                   "proposition": ["Les loups mangent mes moutons. Il m'en reste quatre. Enfin, trois et demi.",
                                   "Chassez-en cinq, et rapportez-moi trois peaux : je ferai des manteaux aux moutons qui restent. Ils ont froid, depuis qu'ils ont peur."],
                   "en_cours": ["Les loups rôdent encore. Mes moutons dorment avec un œil ouvert. C'est mauvais pour leur laine."],
                   "fin": ["Trois peaux ! Mes moutons auront des manteaux en loup. Ça devrait faire réfléchir les autres loups."]}},
               "Les loups des collines dévorent le troupeau d'Alric, mouton après mouton."),
    secondaire("brumerive_pret_du_berger", "Le prêt du berger", 3, "gobillon_l_ermite",
               [[{"type": "parler", "pnj": "alric_le_berger", "texte": "Réclamer les trois pièces à Alric"}],
                [{"type": "parler", "pnj": "bernardin_tourneboule", "texte": "Réclamer les trois pièces au meunier"}],
                [{"type": "parler", "pnj": "gobillon_l_ermite"}]],
               {"gobillon_l_ermite": {
                   "proposition": ["Mon prêêêt… Il m'a jamais rendu mon prêt, le berger ! Trois pièces. Trois ! Allez les lui réclamer."],
                   "en_cours": ["Alors, mes trois pièces ? Je les compte tous les soirs. Enfin, je compte qu'elles me manquent."],
                   "fin": ["Le meunier dit que je les ai dans ma poche ? … Ah. Ah oui. Trois pièces. Bon. Gardez ça pour la peine, je n'en ai plus besoin : je les ai retrouvées."]},
                "alric_le_berger": {
                   "objectif": ["Le prêt de Gobillon ? Je l'ai rendu ! Au meunier, qui devait le lui rendre. Allez voir Bernardin, au moulin."]},
                "bernardin_tourneboule": {
                   "objectif": ["Les trois pièces d'Alric ? Je les ai rendues à Gobillon le jour même. Il les a mises dans sa poche. La gauche."]}},
               "Gobillon réclame trois pièces prêtées au berger. Il y a longtemps. Peut-être."),
    secondaire("brumerive_moulin", "Le moulin de Tournevent", 5, "bernardin_tourneboule",
               [[{"type": "vaincre", "monstre": "gobelin_frondeur", "nombre": 4},
                 {"type": "recolter", "objet": "bois_de_frene", "nombre": 4}],
                [{"type": "parler", "pnj": "bernardin_tourneboule"}]],
               {"bernardin_tourneboule": {
                   "proposition": ["Les frondeurs gobelins visent les ailes de mon moulin. Ils marquent des points. Ils ont un tableau.",
                                   "Chassez-en quatre, et rapportez-moi du bois de frêne pour réparer les ailes. Mon moulin tourne au vent, pas aux cailloux."],
                   "en_cours": ["Un caillou de plus et mon moulin tournera en rond. Enfin, plus en rond que d'habitude."],
                   "fin": ["Des ailes neuves ! Le moulin tourne, le vent tourne, et moi je tourne… autour du tableau des frondeurs. Ils étaient à 312 points."]}},
               "Les frondeurs gobelins prennent les ailes du moulin pour cible."),
    secondaire("brumerive_fausse_fiche", "Fausse fiche de présence", 6, "grizzik_le_deserteur",
               [[apporter("fiche_de_paie_gobeline", 3, "grizzik_le_deserteur", ["gobelin_frondeur", "frondeur_veteran"])]],
               {"grizzik_le_deserteur": {
                   "proposition": ["Psst ! Officiellement, je suis en train de piller un verger. Officieusement, je fais la sieste ici.",
                                   "Si le contremaître contrôle, il me faut une fiche de présence. Rapporte-moi trois fiches de paie des frondeurs : je recopie la signature."],
                   "en_cours": ["Chut ! Les fiches. Et ne dis à personne que tu m'aides. Surtout pas aux humains. Ni aux gobelins."],
                   "fin": ["Parfait. « Grizzik, présent au raid, très courageux, prime méritée. » Ça sonne bien. Je me ferais presque peur."]}},
               "Grizzik, gobelin « en pause », a besoin de prouver qu'il travaille."),
    secondaire("brumerive_greve_des_epouvantails", "La grève des épouvantails", 8, "fermier_gaudin",
               [[{"type": "vaincre", "monstre": "epouvantail_demotive", "nombre": 4},
                 apporter("paille_ensorcelee", 3, "fermier_gaudin", ["epouvantail_demotive", "grand_epouvantail"])],
                [{"type": "parler", "pnj": "grizzik_le_deserteur", "texte": "Demander conseil à Grizzik, expert en grève"}]],
               {"fermier_gaudin": {
                   "proposition": ["Les épouvantails se sont mis en grève. Ils disent qu'on ne les paie pas. On ne les a jamais payés ! Ce sont des épouvantails !",
                                   "Calmez-en quatre et rapportez-moi leur paille ensorcelée : sans elle, ils redeviennent des épouvantails normaux. Qui ne font rien. Comme avant, quoi."],
                   "en_cours": ["Ils ont fait un piquet de grève. Avec un piquet. Ils ont toujours eu un piquet, remarquez."],
                   "objectif": ["Merci ! Mais ils vont recommencer. Le gobelin des champs de l'est, Grizzik, s'y connaît en grèves. Demandez-lui."]},
                "grizzik_le_deserteur": {
                   "fin": ["Des épouvantails en grève ? Ils ont raison ! Dis au fermier de leur offrir un syndicat. Ça ne coûte rien et ça les occupe des années.",
                           "Moi, j'ai un syndicat depuis trois ans. Je n'ai rien obtenu, mais j'ai des réunions."]}},
               "Les épouvantails de la Lande refusent de travailler. Gaudin ne sait plus quoi faire.",
               objets=["chapeau_d_epouvantail"]),

    # --- Crasse-Roc ---
    secondaire("crasse_roc_dentier", "Le dentier de Mamie Ratine", 2, "mamie_ratine",
               [[{"type": "vaincre", "monstre": "rat_des_galeries", "nombre": 6},
                 apporter("dent_de_rat", 4, "mamie_ratine", ["rat_des_galeries", "rat_roi"])]],
               {"mamie_ratine": {
                   "proposition": ["Avant, j'élevais des rats pour les courses. Puis les rats ont gagné, et ils sont partis avec mon dentier.",
                                   "Rapporte-moi quatre dents de rat. Je m'en ferai un nouveau. Ce sera plus pointu, mais on s'habitue."],
                   "en_cours": ["Fans dentier, ve ne peux pas manver la foupe. Ve la bois."],
                   "fin": ["Quatre dents ! Avec un peu de colle et beaucoup de courage… Voilà. Je souris. Ne me regarde pas trop, c'est encore frais."]}},
               "Mamie Ratine a perdu son dentier. Les rats l'ont gagné aux courses."),
    secondaire("crasse_roc_guano_culture", "Guano-culture", 5, "gnark_guanoculteur",
               [[{"type": "vaincre", "monstre": "vampipistrelle", "nombre": 5},
                 apporter("guano_luisant", 5, "gnark_guanoculteur", ["vampipistrelle", "vampipistrelle_comtesse"])]],
               {"gnark_guanoculteur": {
                   "proposition": ["Le guano de vampipistrelle, c'est de l'or ! De l'or qui sent mauvais, mais de l'or.",
                                   "Grumm prend tout ce que je récolte. Aide-moi à me faire une réserve perso : cinq guanos luisants. Personne n'ira voler un tas de guano."],
                   "en_cours": ["Le puits, c'est par là. Tu le trouveras à l'odeur."],
                   "fin": ["Cinq ! Ma réserve perso. Ma retraite, en quelque sorte. Elle sent fort, mais elle est à moi."]}},
               "Gnark veut une réserve de guano à lui, loin des griffes de Grumm."),
    secondaire("crasse_roc_galerie_effondree", "La galerie effondrée", 5, "zogrub_troc_tout",
               [[{"type": "aller", "carte": "crasse_roc_1_1", "texte": "Aller à la galerie effondrée"},
                 {"type": "vaincre", "monstre": "grouilleur", "nombre": 3},
                 {"type": "recolter", "objet": "minerai_de_cuivre", "nombre": 4}],
                [{"type": "parler", "pnj": "zogrub_troc_tout"}]],
               {"zogrub_troc_tout": {
                   "proposition": ["Psst ! J'avais un stock dans la galerie effondrée. Un stock qui n'existe pas, officiellement. Elle s'est effondrée dessus.",
                                   "Va voir s'il reste quelque chose, chasse les grouilleurs qui s'y sont installés, et mine un peu de cuivre pour étayer. Je paie en liquide. Enfin, en brumes."],
                   "en_cours": ["Mon stock qui n'existe pas t'attend. Ne pose pas de questions, surtout à toi-même."],
                   "fin": ["Étayé ! Mon stock est sauf. Tu n'as rien vu. Moi non plus. Tiens, pour ton silence et ton cuivre."]}},
               "Zogrub avait un stock dans une galerie qui s'est effondrée. Un stock qui n'existe pas."),
    secondaire("crasse_roc_preavis_de_grizzlok", "Le préavis de Grizzlok", 8, "grizzlok_le_pacifiste",
               [[{"type": "parler", "pnj": "contremaitre_grumm", "texte": "Porter le préavis de Grizzlok à Grumm"}],
                [{"type": "vaincre", "monstre": "milicien_de_hautepierre", "nombre": 3},
                 {"type": "parler", "pnj": "grizzlok_le_pacifiste", "texte": "Rapporter la réponse de Grumm à Grizzlok"}]],
               {"grizzlok_le_pacifiste": {
                   "proposition": ["J'ai rédigé un préavis de grève. Pacifique. Avec des fleurs dessinées dans la marge.",
                                   "Porte-le à Grumm, à l'entrée des galeries. Et rapporte-moi sa réponse. Attention, sur le chemin du retour, la milice patrouille."],
                   "en_cours": ["Alors, il l'a lu ? Il a vu les fleurs ?"],
                   "fin": ["Un préavis de licenciement en réponse à mon préavis de grève ? … C'est un dialogue social. C'est un début."]},
                "contremaitre_grumm": {
                   "objectif": ["Un préavis de grève ? Avec des fleurs ? Tiens, rapporte-lui ma réponse : un préavis de licenciement. Avec des épines."]}},
               "Grizzlok veut faire grève, pacifiquement. Il lui faut un messager."),
    secondaire("crasse_roc_peage_de_zibeline", "Le péage de Zibeline", 11, "zibeline_la_peagere",
               [[{"type": "vaincre", "monstre": "contremaitre_zele", "nombre": 4},
                 apporter("sifflet_de_contremaitre", 3, "zibeline_la_peagere", ["contremaitre_zele", "contremaitre_en_chef"])]],
               {"zibeline_la_peagere": {
                   "proposition": ["Péage ! Deux brumes pour passer. Sauf que les contremaîtres zélés ont installé leur propre péage, juste devant le mien.",
                                   "Ils taxent mon péage ! Chasse-en quatre et rapporte-moi leurs sifflets : sans sifflet, un contremaître n'est qu'un gobelin qui crie."],
                   "en_cours": ["Ils sifflent encore. Chaque coup de sifflet, c'est une brume qui m'échappe."],
                   "fin": ["Trois sifflets ! Mon péage est à nouveau le seul péage. Pour te remercier, tu passes gratuitement. Aujourd'hui. Avant midi."]}},
               "Sur la Route des Charrois, deux péages, c'est un de trop.",
               objets=["amulette_sifflet"]),

    # --- Sylvebrume ---
    secondaire("sylvebrume_champignons_insolents", "Des champignons qui insultent", 2, "tantine_champignolle",
               [[{"type": "vaincre", "monstre": "morille_grincheuse", "nombre": 5},
                 apporter("chapeau_de_morille", 3, "tantine_champignolle", ["morille_grincheuse", "vieille_morille_rancuniere"])]],
               {"tantine_champignolle": {
                   "proposition": ["Celle-là est comestible. Celle-là aussi. Celle-là vous insulte : laissez-la. Enfin, non : prenez-la.",
                                   "Les morilles grincheuses m'ont traitée de vieille souche. Chasse-en cinq et rapporte-moi trois chapeaux. Je ferai une omelette. Une omelette vexée."],
                   "en_cours": ["Elles m'insultent encore. J'entends « vieille souche » jusqu'ici."],
                   "fin": ["Trois chapeaux ! L'omelette sera grincheuse, mais délicieuse. Elle m'insultera un peu en cuisant. C'est le meilleur moment."]}},
               "Les morilles grincheuses insultent Tantine Champignolle. Elle compte en faire une omelette."),
    secondaire("sylvebrume_ode_au_grand_cerf", "L'ode au Grand Cerf", 5, "poete_lyriandel",
               [[apporter("poil_scintillant", 3, "poete_lyriandel", ["cerf_enchante", "grand_cerf"])],
                [{"type": "parler", "pnj": "gardienne_elwyn", "texte": "Faire lire l'ode à Elwyn"}],
                [{"type": "parler", "pnj": "poete_lyriandel"}]],
               {"poete_lyriandel": {
                   "proposition": ["J'écris une ode au Grand Cerf. Quatre cents strophes. Il en manque une. La plus importante : celle sur son pelage.",
                                   "Rapporte-moi trois poils scintillants des cerfs enchantés. L'inspiration, ça se touche."],
                   "en_cours": ["Sans poil, pas de strophe. Sans strophe, pas d'ode. Sans ode, pas de poète. C'est grave."],
                   "objectif": ["L'inspiration ! Voilà : « Ô pelage d'argent… ». Porte l'ode à Elwyn. Elle est critique. Sévère, mais juste. Surtout sévère."],
                   "fin": ["« Trop courte » ? Quatre cents strophes, trop courte ? Elle a raison. J'en écris quatre cents autres. Merci !"]},
                "gardienne_elwyn": {
                   "objectif": ["Une ode de Lyriandel ? Quatre cents strophes… Je l'ai lue en diagonale. En trois jours. C'est trop court. Dis-le-lui."]}},
               "Le poète Lyriandel cherche l'inspiration. Dans le pelage des cerfs."),
    secondaire("sylvebrume_dette_de_vieux_branchu", "La dette de Vieux-Branchu", 8, "druide_feuillemorte",
               [[{"type": "vaincre", "monstre": "bucheron_de_brumerive", "nombre": 3},
                 apporter("copeaux_de_bois", 5, "druide_feuillemorte", ["bucheron_de_brumerive", "abatteur_en_chef"])]],
               {"druide_feuillemorte": {
                   "proposition": ["Vieux-Branchu avait mille ans. Il me devait de l'argent. Je veux lui faire une stèle quand même : je suis rancunier, pas ingrat.",
                                   "Rapporte-moi cinq poignées de copeaux de bois des bûcherons. Ce sont ses copeaux. Il les reconnaîtra."],
                   "en_cours": ["Des copeaux de Vieux-Branchu. Les bûcherons en ont plein les poches."],
                   "fin": ["Une stèle en copeaux. « À Vieux-Branchu, mille ans, toujours débiteur. » Il aurait aimé. Il aurait surtout aimé ne pas payer."]}},
               "Feuillemorte veut une stèle pour Vieux-Branchu, l'arbre millénaire qu'on a coupé."),
    secondaire("sylvebrume_rapport_d_eclaireuse", "Rapport d'éclaireuse", 10, "eclaireuse_sylphine",
               [[{"type": "aller", "carte": "sylvebrume_2_1", "texte": "Observer la Scierie de Brumerive"},
                 {"type": "aller", "carte": "sylvebrume_1_2", "texte": "Observer les Toiles grises"},
                 {"type": "vaincre", "monstre": "tisseuse_de_brume", "nombre": 3}],
                [{"type": "parler", "pnj": "eclaireuse_sylphine"}]],
               {"eclaireuse_sylphine": {
                   "proposition": ["Je dois rendre un rapport au conseil sur la scierie humaine et les toiles grises. Mais je déteste les deux.",
                                   "Va observer à ma place, chasse quelques tisseuses au passage, et reviens me raconter. J'écrirai que j'y étais."],
                   "en_cours": ["Alors ? La scierie scie ? Les toiles tissent ? Le conseil veut des détails. Pas trop, il délibère lentement."],
                   "fin": ["Une scierie qui scie, des toiles grises de plus en plus grises… Parfait, ça fera un rapport de trois lignes. Le conseil en délibérera un siècle."]}},
               "L'éclaireuse Sylphine doit faire un rapport. Elle préférerait que quelqu'un d'autre regarde."),
    secondaire("sylvebrume_fil_de_brume", "Du fil de brume", 11, "lindore_feuille_d_argent",
               [[{"type": "vaincre", "monstre": "tisseuse_de_brume", "nombre": 3},
                 apporter("fil_de_brume", 4, "lindore_feuille_d_argent", ["tisseuse_de_brume", "grande_tisseuse"])]],
               {"lindore_feuille_d_argent": {
                   "proposition": ["Je couds une robe de saison. La saison dure un siècle : il faut qu'elle tienne.",
                                   "Il me faut quatre fils de brume, pris aux tisseuses. Leur fil est le seul qui ne se démode pas en moins de cent ans."],
                   "en_cours": ["La robe attend son fil. Elle n'est pas pressée : elle a un siècle devant elle."],
                   "fin": ["Quatre fils de brume ! La robe sera prête dans dix ans. Juste à temps pour le début de la saison. Tiens, une cape de chute de tissu."]}},
               "Lindorë coud une robe de saison. Il lui faut un fil qui dure.",
               objets=["cape_de_soie_grise"]),
]


def main():
    for q in QUETES:
        ecrire(os.path.join(JEU, "data", "quetes", q["id"] + ".json"), q)
    print(f"lot 3 : {len(QUETES)} quêtes secondaires")


if __name__ == "__main__":
    main()
