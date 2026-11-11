# Retro Venture

[![CI](https://github.com/Ottoreg/Retro_Venture/actions/workflows/ci.yml/badge.svg)](https://github.com/Ottoreg/Retro_Venture/actions/workflows/ci.yml)

▶️ **Jouer dans le navigateur : https://ottoreg.github.io/Retro_Venture/** (dernière version de la branche par défaut ; client natif dans la release
[« client-natif »](https://github.com/Ottoreg/Retro_Venture/releases/tag/client-natif))
— commandes et contenu de l'alpha : [guide des testeurs](docs/GUIDE_TESTEURS.md)

RPG tactique au tour par tour en 2D isométrique, inspiré de *Dofus Rétro* pour le rendu et le gameplay
et du *Seigneur des Anneaux* pour l'univers, sur un ton parodique. Les aventuriers parcourent le monde à la recherche des
**Reliques de l'Aube**, des objets légendaires dispersés, seules armes capables de vaincre le
**Souverain Cendré** avant qu'il n'asservisse le monde.

Le jeu se développe d'abord **en solo**, puis évolue vers un **multijoueur en ligne** sur un serveur
global découpé en instances.

## Statut

🟡 **Alpha (novembre 2026)** — l'alpha test 1 (mécaniques) est passé ; l'auteur teste maintenant tout ce qui
a été ajouté depuis, avant de retravailler le fond des mécaniques, des classes et des métiers.

**Déjà jouable**

- **Monde** : trois zones de départ (Brumerive, Crasse-Roc, Sylvebrume) et la ville de Hautepierre, monstres à
  paliers de monstres (1 à 5), mini-boss à phases, Pierres de Passage, minicarte et carte du monde façon Dofus Rétro ;
  une Tour céleste réduite (5 étages, clé de Cupidon, Archange Raphaël au sommet, son Calice en récompense).
- **Combat tactique** : cases de placement, coups critiques, poison, glyphes et pièges, poussée, mode tactique,
  historique de combat, IA à distance et de soutien.
- **Cinq Voies** : Guerrier, Rôdeur, Arcaniste (composition Flamme / Givre), Théologue et Chronomancien
  (Voie Impie et son horloge) ; trois races : Humains, Elfes, Gobelins.
- **Progression sans niveaux** : réputation (qui débloque) et points de maîtrise à répartir, par classe et par
  métier ; caractéristiques gagnées par la pratique et plafonnées ; une classe active, changée hors combat.
- **Mode héros (solo)** : jusqu'à 4 personnages joués ensemble, un seul visible, toute l'équipe en combat.
- **Équipement et métiers** : forge personnalisée à l'enclume (l'équipement prédéfini se limite aux
  panoplies), récolte avec temps selon le palier, agriculteur, herboriste et pêcheur.
- **Quêtes** : tutoriels, actes I et II, quêtes secondaires, journal et suivi avec repères sur la carte.
- **Multijoueur (prototype)** : serveur Godot qui fait autorité, comptes Supabase, groupes et combats de
  groupe, spectateurs, chat par canaux, amis et ignorés, signalement, échange entre joueurs (jalons M0 à M4).
- **Graphismes** : sprites en pixel art pour les trois races et quelques monstres (loup, rat, morille).

**Sur `dev`** : tacle et fuite, esquive des retraits de PA / PM, épines, réduction de dégâts fixe, dégâts
spectraux et dommages de mêlée (statistiques et lignes de forge) ; infusion d'essences et infusion miroir à
l'enclume ; maîtres des Voies ; quêtes sans condition de niveau.

**Ensuite** : panoplies d'objets forgés, statistiques de métier sur les outils, hôtel des ventes, art et son.

## Documentation

| Document | Contenu |
|---|---|
| [docs/GDD.md](docs/GDD.md) | Game Design Document : vision, univers, systèmes, architecture, phases |
| [docs/TODO.md](docs/TODO.md) | Liste des tâches par phase |
| [docs/CATALOGUE.md](docs/CATALOGUE.md) | Objets, monstres et sorts (généré) |
| [docs/METIERS.md](docs/METIERS.md) · [docs/CLASSES.md](docs/CLASSES.md) | Toutes les variables des métiers et de la forge, des classes et des races, pour l'équilibrage (générés) |
| [docs/design/](docs/design/) | Documents de design détaillés (équilibrage, formules, tableurs) |
| [docs/lore/](docs/lore/) | Univers, histoire, personnages, régions |
| [docs/decisions/](docs/decisions/) | Journal des décisions techniques et de design |

## Feuille de route

| Phase | Objectif | État |
|---|---|---|
| 0. Pré-production | Moteur choisi, GDD validé | ✅ |
| 1. Prototype | Un combat jouable de bout en bout | ✅ |
| 2. Alpha | Alpha test 1 (mécaniques), puis alpha test 2 (progression sans niveaux, art et son) | 🟡 en cours |
| 3. Solo étendu | 9 races, 9 classes, système des Voies, donjons, quêtes complexes, légendaires | ⚪ |
| 4. Fondations réseau | Serveur autoritaire, comptes, combat à plusieurs | 🟡 prototype fait (M0–M2) |
| 5. Multijoueur | Instances, groupe, amis, chat, échanges, guildes, hôtel des ventes | 🟡 commencé (M3–M4) |

## Structure du dépôt

```
Retro_Venture/
├── docs/          # GDD, TODO, design, lore, décisions
├── .github/       # Intégration continue (tests Godot)
├── game/          # Projet Godot 4
│   ├── core/      # Noyau de jeu : règles, sans affichage (partagé par le solo et le serveur)
│   ├── client/    # Scènes, rendu isométrique, interface, audio
│   ├── data/      # Contenu piloté par les données (sorts, monstres, objets, quêtes…)
│   ├── assets/    # Graphismes, sons, musiques, polices
│   ├── server/    # Serveur multijoueur sans affichage (WebSocket)
│   ├── tools/     # Captures, simulation de combats, joueur automatique
│   └── tests/     # Tests automatisés
└── serveur/       # Docker et tunnel pour héberger le serveur de test
```

## Démarrer

**Sans rien installer :** chaque push déclenche la CI, qui lance les tests, exporte le jeu pour le
web et le publie sur GitHub Pages (lien ci-dessus) en quelques minutes. Les résultats des tests sont
visibles dans l'onglet [Actions](https://github.com/Ottoreg/Retro_Venture/actions) (résumé en bas
de chaque exécution).

**Avec l'éditeur :**

1. Installer [Godot 4.5](https://godotengine.org/download) (version standard, pas .NET).
2. Ouvrir `game/project.godot` dans l'éditeur, puis lancer avec **F5**.
3. Tests en ligne de commande :
   ```sh
   godot --headless --path game --import
   godot --headless --path game -s res://tests/run_tests.gd
   ```

Choix techniques : [moteur Godot 4](docs/decisions/0001-moteur-godot-4.md),
[langage GDScript](docs/decisions/0002-langage-gdscript.md),
[données JSON](docs/decisions/0003-donnees-json.md),
[grille 64×32](docs/decisions/0004-grille-isometrique.md).
