# Retro Venture — guide des testeurs (alpha test 1)

Merci de tester ! Retro Venture est un RPG tactique au tour par tour, façon Dofus Rétro, dans un
monde qui parodie gentiment les grandes sagas de fantasy (gobelins syndiqués, elfes snobs, humains
persuadés d'être les héros…). Ce document explique comment jouer, ce qu'il y a à voir et comment
nous faire vos retours. Le jeu n'affiche volontairement presque aucune aide à l'écran : tout est ici.

## L'alpha test 1 en bref

- **Version 0.6.0** (affichée sur l'écran d'accueil).
- **Ce qu'on teste : les mécaniques** (combat, quêtes, exploration, interface, métiers), pas la
  vitesse de progression.
- **Progression en refonte** : plus de niveaux. On progresse par la **pratique** : chaque sort qui
  a un effet réel (dégâts sur un ennemi, soin de PV perdus, bouclier qui absorbe) donne de la
  **réputation** à votre classe (paliers Inconnu, Apprenti, Compagnon…) et fait monter la
  caractéristique de son élément (Acier → Force, Flamme → Intelligence, Givre → Perception, Tempête
  → Agilité) ; les coups reçus font monter la Vitalité. Plus le combat est difficile pour vous, plus
  il rapporte : des monstres trop faibles ne rapportent presque rien. Les quêtes donnent aussi de la
  réputation. Tous les 500 de réputation, un **point de maîtrise** à placer dans un sort (fenêtre
  des sorts, touche S) : chaque rang ajoute 10 % au sort, et le Guerrier a des effets en plus aux
  rangs 3 et 5. Le Guerrier gagne deux sorts de rang II à 5 000 et 15 000 de réputation. Tout objet
  s'équipe sans condition.
- **Pas encore là** : sons et musiques, dessins définitifs (certains personnages et effets sont
  provisoires), multijoueur. L'équilibrage sera revu d'après vos retours.
- À la fin (ou quand vous voulez), **remplissez le questionnaire** : bouton **« Donner son avis »**
  du menu principal ou du menu pause (Échap), ou directement :
  **https://docs.google.com/forms/d/e/1FAIpQLSdwoJr5-OnRuVcVNbvRGnjtO4MqxJTUe7SIIbgfeKJlRuYcxQ/viewform**

## Lancer le jeu

- Dans le navigateur (Chrome, Firefox ou Edge récents, sur ordinateur) :
  **https://ottoreg.github.io/Retro_Venture/**
- La partie est **sauvegardée automatiquement** dans le navigateur (changement de carte, fin de
  combat, retour au menu…). « Continuer » au menu reprend la dernière partie. Vider les données du
  site efface la sauvegarde. Si vous aviez joué à une version précédente, commencez une **nouvelle
  partie**.
- Résolution prévue : 1280 × 720 ou plus. Plein écran dans les options.
- Le bouton **« Jouer en ligne (prototype) »** du menu sert aux essais du multijoueur avec
  l'auteur : il ne marche que pendant ses sessions de test annoncées. L'alpha test 1 se joue en solo.
  En ligne : cliquez sur un autre joueur pour l'inviter dans votre groupe ; les épées dorées sur la
  carte sont le combat d'un joueur en placement, cliquez dessus pour le rejoindre (membres du
  groupe), ou pour le regarder. Cliquez sur un membre du groupe (sur la carte ou dans la bande
  droite) pour le suivre ; sa position et ses repères apparaissent en vert sur la minicarte. Celui
  qui engage un combat peut le fermer ou refuser les spectateurs. L'inventaire se consulte en
  combat. Tours de 30 s. Une connexion coupée se rouvre toute seule, et on retrouve son combat.
  Pour **échanger** avec un joueur de la même carte : clic sur lui (ou sur son pseudo dans
  l'historique), « Échanger avec… ». Chacun met des objets non portés et des brumes ; tout
  changement retire les validations, et « Valider » attend 3 s après le dernier changement.
  L'échange se fait quand les deux ont validé ; Échap l'annule.

## Par où commencer

1. **Créez votre personnage** : une race (Humain, Gobelin ou Elfe : elle fixe votre zone de départ
   et votre camp), une Voie (Guerrier, Rôdeur, Arcaniste ou Théologue) et un nom.
2. **Parlez au personnage marqué d'un « ! »** près de votre point d'arrivée : Alric (humains), Grumm
   (gobelins) ou Elwyn (elfes). Son **tutoriel** vous apprend à vous équiper (touche **I**), à
   combattre, à récolter et à forger.
3. **Suivez la quête principale de votre camp** (acte I, jusqu'au mini-boss de la zone, vers le
   niveau 12), puis partez pour **Hautepierre** (acte II, niveaux 13 à 25) par la porte au bout de
   votre zone ou par la **Pierre de Passage**. L'histoire de l'alpha se termine à la Brèche, contre
   Grondin (niveau 30).
4. En chemin, **5 quêtes secondaires par zone**, ouvertes à tous les camps : allez voir les zones
   des autres peuples.
5. La quête suivie s'affiche en haut à droite ; le journal s'ouvre avec **Q**.

Créer un deuxième personnage d'une autre race ou d'une autre Voie est très utile si vous avez le
temps : chaque camp a sa propre histoire.

## Créer son personnage

- On commence sans équipement, avec 20 brumes : armes et armures viennent du butin, des marchands
  et des artisans. Une race ne donne pas de caractéristiques, seulement un passif et un sort.
- Trois races, chacune avec sa zone de départ et son sort racial :
  - **Humain** (camp allié) : départ à **Brumerive** ; sort *Ralliement* ; passif +10 % d'XP de
    métier.
  - **Gobelin** (camp ennemi) : départ à **Crasse-Roc** ; sort *Coup bas* ; passif *Chapardeur* :
    +20 prospection et +20 % de brumes en fin de combat.
  - **Elfe** (camp neutre) : départ à **Sylvebrume** ; sort *Pas léger* ; passif +1 portée sur les
    sorts à distance.
- Quatre Voies (classes), chacune avec sa mécanique :
  - **Guerrier** : *Charge* (en ligne droite, jusqu'au contact, puis un coup d'épée) ;
  - **Rôdeur** : *Collet*, un piège invisible qui blesse et ralentit le premier ennemi qui y entre ;
  - **Théologue** (soigneur sacré : soin, bouclier, dégâts Sacrés) : *Absolution*, qui retire leurs
    bonus aux ennemis, leurs malus et leurs poisons aux alliés ;
  - **Arcaniste** (kit entièrement nouveau) : *Composition* ouvre une petite grille (au-dessus du
    sort, ou de la souris avec le raccourci) où l'on choisit ses **3 états élémentaires** d'un coup
    (Flamme ou Givre, +4 % de dégâts chacun ; le PA est rendu aussitôt). Avec 3 états,
    *Fusion arcanique* (2 PA) donne un sort selon la combinaison : Flamme ×3 *Fournaise*, Flamme ×2 +
    Givre *Choc thermique*, Givre ×2 + Flamme *Armure de givre*, Givre ×3 *Blizzard* (4 PA chacun).
    Il prend l'une des **deux places** au bout de la barre de sorts (marquées « ? » tant qu'elles
    sont vides) ; un troisième chasse le plus ancien. Les **3 orbes** à côté des PM prennent la
    couleur de vos états (orange : Flamme, bleu : Givre) ; ils s'affichent aussi au survol de
    votre personnage et dans l'historique. On dit
    qu'un troisième élément compléterait la formule…
- Les soins et boucliers grandissent avec la caractéristique de leur élément (soin Sacré : Force et
  Intelligence ; *Second souffle* du Guerrier : Force ; bouclier de l'*Armure de givre* de
  l'Arcaniste : Perception, l'ancienne Chance).

## Commandes

### Exploration

| Action | Comment |
| --- | --- |
| Se déplacer | Clic sur une case (un nouveau clic pendant la marche change de destination) ; au-delà de 3 cases, le personnage court |
| S'asseoir | Bouton « S'asseoir » de la barre du bas, ou touche A : les PV remontent trois fois plus vite ; on se relève en marchant |
| Barre d'objets | Hors combat, la barre du bas montre des emplacements d'objets à la place des sorts : vides pour l'instant, ils accueilleront les consommables (potions, nourriture) quand il y en aura. Les sorts reviennent en combat et se consultent avec S |
| Attaquer un groupe de monstres | Clic sur le groupe : le personnage le rejoint et le combat commence |
| Parler, commercer, fabriquer | Clic sur un PNJ (bulle « … », ou « ! » / « ? » s'il a une quête pour vous) |
| Boutique | Chez un marchand : onglets Acheter / Vendre et **barre de recherche** (un mot du nom ou du type, « botte », « anneau »… sans se soucier des accents) ; un équipement coûte plus cher quand son palier est haut (× 5 au palier 15, × 10 au palier 30) |
| Historique | À gauche de la barre du bas, touche **H** pour le replier : onglet **Combat** (gardé d'un combat à l'autre) et **Commerce** (chaque achat et vente : objet, quantité, marchand, brumes) ; « Tout » mêle les deux |
| Récolter | Clic sur un arbre (bûcheron) ou un rocher à minerai (mineur) |
| Entrer / sortir d'un bâtiment | Clic sur la porte : celles où l'on peut entrer sont marquées au sol d'un losange doré (double chevron) |
| Changer de carte | Clic sur une case du bord marquée d'un halo blanc (la flèche jaune indique la direction) |
| Voyager vers une autre zone | Clic sur la **Pierre de Passage** (pierre levée aux runes bleues, sur un halo bleu au sol), puis choisir la destination (voir plus bas) |
| Voir ce qu'on survole | Passer la souris sur un monstre, un PNJ, une ressource : une bulle s'affiche (pour un groupe : chaque monstre avec son niveau, puis sa **menace** pour vous : négligeable, faible, à votre mesure ou redoutable, et le multiplicateur de vos gains) |

### Fenêtres et raccourcis

| Touche | Fenêtre |
| --- | --- |
| **C** | Personnage : palier et réputation de la classe active, points de maîtrise, caractéristiques (points gagnés / plafond), PA, PM, initiative, prospection ; survoler une valeur montre d'où elle vient (points gagnés, race, chaque objet, panoplie) ; la liste des classes change la classe active hors combat (une nouvelle classe demande 5 000 de réputation dans une autre et repart de zéro) |
| **I** | Inventaire : équipement porté, sac en trois onglets (Équipements, Consommables, Ressources), équiper / retirer / jeter ; **double-clic** sur un objet pour l'équiper ou le retirer (il remplace l'objet porté, ou le même objet déjà porté, comme une seconde bague identique), ou **glisser** du sac vers un emplacement (et inversement) ; tenir **Ctrl** : jets possibles de l'objet choisi ; au **survol** d'un objet, ses bonus comparés à l'objet porté (gains en vert, pertes en rouge) |
| **S** | Sorts : un onglet pour la Voie, la race et l'arme ; fiche de chaque sort ; rang de maîtrise et bouton pour y placer des points |
| **J** | Métiers : un onglet par métier, niveau, ressources et recettes |
| **M** | Carte du monde : toutes les zones sur un seul panneau, molette pour zoomer (voir plus bas) |
| **Q** | Journal des quêtes : en cours (la suivie en tête) et terminées, objectifs, récompenses, « Suivre » |
| **Échap** | Ferme la fenêtre ouverte ; sinon, **menu pause** (le jeu s'arrête) : reprendre, options, menu principal (avec sauvegarde, pas en combat), quitter |

**Options** (menu principal ou menu pause) : volume, plein écran, taille de la fenêtre (hors
navigateur), mode tactique et pions en mode tactique ; elles sont gardées d'une partie à l'autre, hors sauvegarde.

Les six boutons en bas à droite de la barre ouvrent les mêmes fenêtres.

### L'écran

Comme dans Dofus 2, rien ne passe sur la zone de jeu : la carte est entourée de deux **bandes** à
gauche et à droite, et de la barre du bas (historique, jauges, sorts ou objets, menus). La carte est un peu réduite pour laisser la place
aux bandes ; sur un écran plus large, les bandes s'élargissent.

- **Bande gauche** : le nom de la carte en haut, puis la minicarte, puis la quête suivie.
- **Bande droite** : les messages en haut (« À vous de jouer »…) ; dessous, hors combat, votre nom, palier, réputation et brumes ; en combat, l'ordre de jeu.
Les sorts se consultent dans leur fenêtre (S).

### Minicarte et carte du monde

- **Minicarte** (en haut de la bande gauche), comme dans Dofus Rétro : la carte du
  monde en réduit, **5 × 5 cartes autour de vous**, chacune dessinée d'après son plan (sol,
  chemins, eau, arbres, bâtiments). Votre carte est au milieu (cadre doré, point bleu). **Molette**
  : de 3 × 3 à 9 × 9 cartes. **Glisser** : voir plus loin ; un clic vous recentre. Les icônes
  disent ce qu'il y a sur chaque carte : losange bleu, Pierre de Passage ; A atelier, M marchand,
  C coffre, B mini-boss, ! quête à prendre ou à rendre. **Clic droit** sur une carte : un drapeau
  (Maj + clic droit : vos coéquipiers le voient aussi) ; sous la minicarte, une flèche vous indique
  sa direction et sa distance. Survolez une case pour son nom (et, si vous l'avez visitée, le niveau de ses monstres et leur menace pour vous). En haut, le nom de la zone et les
  coordonnées de la carte ; dans une maison, elle montre la carte devant la porte. Un **clic** dessus
  ouvre la carte du monde (hors combat).
- **Carte du monde** (touche **M**, bouton en forme de carte du bandeau, ou clic sur la minicarte) :
  **tout le monde est montré dès le début**, comme dans Dofus, sur un seul panneau : les zones sont
  à leur place les unes par rapport aux autres (Hautepierre au milieu, reliée aux trois zones de
  départ). Elle s'ouvre centrée sur vous ; **molette** : zoom, **glisser** : se déplacer, un bouton
  par zone pour y aller. En haut, la zone survolée et le nombre de cartes que vous y avez visitées.
  Chaque carte est une case avec son nom, à sa place (est à droite, sud en bas), toujours de la même
  forme ; dézoomée, ce sont les noms des zones qui s'affichent. La carte où vous êtes a un **cadre doré**.
  Un losange bleu marque une Pierre de Passage, les mêmes icônes que sur la minicarte le reste ;
  sous la grille, cochez ou décochez chaque sorte d'icône. Clic droit : un drapeau.
  Les maisons n'y figurent pas (depuis une maison, la carte s'ouvre sur sa zone, avec le cadre doré
  sur la carte devant la porte, comptée comme visitée). Survolez une case pour son nom complet et ses coordonnées. Échap
  ferme la carte du monde avant toute autre fenêtre.

### Le bandeau du bas

- **Cœur rouge** : points de vie (il se vide quand on est blessé).
- **Étoile bleue** : points d'action (PA), pour lancer des sorts.
- **Case verte** : points de mouvement (PM), pour se déplacer en combat.
- **Sorts** : une icône par sort, avec son raccourci (1 à 0, ou & é " ' ( - è _ ç à) et son coût en PA.

### Combat (au tour par tour)

1. **Placement** : comme dans Dofus, chaque carte a ses cases de départ, toujours les mêmes, où que
   vous ayez engagé le groupe : deux côtés, un par camp, et le côté de chacun est **tiré au sort** à
   chaque combat (les vôtres en cercles bleus). Cliquez sur un cercle bleu pour choisir votre case, puis **Prêt**. Après le combat, vous
   reprenez l'exploration là où vous avez engagé le groupe.
2. **Votre tour** :
   - se déplacer : clic sur une case verte (1 PM par case) ;
   - lancer un sort : touche **1 à 0** (ou **& é " ' ( - è _ ç à**, sans Maj, sur un clavier AZERTY)
     ou clic sur son icône, puis clic sur la cible (cases bleues : portée ; un second clic sur le
     sort, un **clic droit** ou **Échap** l'annule). En visant, les dégâts et soins prévus
     s'affichent au-dessus de chaque combattant touché (sans coup critique) ;
   - se cibler soi-même : **clic droit sur l'icône du sort** (il part tout de suite sur votre case) ;
   - **enchaîner** : inutile d'attendre la fin des chiffres et des animations, la main revient tout
     de suite. Pendant une marche, les sorts choisis et leurs cibles (marquées en jaune), un
     déplacement ou la fin du tour sont gardés et partent dans l'ordre dès l'arrivée (5 au plus ; un
     clic droit, sans sort choisi, les annule) ;
   - **Fin de tour** : bouton du bandeau.
   - **Mode tactique** : icône en damier gris de la barre de combat ou touche **T** (aussi dans les options ; les
     personnages restent visibles, l'option « Pions en mode tactique » les remplace par des pions).
     Vue simplifiée de la grille, comme dans Dofus : cases à plat en damier, eau en trous (elle ne
     bloque que le passage), obstacles qui bloquent la vue en blocs, arbres et bâtiments masqués,
     combattants en pions de la couleur de leur camp (initiale et PV). Portées, zones, glyphes et
     cases de placement restent affichées. Le choix est retenu d'un combat à l'autre.
   - **ordre de jeu** dans la bande droite : une ligne par combattant, son portrait (bleu : votre
     camp, rouge : l'adversaire ; doré : celui qui joue), son nom et ses PV ;
   - survoler un combattant : son niveau, ses PV, PA, PM et ses résistances s'affichent à la place
     de la barre de sorts ; pour un ennemi, les cases où il peut aller s'affichent en vert (rien quand un sort est choisi : seulement sa portée).
   - survoler une glyphe ou un de vos pièges : le sort, qui l'a lancé, et les tours restants d'une
     glyphe (les pièges ennemis sont invisibles).
   - **Historique** (à gauche de la barre du bas, en combat comme en exploration ; bouton « – » ou touche **H**
     pour le replier ; onglets Tout, Combat, Commerce). En combat : chaque tour, chaque sort lancé
     et ses effets, gardés après le combat ; dégâts, soins et boucliers à la couleur de leur
     élément (Acier ocre, Flamme orange, Givre bleu, Tempête vert, Sacré jaune pâle, Impie violet).
     Les chiffres qui s'affichent au-dessus des combattants ont les mêmes couleurs (« -12 » :
     dégâts, « +8 » : soin ; un choc contre un obstacle reste rouge).
3. Fin du combat : réputation, brumes et butin (une icône par objet avec sa quantité ; le nom en
   survolant), la difficulté du combat (× 0,1 à × 1,5 : elle multiplie vos gains) et les
   caractéristiques gagnées par la pratique. En groupe, chacun gagne par ses propres actions.
   En cas de défaite, on se réveille avec 1 PV à côté de la Pierre de Passage de son **point de
   résurrection** (voir plus bas), même si elle est sur une autre carte.
   Si le sac (60 places) est plein, le butin y entre quand même, en surplus : il faut alors faire de
   la place (vendre, jeter, ranger au coffre) avant de pouvoir relancer un combat.

Les points de vie se gardent d'un combat à l'autre et remontent doucement (1 PV toutes les 2 s,
trois fois plus vite **assis**) ;
le **lit** de votre maison les rend tous d'un coup.

### Pierres de Passage et point de résurrection

- **Phase de test : toutes les pierres sont accessibles dès le début** (les zones ne sont pas
  encore reliées à pied) : depuis n'importe quelle pierre, vous pouvez voyager vers toutes les
  autres. Plus tard, il faudra d'abord aller à pied jusqu'à une pierre et cliquer dessus pour la
  découvrir.
- Le voyage se **paie** : 10 brumes vers une zone de départ. Le **Trône de Cendre** (carte d'élite de
  test) reste gratuit et connu de tous.
- La fenêtre de voyage montre votre bourse, le prix de chaque destination (en rouge si vous n'avez
  pas assez de brumes) et grise les pierres « pas encore découvertes ».
- **Point de résurrection** : la dernière pierre que vous avez touchée (au début, celle de votre zone
  de départ ; elle est rappelée en bas de la fenêtre de voyage). Toucher une autre pierre la
  remplace, avec un message « Nouveau point de résurrection ».

### Quêtes

- Un **« ! »** jaune au-dessus d'un personnage : il a une quête pour vous. Cliquez dessus : sa
  proposition s'affiche (texte, objectifs, récompenses) avec « Accepter » ou « Plus tard ».
- Un **« ? »** jaune : il attend quelque chose de vous maintenant (lui parler, lui rapporter des
  objets) ; un **« ? »** gris : sa quête est en cours.
- La quête suivie s'affiche **dans la bande gauche**, sous la minicarte (clic : le journal, touche **Q** ;
  le bouton **« – »** la replie pour ne garder que son nom). Chaque objectif qui avance s'annonce
  en haut de la bande droite.
- Dans la proposition et le journal, les **noms en bleu** (personnages, cartes, zones) se
  cliquent : un **repère** (épingle rouge) se pose sur la carte du monde, qui s'ouvre, et sur la
  minicarte (une flèche au bord s'il est plus loin). Recliquez le nom, ou « Retirer le repère »
  sur la carte du monde, pour l'enlever ; il s'en va aussi quand vous arrivez sur sa carte.
- L'objectif de la quête suivie a son **épingle jaune** sur la carte du monde et la minicarte,
  posée toute seule : la carte où aller, le personnage à qui parler, ou la carte la plus proche où
  trouver les monstres ou la ressource demandés.
- On rend une quête en parlant au personnage une fois les autres objectifs remplis (les objets
  demandés sont pris à ce moment-là). Certains objets ne tombent des monstres que pendant la quête
  qui les demande ; les **objets de quête** ne se vendent ni ne se jettent.
- Contenu : un **tutoriel** par camp (Alric à Brumerive, Grumm à Crasse-Roc, Elwyn à Sylvebrume :
  s'équiper, combattre, récolter, forger), puis l'**acte I** de la quête principale de son camp,
  quatre quêtes jusqu'au mini-boss de la zone (le raid gobelin pour les humains, le grand raid pour
  les gobelins, « ce n'est pas notre guerre » pour les elfes). Puis l'**acte II** à Hautepierre
  (13 → 25), trois quêtes par camp où chacun découvre le vrai plan du Souverain (donneurs :
  l'Intendant pour les humains, Brokk sur la Route de l'Est pour les gobelins, l'ambassadrice
  Ilyndra pour les elfes), et le début de l'**acte III**, commun aux trois camps : le Conseil des
  Peuples Libres, puis Grondin à la Brèche. Les quêtes des actes I et II sont réservées au camp de
  votre race. Enfin, **5 quêtes secondaires par zone de départ**, ouvertes à tous une fois un
  tutoriel fini (le prêt du berger, la grève des épouvantails, le dentier de Mamie Ratine, l'ode
  au Grand Cerf…) : n'hésitez pas à visiter les zones des autres camps. Et **3 à Hautepierre**,
  ouvertes à tous aussi (la relève du fantôme, la recette du troll, les fausses Reliques de Fulbert).

## Ce qu'il y a dans cette version

- **4 zones, 52 cartes** :
  - **Brumerive** (humains, 10 cartes, niveaux 1 à 12), **Crasse-Roc** (gobelins, 10 cartes) et
    **Sylvebrume** (elfes, 9 cartes), chacune avec son village (maison avec coffre et lit,
    marchand, forgeron), quatre paliers de monstres (1–3, 4–6, 7–9, 10–12) et un **mini-boss** au
    bout : **Krasbouk** (chef de raid syndiqué), le **Balourd des Abîmes** (sur son île de lave),
    la **Mère-Toile** (au cœur de la Toile). Chacun change de comportement en perdant ses PV
    (phases) et revient 1 minute après sa défaite.
  - **Hautepierre** (19 cartes, niveaux 13 à 30) : la ville humaine (Pierre de Passage sur la
    Grand-Place, marchande, forgeron, Citadelle), reliée aux trois zones de départ par une porte, et
    ses environs : détrousseurs, trolls des ponts, corbacs espions, gargouilles, Cendrillons,
    olifants de guerre, et à la Brèche le **boss Grondin**.
  - Le **Trône de Cendre** (carte d'élite de test, gratuit par les Pierres) : le Souverain Cendré,
    le monstre le plus puissant du jeu, pour les curieux.
- **50 monstres** : une famille par palier, chacune avec son **élite** (plus grande, halo doré, bien
  plus forte, meilleur butin ; elle apparaît toutes les 5 à 6 minutes sur une carte de sa famille, et
  son butin s'améliore tant qu'elle reste en vie : losanges puis couronne dans sa bulle). Les
  monstres ont un **niveau variable** dans leur palier (affiché dans la bulle du groupe). Une fois un
  mini-boss vaincu, sa **variante corrompue** (loup cendreux, grouilleur de braise, arbre calciné)
  apparaît dans son repaire.
- **44 quêtes** : un tutoriel par camp, la quête principale de chaque camp (acte I dans la zone de
  départ, acte II à Hautepierre), le début de l'acte III commun (le Conseil des Peuples Libres, puis
  la Brèche), et 18 quêtes secondaires (15 dans les zones de départ, 3 à Hautepierre).
- **Combat** : coups critiques, bonus et malus, poisons, poussées, glyphes (cases à la couleur de leur élément) et
  pièges invisibles, monstres qui gardent leurs distances ou soignent leurs alliés, **mode
  tactique** (T).
- **Équipement** : 217 équipements, des panoplies (six élémentaires de 6 pièces au niveau 3, six de
  7 pièces arme comprise aux niveaux 15 et 30, avec des PA, des PM et de la portée, deux de 3 pièces à
  mélanger : plus on porte de pièces, plus le bonus grandit), des trophées de boss qui ne se vendent
  pas.
- **Métiers** : bûcheron et mineur (5 ressources chacun, de plus en plus rares), forgeron (23
  recettes, dont certaines demandent des butins de plusieurs zones). **Récolte rare** : 1 fois sur
  100, une ressource rare à la place (« Rare ! »), pour 6 recettes améliorées.
- **Pierres de Passage** : pendant ce test, toutes accessibles dès le début (voyage payant). La
  dernière pierre touchée est votre point de résurrection.

## Problèmes connus

- **Équilibrage provisoire** : nos simulations disent que certains mini-boss sont durs pour
  certaines Voies au niveau 12 (surtout la Mère-Toile, et Krasbouk ou le Balourd pour le Rôdeur).
  Si un mini-boss vous résiste, **allez chercher de l'équipement** (quêtes secondaires, autres zones,
  Hautepierre) puis revenez : c'est exactement le genre de retour qu'on attend.
- Certains combats contre des monstres qui fuient (Cendrillons) peuvent être longs.
- Pas de son ; certains dessins sont provisoires (pas de personnages féminins, pas d'animation de
  mort ni d'effets de sorts).
- Les élites gagnent une marque d'ancienneté par minute (pour le test ; ce sera une par heure).
- Un gel du jeu a été vu une fois contre Grondin, sans qu'on arrive à le reproduire. Le jeu
  reprend désormais seul au bout d'une seconde si l'affichage reste bloqué. Si un gel vous arrive
  quand même, ouvrez la console du navigateur (**F12**, onglet « Console ») et faites une capture
  des messages en rouge : c'est très précieux.

## Ce qu'on aimerait que vous regardiez

- Le **combat** est-il compréhensible sans explication ? Trop facile, trop dur ? Une Voie vous
  semble-t-elle trop faible ou trop forte ?
- Les **quêtes** : saviez-vous toujours quoi faire et où aller ? Les textes vous ont-ils fait
  sourire ? Une quête vous a-t-elle bloqué ?
- Les **zones** se lisent-elles bien (où marcher, où sont les sorties et les portes, ce qui est
  cliquable) ? La minicarte et la carte du monde aident-elles ?
- Le **rythme** : la réputation monte-t-elle trop vite, trop lentement ?
- L'**économie** : prix du marchand, butin, recettes du forgeron.
- Tout ce qui semble **bloqué, lent, illisible ou bizarre**.

## Donner son avis et signaler un problème

Le **questionnaire** (bouton « Donner son avis » du menu principal ou du menu pause) prend une
dizaine de minutes ; il a une partie pour les bugs. Pour chaque problème, donnez si possible :

1. ce que vous faisiez (carte, action, combat ou non, quête en cours) ;
2. ce qui s'est passé, et ce que vous attendiez ;
3. une capture d'écran ;
4. votre navigateur, et si le problème revient en recommençant.
