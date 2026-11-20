# Ombre — Tempête / Acier

**État** : conçue avec l'auteur et **codée le 20/11/2026** (GDD § 4.3, fil « Ajouter la classe Ombre au jeu »,
`game/tests/core/test_ombre.gd`). Valeurs (dégâts, rangs 3 et 5 des maîtrises) provisoires.

## Identité

- Rôle : assassin. Fantaisie : « Assassin à la pige de la Confrérie des Ombres (cotisation non remboursable). Frappe dans le dos et repart avant l'addition. »
- Tenue noire à liseré argent ; toutes les races.
- Base commune à toutes les classes : 50 PV, 6 PA, 3 PM, 100 d'initiative.
- Caractéristiques : Agilité (Tempête), Force (Acier).

## Passif de classe — Coup en traître (Apprenti, 5 rangs)

Débloqué au palier Apprenti. +6 % de dégâts (+1 % par rang) quand elle est invisible, ou pendant le tour où elle sort de l'invisibilité ou du Monde des ombres. Rang 3 : son premier sort de ce tour coûte 1 PA de moins. Rang 5 : +1 PM à sa sortie.

## Voie Tempête — images rémanentes (10 / 10)

Survoltage pose une image sur sa case (une fois par tour) ; chaque sort de mobilité de la Voie en laisse une à son
départ. 3 images au plus (la 4e fait exploser la plus ancienne), empilables, ne bloquent rien ; un ennemi au contact
les fait exploser, sinon elles explosent au début du tour suivant de l'Ombre (croix d'une case, ennemis seulement).

| Sort | PA | Portée | Effet |
|---|---|---|---|
| Survoltage | 2 | 0–0 | Se dédouble en un éclair : une image d'elle-même, faite de foudre, reste sur sa case et explose au contact d'un ennemi (ou au bout d'un tour). |
| Lame-éclair | 3 | 1–1 | Un coup de lame si rapide que la victime entend le tonnerre après. |
| Shuriken d'orage | 3 | 2–6 | Une étoile chargée d'électricité qui ricoche sur un deuxième ennemi. |
| Coup de tonnerre | 5 | 1–1 | Toute la foudre accumulée, d'un seul coup. Bruyant, mais efficace. |
| Court-circuit | 2 | 1–8 | Fait exploser tout de suite ses images sur la case visée, plus fort que d'habitude. |
| Rafale | 3 | 1–3 | Un coup de vent électrique qui renvoie l'ennemi d'où il vient. |
| Foudroiement | 3 | 2–5 | Traverse la ligne comme un éclair, en blessant tous les ennemis sur son passage, et laisse une image à son point de départ. |
| Pas de l'éclair | 2 | 1–4 | Disparaît dans un flash et réapparaît un peu plus loin ; une image reste à sa place. |
| Corps électrique | 2 | 0–0 | Une peau crépitante qui absorbe les coups. |
| Vent porteur | 2 | 0–4 | Un vent dans le dos pour elle ou un allié : plus vite, plus agile. |

## Voie Acier — invisibilité (10 / 10)

Invisible : ni vue ni visée directement (une zone la touche), ni taclée ni tacleuse ; un sort de dégâts non discret
la révèle. L'IA l'ignore et, s'il ne reste qu'elle, la cherche à sa dernière position connue.

| Sort | PA | Portée | Effet |
|---|---|---|---|
| Fondu au noir | 2 | 0–0 | Elle disparaît. Personne ne sait où elle est, pas même son percepteur. |
| Surin | 3 | 1–1 | Le petit couteau de tous les jours. Bien plus douloureux quand on ne l'a pas vu venir. |
| Lame de jet | 3 | 2–5 | Une lame lancée de loin, pour ceux qui n'aiment pas les mains sales. |
| Exécution | 5 | 1–1 | Le coup de grâce : d'autant plus fort que la cible est affaiblie. |
| Arme d'obscurité | 3 | 1–5 | Cache une lame d'ombre dans l'ombre d'un ennemi : elle le suit et frappe au début de son prochain tour. Ne révèle pas l'Ombre. |
| Coupe-jarret | 2 | 1–1 | Un coup bas derrière le genou : l'ennemi ira moins loin. |
| Entaille | 3 | 1–1 | Une entaille dans l'armure : chaque nouvelle entaille la fragilise un peu plus (3 fois au plus). |
| Dans le dos | 2 | 1–4 | Se glisse derrière l'ennemi visé. Portée 7 sur un ennemi marqué par une arme d'obscurité. |
| Monde des ombres | 2 | 0–4 | Envoie la cible (elle-même, un allié ou un ennemi) dans le Monde des ombres pour 2 tours, ou l'en fait sortir. Sur un ennemi : relance dans 2 tours. |
| Affûtage | 1 | 0–0 | Elle aiguise ses lames : +20 Force, cumulable 3 fois. |

## Monde des ombres

Dimension parallèle sur la même carte : seules les entités d'une même dimension interagissent. Envoyé = 2 tours ;
sans Ombre dedans, tout le monde sort au bout d'un tour. Entrée ou sortie sur une case occupée : échange de place
(l'autre est aspiré) ; à la sortie, retour impossible 2 tours (1 pour une Ombre). Vu de dehors, une ombre projetée
quand une entité de la dimension lance un sort ; vu de dedans, lueurs anonymes sur les cases occupées dehors,
filtre sombre sur l'écran. Glyphes, pièges et images restent dans la dimension de leur lanceur ; l'arme d'obscurité
suit sa cible. Le combat ne finit que quand tout un camp est mort, ombres comprises.

## Plus tard

- Multijoueur : le serveur ne cache pas encore aux adversaires ce qu'ils ne voient pas (invisible, dimension).
- Boss non envoyables dans les ombres : au cas par cas.
- Animations propres (PixelLab) ; en attendant les sorts jouent l'attaque de la race.
- 3e Voie éventuelle : Lumière ou Ténèbres.
