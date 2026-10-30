# Retro Venture — consignes pour Claude

RPG tactique au tour par tour (Dofus Rétro × parodie du Seigneur des Anneaux), Godot 4.5 / GDScript.
Solo d'abord, multijoueur plus tard. Vision et règles : [docs/GDD.md](docs/GDD.md) ; tâches : [docs/TODO.md](docs/TODO.md).

## Langue et ton

- L'auteur écrit en français : répondre, committer et documenter en français.
- Le contenu du jeu est parodique (gobelins syndiqués, elfes snobs, humains persuadés d'être les héros…).

## Méthode de travail

- Développer sur la branche de session, la pousser, attendre la CI verte (onglet Actions ou API GitHub),
  puis pousser sur `main` : chaque push sur `main` publie le jeu sur GitHub Pages.
- Pas de pull request sauf demande explicite.
- Garder les tests verts et en ajouter pour chaque règle du noyau ; mettre à jour GDD, TODO,
  `game/data/README.md` et `docs/GUIDE_TESTEURS.md` quand un système ou un contenu change.
- **Économiser les tokens** (demande de l'auteur) :
  - pas de vérification par plusieurs agents : préférer un script de contrôle mécanique, et les tests ;
  - écrire soi-même quand c'est faisable, plutôt que de lancer un workflow ;
  - surveillance de la limite de session : un relevé de temps en temps (toutes les ~20 min), pas de
    réveils à la minute ; s'arrêter proprement (commit + push) vers 85 %, l'auteur fixe la limite à 90 % ;
  - ne pas reprendre automatiquement un travail interrompu sans accord.
- Ne rien laisser seulement dans la session (scratchpad, worktrees) : le conteneur est éphémère,
  tout ce qui compte est commité et poussé.

## Commandes

Depuis `game/` (binaire Godot 4.5.1 standard) :

```sh
godot --headless --path . --import                           # une fois, dans un nouveau clone
godot --headless --path . -s res://tests/run_tests.gd        # tous les tests (RV_TESTS=mot : seulement ces fichiers)
xvfb-run -a godot --path . -s res://tools/screenshot.gd -- sortie.png [carte] [secondes] [action]
```

`tools/screenshot.gd` fait des captures en jeu (actions : glyphe, survol, infobulle, objet, boutique_panoplie, phase, reveil, carte, sermon,
cible, tactique, pause, options, fiche, assis, joueurs, groupe, chat, amis, echange…) ; `tools/art_sheet.gd` fait une planche des dessins ; `tools/simulation.gd` simule des
combats sur chaque groupe des cartes (`-- [combats] [rapport.md] [préfixes de cartes] [detail]`,
~7 min pour tout à 10 combats).
Multijoueur : `godot --headless --path . -s res://server/server_main.gd` (serveur de développement, port
8080) et `-s res://tools/bot.gd -- ws://localhost:8080 Robotin` (un joueur automatique) ; Docker :
`serveur/README.md`.
`python3 tools/catalogue.py` regénère `docs/CATALOGUE.md` (objets, monstres par niveau et lieux, sorts, avec leurs
détails et comment les obtenir) : à relancer après tout changement d'objets, de sorts ou de monstres.

## Architecture

- `game/core/` : règles sans affichage (partagées avec le futur serveur). Commandes → événements,
  constantes dans `Protocol`. Combat : `combat.gd`, `fighter.gd`, `spell.gd`, `combat_ai.gd` ;
  butin : `items/loot.gd` ; données : `data/game_data.gd` (validation des JSON).
- `game/client/` : rendu isométrique, interface, fenêtres.
- `game/data/` : contenu en JSON (cartes, monstres, sorts, objets, panoplies, passages, races, voies,
  métiers, quêtes), format décrit dans `game/data/README.md`. Quêtes : `core/quests/`.
- Dessins : SVG `.svgt` paramétrés, manifeste `art.json` + fragments `art/manifestes/*.json`
  fusionnés par `Art.manifest()` (un fragment par lot de production, pour éviter les conflits).

## Où en est le projet

Phase 2 (alpha solo), en deux tests :

- **Alpha test 1 : les mécaniques.** Chantiers dans l'ordre : contenu du monde (3), puis
  interface (4) et quêtes (6) en derniers avant le lancement. XP de combat ×3,5 jusqu'au 29/10/2026 (supprimé par la refonte de la progression).
- **Alpha test 2 : la progression.** **Refonte décidée le 29/10/2026** (GDD § 4.5, lots dans la TODO) :
  plus de niveaux de personnage, d'arme ni de métier ; réputation (débloque) et points de maîtrise
  (à répartir dans les sorts ou compétences) par classe et par métier ; une classe active à la fois,
  changée hors combat ; caractéristiques gagnées par la pratique et plafonnées ; Chance → Perception,
  Sagesse supprimée ; équipement sans condition ; maîtrise de métier = qualité, jamais d'échec.
  Plus art et son (5). **Lots 0 à 3 faits sur `main`** (29/10/2026, GDD § 4.5 « Où en est la
  refonte ») : `Character.classes` / `earned` / `practiced`, commandes `changer_voie` et `maitriser`,
  protocole v8 ; gains par action en combat (`Progression`, `Combat.practice`, facteur de
  difficulté), rangs de maîtrise (`Spell.mastered`, champ `maitrise`), sorts de rang II
  (`sorts_rang_2`, Cri de guerre et Fendoir validés) ; objets sans conditions, prix selon le palier,
  menace des monstres affichée (`MapView.threat_line`) ; plafond 300 par caractéristique, plus de bonus
  de caractéristiques de race ni d'équipement de départ (demande de l'auteur). Prochain : lot 4 (métiers).

État des chantiers :

1. Fondations du combat — **fait** (crits, bonus/malus, poison, poussée/attirance, glyphes, pièges
   invisibles, IA distance et soutien). Le modèle de sorts voie/rang passe à l'alpha 2.
3. Contenu du monde — **systèmes faits** (niveaux variables, mini-boss à phases, Pierres de Passage
   payantes — toutes connues dès le début pendant la phase de test, `World.ALL_PASSAGES_KNOWN` —,
   point de résurrection, carte du monde qui montre tout dès le début, minicarte façon Dofus Rétro :
   vignettes `MapThumbnail`, molette, glisser, icônes `MapIcons`, drapeaux au clic droit).
   **Conception entièrement validée par l'auteur** (mini-boss révisés compris) :
   `docs/design/chantier3_brouillon/` (document, JSON par lot, scripts `src/build.py` et
   `src/controle.py`). Cases de placement prédéfinies par carte **faites** (calque `placement`,
   GDD § 7.1, outil `game/tools/placement.py`). **Production par lots en cours** : les trois zones de départ
   faites (Brumerive, Crasse-Roc, Sylvebrume ; `src/produire.py`, `src/cartes.py`,
   `src/plans_<lot>.py`), Hautepierre (`src/plans_hautepierre.py`, `peupler` pour les groupes et
   PNJ), les variantes et les métiers (`src/metiers_production.py`) : **tout le contenu est produit**.
   Décors de ville dessinés. Variantes dans les repaires des mini-boss une fois vaincus (groupes
   `apres_boss`). Intégration faite (`tools/simulation.gd`, `docs/design/simulation_combats.md`) :
   ajustements d'équilibrage reportés après l'alpha test 1, d'après les retours des joueurs (TODO).
4. Interface et confort : **mode tactique en combat** (GDD § 14.3), menu pause et options
   (`client/options.gd`, `user://options.cfg`) **faits** ; **bandes latérales façon Dofus 2**
   (`client/world/screen_layout.gd` : carte à l'échelle, rien sur la zone de jeu) **faites** ; reste la fenêtre des quêtes (avec le
   chantier 6, faite) et les petits conforts (raccourcis ; infobulles d'objets comparées à l'équipement porté : faites,
   `client/ui/item_tooltip_list.gd`).
6. Quêtes : conception validée (`docs/design/chantier6_quetes.md`). **Lots 1 (système :
   `core/quests/`, journal Q, suivi, marques `!`/`?`) et 2 (tutoriels et acte I, script
   `docs/design/chantier6/produire_lot2.py`), 3 (15 secondaires, `produire_lot3.py`) et 4 (acte II,
   Conseil et Brèche, `produire_lot4.py`) faits** : tout le contenu de quêtes de l'alpha 1 est
   produit, secondaires de Hautepierre comprises (lot 5, `produire_lot5.py`) ; l'objectif de la
   quête suivie a une épingle jaune automatique (`QuestLinks.objective_pin`). Noms cliquables des textes de quête (PNJ,
   cartes, zones) qui posent un repère sur la minicarte et la carte du monde (`QuestLinks`) : faits.

**Lancement de l'alpha test 1 en préparation** (version 0.6.0, GitHub Pages) : guide des testeurs à
jour, questionnaire Google Forms créé par `docs/creer_formulaire.gs` (référence
`docs/FORMULAIRE_ALPHA1.md` ; le connecteur Drive ne lit pas les formulaires), lien vérifié dans le
bouton « Donner son avis » (`Session.FEEDBACK_URL`). Checklist : TODO, Phase 2, « Lancement de
l'alpha test 1 » : restent la passe de l'auteur dans chaque camp, le gel vu une fois contre Grondin
(attendre la console du navigateur) et l'invitation des testeurs.

**Multijoueur** : plan d'architecture dans le GDD § 16.5 (serveur Godot sans affichage qui
fait autorité, WebSocket, comptes et PostgreSQL via Supabase, client web + natif, jalons M0 à M6).
**Validé par l'auteur le 26/10/2026**, hébergement gratuit pour les tests (PC + tunnel Cloudflare
ou Oracle Always Free), VPS payant pour la bêta. **M0 fait** (GDD § 16.5, « Où en est M0 ») :
`MapInstance` / `PlayerState` dans `World` (façade solo), portée des événements
(`World.recipients`), messages JSON (`Protocol.encode`/`decode`, vérifiés sur tous les tests),
`client/net/` (`LocalConnection`, copie `ClientState` : le client ne lit plus le `World` ; tests et
outils passent par `MapView.server` puis `refresh_state()`). **Prototype M1 en place le 26/10/2026**
(GDD § 16.5, « Où en est M1 ») : serveur `game/server/` (`GameServer`, `WebSocketHost`,
`server_main.gd`), `RemoteConnection` asynchrone (`MapView._request`, réponses par
`take_replies`), autres joueurs affichés, groupe engagé caché aux autres, comptes et personnages
Supabase (`client/net/supabase.gd`, `online_config.gd` à remplir), menu « Jouer en ligne
(prototype) », Docker + tunnel Cloudflare dans `serveur/` (README : étapes de l'auteur), joueur
automatique `tools/bot.gd`. **M2 (combat de groupe) codé le 26/10/2026** (GDD § 16.5, « Où en est
M2 ») : groupes de joueurs, combat rejoint pendant le placement (épées sur la carte), tours de 30 s
en ligne, déconnexion en combat avec retour, parts d'XP, de brumes et de butin ; jeton Supabase
renouvelé (reconnexion automatique). **Fin de M2 le 27/10/2026** : inventaire consultable en
combat, verrous du combat, spectateurs, suivre un membre du groupe, position et repères des membres
sur la minicarte (protocole v4). Reste l'essai à plusieurs chez l'auteur.
**M3 (social) découpé et validé le 27/10/2026** (GDD § 16.5, « Préparation de M3 », 4 lots) : **lots 1
(chat côté serveur : `core/social/chat.gd`, commande `ecrire`, événement `message_chat`,
protocole v5) et 2 (chat côté client : onglets, ligne de saisie, préfixes, menu du pseudo dans
`client/ui/message_log.gd`), 3 (amis et ignorés dans la sauvegarde, `core/social/relations.gd`,
fenêtre `client/ui/friends_window.gd`, touche F) et 4 (signalement, table Supabase `signalements`)
faits** (protocole v6) ; reste l'essai à plusieurs chez l'auteur.
**M4 (commerce) commencé le 28/10/2026 par l'échange entre joueurs** (GDD § 16.5, « Où en est M4 ») :
`core/social/exchange.gd`, commande `echange`, fenêtre `client/ui/exchange_window.gd`, transfert tout
ou rien et sauvegarde des deux personnages en une écriture (`CharacterStore.save_characters`,
personnages liés tant qu'elle n'a pas réussi, sauvegardes une à une) ; protocole v7. Hôtel des
ventes et journal des transactions plus tard. La CI publie aussi, à chaque push sur `main`, le client natif
(release « client-natif ») et l'image du serveur de staging (`ghcr.io/ottoreg/retro-venture-serveur:staging`).

Dernière session (retours de la passe de l'auteur) :

- Retours de test : bulle de dialogue sous le bandeau, suivi de quête repliable, ligne de vue sur
  7 sorts de monstres, garde-fou de la lecture des événements (`MapView._watch_playback`).
- **Catalogue** `docs/CATALOGUE.md` (généré, ne pas éditer) : objets et obtention, panoplies,
  répartition des éléments par zone (alerte au-delà de 60 % d'une zone ou 35 % du jeu), monstres
  avec stats par niveau, lieux et phases, sorts. À regénérer après tout changement de contenu.
- **Règles de monstres** (GDD § 8.1) : un monstre à moins de 3 PM a une menace (PM + portée) d'au
  moins 7, par ses sorts à distance (jamais en allongeant la mêlée) ; un élément de dégâts dominant
  par zone (Brumerive Tempête, Crasse-Roc Flamme, Sylvebrume Givre puis Acier, Hautepierre
  mélangée), Acier 33 % du jeu. Un sort qui change d'élément donne au monstre la caractéristique
  du nouvel élément à la valeur de l'ancienne.
- **Combat** : historique (`client/ui/message_log.gd`, canaux combat et commerce prêts pour le chat, touche H, signal `MapView.combat_logged`),
  dégâts, soins, boucliers et poisons à la couleur de leur élément (historique et chiffres
  flottants), survol des glyphes et des pièges alliés (sort, lanceur, tours restants).
- **Identité des Voies pour l'alpha 1** (GDD § 4.3, `tests/core/test_class_kits.gd`) : Arcaniste
  Flamme / Givre, kit entièrement remplacé (effets `composition_etats` et `creer_sort` :
  *Composition*, qui ouvre une grille des combinaisons, `CombatHud.open_composition`, à la place de
  *Braise* et *Frimas* ; *Fusion arcanique* à 2 PA, 4 sorts créés à 4 PA, 2 places, le plus ancien part ;
  `Fighter.element_states`, `created_spells` ; anciens sorts gardés en trace dans `data/sorts/` ;
  barre : orbes `CombatHud.ElementOrbs` et places vides « ? »), *Charge* du Guerrier (effet `charge`,
  `Combat.charge_path`), *Collet* du Rôdeur (piège), *Absolution* du Théologue (`retrait_etats` ;
  les effets des phases ont `retirable: false`). L'IA ignore les sorts de composition. La Tempête
  de l'Arcaniste vient après l'alpha 1 (à laisser deviner aux testeurs).
- **Chronomancien, Voie Impie** (29/10/2026, demande de l'auteur, GDD § 4.3) : 5e Voie de l'alpha 1,
  effets `horloge` / `decalage_horaire` (`Combat.CLOCK_OFFSETS`, `clock_destination`, échange de
  place), état `insoignable`, carac `degats_infliges` ; heures 3 h, 4 h et 9 h sans effet en
  attendant l'esquive des retraits et le tacle / fuite (à coder dès que possible, TODO) ; protocole v9.
- Idées notées sans les faire : pistes des classes à venir et suite de la refonte de l'Arcaniste
  (GDD § 4.3) ; autres idées d'identité des classes (TODO, « Identité des classes ») ; Cape en peau d'ananas (forte résistance Flamme ; demande des
  bonus de résistance sur l'équipement, GDD § 9.2) ; PNJ qui appellent le joueur par son pseudo
  (balise `{joueur}` dans les dialogues, refusé pour l'instant).
- Le pseudo choisi est déjà utilisé partout ; « Aventurier » (`World.DEFAULT_NAME`) n'apparaît
  que dans les tests et les captures, sans écran de création.

## Règles de design à respecter (détails dans le GDD)

- Zones de départ : paliers 1–3 / 4–6 / 7–9 / 10–12, asymétriques entre zones (§ 3.5).
- Niveau variable dans une famille, pondéré ; élites à niveau fixe, au-dessus de la famille.
- Le niveau d'un monstre change ses stats, jamais son butin ; PA/PM fixes par famille sauf exception.
- Butin : limite par monstre partagée entre joueurs, tirage du plus prospecteur au moins prospecteur.
- Combat : cases de placement prédéfinies par carte, pour chaque camp (comme Dofus), calque
  `placement` obligatoire sur toute carte à groupes.
- Mini-boss : réapparition ≤ 60 s pendant l'alpha, phases de profils différents selon leur thème,
  jamais de soin à un changement de phase.
