# Chantier 3 — Contenu du monde

Document de conception, généré par `src/build.py` (contrôle de cohérence : `src/controle.py`). Brouillon à valider avant toute production.

## 1. Résumé

- **48 cartes** (42 nouvelles), **49 monstres** (familles, élites, mini-boss, variantes), **65 sorts nouveaux** (18 réutilisés), **94 objets**, **14 nouveaux dessins** et 94 icônes.

| Zone | Cartes | Niveaux | Familles par palier | Mini-boss |
|---|---|---|---|---|
| Collines de Brumerive | 10 | 1–12 | 1-3 : Loup des collines ; 4-6 : Gobelin frondeur ; 7-9 : Gobelin pillard, Épouvantail démotivé ; 10-12 : Gobelin briseur | Krasbouk, Chef de Raid (syndiqué) (niv. 12) |
| Galeries de Crasse-Roc | 10 | 1–12 | 1-3 : Rat des galeries, Grouilleur ; 4-6 : Vampipistrelle ; 7-9 : Milicien de Hautepierre ; 10-12 : Contremaître zélé | Le Balourd des Abîmes (niv. 12) |
| Lisière de Sylvebrume | 9 | 1–12 | 1-3 : Morille grincheuse ; 4-6 : Cerf enchanté, Arbre vivant ; 7-9 : Bûcheron de Brumerive ; 10-12 : Tisseuse de brume | La Mère-Toile (niv. 12) |
| Hautepierre et ses environs | 19 | 13–30 | 13-15 : Détrousseur des grands chemins ; 16-18 : Troll des ponts ; 19-21 : Corbac espion ; 22-24 : Gargouille ; 25-27 : Cendrillon ; 28-30 : Olifant de guerre | Grondin, Bélier de la Brèche (niv. 30) |
| Variantes corrompues | — | — | Loup cendreux, Grouilleur de braise, Arbre calciné | — |

**Ce que le joueur vit.** Chaque race commence dans sa zone (1 → 12) : quatre paliers de familles, une élite par famille, un mini-boss au bout, puis des variantes corrompues. Vers le niveau 12, il rejoint Hautepierre (13 → 30) : la ville, ses environs et le boss Grondin. Les nouveaux métiers (if, hêtre, malorme ; étain, argent, obsidienne) et les recettes demandent des butins de plusieurs zones, ce qui pousse à voyager.

## 2. Règles suivies

- Paliers 1–3 / 4–6 / 7–9 / 10–12 dans chaque zone de départ, asymétriques entre zones ; niveau variable dans une famille, pondéré (faible 6/3/1, moyen 3/4/3, fort 1/3/6).
- Le niveau d'un monstre change ses stats, pas son butin ; PA/PM fixes par famille sauf mécanique spéciale.
- Élites : niveau > max de la famille, PV ≥ 2× la base, butin non commun plus fréquent.
- Formats de données : ceux de `game/data/README.md` ; ids nouveaux sans collision avec `game/data` (vérifié par `src/controle.py`).

## 3. Collines de Brumerive

Palette `brumerive` ; Pierre de Passage `brumerive` sur `brumerive_0_0` (10 écus, existante). 10 cartes.

```
          x=0                     x=1                      x=2                       x=3
y=0  [Village 1-3 *]  ──  [Champs de l'est 1-6] ──  [Verger des Pommeaux 7-9]
          │                       │                        │
y=1  [Rives de la Brume 1-3] ── [Moulin de Tournevent 4-6] ── [Lande aux épouvantails 7-9] ── [Gué de Brume-Haute 10-12] ══+ (porte) Hautepierre 0_2
                                  │                        │                          │
y=2                       [Les Grands Blés 7-9] ── [Camp du raid 10-12] ── [Palissade de Krasbouk ☠ 12]
```

**Progression.** Humains : départ calme, puis le raid monte en puissance. Palier 1–3 : une seule famille (loups) sur 3 cartes (village, Rives, Champs) — on apprend à se battre sans surprise. Palier 4–6 : maigre (frondeurs seuls, Champs et Moulin) — les frondeurs à distance obligent à apprendre à se cacher derrière les obstacles. Palier 7–9 : généreux (pillards + épouvantails, Verger, Lande, Grands Blés : 3 cartes) — c'est là que l'humain prend son équipement (Pyromane, Enfant de Chœur). Palier 10–12 : briseurs (Camp du raid, Gué) puis Krasbouk. Asymétrie : beaucoup de mêlée, peu de magie ; le milieu de zone est le plus riche, la fin est courte et passe vite à Hautepierre par le Gué.

### 3.1 Cartes

**`brumerive_0_0` — Place du village** (existante ; palier 1-3 ; x=0, y=0 ; Pierre de Passage)
- Sorties : droite → `brumerive_1_0`, bas → `brumerive_0_1`.
- Ambiance : Le village de départ des humains, inchangé.
- Plan : Retouches seulement : ouvrir 3 cases au bas du plan (colonnes 8 à 10 de la dernière ligne, en « . ») pour la sortie bas ; maison, auberge, porte, pierre et PNJ inchangés.
- Ressources : F×5, U×3 (inchangées).
- Groupes : 1. loup_des_collines; 2. loup_des_collines + loup_des_collines; 3. 1–3 parmi {loup_des_collines}. Le 3e groupe (frondeur + loup, palier 4–6) devient 1 à 3 loups : la place du village reste au palier 1–3.
- PNJ : Alric, Barlimon et Célébrimbert restent tels quels.

**`brumerive_1_0` — Champs de l'est** (existante ; palier 1-6 ; x=1, y=0)
- Sorties : gauche → `brumerive_0_0`, droite → `brumerive_2_0`, bas → `brumerive_1_1`.
- Ambiance : Carte de transition : les loups des collines croisent les premiers frondeurs.
- Plan : Retouches : ouvrir la dernière ligne (colonnes 8 à 10) pour la sortie bas ; la colonne de droite est déjà praticable sur les lignes 13 à 21. Muret de l'est conservé.
- Ressources : C×5, U×1, I×3 (inchangées).
- Groupes : 1. 1–2 parmi {loup_des_collines, gobelin_frondeur}; 2. gobelin_frondeur + gobelin_frondeur; 3. gobelin_frondeur + loup_des_collines.
- PNJ : Grizzik reste.

**`brumerive_0_1` — Rives de la Brume** (nouvelle ; palier 1-3 ; x=0, y=1)
- Sorties : haut → `brumerive_0_0`, droite → `brumerive_1_1`.
- Ambiance : Berges brumeuses de la rivière qui donne son nom à la région ; roseaux, ponton vermoulu, barque retournée.
- Plan : Une large bande d'eau (E) en diagonale du haut-gauche au bas-droite, traversée par un gué de 3 cases (« . ») au milieu ; berges d'arbres (A) clairsemés, quelques rochers (R) ; chemin de terre (:) du haut (vers le village) jusqu'au gué puis vers la droite. Départ (@) en haut, près de la sortie.
- Ressources : F×3, U×2.
- Groupes : 1. loup_des_collines; 2. 2–3 parmi {loup_des_collines}; 3. loup_des_collines + loup_des_collines.
- PNJ `a` **Gobillon, ermite des berges** (`gobillon_l_ermite`) — PNJ d'ambiance (humour) : « Mon prêêêt… Il m'a jamais rendu mon prêt, le berger ! Trois pièces, qu'il me doit. Trois ! » / « Nous on aime pas les aventuriers. Ils posent des questions. Ils marchent dans nos roseaux. » / « Les loups ? Les loups mangent pas Gobillon. Gobillon a mauvais goût. Gobillon en est fier. »

**`brumerive_1_1` — Moulin de Tournevent** (nouvelle ; palier 4-6 ; x=1, y=1)
- Sorties : haut → `brumerive_1_0`, gauche → `brumerive_0_1`, droite → `brumerive_2_1`, bas → `brumerive_1_2`.
- Ambiance : Un moulin à vent sur une butte, des sacs de farine éventrés : les frondeurs s'y sont installés en hauteur.
- Plan : Moulin : décor « maison » au centre-haut (3×3 de #) et murets autour ; butte de rochers (R) qui coupe les lignes de vue, champs labourés en chemins (:) croisés ; une mare (E) de 2×3 au bas-gauche.
- Ressources : F×2, C×2, I×1.
- Groupes : 1. gobelin_frondeur + gobelin_frondeur; 2. gobelin_frondeur; 3. 2–3 parmi {gobelin_frondeur}; 4. gobelin_frondeur + loup_des_collines.
- PNJ `a` **Bernardin Tourneboule, meunier** (`bernardin_tourneboule`) — PNJ d'ambiance : « Mon moulin tourne au vent. Le vent tourne au gobelin. Et moi, je tourne en rond. » / « Les frondeurs se sont perchés sur ma butte. Ils disent que c'est stratégique. Moi je dis que c'est ma butte. » / « Si vous allez vers les Grands Blés, au sud, méfiez-vous des épouvantails. Ils ont des revendications. »

**`brumerive_2_0` — Verger des Pommeaux** (nouvelle ; palier 7-9 ; x=2, y=0)
- Sorties : gauche → `brumerive_1_0`, bas → `brumerive_2_1`.
- Ambiance : Un verger pillé : pommiers en rangs, ferme aux volets arrachés, poulailler vide. Les pillards gobelins s'y servent.
- Plan : Rangées régulières d'arbres (A) espacés de 2 cases (le verger), ferme : décor « maison » en haut-droite, enclos de murets (#/muret) ; chemin (:) de gauche vers la ferme puis vers le bas ; quelques souches.
- Ressources : F×3, C×2, Y×1.
- Groupes : 1. gobelin_pillard; 2. gobelin_pillard + gobelin_pillard; 3. gobelin_pillard + gobelin_frondeur; 4. 2–3 parmi {gobelin_pillard, gobelin_frondeur}.
- PNJ `a` **Mère Pomponne, fermière** (`mere_pomponne`) — PNJ d'ambiance (future quête : rapporter les sacs de rapine) : « Ils ont pris mes pommes, mes poules et mon mari. Rapportez-moi au moins les poules. » / « Le mari ? Oh, il reviendra. Il revient toujours quand il a faim. » / « Les pillards cachent leur butin dans des sacs. Si vous en trouvez, il y a peut-être un chandelier à moi dedans. »

**`brumerive_2_1` — Lande aux épouvantails** (nouvelle ; palier 7-9 ; x=2, y=1)
- Sorties : haut → `brumerive_2_0`, gauche → `brumerive_1_1`, droite → `brumerive_3_1`, bas → `brumerive_2_2`.
- Ambiance : Une lande de bruyère à l'abandon, plantée d'épouvantails qui tournent la tête quand on passe.
- Plan : Terrain ouvert (peu d'obstacles : les épouvantails n'ont que 2 PM, ils doivent pouvoir être contournés), quelques rochers (R) en îlots, un vieux muret en arc au centre ; chemins (:) en croix vers les 4 sorties.
- Ressources : C×2, I×2, Y×2, T×1.
- Groupes : 1. epouvantail_demotive; 2. epouvantail_demotive + epouvantail_demotive; 3. 1–3 parmi {epouvantail_demotive}; 4. epouvantail_demotive + gobelin_pillard.

**`brumerive_1_2` — Les Grands Blés** (nouvelle ; palier 7-9 ; x=1, y=2)
- Sorties : haut → `brumerive_1_1`, droite → `brumerive_2_2`.
- Ambiance : Un champ de blé en labyrinthe, une grange (décor « cabane »), des épouvantails en grève.
- Plan : Labyrinthe de blé : les murs du labyrinthe en rochers bas (R, à remplacer plus tard par un décor « blé » si on le dessine) laissant des allées de 1 à 2 cases ; grange en bas-gauche ; une clairière centrale (5×5 praticable) pour les combats.
- Ressources : F×2, Y×2, T×2.
- Groupes : 1. epouvantail_demotive + epouvantail_demotive; 2. epouvantail_demotive; 3. gobelin_pillard + epouvantail_demotive.
- PNJ `a` **Gaudin, fermier** (`fermier_gaudin`) — PNJ d'ambiance : « Les épouvantails se sont mis en grève. Ils disent qu'on ne les paie pas. » / « On ne les a jamais payés : ce sont des épouvantails ! … C'est ce qu'ils disent aussi, remarquez. » / « Depuis, ce sont les corbeaux qui gardent les champs. Contre nous. »

**`brumerive_2_2` — Camp du raid** (nouvelle ; palier 10-12 ; x=2, y=2)
- Sorties : haut → `brumerive_2_1`, gauche → `brumerive_1_2`, droite → `brumerive_3_2`.
- Ambiance : Le campement du raid gobelin : tentes de peaux, feux de camp, tas de butin, panneau « Raid de Brumerive — Équipe de nuit ».
- Plan : Deux décors « cabane » (tentes) et une palissade de murs (M) en U ouverte vers la droite (vers la Palissade de Krasbouk) ; foyers en rochers (R) isolés ; chemin (:) central.
- Ressources : I×2, T×2.
- Groupes : 1. gobelin_briseur; 2. gobelin_briseur + gobelin_briseur; 3. 2–3 parmi {gobelin_briseur, gobelin_pillard}; 4. gobelin_briseur + gobelin_frondeur.

**`brumerive_3_1` — Gué de Brume-Haute** (nouvelle ; palier 10-12 ; x=3, y=1)
- Sorties : gauche → `brumerive_2_1`, bas → `brumerive_3_2` ; portes : `hautepierre_0_2`.
- Ambiance : Le gué où la route de Brumerive rejoint celle de Hautepierre ; une borne, un poste de garde humain, des briseurs qui rôdent.
- Plan : Rivière (E) verticale sur 3 colonnes au tiers droit, gué de pierres praticable sur 3 lignes au milieu ; route (:) de gauche à droite par le gué jusqu'au passage « + » sur le bord droit (porte vers hautepierre_0_2, avec le décor « poteau_indicateur » sur une case # voisine) ; poste de garde (décor « cabane ») côté droit.
- Ressources : Y×2, T×1, I×1.
- Groupes : 1. gobelin_briseur + gobelin_briseur; 2. gobelin_briseur; 3. 1–2 parmi {gobelin_briseur}.
- PNJ `a` **Hubert, sentinelle de Hautepierre** (`sentinelle_hubert`) — PNJ d'ambiance, annonce Hautepierre : « Hautepierre est à l'est. Pour y entrer, il faut un laissez-passer. » / « Pour avoir un laissez-passer, il faut aller au bureau des laissez-passer. Qui est à Hautepierre. » / « Bon, passez. Mais si on vous demande, vous avez un laissez-passer. »
- Lien entre zones : Les sorties ne changent pas de zone (test des coordonnées) : le lien avec Hautepierre est une porte « + » (route), posée par le lot Hautepierre qui crée les deux côtés en même temps.

**`brumerive_3_2` — Palissade de Krasbouk** (nouvelle ; palier 10-12 ; x=3, y=2 ; **boss**)
- Sorties : gauche → `brumerive_2_2`, haut → `brumerive_3_1`.
- Ambiance : La palissade du chef de raid : pieux, étendard, tableau d'affichage syndical (« Pause : 3 fois par heure »).
- Plan : Palissade de murs (M) en grand rectangle avec deux ouvertures (gauche et haut) ; à l'intérieur une grande tente (décor « auberge » recolorée ou « cabane ») et l'arène dégagée (7×7) où attend Krasbouk ; deux tours de guet en rochers.
- Ressources : T×1.
- Groupes : 1. krasbouk + gobelin_frondeur (réapparition 45–60 s); 2. gobelin_briseur + gobelin_briseur. Groupe 1 : le boss et son « secrétaire » (un frondeur qui prend des notes), fixe, réapparition en 1 min au plus.

### 3.2 Familles

| Famille | Palier | Rôle | Niv. de base : PV / PA / PM | XP base | Élite (niv., PV) |
|---|---|---|---|---|---|
| Loup des collines | 1-3 | moyen | 18 / 6 / 4 | 16 | Loup alpha (7, 70) |
| Gobelin frondeur | 4-6 | faible | 22 / 6 / 3 | 35 | Frondeur vétéran (9, 60) |
| Gobelin pillard | 7-9 | fort | 38 / 6 / 3 | 62 | Pillard émérite (12, 118) |
| Épouvantail démotivé | 7-9 | moyen | 38 / 7 / 2 | 62 | Grand Épouvantail (12, 118) |
| Gobelin briseur | 10-12 | fort | 65 / 6 / 3 | 116 | Défonceur de portes (15, 187) |

#### Loup des collines (`loup_des_collines`) *(existante, retouchée)* — palier 1-3, famille moyen, gabarit standard
*Affamé en permanence. Considère les aventuriers comme un en-cas.*

- Niveaux 1–3 (poids 3/4/3) ; base (niv. 1) : PV 18, PA 6, PM 4, Ini 100 ; par niveau : pv +4, initiative +5, xp +7, force +4.
- Résistances : Acier +0, Flamme -10, Givre +10, Tempête +0 ; IA `basique` ; XP 16 (+7/niv.) ; écus 2–6.
- Sorts : 
  - `loup_morsure` (existant)
- Butin : croc_de_loup 50 % ×1–2, peau_de_loup 30 %, amulette_croc 6 %, cape_en_peau_de_loup 3 %, bonnet_de_berger 5 %, anneau_mauvais_oeil 2 %, ceinture_mauvais_oeil 2 %, bottes_mauvais_oeil 2 %.
- Dessin : image `loup` (échelle 0.8).
- Modifications du fichier existant : Niveau de base 1 au lieu de 3, tranche 1–3 (poids 3/4/3) ; à son niveau 3 il garde exactement ses valeurs actuelles (26 PV, 110 d'initiative, 30 XP). Ajouter la Force par niveau et les pièces Mauvais Œil (anneau, ceinture, bottes) au butin.
- **Élite : Loup alpha** (`loup_alpha`) *(existante)*, niveau 7 — *Le chef de meute. Il ne chasse plus lui-même : il supervise, et il goûte.* PV 70, PA 7, PM 5, Ini 150, For 20 ; rés. Acier +10, Flamme -5, Givre +15, Tempête +5 ; XP 110 ; écus 10–25.
  - Sorts : `loup_morsure`, `alpha_croc_sanglant`
  - Butin : croc_de_loup 90 % ×2–4, peau_de_loup 70 % ×1–2, amulette_croc 25 %, cape_en_peau_de_loup 15 %, bonnet_de_berger 15 %, anneau_mauvais_oeil 6 %, ceinture_mauvais_oeil 6 %, bottes_mauvais_oeil 6 %.
  - Dessin : image `loup` (échelle 1.05 ; couleurs pelage #4e4f57, pelage_ombre #35363d, ventre #8a8478).
  - Modifications : Ajouter la Force (20) et les trois pièces du Mauvais Œil au butin ; le reste ne change pas.

#### Gobelin frondeur (`gobelin_frondeur`) *(existante, retouchée)* — palier 4-6, famille faible, gabarit tireur
*Éclaireur des raids gobelins. Ne s'approche jamais : ce n'est pas dans sa fiche de poste.*

- Niveaux 4–6 (poids 6/3/1) ; base (niv. 4) : PV 22, PA 6, PM 3, Ini 90 ; par niveau : pv +3, initiative +5, xp +6, force +4.
- Résistances : Acier +5, Tempête -5 ; IA `distance` ; XP 35 (+6/niv.) ; écus 5–12.
- Sorts : 
  - `gobelin_fronde` (existant)
- Butin : caillou_de_fronde 60 % ×1–3, fiche_de_paie_gobeline 15 %, anneau_du_frondeur 5 %, bottes_de_marche 5 %, fronde_reglementaire 3 %, anneau_courant_d_air 2 %, ceinture_courant_d_air 2 %, bottes_courant_d_air 2 %.
- Dessin : rig `gobelin` (arme fronde ; couleurs peau #6f9a3e, tunique #7a6040, manches #5a4630, pantalon #4a3a28, cheveux #2e2418).
- Modifications du fichier existant : Tranche 4–6 (poids 6/3/1, il reste surtout niveau 4 comme aujourd'hui). Ajouter Force et PV par niveau, et les pièces Courant d'Air (anneau, ceinture, bottes) au butin.
- **Élite : Frondeur vétéran** (`frondeur_veteran`) *(existante)*, niveau 9 — *Vingt ans de fronde au service du Souverain Cendré. Il attend toujours sa médaille.* PV 60, PA 8, PM 3, Ini 120, For 25 ; rés. Acier +15, Tempête +0 ; XP 140 ; écus 15–35.
  - Sorts : `gobelin_fronde`, `veteran_pluie_de_cailloux`, `veteran_chausse_trape`
  - Butin : caillou_de_fronde 90 % ×2–5, fiche_de_paie_gobeline 50 %, anneau_du_frondeur 20 %, bottes_de_marche 15 %, fronde_reglementaire 12 %, anneau_courant_d_air 6 %, ceinture_courant_d_air 6 %, bottes_courant_d_air 6 %.
  - Dessin : rig `gobelin_veteran` (arme fronde ; accessoires barbe ; couleurs peau #5f8a36, tunique #6e2a22, manches #8a8f96, pantalon #3a3028, cheveux #b0aaa0, ceinture #c9a04e).
  - Modifications : Niveau 8 → 9 (au-dessus de la tranche 4–6 + 3), PV 55 → 60, Force 25, XP 120 → 140 ; ajouter les pièces Courant d'Air au butin.

#### Gobelin pillard (`gobelin_pillard`) — palier 7-9, famille fort, gabarit standard
*Il prend tout ce qui n'est pas cloué. Ce qui est cloué, il revient le chercher avec une pince.*

- Niveaux 7–9 (poids 1/3/6) ; base (niv. 7) : PV 38, PA 6, PM 3, Ini 95, For 24, Agi 12 ; par niveau : pv +4, initiative +5, xp +12, force +4, agilite +2.
- Résistances : Acier +10, Tempête +5, Flamme -10, Givre +0 ; IA `basique` ; XP 62 (+12/niv.) ; écus 7–16.
- Sorts : 
  - **Estocade de pillard** (`pillard_estocade`, nouveau) : 3 PA, portée 1, 2/tour — 5–7 Acier. *Un coup rapide, avant que la victime ne compte ses poules.* 
  - **Vol à l'arraché** (`pillard_vol_a_l_arrache`, nouveau) : 2 PA, portée 1, 1/tour — 2–4 Tempête ; −2 Dommages (2 t). *Il vous prend quelque chose. Vous ne savez pas quoi, mais vous frappez moins fort.*
- Butin : sac_de_rapine 55 % ×1–2, ordre_de_raid 12 %, coutelas_de_pillard 4 %, bottes_de_rapine 5 %, coiffe_enfant_de_choeur 3 %, cape_enfant_de_choeur 3 %, amulette_enfant_de_choeur 3 %.
- Dessin : rig `gobelin` (arme epee ; accessoires chapeau_paille ; couleurs peau #7a9a42, tunique #8a2a22, manches #5a2018, pantalon #3e3226, cheveux #2a2018, ceinture #c9a04e).
- Note : Vient piller la campagne : vit dans le Verger, la Lande et les Grands Blés ; quelques-uns accompagnent les briseurs au Camp du raid.
- **Élite : Pillard émérite** (`pillard_emerite`), niveau 12 — *Trente ans de carrière, pas un seul jour de congé, et une cave pleine de chandeliers.* PV 118, PA 7, PM 3, Ini 125, For 54, Agi 32 ; rés. Acier +20, Tempête +15, Flamme -5, Givre +10 ; XP 221 ; écus 18–40.
  - Sorts : `pillard_estocade`, `pillard_vol_a_l_arrache`, `pillard_razzia`
  - **Razzia** (`pillard_razzia`, nouveau) : 4 PA, portée 0, cercle 1, sans ldv, lanceur exclu, 1/tour — 6–9 Acier. *Il tourne sur lui-même en hurlant le nom de son raid. Tout ce qui l'entoure prend un coup.*
  - Butin : sac_de_rapine 88 % ×2–4, ordre_de_raid 48 %, coutelas_de_pillard 16 %, bottes_de_rapine 20 %, coiffe_enfant_de_choeur 13 %, cape_enfant_de_choeur 13 %, amulette_enfant_de_choeur 13 %.
  - Dessin : rig `gobelin_veteran` (arme epee ; accessoires chapeau_paille, barbe ; couleurs peau #6a8a3a, tunique #6a1a14, manches #3e1410, pantalon #2e2620, cheveux #8a8478, ceinture #e0b860).

#### Épouvantail démotivé (`epouvantail_demotive`) — palier 7-9, famille moyen, gabarit standard
*Il ne fait plus peur à personne depuis des années. Alors il se venge, mollement mais souvent.*

- Niveaux 7–9 (poids 3/4/3) ; base (niv. 7) : PV 38, PA 7, PM 2, Ini 60, For 12, Agi 12 ; par niveau : pv +4, initiative +5, xp +12, force +2, agilite +2.
- Résistances : Acier +15, Tempête +10, Givre +5, Flamme -30 ; IA `basique` ; XP 62 (+12/niv.) ; écus 7–16.
- Sorts : 
  - **Coup de fourche** (`epouvantail_fourche`, nouveau) : 4 PA, portée 1–2, 1/tour — 6–9 Acier. *Trois dents, une seule intention.* 
  - **Nuée de corbeaux** (`epouvantail_nuee_de_corbeaux`, nouveau) : 3 PA, portée 2–5, sans ldv, 1/tour — 4–6 Tempête. *Il ne fait plus peur aux corbeaux, alors il travaille avec eux.*
- Butin : paille_ensorcelee 60 % ×1–3, citrouille_grimacante 12 %, chapeau_d_epouvantail 5 %, fourche_d_epouvantail 3 %, coiffe_pyromane_repenti 3 %, cape_pyromane_repenti 3 %, amulette_pyromane_repenti 3 %.
- Dessin : rig `humain` (arme fourche ; accessoires chapeau_paille ; couleurs peau #c9b27a, cheveux #e0c060, tunique #7a6a4a, manches #a08a5a, pantalon #5a6a8a, bottes #5a4632, ceinture #8a6a3a, chapeau #c8a85a). **Nouveau dessin** : arme « fourche » (petite, 2 dents de fer rouillé sur manche clair, même attache que le bâton).
- Note : Épouvantail = humain recoloré : peau de toile de jute, cheveux de paille, chapeau de paille et fourche. 2 PM seulement : il faut aller le chercher, ou se méfier de ses corbeaux.
- **Élite : Grand Épouvantail** (`grand_epouvantail`), niveau 12 — *Le doyen des champs. Il a fait fuir trois générations de corbeaux, puis s'est lassé.* PV 118, PA 8, PM 2, Ini 90, For 32, Agi 32 ; rés. Acier +25, Tempête +20, Givre +15, Flamme -25 ; XP 221 ; écus 18–40.
  - Sorts : `epouvantail_fourche`, `epouvantail_nuee_de_corbeaux`, `epouvantail_champ_maudit`
  - **Champ maudit** (`epouvantail_champ_maudit`, nouveau) : 3 PA, portée 1–4, cercle 1, sans ldv, 1/tour, délai 2 — glyphe 2 t : 3–5 Tempête (ennemis), −1 PM (1 t) (ennemis). *La terre se couvre d'épis noirs qui piquent les chevilles.*
  - Butin : paille_ensorcelee 90 % ×2–5, citrouille_grimacante 48 %, chapeau_d_epouvantail 20 %, fourche_d_epouvantail 13 %, coiffe_pyromane_repenti 13 %, cape_pyromane_repenti 13 %, amulette_pyromane_repenti 13 %.
  - Dessin : rig `humain_grand` (arme fourche ; accessoires chapeau_paille ; couleurs peau #b89a62, cheveux #d0a840, tunique #4e4232, manches #8a7448, pantalon #3e4a6a, bottes #3a2a1e, ceinture #6a4a2a, chapeau #8a6a3a).

#### Gobelin briseur (`gobelin_briseur`) — palier 10-12, famille fort, gabarit costaud
*Spécialiste des portes, des palissades et des idées des autres.*

- Niveaux 10–12 (poids 1/3/6) ; base (niv. 10) : PV 65, PA 6, PM 3, Ini 85, For 36 ; par niveau : pv +6, initiative +5, xp +16, force +4.
- Résistances : Acier +15, Flamme +5, Tempête -10, Givre +0 ; IA `basique` ; XP 116 (+16/niv.) ; écus 11–25.
- Sorts : 
  - **Coup de hache** (`briseur_coup_de_hache`, nouveau) : 4 PA, portée 1, 1/tour — 7–10 Acier. *Il brise les portes. Les genoux, c'est en bonus.* 
  - **Épaulée** (`briseur_epaulee`, nouveau) : 3 PA, portée 1, 1/tour — 3–5 Acier ; poussee 2. *Un coup d'épaule de professionnel : on recule, on réfléchit.* 
  - **Gnôle de raid** (`briseur_gnole`, nouveau) : 2 PA, portée 0, sans ldv, 1/tour, délai 3 — soin Acier 6–9. *Une gorgée de gnôle. Ça soigne, d'après l'étiquette.*
- Butin : gnole_de_raid 55 % ×1–2, medaille_en_chocolat 12 %, ceinture_a_gnole 5 %, ordre_de_raid 8 %.
- Dessin : rig `gobelin_veteran` (arme hache ; accessoires casque ; couleurs peau #6e8a40, tunique #4e4e58, manches #8a8f96, pantalon #3a3028, cheveux #1e1a16, ceinture #5a3a22, bottes #2e2620). **Nouveau dessin** : arme « hache » (partagée avec le bûcheron de Sylvebrume).
- Note : Le cœur du raid : mêlée, poussée et un petit soin. Groupes de 1 à 2 (3 seulement s'ils tirent bas).
- **Élite : Défonceur de portes** (`defonceur_de_portes`), niveau 15 — *Il n'a jamais ouvert une porte de sa vie. Il les a toutes défoncées, y compris celle de chez lui.* PV 187, PA 7, PM 3, Ini 115, For 66 ; rés. Acier +25, Flamme +15, Tempête -5, Givre +10 ; XP 359 ; écus 28–62.
  - Sorts : `briseur_coup_de_hache`, `briseur_epaulee`, `briseur_gnole`, `briseur_belier`
  - **Bélier humain** (`briseur_belier`, nouveau) : 4 PA, portée 1–3, croix latine, en ligne, 1/tour — 5–8 Acier. *Il fonce tête baissée. Il n'a jamais compris pourquoi ça fait mal aux autres et pas à lui.*
  - Butin : gnole_de_raid 88 % ×2–4, medaille_en_chocolat 48 %, ceinture_a_gnole 20 %, ordre_de_raid 32 %.
  - Dessin : rig `gobelin_chef` (arme hache ; accessoires casque, barbe ; couleurs peau #5e7a36, tunique #3a3a42, manches #6a6f76, pantalon #2a2420, cheveux #1e1a16, ceinture #8a2a1a, bottes #1e1a17).

### 3.3 Boss

#### Mini-boss : Krasbouk, Chef de Raid (syndiqué) (`krasbouk`) — niveau 12, carte `brumerive_3_2`
*Il mène le raid sur Brumerive parce que son contrat le dit. Il a lu le contrat. Lui seul.*

- PV 300, PA 7, PM 3, Ini 120, For 30 ; rés. Acier +20, Flamme +10, Tempête +0, Givre -10 ; IA `basique` ; XP 700 ; écus 80–140.
- Groupe fixe : krasbouk, gobelin_frondeur ; réapparition 45–60 s.
- Sorts : 
  - **Hachoir réglementaire** (`krasbouk_hachoir`, nouveau) : 4 PA, portée 1, 1/tour — 7–10 Acier. *Coup porté selon l'article 3 du contrat de raid.*
  - **Hachette de jet** (`krasbouk_hachette`, nouveau) : 3 PA, portée 2–5, 1/tour — 4–6 Acier. *Il en a toujours une de rechange, glissée dans la botte.*
  - **Cri de raid** (`krasbouk_cri_de_raid`, nouveau) : 2 PA, portée 0, sans ldv, 1/tour, délai 3 — +25 For (2 t) (alliés). *« Pour la prime ! » Ses muscles y croient.*
  - **Tourbillon syndical** (`krasbouk_tourbillon`, nouveau) : 4 PA, portée 0, cercle 1, sans ldv, lanceur exclu, 1/tour — 7–10 Acier. *Il fait le tour de la question. Et de tous ceux qui l'entourent.*
- Phases :
  - **60 %** — « « Article 7 : piquet de grève mobile ! » Krasbouk court d'un bout à l'autre de la palissade. » — sur lui : +2 PM (3 t) ; +2 Portée (3 t)
  - **30 %** — « « Prime de risque ! PRIME DE RISQUE ! » Krasbouk jette son casque et entre en grève… contre vous. » — apprend `krasbouk_tourbillon` ; sur lui : +25 % Crit (3 t) ; +4 Dommages (3 t) ; −20 Rés. Acier (3 t)
- Butin : ordre_de_raid 100 %, sac_de_rapine 90 % ×2–4, chevaliere_du_delegue 20 %, hachoir_de_krasbouk 12 %.
- Dessin : rig `gobelin_chef` (arme hache ; accessoires casque, cape_cendre ; couleurs peau #7c9a48, tunique #8a2a1a, manches #4e4e58, pantalon #2a2420, cheveux #2a2018, ceinture #e0b860, bottes #1e1a17).
- Équilibrage : Profil agressif. Pour un niveau 12 seul (146 PV, ~33 dégâts/tour) : 300 PV (sans soin ni bouclier), soit 9 à 10 tours ; ~17 dégâts/tour, ~25 en dernière phase (critiques, Dommages, tourbillon) mais −20 % de rés. Acier pendant 3 tours : la fenêtre pour finir le combat. Gagnable avec les soins de sa Voie, perdu si on se laisse encercler.

## 4. Galeries de Crasse-Roc

Palette `crasse_roc` ; Pierre de Passage `crasse_roc` sur `crasse_roc_0_0` (10 écus, existante). 10 cartes.

```
          x=0                       x=1                        x=2
y=0  [Entrée des galeries 1-3 *] ── [Le Crassier 1-3] ── [Puits des Vampipistrelles 4-6]
          │                            │                          │
y=1  [La Rataillerie 1-3] ──────── [Galerie effondrée 4-6] ── [Poste avancé de la Milice 7-9]
                                                                  │
y=2  [Route des Charrois 10-12] ── [Forges noires 10-12] ──── [Carrière aux Échos 7-9]
   +══ porte vers Hautepierre 4_2      │
y=3                              [L'Abîme du Balourd ☠ 12]
```

**Progression.** Gobelins : « des rats à volonté, puis la dèche ». Palier 1–3 très généreux : deux familles (rats faibles, grouilleurs forts) sur trois cartes (Entrée, Crassier, Rataillerie), des groupes de 3 — avec le passif Chapardeur, le gobelin s'équipe vite (Fouineur, Pressé). Palier 4–6 maigre : une seule famille volante (vampipistrelles) sur 2 cartes, pénible pour les tireurs. Palier 7–9 : la milice humaine (armure, résistance Acier) sur 2 cartes : il faut changer d'élément ou s'équiper (Forgeron Hargneux). Palier 10–12 : contremaîtres en soutien (groupes qui se donnent des PA) et le Balourd, le plus dur des trois mini-boss. Asymétrie : départ le plus rapide, fin la plus rude ; la sortie vers Hautepierre (Route des Charrois) est au palier 10–12.

### 4.1 Cartes

**`crasse_roc_0_0` — Entrée des galeries** (existante ; palier 1-3 ; x=0, y=0 ; Pierre de Passage)
- Sorties : droite → `crasse_roc_1_0`, bas → `crasse_roc_0_1`.
- Ambiance : Le campement de départ des gobelins, inchangé.
- Plan : Retouche : ouvrir 3 cases de la dernière ligne (colonnes 7 à 9, sous le chemin) pour la sortie bas.
- Ressources : U×3, I×4 (inchangées).
- Groupes : 1. rat_des_galeries + rat_des_galeries; 2. 1–2 parmi {grouilleur, rat_des_galeries}. inchangés
- PNJ : Grumm, Zogrub et Krogma restent.

**`crasse_roc_1_0` — Le Crassier** (existante ; palier 1-3 ; x=1, y=0)
- Sorties : gauche → `crasse_roc_0_0`, droite → `crasse_roc_2_0`, bas → `crasse_roc_1_1`.
- Ambiance : Inchangé : terrils et galerie.
- Plan : Retouches : remplacer par « . » le dernier caractère des lignes 15 à 19 (bord droit) pour la sortie droite, et 3 cases de la dernière ligne (colonnes 8 à 10) pour la sortie bas ; vérifier l'accessibilité.
- Ressources : U×3, I×3 (inchangées).
- Groupes : 1. rat_des_galeries + rat_des_galeries + rat_des_galeries; 2. grouilleur + rat_des_galeries; 3. 2–3 parmi {grouilleur, rat_des_galeries}; 4. grouilleur. inchangés

**`crasse_roc_0_1` — La Rataillerie** (nouvelle ; palier 1-3 ; x=0, y=1)
- Sorties : haut → `crasse_roc_0_0`, droite → `crasse_roc_1_1`.
- Ambiance : Une décharge de galerie où les rats ont fondé une ville : tas de ferraille, nids de chiffons, pièges à rats tous déclenchés.
- Plan : Cuvette entourée de rochers (R) épais sur 2 rangées, nombreux petits îlots de R (tas de ferraille) qui forment des couloirs ; une flaque (E) au centre ; décor « cabane » (atelier de Mamie Ratine) en haut-gauche.
- Ressources : U×3, F×1.
- Groupes : 1. rat_des_galeries + rat_des_galeries; 2. 3–3 parmi {rat_des_galeries}; 3. rat_des_galeries + grouilleur; 4. grouilleur + grouilleur.
- PNJ `a` **Mamie Ratine, éleveuse de rats (retraitée)** (`mamie_ratine`) — PNJ d'ambiance : « Avant, j'élevais des rats pour les courses. Puis les rats ont gagné, et ils sont partis avec la caisse. » / « Le Rat-roi ? Douze rats noués par la queue. Je leur avais dit de ne pas jouer à la ronde. » / « Si tu ramènes des queues de rat, garde-les. Ça peut toujours servir. Je ne sais pas à quoi. »

**`crasse_roc_2_0` — Puits des Vampipistrelles** (nouvelle ; palier 4-6 ; x=2, y=0)
- Sorties : gauche → `crasse_roc_1_0`, bas → `crasse_roc_2_1`.
- Ambiance : Un ancien puits d'aération effondré en gouffre, plein de vampipistrelles qui dorment la tête en bas… sauf quand on passe.
- Plan : Grand gouffre (E, eau noire) de 5×7 au centre, bordé de rochers ; corniche praticable tout autour (2 à 3 cases de large) ; décor « galerie » (entrée de mine) en haut-droite ; stalagmites (R) isolées qui coupent les lignes de vue.
- Ressources : U×2, I×2.
- Groupes : 1. vampipistrelle; 2. vampipistrelle + vampipistrelle; 3. 2–3 parmi {vampipistrelle}.
- PNJ `a` **Gnark, guano-culteur** (`gnark_guanoculteur`) — PNJ d'ambiance : « Le guano de vampipistrelle, c'est de l'or ! De l'or qui sent mauvais, mais de l'or ! » / « La Comtesse ? Une vampipistrelle grosse comme un chien. Elle se croit noble. Elle mord comme une roturière. » / « Ne regarde pas en l'air en parlant. Crois-moi. »

**`crasse_roc_1_1` — Galerie effondrée** (nouvelle ; palier 4-6 ; x=1, y=1)
- Sorties : haut → `crasse_roc_1_0`, gauche → `crasse_roc_0_1`, droite → `crasse_roc_2_1`.
- Ambiance : Une galerie dont le plafond s'est écroulé : rails tordus, wagonnets renversés, poutres.
- Plan : Deux longs couloirs de rails (chemins « : » rectilignes) séparés par des éboulis (R) ; quelques poutres de soutènement (A) ; le bas de la carte est fermé par l'éboulement (pas de sortie bas).
- Ressources : I×2, U×1, T×1.
- Groupes : 1. vampipistrelle + vampipistrelle; 2. vampipistrelle; 3. 2–3 parmi {vampipistrelle, grouilleur}.

**`crasse_roc_2_1` — Poste avancé de la Milice** (nouvelle ; palier 7-9 ; x=2, y=1)
- Sorties : haut → `crasse_roc_2_0`, gauche → `crasse_roc_1_1`, bas → `crasse_roc_2_2`.
- Ambiance : Les humains de Hautepierre ont planté un poste fortifié à l'entrée des galeries : palissade, tente, étendard à tour blanche.
- Plan : Palissade de murs (M) en carré au centre-droit, ouverte en bas ; décor « maison » (corps de garde) dedans ; tonneaux (R) ; terrain dégagé à gauche pour combattre.
- Ressources : I×2, T×2.
- Groupes : 1. milicien_de_hautepierre; 2. milicien_de_hautepierre + milicien_de_hautepierre; 3. milicien_de_hautepierre + vampipistrelle; 4. 1–3 parmi {milicien_de_hautepierre}.

**`crasse_roc_2_2` — Carrière aux Échos** (nouvelle ; palier 7-9 ; x=2, y=2)
- Sorties : haut → `crasse_roc_2_1`, gauche → `crasse_roc_1_2`.
- Ambiance : Une carrière en gradins où chaque coup de pioche résonne trois fois. Les miliciens y « inspectent » le travail des gobelins.
- Plan : Gradins : 3 bandes horizontales de rochers (R) percées de rampes de 2 cases ; veines de minerai le long des gradins ; un treuil (décor « cabane ») en bas-gauche.
- Ressources : T×3, I×2.
- Groupes : 1. milicien_de_hautepierre + milicien_de_hautepierre; 2. milicien_de_hautepierre; 3. 2–3 parmi {milicien_de_hautepierre}.
- PNJ `a` **Grizzlok, gobelin pacifiste** (`grizzlok_le_pacifiste`) — PNJ d'ambiance (acte II en germe) : « J'ai déposé un préavis de grève. Le contremaître a déposé un préavis de coups de bâton. » / « Les humains disent qu'on est les méchants. Le contremaître dit que ce sont eux. Et si c'était le contremaître ? » / « Un jour, il y aura un syndicat des gobelins. Avec des chaises. Des vraies. »

**`crasse_roc_1_2` — Forges noires** (nouvelle ; palier 10-12 ; x=1, y=2)
- Sorties : droite → `crasse_roc_2_2`, gauche → `crasse_roc_0_2`, bas → `crasse_roc_1_3`.
- Ambiance : Les forges du Souverain : rigoles de lave, enclumes, cheminées. Les contremaîtres y comptent les minutes de pause (zéro).
- Plan : Palette « forges » (eau = lave). Deux rigoles de lave (E) en diagonale qui découpent la carte en 3 zones reliées par des passerelles d'une case ; enclumes et soufflets en rochers (R) ; deux décors « galerie » (cheminées) en haut.
- Ressources : I×2, T×2.
- Groupes : 1. contremaitre_zele; 2. contremaitre_zele + contremaitre_zele; 3. 2–3 parmi {contremaitre_zele, milicien_de_hautepierre}; 4. contremaitre_zele + vampipistrelle.

**`crasse_roc_0_2` — Route des Charrois** (nouvelle ; palier 10-12 ; x=0, y=2)
- Sorties : droite → `crasse_roc_1_2` ; portes : `hautepierre_4_2`.
- Ambiance : La route par où sortent les charrois de minerai, vers l'ouest et Hautepierre ; un péage gobelin improvisé.
- Plan : Route (:) large de l'est (vers les forges) à l'ouest, jusqu'au passage « + » sur le bord gauche (porte vers hautepierre_4_2, décor « poteau_indicateur » à côté) ; charrettes renversées (R) ; falaises (R) en haut et en bas.
- Ressources : T×2, I×1.
- Groupes : 1. contremaitre_zele + contremaitre_zele; 2. contremaitre_zele; 3. 1–2 parmi {contremaitre_zele}.
- PNJ `a` **Zibeline, péagère** (`zibeline_la_peagere`) — PNJ d'ambiance : « Péage ! Deux écus pour passer. Trois pour repasser. Quatre si vous avez l'air content. » / « Hautepierre, c'est tout droit. Les humains y ont des murs blancs et des idées noires sur nous. » / « Vous ne payez pas ? Bon. Je note. Je note toujours. Je ne fais rien après, mais je note. »
- Lien entre zones : Porte « + » vers hautepierre_4_2 (route), posée par le lot Hautepierre avec sa réciproque.

**`crasse_roc_1_3` — L'Abîme du Balourd** (nouvelle ; palier 10-12 ; x=1, y=3 ; **boss**)
- Sorties : haut → `crasse_roc_1_2`.
- Ambiance : Le fond des galeries, là où on a creusé trop profond : un lac de lave, un pont de pierre, et quelque chose de très grand qui attend.
- Plan : Palette « forges ». Lac de lave (E) sur tout le bas et les côtés ; une plate-forme centrale (7×7 praticable) reliée au haut par un pont de 2 cases de large ; piliers (R) sur la plate-forme pour s'abriter du Crachat de lave.
- Ressources : —.
- Groupes : 1. balourd_des_abimes (réapparition 45–60 s); 2. contremaitre_zele + contremaitre_zele. Groupe 1 : le Balourd seul, fixe, réapparition en 1 min au plus ; groupe 2 près du pont (les contremaîtres « surveillent les travaux »).

### 4.2 Familles

| Famille | Palier | Rôle | Niv. de base : PV / PA / PM | XP base | Élite (niv., PV) |
|---|---|---|---|---|---|
| Rat des galeries | 1-3 | faible | 14 / 5 / 4 | 12 | Rat-roi (5, 40) |
| Grouilleur | 1-3 | fort | 18 / 6 / 3 | 16 | Grouilleur ancestral (7, 65) |
| Vampipistrelle | 4-6 | moyen | 22 / 6 / 5 | 27 | Vampipistrelle comtesse (9, 74) |
| Milicien de Hautepierre | 7-9 | fort | 38 / 6 / 3 | 62 | Sergent de la milice (12, 118) |
| Contremaître zélé | 10-12 | moyen | 45 / 6 / 3 | 102 | Contremaître en chef (15, 130) |

#### Rat des galeries (`rat_des_galeries`) *(existante, retouchée)* — palier 1-3, famille faible, gabarit frele
*Il vivait là avant les gobelins. Il compte bien y vivre après.*

- Niveaux 1–3 (poids 6/3/1) ; base (niv. 1) : PV 14, PA 5, PM 4, Ini 60 ; par niveau : pv +3, initiative +5, xp +4, force +5.
- Résistances : Tempête -10 ; IA `basique` ; XP 12 (+4/niv.) ; écus 1–4.
- Sorts : 
  - `rat_morsure` (existant) 
  - `rat_grignotage` (existant)
- Butin : queue_de_rat 60 % ×1–2, dent_de_rat 30 %, bottes_feutrees 5 %, coiffe_fouineur 2 %, amulette_fouineur 2 %, cape_fouineur 2 %.
- Dessin : image `rat` (échelle 0.8).
- Modifications du fichier existant : Stats inchangées (déjà en tranche 1–3, poids 6/3/1). Ajouter les pièces du Fouineur (coiffe, amulette, cape) au butin : un fouineur chez les rats, évidemment.
- **Élite : Rat-roi** (`rat_roi`) *(existante)*, niveau 5 — *Douze rats noués par la queue, un seul trône, beaucoup d'opinions.* PV 40, PA 6, PM 4, Ini 90, For 0 ; rés. Tempête -5, Acier +5 ; XP 60 ; écus 5–15.
  - Sorts : `rat_morsure`, `rat_grignotage`, `rat_roi_morsure_royale`
  - Butin : queue_de_rat 90 % ×2–4, dent_de_rat 70 % ×1–2, bottes_feutrees 20 %, coiffe_fouineur 6 %, amulette_fouineur 6 %, cape_fouineur 6 %.
  - Dessin : image `rat` (échelle 1.15 ; teinte #c9b9a0).
  - Modifications : Ajouter les trois pièces du Fouineur au butin ; rien d'autre.

#### Grouilleur (`grouilleur`) *(existante, retouchée)* — palier 1-3, famille fort, gabarit standard
*Un mille-pattes vert de la taille d'un chien, qui crache et qui ne compte pas ses pattes.*

- Niveaux 1–3 (poids 1/3/6) ; base (niv. 1) : PV 18, PA 6, PM 3, Ini 60 ; par niveau : pv +4, initiative +5, xp +7, force +3, intelligence +3, rés. Givre +2, Flamme +2.
- Résistances : Givre +6, Flamme +6, Acier -5 ; IA `basique` ; XP 16 (+7/niv.) ; écus 3–8.
- Sorts : 
  - `grouilleur_pinces` (existant) 
  - `grouilleur_crachat` (existant)
- Butin : carapace_de_grouilleur 50 % ×1–2, glande_acide 15 %, ceinture_de_carapace 5 %, anneau_presse 2 %, bottes_presse 2 %, ceinture_presse 2 %.
- Dessin : image `grouilleur` (échelle 0.85).
- Modifications du fichier existant : Stats inchangées (tranche 1–3, poids 1/3/6). Ajouter les pièces du Pressé (anneau, bottes, ceinture) au butin.
- **Élite : Grouilleur ancestral** (`grouilleur_ancestral`) *(existante)*, niveau 7 — *Il a plus de pattes que d'années, et il a beaucoup d'années.* PV 65, PA 7, PM 3, Ini 90, For 0, Int 0 ; rés. Givre +20, Flamme +20, Acier +0 ; XP 100 ; écus 8–20.
  - Sorts : `grouilleur_pinces`, `grouilleur_crachat`, `ancestral_jet_d_acide`
  - Butin : carapace_de_grouilleur 90 % ×2–4, glande_acide 50 % ×1–2, ceinture_de_carapace 20 %, anneau_presse 6 %, bottes_presse 6 %, ceinture_presse 6 %.
  - Dessin : image `grouilleur` (échelle 1.15 ; teinte #b8a878).
  - Modifications : Ajouter les trois pièces du Pressé (il a beaucoup de pattes, il est toujours pressé) au butin.

#### Vampipistrelle (`vampipistrelle`) — palier 4-6, famille moyen, gabarit frele
*Une pipistrelle qui s'est prise pour un vampire. Personne n'a osé la contredire.*

- Niveaux 4–6 (poids 3/4/3) ; base (niv. 4) : PV 22, PA 6, PM 5, Ini 120, Cha 6, Agi 6 ; par niveau : pv +3, initiative +5, xp +8, agilite +2, chance +2.
- Résistances : Tempête +20, Givre +5, Acier -10, Flamme -5 ; IA `basique` ; XP 27 (+8/niv.) ; écus 4–9.
- Sorts : 
  - **Suçon** (`vampipistrelle_sucon`, nouveau) : 3 PA, portée 1, 2/tour — 4–6 Impie. *Une petite morsure, très affectueuse, très impie.* 
  - **Ultrason** (`vampipistrelle_ultrason`, nouveau) : 3 PA, portée 1–4, sans ldv, 1/tour — 3–5 Tempête ; −1 Portée (1 t). *Un cri si aigu qu'on ne vise plus droit.*
- Butin : aile_de_vampipistrelle 55 % ×1–2, guano_luisant 12 %, cape_de_vampipistrelle 4 %, anneau_bonhomme_de_neige 3 %, ceinture_bonhomme_de_neige 3 %, bottes_bonhomme_de_neige 3 %.
- Dessin : image `vampipistrelle` (échelle 0.85). **Nouveau dessin** : monstre/vampipistrelle.svgt, ~44×34 px : chauve-souris en vol stationnaire vue de 3/4, corps rond brun-violet ({{pelage}}), grandes ailes membraneuses violet sombre déployées en V, grandes oreilles pointues, deux petits crocs blancs, yeux rouges ; ombre au sol décollée (ellipse à ~8 px sous les pieds, l'ancre au centre de l'ombre)..
- Note : Vole au-dessus du sol (5 PM) : elle vient chercher les tireurs. Faible à l'Acier.
- **Élite : Vampipistrelle comtesse** (`vampipistrelle_comtesse`), niveau 9 — *Elle exige qu'on l'appelle « Madame la Comtesse ». Elle mord ceux qui oublient.* PV 74, PA 7, PM 5, Ini 150, Cha 26, Agi 26 ; rés. Tempête +30, Givre +15, Acier -5, Flamme +0 ; XP 130 ; écus 10–22.
  - Sorts : `vampipistrelle_sucon`, `vampipistrelle_ultrason`, `comtesse_nuee`
  - **Nuée de la comtesse** (`comtesse_nuee`, nouveau) : 5 PA, portée 1–4, cercle 1, 1/tour — 5–7 Impie. *Toute la famille vient dîner. Vous êtes le dîner.*
  - Butin : aile_de_vampipistrelle 88 % ×2–4, guano_luisant 48 %, cape_de_vampipistrelle 16 %, anneau_bonhomme_de_neige 13 %, ceinture_bonhomme_de_neige 13 %, bottes_bonhomme_de_neige 13 %.
  - Dessin : image `vampipistrelle` (échelle 1.1 ; teinte #d8a0b8).

#### Milicien de Hautepierre (`milicien_de_hautepierre`) — palier 7-9, famille fort, gabarit standard
*Envoyé « sécuriser » les galeries. Il sécurise surtout les tonneaux de bière du poste.*

- Niveaux 7–9 (poids 1/3/6) ; base (niv. 7) : PV 38, PA 6, PM 3, Ini 95, For 24 ; par niveau : pv +4, initiative +5, xp +12, force +4.
- Résistances : Acier +20, Flamme +5, Tempête +0, Givre -10, Sacré +5 ; IA `basique` ; XP 62 (+12/niv.) ; écus 7–16.
- Sorts : 
  - **Coup d'épée réglementaire** (`milicien_coup_d_epee`, nouveau) : 4 PA, portée 1, 1/tour — 7–10 Acier. *Exécuté selon le manuel de la milice, page 12.* 
  - **Bouclier levé** (`milicien_bouclier_leve`, nouveau) : 2 PA, portée 0, sans ldv, 1/tour, délai 2 — bouclier Acier 8–12. *Position de garde numéro 3. Il ne connaît que celle-là, mais il la connaît bien.*
- Butin : maillon_de_cotte 50 % ×1–3, ecusson_de_milice 12 %, casque_cabosse 4 %, epee_de_milicien 4 %, bottes_de_milicien 4 %, cape_forgeron_hargneux 3 %, ceinture_forgeron_hargneux 3 %, bottes_forgeron_hargneux 3 %.
- Dessin : rig `humain` (arme epee ; accessoires casque ; couleurs tunique #4a6a9a, manches #8a8f96, pantalon #3a3a4a, bottes #2e2620, ceinture #c9a04e, cheveux #5a3a22). **Nouveau dessin** : accessoire « casque » (casque rond de fer à nasal, 2 vues ; partagé avec plusieurs familles).
- Note : Des humains combattus par des gobelins : la milice d'Hautepierre (camp allié) est l'ennemie de l'acte I des gobelins. Armure : forte résistance Acier, faible au Givre.
- **Élite : Sergent de la milice** (`sergent_de_milice`), niveau 12 — *Vingt ans de service, trois promotions, aucune bataille. Ça va changer, croit-il.* PV 118, PA 7, PM 3, Ini 125, For 54 ; rés. Acier +30, Flamme +15, Tempête +10, Givre -5, Sacré +15 ; XP 221 ; écus 18–40.
  - Sorts : `milicien_coup_d_epee`, `milicien_bouclier_leve`, `sergent_rappel_a_l_ordre`
  - **Rappel à l'ordre** (`sergent_rappel_a_l_ordre`, nouveau) : 3 PA, portée 2–4, en ligne, 1/tour, délai 1 — attirance 2 ; 4–6 Acier. *« Vous, là ! Approchez ! » On approche, c'est plus fort que soi.*
  - Butin : maillon_de_cotte 80 % ×2–5, ecusson_de_milice 48 %, casque_cabosse 16 %, epee_de_milicien 16 %, bottes_de_milicien 16 %, cape_forgeron_hargneux 13 %, ceinture_forgeron_hargneux 13 %, bottes_forgeron_hargneux 13 %.
  - Dessin : rig `humain_grand` (arme epee ; accessoires casque, barbe ; couleurs tunique #2e4a7a, manches #a8aeb6, pantalon #2a2a36, bottes #1e1a17, ceinture #e0b860, cheveux #8a8478, barbe #8a8478).

#### Contremaître zélé (`contremaitre_zele`) — palier 10-12, famille moyen, gabarit soutien
*Il fait travailler les autres avec une énergie qu'il n'a jamais mise à travailler lui-même.*

- Niveaux 10–12 (poids 3/4/3) ; base (niv. 10) : PV 45, PA 6, PM 3, Ini 100, For 18, Agi 18 ; par niveau : pv +4, initiative +5, xp +14, force +2, agilite +2.
- Résistances : Acier +10, Tempête +10, Flamme -10, Givre -5 ; IA `soutien` ; XP 102 (+14/niv.) ; écus 9–22.
- Sorts : 
  - **Coup de bâton** (`contremaitre_coup_de_baton`, nouveau) : 3 PA, portée 1–2, 2/tour — 5–7 Acier. *Motivation par l'exemple. Et par le bâton.* 
  - **Heures sup'** (`contremaitre_heures_sup`, nouveau) : 2 PA, portée 1–4, 1/tour, délai 2 — +2 PA. *Un collègue gagne 2 PA tout de suite. Non payés, évidemment.* 
  - **Retenue sur salaire** (`contremaitre_retenue_sur_salaire`, nouveau) : 3 PA, portée 2–5, 1/tour — 4–6 Tempête ; −3 Dommages (2 t). *Vos dégâts sont retenus à la source.*
- Butin : sifflet_de_contremaitre 50 % ×1–2, registre_des_heures 12 %, amulette_sifflet 4 %, anneau_pyromane_repenti 3 %, ceinture_pyromane_repenti 3 %, bottes_pyromane_repenti 3 %.
- Dessin : rig `gobelin_veteran` (arme baton ; accessoires casque, tablier ; couleurs peau #7c9a48, tunique #5e4a32, manches #4a3a28, pantalon #3e3226, cheveux #2a2018, ceinture #c9a04e, tablier #3a3028).
- Note : IA soutien : se tient à distance, donne des PA aux autres contremaîtres et retient vos Dommages. Les groupes de 2–3 sont les plus durs de la zone.
- **Élite : Contremaître en chef** (`contremaitre_en_chef`), niveau 15 — *Il a un bureau, un tampon et un sifflet en or. Il ne descend jamais dans les galeries, sauf pour licencier.* PV 130, PA 7, PM 3, Ini 130, For 38, Agi 38 ; rés. Acier +20, Tempête +20, Flamme -5, Givre +0 ; XP 314 ; écus 22–55.
  - Sorts : `contremaitre_coup_de_baton`, `contremaitre_heures_sup`, `contremaitre_retenue_sur_salaire`, `chef_licenciement`
  - **Licenciement** (`chef_licenciement`, nouveau) : 4 PA, portée 1–2, 1/tour — 6–9 Acier ; poussee 3. *« Vous êtes viré ! » La porte, c'est par là. Loin.*
  - Butin : sifflet_de_contremaitre 80 % ×2–4, registre_des_heures 48 %, amulette_sifflet 16 %, anneau_pyromane_repenti 13 %, ceinture_pyromane_repenti 13 %, bottes_pyromane_repenti 13 %.
  - Dessin : rig `gobelin_chef` (arme baton ; accessoires casque, tablier, barbe ; couleurs peau #6a8a3a, tunique #2a2a32, manches #1e1e26, pantalon #2a2420, cheveux #1e1a16, ceinture #e0b860, tablier #5a2a1a).

### 4.3 Boss

#### Mini-boss : Le Balourd des Abîmes (`balourd_des_abimes`) — niveau 12, carte `crasse_roc_1_3`
*Les gobelins ont creusé trop profond. Le contremaître dit que c'est la faute des ouvriers. Le Balourd dit que c'est la faute de tout le monde.*

- PV 300, PA 7, PM 3, Ini 90, Int 20 ; rés. Flamme +40, Acier +15, Tempête +0, Givre -25 ; IA `basique` ; XP 760 ; écus 90–150.
- Groupe fixe : balourd_des_abimes ; réapparition 45–60 s.
- Sorts : 
  - **Lame de braise** (`balourd_lame_de_braise`, nouveau) : 4 PA, portée 1, 1/tour — 8–11 Flamme. *Une épée faite de feu. Ou un feu en forme d'épée : il n'a jamais su.*
  - **Fouet de flammes** (`balourd_fouet`, nouveau) : 4 PA, portée 1–3, 1/tour — 6–9 Flamme ; attirance 1. *Il vous ramène vers lui, poliment, par le cou.*
  - **Crachat de lave** (`balourd_crachat_de_lave`, nouveau) : 3 PA, portée 2–6, cercle 1, 1/tour — 4–6 Flamme. *Il n'a pas de manières. Il a de la lave.*
  - **Pluie de braises** (`balourd_pluie_de_braises`, nouveau) : 3 PA, portée 1–5, cercle 2, sans ldv, 1/tour, délai 3 — glyphe 2 t : 3–5 Flamme (ennemis). *Le plafond de la galerie s'embrase. Personne ne va aimer la suite.*
- Phases :
  - **70 %** — « « Qui a creusé ici ? Je veux le nom du contremaître ! » Sa peau de roche se referme, fissure par fissure. » — sur lui : +25 Rés. Givre (3 t) ; +15 Rés. Acier (3 t)
  - **40 %** — « Le Balourd s'embrase et le plafond de la galerie prend feu. » — apprend `balourd_pluie_de_braises` ; sur lui : +30 Int (3 t)
  - **15 %** — « « Bon. On peut peut-être négocier ? » Il ne négocie pas : il déploie ses ailes de fumée. » — sur lui : +3 PM (3 t) ; +2 Portée (3 t)
- Butin : corne_du_balourd 100 %, cape_de_fumee 20 %, fouet_du_balourd 12 %, registre_des_heures 50 % ×1–2.
- Dessin : image `balourd` (échelle 1.0). **Nouveau dessin** : monstre/balourd.svgt, ~96×104 px : démon massif de roche noire fissurée de lave orange, deux cornes recourbées, ailes de fumée grise en lambeaux, épée de braise dans la main droite et fouet de flamme dans la gauche ; yeux jaunes ; ancre aux pieds (≈ [48, 100]). Le plus grand monstre des zones de départ..
- Équilibrage : Profil défensif puis éruptif. Plus dur que les deux autres mini-boss (zone « rude à la fin ») : 300 PV, et sa faiblesse au Givre (−25) est couverte pendant 3 tours à 70 % ; ~17 dégâts/tour puis ~25 avec +30 Int et la glyphe de braises ; à 15 %, +3 PM et +2 portée : il ne se laisse plus coincer. Les arcanistes de Givre et les gobelins Chance s'en sortent mieux, à condition de garder leurs coups pour après la carapace.

## 5. Lisière de Sylvebrume

Palette `sylvebrume` ; Pierre de Passage `sylvebrume` sur `sylvebrume_0_0` (10 écus, existante). 9 cartes.

```
          x=0                          x=1                         x=2
y=0  [Clairière de la Lisière 1-3 *] ── [Futaie ancienne 4-6] ── [Bosquet des Cerfs 4-6]
          │                               │                         │
y=1  [Sous-bois moussu 1-3] ────────── [Coupe rase 7-9] ──────── [Scierie de Brumerive 7-9]
                                          │                         │
y=2  [Cœur de la Toile ☠ 12] ────────── [Toiles grises 10-12] ──── [Orée du Sud 10-12]
                                                               +══ porte vers Hautepierre 2_0
```

**Progression.** Elfes : « lent au début, riche au milieu ». Palier 1–3 maigre : une seule famille faible (morilles, peu d'XP, 2 PM) sur 2 cartes — l'elfe démarre lentement mais sans risque. Palier 4–6 riche et costaud : cerfs et arbres vivants (les deux familles historiques) sur 3 cartes (Futaie, Bosquet, et quelques arbres à la Coupe rase) — beaucoup d'XP et de butin rare. Palier 7–9 : les bûcherons humains (envahisseurs de l'acte I) sur 2 cartes. Palier 10–12 : tisseuses de brume sur 2 cartes, puis la Mère-Toile. Asymétrie : départ le plus lent des trois zones, milieu le plus riche, beaucoup de contrôle (PM retirés, poisons) qui récompense la portée de l'Œil perçant.

### 5.1 Cartes

**`sylvebrume_0_0` — Clairière de la Lisière** (existante ; palier 1-3 ; x=0, y=0 ; Pierre de Passage)
- Sorties : droite → `sylvebrume_1_0`, bas → `sylvebrume_0_1`.
- Ambiance : Le village elfe de départ, inchangé.
- Plan : Retouche : ouvrir les trois dernières lignes aux colonnes 6 à 8 (un passage entre les arbres) pour la sortie bas.
- Ressources : F×4, C×3 (inchangées).
- Groupes : 1. morille_grincheuse; 2. 2–3 parmi {morille_grincheuse}. Le cerf et l'arbre (palier 4–6) laissent la place aux morilles : il n'y avait rien au palier 1–3 chez les elfes.
- PNJ : Elwyn, Lindorë et Aelthar restent.

**`sylvebrume_1_0` — Futaie ancienne** (existante ; palier 4-6 ; x=1, y=0)
- Sorties : gauche → `sylvebrume_0_0`, droite → `sylvebrume_2_0`, bas → `sylvebrume_1_1`.
- Ambiance : Inchangée : grands arbres et étang.
- Plan : Retouches : remplacer par « . » les deux derniers caractères des lignes 15 à 19 (bord droit) et 3 cases des deux dernières lignes (colonnes 8 à 10) pour les sorties droite et bas.
- Ressources : F×5, C×3 (inchangées).
- Groupes : 1. 2–3 parmi {cerf_enchante, arbre_vivant}; 2. arbre_vivant + cerf_enchante; 3. arbre_vivant; 4. cerf_enchante. inchangés

**`sylvebrume_0_1` — Sous-bois moussu** (nouvelle ; palier 1-3 ; x=0, y=1)
- Sorties : haut → `sylvebrume_0_0`, droite → `sylvebrume_1_1`.
- Ambiance : Un sous-bois de mousse épaisse et de ronds de sorcière, où les morilles tiennent conseil (elles boudent).
- Plan : Forêt dense (A) sur les bords, clairières rondes reliées par des sentiers (:) ; trois « ronds de sorcière » (cercles de 6 cases praticables autour d'un rocher R) ; un ruisseau (E) étroit au bas.
- Ressources : F×3, U×1.
- Groupes : 1. morille_grincheuse + morille_grincheuse; 2. morille_grincheuse; 3. 1–3 parmi {morille_grincheuse}.
- PNJ `a` **Tantine Champignolle, cueilleuse** (`tantine_champignolle`) — PNJ d'ambiance : « Celle-là est comestible. Celle-là aussi. Celle-là vous insulte : laissez-la. » / « Les morilles grincheuses ? Elles n'aiment pas qu'on les cueille. Personne n'aime, remarquez. » / « Si vous trouvez des spores grincheuses, ne les respirez pas. Sauf si vous voulez bouder toute la journée. »

**`sylvebrume_2_0` — Bosquet des Cerfs** (nouvelle ; palier 4-6 ; x=2, y=0)
- Sorties : gauche → `sylvebrume_1_0`, bas → `sylvebrume_2_1`.
- Ambiance : Un bosquet sacré où les cerfs enchantés viennent boire ; un petit autel elfe couvert de lierre.
- Plan : Source (E) au centre-haut qui descend en ruisseau vers le bas ; autel : décor « pavillon » en haut-gauche ; arbres (A) en couronne, sol dégagé (les cerfs ont 4 PM, il faut de la place).
- Ressources : F×2, C×2, Y×1.
- Groupes : 1. cerf_enchante; 2. cerf_enchante + cerf_enchante; 3. cerf_enchante + arbre_vivant; 4. arbre_vivant.
- PNJ `a` **Lyriandel, poète** (`poete_lyriandel`) — PNJ d'ambiance : « J'écris une ode au Grand Cerf. Quatre cents strophes. Il en manque une : la rime en « -erf ». » / « « Ô cerf, ô ramure, ô… » non. Encore raté. » / « Le Grand Cerf est passé ce matin. Il a mangé mon brouillon. Je crois que c'était une critique. »

**`sylvebrume_1_1` — Coupe rase** (nouvelle ; palier 7-9 ; x=1, y=1)
- Sorties : haut → `sylvebrume_1_0`, gauche → `sylvebrume_0_1`, droite → `sylvebrume_2_1`, bas → `sylvebrume_1_2`.
- Ambiance : Une coupe à blanc en pleine forêt : souches, troncs empilés, quelques arbres rescapés. Les bûcherons de Brumerive y travaillent sans relâche.
- Plan : Grande zone dégagée semée de souches (rochers R, ou un décor « souche » si on l'ajoute) ; piles de troncs (R alignés par 3) ; lisière d'arbres (A) intacte sur les bords ; chemin de débardage (:) du haut vers le bas.
- Ressources : Y×2, C×2.
- Groupes : 1. bucheron_de_brumerive; 2. bucheron_de_brumerive + bucheron_de_brumerive; 3. 2–3 parmi {bucheron_de_brumerive, arbre_vivant}.
- PNJ `a` **Feuillemorte, druide** (`druide_feuillemorte`) — PNJ d'ambiance (acte I elfe) : « Ils ont coupé Vieux-Branchu. Il avait mille ans. Il me devait de l'argent. » / « Les humains ont un papier qui les autorise. Nous avons des flèches qui ne les autorisent pas. » / « Le Conseil de la Lisière délibère sur l'opportunité de délibérer. Pendant ce temps, faites quelque chose. »

**`sylvebrume_2_1` — Scierie de Brumerive** (nouvelle ; palier 7-9 ; x=2, y=1)
- Sorties : haut → `sylvebrume_2_0`, gauche → `sylvebrume_1_1`, bas → `sylvebrume_2_2`.
- Ambiance : Une scierie humaine montée sur la rivière, avec sa roue à aubes et son panneau « Bois de Sylvebrume — prix d'usine ».
- Plan : Rivière (E) verticale à droite ; scierie : décor « maison » au bord de l'eau ; tas de planches (R) ; enclos de rondins (murets) ; terrain plat à gauche.
- Ressources : Y×2, F×1.
- Groupes : 1. bucheron_de_brumerive + bucheron_de_brumerive; 2. bucheron_de_brumerive; 3. 2–3 parmi {bucheron_de_brumerive}.

**`sylvebrume_1_2` — Toiles grises** (nouvelle ; palier 10-12 ; x=1, y=2)
- Sorties : haut → `sylvebrume_1_1`, gauche → `sylvebrume_0_2`, droite → `sylvebrume_2_2`.
- Ambiance : Une partie de la forêt où la brume a pris consistance : des toiles géantes tendues entre les troncs, des cocons qui pendent.
- Plan : Arbres (A) serrés formant des couloirs tortueux ; quelques arbres morts (décor arbre_mort via la palette ou en A) ; clairières de 4×4 pour combattre ; pas de chemin tracé.
- Ressources : Y×2, C×1.
- Groupes : 1. tisseuse_de_brume; 2. tisseuse_de_brume + tisseuse_de_brume; 3. 1–3 parmi {tisseuse_de_brume}; 4. tisseuse_de_brume + bucheron_de_brumerive.

**`sylvebrume_2_2` — Orée du Sud** (nouvelle ; palier 10-12 ; x=2, y=2)
- Sorties : haut → `sylvebrume_2_1`, gauche → `sylvebrume_1_2` ; portes : `hautepierre_2_0`.
- Ambiance : La forêt s'ouvre sur les plaines du sud ; une tour de guet elfe en ruine surveille la route de Hautepierre.
- Plan : Arbres (A) en haut, plaine dégagée en bas ; tour de guet en ruine (rochers R en cercle) au centre ; sentier (:) jusqu'au passage « + » sur le bord bas (porte vers hautepierre_2_0, décor « poteau_indicateur » à côté).
- Ressources : Y×1, T×1.
- Groupes : 1. tisseuse_de_brume + tisseuse_de_brume; 2. tisseuse_de_brume; 3. 1–2 parmi {tisseuse_de_brume}.
- PNJ `a` **Sylphine, éclaireuse** (`eclaireuse_sylphine`) — PNJ d'ambiance, annonce Hautepierre : « Au sud, Hautepierre. Des humains, des murs, du bruit. Je déconseille. » / « Mais vous irez quand même. Les jeunes vont toujours voir les humains. Ça leur passe vers trois cents ans. » / « Les toiles avancent vers la Lisière. Quelque chose les pousse. Quelque chose de gris, qui sent le brûlé. »
- Lien entre zones : Porte « + » vers hautepierre_2_0 (route), posée par le lot Hautepierre avec sa réciproque.

**`sylvebrume_0_2` — Cœur de la Toile** (nouvelle ; palier 10-12 ; x=0, y=2 ; **boss**)
- Sorties : droite → `sylvebrume_1_2`.
- Ambiance : Une clairière entièrement tendue de soie grise, au centre de laquelle trône la Mère-Toile.
- Plan : Clairière circulaire (9×9 praticable) cernée d'arbres (A) épais ; cocons (R) répartis dans la clairière comme couverts ; une seule entrée à droite.
- Ressources : —.
- Groupes : 1. mere_toile (réapparition 45–60 s); 2. tisseuse_de_brume + tisseuse_de_brume. Groupe 1 : la Mère-Toile seule, fixe, réapparition en 1 min au plus ; groupe 2 à l'entrée.

### 5.2 Familles

| Famille | Palier | Rôle | Niv. de base : PV / PA / PM | XP base | Élite (niv., PV) |
|---|---|---|---|---|---|
| Morille grincheuse | 1-3 | faible | 14 / 5 / 2 | 8 | Vieille Morille rancunière (6, 54) |
| Cerf enchanté | 4-6 | moyen | 36 / 7 / 4 | 45 | Grand cerf de la Lisière (9, 90) |
| Arbre vivant | 4-6 | fort | 52 / 7 / 1 | 52 | Arbre millénaire (10, 150) |
| Bûcheron de Brumerive | 7-9 | fort | 49 / 6 / 3 | 74 | Abatteur en chef (12, 153) |
| Tisseuse de brume | 10-12 | moyen | 50 / 6 / 4 | 97 | Grande Tisseuse (15, 144) |

#### Morille grincheuse (`morille_grincheuse`) — palier 1-3, famille faible, gabarit frele
*Elle pousse à l'ombre, elle râle à l'ombre, elle mord à l'ombre.*

- Niveaux 1–3 (poids 6/3/1) ; base (niv. 1) : PV 14, PA 5, PM 2, Ini 40 ; par niveau : pv +3, initiative +5, xp +5, chance +4.
- Résistances : Givre +15, Tempête +10, Acier +0, Flamme -20 ; IA `basique` ; XP 8 (+5/niv.) ; écus 3–5.
- Sorts : 
  - **Spores** (`morille_spores`, nouveau) : 3 PA, portée 1–3, sans ldv, 1/tour — 2–4 Givre ; poison Givre 1–2 (2 t). *Un nuage de mauvaise humeur, très contagieux.* 
  - **Bouderie** (`morille_bouderie`, nouveau) : 2 PA, portée 0, sans ldv, 1/tour, délai 2 — bouclier Givre 4–6. *Elle boude. C'est étonnamment efficace.*
- Butin : chapeau_de_morille 60 % ×1–2, spores_grincheuses 12 %, bottes_de_mousse 5 %, coiffe_mauvais_oeil 2 %, cape_mauvais_oeil 2 %, amulette_mauvais_oeil 2 %.
- Dessin : image `morille` (échelle 0.8). **Nouveau dessin** : monstre/morille.svgt, ~34×42 px : morille debout, chapeau conique alvéolé brun-beige ({{pelage}}/{{pelage_ombre}}), pied blanc trapu servant de corps, deux petits bras, sourcils froncés et bouche boudeuse, petites jambes ; ancre aux pieds..
- Note : 2 PM, peu de dégâts mais des poisons : une première famille lente et sûre, peu d'XP (gabarit frêle).
- **Élite : Vieille Morille rancunière** (`vieille_morille_rancuniere`), niveau 6 — *Elle se souvient de chaque pied qui l'a écrasée depuis trois siècles. Elle a une liste.* PV 54, PA 6, PM 2, Ini 70, Cha 30 ; rés. Givre +25, Tempête +20, Acier +10, Flamme -15 ; XP 80 ; écus 8–12.
  - Sorts : `morille_spores`, `morille_bouderie`, `rancune_nuage_de_spores`
  - **Nuage de rancune** (`rancune_nuage_de_spores`, nouveau) : 4 PA, portée 1–3, cercle 1, sans ldv, 1/tour — poison Givre 2–3 (3 t) ; −1 Portée (1 t). *Elle n'oublie rien. Vos poumons non plus.*
  - Butin : chapeau_de_morille 90 % ×2–4, spores_grincheuses 48 %, bottes_de_mousse 20 %, coiffe_mauvais_oeil 12 %, cape_mauvais_oeil 12 %, amulette_mauvais_oeil 12 %.
  - Dessin : image `morille` (échelle 1.1 ; teinte #a08060).

#### Cerf enchanté (`cerf_enchante`) *(existante, retouchée)* — palier 4-6, famille moyen, gabarit standard
*Ses bois luisent au crépuscule. Il charge aussi, au crépuscule et le reste du temps.*

- Niveaux 4–6 (poids 3/4/3) ; base (niv. 4) : PV 36, PA 7, PM 4, Ini 110 ; par niveau : pv +4, initiative +5, xp +6, force +2, agilite +2.
- Résistances : Tempête +20, Flamme -10 ; IA `basique` ; XP 45 (+6/niv.) ; écus 4–10.
- Sorts : 
  - `cerf_ramure` (existant) 
  - `cerf_eclat_sylvestre` (existant)
- Butin : poil_scintillant 50 % ×1–2, bois_de_cerf_enchante 20 %, couronne_de_ramure 4 %, coiffe_courant_d_air 3 %, cape_courant_d_air 3 %, amulette_courant_d_air 3 %.
- Dessin : image `cerf` (échelle 0.8).
- Modifications du fichier existant : Tranche 4–6 (poids 3/4/3) à partir de ses valeurs actuelles (niveau 4). Ajouter Force et Agilité par niveau, et les pièces Courant d'Air (coiffe, cape, amulette) au butin.
- **Élite : Grand cerf de la Lisière** (`grand_cerf`) *(existante)*, niveau 9 — *Les elfes le saluent, les humains le chassent, les poètes lui écrivent. Il n'aime aucun des trois.* PV 90, PA 8, PM 5, Ini 150, For 20, Agi 20 ; rés. Tempête +30, Flamme -5, Acier +10 ; XP 150 ; écus 12–30.
  - Sorts : `cerf_ramure`, `cerf_eclat_sylvestre`, `grand_cerf_charge`
  - Butin : poil_scintillant 90 % ×2–4, bois_de_cerf_enchante 60 % ×1–2, couronne_de_ramure 18 %, coiffe_courant_d_air 8 %, cape_courant_d_air 8 %, amulette_courant_d_air 8 %.
  - Dessin : image `cerf` (échelle 1.05 ; teinte #f0e0c0).
  - Modifications : Ajouter Force 20 et Agilité 20, et les pièces Courant d'Air au butin.

#### Arbre vivant (`arbre_vivant`) *(existante, retouchée)* — palier 4-6, famille fort, gabarit tank
*Un vieux chêne qui en a assez qu'on lui coupe les branches.*

- Niveaux 4–6 (poids 1/3/6) ; base (niv. 4) : PV 52, PA 7, PM 1, Ini 35 ; par niveau : pv +8, initiative +5, xp +8, force +3.
- Résistances : Acier +25, Givre +15, Flamme -25 ; IA `basique` ; XP 52 (+8/niv.) ; écus 5–12.
- Sorts : 
  - `arbre_branche` (existant) 
  - `arbre_racines` (existant)
- Butin : ecorce_vivante 60 % ×1–3, seve_ancienne 10 %, cape_d_ecorce 4 %.
- Dessin : image `arbre_vivant` (échelle 0.85).
- Modifications du fichier existant : Niveau de base 4 (tranche 4–6, poids 1/3/6) : 52 PV et 52 XP au niveau 4, +8 par niveau (au niveau 5, ses valeurs actuelles : 60 PV, 60 XP) ; initiative 35 (+5/niveau) ; Force +3 par niveau.
- **Élite : Arbre millénaire** (`arbre_millenaire`) *(existante)*, niveau 10 — *Il a vu naître Sylvebrume. Il compte bien la voir disparaître, sans se presser.* PV 150, PA 8, PM 1, Ini 50, For 25 ; rés. Acier +35, Givre +25, Flamme -20 ; XP 180 ; écus 15–35.
  - Sorts : `arbre_branche`, `arbre_racines`, `millenaire_ronces`, `millenaire_cercle_de_seve`
  - Butin : ecorce_vivante 90 % ×2–5, seve_ancienne 40 % ×1–2, cape_d_ecorce 18 %.
  - Dessin : image `arbre_vivant` (échelle 1.12 ; teinte #a89a88).
  - Modifications : Ajouter Force 25 ; le reste ne change pas.

#### Bûcheron de Brumerive (`bucheron_de_brumerive`) — palier 7-9, famille fort, gabarit costaud
*Il a un bon de coupe signé à Hautepierre et une hache aiguisée. Les elfes ont des flèches. Le débat est ouvert.*

- Niveaux 7–9 (poids 1/3/6) ; base (niv. 7) : PV 49, PA 6, PM 3, Ini 85, For 24 ; par niveau : pv +5, initiative +5, xp +14, force +4.
- Résistances : Acier +10, Givre +5, Flamme +0, Tempête -10 ; IA `basique` ; XP 74 (+14/niv.) ; écus 8–19.
- Sorts : 
  - **Coup de cognée** (`bucheron_cognee`, nouveau) : 4 PA, portée 1, 1/tour — 7–10 Acier. *Bien droit, comme pour un chêne. Vous n'êtes pas un chêne.* 
  - **Attention, ça tombe !** (`bucheron_ca_tombe`, nouveau) : 4 PA, portée 2–4, croix latine, sans ldv, en ligne, 1/tour, délai 1 — 5–7 Acier. *Il crie toujours avant. Personne n'écoute jamais.*
- Butin : copeaux_de_bois 55 % ×1–3, bon_de_coupe 12 %, hache_de_bucheron 4 %, ceinture_de_bucheron 4 %, anneau_enfant_de_choeur 3 %, ceinture_enfant_de_choeur 3 %, bottes_enfant_de_choeur 3 %.
- Dessin : rig `humain` (arme hache ; accessoires barbe ; couleurs tunique #a83a2a, manches #7a2a20, pantalon #3a4a6a, bottes #4a3424, ceinture #3d2b1f, cheveux #5a3a22, barbe #5a3a22). **Nouveau dessin** : arme « hache » (fer large, manche clair ; partagée avec le briseur).
- Note : Les humains (camp allié) envahisseurs de la Lisière : « Attention, ça tombe ! » frappe en croix latine (l'arbre qui tombe).
- **Élite : Abatteur en chef** (`abatteur_en_chef`), niveau 12 — *Il a abattu Vieux-Branchu, mille ans d'âge, en une matinée. Il en a fait un banc. Personne ne s'assoit dessus.* PV 153, PA 7, PM 3, Ini 115, For 54 ; rés. Acier +20, Givre +15, Flamme +10, Tempête -5 ; XP 266 ; écus 20–48.
  - Sorts : `bucheron_cognee`, `bucheron_ca_tombe`, `abatteur_souche_piegee`
  - **Souche piégée** (`abatteur_souche_piegee`, nouveau) : 3 PA, portée 1–4, sans ldv, 1/tour, délai 2 — piège (cercle 1) : 7–10 Acier (ennemis), −2 PM (1 t) (ennemis). *Une souche, des pointes, et un abatteur qui sourit.*
  - Butin : copeaux_de_bois 88 % ×2–5, bon_de_coupe 48 %, hache_de_bucheron 16 %, ceinture_de_bucheron 16 %, anneau_enfant_de_choeur 13 %, ceinture_enfant_de_choeur 13 %, bottes_enfant_de_choeur 13 %.
  - Dessin : rig `humain_grand` (arme hache ; accessoires barbe, casque ; couleurs tunique #7a1e16, manches #5a1610, pantalon #2a3a5a, bottes #2e2620, ceinture #1e1a17, cheveux #2e2418, barbe #2e2418).

#### Tisseuse de brume (`tisseuse_de_brume`) — palier 10-12, famille moyen, gabarit standard
*Une araignée grosse comme un poney, qui tisse le brouillard de Sylvebrume. Les elfes disent que c'est poétique. De loin.*

- Niveaux 10–12 (poids 3/4/3) ; base (niv. 10) : PV 50, PA 6, PM 4, Ini 110, Cha 36 ; par niveau : pv +4, initiative +5, xp +13, chance +4.
- Résistances : Givre +20, Impie +10, Acier +0, Flamme -15 ; IA `basique` ; XP 97 (+13/niv.) ; écus 9–21.
- Sorts : 
  - **Morsure glacée** (`tisseuse_morsure`, nouveau) : 3 PA, portée 1, 1/tour — 4–6 Givre ; poison Givre 2–3 (2 t). *Le venin des tisseuses gèle le sang. Et l'humeur.* 
  - **Toile collante** (`tisseuse_toile`, nouveau) : 3 PA, portée 2–5, 1/tour — 2–4 Givre ; −2 PM (1 t). *On se débat, on s'emmêle, on reste là.*
- Butin : fil_de_brume 55 % ×1–3, crochet_d_araignee 12 %, cape_de_soie_grise 4 %, coiffe_bonhomme_de_neige 3 %, cape_bonhomme_de_neige 3 %, amulette_bonhomme_de_neige 3 %.
- Dessin : image `araignee` (échelle 0.85). **Nouveau dessin** : monstre/araignee.svgt, ~60×38 px : araignée vue de 3/4, abdomen gris perle ({{pelage}}) à motif de toile bleu pâle, céphalothorax plus sombre ({{pelage_ombre}}), 8 pattes fines articulées, 6 petits yeux noirs brillants, crochets ; ancre au centre entre les pattes. Recolorable pour la Mère-Toile..
- Note : Retrait de PM et poisons : il faut frapper fort et vite. Faible à la Flamme.
- **Élite : Grande Tisseuse** (`grande_tisseuse`), niveau 15 — *Sa toile couvre trois clairières. Elle a oublié où elle a rangé la dernière proie.* PV 144, PA 7, PM 4, Ini 140, Cha 66 ; rés. Givre +30, Impie +20, Acier +10, Flamme -10 ; XP 299 ; écus 22–52.
  - Sorts : `tisseuse_morsure`, `tisseuse_toile`, `tisseuse_cocon`
  - **Cocon** (`tisseuse_cocon`, nouveau) : 4 PA, portée 1–4, 1/tour, délai 1 — 6–9 Givre ; −2 PA (1 t). *Elle vous emballe pour plus tard.*
  - Butin : fil_de_brume 88 % ×2–5, crochet_d_araignee 48 %, cape_de_soie_grise 16 %, coiffe_bonhomme_de_neige 13 %, cape_bonhomme_de_neige 13 %, amulette_bonhomme_de_neige 13 %.
  - Dessin : image `araignee` (échelle 1.1 ; teinte #b8c0d8).

### 5.3 Boss

#### Mini-boss : La Mère-Toile (`mere_toile`) — niveau 12, carte `sylvebrume_0_2`
*Elle tisse depuis l'Âge de l'Aube et n'a jamais fini un seul napperon. Depuis que la Cendre tombe, elle tisse plus vite, et plus noir.*

- PV 300, PA 7, PM 4, Ini 130, Cha 25 ; rés. Givre +30, Impie +15, Tempête +10, Acier +5, Flamme -20 ; IA `basique` ; XP 720 ; écus 80–140.
- Groupe fixe : mere_toile ; réapparition 45–60 s.
- Sorts : 
  - **Venin ancestral** (`meretoile_venin`, nouveau) : 4 PA, portée 1, 1/tour — 7–10 Givre ; poison Givre 3–4 (3 t). *Une seule morsure, et l'hiver s'installe dans vos veines.*
  - **Morsure glacée** (`tisseuse_morsure`, nouveau) : 3 PA, portée 1, 1/tour — 4–6 Givre ; poison Givre 2–3 (2 t). *Le venin des tisseuses gèle le sang. Et l'humeur.*
  - **Toile collante** (`tisseuse_toile`, nouveau) : 3 PA, portée 2–5, 1/tour — 2–4 Givre ; −2 PM (1 t). *On se débat, on s'emmêle, on reste là.*
  - **Toile géante** (`meretoile_toile_geante`, nouveau) : 4 PA, portée 2–5, cercle 2, sans ldv, 1/tour, délai 3 — glyphe 2 t : 2–4 Givre (ennemis), −2 PM (1 t) (ennemis). *Toute la clairière devient un piège.*
- Phases :
  - **65 %** — « La Mère-Toile court sur ses fils et tisse la clairière entière. » — apprend `meretoile_toile_geante` ; sur lui : +2 PM (3 t)
  - **35 %** — « « Mes petites ! … Ah, non : elles sont toutes à la Lisière, à embêter les elfes. » Elle s'emmaillote dans sa soie. » — sur lui : +30 Rés. Flamme (3 t) ; +20 Rés. Acier (3 t)
  - **10 %** — « Elle file un dernier fil… et décide qu'elle a assez tissé pour aujourd'hui. » — sur lui : +40 Cha (3 t) ; +20 % Crit (3 t)
- Butin : soie_de_la_mere_toile 100 %, fil_de_brume 90 % ×2–4, anneau_aux_huit_yeux 20 %, fuseau_de_la_mere_toile 12 %.
- Dessin : image `araignee` (échelle 1.5 ; teinte #d8c8f0).
- Équilibrage : Profil contrôle et placement. 300 PV, ~16 dégâts/tour avec poisons, retrait de PM et toile géante : un combat de placement. Faible à la Flamme (−20), sauf pendant son cocon (35 %, 3 tours) ; à 10 % elle mise tout sur l'attaque (Chance et critiques).

## 6. Hautepierre et ses environs

Palette `hautepierre` ; Pierre de Passage `hautepierre` sur `hautepierre_2_2` (20 écus). 19 cartes.

```
            x=0                    x=1                       x=2                        x=3                        x=4
                                                      +══ Sylvebrume 2_2
y=0                         [Bois-Corbeau 19-21] ── [Route du Nord 13-15] ── [Colline Pelée 19-21 ✦]
                                   │                        │                          │
y=1                         [Vigie aux Corbacs 19-21] ─ (Citadelle) ──────── [Ruines Vieille Garde 22-24] ── [Cimetière des Gargouilles 22-24]
                                   │                        │                          │                          │
y=2  [Route de l'Ouest 13-15] ── (Porte de l'Ouest) ─── (Grand-Place *) ───── (Porte de l'Est) ──────── [Route de l'Est 13-15 ✦]
 Brumerive 3_1 ══+                 │                        │                          │                          │ +══ Crasse-Roc 0_2
y=3                         [Rives du Fleuve Gris 16-18] ─ [Pont des Trolls 16-18] ─ [Camp des Cendrillons 25-27 ✦] ─ [Plaine Cendrée 25-27 ✦]
                                                            │                          │                          │
y=4                                                  [Gorges du Troll 16-18 ✦] ─ [Champs du Pèle-Ennemi 28-30 ✦] ─ [La Brèche ☠ 30 ✦]

( ) = ville, sans monstres ; ✦ = carte cendrée (« cendree »: true, variantes Corrompues possibles)
```

**Progression.** Chaque race arrive par sa propre route (Brumerive à l'ouest, Sylvebrume au nord, Crasse-Roc à l'est), toutes au palier 13–15 (détrousseurs ; loups cendreux sur la route de l'Est). Puis : 16–18 au sud (trolls du pont, grouilleurs de braise dans les gorges), 19–21 au nord (corbacs, arbres calcinés), 22–24 au nord-est (gargouilles des ruines), 25–27 au sud-est (Cendrillons), 28–30 au champ de bataille (olifants) et Grondin à la Brèche. La progression tourne autour de la ville, qu'on retraverse souvent (Pierre, forge, marchande). Une famille par palier, complétée par une variante Corrompue sur les trois premiers paliers.

### 6.1 Cartes

**`hautepierre_2_2` — Grand-Place** (nouvelle ; palier ville ; x=2, y=2 ; Pierre de Passage)
- Sorties : gauche → `hautepierre_1_2`, droite → `hautepierre_3_2`, haut → `hautepierre_2_1`, bas → `hautepierre_2_3`.
- Ambiance : Le cœur de la cité : pavés, fontaine, étals, l'auberge Au Heaume Fendu et la Pierre de Passage au milieu.
- Plan : Grande place dégagée en chemins (:) qui figurent les pavés ; fontaine (1×1) au centre et Pierre « * » juste au sud ; auberge (décor « auberge ») en haut-gauche, forge (décor « maison ») en haut-droite, 4 étals (1×1) ; murs (M) de façades le long des bords sauf aux 4 sorties (3 cases chacune).
- Ressources : —.
- Groupes : aucun.
- Décors : auberge, maison (forge), fontaine, etal ×4.
- PNJ `a` **Clairon, crieur public** (`clairon_crieur_public`) — PNJ d'ambiance (nouvelles de la guerre) : « Oyez, oyez ! La cendre tombe à l'est ! Le Conseil se réunira dès qu'il aura fini de se réunir pour décider quand se réunir ! » / « Oyez ! Un bélier géant aurait été vu près de la Brèche ! On recommande aux citoyens de ne pas être une porte ! » / « Oyez ! Les gobelins sont autorisés en ville, à condition de ne rien toucher. Les elfes aussi, à condition de ne rien critiquer. Bonne chance à tous. »
- PNJ `b` **Rosemonde Beurrefondu, marchande** (`rosemonde_beurrefondu`, marchand) — Marchande (maison mère du Poney Essoufflé) : « Bienvenue au Poney Essoufflé, la maison mère ! Mon neveu Barlimon tient la succursale de Brumerive. Il vous a parlé de moi ? Il parle trop. »
- PNJ `c` **Gontran Batenclume, forgeron de la Garde** (`gontran_batenclume`, atelier forgeron) — Atelier forgeron : « Je forge pour la Garde depuis trente ans. Épées, heaumes, et surtout des laissez-passer en fer : ça ne se perd pas. »
- PNJ `d` **Maître Ripaille, aubergiste** (`maitre_ripaille`) — PNJ d'ambiance (rumeurs) : « Au Heaume Fendu, on sert la meilleure bière de Hautepierre. Et la seule, depuis que les trolls ont bloqué le pont des brasseurs. » / « Un conseil : ne commandez jamais la « spécialité du troll ». C'est le troll qui la commande. » / « Les Cendrillons ? Ils viennent boire ici avant minuit. Après, ils ne payent plus : ils ont oublié qui ils sont. »

**`hautepierre_2_1` — Citadelle de la Tour Blanche** (nouvelle ; palier ville ; x=2, y=1)
- Sorties : haut → `hautepierre_2_0`, bas → `hautepierre_2_2`, gauche → `hautepierre_1_1`, droite → `hautepierre_3_1`.
- Ambiance : La haute ville : la Tour Blanche, l'Arbre Blanc (mort, repeint), les PNJ de l'histoire et la future salle du Conseil.
- Plan : Cour d'honneur dégagée ; Tour Blanche (décor « tour_blanche ») au centre-haut, Arbre Blanc (décor « arbre_mort » sur une case #) devant ; deux décors « maison » (salle du Conseil, archives) ; murs (M) d'enceinte avec les 4 ouvertures.
- Ressources : —.
- Groupes : aucun.
- Décors : tour_blanche, arbre_mort (Arbre Blanc), maison ×2.
- PNJ `a` **Gaspard le Sobre, Intendant de Hautepierre** (`intendant_gaspard`) — PNJ de l'histoire (acte II humain) : « Le roi ? Il reviendra. En attendant, c'est moi qui gouverne, et qui mange les tomates cerises. Une par décision. » / « La Cendre ? Une rumeur. Les gobelins ? Une nuisance. Les elfes ? Une opinion. Hautepierre tiendra. » / « Si vous voulez vous rendre utile, allez voir le capitaine. Il adore les volontaires : ils coûtent moins cher. »
- PNJ `b` **Capitaine Aldebert** (`capitaine_aldebert`) — PNJ de l'histoire (garde) : « On n'entre pas comme ça dans les Marches Cendrées. Il faut d'abord remplir le formulaire B-12. En trois exemplaires. » / « Un bélier de siège géant rôde à la Brèche, à l'est. Si vous êtes assez fou pour y aller, prenez au moins un casque. » / « Les trolls bloquent le pont du sud. Les corbacs nous espionnent au nord. Et l'Intendant compte ses tomates. »
- PNJ `c` **Pétronille, archiviste** (`archiviste_petronille`) — PNJ de lore (Reliques) : « Huit Reliques de l'Aube, huit bagues. La nôtre, la Chevalière Sans-Rouille, a disparu il y a trois siècles. On a gardé l'écrin. Il est très beau. » / « D'après les archives, chaque Relique est portée par un Héraut Cendré. D'après les mêmes archives, les Hérauts n'existent pas. Je vais devoir réécrire les archives. » / « Ne touchez pas aux parchemins du fond. Ce sont des factures de l'Âge de l'Aube. Toujours impayées. »
- PNJ `d` **Snagrod, délégué syndical gobelin** (`snagrod_delegue`) — PNJ de l'histoire (acte III en germe) : « J'attends dans l'antichambre depuis trois semaines. On m'a promis un siège au Conseil. Pour l'instant, j'ai un tabouret. » / « Les gobelins veulent trois choses : des chaises, des pauses, et ne plus être sacrifiés en premier. Dans cet ordre. » / « Si le Conseil se forme un jour, je réclamerai la présidence. On ne sait jamais, ça peut marcher. »
- PNJ `e` **Ilyndra Tel'Hautaine, ambassadrice elfe** (`ilyndra_tel_hautaine`) — PNJ de l'histoire (acte II elfe) : « Je suis ici en observatrice. J'observe. C'est très humain, tout ça. Très bruyant. » / « Le Conseil de la Lisière m'a envoyée pour décider s'il fallait envoyer quelqu'un. J'ai décidé que oui. On m'a donc envoyée. » / « La Cendre touche nos arbres. Ce n'est plus seulement votre guerre. Ne le répétez pas. »

**`hautepierre_1_2` — Porte de l'Ouest** (nouvelle ; palier ville ; x=1, y=2)
- Sorties : gauche → `hautepierre_0_2`, droite → `hautepierre_2_2`, haut → `hautepierre_1_1`, bas → `hautepierre_1_3`.
- Ambiance : La porte des routes de l'ouest (vers Brumerive) et le temple de la cité.
- Plan : Rempart (M) sur le bord gauche percé d'une porte de 3 cases entre deux « tour_de_garde » ; temple (décor « temple ») au centre-haut ; ruelles en chemins (:) ; quelques maisons (décor « maison »).
- Ressources : —.
- Groupes : aucun.
- Décors : temple, tour_de_garde ×2, maison ×2.
- PNJ `a` **Sergent Mordicus** (`sergent_mordicus`) — Garde de la porte : « Halte ! Laissez-passer ? … Pas de laissez-passer ? … Bon, passez, mais je vous ai à l'œil. » / « À l'ouest, la route de Brumerive. Pleine de détrousseurs. Ils volent tout, sauf les laissez-passer : ça, ils n'en veulent pas. »
- PNJ `b` **Frère Bénitier, prêtre** (`frere_benitier`) — PNJ d'ambiance (Théologues) : « J'ai béni la Masse bénite trois fois : le manche, la tête… et mon pouce. Il guérit très bien, merci. » / « Le Sacré, c'est la Force et l'Intelligence réunies. Comme moi. Enfin, comme moi les bons jours. » / « Les trolls craignent la lumière. Les Cendrillons aussi. Moi, je crains les trolls. Tout le monde craint quelque chose. »
- PNJ `c` **Fulbert l'Authentique, colporteur** (`fulbert_l_authentique`) — PNJ d'ambiance (humour) : « Véritable Relique de l'Aube ! Garantie d'origine ! Enfin, garantie… d'origine. D'une origine. » / « Celle-ci, c'est l'Anneau-Lanterne ! Il éclaire ! Si on le met près d'une bougie. » / « Je ne vends rien aujourd'hui, la Garde m'a confisqué le stock. Mais je reprends les commandes. »

**`hautepierre_3_2` — Porte de l'Est** (nouvelle ; palier ville ; x=3, y=2)
- Sorties : gauche → `hautepierre_2_2`, droite → `hautepierre_4_2`, haut → `hautepierre_3_1`, bas → `hautepierre_3_3`.
- Ambiance : La porte qui regarde vers l'est et la Cendre : réfugiés, barricades, gardes nerveux.
- Plan : Rempart (M) sur le bord droit percé d'une porte de 3 cases entre deux « tour_de_garde » ; barricades (R) ; tentes de réfugiés (décor « cabane ») ; un peu de cendre au sol (taches de palette).
- Ressources : —.
- Groupes : aucun.
- Décors : tour_de_garde ×2, cabane ×2.
- PNJ `a` **Sergente Brisetout** (`sergente_brisetout`) — Garde de la porte : « À l'est, la Route des Charrois vers Crasse-Roc, et la Brèche. Au sud-est, les terres cendrées. Je déconseille les deux. » / « Des gobelins arrivent par la Route de l'Est. Ils disent qu'ils fuient. Ils fuient quoi ? Ils ne savent pas l'expliquer. Ça m'inquiète. »
- PNJ `b` **Mélisande, réfugiée** (`melisande_la_refugiee`) — PNJ d'ambiance (acte II) : « Ma ferme était dans la plaine, à l'est. Maintenant, c'est une plaine de cendre. Et une ferme de cendre. » / « Il y avait des gens en noir qui dansaient dans la cendre en riant. À minuit, ils se sont arrêtés et ont pleuré. Je n'ai pas compris. »

**`hautepierre_0_2` — Route de l'Ouest** (nouvelle ; palier 13-15 ; x=0, y=2)
- Sorties : droite → `hautepierre_1_2` ; portes : `brumerive_3_1`.
- Ambiance : La grand-route qui monte de Brumerive : bornes, auberge en ruine, détrousseurs embusqués dans les fossés.
- Plan : Route (:) de 2 cases de large de la gauche à la droite, bordée de haies (A) et de fossés (E étroits) ; auberge en ruine (décor « maison ») ; au bord gauche, le passage « + » (porte vers brumerive_3_1) avec un « poteau_indicateur ».
- Ressources : C×2, Y×2, T×1.
- Groupes : 1. detrousseur; 2. detrousseur + detrousseur; 3. 2–3 parmi {detrousseur}.
- Lien entre zones : Porte « + » sur le bord gauche vers brumerive_3_1 (réciproque ajoutée sur le Gué de Brume-Haute par ce lot).

**`hautepierre_2_0` — Route du Nord** (nouvelle ; palier 13-15 ; x=2, y=0)
- Sorties : bas → `hautepierre_2_1`, gauche → `hautepierre_1_0`, droite → `hautepierre_3_0` ; portes : `sylvebrume_2_2`.
- Ambiance : La route qui descend de la Lisière : champs de blé, moulins, pèlerins perdus.
- Plan : Route (:) du haut vers le bas ; passage « + » sur le bord haut (porte vers sylvebrume_2_2) avec « poteau_indicateur » ; champs (zones dégagées) et bosquets (A) ; un moulin (décor « maison ») à droite.
- Ressources : F×2, C×2, Y×1.
- Groupes : 1. detrousseur + detrousseur; 2. detrousseur; 3. 1–3 parmi {detrousseur}.
- PNJ `a` **Anselme, pèlerin égaré** (`pelerin_egare`) — PNJ d'ambiance : « Je cherche le chemin de Hautepierre. … C'est en bas ? Depuis tout ce temps ? Je tournais autour. » / « Les détrousseurs m'ont tout pris. Sauf ma foi. Ils l'ont regardée, et ils l'ont reposée. »
- Lien entre zones : Porte « + » sur le bord haut vers sylvebrume_2_2 (réciproque ajoutée sur l'Orée du Sud par ce lot).

**`hautepierre_4_2` — Route de l'Est** (nouvelle ; palier 13-15 ; x=4, y=2)
- Sorties : gauche → `hautepierre_3_2`, haut → `hautepierre_4_1`, bas → `hautepierre_4_3` ; portes : `crasse_roc_0_2`.
- Ambiance : La route des charrois qui arrive des montagnes gobelines ; la cendre commence à griser les talus.
- Plan : Carte cendrée (palette `cendree`). Route (:) de la droite vers la gauche ; passage « + » sur le bord droit (porte vers crasse_roc_0_2) avec « poteau_indicateur » ; charrettes abandonnées (R) ; arbres grisés (A).
- Ressources : I×2, T×2, C×1.
- Groupes : 1. detrousseur + detrousseur; 2. 1–2 parmi {loup_cendreux}; 3. detrousseur + loup_cendreux; 4. detrousseur.
- PNJ `a` **Brokk, caravanier gobelin** (`caravanier_brokk`) — PNJ d'ambiance (acte II gobelin) : « On transporte du minerai pour le Souverain. Enfin, on transportait. Le Souverain a fait brûler la dernière caravane « pour l'exemple ». » / « L'exemple de quoi ? Personne n'a su me dire. Alors je fais une pause. Une longue. »
- Lien entre zones : Porte « + » sur le bord droit vers crasse_roc_0_2 (réciproque ajoutée sur la Route des Charrois par ce lot).

**`hautepierre_1_3` — Rives du Fleuve Gris** (nouvelle ; palier 16-18 ; x=1, y=3)
- Sorties : haut → `hautepierre_1_2`, droite → `hautepierre_2_3`.
- Ambiance : Le fleuve qui coule au pied de la cité ; lavoirs abandonnés, barques échouées, et des trolls qui pêchent à mains nues.
- Plan : Fleuve (E) large sur le bas de la carte, berge praticable de 4 à 6 lignes ; lavoir (décor « cabane ») ; roseaux (A bas) ; un ponton.
- Ressources : H×2, Y×1, G×1.
- Groupes : 1. troll_des_ponts; 2. troll_des_ponts + troll_des_ponts; 3. troll_des_ponts + detrousseur.
- PNJ `a` **Caron, passeur** (`passeur_caron`) — PNJ d'ambiance : « Un écu l'aller, deux le retour. Le pont des trolls ? Gratuit. Enfin, ça dépend pour qui. » / « Les trolls ne savent pas nager. Moi non plus. On a ça en commun, on en parle parfois. »

**`hautepierre_2_3` — Pont des Trolls** (nouvelle ; palier 16-18 ; x=2, y=3)
- Sorties : haut → `hautepierre_2_2`, gauche → `hautepierre_1_3`, bas → `hautepierre_2_4`, droite → `hautepierre_3_3`.
- Ambiance : Le vieux pont de pierre au sud de la cité, squatté par une famille de trolls qui réclame un péage en nature.
- Plan : Fleuve (E) horizontal au milieu de la carte, pont de pierre de 3 cases de large du haut vers le bas ; piles du pont (R) ; berges dégagées des deux côtés ; un feu de camp de troll (R) sous le pont.
- Ressources : H×2, G×2.
- Groupes : 1. troll_des_ponts; 2. troll_des_ponts + troll_des_ponts; 3. 2–3 parmi {troll_des_ponts, grouilleur_de_braise}; 4. troll_des_ponts.

**`hautepierre_2_4` — Gorges du Troll** (nouvelle ; palier 16-18 ; x=2, y=4)
- Sorties : haut → `hautepierre_2_3`, droite → `hautepierre_3_4`.
- Ambiance : Des gorges encaissées où la cendre s'accumule ; les grouilleurs venus des mines y ont muté en grouilleurs de braise.
- Plan : Carte cendrée (palette `cendree`). Falaises (R) sur les bords, défilé central de 4 à 6 cases ; éboulis (R) ; petit torrent (E) qui serpente.
- Ressources : G×2, H×1, T×1.
- Groupes : 1. 1–3 parmi {grouilleur_de_braise}; 2. troll_des_ponts + grouilleur_de_braise; 3. troll_des_ponts + troll_des_ponts.

**`hautepierre_1_0` — Bois-Corbeau** (nouvelle ; palier 19-21 ; x=1, y=0)
- Sorties : droite → `hautepierre_2_0`, bas → `hautepierre_1_1`.
- Ambiance : Un bois sombre aux arbres noirs où nichent les corbacs espions du Souverain ; on se sent observé, et on l'est.
- Plan : Arbres (A) serrés, troncs morts (arbre_mort via la palette ou A), clairières reliées ; nids (R) au pied des arbres ; aucun chemin tracé.
- Ressources : H×2, Y×2.
- Groupes : 1. corbac_espion + corbac_espion; 2. corbac_espion; 3. 2–3 parmi {corbac_espion}; 4. corbac_espion + arbre_calcine.

**`hautepierre_1_1` — Vigie aux Corbacs** (nouvelle ; palier 19-21 ; x=1, y=1)
- Sorties : haut → `hautepierre_1_0`, droite → `hautepierre_2_1`, bas → `hautepierre_1_2`.
- Ambiance : Une ancienne tour de vigie de la cité, abandonnée, dont les corbacs ont fait leur quartier général.
- Plan : Tour en ruine (décor « tour_de_garde ») au centre ; murets écroulés (M bas) en cercle ; prairie autour ; pigeonnier (décor « cabane »).
- Ressources : H×1, G×2.
- Groupes : 1. corbac_espion; 2. corbac_espion + corbac_espion; 3. 2–3 parmi {corbac_espion, troll_des_ponts}.

**`hautepierre_3_0` — Colline Pelée** (nouvelle ; palier 19-21 ; x=3, y=0)
- Sorties : gauche → `hautepierre_2_0`, bas → `hautepierre_3_1`.
- Ambiance : Une colline brûlée par la première pluie de cendre ; les arbres y sont devenus des arbres calcinés qui marchent.
- Plan : Carte cendrée (palette `cendree`). Colline : anneaux de rochers (R) en terrasses ; arbres morts (A) ; cratères de cendre (taches) ; vue dégagée au sommet.
- Ressources : H×1, G×1, L×1.
- Groupes : 1. 1–2 parmi {arbre_calcine}; 2. arbre_calcine + corbac_espion; 3. corbac_espion + corbac_espion.

**`hautepierre_3_1` — Ruines de la Vieille Garde** (nouvelle ; palier 22-24 ; x=3, y=1)
- Sorties : haut → `hautepierre_3_0`, gauche → `hautepierre_2_1`, droite → `hautepierre_4_1`, bas → `hautepierre_3_2`.
- Ambiance : Les ruines de l'ancienne enceinte, trois siècles plus vieille que la cité actuelle ; les gargouilles des anciens toits s'y sont réveillées.
- Plan : Pans de murs (M) en ruine formant des salles ouvertes ; colonnes (R) ; dalles (chemins :) ; une porte monumentale effondrée au centre.
- Ressources : G×2, L×1, D×1.
- Groupes : 1. gargouille; 2. gargouille + gargouille; 3. 2–3 parmi {gargouille, corbac_espion}.
- PNJ `a` **Capitaine Pérenne (fantôme)** (`capitaine_perenne`) — PNJ d'ambiance : « Garde, à vos postes ! … Ah. Pardon. Je suis de garde depuis trois cents ans. On a oublié de me relever. » / « Les gargouilles ? Elles gardaient les gouttières de mon temps. La Cendre les a réveillées. Elles gardent encore, mais contre tout le monde. »

**`hautepierre_4_1` — Cimetière des Gargouilles** (nouvelle ; palier 22-24 ; x=4, y=1)
- Sorties : gauche → `hautepierre_3_1`, bas → `hautepierre_4_2`.
- Ambiance : Le cimetière où l'on entassait les gargouilles cassées des toits de la ville. Elles n'ont pas aimé.
- Plan : Tombes et statues (R) en rangées ; caveau (décor « temple » recoloré ou « maison ») ; allées (:) ; un if noir (Y) dans un coin.
- Ressources : G×1, L×1, D×1.
- Groupes : 1. gargouille + gargouille; 2. gargouille; 3. 2–3 parmi {gargouille}.

**`hautepierre_3_3` — Camp des Cendrillons** (nouvelle ; palier 25-27 ; x=3, y=3)
- Sorties : haut → `hautepierre_3_2`, gauche → `hautepierre_2_3`, droite → `hautepierre_4_3`, bas → `hautepierre_3_4`.
- Ambiance : Le campement des adeptes de la Cendre, aux portes de la ville : tentes noires, piste de danse cendrée, horloge arrêtée à minuit moins cinq.
- Plan : Carte cendrée (palette `cendree`). Tentes (décor « cabane » ×2) ; cercle de danse dégagé au centre (7×7) entouré de braseros (R) ; horloge (décor « tour_de_garde ») en haut.
- Ressources : L×1, D×2.
- Groupes : 1. cendrillon; 2. cendrillon + cendrillon; 3. 2–3 parmi {cendrillon, gargouille}; 4. cendrillon + olifant_de_guerre.

**`hautepierre_4_3` — Plaine Cendrée** (nouvelle ; palier 25-27 ; x=4, y=3)
- Sorties : haut → `hautepierre_4_2`, gauche → `hautepierre_3_3`, bas → `hautepierre_4_4`.
- Ambiance : Une plaine agricole recouverte de cendre ; des fermes vides, des épouvantails noirs, des Cendrillons qui y valsent.
- Plan : Carte cendrée (palette `cendree`). Terrain ouvert, champs grisés, fermes (décor « maison ») abandonnées, clôtures (murets) ; peu d'obstacles (les olifants ont de la place).
- Ressources : L×2, D×1, G×1.
- Groupes : 1. cendrillon + cendrillon; 2. cendrillon; 3. 2–3 parmi {cendrillon}.

**`hautepierre_3_4` — Champs du Pèle-Ennemi** (nouvelle ; palier 28-30 ; x=3, y=4)
- Sorties : haut → `hautepierre_3_3`, gauche → `hautepierre_2_4`, droite → `hautepierre_4_4`.
- Ambiance : Le grand champ de bataille au sud-est de la cité, où l'armée du Souverain masse ses olifants avant l'assaut.
- Plan : Carte cendrée (palette `cendree`). Immense plaine ouverte ; carcasses de catapultes (R) ; tranchées (E étroites et peu nombreuses) ; étendards noirs (R isolés).
- Ressources : L×2, D×2.
- Groupes : 1. olifant_de_guerre; 2. olifant_de_guerre + cendrillon; 3. olifant_de_guerre + olifant_de_guerre; 4. 2–3 parmi {olifant_de_guerre, cendrillon}.
- PNJ `a` **Clopin, vétéran** (`veteran_clopin`) — PNJ d'ambiance : « J'étais là au dernier siège. On a gagné. Enfin, on a survécu, c'est pareil à la fin. » / « Le bélier, Grondin, frappe toujours trois coups. Au troisième, tenez-vous loin. Ou loin de loin. »

**`hautepierre_4_4` — La Brèche** (nouvelle ; palier 28-30 ; x=4, y=4 ; **boss**)
- Sorties : gauche → `hautepierre_3_4`, haut → `hautepierre_4_3`.
- Ambiance : La brèche ouverte dans la grande muraille extérieure, d'où descend la Cendre ; Grondin y attend la prochaine porte à enfoncer.
- Plan : Palette `cendre` (comme le Trône de Cendre). Muraille éventrée (M) en diagonale avec une brèche de 5 cases ; arène dégagée (8×8) devant ; braises (taches) ; débris (R) en couverts.
- Ressources : D×1.
- Groupes : 1. grondin (réapparition 45–60 s); 2. olifant_de_guerre + cendrillon. Groupe 1 : Grondin seul, fixe, réapparition en 1 min au plus.

### 6.2 Familles

| Famille | Palier | Rôle | Niv. de base : PV / PA / PM | XP base | Élite (niv., PV) |
|---|---|---|---|---|---|
| Détrousseur des grands chemins | 13-15 | moyen | 63 / 6 / 4 | 137 | Chef de bande (18, 174) |
| Troll des ponts | 16-18 | fort | 131 / 6 / 2 | 235 | Troll gastronome (21, 350) |
| Corbac espion | 19-21 | faible | 79 / 6 / 5 | 218 | Corbac chef espion (24, 206) |
| Gargouille | 22-24 | moyen | 142 / 6 / 3 | 342 | Gargouille de la Grande Porte (27, 361) |
| Cendrillon | 25-27 | moyen | 113 / 6 / 3 | 361 | Marraine Cendrée (30, 284) |
| Olifant de guerre | 28-30 | fort | 246 / 7 / 3 | 530 | Olifant-tour (33, 605) |

#### Détrousseur des grands chemins (`detrousseur`) — palier 13-15, famille moyen, gabarit standard
*Il vole les riches pour donner aux pauvres. Il est pauvre. La boucle est bouclée.*

- Niveaux 13–15 (poids 3/4/3) ; base (niv. 13) : PV 63, PA 6, PM 4, Ini 130, Cha 24, Agi 24 ; par niveau : pv +4, initiative +5, xp +14, agilite +2, chance +2.
- Résistances : Tempête +10, Givre +5, Acier +0, Flamme +0, Sacré -10 ; IA `basique` ; XP 137 (+14/niv.) ; écus 11–26.
- Sorts : 
  - **Coup de surin** (`detrousseur_surin`, nouveau) : 3 PA, portée 1, 2/tour — 5–7 Impie. *Dans l'ombre, sans prévenir, sans facture.* 
  - **La bourse ou la vie** (`detrousseur_la_bourse_ou_la_vie`, nouveau) : 3 PA, portée 1–2, 1/tour — 3–5 Tempête ; −15 Cha (2 t). *Vous choisissez la bourse. Il prend quand même un peu de la vie.*
- Butin : bourse_vide 55 % ×1–2, carte_au_tresor_douteuse 12 %, capuche_de_detrousseur 4 %, dague_de_detrousseur 3 %, bottes_de_grand_chemin 4 %.
- Dessin : rig `humain` (arme epee ; accessoires capuche ; couleurs tunique #3a4a32, manches #2e3a28, pantalon #3a3028, bottes #2e2620, ceinture #5a3a22, cheveux #2e2418, chapeau #2e3a28). **Nouveau dessin** : accessoire « capuche » (capuche de tissu rabattue sur la tête, 2 vues, couleur {{chapeau}}).
- Note : Humains hors-la-loi (aucun camp) : les routes autour de Hautepierre ne sont pas sûres, quel que soit le camp du joueur.
- **Élite : Chef de bande** (`chef_de_bande`), niveau 18 — *Il se fait appeler « le Prince des voleurs ». Ses hommes l'appellent « le patron » ; sa mère, « Gérard ».* PV 174, PA 7, PM 4, Ini 160, Cha 44, Agi 44 ; rés. Tempête +20, Givre +15, Acier +10, Flamme +10, Sacré -5 ; XP 383 ; écus 28–65.
  - Sorts : `detrousseur_surin`, `detrousseur_la_bourse_ou_la_vie`, `chef_de_bande_embuscade`
  - **Embuscade** (`chef_de_bande_embuscade`, nouveau) : 3 PA, portée 1–4, sans ldv, 1/tour, délai 2 — piège : 9–13 Impie (ennemis), −2 PM (1 t) (ennemis). *Ils étaient cachés dans le fossé. Ils y sont toujours, d'ailleurs.*
  - Butin : bourse_vide 88 % ×2–4, carte_au_tresor_douteuse 48 %, capuche_de_detrousseur 16 %, dague_de_detrousseur 13 %, bottes_de_grand_chemin 16 %.
  - Dessin : rig `humain_grand` (arme epee ; accessoires capuche ; couleurs tunique #4a2a3a, manches #3a2030, pantalon #2a2420, bottes #1e1a17, ceinture #c9a04e, cheveux #1e1a16, chapeau #4a2a3a).

#### Troll des ponts (`troll_des_ponts`) — palier 16-18, famille fort, gabarit tank
*Il garde un pont qui ne mène nulle part et réclame un péage que personne ne paie. Il a donc beaucoup de temps libre, et faim.*

- Niveaux 16–18 (poids 1/3/6) ; base (niv. 16) : PV 131, PA 6, PM 2, Ini 50, For 60 ; par niveau : pv +8, initiative +5, xp +21, force +4.
- Résistances : Acier +25, Givre +15, Tempête +0, Flamme -20, Sacré -10 ; IA `basique` ; XP 235 (+21/niv.) ; écus 17–40.
- Sorts : 
  - **Coup de massue** (`troll_coup_de_massue`, nouveau) : 4 PA, portée 1, 1/tour — 8–11 Acier ; poussee 1. *Pas de technique, beaucoup de massue.* 
  - **Lancer de rocher** (`troll_rocher`, nouveau) : 4 PA, portée 2–5, 1/tour — 5–8 Acier. *Il arrache un morceau de pont et vous le rend.*
- Butin : dent_de_troll 55 % ×1–2, recette_de_troll 12 %, ceinture_de_troll 4 %, anneau_de_nez_de_troll 4 %, massue_de_troll 3 %.
- Dessin : rig `troll` (arme massue ; couleurs peau #8a8a6a, tunique #6a5030, manches #8a8a6a, pantalon #5a4630, bottes #8a8a6a, ceinture #3a2a1a, cheveux #4a4a3a). **Nouveau dessin** : têtes « tete_troll » et « tete_troll_dos » (grosse tête ronde au nez énorme, petites oreilles pointues, deux crocs du bas, front bas ; peau {{peau}}) pour le nouvel assemblage « troll » (base humain, échelle 1.15) ; arme « massue » (gourdin noueux avec un clou).
- Note : Tank lent (2 PM) qui craint la Flamme et le Sacré : les théologues et pyromanes ont l'avantage.
- **Élite : Troll gastronome** (`troll_gastronome`), niveau 21 — *Il a lu un livre de cuisine. Un seul. Il l'applique à tout le monde.* PV 350, PA 7, PM 2, Ini 80, For 90 ; rés. Acier +35, Givre +25, Tempête +10, Flamme -15, Sacré -5 ; XP 622 ; écus 42–100.
  - Sorts : `troll_coup_de_massue`, `troll_rocher`, `gastronome_marinade`
  - **Marinade** (`gastronome_marinade`, nouveau) : 3 PA, portée 1–2, 1/tour — poison Flamme 4–6 (3 t) ; −10 Rés. Flamme (3 t). *Il vous assaisonne avant cuisson. Le feu vous fera plus mal ensuite.*
  - Butin : dent_de_troll 88 % ×2–4, recette_de_troll 48 %, ceinture_de_troll 16 %, anneau_de_nez_de_troll 16 %, massue_de_troll 13 %.
  - Dessin : rig `troll_grand` (arme massue ; accessoires tablier ; couleurs peau #7a7a5a, tunique #e8e0d0, manches #7a7a5a, pantalon #4a3a28, bottes #7a7a5a, ceinture #3a2a1a, cheveux #3a3a2a, tablier #f2ecdc).

#### Corbac espion (`corbac_espion`) — palier 19-21, famille faible, gabarit tireur
*Un corbeau au service de la Cendre, avec une longue-vue en bandoulière. Il note tout ce que vous faites, surtout les bêtises.*

- Niveaux 19–21 (poids 6/3/1) ; base (niv. 19) : PV 79, PA 6, PM 5, Ini 150, Agi 72 ; par niveau : pv +4, initiative +5, xp +17, agilite +4.
- Résistances : Tempête +25, Flamme +5, Givre +0, Acier -10 ; IA `distance` ; XP 218 (+17/niv.) ; écus 15–34.
- Sorts : 
  - **Coup de bec** (`corbac_bec`, nouveau) : 3 PA, portée 1, 1/tour — 5–7 Acier. *Toujours dans l'œil. Il vise bien, il a de l'entraînement.* 
  - **Piqué** (`corbac_pique`, nouveau) : 4 PA, portée 2–5, 1/tour — 6–9 Tempête. *Il tombe du ciel comme un mauvais présage, et c'en est un.*
- Butin : plume_de_corbac 55 % ×1–3, message_intercepte 12 %, chapeau_a_plume_de_corbac 4 %, amulette_oeil_de_corbac 2 %.
- Dessin : image `corbac` (échelle 0.9). **Nouveau dessin** : monstre/corbac.svgt, ~44×42 px : gros corbeau noir aux reflets bleus ({{pelage}}/{{pelage_ombre}}), ailes à demi déployées, bec épais gris, œil rouge, petite longue-vue en laiton en bandoulière ; perché au sol, ancre entre les pattes..
- Note : Tireur rapide (5 PM, IA distance) : il faut le coincer contre les obstacles. Faible à l'Acier.
- **Élite : Corbac chef espion** (`corbac_chef_espion`), niveau 24 — *Il dirige un réseau de quatre cents corbeaux. Il connaît votre adresse, votre taille de chapeau et votre plat préféré.* PV 206, PA 7, PM 5, Ini 180, Agi 102 ; rés. Tempête +35, Flamme +15, Givre +10, Acier -5 ; XP 554 ; écus 38–85.
  - Sorts : `corbac_bec`, `corbac_pique`, `chef_espion_rapport`
  - **Rapport détaillé** (`chef_espion_rapport`, nouveau) : 3 PA, portée 1–6, 1/tour — −15 Rés. Tempête (2 t) ; −1 Portée (1 t). *Il a tout noté. Vos faiblesses aussi.*
  - Butin : plume_de_corbac 88 % ×2–5, message_intercepte 48 %, chapeau_a_plume_de_corbac 16 %, amulette_oeil_de_corbac 12 %, cape_de_plumes_noires 15 %.
  - Dessin : image `corbac` (échelle 1.15 ; teinte #c0b0d8).

#### Gargouille (`gargouille`) — palier 22-24, famille moyen, gabarit costaud
*Elle a gardé une gouttière de Hautepierre pendant trois siècles. Depuis que la Cendre tombe, elle garde rancune.*

- Niveaux 22–24 (poids 3/4/3) ; base (niv. 22) : PV 142, PA 6, PM 3, Ini 70, For 42, Cha 42 ; par niveau : pv +8, initiative +5, xp +23, force +2, chance +2.
- Résistances : Acier +30, Flamme +20, Givre +10, Tempête -15 ; IA `basique` ; XP 342 (+23/niv.) ; écus 22–49.
- Sorts : 
  - **Griffes de pierre** (`gargouille_griffes`, nouveau) : 4 PA, portée 1, 1/tour — 7–10 Acier. *Trois siècles à garder une gouttière, ça aiguise les griffes.* 
  - **Gargouillis** (`gargouille_gargouillis`, nouveau) : 3 PA, portée 2–4, 1/tour — 5–7 Givre. *Elle crache l'eau de pluie de la semaine. Glacée.*
- Butin : eclat_de_gargouille 55 % ×1–3, coeur_de_pierre 12 %, anneau_de_granit 4 %, bottes_de_gargouille 3 %, hallebarde_de_la_vieille_garde 3 %.
- Dessin : image `gargouille` (échelle 0.9). **Nouveau dessin** : monstre/gargouille.svgt, ~54×60 px : gargouille de pierre grise ({{pierre}}) accroupie, petites ailes de chauve-souris repliées, cornes courtes, gueule grande ouverte en gouttière, griffes ; taches de mousse ; ancre aux pieds..
- Note : Très résistante à l'Acier et à la Flamme, faible à la Tempête : la famille qui oblige les guerriers à varier.
- **Élite : Gargouille de la Grande Porte** (`gargouille_de_la_grande_porte`), niveau 27 — *La plus vieille de la ville. Elle a vu passer trois rois, deux sièges et un nombre incalculable de pigeons.* PV 361, PA 7, PM 3, Ini 100, For 62, Cha 62 ; rés. Acier +40, Flamme +30, Givre +20, Tempête -10 ; XP 834 ; écus 55–122.
  - Sorts : `gargouille_griffes`, `gargouille_gargouillis`, `gargouille_petrification`
  - **Regard de pierre** (`gargouille_petrification`, nouveau) : 3 PA, portée 1–3, 1/tour, délai 2 — 3–5 Givre ; −2 PM (1 t) ; −1 PA (1 t). *Un regard figé. Vos jambes suivent l'exemple.*
  - Butin : eclat_de_gargouille 88 % ×2–5, coeur_de_pierre 48 %, anneau_de_granit 16 %, bottes_de_gargouille 13 %, hallebarde_de_la_vieille_garde 13 %, amulette_coeur_de_pierre 15 %.
  - Dessin : image `gargouille` (échelle 1.15 ; teinte #d8d0c0).

#### Cendrillon (`cendrillon`) — palier 25-27, famille moyen, gabarit soutien
*Adepte du Souverain Cendré. Ils dansent dans la cendre et doivent rentrer avant minuit, sinon ils redeviennent des gens normaux.*

- Niveaux 25–27 (poids 3/4/3) ; base (niv. 25) : PV 113, PA 6, PM 3, Ini 110, Int 96 ; par niveau : pv +6, initiative +5, xp +22, intelligence +4.
- Résistances : Flamme +30, Impie +15, Acier +0, Givre -20, Sacré -15 ; IA `soutien` ; XP 361 (+22/niv.) ; écus 21–48.
- Sorts : 
  - **Cendres ardentes** (`cendrillon_cendres_ardentes`, nouveau) : 4 PA, portée 2–5, 1/tour — 6–9 Flamme. *Une poignée de cendre du Souverain, jetée au visage. Ça ne part pas.* 
  - **Bal de minuit** (`cendrillon_bal_de_minuit`, nouveau) : 3 PA, portée 0–3, 1/tour, délai 1 — soin Flamme 7–10 (alliés). *Une valse de cendre qui referme les plaies d'un fidèle.*
- Butin : cendre_tiede 55 % ×1–3, invitation_au_bal 12 %, pantoufles_de_cendre 3 %, masque_de_cendrillon 4 %, baguette_de_cendrillon 3 %, bague_de_minuit 3 %.
- Dessin : rig `humain` (arme sceptre ; accessoires cape_cendre ; couleurs peau #d8c8c0, tunique #3a302c, manches #2a2420, pantalon #1e1a17, bottes #141110, ceinture #8a2a1a, cheveux #8a8a8a).
- Note : IA soutien : soigne les autres Cendrillons et les olifants qu'ils accompagnent. Faibles au Givre et au Sacré.
- **Élite : Marraine Cendrée** (`marraine_cendree`), niveau 30 — *Elle exauce les vœux. Le vôtre était de rentrer chez vous ; elle l'a mal compris.* PV 284, PA 7, PM 3, Ini 140, Int 126 ; rés. Flamme +40, Impie +25, Acier +10, Givre -15, Sacré -10 ; XP 856 ; écus 52–120.
  - Sorts : `cendrillon_cendres_ardentes`, `cendrillon_bal_de_minuit`, `marraine_coup_de_baguette`
  - **Coup de baguette** (`marraine_coup_de_baguette`, nouveau) : 4 PA, portée 1–4, cercle 1, 1/tour — 6–8 Flamme ; −1 PA (1 t). *Un geste gracieux, une citrouille qui explose.*
  - Butin : cendre_tiede 88 % ×2–5, invitation_au_bal 48 %, pantoufles_de_cendre 13 %, masque_de_cendrillon 16 %, baguette_de_cendrillon 13 %, bague_de_minuit 13 %.
  - Dessin : rig `humain_grand` (arme sceptre ; accessoires cape_cendre, etole ; couleurs peau #e0d0c8, tunique #5a4a6a, manches #3a2e4a, pantalon #2a2236, bottes #141110, ceinture #c9a04e, cheveux #e8e8e8, etole #c9a04e).

#### Olifant de guerre (`olifant_de_guerre`) — palier 28-30, famille fort, gabarit tank
*Trois tonnes, quatre défenses, et un caparaçon rouge brodé « Armée du Souverain ». Il ne sait pas lire, heureusement pour lui.*

- Niveaux 28–30 (poids 1/3/6) ; base (niv. 28) : PV 246, PA 7, PM 3, Ini 60, For 108 ; par niveau : pv +11, initiative +5, xp +29, force +4.
- Résistances : Acier +30, Tempête +20, Flamme +10, Givre -15 ; IA `basique` ; XP 530 (+29/niv.) ; écus 29–68.
- Sorts : 
  - **Charge d'olifant** (`olifant_charge`, nouveau) : 5 PA, portée 1, 1/tour — 9–13 Acier ; poussee 2. *Trois tonnes de bonne humeur, lancées droit sur vous.* 
  - **Barrissement** (`olifant_barrissement`, nouveau) : 3 PA, portée 0, cercle 2, sans ldv, lanceur exclu, 1/tour, délai 1 — 3–5 Tempête (ennemis) ; −1 PM (1 t) (ennemis). *Le cor d'origine. Les oreilles saignent, les jambes flanchent.*
- Butin : cuir_d_olifant 55 % ×1–2, ivoire_d_olifant 12 %, cape_en_cuir_d_olifant 4 %, semelles_d_olifant 3 %, cor_d_olifant 1.5 %.
- Dessin : image `olifant` (échelle 0.9). **Nouveau dessin** : monstre/olifant.svgt, ~86×70 px : éléphant de guerre gris ({{pelage}}/{{pelage_ombre}}) vu de 3/4, quatre défenses, grandes oreilles, caparaçon rouge à bordure dorée sur le dos, petite tête de mort cendrée brodée ; ancre entre les pattes..
- Note : Le monstre normal le plus solide de l'alpha. Ses groupes viennent avec des Cendrillons qui le soignent.
- **Élite : Olifant-tour** (`olifant_a_tour`), niveau 33 — *Un olifant qui porte une tour sur le dos. Dans la tour, personne. Il l'a gardée par habitude.* PV 605, PA 8, PM 3, Ini 90, For 138 ; rés. Acier +40, Tempête +30, Flamme +20, Givre -10 ; XP 1228 ; écus 72–170.
  - Sorts : `olifant_charge`, `olifant_barrissement`, `olifant_pietinement`
  - **Piétinement** (`olifant_pietinement`, nouveau) : 5 PA, portée 0, cercle 1, sans ldv, lanceur exclu, 1/tour — 10–13 Acier. *Il danse. Personne n'a envie d'être son cavalier.*
  - Butin : cuir_d_olifant 88 % ×2–4, ivoire_d_olifant 48 %, cape_en_cuir_d_olifant 16 %, semelles_d_olifant 13 %, cor_d_olifant 12 %.
  - Dessin : image `olifant` (échelle 1.12 ; teinte #c8b8a8).

### 6.3 Boss

#### Mini-boss : Grondin, Bélier de la Brèche (`grondin`) — niveau 30, carte `hautepierre_4_4`
*Un bélier de siège à tête de loup, forgé dans les Marches Cendrées. Il avance tout seul. Personne ne veut savoir comment.*

- PV 600, PA 8, PM 2, Ini 80, For 40 ; rés. Acier +35, Flamme +25, Tempête +10, Givre -20, Sacré -10 ; IA `basique` ; XP 3600 ; écus 300–500.
- Groupe fixe : grondin ; réapparition 45–60 s.
- Sorts : 
  - **Coup de bélier** (`grondin_coup_de_belier`, nouveau) : 5 PA, portée 1, 1/tour — 12–16 Acier ; poussee 2. *Le coup qui a fait trembler la Grande Porte. Vous êtes moins solide qu'une porte.*
  - **Éclats de porte** (`grondin_eclats_de_porte`, nouveau) : 3 PA, portée 2–5, cercle 1, 1/tour — 4–6 Acier. *Il crache les morceaux des portes qu'il a déjà enfoncées.*
  - **Élan** (`grondin_elan`, nouveau) : 2 PA, portée 0, sans ldv, 1/tour, délai 2 — +2 PM (1 t). *Les roues grincent, les chaînes claquent : il recule pour mieux frapper.*
  - **Charge de la Brèche** (`grondin_charge`, nouveau) : 5 PA, portée 2–5, en ligne, 1/tour, délai 2 — 10–14 Acier ; poussee 2. *Les chaînes lâchent : le bélier dévale la pente. Ce qui est devant lui ne le reste pas.*
  - **Souffle de forge** (`grondin_souffle_de_forge`, nouveau) : 4 PA, portée 1–4, cercle 1, 1/tour — 8–11 Flamme. *La tête de loup crache le feu de la forge où on l'a coulée.*
- Phases :
  - **75 %** — « Des mains invisibles clouent des planches neuves sur le toit du bélier. Personne ne veut savoir à qui elles sont. » — sur lui : bouclier Acier 80–80 ; +20 Rés. Givre (3 t)
  - **50 %** — « « Grondin ! Grondin ! » scandent des voix dans la cendre. Les chaînes lâchent. » — apprend `grondin_charge` ; sur lui : +2 PM (3 t)
  - **20 %** — « « Trois coups ! On frappe toujours trois coups ! » Ses roues cassent ; sa tête de loup s'embrase. » — apprend `grondin_souffle_de_forge` ; sur lui : +40 For (3 t) ; −2 PM (3 t)
- Butin : eclat_de_cendre 100 % ×1–2, heaume_du_belier 15 %, anneau_du_gond 15 %, marteau_de_grondin 6 %.
- Dessin : image `grondin` (échelle 1.0). **Nouveau dessin** : monstre/grondin.svgt, ~112×76 px : bélier de siège sur 4 roues, poutre de bois noir cerclée de fer, tête de loup en fer forgé à l'avant aux yeux rouge braise, chaînes pendantes, toit de planches roussies ; ancre au centre bas (≈ [56, 72]). Pas d'équipage : il avance seul..
- Équilibrage : Profil de siège. Pour un niveau 29–30 seul (~285 PV, ~60 dégâts/tour) : ~680 PV effectifs (600 + bouclier 80, sous les 900 du Souverain), 11 tours ; ~28 dégâts/tour (poussées comprises) ; à 50 % il charge de loin ; à 20 %, ~40 dégâts/tour mais −2 PM : on peut le contourner et frapper à distance. Faible au Givre (−20, couvert 3 tours à 75 %) et au Sacré (−10).

### 6.4 La ville

Hautepierre est la cité des humains bâtie sur un éperon rocheux blanc : remparts, Tour Blanche, Arbre Blanc (mort depuis deux siècles, repeint chaque printemps), et une administration qui délivre des laissez-passer à ceux qui ont déjà un laissez-passer. Terrain commun des trois camps : à l'acte II, les gardes tolèrent gobelins et elfes « en visite » (plus tard : gardes hostiles avant l'acte III, voir TODO) ; à l'acte III, la salle du Conseil des Peuples Libres s'ouvre dans la Citadelle.

- **4 cartes de ville**, palette `hautepierre` (herbe tirant vers le gris-vert des pavés, murs clairs), sans monstres : la Grand-Place (Pierre de Passage, marchande, forgeron, auberge), la Citadelle de la Tour Blanche (PNJ de l'histoire), la Porte de l'Ouest (temple) et la Porte de l'Est (vers les terres cendrées).
- **Remparts** : lignes de murs (M) sur les bords des cartes de ville, percées aux sorties ; chaque Porte a un passage de 3 cases encadré de deux tours (décor `tour_de_garde`).
- **Nouveaux décors** (3×3 sauf mention) : `tour_blanche` (tour haute, toit d'ardoise bleue, bannière à tour blanche ; emprise 3×3 mais dessinée haute), `temple` (fronton, colonnes, soleil doré), `tour_de_garde`, et en 1×1 `fontaine` (bassin rond, statue d'un héros dont personne ne se rappelle le nom), `etal` (étal de marché à toile rayée), `poteau_indicateur` (pour les passages entre zones, voir § 2).
- **Pierre de Passage** `hautepierre` sur la Grand-Place, **20 écus** (plus loin que les zones de départ), à découvrir.
- Pas de maison du joueur à Hautepierre pour l'alpha (on garde celle de sa zone de départ ; la Pierre y ramène).

## 7. Variantes Corrompues

**Règle simple des Corrompus.** Une variante Corrompue est un monstre à part entière (son propre fichier), marqué `"corrompu": true` et `"base": "<famille d'origine>"`. Ce n'est pas une famille : **pas d'élite**, pas de `famille`, et le test « un élite par famille » doit l'ignorer. Elle se construit toujours de la même façon :

1. **Niveau** : environ 10 à 15 niveaux au-dessus de sa base, dans un palier de Hautepierre (13–15, 16–18, 19–21), avec ses propres `niveaux` et poids.
2. **Corps** : même dessin que sa base, assombri (`teinte` ou `couleurs`) ; PV ≈ référence du niveau × 1,1 (× 1,5 pour l'arbre, qui reste un tank) ; mêmes PA/PM que sa base.
3. **Cendre** : Flamme +20 à +35 en résistance, Sacré −10 (la lumière la blesse), faiblesse Givre ; elle garde **les sorts de sa base** et gagne **un sort de Flamme**.
4. **Butin** : la ressource commune de sa base, `cendre_tiede` (50 %), `eclat_de_cendre` (3 %, rare) et un équipement rare qui lui est propre.
5. **Apparition** : seulement sur les **cartes cendrées** (`"cendree": true` dans la carte : cendre qui tombe, palette `cendree`), placée explicitement dans les `groupes` (jamais plus d'une variante par groupe fixe ; dans un `parmi`, elle peut être seule). Pas de tirage aléatoire caché : ce qu'on voit dans le fichier de carte est ce qui apparaît.

Plus tard (hors alpha), la même règle permettra une « contamination » : une carte d'une zone de départ deviendrait cendrée à l'acte II et ses familles y laisseraient la place à leurs variantes.

| Variante | Base | Palier | PV / PA / PM (niv. min) | Cartes |
|---|---|---|---|---|
| Loup cendreux (`loup_cendreux`) | `loup_des_collines` | 13-15 | 69 / 6 / 4 | hautepierre_4_2 |
| Grouilleur de braise (`grouilleur_de_braise`) | `grouilleur` | 16-18 | 85 / 6 / 3 | hautepierre_2_3, hautepierre_2_4 |
| Arbre calciné (`arbre_calcine`) | `arbre_vivant` | 19-21 | 140 / 7 / 1 | hautepierre_1_0, hautepierre_3_0 |

#### Loup cendreux (`loup_cendreux`, base `loup_des_collines`) — palier 13-15
*Un loup des collines qui a mangé quelque chose qu'il n'aurait pas dû, dans la cendre. Il a toujours faim, mais maintenant il fume.*

- Niveaux 13–15 (poids 3/4/3) ; base : PV 69, PA 6, PM 4, Ini 130, For 24, Int 24 ; par niveau : pv +5, initiative +5, xp +16, force +2, intelligence +2.
- Résistances : Flamme +20, Givre +10, Impie +15, Acier +0, Tempête +0, Sacré -10 ; IA `basique` ; XP 151 ; écus 12–29.
- Sorts : 
  - `loup_morsure` (existant)
  - **Morsure brûlante** (`cendreux_morsure_brulante`, nouveau) : 3 PA, portée 1, 1/tour — 4–6 Flamme ; poison Flamme 2–3 (2 t). *Ses crocs gardent la chaleur de la Cendre.*
- Butin : croc_de_loup 50 % ×1–2, cendre_tiede 50 % ×1–2, eclat_de_cendre 3 %, cape_de_loup_cendreux 4 %.
- Dessin : image `loup` (échelle 0.9 ; couleurs pelage #3a3634, pelage_ombre #26221f, ventre #c25a2a).

#### Grouilleur de braise (`grouilleur_de_braise`, base `grouilleur`) — palier 16-18
*Un grouilleur descendu des mines dans les gorges cendrées. Son acide a pris feu ; ses pattes aussi, un peu.*

- Niveaux 16–18 (poids 1/3/6) ; base : PV 85, PA 6, PM 3, Ini 90, For 30, Int 30 ; par niveau : pv +6, initiative +5, xp +18, force +2, intelligence +2.
- Résistances : Flamme +35, Impie +10, Acier +0, Givre -10, Sacré -10 ; IA `basique` ; XP 199 ; écus 14–34.
- Sorts : 
  - `grouilleur_pinces` (existant)
  - **Crachat de feu** (`braise_crachat_de_feu`, nouveau) : 4 PA, portée 2–4, cercle 1, 1/tour — 5–7 Flamme. *L'acide a pris feu. Il en est très fier.*
- Butin : carapace_de_grouilleur 50 % ×1–2, cendre_tiede 50 % ×1–2, eclat_de_cendre 3 %, bottes_de_braise 4 %.
- Dessin : image `grouilleur` (échelle 0.95 ; teinte #ff9a60).

#### Arbre calciné (`arbre_calcine`, base `arbre_vivant`) — palier 19-21
*Un arbre vivant que la première pluie de cendre a brûlé debout. Il marche encore, il fume, et il est de très mauvaise humeur.*

- Niveaux 19–21 (poids 3/4/3) ; base : PV 140, PA 7, PM 1, Ini 40, For 36, Int 36 ; par niveau : pv +8, initiative +5, xp +23, force +2, intelligence +2.
- Résistances : Acier +25, Flamme +30, Givre -20, Tempête +0, Sacré -10 ; IA `basique` ; XP 299 ; écus 21–47.
- Sorts : 
  - `arbre_branche` (existant)
  - `arbre_racines` (existant)
  - **Pluie de cendres** (`calcine_cendres`, nouveau) : 3 PA, portée 1–3, cercle 1, sans ldv, 1/tour, délai 2 — glyphe 2 t : 4–6 Flamme (ennemis). *Il secoue ses branches mortes ; il en tombe des braises.*
- Butin : ecorce_vivante 50 % ×1–2, cendre_tiede 50 % ×1–2, eclat_de_cendre 3 %, ceinture_d_ecorce_calcinee 4 %.
- Dessin : image `arbre_vivant` (échelle 0.95 ; teinte #6a5a50).

## 8. Objets

94 nouveaux objets : 18 armes, 6 coiffes, 6 capes, 5 amulettes, 7 anneaux, 5 ceintures, 8 bottes, 39 ressources. Les bonus suivent le budget `(3 + 0,8 × niveau) × rareté` (commun 1 ; peu commun 1,2 ; rare 1,45 ; épique 1,8 ; légendaire 2,2), pondéré par stat (Vitalité 0,5 ; Prospection 0,25 ; Initiative 0,1 ; Dommages 4 ; Critique 2) ; les armes prennent 60 % du budget, le reste est dans l'attaque. Chaque objet a besoin d'une icône (description dans le JSON, champ `icone`).

### 8.1 Armes (18)

| Objet | Niv. | Rareté | Bonus | Source |
|---|---|---|---|---|
| Épée de milicien (`epee_de_milicien`) | 8 | commun | For 3–4, Vit 4–5 ; attaque 4 PA, PO 1–1, 9–14 Acier | butin:milicien_de_hautepierre |
| Fourche d'épouvantail (`fourche_d_epouvantail`) | 8 | commun | For 3–4, Vit 4–5 ; attaque 4 PA, PO 1–2, 9–14 Acier | butin:epouvantail_demotive |
| Coutelas de pillard (`coutelas_de_pillard`) | 9 | peu commun | Agi 3–4, Cha 3–4 ; attaque 3 PA, PO 1–1, 8–11 Impie | butin:gobelin_pillard |
| Hache de bûcheron (`hache_de_bucheron`) | 9 | peu commun | For 4–5, Vit 5–7 ; attaque 4 PA, PO 1–1, 10–15 Acier | butin:bucheron_de_brumerive |
| Arc d'if (`arc_d_if`) | 10 | peu commun | Agi 4–6, Ini 19–27 ; attaque 4 PA, PO 2–6, 10–16 Tempête | recette |
| Bâton gelé (`baton_gele`) | 11 | peu commun | Cha 5–7, Sag 2–3 ; attaque 3 PA, PO 1–4, 8–12 Givre | recette |
| Fouet du Balourd (`fouet_du_balourd`) | 12 | épique | Int 5–8, Vit 7–9, Dom 1 ; attaque 4 PA, PO 1–3, 13–19 Flamme | boss:balourd_des_abimes |
| Fuseau de la Mère-Toile (`fuseau_de_la_mere_toile`) | 12 | épique | Cha 5–8, Vit 7–9, Dom 1 ; attaque 4 PA, PO 2–5, 13–19 Givre | boss:mere_toile |
| Hachoir de Krasbouk (`hachoir_de_krasbouk`) | 12 | épique | For 5–8, Vit 7–9, Dom 1 ; attaque 4 PA, PO 1–1, 13–19 Acier | boss:krasbouk |
| Dague de détrousseur (`dague_de_detrousseur`) | 14 | peu commun | Agi 6–8, Ini 24–35 ; attaque 3 PA, PO 1–3, 9–13 Tempête | butin:detrousseur |
| Épée d'argent (`epee_d_argent`) | 15 | rare | For 6–9, Vit 4–6, Sag 2–3 ; attaque 4 PA, PO 1–1, 13–19 Acier | recette |
| Massue de troll (`massue_de_troll`) | 17 | rare | For 7–10, Vit 9–13 ; attaque 5 PA, PO 1–1, 17–25 Acier | butin:troll_des_ponts |
| Sceptre de Hautepierre (`sceptre_de_hautepierre`) | 18 | rare | For 4–5, Int 4–5, Sag 2–3, Vit 5–7 ; attaque 4 PA, PO 1–2, 14–20 Sacré | recette |
| Hallebarde de la Vieille Garde (`hallebarde_de_la_vieille_garde`) | 22 | rare | For 7–10, Vit 9–12, Sag 3–4 ; attaque 4 PA, PO 1–2, 15–22 Acier | butin:gargouille |
| Dague d'obsidienne (`dague_d_obsidienne`) | 23 | rare | Agi 6–9, Cha 6–9, Crit 1–2 ; attaque 3 PA, PO 1–1, 11–17 Impie | recette |
| Arc de malorme (`arc_de_malorme`) | 25 | rare | Agi 10–14, Ini 32–46, Sag 3–5 ; attaque 4 PA, PO 2–7, 16–23 Tempête | recette |
| Baguette de Cendrillon (`baguette_de_cendrillon`) | 26 | rare | Int 10–14, Sag 3–5, Vit 7–10 ; attaque 4 PA, PO 2–6, 16–24 Flamme | butin:cendrillon |
| Marteau de Grondin (`marteau_de_grondin`) | 30 | légendaire | For 13–18, Vit 14–20, Dom 2–3, PA 1 ; attaque 5 PA, PO 1–1, 25–37 Acier | boss:grondin |

### 8.2 Coiffes (6)

| Objet | Niv. | Rareté | Bonus | Source |
|---|---|---|---|---|
| Chapeau d'épouvantail (`chapeau_d_epouvantail`) | 7 | peu commun | Agi 4–6, Vit 5–7, Sag 2 | butin:epouvantail_demotive |
| Capuche de détrousseur (`capuche_de_detrousseur`) | 13 | peu commun | Agi 5–7, Cha 4–6, Pro 15–22 | butin:detrousseur |
| Chapeau à plume de corbac (`chapeau_a_plume_de_corbac`) | 19 | peu commun | Agi 9–13, Pro 17–25, Ini 44–63 | butin:corbac_espion |
| Heaume d'argent (`heaume_d_argent`) | 20 | rare | Vit 22–32, For 7–10, Sag 4–6 | recette |
| Masque de Cendrillon (`masque_de_cendrillon`) | 26 | rare | Int 14–20, Vit 17–24, Sag 6–8 | butin:cendrillon |
| Heaume du Bélier (`heaume_du_belier`) | 30 | épique | For 16–22, Vit 31–45, Dom 2–3 | boss:grondin |

### 8.3 Capes (6)

| Objet | Niv. | Rareté | Bonus | Source |
|---|---|---|---|---|
| Cape de vampipistrelle (`cape_de_vampipistrelle`) | 5 | peu commun | Agi 3–4, Cha 2–3, Ini 20–29 | butin:vampipistrelle |
| Cape de soie grise (`cape_de_soie_grise`) | 11 | peu commun | Cha 6–8, Sag 2–3, Vit 7–10 | butin:tisseuse_de_brume |
| Cape de fumée (`cape_de_fumee`) | 12 | rare | Int 6–8, Agi 4–6, Vit 9–13 | boss:balourd_des_abimes |
| Cape de loup cendreux (`cape_de_loup_cendreux`) | 15 | rare | Agi 7–10, Vit 10–15, Ini 52–75 | butin:loup_cendreux |
| Cape de plumes noires (`cape_de_plumes_noires`) | 21 | rare | Agi 11–17, Vit 14–20, Ini 46–66 | butin:corbac_chef_espion |
| Cape en cuir d'olifant (`cape_en_cuir_d_olifant`) | 28 | rare | Vit 29–42, For 9–13, Sag 6–8 | butin:olifant_de_guerre |

### 8.4 Amulettes (5)

| Objet | Niv. | Rareté | Bonus | Source |
|---|---|---|---|---|
| Amulette-sifflet (`amulette_sifflet`) | 11 | peu commun | Ini 34–49, Agi 5–7, Sag 3–5 | butin:contremaitre_zele |
| Amulette d'argent (`amulette_d_argent`) | 16 | peu commun | Vit 12–17, For 3–4, Int 3–4, Cha 3–4 | recette |
| Amulette œil-de-corbac (`amulette_oeil_de_corbac`) | 20 | rare | Agi 9–13, Pro 26–38, Sag 7–10 | butin:corbac_espion |
| Amulette cœur-de-pierre (`amulette_coeur_de_pierre`) | 24 | rare | Vit 26–37, Cha 8–11, Sag 5–7 | butin:gargouille_de_la_grande_porte |
| Cor d'olifant (`cor_d_olifant`) | 29 | épique | For 11–16, Vit 23–33, Dom 2–3, Sag 8–11 | butin:olifant_de_guerre |

### 8.5 Anneaux (7)

| Objet | Niv. | Rareté | Bonus | Source |
|---|---|---|---|---|
| Anneau d'étain (`anneau_d_etain`) | 8 | commun | Vit 8–11, Sag 4–5 | recette |
| Anneau aux huit yeux (`anneau_aux_huit_yeux`) | 12 | rare | Cha 4–5, Agi 2–3, PO 1 | boss:mere_toile |
| Chevalière du Délégué (`chevaliere_du_delegue`) | 12 | rare | For 4–6, Pro 18–25, Dom 1, Sag 3–4 | boss:krasbouk |
| Anneau de nez de troll (`anneau_de_nez_de_troll`) | 17 | peu commun | For 8–11, Vit 10–14, Sag 3–5 | butin:troll_des_ponts |
| Anneau de granit (`anneau_de_granit`) | 22 | peu commun | Vit 20–28, For 5–7, Cha 5–7 | butin:gargouille |
| Bague de minuit (`bague_de_minuit`) | 27 | rare | Int 11–16, Dom 1–2, Vit 17–25, Crit 1–2 | butin:cendrillon |
| Anneau du Gond (`anneau_du_gond`) | 30 | épique | For 12–17, Int 12–17, Vit 16–22, Dom 2–3 | boss:grondin |

### 8.6 Ceintures (5)

| Objet | Niv. | Rareté | Bonus | Source |
|---|---|---|---|---|
| Ceinture de bûcheron (`ceinture_de_bucheron`) | 9 | commun | For 4–6, Vit 8–12 | butin:bucheron_de_brumerive |
| Ceinture à gnôle (`ceinture_a_gnole`) | 11 | peu commun | Vit 11–16, For 6–8 | butin:gobelin_briseur |
| Ceinture de troll (`ceinture_de_troll`) | 16 | peu commun | Vit 18–26, For 6–9 | butin:troll_des_ponts |
| Ceinture d'écorce calcinée (`ceinture_d_ecorce_calcinee`) | 21 | rare | Vit 23–33, For 6–8, Int 6–8 | butin:arbre_calcine |
| Ceinture d'obsidienne (`ceinture_d_obsidienne`) | 27 | rare | Vit 29–41, Int 7–10, Cha 7–10 | recette |

### 8.7 Bottes (8)

| Objet | Niv. | Rareté | Bonus | Source |
|---|---|---|---|---|
| Bottes de mousse (`bottes_de_mousse`) | 2 | commun | Cha 2–3, Vit 4–5 | butin:morille_grincheuse |
| Bottes de rapine (`bottes_de_rapine`) | 9 | peu commun | Agi 4–6, Ini 29–42, Pro 12–17 | butin:gobelin_pillard |
| Bottes de milicien (`bottes_de_milicien`) | 10 | peu commun | Vit 11–15, For 3–5, Ini 21–30 | butin:milicien_de_hautepierre |
| Bottes de grand chemin (`bottes_de_grand_chemin`) | 14 | peu commun | Agi 5–8, Vit 8–12, Ini 41–59 | butin:detrousseur |
| Bottes de braise (`bottes_de_braise`) | 18 | rare | Int 8–12, For 6–9, Ini 60–87 | butin:grouilleur_de_braise |
| Bottes de gargouille (`bottes_de_gargouille`) | 23 | rare | Vit 20–29, For 7–11, Cha 7–11 | butin:gargouille |
| Pantoufles de cendre (`pantoufles_de_cendre`) | 25 | rare | Int 11–15, Agi 8–12, Ini 80–115 | butin:cendrillon |
| Semelles d'olifant (`semelles_d_olifant`) | 29 | rare | Vit 30–44, For 9–13, Ini 61–87 | butin:olifant_de_guerre |

### 8.8 Ressources (39)

| Ressource | Rareté | Source |
|---|---|---|
| Aile de vampipistrelle (`aile_de_vampipistrelle`) | commun | butin:vampipistrelle |
| Bois d'if (`bois_d_if`) | peu commun | recolte:bucheron (Y) |
| Bois de hêtre (`bois_de_hetre`) | peu commun | recolte:bucheron (H) |
| Bois de malorme (`bois_de_malorme`) | rare | recolte:bucheron (L) |
| Bon de coupe (`bon_de_coupe`) | peu commun | butin:bucheron_de_brumerive |
| Bourse vide (`bourse_vide`) | commun | butin:detrousseur |
| Carte au trésor douteuse (`carte_au_tresor_douteuse`) | peu commun | butin:detrousseur |
| Cendre tiède (`cendre_tiede`) | commun | butin:cendrillon|variantes corrompues |
| Chapeau de morille (`chapeau_de_morille`) | commun | butin:morille_grincheuse |
| Citrouille grimaçante (`citrouille_grimacante`) | peu commun | butin:epouvantail_demotive |
| Cœur de pierre (`coeur_de_pierre`) | peu commun | butin:gargouille |
| Copeaux de bois (`copeaux_de_bois`) | commun | butin:bucheron_de_brumerive |
| Corne du Balourd (`corne_du_balourd`) | rare | boss:balourd_des_abimes |
| Crochet d'araignée (`crochet_d_araignee`) | peu commun | butin:tisseuse_de_brume |
| Cuir d'olifant (`cuir_d_olifant`) | commun | butin:olifant_de_guerre |
| Dent de troll (`dent_de_troll`) | commun | butin:troll_des_ponts |
| Éclat de cendre (`eclat_de_cendre`) | rare | butin:variantes corrompues|boss:grondin |
| Éclat de gargouille (`eclat_de_gargouille`) | commun | butin:gargouille |
| Écusson de milice (`ecusson_de_milice`) | peu commun | butin:milicien_de_hautepierre |
| Fil de brume (`fil_de_brume`) | commun | butin:tisseuse_de_brume |
| Gnôle de raid (`gnole_de_raid`) | commun | butin:gobelin_briseur |
| Guano luisant (`guano_luisant`) | peu commun | butin:vampipistrelle |
| Invitation au bal (`invitation_au_bal`) | peu commun | butin:cendrillon |
| Ivoire d'olifant (`ivoire_d_olifant`) | peu commun | butin:olifant_de_guerre |
| Maillon de cotte (`maillon_de_cotte`) | commun | butin:milicien_de_hautepierre |
| Médaille en chocolat (`medaille_en_chocolat`) | peu commun | butin:gobelin_briseur |
| Message intercepté (`message_intercepte`) | peu commun | butin:corbac_espion |
| Minerai d'argent (`minerai_d_argent`) | peu commun | recolte:mineur (G) |
| Minerai d'étain (`minerai_d_etain`) | commun | recolte:mineur (T) |
| Obsidienne (`obsidienne`) | rare | recolte:mineur (D) |
| Ordre de raid (`ordre_de_raid`) | peu commun | butin:gobelin_pillard|boss:krasbouk |
| Paille ensorcelée (`paille_ensorcelee`) | commun | butin:epouvantail_demotive |
| Plume de corbac (`plume_de_corbac`) | commun | butin:corbac_espion |
| Recette de troll (`recette_de_troll`) | peu commun | butin:troll_des_ponts |
| Registre des heures (`registre_des_heures`) | peu commun | butin:contremaitre_zele |
| Sac de rapine (`sac_de_rapine`) | commun | butin:gobelin_pillard |
| Sifflet de contremaître (`sifflet_de_contremaitre`) | commun | butin:contremaitre_zele |
| Soie de la Mère-Toile (`soie_de_la_mere_toile`) | rare | boss:mere_toile |
| Spores grincheuses (`spores_grincheuses`) | peu commun | butin:morille_grincheuse |

## 9. Métiers

Trois nouvelles essences et trois nouveaux minerais, aux niveaux de métier 8, 15 et 22 (XP de métier : 5·n·(n−1) ; ~40 récoltes pour le niveau 8, ~65 de plus pour le 15, ~70 de plus pour le 22). Aucun nouveau dessin : chaque ressource réutilise `arbre_haut`, `arbre_large` ou `minerai` avec ses couleurs (entrées `images` + `ressources` du manifeste).

| Marqueur | Métier | Ressource | Objet | Niveau | Quantité | XP | Repousse (s) | Image | Où |
|---|---|---|---|---|---|---|---|---|---|
| `Y` | bucheron | If | `bois_d_if` | 8 | 1–2 | 12 | 90–150 | `if` (#1e4a2a) | brumerive (7–12), sylvebrume (4–12), hautepierre (13–21) |
| `H` | bucheron | Hêtre | `bois_de_hetre` | 15 | 1–2 | 18 | 90–150 | `hetre` (#8ab84a) | hautepierre (16–24) |
| `L` | bucheron | Malorme | `bois_de_malorme` | 22 | 1–2 | 25 | 120–180 | `malorme` (#e0b830) | hautepierre (19–30) |
| `T` | mineur | Étain | `minerai_d_etain` | 8 | 1–2 | 12 | 90–150 | `minerai_etain` (#d8d8d0) | brumerive (7–12), crasse_roc (4–12), sylvebrume (10–12), hautepierre (13–18) |
| `G` | mineur | Argent | `minerai_d_argent` | 15 | 1–2 | 18 | 90–150 | `minerai_argent` (#f4f8ff) | hautepierre (16–27) |
| `D` | mineur | Obsidienne | `obsidienne` | 22 | 1–2 | 25 | 120–180 | `minerai_obsidienne` (#6a3a8a) | hautepierre (22–30, cartes cendrées) |

Marqueurs choisis hors de la légende (`. @ 1-9 a-z A M R E : # + * $ = F C U I`) : **Y** (if, *yew*), **H** (hêtre), **L** (malorme), **T** (étain, *tin*), **G** (ar**g**ent), **D** (obsi**d**ienne).

### 9.1 Recettes de forgeron (10 existantes + 13 = 23)

| Objet | Niveau | XP | Ingrédients |
|---|---|---|---|
| `anneau_forgeron_hargneux` | 4 | 20 | 3 minerai_de_fer, 3 minerai_de_cuivre, 2 croc_de_loup |
| `amulette_forgeron_hargneux` | 5 | 24 | 4 minerai_de_fer, 2 peau_de_loup, 2 dent_de_rat |
| `coiffe_forgeron_hargneux` | 6 | 28 | 5 minerai_de_fer, 2 bois_de_chene, 3 carapace_de_grouilleur |
| `anneau_d_etain` | 8 | 32 | 5 minerai_d_etain, 2 minerai_de_cuivre |
| `arc_d_if` | 10 | 38 | 6 bois_d_if, 3 fil_de_brume, 2 aile_de_vampipistrelle |
| `baton_gele` | 11 | 40 | 5 bois_d_if, 3 minerai_d_etain, 1 spores_grincheuses |
| `epee_d_argent` | 15 | 55 | 6 minerai_d_argent, 2 bois_de_hetre, 4 maillon_de_cotte |
| `amulette_d_argent` | 16 | 58 | 4 minerai_d_argent, 3 dent_de_troll, 2 bourse_vide |
| `sceptre_de_hautepierre` | 18 | 65 | 5 minerai_d_argent, 3 bois_de_hetre, 2 ecusson_de_milice, 1 ordre_de_raid |
| `heaume_d_argent` | 20 | 72 | 6 minerai_d_argent, 6 maillon_de_cotte, 3 plume_de_corbac |
| `dague_d_obsidienne` | 23 | 82 | 5 obsidienne, 2 bois_de_malorme, 3 crochet_d_araignee, 1 eclat_de_cendre |
| `arc_de_malorme` | 25 | 90 | 6 bois_de_malorme, 1 soie_de_la_mere_toile, 4 plume_de_corbac |
| `ceinture_d_obsidienne` | 27 | 98 | 6 obsidienne, 3 cuir_d_olifant, 1 corne_du_balourd |

Les recettes utilisent les ressources de monstres de toutes les zones (crocs, carapaces, fils, maillons, plumes, ordres de raid…) et des trophées de mini-boss (Soie de la Mère-Toile, Corne du Balourd) : fabriquer haut niveau pousse à voyager entre les zones.

### 9.2 Panoplies : comment les obtenir sans marchand

Les 8 panoplies restent en vente chez les marchands (jets fixes de niveau 3). En plus, chacune s'obtient **sans marchand** : chaque panoplie élémentaire est partagée entre **deux familles de deux zones différentes** (3 pièces chacune), et le Forgeron Hargneux se fabrique à moitié. Chaque race trouve ainsi 3 à 4 panoplies chez elle et doit voyager (Pierres de Passage) pour compléter les autres. Les élites lâchent ces pièces 3 fois plus souvent.

- **Forgeron Hargneux (Acier)** (`forgeron_hargneux`) : Recettes de forgeron : anneau (niv. 4), amulette (5), coiffe (6). Butin du Milicien de Hautepierre (Crasse-Roc 7–9) : cape, ceinture, bottes (3 %, 9–13 % sur le Sergent).
- **Pyromane Repenti (Flamme)** (`pyromane_repenti`) : Épouvantail démotivé (Brumerive 7–9 : il garde ces pièces « pour se rassurer ») : coiffe, cape, amulette ; Contremaître zélé (Crasse-Roc 10–12) : anneau, ceinture, bottes (3 % chacune).
- **Bonhomme de Neige (Givre)** (`bonhomme_de_neige`) : Tisseuse de brume (Sylvebrume 10–12) : coiffe, cape, amulette ; Vampipistrelle (Crasse-Roc 4–6) : anneau, ceinture, bottes (3 %).
- **Courant d'Air (Tempête)** (`courant_d_air`) : Cerf enchanté (Sylvebrume 4–6) : coiffe, cape, amulette (3 %) ; Gobelin frondeur (Brumerive 4–6) : anneau, ceinture, bottes (2 %).
- **Enfant de Chœur (Sacré)** (`enfant_de_choeur`) : Gobelin pillard (Brumerive 7–9, volées à la chapelle) : coiffe, cape, amulette ; Bûcheron de Brumerive (Sylvebrume 7–9, il chante à la chorale le dimanche) : anneau, ceinture, bottes (3 %).
- **Mauvais Œil (Impie)** (`mauvais_oeil`) : Morille grincheuse (Sylvebrume 1–3) : coiffe, cape, amulette ; Loup des collines (Brumerive 1–3) : anneau, ceinture, bottes (2 %).
- **Pressé (Initiative, 3 pièces)** (`presse`) : Grouilleur (Crasse-Roc 1–3, beaucoup de pattes, toujours pressé) : anneau, bottes, ceinture (2 %, 6 % sur l'Ancestral).
- **Fouineur (Prospection, 3 pièces)** (`fouineur`) : Rat des galeries (Crasse-Roc 1–3) : coiffe, amulette, cape (2 %, 6 % sur le Rat-roi).

## 10. Récapitulatif d'équilibrage

Référence : un joueur seul contre un groupe de 2 monstres de son niveau. Le combat dure `2 + niveau/10` tours du joueur et lui coûte environ 40 % de ses PV. Formules dans `src/balance.py`.

| Niv. | XP pour passer | PV joueur | Carac. principale | Dégâts joueur / tour | PV monstre | Dégâts / sort monstre | XP monstre | Écus | Combats pour le niveau |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 80 | 58 | 8 | 16.2 | 17 | 6.6 | 7 | 2–4 | 7 |
| 3 | 360 | 74 | 24 | 18.6 | 24 | 7.7 | 23 | 3–8 | 9 |
| 6 | 1080 | 98 | 48 | 24.2 | 34 | 9.0 | 52 | 6–13 | 12 |
| 9 | 2160 | 122 | 72 | 27.8 | 46 | 10.0 | 85 | 8–18 | 14 |
| 12 | 3600 | 146 | 96 | 33.4 | 59 | 10.9 | 123 | 10–23 | 16 |
| 15 | 5400 | 170 | 120 | 39.0 | 72 | 11.6 | 166 | 12–28 | 18 |
| 18 | 7560 | 194 | 144 | 42.6 | 87 | 12.2 | 213 | 14–33 | 20 |
| 21 | 10080 | 218 | 168 | 48.2 | 103 | 12.7 | 266 | 16–38 | 21 |
| 24 | 12960 | 242 | 192 | 51.8 | 121 | 13.1 | 324 | 18–43 | 22 |
| 27 | 16200 | 266 | 216 | 57.4 | 139 | 13.5 | 386 | 21–48 | 23 |
| 30 | — | 290 | 240 | 63.0 | 158 | 13.8 | 453 | 23–53 | — |

- **Durée visée** : 14.0 h de combat du niveau 1 au niveau 30, dont 2.7 h dans la zone de départ (1 → 12, ~129 combats) et ~366 combats dans Hautepierre (12 → 30).
- **Alpha 1** : l'XP de combat est multipliée par 3.5 (`Character.XP_RATE`) ; tout le contenu (1 → 30) se fait alors en ~4.0 h de combat, ~4 à 5 h avec les déplacements. On revient à ×1 (~15 h pour les 30 premiers niveaux) quand on testera la vraie progression.
- **Élites** : niveau = max de la famille + 3, PV ≥ 2× la base, XP × 1,8, écus × 2,5, butin plus fréquent ; **mini-boss** : groupe fixe, réapparition en 60 s au plus (alpha : on doit pouvoir retester ses mécaniques), 2 ou 3 phases de profils différents tirés de son thème (agressif, défensif, mobilité, contrôle), **jamais de soin** à un changement de phase (risque de combat sans fin), trophée de recette.
- **Variantes corrompues** : +10 % d'XP, éléments Flamme, apparaissent après le mini-boss de leur zone (voir §7).
- **À valider en jeu** : la durée réelle des combats (le modèle suppose 70 % de coups portés) et la vitesse de progression de chaque race, puisque les paliers sont asymétriques entre zones.

## 11. Dessins à faire

- **14 nouveaux dessins** de monstres, armes ou accessoires (liste ci-dessous) ; les 35 autres monstres réutilisent un rig ou une image existante (recoloration, échelle, accessoires) décrits dans leur fiche.
- **94 icônes d'objets** (une par nouvel objet, description dans le JSON).
- **Ressources de récolte** : aucun nouveau dessin, recoloration de `arbre_haut`, `arbre_large` et `minerai` (§9).
- **Décors des cartes** : réutilisation des décors existants, recolorés par la palette de zone ; les éléments propres à une carte sont décrits dans son « Plan ».

| Zone | Pour | Dessin |
|---|---|---|
| brumerive | Épouvantail démotivé | arme « fourche » (petite, 2 dents de fer rouillé sur manche clair, même attache que le bâton) |
| brumerive | Gobelin briseur | arme « hache » (partagée avec le bûcheron de Sylvebrume) |
| crasse_roc | Vampipistrelle | monstre/vampipistrelle.svgt, ~44×34 px : chauve-souris en vol stationnaire vue de 3/4, corps rond brun-violet ({{pelage}}), grandes ailes membraneuses violet sombre déployées en V, grandes oreilles pointues, deux petits crocs blancs, yeux rouges ; ombre au sol décollée (ellipse à ~8 px sous les pieds, l'ancre au centre de l'ombre). |
| crasse_roc | Milicien de Hautepierre | accessoire « casque » (casque rond de fer à nasal, 2 vues ; partagé avec plusieurs familles) |
| crasse_roc | Le Balourd des Abîmes | monstre/balourd.svgt, ~96×104 px : démon massif de roche noire fissurée de lave orange, deux cornes recourbées, ailes de fumée grise en lambeaux, épée de braise dans la main droite et fouet de flamme dans la gauche ; yeux jaunes ; ancre aux pieds (≈ [48, 100]). Le plus grand monstre des zones de départ. |
| sylvebrume | Morille grincheuse | monstre/morille.svgt, ~34×42 px : morille debout, chapeau conique alvéolé brun-beige ({{pelage}}/{{pelage_ombre}}), pied blanc trapu servant de corps, deux petits bras, sourcils froncés et bouche boudeuse, petites jambes ; ancre aux pieds. |
| sylvebrume | Bûcheron de Brumerive | arme « hache » (fer large, manche clair ; partagée avec le briseur) |
| sylvebrume | Tisseuse de brume | monstre/araignee.svgt, ~60×38 px : araignée vue de 3/4, abdomen gris perle ({{pelage}}) à motif de toile bleu pâle, céphalothorax plus sombre ({{pelage_ombre}}), 8 pattes fines articulées, 6 petits yeux noirs brillants, crochets ; ancre au centre entre les pattes. Recolorable pour la Mère-Toile. |
| hautepierre | Détrousseur des grands chemins | accessoire « capuche » (capuche de tissu rabattue sur la tête, 2 vues, couleur {{chapeau}}) |
| hautepierre | Troll des ponts | têtes « tete_troll » et « tete_troll_dos » (grosse tête ronde au nez énorme, petites oreilles pointues, deux crocs du bas, front bas ; peau {{peau}}) pour le nouvel assemblage « troll » (base humain, échelle 1.15) ; arme « massue » (gourdin noueux avec un clou) |
| hautepierre | Corbac espion | monstre/corbac.svgt, ~44×42 px : gros corbeau noir aux reflets bleus ({{pelage}}/{{pelage_ombre}}), ailes à demi déployées, bec épais gris, œil rouge, petite longue-vue en laiton en bandoulière ; perché au sol, ancre entre les pattes. |
| hautepierre | Gargouille | monstre/gargouille.svgt, ~54×60 px : gargouille de pierre grise ({{pierre}}) accroupie, petites ailes de chauve-souris repliées, cornes courtes, gueule grande ouverte en gouttière, griffes ; taches de mousse ; ancre aux pieds. |
| hautepierre | Olifant de guerre | monstre/olifant.svgt, ~86×70 px : éléphant de guerre gris ({{pelage}}/{{pelage_ombre}}) vu de 3/4, quatre défenses, grandes oreilles, caparaçon rouge à bordure dorée sur le dos, petite tête de mort cendrée brodée ; ancre entre les pattes. |
| hautepierre | Grondin, Bélier de la Brèche | monstre/grondin.svgt, ~112×76 px : bélier de siège sur 4 roues, poutre de bois noir cerclée de fer, tête de loup en fer forgé à l'avant aux yeux rouge braise, chaînes pendantes, toit de planches roussies ; ancre au centre bas (≈ [56, 72]). Pas d'équipage : il avance seul. |

## 12. Lots de production

Chaque lot ne touche que ses propres fichiers : `game/data/<type>/<id>.json` pour ses ids, son fragment d'images `game/art/manifestes/<lot>.json`, ses dessins et ses icônes. Les lots de zone peuvent donc avancer en parallèle ; variantes et métiers viennent après, car ils réutilisent les butins des zones.

| Lot | Cartes nouvelles | Monstres | Sorts nouveaux | Objets | Dessins nouveaux | Dépend de |
|---|---|---|---|---|---|---|
| brumerive | 8 | 11 | 14 | 13 | 2 | — |
| crasse_roc | 8 | 11 | 14 | 13 | 3 | — |
| sylvebrume | 7 | 11 | 11 | 13 | 3 | — |
| hautepierre | 19 | 13 | 23 | 35 | 6 | — |
| variantes | 0 | 3 | 3 | 4 | 0 | lots de zone |
| metiers | 0 | 0 | 0 | 16 | 0 | lots de zone + variantes |

Ordre proposé :
1. **Lots de zone** Brumerive, Crasse-Roc, Sylvebrume, puis Hautepierre (le plus gros : on peut le couper en deux, cartes et ville d'un côté, monstres et boss de l'autre).
2. **Variantes et métiers** (ressources, nœuds de récolte, recettes, sources des panoplies).
3. **Intégration** : tests de chargement des données, combat simulé par palier pour vérifier le modèle d'équilibrage, captures d'écran, GDD, TODO et guide des testeurs.

Les 18 sorts existants réutilisés ne sont pas modifiés.
