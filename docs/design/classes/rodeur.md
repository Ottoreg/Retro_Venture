# Rôdeur — Acier / Flamme

**État** : conçu et codé le 23/11/2026 (propositions du document « Rôdeur : questions de design » validées telles
quelles par l'auteur). Même texte que le GDD § 4.3, « Rôdeur : conception finale ». Valeurs actuelles : [CLASSES.md](../../CLASSES.md).



- *Identité* : distance et mobilité, famille mixte ; 50 PV, 6 PA, 3 PM, 100 d'initiative. Voie Acier : Force (l'archer
  pisteur) ; Voie Flamme : Intelligence (le poseur de pièges et d'explosifs), chacune pure. La **Tempête disparaît** du
  Rôdeur : *Flèche* passe en Acier (5 à 8). *Collet* reste dans la Voie Acier. Même planche, sorts joués avec l'attaque
  de la race. Pondération de `tools/simulation.gd` : Force et Intelligence à parts égales.
- *Passif* **Rabatteur** (Apprenti, 5 rangs, effet `rabatteur`) : un ennemi **poussé ou attiré sur un piège** du Rôdeur
  (de n'importe quel sort à piège) subit **+20 % de dégâts du piège, +4 % par rang** (40 % au rang 5). Rang 3 : il est
  aussi **immobilisé** (0 PM) à son prochain tour. Rang 5 : le Rôdeur récupère **1 PA**, une fois par tour. Il lie les
  deux Voies : la Voie Acier pousse (*Flèche de rabat*), la Voie Flamme pose.
- *Signature Acier* **Traces** (effet `trace`, crans, 3 au plus, 3 tours) : *Pister* en pose 2, *Flèche*, *Tir perçant*
  et *Flèche de rabat* une ; *Coup de dague* les consomme toutes (+30 % de dégâts par Trace, champ `par_trace`).
- *Signature Flamme* **Mines et Détonateur** : *Mine* pose 2 pièges explosifs à la fois (le 3e chasse le plus ancien,
  champ `pieges_max` des sorts) ; *Détonateur* (effet `detonateur`) les fait toutes sauter d'un coup, +10 % de dégâts
  par Mine qui saute ; sans Mine posée, il est grisé (« Aucun piège à faire sauter »). Les Mines touchent les ennemis
  dans un cercle de 1 autour d'elles.
- *Voie Acier* (10, « relance » = tours entre deux lancers ; Traces notées T) :

| Rôle | Sort | PA | Portée | Effet | Rang 3 | Rang 5 |
|---|---|---|---|---|---|---|
| Signature | *Pister* | 2 | 1–8, sans ligne de vue | +2 T ; 1 par tour | +2 portée | +1 T de plus |
| Dégâts de base | *Flèche* | 3 | 2–6 | 5 à 8 Acier, +1 T ; 2 par tour | +1 portée | 3 par tour |
| Dégâts | *Tir perçant* | 4 | 3–7 | 8 à 11 Acier, +1 T ; 1 par tour | l'ennemi juste derrière la cible prend 10 à 14 (`derriere`) | ignore 20 % de la résistance (`perce_resistance`) |
| Gros coup | *Tir de grâce* | 5 | 3–7 | 15 à 20 Acier ; 1 par tour | +30 % contre une cible sous 30 % de ses PV (`execution`) | relancé aussitôt s'il tue (`relance_si_tue`) |
| Combo | *Coup de dague* | 2 | mêlée | 3 à 5 Acier, +30 % par T (consommées) ; 2 par tour | +40 % par T | −1 PM par T consommée (`pm_par_trace`) |
| Contrôle | *Collet* | 3 | 1–4 | piège invisible : 7 à 10 Acier et −2 PM ; relance 2 | −3 PM | 2 Collets à la fois |
| Contrôle | *Flèche de rabat* | 3 | 2–6 | 3 à 5 Acier, poussée de 2, +1 T ; 1 par tour | poussée de 3 | une cible à plus de 3 cases est attirée (d'autant) au lieu d'être poussée (`attire_au_dela`) |
| Mobilité | *Roulade* | 2 | 1–2, case libre | téléportation ; relance 2 | +1 portée | relance 1 |
| Défense | *Couvert* | 2 | soi | −25 % de dégâts reçus à distance (2 cases ou plus, caractéristique `reduction_distance`) 2 tours ; relance 3 | −35 % | aussi les alliés à 1 case |
| Soutien | *Œil de faucon* | 2 | 0–5, soi ou allié | +2 portée et +10 % de critique 2 tours ; relance 4 | 3 tours | +5 % de critique de plus, 3 tours |

- *Voie Flamme* (10) :

| Rôle | Sort | PA | Portée | Effet | Rang 3 | Rang 5 |
|---|---|---|---|---|---|---|
| Signature | *Mine* | 2 | 1–5, sans ligne de vue | piège invisible : 6 à 8 Flamme, cercle de 1 ; 2 à la fois ; 2 par tour | 3 Mines à la fois | cercle de 2 |
| Signature | *Détonateur* | 3 | soi | toutes ses Mines sautent, +10 % par Mine ; 1 par tour | +15 % par Mine | +1 PA par Mine qui touche (`pa_par_piege`) |
| Dégâts de base | *Flèche enflammée* | 3 | 2–6 | 5 à 8 Flamme ; 2 par tour | +1 portée | fait sauter ses Mines à 1 case de la cible (`rayon`) |
| Zone | *Bombe artisanale* | 4 | 2–5, sans ligne de vue | 7 à 10 Flamme, cercle de 1 ; 1 par tour | +1 portée | 2 par tour |
| Gros coup | *Flèche explosive* | 5 | 3–7 | 7 à 9 Flamme sur le cercle de 1, encore 7 à 9 sur la cible seule (`centre_seul`) ; 1 par tour | les voisins sont poussés d'1 case depuis la cible (`depuis_centre`) | +20 % de dégâts (`bonus_pct`) |
| Contrôle | *Mâchoire de loup* | 3 | 1–4 | piège invisible : 6 à 9 Flamme et état **enchaîné** 3 tours (ne finit aucun déplacement à plus de 3 cases du piège, 5 pour un boss ; marche, poussée, téléportation et charge comprises) ; relance 2 | 4 tours | poison Flamme 3 par tour, 4 tours |
| Contrôle | *Piège à fil* | 4 | 2–5 | 2 fils perpendiculaires au Rôdeur et un explosif à chaque bout (4 cases) : traverser un fil ou marcher sur un explosif fait sauter les deux explosifs (8 à 11 Flamme, cercle de 1 autour de chacun) ; relance 2 | −1 PM aussi | 4 fils (6 cases) |
| Mobilité | *Saut à la poudre* | 3 | 2–4, case libre | téléportation, 4 à 6 Flamme aux ennemis à 1 case de la case de départ (`au_depart`) ; relance 2 | +1 portée | laisse une Mine sur la case de départ (compte parmi ses Mines) |
| Défense | *Écran de fumée* | 2 | soi | glyphe de fumée (cercle de 1) 2 tours : **coupe la ligne de vue** dans les deux sens (champ `fumee`) ; relance 3 | 3 tours | −1 PM aux ennemis qui y sont |
| Soutien | *Fusée éclairante* | 2 | 1–7, sans ligne de vue | cercle de 3 : **révèle** les pièges ennemis (montrés au camp du Rôdeur) et les invisibles (effet `revelation`), −15 % de résistance Flamme 2 tours aux ennemis ; relance 2 | cercle de 4 | −10 % de plus |

- *Adaptations faites en codant* (signalées à l'auteur) : *Flèche de rabat* au rang 5 attire au lieu de pousser une
  cible à plus de 3 cases (plutôt que « choisir le sens ») ; *Bombe artisanale* au rang 3 gagne +1 portée ; le
  Rabatteur monte de 4 % par rang (20 % à Apprenti, 40 % au rang 5) ; *Tir de grâce* reprend le champ `execution` du
  Guerrier. Le Piège à fil pose ses cases sur une ligne perpendiculaire à la direction lanceur → case visée, centrée sur
  elle ; les cases infranchissables sont sautées.
- *Mécaniques nouvelles* : pièges à plusieurs cases de déclenchement (champ `declencheurs` de l'événement `piege_pose`),
  zone de piège `fil`, nombre de pièges par sort, glyphe de fumée qui bloque la vue, révélation des pièges ennemis (le
  client les montre en rouge, infobulle « Piège ennemi »), état `enchaine`, raisons de refus `enchaine` et
  `aucun_piege` ; changements de rang `pieges_max`, `zone_piege`, `duree` (au sol compris), `effets_au_sol`
  (effets ajoutés dans un piège ou une glyphe) et `modifie` (`{ type d'effet : { clé : valeur } }`) ; protocole v26.
  L'IA des monstres sait se servir du Détonateur (pour un Rôdeur joué par l'IA dans les simulations).
- *Plus tard* : aucun monstre ne joue la classe ; 3e Voie Lumière ou Ténèbres à trancher (pistes plus bas).

