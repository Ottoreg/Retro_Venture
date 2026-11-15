# Guerrier — Acier / Impie

**État** : Voie Acier presque complète (7 sorts sur 10, rangs 3 et 5 écrits) ; Voie Impie et passif à concevoir.

## Identité

- Rôle : mêlée polyvalente, encaisse et rend les coups. Famille corps à corps.
- Fantaisie : *« Au contact, il encaisse et rend les coups. Réfléchit après, de préférence. »*
  Voie Impie (décidée le 15/11/2026) : **chevalier maudit**.
- Caractéristiques : Force (Acier) ; Agilité + Perception (Impie).
- Base : 60 PV, 6 PA, 3 PM, initiative 100.

## Passif de classe — à concevoir

Pistes (TODO, « Identité des classes ») :
- *Rancune* (jauge) : chaque coup reçu en donne (ex. 1 pour 5 PV perdus, 10 au plus) ; certains sorts la dépensent.
- *Élan* : chaque case parcourue dans le tour donne +X % au prochain coup de mêlée.
- *Défi* : un ennemi défié qui frappe le Guerrier prend un contrecoup, s'il frappe un autre il prend un malus
  (base de la provocation du Myrmidon).

À trancher : lequel, son effet par rang (1 à 5), et comment il sert aussi la Voie Impie.

## Voie Acier (7 / 10)

| Sort | Rôle | Base | Rang 3 | Rang 5 |
|---|---|---|---|---|
| Charge | Signature | 3 PA, 2–4 en ligne, fonce au contact, 6–9 Acier, relance 2 | +1 portée | relance 1 |
| Frappe | Dégâts de base | 3 PA, mêlée, 8–12 Acier, 2/tour | +5 % critique | −1 PM à la cible |
| Lancer de hache | Dégâts à distance | 4 PA, 2–5, 6–9 Acier | +1 portée | 3 PA |
| Tourbillon | Dégâts en zone | 4 PA, autour de soi, 7–10 Acier | poussée 1 | zone 2 |
| Fendoir | Gros coup | 5 PA, mêlée, 16–22 Acier | +5 % critique | 4 PA |
| Second souffle | Défense / soin | 2 PA, soin 12–18, relance 3 | relance 2 | + bouclier 9–14 |
| Cri de guerre | Soutien | 3 PA, +4–6 Dommages aux alliés à 2 cases, relance 4 | relance 3 | zone 3 |

Il manque **3 sorts** :
- [ ] Contrôle 1 (placement ou entrave au contact)
- [ ] Contrôle 2
- [ ] Mobilité (Charge est la signature ; un saut, un bond ou un repli)

À vérifier : un des 4 sorts de dégâts doit se combiner avec Charge (ou avec le passif choisi).

## Voie Impie — chevalier maudit (0 / 10)

- [ ] Signature (mécanique propre à la Voie)
- [ ] Dégâts de base pas cher
- [ ] Dégâts à distance ou en zone
- [ ] Gros coup cher
- [ ] Dégâts qui se combinent avec la signature
- [ ] Contrôle 1
- [ ] Contrôle 2
- [ ] Mobilité
- [ ] Défense ou soin (modeste)
- [ ] Soutien utile en solo

Pistes à discuter (non validées) : sacrifice de PV pour plus de dégâts (mécanique prévue au GDD), vol de vie
(effet `vol` déjà codé), malédictions qui s'aggravent au contact, entrave au contact (idée « chevalier noir »
de la 3e Voie Ténèbres). Ne pas recouper le Démoniste Impie (invocations) ni le Chronomancien Impie (horloge).

## 3e Voie (si validée)

Proposition : Ténèbres (chevalier noir, lames d'ombre) ; contre-proposition : Lumière (champion radieux,
frappes qui éblouissent, aura qui révèle les invisibles). Moins logique depuis la Voie Impie : à revoir.

## Mécaniques à coder (selon les choix)

Jauge de classe (Rancune), provocation (Défi), sacrifice de PV.

## À faire

- [ ] Choisir le passif et ses 5 rangs
- [ ] 3 sorts Acier
- [ ] 10 sorts Impie avec rangs 3 et 5
- [ ] Vérifier le jeu en solo et que les deux Voies se jouent différemment
