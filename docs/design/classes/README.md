# Fiches de conception des classes

Fiches de travail créées le 15/11/2026, fil « Concevoir les classes du jeu ». Chaque fiche liste ce qui est
déjà conçu et ce qui manque, d'après le **gabarit commun** (GDD § 4.3) :

- 20 sorts par classe, en **deux Voies de 10 sorts** jouables en même temps (Arcaniste : 12 sorts + 8 utilitaires) ;
- par Voie : **1 signature, 4 dégâts, 2 contrôle, 1 mobilité, 1 défense ou soin, 1 soutien** (écart de 1 ou 2 accepté) ;
- chaque sort : 5 rangs, +10 % par rang pour les sorts à valeurs, effet propre aux rangs 3 et 5 ;
- **un passif de classe** hors des 20 sorts, débloqué à Apprenti, 5 rangs ;
- 3e Voie Lumière ou Ténèbres (10 sorts) seulement si elle est validée.

Valeurs actuelles des sorts : [CLASSES.md](../../CLASSES.md) (généré). Une fois une fiche validée, elle est
reportée dans le GDD § 4.3, puis codée sur demande.

| Ordre | Classe | Voies | Sorts conçus | À concevoir |
|:-:|---|---|:-:|:-:|
| 1 | [Guerrier](guerrier.md) | Acier / Impie | 7 | 13 + passif |
| 2 | [Rôdeur](rodeur.md) | Acier / Flamme | 5 | 15 + passif |
| 3 | [Théologue](theologue.md) | Sacré / Flamme | 5 | 15 + passif |
| 4 | [Chronomancien](chronomancien.md) | Impie / Givre | 6 | 14 + passif |
| 5 | [Arcaniste](arcaniste.md) | Flamme + Givre + Tempête (une Voie) | 12 | 8 + passif |
| 6 | [Myrmidon](myrmidon.md) | Acier / Givre | 0 | 20 + passif |
| 7 | [Paladin](paladin.md) | Sacré / Tempête | 0 | 20 + passif |
| 8 | [Ombre](ombre.md) | Tempête / Acier | 0 | 20 + passif |
| 9 | [Démoniste](demoniste.md) | Impie / Flamme | 0 | 20 + passif |
| | **Total** | | **35** | **145 + 9 passifs** |

Rappel des éléments : Acier → Force, Flamme → Intelligence, Givre → Perception, Tempête → Agilité,
Sacré → Force + Intelligence, Impie → Agilité + Perception. Répartition à terme : Acier 4 classes,
Flamme 4, Impie 3, Tempête 3, Givre 3, Sacré 2 ; chaque caractéristique est jouée par 6 classes.
