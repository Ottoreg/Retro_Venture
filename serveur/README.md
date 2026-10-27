# Serveur de jeu (prototype M1)

Serveur Godot 4.5 sans affichage qui fait autorité (GDD § 16.5) : il fait tourner le même `game/core/`
que le solo, reçoit les commandes des clients par WebSocket et leur renvoie les événements. Code :
`game/server/` ; client : `game/client/net/remote_connection.gd`, écran `game/client/online/`.

Deux façons de le lancer :

- **Développement** (sans Supabase) : pseudos sans mot de passe, personnages dans un dossier.
- **Serveur de test, ou « staging »** (Supabase + tunnel Cloudflare) : comptes, personnages dans
  la base, adresse publiée automatiquement pour le jeu sur GitHub Pages et le client natif.

**Staging** : c'est l'environnement de test, qui suit toujours `main`. À chaque push sur `main`, la
CI publie à la fois le jeu web, le client natif et l'image Docker du serveur
(`ghcr.io/ottoreg/retro-venture-serveur:staging`) : client et serveur ont toujours la même version
(même protocole). Le PC qui sert de serveur reprend la dernière image à chaque lancement, sans
cloner ni compiler le dépôt. Plus tard (bêta), une **production** sur un VPS, mise à jour à la main
et avec sa propre base, pour que les essais ne cassent pas les parties des joueurs.

**Client natif** (Windows, Linux) : release « client-natif » du dépôt
(https://github.com/Ottoreg/Retro_Venture/releases/tag/client-natif), mise à jour à chaque push sur
`main`. Windows avertit (pas de certificat de signature) : « Informations complémentaires » puis
« Exécuter quand même ».

## Développement, sur son poste

Avec Godot 4.5.1 (depuis la racine du dépôt) :

```sh
godot --headless --path game -s res://server/server_main.gd
```

Puis dans le jeu : Options → « Adresse du serveur » : `ws://localhost:8080`, et menu « Jouer en
ligne (prototype) » avec un pseudo. Pour voir un autre joueur sans second poste, un joueur
automatique qui se promène et répond aux messages privés (chat, jalon M3) :

```sh
godot --headless --path game -s res://tools/bot.gd -- ws://localhost:8080 Robotin
```

## Serveur de test sur le PC de l'auteur

À faire une fois (Supabase), puis à chaque session de test (Docker). Aucune clé n'est à coller dans
une conversation : elles vont dans des fichiers sur le PC (ou, pour la clé publique, dans le dépôt).

### Une fois : le projet Supabase

1. Sur https://supabase.com, créer un compte puis un projet (offre gratuite, région Europe ;
   noter le mot de passe de la base dans un gestionnaire de mots de passe, il ne sert pas au jeu).
2. **SQL Editor** → New query → coller tout `serveur/supabase/schema.sql` → **Run**.
3. **Authentication → Sign In / Providers → Email** : laisser « Confirm email » activé.
   **Authentication → URL Configuration** : *Site URL* = `https://ottoreg.github.io/Retro_Venture/`
   (le lien du courriel de confirmation y ramène).
4. **Project Settings → API Keys** : repérer la clé **publishable** (`sb_publishable_…`, publique)
   et créer une clé **secret** (`sb_secret_…`, secrète). **Project Settings → Data API** : l'adresse
   du projet (`https://….supabase.co`).
5. Dans le dépôt, remplir `game/client/net/online_config.gd` : `SUPABASE_URL` et `PUBLISHABLE_KEY`
   (la clé publique est faite pour être dans le jeu). Pousser sur `main` : le jeu web se met à jour.

### Une fois : rendre l'image du serveur publique

Après le premier passage de la CI qui la publie : https://github.com/Ottoreg?tab=packages →
**retro-venture-serveur** → **Package settings** → *Change visibility* → **Public** (elle ne
contient que le code du jeu, déjà public ; sinon chaque poste doit faire `docker login ghcr.io`).

### Sur chaque poste qui peut servir de serveur

1. Installer **Docker Desktop** (Windows : avec WSL 2, proposé à l'installation) et le lancer.
2. Récupérer le dossier `serveur/` du dépôt (un clone, ou seulement `docker-compose.yml` et
   `exemple.env`). Y copier `exemple.env` en `.env` et le remplir :
   `SUPABASE_URL`, `SUPABASE_SECRET_KEY` (la clé secrète), `RV_POSTE` (le nom du poste). Le fichier
   `.env` n'est jamais commité (`.gitignore`).

### Lancer et arrêter

```sh
cd serveur
docker compose up -d              # démarre le serveur (dernière image de main) et le tunnel
docker compose logs -f serveur    # « Adresse publique : wss://….trycloudflare.com » une fois prêt
docker compose down               # arrête tout
```

- Le serveur écrit son adresse dans Supabase toutes les 30 s ; le jeu (web ou natif) la lit avant
  de se connecter. Rien à saisir pour les joueurs.
- **Un seul poste à la fois** : un serveur refuse de démarrer si un autre a donné signe de vie depuis
  moins de 90 s (message dans le journal). Après un `docker compose down` sur un poste, attendre
  90 s avant de lancer l'autre.
- Les personnages sont chez Supabase : on peut changer de poste sans rien copier.
- Si l'adresse publique n'apparaît pas dans le journal du serveur, la lire dans celui du tunnel
  (`docker compose logs tunnel`, ligne en `https://….trycloudflare.com`) et l'ajouter dans `.env` :
  `RV_PUBLIC_ADDRESS=wss://….trycloudflare.com`, puis `docker compose up -d`.
- Sur le poste du serveur, le jeu peut aussi viser `ws://localhost:8080` (Options).

Pour essayer un serveur construit depuis son clone (changements pas encore sur `main`) :
`docker compose -f docker-compose.yml -f docker-compose.local.yml up --build -d`.

## Réglages (variables d'environnement)

| Variable | Rôle |
|---|---|
| `RV_PORT` | Port WebSocket (8080) |
| `SUPABASE_URL`, `SUPABASE_SECRET_KEY` | Comptes et personnages dans Supabase ; sans elles, serveur de développement |
| `RV_DATA_DIR` | Dossier des personnages du serveur de développement (`user://serveur`, `/donnees` dans Docker) |
| `RV_TUNNEL_METRICS` | Métriques de cloudflared, pour lire l'adresse du tunnel rapide (mis par `docker-compose.yml`) |
| `RV_PUBLIC_ADDRESS` | Adresse publique fixe (`wss://…`), à la place de celle du tunnel |
| `RV_POSTE` | Nom du poste, montré si un autre serveur tourne déjà |

## Ce que fait le prototype (M1)

- Compte (inscription avec confirmation par courriel, connexion) ; un personnage par compte, pseudo
  unique ; création, chargement et sauvegarde sur le serveur (fin de combat, changement de carte,
  déconnexion, toutes les 60 s).
- Deux joueurs sur la même carte se voient arriver, bouger, s'asseoir et partir ; le nom, le niveau,
  la race et la Voie au survol.
- Combats encore en solo mais calculés par le serveur : le groupe attaqué disparaît pour les autres
  (il revient si le joueur perd ou se déconnecte).
- Reconnexion : on retrouve son personnage là où on l'a laissé ; un compte connecté ailleurs
  remplace l'ancienne connexion.
- Protocole versionné (`Protocol.VERSION`) : un client trop ancien est prié de recharger la page ;
  limite de débit par connexion.
