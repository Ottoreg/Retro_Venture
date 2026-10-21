"""Rééquilibre les ressources de récolte des zones de départ (après le lot Métiers).

    python3 src/recolte_zones.py      (depuis docs/design/chantier3_brouillon)

Sylvebrume n'avait presque pas de minerai (1 cuivre, 1 étain, aucun fer) et Crasse-Roc presque pas
de bois (1 frêne, ni chêne ni if) : chaque zone de départ doit permettre de monter chaque métier de
récolte jusqu'au palier suivant. La zone garde son caractère (Sylvebrume reste boisée, Crasse-Roc
minière) ; les ressources de bas niveau vont vers l'entrée de la zone, celles de niveau 8 (if, étain)
là où il y en a déjà. Nombres totaux voulus par carte ; même méthode que `metiers_production.poser`
(un nœud remplace un arbre ou un rocher à portée, sinon une case libre sans couper de chemin).
Relancer le script ne double rien.
"""
from metiers_production import poser

VOULUS = {
    # Sylvebrume : cuivre à l'entrée, fer au milieu, étain vers le sud.
    "sylvebrume_0_0": {"U": 2},
    "sylvebrume_0_1": {"U": 2},
    "sylvebrume_1_0": {"U": 1, "I": 1},
    "sylvebrume_1_1": {"I": 2},
    "sylvebrume_2_0": {"I": 1},
    "sylvebrume_2_1": {"I": 1, "T": 1},
    "sylvebrume_1_2": {"T": 1},
    "sylvebrume_2_2": {"T": 2},
    # Crasse-Roc : frêne et chêne là où poussent déjà quelques arbres, if vers les cartes de niveau 8.
    "crasse_roc_0_0": {"F": 2, "C": 1},
    "crasse_roc_1_0": {"F": 1, "C": 2},
    "crasse_roc_1_1": {"C": 1, "Y": 1},
    "crasse_roc_0_2": {"C": 1, "Y": 1},
    "crasse_roc_2_1": {"Y": 1},
}

if __name__ == "__main__":
    poser(VOULUS)
