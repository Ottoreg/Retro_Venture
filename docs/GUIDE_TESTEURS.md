# Retro Venture — guide des testeurs (alpha test 1)

Merci de tester ! Retro Venture est un RPG tactique au tour par tour, façon Dofus Rétro, dans un
monde qui parodie gentiment les grandes sagas de fantasy (gobelins syndiqués, elfes snobs, humains
persuadés d'être les héros…). Ce document explique comment jouer, ce qu'il y a à voir et comment
nous faire vos retours. Le jeu n'affiche volontairement presque aucune aide à l'écran : tout est ici.

## L'alpha test 1 en bref

- **Version 0.6.0** (affichée sur l'écran d'accueil).
- **Ce qu'on teste : les mécaniques** (combat, quêtes, exploration, interface, métiers), pas la
  vitesse de progression : l'expérience est multipliée par 3,5 pour qu'on puisse **tout voir en
  4 à 5 heures**, du niveau 1 au niveau 30.
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

- Trois races, chacune avec sa zone de départ et son sort racial :
  - **Humain** (camp allié) : départ à **Brumerive** ; sort *Ralliement* ; passif +10 % d'XP de
    métier.
  - **Gobelin** (camp ennemi) : départ à **Crasse-Roc** ; sort *Coup bas* ; passif *Chapardeur* :
    +20 prospection et +20 % d'écus en fin de combat.
  - **Elfe** (camp neutre) : départ à **Sylvebrume** ; sort *Pas léger* ; passif +1 portée sur les
    sorts à distance.
- Quatre Voies (classes), chacune avec sa mécanique :
  - **Guerrier** : *Charge* (en ligne droite, jusqu'au contact, puis un coup d'épée) ;
  - **Rôdeur** : *Collet*, un piège invisible qui blesse et ralentit le premier ennemi qui y entre ;
  - **Théologue** (soigneur sacré : soin, bouclier, dégâts Sacrés) : *Absolution*, qui retire leurs
    bonus aux ennemis, leurs malus et leurs poisons aux alliés ;
  - **Arcaniste** (kit entièrement nouveau) : *Braise* et *Frimas* donnent un **état élémentaire**
    (Flamme ou Givre, 3 au plus, +4 % de dégâts chacun ; le PA est rendu aussitôt). Avec 3 états,
    *Créer un sort* (2 PA) donne un sort selon la combinaison : Flamme ×3 *Fournaise*, Flamme ×2 +
    Givre *Choc thermique*, Givre ×2 + Flamme *Armure de givre*, Givre ×3 *Blizzard* (4 PA chacun).
    Il prend l'une des **deux places** au bout de la barre de sorts (marquées « ? » tant qu'elles
    sont vides) ; un troisième chasse le plus ancien. Les **3 orbes** à côté des PM prennent la
    couleur de vos états (orange : Flamme, bleu : Givre) ; ils s'affichent aussi au survol de
    votre personnage et dans l'historique. On dit
    qu'un troisième élément compléterait la formule…
- Les soins et boucliers grandissent avec la caractéristique de leur élément (soin Sacré : Force et
  Intelligence ; *Second souffle* du Guerrier : Force ; bouclier de l'*Armure de givre* de
  l'Arcaniste : Chance).

## Commandes

### Exploration

| Action | Comment |
| --- | --- |
| Se déplacer | Clic sur une case (un nouveau clic pendant la marche change de destination) |
| Attaquer un groupe de monstres | Clic sur le groupe : le personnage le rejoint et le combat commence |
| Parler, commercer, fabriquer | Clic sur un PNJ (bulle « … », ou « ! » / « ? » s'il a une quête pour vous) |
| Récolter | Clic sur un arbre (bûcheron) ou un rocher à minerai (mineur) |
| Entrer / sortir d'un bâtiment | Clic sur la porte : celles où l'on peut entrer sont marquées au sol d'un losange doré (double chevron) |
| Changer de carte | Clic sur une case du bord marquée d'un halo blanc (la flèche jaune indique la direction) |
| Voyager vers une autre zone | Clic sur la **Pierre de Passage** (pierre levée aux runes bleues), puis choisir la destination (voir plus bas) |
| Voir ce qu'on survole | Passer la souris sur un monstre, un PNJ, une ressource : une bulle s'affiche (pour un groupe : chaque monstre avec son niveau) |

### Fenêtres et raccourcis

| Touche | Fenêtre |
| --- | --- |
| **C** | Personnage : caractéristiques, PA, PM, initiative, prospection, points à répartir après un niveau ; survoler une valeur montre d'où elle vient (points, race, chaque objet, panoplie) ; « Réinitialiser » rend tous les points investis (gratuit pendant l'alpha) |
| **I** | Inventaire : équipement porté, sac, équiper / retirer / jeter ; **double-clic** sur un objet pour l'équiper ou le retirer, ou **glisser** du sac vers un emplacement (et inversement) ; tenir **Ctrl** : jets possibles de l'objet choisi |
| **S** | Sorts : un onglet pour la Voie, la race et l'arme ; fiche de chaque sort |
| **J** | Métiers : un onglet par métier, niveau, ressources et recettes |
| **M** | Carte du monde : un onglet par zone visitée, ses cartes en grille (voir plus bas) |
| **Q** | Journal des quêtes : en cours (la suivie en tête) et terminées, objectifs, récompenses, « Suivre » |
| **Échap** | Ferme la fenêtre ouverte ; sinon, **menu pause** (le jeu s'arrête) : reprendre, options, menu principal (avec sauvegarde, pas en combat), quitter |

**Options** (menu principal ou menu pause) : volume, plein écran, taille de la fenêtre (hors
navigateur) et mode tactique ; elles sont gardées d'une partie à l'autre, hors sauvegarde.

Les six boutons en bas à droite du bandeau ouvrent les mêmes fenêtres. Un clic sur un sort du
bandeau, hors combat, ouvre sa fiche.

### Minicarte et carte du monde

- **Minicarte** (dans la barre du bas, à gauche des menus, en exploration seulement), comme dans Dofus Rétro : la carte du
  monde en réduit, **5 × 3 cartes autour de vous**. Votre carte est au milieu (cadre doré, point
  bleu) ; les autres cartes sont des cases claires, les traits sont les passages entre cartes, le
  losange bleu une Pierre de Passage. Survolez
  une case pour son nom. En haut, le nom de la zone et les coordonnées de la carte ; dans une maison,
  elle montre la carte devant la porte. Un **clic** dessus ouvre la carte du monde. Elle disparaît en
  combat.
- **Carte du monde** (touche **M**, bouton en forme de carte du bandeau, ou clic sur la minicarte) :
  **tout le monde est montré dès le début**, comme dans Dofus : un onglet par zone du jeu, ouvert
  sur la zone actuelle, avec le nombre de cartes que vous y avez visitées. Chaque carte est une case
  avec son nom, à sa place (est à droite, sud en bas) ; la carte où vous êtes a un **cadre doré**.
  Un losange bleu marque une Pierre de Passage.
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
   vous ayez engagé le groupe : les vôtres (cercles bleus) d'un côté, celles des monstres de
   l'autre. Cliquez sur un cercle bleu pour choisir votre case, puis **Prêt**. Après le combat, vous
   reprenez l'exploration là où vous avez engagé le groupe.
2. **Votre tour** :
   - se déplacer : clic sur une case verte (1 PM par case) ;
   - lancer un sort : touche **1 à 0** (ou **& é " ' ( - è _ ç à**, sans Maj, sur un clavier AZERTY)
     ou clic sur son icône, puis clic sur la cible (cases bleues : portée ; un second clic sur le
     sort, un **clic droit** ou **Échap** l'annule) ;
   - **enchaîner** : inutile d'attendre la fin des chiffres et des animations, la main revient tout
     de suite. Pendant une marche, les sorts choisis et leurs cibles (marquées en jaune), un
     déplacement ou la fin du tour sont gardés et partent dans l'ordre dès l'arrivée (5 au plus ; un
     clic droit, sans sort choisi, les annule) ;
   - **Fin de tour** : bouton du bandeau.
   - **Mode tactique** : bouton « Tactique » du bandeau ou touche **T** (aussi dans les options).
     Vue simplifiée de la grille, comme dans Dofus : cases à plat en damier, eau à plat (elle ne
     bloque que le passage), obstacles qui bloquent la vue en blocs, arbres et bâtiments masqués,
     combattants en pions de la couleur de leur camp (initiale et PV). Portées, zones, glyphes et
     cases de placement restent affichées. Le choix est retenu d'un combat à l'autre.
   - survoler un combattant : son niveau, ses PV, PA, PM et ses résistances s'affichent à la place
     de la barre de sorts.
   - survoler une glyphe ou un de vos pièges : le sort, qui l'a lancé, et les tours restants d'une
     glyphe (les pièges ennemis sont invisibles).
   - **Historique du combat** (en bas à gauche, bouton « – » ou touche **H** pour le replier) :
     chaque tour, chaque sort lancé et ses effets ; dégâts, soins et boucliers à la couleur de leur
     élément (Acier ocre, Flamme orange, Givre bleu, Tempête vert, Sacré jaune pâle, Impie violet).
     Les chiffres qui s'affichent au-dessus des combattants ont les mêmes couleurs (« -12 » :
     dégâts, « +8 » : soin ; un choc contre un obstacle reste rouge).
3. Fin du combat : expérience, écus et butin (une icône par objet avec sa quantité ; le nom en
   survolant). Pendant l'alpha 1, l'expérience gagnée est **multipliée par 3,5** : on monte vite de
   niveau pour tester toutes les mécaniques ; la vraie vitesse de progression viendra à l'alpha 2.
   En cas de défaite, on se réveille avec 1 PV à côté de la Pierre de Passage de son **point de
   résurrection** (voir plus bas), même si elle est sur une autre carte.
   Si le sac (60 places) est plein, le butin y entre quand même, en surplus : il faut alors faire de
   la place (vendre, jeter, ranger au coffre) avant de pouvoir relancer un combat.

Les points de vie se gardent d'un combat à l'autre et remontent doucement (1 PV toutes les 2 s) ;
le **lit** de votre maison les rend tous d'un coup.

### Pierres de Passage et point de résurrection

- **Phase de test : toutes les pierres sont accessibles dès le début** (les zones ne sont pas
  encore reliées à pied) : depuis n'importe quelle pierre, vous pouvez voyager vers toutes les
  autres. Plus tard, il faudra d'abord aller à pied jusqu'à une pierre et cliquer dessus pour la
  découvrir.
- Le voyage se **paie** : 10 écus vers une zone de départ. Le **Trône de Cendre** (carte d'élite de
  test) reste gratuit et connu de tous.
- La fenêtre de voyage montre votre bourse, le prix de chaque destination (en rouge si vous n'avez
  pas assez d'écus) et grise les pierres « pas encore découvertes ».
- **Point de résurrection** : la dernière pierre que vous avez touchée (au début, celle de votre zone
  de départ ; elle est rappelée en bas de la fenêtre de voyage). Toucher une autre pierre la
  remplace, avec un message « Nouveau point de résurrection ».

### Quêtes

- Un **« ! »** jaune au-dessus d'un personnage : il a une quête pour vous. Cliquez dessus : sa
  proposition s'affiche (texte, objectifs, récompenses) avec « Accepter » ou « Plus tard ».
- Un **« ? »** jaune : il attend quelque chose de vous maintenant (lui parler, lui rapporter des
  objets) ; un **« ? »** gris : sa quête est en cours.
- La quête suivie s'affiche **en haut à droite**, dans le bandeau, en petit (clic : le journal, touche **Q** ;
  le bouton **« – »** la replie pour ne garder que son nom). Chaque objectif qui avance s'annonce
  en bas de l'écran.
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
  au Grand Cerf…) : n'hésitez pas à visiter les zones des autres camps.

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
- **41 quêtes** : un tutoriel par camp, la quête principale de chaque camp (acte I dans la zone de
  départ, acte II à Hautepierre), le début de l'acte III commun (le Conseil des Peuples Libres, puis
  la Brèche), et 15 quêtes secondaires.
- **Combat** : coups critiques, bonus et malus, poisons, poussées, glyphes (cases colorées) et
  pièges invisibles, monstres qui gardent leurs distances ou soignent leurs alliés, **mode
  tactique** (T).
- **Équipement** : 133 équipements, des panoplies (six élémentaires de 6 pièces, deux de 3 pièces à
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
  Si un mini-boss vous résiste, **allez gagner quelques niveaux** (quêtes secondaires, autres zones,
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
- Le **rythme** : la montée en niveau est-elle trop rapide, trop lente ?
- L'**économie** : prix du marchand, butin, recettes du forgeron.
- Tout ce qui semble **bloqué, lent, illisible ou bizarre**.

## Donner son avis et signaler un problème

Le **questionnaire** (bouton « Donner son avis » du menu principal ou du menu pause) prend une
dizaine de minutes ; il a une partie pour les bugs. Pour chaque problème, donnez si possible :

1. ce que vous faisiez (carte, action, combat ou non, quête en cours) ;
2. ce qui s'est passé, et ce que vous attendiez ;
3. une capture d'écran ;
4. votre navigateur, et si le problème revient en recommençant.
