# Retro Venture — guide des testeurs (alpha solo)

Merci de tester ! Ce document explique comment jouer, ce qu'il y a à voir dans cette version et
comment nous faire vos retours. Le jeu n'affiche volontairement presque aucune aide à l'écran : tout
est ici.

## Lancer le jeu

- Dans le navigateur (Chrome, Firefox ou Edge récents, sur ordinateur) :
  **https://ottoreg.github.io/Retro_Venture/**
- La partie est **sauvegardée automatiquement** dans le navigateur (changement de carte, fin de
  combat, retour au menu…). « Continuer » au menu reprend la dernière partie. Vider les données du
  site efface la sauvegarde.
- Résolution prévue : 1280 × 720 ou plus.

## Créer son personnage

- Trois races, chacune avec sa zone de départ et son sort racial :
  - **Humain** : départ à **Brumerive** ; sort *Ralliement* ; passif +10 % d'XP de métier.
  - **Gobelin** : départ à **Crasse-Roc** ; sort *Coup bas* ; passif *Chapardeur* : +20 prospection
    et +20 % d'écus en fin de combat.
  - **Elfe** : départ à **Sylvebrume** ; sort *Pas léger* ; passif +1 portée sur les sorts à distance.
- Quatre Voies (classes) : **Guerrier**, **Rôdeur**, **Arcaniste** et **Théologue** (soigneur
  sacré : soin, bouclier qui absorbe les dégâts jusqu'à son prochain tour, dégâts Sacrés), avec 4
  sorts chacune.
- Les soins et boucliers grandissent avec la caractéristique de leur élément (soin Sacré : Force et
  Intelligence ; *Second souffle* du Guerrier : Force ; *Soin mineur* de l'Arcaniste :
  Intelligence).

## Commandes

### Exploration

| Action | Comment |
| --- | --- |
| Se déplacer | Clic sur une case (un nouveau clic pendant la marche change de destination) |
| Attaquer un groupe de monstres | Clic sur le groupe : le personnage le rejoint et le combat commence |
| Parler, commercer, fabriquer | Clic sur un PNJ (bulle « … » au-dessus de sa tête) |
| Récolter | Clic sur un arbre (bûcheron) ou un rocher à minerai (mineur) |
| Entrer / sortir d'un bâtiment | Clic sur la porte : celles où l'on peut entrer sont marquées au sol d'un losange doré (double chevron) |
| Changer de carte | Clic sur une flèche jaune au bord de l'écran |
| Voyager vers une autre zone | Clic sur la **Pierre de Passage** (pierre levée aux runes bleues), puis choisir la destination (voir plus bas) |
| Voir ce qu'on survole | Passer la souris sur un monstre, un PNJ, une ressource : une bulle s'affiche (pour un groupe : chaque monstre avec son niveau) |

### Fenêtres et raccourcis

| Touche | Fenêtre |
| --- | --- |
| **C** | Personnage : caractéristiques, PA, PM, initiative, prospection, points à répartir après un niveau |
| **I** | Inventaire : équipement porté, sac, équiper / retirer / jeter (tenir **Ctrl** : jets possibles de l'objet choisi) |
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

- **Minicarte** (en haut à droite, en exploration seulement), comme dans Dofus Rétro : la carte du
  monde en réduit, **5 × 5 cartes autour de vous**. Votre carte est au milieu (cadre doré, point
  bleu) ; les autres cartes sont des cases claires, les traits sont les passages entre cartes, le
  losange bleu une Pierre de Passage. Survolez
  une case pour son nom. En haut, le nom de la zone et les coordonnées de la carte ; dans une maison,
  elle montre la carte devant la porte. Un **clic** dessus ouvre la carte du monde. Elle disparaît en
  combat (l'ordre de jeu prend sa place). Elle cache le coin en haut à droite de la carte : si un
  groupe ou un PNJ passe dessous, ou pour aller sur ces cases, **repliez-la** avec le petit bouton
  **« – »** de sa barre (« + » pour la déplier) ; elle reste repliée d'une carte à l'autre.
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
- **Sorts** : une icône par sort, avec son raccourci (1 à 0) et son coût en PA.

### Combat (au tour par tour)

1. **Placement** : comme dans Dofus, chaque carte a ses cases de départ, toujours les mêmes, où que
   vous ayez engagé le groupe : les vôtres (cercles bleus) d'un côté, celles des monstres de
   l'autre. Cliquez sur un cercle bleu pour choisir votre case, puis **Prêt**. Après le combat, vous
   reprenez l'exploration là où vous avez engagé le groupe.
2. **Votre tour** :
   - se déplacer : clic sur une case verte (1 PM par case) ;
   - lancer un sort : touche **1 à 0** ou clic sur son icône, puis clic sur la cible (cases bleues :
     portée ; un second clic sur le sort, un **clic droit** ou **Échap** l'annule) ;
   - **Fin de tour** : bouton du bandeau.
   - **Mode tactique** : bouton « Tactique » du bandeau ou touche **T** (aussi dans les options).
     Vue simplifiée de la grille, comme dans Dofus : cases à plat en damier, eau à plat (elle ne
     bloque que le passage), obstacles qui bloquent la vue en blocs, arbres et bâtiments masqués,
     combattants en pions de la couleur de leur camp (initiale et PV). Portées, zones, glyphes et
     cases de placement restent affichées. Le choix est retenu d'un combat à l'autre.
   - survoler un combattant : son niveau, ses PV, PA, PM et ses résistances s'affichent à la place
     de la barre de sorts.
3. Fin du combat : expérience, écus et butin (une icône par objet avec sa quantité ; le nom en
   survolant). Pendant l'alpha 1, l'expérience gagnée est **multipliée par 3,5** : on monte vite de
   niveau pour tester toutes les mécaniques ; la vraie vitesse de progression viendra à l'alpha 2. En cas de défaite, on se réveille avec 1 PV à côté de la Pierre de Passage de son
   **point de résurrection** (voir plus bas), même si elle est sur une autre carte.
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
- La quête suivie s'affiche **sous la minicarte** (clic : le journal, touche **Q**). Chaque objectif
  qui avance s'annonce en bas de l'écran.
- On rend une quête en parlant au personnage une fois les autres objectifs remplis (les objets
  demandés sont pris à ce moment-là). Certains objets ne tombent des monstres que pendant la quête
  qui les demande ; les **objets de quête** ne se vendent ni ne se jettent.
- Contenu : un **tutoriel** par camp (Alric à Brumerive, Grumm à Crasse-Roc, Elwyn à Sylvebrume :
  s'équiper, combattre, récolter, forger), puis l'**acte I** de la quête principale de son camp,
  quatre quêtes jusqu'au mini-boss de la zone (le raid gobelin pour les humains, le grand raid pour
  les gobelins, « ce n'est pas notre guerre » pour les elfes). Les quêtes principales sont réservées
  au camp de votre race.

## Ce qu'il y a dans cette version

- **Zones** : **Brumerive, complète** (10 cartes, niveaux 1 à 12 : place du village, champs de
  l'est, rives de la Brume, moulin de Tournevent, verger des Pommeaux, lande aux épouvantails, Grands
  Blés, camp du raid, gué de Brume-Haute, palissade de Krasbouk), **Crasse-Roc, complète** (10
  cartes, niveaux 1 à 12 : entrée des galeries, Crassier, Rataillerie, puits des Vampipistrelles,
  galerie effondrée, poste avancé de la Milice, carrière aux Échos, Forges noires, route des
  Charrois, abîme du Balourd), **Sylvebrume, complète** (9 cartes, niveaux 1 à 12 : clairière de la
  Lisière, futaie ancienne, sous-bois moussu, bosquet des Cerfs, coupe rase, scierie de Brumerive,
  Toiles grises, orée du Sud, cœur de la Toile), **Hautepierre, complète** (19 cartes, niveaux 13 à
  30 : la ville au centre avec sa Pierre de Passage sur la Grand-Place, la marchande Rosemonde et le
  forgeron Gontran, la Citadelle et ses personnages ; trois routes la relient aux zones de départ par
  une porte, depuis le Gué de Brume-Haute, la Route des Charrois et l'Orée du Sud), Sylvebrume (clairière de la Lisière, futaie ancienne), reliées seulement par les
  Pierres de Passage (toutes accessibles dès le début, voir plus haut). Le **Trône de Cendre** (carte d'élite) est
  accessible par n'importe quelle Pierre : le Souverain Cendré y attend, c'est le monstre le plus
  puissant du jeu.
- **Monstres** : à Brumerive, par palier — loups (1–3), frondeurs gobelins (4–6), pillards
  gobelins et épouvantails démotivés (7–9), briseurs gobelins (10–12), chacun avec son élite (loup
  alpha, frondeur vétéran, pillard émérite, grand épouvantail, défonceur de portes) ; au bout, le
  **mini-boss Krasbouk**, chef de raid syndiqué (palissade, carte 3, 2), en trois temps : il court
  et tire de plus loin à 60 % de PV, puis entre en rage à 30 % (critiques, Dommages, mais moins
  résistant à l'Acier) ; il revient 1 minute après sa défaite. À Crasse-Roc : rats et grouilleurs
  (1–3), vampipistrelles (4–6), miliciens de Hautepierre (7–9), contremaîtres zélés (10–12), avec
  leurs élites (rat-roi, grouilleur ancestral, vampipistrelle comtesse, sergent de la milice,
  contremaître en chef) ; au fond, le **mini-boss Balourd des Abîmes** sur son île au milieu de la
  lave : à 70 % sa carapace couvre sa faiblesse au Givre, à 40 % il s'embrase (pluie de braises), à
  15 % il s'envole (plus de PM et de portée). À Sylvebrume : morilles grincheuses (1–3), cerfs
  enchantés et arbres vivants (4–6), bûcherons de Brumerive (7–9), tisseuses de brume (10–12), avec
  leurs élites ; au cœur de la Toile, le **mini-boss Mère-Toile** : à 65 % elle tisse toute la
  clairière (toile géante, plus de PM), à 35 % elle s'enferme dans un cocon (couvre sa faiblesse à
  la Flamme), à 10 % elle mise tout sur l'attaque. Une fois un mini-boss vaincu, la cendre gagne
  son repaire : un groupe de sa **variante corrompue** (loup cendreux, grouilleur de braise, arbre
  calciné, niveaux 13 à 21) y apparaît pour de bon, avant-goût de Hautepierre.
  À Hautepierre, une famille par palier : détrousseurs (13–15), trolls des ponts (16–18), corbacs
  espions (19–21), gargouilles (22–24), Cendrillons (25–27), olifants de guerre (28–30), chacune
  avec son élite ; des **variantes corrompues** (loup cendreux, grouilleur de braise, arbre calciné),
  plus fortes et de Flamme, sur les premiers paliers ; et à la Brèche, le **boss Grondin**, bélier de
  siège : à 75 % il se blinde, à 50 % il charge de loin, à 20 % ses roues cassent (il frappe très
  fort mais ne bouge presque plus). Les groupes comptent 1 à 3 monstres, parfois mélangés,
  se promènent autour de leur place et réapparaissent 2 à 3 minutes après avoir été vaincus. Les
  trophées de boss (hachoir, chevalière de Krasbouk) ne se vendent pas en boutique.
- **Niveaux des monstres** : à Crasse-Roc, rats et grouilleurs ont un niveau de 1 à 3, tiré à chaque
  apparition (les rats surtout au niveau 1, les grouilleurs surtout au niveau 3). Plus haut niveau :
  plus de PV, de dégâts et d'XP, mais le même butin. La bulle du groupe et le cadre du combattant
  survolé montrent le niveau de chacun.
- **Nouveautés du combat** : coups critiques (5 % par sort, « Coup critique ! », valeurs × 1,5),
  bonus et malus temporaires, poisons, poussées, glyphes et pièges. Survoler un combattant montre
  ses états en cours (« −2 PM (1 tour) », « Poison 6 Givre (3 tours) »…).
  - L'**Arbre millénaire** pose un *Cercle de sève* autour de lui (cases vertes) : il s'y soigne, et
    qui y commence son tour perd 2 PM.
  - Le **Frondeur vétéran** sème des *Chausse-trapes* **invisibles** : on ne voit que le nom du sort.
    Marcher dessus arrête le déplacement, blesse et retire 2 PM.
  - Les frondeurs gardent leurs distances : ils tirent de loin, puis reculent.
- **Élites** : chaque famille a sa version élite, plus grande, avec un halo doré, bien plus forte et
  qui lâche plus souvent les objets rares (Loup alpha, Frondeur vétéran, Rat-roi, Grouilleur
  ancestral, Grand cerf de la Lisière, Arbre millénaire). Chaque élite tente d'apparaître toutes
  les 5 à 6 minutes de jeu (où que vous soyez), sur une carte au hasard où vit sa famille : dans un
  nouveau groupe, ou à la place d'un monstre d'un groupe s'il y a déjà 3 groupes sur la carte. Une
  seule de chaque espèce à la fois ; une fois vaincue, elle revient 5 à 6 minutes plus tard.
  Plus une élite reste en vie, plus son butin s'améliore : un losange doré par minute dans sa bulle
  (5 au plus), puis des triangles au-dessus en couronne ; +10 % de chances de butin par marque,
  jusqu'à +100 %. (Pour les tests, une marque par minute ; ce sera une par heure ensuite.)
- **Dans chaque village de départ** : une maison (coffre de 100 places partagé entre les maisons, et
  un lit), un marchand qui achète et vend tous les objets, et un forgeron.
- **Panoplies** (vendues par les marchands, niveau 3) : six panoplies élémentaires de 6 pièces
  (Forgeron Hargneux : Force ; Pyromane Repenti : Intelligence ; Bonhomme de Neige : Chance ;
  Courant d'Air : Agilité ; Enfant de Chœur : Sacré ; Mauvais Œil : Impie) et deux de 3 pièces à
  mélanger (Pressé : Initiative et Dommages ; Fouineur : Prospection). Plus on porte de pièces d'une
  même panoplie, plus son bonus grandit ; le détail d'un objet (inventaire, marchand) montre les
  pièces portées et le palier actif (marqué « » »).
- **Éléments Sacré et Impie, statistique Dommages** : à tester avec la Masse bénite (Sacré : Force
  et Intelligence), la Dague du Mauvais Œil (Impie : Agilité et Chance) et la Chevalière du Cogneur
  (+Dommages : des dégâts en plus sur chaque coup, quel que soit l'élément), en vente chez les
  marchands. Les Dommages apparaissent dans la fiche (C).
- **Reliques** : les huit cases « Reliques » de l'inventaire restent vides pour l'instant (les
  Reliques arriveront avec la quête principale).
- **Métiers** : bûcheron (frêne, chêne, if niv. 8, hêtre niv. 15, malorme niv. 22), mineur
  (cuivre, fer, étain niv. 8, argent niv. 15, obsidienne niv. 22), forgeron (23 recettes, dont
  certaines demandent des butins de plusieurs zones : il faut voyager). Les ressources repoussent
  en 1 à 3 minutes. **Récolte rare** : 1 fois sur 100, on obtient à la place une ressource rare
  (« Rare ! » en doré au-dessus du personnage), qui sert à 6 recettes améliorées du forgeron ; ni les
  ressources rares ni ces objets ne se trouvent chez le marchand.

Pas encore là : quêtes secondaires et actes II–III (à venir), multijoueur, sons et musiques.

## Ce qu'on aimerait que vous regardiez

- Le combat est-il compréhensible sans explication ? Trop facile, trop dur ?
- Les zones se lisent-elles bien (où marcher, où sont les sorties, ce qui est cliquable) ?
- Les groupes de monstres : est-ce qu'on voit bien qui est dans un groupe, et où il va ?
- L'économie : prix du marchand, butin, recettes du forgeron.
- Les quêtes : savait-on toujours quoi faire et où aller ? Les textes font-ils sourire ?
- Tout ce qui semble bloqué, lent, illisible ou bizarre.

## Signaler un problème

Pour chaque problème, donnez si possible :

1. ce que vous faisiez (carte, action, combat ou non) ;
2. ce qui s'est passé, et ce que vous attendiez ;
3. une capture d'écran ;
4. votre navigateur, et si le problème revient en recommençant.
