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
| 1 | [Guerrier](guerrier.md) | Acier / Impie | 20 + passif | — (codé) |
| 2 | [Rôdeur](rodeur.md) | Acier / Flamme | 5 | 15 + passif |
| 3 | [Théologue](theologue.md) | Sacré / Flamme | 20 + passif | — (codé) |
| 4 | [Chronomancien](chronomancien.md) | Impie / Givre | 20 + passif | — (codé) |
| 5 | [Arcaniste](arcaniste.md) | Flamme + Givre + Tempête (une Voie) | 20 + passif | — (codé) |
| 6 | [Myrmidon](myrmidon.md) | Acier / Givre | 20 + passif | — (codé) |
| 7 | [Paladin](paladin.md) | Sacré / Tempête | 20 + passif | — (codé) |
| 8 | [Ombre](ombre.md) | Tempête / Acier | 20 + passif | — (codée) |
| 9 | [Démoniste](demoniste.md) | Impie / Flamme | 20 + passif | — (codé, passif à revoir) |
| | **Total** | | **165 + 8 passifs** | **15 + 1 passif** |

Rappel des éléments : Acier → Force, Flamme → Intelligence, Givre → Perception, Tempête → Agilité,
Sacré → Force + Intelligence, Impie → Agilité + Perception. Répartition à terme : Acier 4 classes,
Flamme 4, Impie 3, Tempête 3, Givre 3, Sacré 2 ; chaque caractéristique est jouée par 6 classes.
