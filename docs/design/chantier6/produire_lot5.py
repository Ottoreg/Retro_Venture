"""Chantier 6, lot 5 : quêtes secondaires de Hautepierre (conception : ../chantier6_quetes.md § 7).

    python3 docs/design/chantier6/produire_lot5.py      (depuis la racine du dépôt)

Écrit les 3 quêtes secondaires de Hautepierre dans game/data/quetes. Comme celles des zones de
départ : ouvertes à tous les camps une fois un tutoriel terminé, récompense de 3 combats de
référence. Relancer le script réécrit ces fichiers.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from produire_lot2 import JEU, ecrire  # noqa: E402
from produire_lot3 import apporter, secondaire  # noqa: E402

QUETES = [
    secondaire("hautepierre_la_releve", "La relève", 16, "capitaine_perenne",
               [[{"type": "parler", "pnj": "sergent_mordicus", "texte": "Proposer la relève au Sergent Mordicus"},
                 {"type": "parler", "pnj": "sergente_brisetout", "texte": "Proposer la relève à la Sergente Brisetout"},
                 {"type": "parler", "pnj": "veteran_clopin", "texte": "Proposer la relève à Clopin, le vétéran"}],
                [{"type": "parler", "pnj": "capitaine_perenne", "texte": "Rendre compte au Capitaine Pérenne"}]],
               {"capitaine_perenne": {
                   "proposition": ["Trois cents ans de garde. Je ne me plains pas. Mais le règlement dit : « relève toutes les quatre heures ». J'ai un peu de retard.",
                                   "Trouvez-moi une relève. Le Sergent Mordicus, à la Porte de l'Ouest, la Sergente Brisetout, à la Porte de l'Est, ou ce vieux Clopin, aux Champs du Pèle-Ennemi. N'importe qui de vivant. Ou de mort, je ne suis pas difficile."],
                   "en_cours": ["Alors, ma relève ? Je l'attends au garde-à-vous. Ça fait trois siècles, je ne suis plus à une heure près."],
                   "fin": ["Personne ? Le premier a trop de travail, la deuxième pas assez de temps, le troisième pas assez de jambes.",
                           "Bon. Je reste. Au fond, je ne saurais pas quoi faire de mes soirées. Merci d'avoir essayé : vous avez le sens du service. Ça se perd."]},
                "sergent_mordicus": {
                   "objectif": ["Relever un fantôme ? Aux Ruines ? Avec les gargouilles ? … Je suis déjà de garde ici. Je garde la porte. Et la porte me garde. On est très liés."]},
                "sergente_brisetout": {
                   "objectif": ["Une garde de trois cents ans ? Non merci. Dites au Capitaine que je prends mon tour dès qu'il aura fini le sien. C'est le règlement."]},
                "veteran_clopin": {
                   "objectif": ["Pérenne ? Il était déjà vieux quand mon grand-père était jeune. Je veux bien le relever, mais il faudrait que je tienne debout. Dites-lui que je suis de cœur avec lui. Assis."]}},
               "Le Capitaine Pérenne, fantôme, monte la garde depuis trois cents ans. Il aimerait une relève."),
    secondaire("hautepierre_recette_du_troll", "La recette du troll", 18, "maitre_ripaille",
               [[apporter("recette_de_troll", 3, "maitre_ripaille", ["troll_des_ponts", "troll_gastronome"], taux=0.35),
                 apporter("dent_de_troll", 3, "maitre_ripaille", ["troll_des_ponts", "troll_gastronome"])]],
               {"maitre_ripaille": {
                   "proposition": ["Les clients réclament la « spécialité du troll ». Moi, je ne sais pas la faire : c'est le troll qui la fait, et c'est le client qui la devient.",
                                   "Rapportez-moi trois recettes de troll, celles qu'ils gardent sur eux, aux Rives du Fleuve Gris ou au Pont des Trolls. Et trois dents de troll : c'est l'ingrédient secret. Le seul, en fait."],
                   "en_cours": ["La soupe du jour attend ses dents. Elle n'est pas pressée, la soupe. Les clients, si."],
                   "fin": ["« Aventurier rôti, trois façons »… « Aventurier en croûte »… « Ragoût de dents, sans aventurier ». Voilà ! Celle-là, je peux la servir.",
                           "Soupe du jour : ragoût de dents de troll. Je vous la déconseille. Voici vos brumes, et un conseil : ne mangez jamais ici."]}},
               "Maître Ripaille veut mettre la « spécialité du troll » à la carte du Heaume Fendu. Sans troll."),
    secondaire("hautepierre_fausses_reliques", "Authentiques fausses reliques", 24, "fulbert_l_authentique",
               [[apporter("cendre_tiede", 5, "fulbert_l_authentique", ["cendrillon", "loup_cendreux", "grouilleur_de_braise", "arbre_calcine"]),
                 apporter("eclat_de_cendre", 1, "fulbert_l_authentique", ["loup_cendreux", "grouilleur_de_braise", "arbre_calcine"], taux=0.3)]],
               {"fulbert_l_authentique": {
                   "proposition": ["Tout le monde ne parle que des Reliques de l'Aube. La demande explose ! L'offre, elle, est… en cours de fabrication.",
                                   "Rapportez-moi cinq cendres tièdes et un éclat de cendre, de la Plaine Cendrée ou d'ailleurs. Avec un peu de colle et beaucoup d'aplomb, ça fera des Reliques garanties d'origine. Une origine. La mienne."],
                   "en_cours": ["Mes clients attendent leurs Reliques. Ils sont très patients : ils ne savent pas encore à quoi ça ressemble."],
                   "fin": ["Magnifique ! Un éclat noir qui brûle sans flamme, posé sur de la cendre tiède… La Relique de la Cheminée ! Authentique !",
                           "Ne le répétez pas à la Garde. Ni à la Chevalière Sans-Rouille, si vous la croisez. Surtout pas à elle : elle sait à quoi ressemblent les vraies."]}},
               "Fulbert l'Authentique prépare une nouvelle collection de Reliques. Il lui manque la matière première."),
]


def main():
    for q in QUETES:
        ecrire(os.path.join(JEU, "data", "quetes", q["id"] + ".json"), q)
    print(f"lot 5 : {len(QUETES)} quêtes secondaires de Hautepierre")


if __name__ == "__main__":
    main()
