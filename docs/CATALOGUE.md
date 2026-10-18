# Catalogue des objets et des sorts

Généré par `game/tools/catalogue.py` à partir de `game/data/` : ne pas modifier à la main,
relancer `python3 game/tools/catalogue.py` après un changement de contenu.

Lecture : les plages (8–12) sont des jets aléatoires ; « t. » = tours. Les sorts gagnent en
puissance avec la caractéristique de leur élément (Acier : Force, Flamme : Intelligence,
Givre : Chance, Tempête : Agilité, Sacré : Force et Intelligence, Impie : Agilité et Chance).
Prix de boutique : selon la rareté (revente à 25 %).

## Sommaire

- [Armes](#armes)
- [Coiffes](#coiffes)
- [Capes](#capes)
- [Amulettes](#amulettes)
- [Anneaux](#anneaux)
- [Ceintures](#ceintures)
- [Bottes](#bottes)
- [Ressources](#ressources)
- [Objets de quête](#objets-de-quête)
- [Panoplies](#panoplies)
- [Sorts des Voies](#sorts-des-voies)
- [Sorts de race](#sorts-de-race)
- [Sorts des monstres](#sorts-des-monstres)

**205 objets** (31 armes, 16 coiffes, 16 capes, 18 amulettes, 20 anneaux, 15 ceintures, 17 bottes, 66 ressources, 6 objets de quête) et **105 sorts**.

## Armes

| Nom | Niv. | Rareté | Bonus | Conditions | Attaque | Obtention | Description |
|---|---|---|---|---|---|---|---|
| **Arc de frêne** | 1 | Commun | Agilité 2–5 | — | 4 PA, portée 2–5, 1/tour : 5–8 Tempête | boutique 40 écus<br>Forgeron niv. 1 (6 Bois de frêne, 1 Peau de loup)<br>équipement de départ : Rôdeur | Taillé dans une branche de frêne par quelqu'un qui avait vu un arc une fois. |
| **Bâton de novice** | 1 | Commun | Intelligence 2–5 | — | 3 PA, portée 1–2, 1/tour : 4–7 Flamme | boutique 40 écus<br>Forgeron niv. 1 (5 Bois de frêne, 1 Minerai de cuivre)<br>équipement de départ : Arcaniste | Un bâton. Les apprentis jurent qu'il est magique. Il est surtout en bois. |
| **Sceptre de novice** | 1 | Commun | Intelligence 1–3, Force 1–3 | — | 3 PA, portée 1, 2/tour : 4–7 Sacré | boutique 40 écus<br>équipement de départ : Théologue | Un bâton avec un soleil en laiton au bout. Le laiton a la foi, le bâton un peu moins. |
| **Épée de fer** | 1 | Commun | Force 2–5 | — | 4 PA, portée 1, 1/tour : 7–11 Acier | boutique 40 écus<br>Forgeron niv. 2 (4 Minerai de fer, 2 Bois de frêne)<br>équipement de départ : Guerrier | Une épée honnête. Ni légendaire, ni maudite, juste en fer. |
| **Fronde réglementaire** | 3 | Rare | Agilité 4–8, Chance 2–5, Prospection 5–10 | — | 3 PA, portée 2–6, 2/tour : 4–7 Tempête | boutique 350 écus<br>butin : Frondeur vétéran 12 %, Gobelin frondeur 3 % | Modèle officiel de l'armée du Souverain Cendré. Fournie sans cailloux. |
| **Dague du Mauvais Œil** | 4 | Peu commun | Agilité 2–5, Chance 2–5 | — | 3 PA, portée 1, 2/tour : 5–8 Impie | boutique 120 écus | L'œil sur la garde vous regarde. Il vous juge. Il a raison. |
| **Masse bénite** | 4 | Peu commun | Force 2–5, Intelligence 2–5 | — | 4 PA, portée 1, 1/tour : 9–13 Sacré | boutique 120 écus | Bénie trois fois par un prêtre de Hautepierre. Il a béni le manche, la tête et, par erreur, son pouce. |
| **Masse cerclée** | 4 | Peu commun | Force 4–8, Vitalité 5–10 | Force ≥ 10 | 4 PA, portée 1, 1/tour : 10–15 Acier | boutique 120 écus<br>Forgeron niv. 5 (4 Bois de chêne, 5 Minerai de fer) | Du chêne, du fer, et l'intention bien arrêtée de cabosser quelque chose. |
| **Arc du Cœur de frêne** | 7 | Rare | Agilité 6–9, Initiative 15–22 | — | 4 PA, portée 2–6, 1/tour : 9–13 Tempête | Forgeron niv. 7 (1 Cœur de frêne, 8 Bois de frêne, 2 Peau de loup) | Taillé dans le cœur d'un frêne têtu : il plie, mais c'est lui qui décide quand. |
| **Fourche d'épouvantail** | 8 | Commun | Force 3–4, Vitalité 4–5 | — | 4 PA, portée 1–2, 1/tour : 9–14 Acier | boutique 40 écus<br>butin : Grand Épouvantail 13 %, Épouvantail démotivé 3 % | Trois dents, dont deux tordues. Vise toujours à côté, mais de peu. |
| **Épée de milicien** | 8 | Commun | Force 3–4, Vitalité 4–5 | — | 4 PA, portée 1, 1/tour : 9–14 Acier | boutique 40 écus<br>butin : Sergent de la milice 16 %, Milicien de Hautepierre 4 % | Modèle réglementaire de Hautepierre. Gravée « Propriété de la milice — ne pas perdre ». Perdue. |
| **Coutelas de pillard** | 9 | Peu commun | Agilité 3–4, Chance 3–4 | — | 3 PA, portée 1, 2/tour : 8–11 Impie | boutique 120 écus<br>butin : Pillard émérite 16 %, Gobelin pillard 4 % | Une lame courte, pratique pour couper les cordes à linge et les conversations. |
| **Hache de bûcheron** | 9 | Peu commun | Force 4–5, Vitalité 5–7 | — | 4 PA, portée 1, 1/tour : 10–15 Acier | boutique 120 écus<br>butin : Abatteur en chef 16 %, Bûcheron de Brumerive 4 % | Une cognée honnête. Elle a abattu Vieux-Branchu ; elle n'en est pas fière. |
| **Arc d'if** | 10 | Peu commun | Agilité 4–6, Initiative 19–27 | — | 4 PA, portée 2–6, 1/tour : 10–16 Tempête | boutique 120 écus<br>Forgeron niv. 10 (6 Bois d'if, 3 Fil de brume, 2 Aile de vampipistrelle) | Un vrai arc, cette fois. Taillé par quelqu'un qui en avait vu plus d'un. |
| **Bâton gelé** | 11 | Peu commun | Chance 5–7, Sagesse 2–3 | — | 3 PA, portée 1–4, 2/tour : 8–12 Givre | boutique 120 écus<br>Forgeron niv. 11 (5 Bois d'if, 3 Minerai d'étain, 1 Spores grincheuses) | Un bâton d'if cerclé d'étain, couvert de givre en permanence. Ne pas lécher. |
| **Fouet du Balourd** | 12 | Épique | Intelligence 5–8, Vitalité 7–9, Dommages 1 | — | 4 PA, portée 1–3, 1/tour : 13–19 Flamme | butin : Le Balourd des Abîmes 12 % | Une lanière de feu qui ne s'éteint pas. Ne pas ranger dans le sac à côté des parchemins. |
| **Fuseau de la Mère-Toile** | 12 | Épique | Chance 5–8, Vitalité 7–9, Dommages 1 | — | 4 PA, portée 2–5, 1/tour : 13–19 Givre | butin : La Mère-Toile 12 % | Elle tissait avec ; vous frappez avec. Le fil gèle tout ce qu'il touche. |
| **Hachoir de Krasbouk** | 12 | Épique | Force 5–8, Vitalité 7–9, Dommages 1 | — | 4 PA, portée 1, 2/tour : 13–19 Acier | butin : Krasbouk, Chef de Raid (syndiqué) 12 % | Inscrit à l'inventaire du raid sous « outil de négociation ». |
| **Masse météorique** | 12 | Rare | Force 8–12, Vitalité 8–12, Dommages 1 | — | 4 PA, portée 1, 1/tour : 14–20 Acier | Forgeron niv. 12 (1 Fer météorique, 1 Chêne des Anciens, 8 Minerai de fer) | Une tête de fer tombée du ciel sur un manche de chêne des Anciens. Elle retombe souvent. |
| **Dague de détrousseur** | 14 | Peu commun | Agilité 6–8, Initiative 24–35 | — | 3 PA, portée 1–3, 2/tour : 9–13 Tempête | boutique 120 écus<br>butin : Chef de bande 13 %, Détrousseur des grands chemins 3 % | Équilibrée pour le lancer, et pour le retour : elle a une ficelle. |
| **Épée d'argent** | 15 | Rare | Force 6–9, Vitalité 4–6, Sagesse 2–3 | — | 4 PA, portée 1, 1/tour : 13–19 Acier | boutique 350 écus<br>Forgeron niv. 15 (6 Minerai d'argent, 2 Bois de hêtre, 4 Maillon de cotte) | Brillante et tranchante. Les Corrompus détestent son reflet. |
| **Massue de troll** | 17 | Rare | Force 7–10, Vitalité 9–13 | Force ≥ 40 | 5 PA, portée 1, 1/tour : 17–25 Acier ; poussée de 1 case(s) | boutique 350 écus<br>butin : Troll gastronome 13 %, Troll des ponts 3 % | Un tronc d'arbre avec un clou. Le clou, c'est pour l'élégance. |
| **Sceptre de Hautepierre** | 18 | Rare | Force 4–5, Intelligence 4–5, Sagesse 2–3, Vitalité 5–7 | — | 4 PA, portée 1–2, 1/tour : 14–20 Sacré | boutique 350 écus<br>Forgeron niv. 18 (5 Minerai d'argent, 3 Bois de hêtre, 2 Écusson de milice, 1 Ordre de raid) | Surmonté d'une petite Tour Blanche en argent. Béni par Frère Bénitier, pouce compris. |
| **Lame cendrée** | 20 | Légendaire | Force 20–30, Intelligence 10–15, PA 1 | Force ≥ 60 | 4 PA, portée 1, 2/tour : 20–28 Flamme | boutique 2500 écus<br>butin : Le Souverain Cendré 5 % | L'épée du Souverain Cendré. Elle est encore chaude, et elle le restera. |
| **Épée lunaire** | 20 | Épique | Force 9–13, Vitalité 6–9, % Critique 2–3 | — | 4 PA, portée 1, 1/tour : 17–24 Acier | Forgeron niv. 20 (1 Argent lunaire, 1 Hêtre centenaire, 6 Minerai d'argent) | Une lame d'argent lunaire sur une garde de hêtre centenaire. Elle éclaire le chemin, et la cible. |
| **Hallebarde de la Vieille Garde** | 22 | Rare | Force 7–10, Vitalité 9–12, Sagesse 3–4 | — | 4 PA, portée 1–2, 1/tour : 15–22 Acier | boutique 350 écus<br>butin : Gargouille de la Grande Porte 13 %, Gargouille 3 % | Arme des gardes d'il y a trois siècles. Les gargouilles l'ont gardée, par habitude. |
| **Dague d'obsidienne** | 23 | Rare | Agilité 6–9, Chance 6–9, % Critique 1–2 | — | 3 PA, portée 1, 2/tour : 11–17 Impie | boutique 350 écus<br>Forgeron niv. 23 (5 Obsidienne, 2 Bois de malorme, 3 Crochet d'araignée, 1 Éclat de cendre) | Noire, tranchante, fragile. Comme le caractère de celui qui l'a forgée. |
| **Arc de malorme** | 25 | Rare | Agilité 10–14, Initiative 32–46, Sagesse 3–5 | — | 4 PA, portée 2–7, 1/tour : 16–23 Tempête | boutique 350 écus<br>Forgeron niv. 25 (6 Bois de malorme, 1 Soie de la Mère-Toile, 4 Plume de corbac) | Doré, léger, parfait. Les elfes prétendent qu'il est mal fait, par principe. |
| **Baguette de Cendrillon** | 26 | Rare | Intelligence 10–14, Sagesse 3–5, Vitalité 7–10 | — | 4 PA, portée 2–6, 1/tour : 16–24 Flamme | boutique 350 écus<br>butin : Marraine Cendrée 13 %, Cendrillon 3 % | Pas magique. Enfin, pas comme on l'espérait. |
| **Sceptre de malorme** | 26 | Épique | Intelligence 12–16, Sagesse 5–7, Dommages 1–2 | — | 4 PA, portée 1–3, 1/tour : 16–23 Flamme | Forgeron niv. 26 (1 Malorme ensorcelée, 1 Obsidienne sanglante, 6 Bois de malorme, 4 Obsidienne) | Malorme ensorcelée et obsidienne sanglante : il murmure des sorts que personne ne lui a appris. |
| **Marteau de Grondin** | 30 | Légendaire | Force 13–18, Vitalité 14–20, Dommages 2–3, PA 1 | Force ≥ 80 | 5 PA, portée 1, 1/tour : 25–37 Acier ; poussée de 1 case(s) | butin : Grondin, Bélier de la Brèche 6 % | Le dernier morceau du bélier. Il frappe toujours trois coups, même quand on n'en demande qu'un. |

## Coiffes

| Nom | Niv. | Rareté | Bonus | Conditions | Obtention | Description |
|---|---|---|---|---|---|---|
| **Bonnet de berger** | 1 | Commun | Vitalité 3–8, Sagesse 1–3 | — | boutique 40 écus<br>butin : Loup alpha 15 %, Loup des collines 5 % | Il tient chaud et sent un peu le mouton. |
| **Coiffe de l'Enfant de Chœur** *(Panoplie de l'Enfant de Chœur)* | 3 | Commun | Force 2–4, Intelligence 2–4, Vitalité 5–10 | — | boutique 40 écus<br>butin : Pillard émérite 13 %, Gobelin pillard 3 % | Immaculé, béni, repassé. On se demande comment il reste aussi propre en combat. |
| **Coiffe du Bonhomme de Neige** *(Panoplie du Bonhomme de Neige)* | 3 | Commun | Chance 5–8, Vitalité 5–10 | — | boutique 40 écus<br>butin : Grande Tisseuse 13 %, Tisseuse de brume 3 % | Frais toute l'année. Ne pas porter près d'un feu de camp, ni d'un pyromane, même repenti. |
| **Coiffe du Courant d'Air** *(Panoplie du Courant d'Air)* | 3 | Commun | Agilité 5–8, Vitalité 5–10 | — | boutique 40 écus<br>butin : Grand cerf de la Lisière 8 %, Cerf enchanté 3 % | On ne le voit pas arriver. On le sent passer, surtout dans le dos. |
| **Coiffe du Forgeron Hargneux** *(Panoplie du Forgeron Hargneux)* | 3 | Commun | Force 5–8, Vitalité 5–10 | — | boutique 40 écus<br>Forgeron niv. 6 (5 Minerai de fer, 2 Bois de chêne, 3 Carapace de grouilleur) | Coulé dans la même fonte que l'enclume du forgeron. Et dans la même humeur. |
| **Coiffe du Fouineur** *(Panoplie du Fouineur)* | 3 | Commun | Prospection 10–20, Chance 2–4 | — | boutique 40 écus<br>butin : Rat-roi 6 %, Rat des galeries 2 % | Il trouve toujours quelque chose. Parfois même ce qu'il cherchait. |
| **Coiffe du Mauvais Œil** *(Panoplie du Mauvais Œil)* | 3 | Commun | Agilité 2–4, Chance 2–4, Vitalité 5–10 | — | boutique 40 écus<br>butin : Vieille Morille rancunière 12 %, Morille grincheuse 2 % | Porte malheur à tout le monde, sauf à son propriétaire. Pour l'instant. |
| **Coiffe du Pyromane Repenti** *(Panoplie du Pyromane Repenti)* | 3 | Commun | Intelligence 5–8, Vitalité 5–10 | — | boutique 40 écus<br>butin : Grand Épouvantail 13 %, Épouvantail démotivé 3 % | Il a juré de ne plus rien brûler. Ses vêtements, eux, n'ont rien juré. |
| **Casque cabossé** | 4 | Peu commun | Vitalité 6–12, Force 2–5 | Force ≥ 5 | boutique 120 écus<br>butin : Sergent de la milice 16 %, Milicien de Hautepierre 4 %<br>Forgeron niv. 4 (6 Minerai de fer, 1 Peau de loup)<br>récompense de « Inspection surprise » | A appartenu à un garde de Hautepierre. Les bosses aussi. |
| **Couronne de ramure** | 4 | Rare | Sagesse 4–8, Intelligence 3–6 | — | boutique 350 écus<br>butin : Grand cerf de la Lisière 18 %, Cerf enchanté 4 %<br>récompense de « Coupe rase » | Tressée dans les bois d'un cerf enchanté. Les elfes trouvent ça déplacé. |
| **Chapeau d'épouvantail** | 7 | Peu commun | Agilité 4–6, Vitalité 5–7, Sagesse 2 | — | boutique 120 écus<br>butin : Grand Épouvantail 20 %, Épouvantail démotivé 5 %<br>récompense de « La grève des épouvantails » | Il ne fait plus peur aux corbeaux. Aux aventuriers non plus, mais il tient chaud. |
| **Capuche de détrousseur** | 13 | Peu commun | Agilité 5–7, Chance 4–6, Prospection 15–22 | — | boutique 120 écus<br>butin : Chef de bande 16 %, Détrousseur des grands chemins 4 % | On ne voit pas votre visage. On voit très bien vos intentions. |
| **Chapeau à plume de corbac** | 19 | Peu commun | Agilité 9–13, Prospection 17–25, Initiative 44–63 | — | boutique 120 écus<br>butin : Corbac chef espion 16 %, Corbac espion 4 % | La plume tourne la tête quand quelqu'un parle de vous. |
| **Heaume d'argent** | 20 | Rare | Vitalité 22–32, Force 7–10, Sagesse 4–6 | — | boutique 350 écus<br>Forgeron niv. 20 (6 Minerai d'argent, 6 Maillon de cotte, 3 Plume de corbac)<br>récompense de « Messages interceptés » | Le casque des officiers de Hautepierre. Les miliciens le saluent par réflexe. |
| **Masque de Cendrillon** | 26 | Rare | Intelligence 14–20, Vitalité 17–24, Sagesse 6–8 | — | boutique 350 écus<br>butin : Marraine Cendrée 16 %, Cendrillon 4 % | Un loup de bal noir. Personne ne vous reconnaît, surtout pas vous. |
| **Heaume du Bélier** | 30 | Épique | Force 16–22, Vitalité 31–45, Dommages 2–3 | — | butin : Grondin, Bélier de la Brèche 15 % | Taillé dans la tête de Grondin. Les portes s'ouvrent devant vous. Souvent en morceaux. |

## Capes

| Nom | Niv. | Rareté | Bonus | Conditions | Obtention | Description |
|---|---|---|---|---|---|---|
| **Cape de l'Enfant de Chœur** *(Panoplie de l'Enfant de Chœur)* | 3 | Commun | Force 2–4, Intelligence 2–4, Sagesse 2–4 | — | boutique 40 écus<br>butin : Pillard émérite 13 %, Gobelin pillard 3 % | Immaculé, béni, repassé. On se demande comment il reste aussi propre en combat. |
| **Cape du Bonhomme de Neige** *(Panoplie du Bonhomme de Neige)* | 3 | Commun | Chance 4–7, Sagesse 2–4 | — | boutique 40 écus<br>butin : Grande Tisseuse 13 %, Tisseuse de brume 3 % | Frais toute l'année. Ne pas porter près d'un feu de camp, ni d'un pyromane, même repenti. |
| **Cape du Courant d'Air** *(Panoplie du Courant d'Air)* | 3 | Commun | Agilité 4–7, Sagesse 2–4 | — | boutique 40 écus<br>butin : Grand cerf de la Lisière 8 %, Cerf enchanté 3 % | On ne le voit pas arriver. On le sent passer, surtout dans le dos. |
| **Cape du Forgeron Hargneux** *(Panoplie du Forgeron Hargneux)* | 3 | Commun | Force 4–7, Sagesse 2–4 | — | boutique 40 écus<br>butin : Sergent de la milice 13 %, Milicien de Hautepierre 3 % | Coulé dans la même fonte que l'enclume du forgeron. Et dans la même humeur. |
| **Cape du Fouineur** *(Panoplie du Fouineur)* | 3 | Commun | Prospection 10–20, Sagesse 2–4 | — | boutique 40 écus<br>butin : Rat-roi 6 %, Rat des galeries 2 % | Il trouve toujours quelque chose. Parfois même ce qu'il cherchait. |
| **Cape du Mauvais Œil** *(Panoplie du Mauvais Œil)* | 3 | Commun | Agilité 2–4, Chance 2–4, Sagesse 2–4 | — | boutique 40 écus<br>butin : Vieille Morille rancunière 12 %, Morille grincheuse 2 % | Porte malheur à tout le monde, sauf à son propriétaire. Pour l'instant. |
| **Cape du Pyromane Repenti** *(Panoplie du Pyromane Repenti)* | 3 | Commun | Intelligence 4–7, Sagesse 2–4 | — | boutique 40 écus<br>butin : Grand Épouvantail 13 %, Épouvantail démotivé 3 % | Il a juré de ne plus rien brûler. Ses vêtements, eux, n'ont rien juré. |
| **Cape en peau de loup** | 3 | Rare | Agilité 3–6, Vitalité 4–8, Initiative 10–20 | — | boutique 350 écus<br>butin : Loup alpha 15 %, Loup des collines 3 % | Le loup n'en a plus besoin. |
| **Cape d'écorce** | 5 | Rare | Vitalité 15–25, Chance 2–4 | — | boutique 350 écus<br>butin : Arbre millénaire 18 %, Arbre vivant 4 %<br>récompense de « Les arbres sont nerveux » | Elle pousse un peu chaque printemps. Prévoir une taille au-dessus. |
| **Cape de vampipistrelle** | 5 | Peu commun | Agilité 3–4, Chance 2–3, Initiative 20–29 | — | boutique 120 écus<br>butin : Vampipistrelle comtesse 16 %, Vampipistrelle 4 %<br>récompense de « Heures supplémentaires (non payées) » | Cousue d'ailes. On ne vole pas avec, mais on a l'air de pouvoir. |
| **Cape de soie grise** | 11 | Peu commun | Chance 6–8, Sagesse 2–3, Vitalité 7–10 | — | boutique 120 écus<br>butin : Grande Tisseuse 16 %, Tisseuse de brume 4 %<br>récompense de « Du fil de brume » | Tissée par les tisseuses de brume. Elle colle un peu, mais elle protège du froid et des regards. |
| **Cape de fumée** | 12 | Rare | Intelligence 6–8, Agilité 4–6, Vitalité 9–13 | — | butin : Le Balourd des Abîmes 20 % | Taillée dans la fumée du Balourd. Elle sent le roussi, mais elle a de l'allure. |
| **Écharpe du Héros de Brumerive** | 12 | Rare | Vitalité 20–30, Force 5–8, Intelligence 5–8 | — | récompense de « La palissade de Krasbouk » | Brodée « Au héros de Brumerive » par le bourgmestre, qui en a commandé une pour lui aussi. Par précaution. |
| **Cape de loup cendreux** | 15 | Rare | Agilité 7–10, Vitalité 10–15, Initiative 52–75 | — | boutique 350 écus<br>butin : Loup cendreux 4 %<br>récompense de « Le convoi de Brokk » | Elle sent le brûlé et ne sèche jamais vraiment. Le loup non plus, d'ailleurs. |
| **Cape de plumes noires** | 21 | Rare | Agilité 11–17, Vitalité 14–20, Initiative 46–66 | — | boutique 350 écus<br>butin : Corbac chef espion 15 % | Elle bruisse comme une volée de corbeaux. Les vrais corbeaux la trouvent vulgaire. |
| **Cape en cuir d'olifant** | 28 | Rare | Vitalité 29–42, Force 9–13, Sagesse 6–8 | — | boutique 350 écus<br>butin : Olifant-tour 16 %, Olifant de guerre 4 %<br>récompense de « Le Conseil des Peuples Libres » | Lourde, raide, increvable. On a l'air d'une tente, mais d'une tente blindée. |

## Amulettes

| Nom | Niv. | Rareté | Bonus | Conditions | Obtention | Description |
|---|---|---|---|---|---|---|
| **Amulette-croc** | 2 | Peu commun | Force 2–4, Chance 2–4 | — | boutique 120 écus<br>butin : Loup alpha 25 %, Loup des collines 6 %<br>Forgeron niv. 3 (4 Croc de loup, 2 Minerai de cuivre) | Un croc de loup au bout d'une ficelle. Très à la mode chez les bergers. |
| **Amulette de l'Enfant de Chœur** *(Panoplie de l'Enfant de Chœur)* | 3 | Commun | Force 3–5, Intelligence 3–5 | — | boutique 40 écus<br>butin : Pillard émérite 13 %, Gobelin pillard 3 % | Immaculé, béni, repassé. On se demande comment il reste aussi propre en combat. |
| **Amulette du Bonhomme de Neige** *(Panoplie du Bonhomme de Neige)* | 3 | Commun | Chance 6–10 | — | boutique 40 écus<br>butin : Grande Tisseuse 13 %, Tisseuse de brume 3 % | Frais toute l'année. Ne pas porter près d'un feu de camp, ni d'un pyromane, même repenti. |
| **Amulette du Courant d'Air** *(Panoplie du Courant d'Air)* | 3 | Commun | Agilité 6–10 | — | boutique 40 écus<br>butin : Grand cerf de la Lisière 8 %, Cerf enchanté 3 % | On ne le voit pas arriver. On le sent passer, surtout dans le dos. |
| **Amulette du Forgeron Hargneux** *(Panoplie du Forgeron Hargneux)* | 3 | Commun | Force 6–10 | — | boutique 40 écus<br>Forgeron niv. 5 (4 Minerai de fer, 2 Peau de loup, 2 Dent de rat) | Coulé dans la même fonte que l'enclume du forgeron. Et dans la même humeur. |
| **Amulette du Fouineur** *(Panoplie du Fouineur)* | 3 | Commun | Prospection 15–25 | — | boutique 40 écus<br>butin : Rat-roi 6 %, Rat des galeries 2 % | Il trouve toujours quelque chose. Parfois même ce qu'il cherchait. |
| **Amulette du Mauvais Œil** *(Panoplie du Mauvais Œil)* | 3 | Commun | Agilité 3–5, Chance 3–5 | — | boutique 40 écus<br>butin : Vieille Morille rancunière 12 %, Morille grincheuse 2 % | Porte malheur à tout le monde, sauf à son propriétaire. Pour l'instant. |
| **Amulette du Pyromane Repenti** *(Panoplie du Pyromane Repenti)* | 3 | Commun | Intelligence 6–10 | — | boutique 40 écus<br>butin : Grand Épouvantail 13 %, Épouvantail démotivé 3 % | Il a juré de ne plus rien brûler. Ses vêtements, eux, n'ont rien juré. |
| **Amulette-sifflet** | 11 | Peu commun | Initiative 34–49, Agilité 5–7, Sagesse 3–5 | — | boutique 120 écus<br>butin : Contremaître en chef 16 %, Contremaître zélé 4 %<br>récompense de « Le péage de Zibeline » | Un sifflet de contremaître porté en pendentif. Les gobelins sursautent quand vous respirez fort. |
| **Broche de la Lisière** | 12 | Rare | Intelligence 6–10, Agilité 6–10, Sagesse 4–8 | — | récompense de « La Mère-Toile » | Remise aux observateurs du conseil elfe. On ne l'a remise qu'une fois en trois siècles : à vous. |
| **Carte du syndicat** | 12 | Rare | Agilité 6–10, Chance 6–10, Prospection 10–20 | — | récompense de « Le Balourd des Abîmes » | Carte de délégué provisoire du Syndicat des Travailleurs de Crasse-Roc. Donne droit à une pause par décennie. |
| **Amulette chantante** | 14 | Épique | Intelligence 8–11, Sagesse 4–6, Vitalité 8–12 | — | Forgeron niv. 14 (1 Étain chantant, 1 If funèbre, 6 Minerai d'étain, 2 Fil de brume)<br>récompense de « Notes d'observatrice » | Étain chantant et if funèbre : elle fredonne des airs d'enterrement, juste assez faux. |
| **Amulette d'argent** | 16 | Peu commun | Vitalité 12–17, Force 3–4, Intelligence 3–4, Chance 3–4 | — | boutique 120 écus<br>Forgeron niv. 16 (4 Minerai d'argent, 3 Dent de troll, 2 Bourse vide) | Une médaille d'argent à l'effigie d'un héros inconnu. Peut-être vous, un jour. Peut-être pas. |
| **Amulette œil-de-corbac** | 20 | Rare | Agilité 9–13, Prospection 26–38, Sagesse 7–10 | — | boutique 350 écus<br>butin : Corbac chef espion 12 %, Corbac espion 2 % | Un œil de verre noir qui voit ce qui brille. Surtout ce qui brille dans les poches des autres. |
| **Brassard du délégué** | 23 | Rare | Agilité 10–15, Chance 8–12, Prospection 15–25 | — | récompense de « Le registre des sacrifiés » | Brassard rouge du Syndicat des Travailleurs de Crasse-Roc, section « préavis contre le Souverain lui-même ». |
| **Insigne de la Vieille Garde** | 23 | Rare | Force 10–15, Vitalité 20–30, Sagesse 5–8 | — | récompense de « La vieille garde » | Remis par un fantôme qui monte la garde depuis trois cents ans. Il ne l'a jamais quitté : il ne savait pas qu'on pouvait. |
| **Amulette cœur-de-pierre** | 24 | Rare | Vitalité 26–37, Chance 8–11, Sagesse 5–7 | — | boutique 350 écus<br>butin : Gargouille de la Grande Porte 15 % | Elle bat une fois par heure, contre votre poitrine. On s'y fait. |
| **Cor d'olifant** | 29 | Épique | Force 11–16, Vitalité 23–33, Dommages 2–3, Sagesse 8–11 | — | butin : Olifant-tour 12 %, Olifant de guerre 2 % | Un cor taillé dans une défense. Quand on souffle dedans, quelqu'un, quelque part, accourt. Ou fuit. |

## Anneaux

| Nom | Niv. | Rareté | Bonus | Conditions | Obtention | Description |
|---|---|---|---|---|---|---|
| **Anneau de cuivre** | 1 | Commun | Intelligence 1–3, Chance 1–3 | — | boutique 40 écus<br>Forgeron niv. 1 (4 Minerai de cuivre)<br>équipement de départ : Arcaniste<br>équipement de départ : Théologue | Il verdit le doigt, mais il porte chance. |
| **Anneau de l'Enfant de Chœur** *(Panoplie de l'Enfant de Chœur)* | 3 | Commun | Force 1–3, Intelligence 1–3, Vitalité 3–6 | — | boutique 40 écus<br>butin : Abatteur en chef 13 %, Bûcheron de Brumerive 3 % | Immaculé, béni, repassé. On se demande comment il reste aussi propre en combat. |
| **Anneau du Bonhomme de Neige** *(Panoplie du Bonhomme de Neige)* | 3 | Commun | Chance 3–6, Vitalité 3–6 | — | boutique 40 écus<br>butin : Vampipistrelle comtesse 13 %, Vampipistrelle 3 % | Frais toute l'année. Ne pas porter près d'un feu de camp, ni d'un pyromane, même repenti. |
| **Anneau du Courant d'Air** *(Panoplie du Courant d'Air)* | 3 | Commun | Agilité 3–6, Vitalité 3–6 | — | boutique 40 écus<br>butin : Frondeur vétéran 6 %, Gobelin frondeur 2 % | On ne le voit pas arriver. On le sent passer, surtout dans le dos. |
| **Anneau du Forgeron Hargneux** *(Panoplie du Forgeron Hargneux)* | 3 | Commun | Force 3–6, Vitalité 3–6 | — | boutique 40 écus<br>Forgeron niv. 4 (3 Minerai de fer, 3 Minerai de cuivre, 2 Croc de loup) | Coulé dans la même fonte que l'enclume du forgeron. Et dans la même humeur. |
| **Anneau du Mauvais Œil** *(Panoplie du Mauvais Œil)* | 3 | Commun | Agilité 1–3, Chance 1–3, Vitalité 3–6 | — | boutique 40 écus<br>butin : Loup alpha 6 %, Loup des collines 2 % | Porte malheur à tout le monde, sauf à son propriétaire. Pour l'instant. |
| **Anneau du Pressé** *(Panoplie du Pressé)* | 3 | Commun | Initiative 10–20, Dommages 1 | — | boutique 40 écus<br>butin : Grouilleur ancestral 6 %, Grouilleur 2 % | Toujours le premier, jamais à l'heure. |
| **Anneau du Pyromane Repenti** *(Panoplie du Pyromane Repenti)* | 3 | Commun | Intelligence 3–6, Vitalité 3–6 | — | boutique 40 écus<br>butin : Contremaître en chef 13 %, Contremaître zélé 3 % | Il a juré de ne plus rien brûler. Ses vêtements, eux, n'ont rien juré. |
| **Anneau du frondeur** | 3 | Peu commun | Agilité 2–4, Prospection 5–10 | — | boutique 120 écus<br>butin : Frondeur vétéran 20 %, Gobelin frondeur 5 % | Gravé « Employé du mois ». Le mois n'est pas précisé. |
| **Anneau vert-de-gris** | 5 | Rare | Chance 4–6, Agilité 4–6, Prospection 8–12 | — | Forgeron niv. 5 (1 Cuivre vert-de-gris, 6 Minerai de cuivre, 3 Croc de loup) | Il verdit les doigts et porte chance. Les deux sont liés, assure le forgeron. |
| **Chevalière du Cogneur** | 5 | Rare | Dommages 2–4, Force 1–3 | — | boutique 350 écus<br>récompense de « Les ordres du raid » | Un poing gravé, à l'envers pour qu'il s'imprime à l'endroit sur la joue d'en face. |
| **Anneau d'étain** | 8 | Commun | Vitalité 8–11, Sagesse 4–5 | — | boutique 40 écus<br>Forgeron niv. 8 (5 Minerai d'étain, 2 Minerai de cuivre) | Il crie quand on le tord. Évitez de vous ronger les ongles en le portant. |
| **Anneau aux huit yeux** | 12 | Rare | Chance 4–5, Agilité 2–3, Portée 1 | — | butin : La Mère-Toile 20 % | Huit pierres noires qui vous regardent. Avec, vous voyez plus loin ; eux aussi. |
| **Chevalière du Délégué** | 12 | Rare | Force 4–6, Prospection 18–25, Dommages 1, Sagesse 3–4 | — | butin : Krasbouk, Chef de Raid (syndiqué) 20 % | Gravée « Délégué syndical, section raids ». Ouvre des portes, et parfois des crânes. |
| **Anneau de nez de troll** | 17 | Peu commun | Force 8–11, Vitalité 10–14, Sagesse 3–5 | — | boutique 120 écus<br>butin : Troll gastronome 16 %, Troll des ponts 4 % | Il fait le tour du doigt. Et de la main. Et un peu du poignet. |
| **Anneau de granit** | 22 | Peu commun | Vitalité 20–28, Force 5–7, Chance 5–7 | — | boutique 120 écus<br>butin : Gargouille de la Grande Porte 16 %, Gargouille 4 % | Taillé dans une gargouille. Lourd, solide, un peu grimaçant. |
| **Feuille d'argent de l'ambassade** | 25 | Rare | Intelligence 10–15, Agilité 6–10, Sagesse 6–10 | — | récompense de « Le bal des Cendrillons » | Le sceau de l'ambassade elfe. On ne la remet qu'aux observateurs qui ont fini par intervenir. |
| **Bague de minuit** | 27 | Rare | Intelligence 11–16, Dommages 1–2, Vitalité 17–25, % Critique 1–2 | — | boutique 350 écus<br>butin : Marraine Cendrée 13 %, Cendrillon 3 % | Elle sonne douze coups. Ensuite, tout redevient citrouille. |
| **Anneau du Gond** | 30 | Épique | Force 12–17, Intelligence 12–17, Vitalité 16–22, Dommages 2–3 | — | butin : Grondin, Bélier de la Brèche 15 % | Un gond de la Grande Porte de Hautepierre, arraché par Grondin. Il tient toujours. |
| **Éclat de l'Aube** | 30 | Épique | Vitalité 20–30, Force 6–10, Intelligence 6–10, Chance 6–10, Agilité 6–10 | — | récompense de « La Brèche » | Un éclat de lumière tombé de la Brèche quand Grondin s'est effondré. Il brille comme une Relique. Ce n'en est pas une. Pas encore. |

## Ceintures

| Nom | Niv. | Rareté | Bonus | Conditions | Obtention | Description |
|---|---|---|---|---|---|---|
| **Ceinture de corde** | 1 | Commun | Vitalité 2–5 | — | boutique 40 écus<br>Forgeron niv. 1 (2 Peau de loup, 1 Minerai de cuivre)<br>équipement de départ : Guerrier<br>équipement de départ : Rôdeur | Tient le pantalon. Mission accomplie. |
| **Ceinture de carapace** | 3 | Peu commun | Vitalité 5–10, Force 2–4 | — | boutique 120 écus<br>butin : Grouilleur ancestral 20 %, Grouilleur 5 % | Des anneaux de grouilleur enfilés sur une lanière. Ça craque à chaque pas. |
| **Ceinture de l'Enfant de Chœur** *(Panoplie de l'Enfant de Chœur)* | 3 | Commun | Force 2–4, Intelligence 2–4, Vitalité 5–10 | — | boutique 40 écus<br>butin : Abatteur en chef 13 %, Bûcheron de Brumerive 3 % | Immaculé, béni, repassé. On se demande comment il reste aussi propre en combat. |
| **Ceinture du Bonhomme de Neige** *(Panoplie du Bonhomme de Neige)* | 3 | Commun | Chance 4–7, Vitalité 5–10 | — | boutique 40 écus<br>butin : Vampipistrelle comtesse 13 %, Vampipistrelle 3 % | Frais toute l'année. Ne pas porter près d'un feu de camp, ni d'un pyromane, même repenti. |
| **Ceinture du Courant d'Air** *(Panoplie du Courant d'Air)* | 3 | Commun | Agilité 4–7, Vitalité 5–10 | — | boutique 40 écus<br>butin : Frondeur vétéran 6 %, Gobelin frondeur 2 % | On ne le voit pas arriver. On le sent passer, surtout dans le dos. |
| **Ceinture du Forgeron Hargneux** *(Panoplie du Forgeron Hargneux)* | 3 | Commun | Force 4–7, Vitalité 5–10 | — | boutique 40 écus<br>butin : Sergent de la milice 13 %, Milicien de Hautepierre 3 % | Coulé dans la même fonte que l'enclume du forgeron. Et dans la même humeur. |
| **Ceinture du Mauvais Œil** *(Panoplie du Mauvais Œil)* | 3 | Commun | Agilité 2–4, Chance 2–4, Vitalité 5–10 | — | boutique 40 écus<br>butin : Loup alpha 6 %, Loup des collines 2 % | Porte malheur à tout le monde, sauf à son propriétaire. Pour l'instant. |
| **Ceinture du Pressé** *(Panoplie du Pressé)* | 3 | Commun | Initiative 10–20, Dommages 1–2 | — | boutique 40 écus<br>butin : Grouilleur ancestral 6 %, Grouilleur 2 % | Toujours le premier, jamais à l'heure. |
| **Ceinture du Pyromane Repenti** *(Panoplie du Pyromane Repenti)* | 3 | Commun | Intelligence 4–7, Vitalité 5–10 | — | boutique 40 écus<br>butin : Contremaître en chef 13 %, Contremaître zélé 3 % | Il a juré de ne plus rien brûler. Ses vêtements, eux, n'ont rien juré. |
| **Ceinturon riveté** | 3 | Peu commun | Vitalité 8–15, Force 1–3 | — | boutique 120 écus<br>Forgeron niv. 3 (3 Peau de loup, 3 Minerai de fer)<br>récompense de « Le verger de Mère Pomponne » | Une ceinture de cuir clouté. Tient le pantalon et le moral. |
| **Ceinture de bûcheron** | 9 | Commun | Force 4–6, Vitalité 8–12 | — | boutique 40 écus<br>butin : Abatteur en chef 16 %, Bûcheron de Brumerive 4 % | Larges bretelles, larges épaules, petit esprit de conservation. |
| **Ceinture à gnôle** | 11 | Peu commun | Vitalité 11–16, Force 6–8 | — | boutique 120 écus<br>butin : Défonceur de portes 20 %, Gobelin briseur 5 % | Avec porte-flasque intégré. La flasque est vide, l'intention est là. |
| **Ceinture de troll** | 16 | Peu commun | Vitalité 18–26, Force 6–9 | — | boutique 120 écus<br>butin : Troll gastronome 16 %, Troll des ponts 4 %<br>récompense de « Droit de passage » | Une corde de pont, nouée deux fois. Elle fait trois fois votre tour de taille. |
| **Ceinture d'écorce calcinée** | 21 | Rare | Vitalité 23–33, Force 6–8, Intelligence 6–8 | — | boutique 350 écus<br>butin : Arbre calciné 4 %<br>récompense de « Les arbres qui brûlent » | Elle craque à chaque pas et laisse un peu de cendre partout. Les aubergistes vous détestent. |
| **Ceinture d'obsidienne** | 27 | Rare | Vitalité 29–41, Intelligence 7–10, Chance 7–10 | — | boutique 350 écus<br>Forgeron niv. 27 (6 Obsidienne, 3 Cuir d'olifant, 1 Corne du Balourd) | Des plaques de verre noir sur du cuir d'olifant. Elle tinte quand on court. |

## Bottes

| Nom | Niv. | Rareté | Bonus | Conditions | Obtention | Description |
|---|---|---|---|---|---|---|
| **Bottes de marche** | 2 | Peu commun | Agilité 1–3, Initiative 5–15 | — | boutique 120 écus<br>butin : Frondeur vétéran 15 %, Gobelin frondeur 5 %<br>Forgeron niv. 2 (3 Peau de loup, 2 Minerai de cuivre)<br>récompense de « Aux armes, citoyens (surtout vous) » | Usées par mille chemins, dont une bonne moitié de raccourcis ratés. |
| **Bottes de mousse** | 2 | Commun | Chance 2–3, Vitalité 4–5 | — | boutique 40 écus<br>butin : Vieille Morille rancunière 20 %, Morille grincheuse 5 %<br>récompense de « Observer sans intervenir » | Douces, silencieuses, un peu humides. Les champignons poussent dessus si on ne marche pas assez. |
| **Bottes feutrées** | 2 | Commun | Agilité 2–4, Prospection 5–10 | — | boutique 40 écus<br>butin : Rat-roi 20 %, Rat des galeries 5 %<br>récompense de « Objectifs de productivité » | Doublées de fourrure de rat. On marche sans bruit, et sans trop se poser de questions. |
| **Bottes de l'Enfant de Chœur** *(Panoplie de l'Enfant de Chœur)* | 3 | Commun | Force 1–3, Intelligence 1–3, Initiative 5–10 | — | boutique 40 écus<br>butin : Abatteur en chef 13 %, Bûcheron de Brumerive 3 % | Immaculé, béni, repassé. On se demande comment il reste aussi propre en combat. |
| **Bottes du Bonhomme de Neige** *(Panoplie du Bonhomme de Neige)* | 3 | Commun | Chance 3–6, Initiative 5–10 | — | boutique 40 écus<br>butin : Vampipistrelle comtesse 13 %, Vampipistrelle 3 % | Frais toute l'année. Ne pas porter près d'un feu de camp, ni d'un pyromane, même repenti. |
| **Bottes du Courant d'Air** *(Panoplie du Courant d'Air)* | 3 | Commun | Agilité 3–6, Initiative 5–10 | — | boutique 40 écus<br>butin : Frondeur vétéran 6 %, Gobelin frondeur 2 % | On ne le voit pas arriver. On le sent passer, surtout dans le dos. |
| **Bottes du Forgeron Hargneux** *(Panoplie du Forgeron Hargneux)* | 3 | Commun | Force 3–6, Initiative 5–10 | — | boutique 40 écus<br>butin : Sergent de la milice 13 %, Milicien de Hautepierre 3 % | Coulé dans la même fonte que l'enclume du forgeron. Et dans la même humeur. |
| **Bottes du Mauvais Œil** *(Panoplie du Mauvais Œil)* | 3 | Commun | Agilité 1–3, Chance 1–3, Initiative 5–10 | — | boutique 40 écus<br>butin : Loup alpha 6 %, Loup des collines 2 % | Porte malheur à tout le monde, sauf à son propriétaire. Pour l'instant. |
| **Bottes du Pressé** *(Panoplie du Pressé)* | 3 | Commun | Initiative 15–25, Agilité 2–4 | — | boutique 40 écus<br>butin : Grouilleur ancestral 6 %, Grouilleur 2 % | Toujours le premier, jamais à l'heure. |
| **Bottes du Pyromane Repenti** *(Panoplie du Pyromane Repenti)* | 3 | Commun | Intelligence 3–6, Initiative 5–10 | — | boutique 40 écus<br>butin : Contremaître en chef 13 %, Contremaître zélé 3 % | Il a juré de ne plus rien brûler. Ses vêtements, eux, n'ont rien juré. |
| **Bottes de rapine** | 9 | Peu commun | Agilité 4–6, Initiative 29–42, Prospection 12–17 | — | boutique 120 écus<br>butin : Pillard émérite 20 %, Gobelin pillard 5 % | Volées, évidemment. On ne sait pas à qui, ni à combien de personnes. |
| **Bottes de milicien** | 10 | Peu commun | Vitalité 11–15, Force 3–5, Initiative 21–30 | — | boutique 120 écus<br>butin : Sergent de la milice 16 %, Milicien de Hautepierre 4 % | Cirées pour la parade, crottées pour la patrouille. |
| **Bottes de grand chemin** | 14 | Peu commun | Agilité 5–8, Vitalité 8–12, Initiative 41–59 | — | boutique 120 écus<br>butin : Chef de bande 16 %, Détrousseur des grands chemins 4 %<br>récompense de « Le tampon officiel » | Elles connaissent toutes les routes, et surtout tous les fossés pour se cacher. |
| **Bottes de braise** | 18 | Rare | Intelligence 8–12, Force 6–9, Initiative 60–87 | — | boutique 350 écus<br>butin : Grouilleur de braise 4 % | Taillées dans la carapace d'un grouilleur de braise. Chaudes en hiver, en été aussi, toute l'année en fait. |
| **Bottes de gargouille** | 23 | Rare | Vitalité 20–29, Force 7–11, Chance 7–11 | — | boutique 350 écus<br>butin : Gargouille de la Grande Porte 13 %, Gargouille 3 % | On ne court pas avec. On ne tombe pas non plus. |
| **Pantoufles de cendre** | 25 | Rare | Intelligence 11–15, Agilité 8–12, Initiative 80–115 | — | boutique 350 écus<br>butin : Marraine Cendrée 13 %, Cendrillon 3 % | Il n'y en a qu'une paire, mais elles ne vont à personne. Sauf à vous, bizarrement. |
| **Semelles d'olifant** | 29 | Rare | Vitalité 30–44, Force 9–13, Initiative 61–87 | — | boutique 350 écus<br>butin : Olifant-tour 13 %, Olifant de guerre 3 % | Chaque pas fait trembler le plancher. Chaque plancher s'en souvient. |

## Ressources

| Nom | Niv. | Rareté | Obtention | Description |
|---|---|---|---|---|
| **Aile de vampipistrelle** | 1 | Commun | boutique 4 écus<br>butin : Vampipistrelle comtesse 88 %, Vampipistrelle 55 % | Fine comme du papier, solide comme du cuir, et elle sent la cave. |
| **Argent lunaire** | 1 | Rare | Mineur : Argent niv. 15, récolte rare | Il brille même la nuit, surtout la nuit. Les loups le regardent bizarrement. |
| **Bois d'if** | 1 | Peu commun | boutique 12 écus<br>Bûcheron : If niv. 8 | Sombre, souple, toxique. Les rôdeurs l'adorent, les chèvres beaucoup moins. |
| **Bois de cerf enchanté** | 1 | Peu commun | boutique 12 écus<br>butin : Grand cerf de la Lisière 60 %, Cerf enchanté 20 % | Une ramure qui murmure quand le vent passe. |
| **Bois de chêne** | 1 | Peu commun | boutique 12 écus<br>Bûcheron : Chêne niv. 3 | Dur comme une tête de nain, et presque aussi vieux. |
| **Bois de frêne** | 1 | Commun | boutique 4 écus<br>Bûcheron : Frêne niv. 1 | Souple et droit. Les elfes en font des arcs, les humains des manches de pioche. |
| **Bois de hêtre** | 1 | Peu commun | boutique 12 écus<br>Bûcheron : Hêtre niv. 15 | Blond, dur, régulier. On en fait des manches, des tables et des excuses. |
| **Bois de malorme** | 1 | Rare | boutique 35 écus<br>Bûcheron : Malorme niv. 22 | Un orme aux feuilles d'or. Les elfes jurent qu'ils l'ont vu en premier. |
| **Bon de coupe** | 1 | Peu commun | boutique 12 écus<br>butin : Abatteur en chef 48 %, Bûcheron de Brumerive 12 %<br>« Coupe rase » : sur Bûcheron de Brumerive, Abatteur en chef (50 %) | Autorisation de couper « quelques arbres ». Le mot « quelques » a été rayé. |
| **Bourse vide** | 1 | Commun | boutique 4 écus<br>butin : Chef de bande 88 %, Détrousseur des grands chemins 55 % | Vide. Comme toutes celles qu'il a volées, apparemment. Il ne comprend pas non plus. |
| **Caillou de fronde** | 1 | Commun | boutique 4 écus<br>butin : Frondeur vétéran 90 %, Gobelin frondeur 60 % | Un caillou. Rond. Réglementaire, d'après le gobelin qui le tenait. |
| **Carapace de grouilleur** | 1 | Commun | boutique 4 écus<br>butin : Grouilleur ancestral 90 %, Grouilleur 50 %, Grouilleur de braise 50 % | Un anneau de carapace verte. Il en manque une centaine pour faire le tour. |
| **Carte au trésor douteuse** | 1 | Peu commun | boutique 12 écus<br>butin : Chef de bande 48 %, Détrousseur des grands chemins 12 % | Une croix rouge, une flèche, et la mention « à peu près par là ». |
| **Cendre tiède** | 1 | Commun | boutique 4 écus<br>butin : Marraine Cendrée 88 %, Cendrillon 55 %, Arbre calciné 50 %, Grouilleur de braise 50 %, Loup cendreux 50 %<br>« Les arbres qui brûlent » : sur Arbre calciné (50 %) | Elle tombe de l'est depuis quelques mois. Elle ne refroidit jamais tout à fait. |
| **Chapeau de morille** | 1 | Commun | boutique 4 écus<br>butin : Vieille Morille rancunière 90 %, Morille grincheuse 60 %<br>« Des champignons qui insultent » : sur Morille grincheuse, Vieille Morille rancunière (50 %) | Alvéolé, parfumé, vexé. Il continue de bouder même détaché. |
| **Chêne des Anciens** | 1 | Rare | Bûcheron : Chêne niv. 3, récolte rare | Une bûche si vieille qu'elle se souvient de l'Âge de l'Aube. Elle refuse d'en parler. |
| **Citrouille grimaçante** | 1 | Peu commun | boutique 12 écus<br>butin : Grand Épouvantail 48 %, Épouvantail démotivé 12 % | Elle a été sculptée par personne. C'est bien ce qui inquiète. |
| **Copeaux de bois** | 1 | Commun | boutique 4 écus<br>butin : Abatteur en chef 88 %, Bûcheron de Brumerive 55 %<br>« La dette de Vieux-Branchu » : sur Bûcheron de Brumerive, Abatteur en chef (50 %) | Ce qui reste d'un arbre quand un bûcheron est passé. Les elfes les ramassent en pleurant. |
| **Corne du Balourd** | 1 | Rare | boutique 35 écus<br>butin : Le Balourd des Abîmes 100 % | Encore tiède. Si on la porte à l'oreille, on entend les galeries s'effondrer. |
| **Croc de loup** | 1 | Commun | boutique 4 écus<br>butin : Loup alpha 90 %, Loup cendreux 50 %, Loup des collines 50 % | Pointu, un peu baveux. Les forgerons en raffolent pour une raison qu'ils gardent pour eux. |
| **Crochet d'araignée** | 1 | Peu commun | boutique 12 écus<br>butin : Grande Tisseuse 48 %, Tisseuse de brume 12 % | Encore une goutte de venin au bout. Ne pas s'en servir comme cure-dent. |
| **Cuir d'olifant** | 1 | Commun | boutique 4 écus<br>butin : Olifant-tour 88 %, Olifant de guerre 55 % | Épais comme un mur de Hautepierre, et presque aussi gris. |
| **Cuivre vert-de-gris** | 1 | Rare | Mineur : Cuivre niv. 1, récolte rare | Un cuivre qui a pris l'air pendant un siècle. Il a de la patine, et de l'opinion. |
| **Cœur de frêne** | 1 | Rare | Bûcheron : Frêne niv. 1, récolte rare | Le centre d'un frêne qui a tenu trois tempêtes. Il en garde la souplesse, et la rancune. |
| **Cœur de pierre** | 1 | Peu commun | boutique 12 écus<br>butin : Gargouille de la Grande Porte 48 %, Gargouille 12 % | Il bat une fois par heure. On ne sait pas pour qui. |
| **Dent de rat** | 1 | Commun | boutique 4 écus<br>butin : Rat-roi 70 %, Rat des galeries 30 %<br>« Le dentier de Mamie Ratine » : sur Rat des galeries, Rat-roi (50 %) | Jaune, pointue, et encore un peu mordante. |
| **Dent de troll** | 1 | Commun | boutique 4 écus<br>butin : Troll gastronome 88 %, Troll des ponts 55 % | Grosse comme un poing, jaune comme un vieux fromage. Le troll en a d'autres. |
| **Fer météorique** | 1 | Rare | Mineur : Fer niv. 3, récolte rare | Tombé du ciel il y a longtemps. Les gobelins disent que c'était une réclamation. |
| **Fiche de paie gobeline** | 1 | Peu commun | boutique 12 écus<br>butin : Frondeur vétéran 50 %, Gobelin frondeur 15 %<br>« Aux armes, citoyens (surtout vous) » : sur Gobelin frondeur, Frondeur vétéran (50 %)<br>« Fausse fiche de présence » : sur Gobelin frondeur, Frondeur vétéran (50 %) | « Salaire : 0. Primes : 0. Retenue pour usure de cailloux : 3. » Document historique. |
| **Fil de brume** | 1 | Commun | boutique 4 écus<br>butin : La Mère-Toile 90 %, Grande Tisseuse 88 %, Tisseuse de brume 55 %<br>« Du fil de brume » : sur Tisseuse de brume, Grande Tisseuse (50 %) | Un fil d'araignée si fin qu'on le voit seulement quand il fait humide. Il fait toujours humide. |
| **Fragment de cendre** | 1 | Légendaire | boutique 250 écus<br>butin : Le Souverain Cendré 100 % | Un éclat tiède de la couronne du Souverain Cendré. Il ne refroidit jamais. |
| **Glande acide** | 1 | Peu commun | boutique 12 écus<br>butin : Grouilleur ancestral 50 %, Grouilleur 15 % | À manipuler avec des gants. Et une pince. Et de loin. |
| **Gnôle de raid** | 1 | Commun | boutique 4 écus<br>butin : Défonceur de portes 88 %, Gobelin briseur 55 % | Désinfecte, dégraisse, décape. Se boit aussi, paraît-il. |
| **Guano luisant** | 1 | Peu commun | boutique 12 écus<br>butin : Vampipistrelle comtesse 48 %, Vampipistrelle 12 %<br>« Guano-culture » : sur Vampipistrelle, Vampipistrelle comtesse (50 %)<br>« Heures supplémentaires (non payées) » : sur Vampipistrelle, Vampipistrelle comtesse (50 %) | De l'or, d'après Gnark. De l'or qui sent mauvais, mais de l'or. |
| **Hêtre centenaire** | 1 | Rare | Bûcheron : Hêtre niv. 15, récolte rare | Cent ans de patience dans chaque cerne. Il se fend quand il l'a décidé. |
| **If funèbre** | 1 | Rare | Bûcheron : If niv. 8, récolte rare | Il pousse près des tombes. Les archers l'adorent ; les fossoyeurs, moins. |
| **Invitation au bal** | 1 | Peu commun | boutique 12 écus<br>butin : Marraine Cendrée 48 %, Cendrillon 12 %<br>« Le bal des Cendrillons » : sur Cendrillon, Marraine Cendrée (50 %) | « Bal du Souverain, minuit. Tenue cendrée exigée. Les citrouilles ne sont pas admises. » |
| **Ivoire d'olifant** | 1 | Peu commun | boutique 12 écus<br>butin : Olifant-tour 48 %, Olifant de guerre 12 % | Un morceau de défense. On en fait des cors ; l'olifant n'a pas été consulté. |
| **Maillon de cotte** | 1 | Commun | boutique 4 écus<br>butin : Sergent de la milice 80 %, Milicien de Hautepierre 50 % | Un anneau de cotte de mailles. Il en faut beaucoup pour faire une cotte, et un milicien pour la remplir. |
| **Malorme ensorcelée** | 1 | Rare | Bûcheron : Malorme niv. 22, récolte rare | Ses feuilles dorées chuchotent. Ce qu'elles disent n'est pas très gentil. |
| **Message intercepté** | 1 | Peu commun | boutique 12 écus<br>butin : Corbac chef espion 48 %, Corbac espion 12 %<br>« Messages interceptés » : sur Corbac espion, Corbac chef espion (40 %) | « Rapport n° 412 : RAS. Rapport n° 413 : toujours RAS. Rapport n° 414 : j'ai faim. » |
| **Minerai d'argent** | 1 | Peu commun | boutique 12 écus<br>Mineur : Argent niv. 15 | Brillant, précieux, et mortel pour les choses qui ne devraient pas exister. |
| **Minerai d'étain** | 1 | Commun | boutique 4 écus<br>Mineur : Étain niv. 8 | Il crie quand on le tord. Si, si : écoutez bien. |
| **Minerai de cuivre** | 1 | Commun | boutique 4 écus<br>Mineur : Cuivre niv. 1 | Ça brille un peu, ça verdit beaucoup. |
| **Minerai de fer** | 1 | Peu commun | boutique 12 écus<br>Mineur : Fer niv. 3 | Lourd, terne, indispensable. Comme un garde de Hautepierre. |
| **Médaille en chocolat** | 1 | Peu commun | boutique 12 écus<br>butin : Défonceur de portes 48 %, Gobelin briseur 12 % | Décernée au briseur du mois. Il en a mangé la moitié pendant la cérémonie. |
| **Obsidienne** | 1 | Rare | boutique 35 écus<br>Mineur : Obsidienne niv. 22 | Verre de volcan. Elle coupe mieux que l'acier et se casse mieux que le verre. |
| **Obsidienne sanglante** | 1 | Rare | Mineur : Obsidienne niv. 22, récolte rare | Un verre noir veiné de rouge. Il coupe, et il a l'air content de couper. |
| **Ordre de raid** | 1 | Peu commun | boutique 12 écus<br>butin : Krasbouk, Chef de Raid (syndiqué) 100 %, Pillard émérite 48 %, Défonceur de portes 32 %, Gobelin pillard 12 %, Gobelin briseur 8 %<br>« Les ordres du raid » : sur Gobelin briseur, Gobelin pillard, Défonceur de portes, Pillard émérite (35 %) | Signé par un Héraut Cendré. L'orthographe est approximative, la menace très claire. |
| **Paille ensorcelée** | 1 | Commun | boutique 4 écus<br>butin : Grand Épouvantail 90 %, Épouvantail démotivé 60 %<br>« La grève des épouvantails » : sur Épouvantail démotivé, Grand Épouvantail (50 %) | Elle frissonne quand on parle de feu. On la comprend. |
| **Peau de loup** | 1 | Commun | boutique 4 écus<br>butin : Loup alpha 70 %, Loup des collines 30 %<br>« Les moutons d'Alric » : sur Loup des collines, Loup alpha (50 %) | Chaude, souple, et presque pas trouée. |
| **Plume de corbac** | 1 | Commun | boutique 4 écus<br>butin : Corbac chef espion 88 %, Corbac espion 55 % | Noire, luisante, et elle a l'air de vous écouter. |
| **Poil scintillant** | 1 | Commun | boutique 4 écus<br>butin : Grand cerf de la Lisière 90 %, Cerf enchanté 50 %<br>« L'ode au Grand Cerf » : sur Cerf enchanté, Grand cerf de la Lisière (50 %) | Il brille encore un peu dans le noir, comme le cerf qui l'a perdu. |
| **Queue de rat** | 1 | Commun | boutique 4 écus<br>butin : Rat-roi 90 %, Rat des galeries 60 %<br>« Objectifs de productivité » : sur Rat des galeries, Rat-roi (50 %) | Ne demandez pas à quoi ça sert. Les gobelins, eux, savent. |
| **Recette de troll** | 1 | Peu commun | boutique 12 écus<br>butin : Troll gastronome 48 %, Troll des ponts 12 %<br>« Droit de passage » : sur Troll des ponts, Troll gastronome (40 %) | « Aventurier rôti, trois façons. » Il manque la troisième, heureusement. |
| **Registre des heures** | 1 | Peu commun | boutique 12 écus<br>butin : Le Balourd des Abîmes 50 %, Contremaître en chef 48 %, Contremaître zélé 12 % | Toutes les heures supplémentaires y sont notées. Aucune n'a été payée. |
| **Sac de rapine** | 1 | Commun | boutique 4 écus<br>butin : Krasbouk, Chef de Raid (syndiqué) 90 %, Pillard émérite 88 %, Gobelin pillard 55 % | Dedans : une poule, un chandelier et un seul soulier. |
| **Sifflet de contremaître** | 1 | Commun | boutique 4 écus<br>butin : Contremaître en chef 80 %, Contremaître zélé 50 %<br>« Le péage de Zibeline » : sur Contremaître zélé, Contremaître en chef (50 %) | Trois coups : au travail. Deux coups : plus vite. Un coup : vous êtes viré. |
| **Soie de la Mère-Toile** | 1 | Rare | boutique 35 écus<br>butin : La Mère-Toile 100 % | Un écheveau tissé depuis l'Âge de l'Aube. Elle n'a jamais fini un seul napperon. |
| **Spores grincheuses** | 1 | Peu commun | boutique 12 écus<br>butin : Vieille Morille rancunière 48 %, Morille grincheuse 12 % | Une pincée suffit à gâcher une fête. Les elfes en mettent dans les lettres de refus. |
| **Sève ancienne** | 1 | Rare | boutique 35 écus<br>butin : Arbre millénaire 40 %, Arbre vivant 10 %<br>« Les arbres sont nerveux » : sur Arbre vivant, Arbre millénaire (50 %) | Ambrée, épaisse, plus vieille que Brumerive. |
| **Éclat de cendre** | 1 | Rare | boutique 35 écus<br>butin : Grondin, Bélier de la Brèche 100 %, Arbre calciné 3 %, Grouilleur de braise 3 %, Loup cendreux 3 % | Un fragment noir qui brûle sans flamme. Les Corrompus en ont plein le corps. |
| **Éclat de gargouille** | 1 | Commun | boutique 4 écus<br>butin : Gargouille de la Grande Porte 88 %, Gargouille 55 % | Un morceau de gargouille. Il grimace encore. |
| **Écorce vivante** | 1 | Commun | boutique 4 écus<br>butin : Arbre millénaire 90 %, Arbre vivant 60 %, Arbre calciné 50 % | Elle bouge encore un peu. C'est normal, paraît-il. |
| **Écusson de milice** | 1 | Peu commun | boutique 12 écus<br>butin : Sergent de la milice 48 %, Milicien de Hautepierre 12 %<br>« Inspection surprise » : sur Milicien de Hautepierre, Sergent de la milice (50 %) | Une tour blanche sur fond bleu. Les gobelins le collectionnent, les miliciens le regrettent. |
| **Étain chantant** | 1 | Rare | Mineur : Étain niv. 8, récolte rare | Il crie quand on le plie. Les forgerons trouvent ça touchant ; les voisins, non. |

## Objets de quête

| Nom | Niv. | Rareté | Obtention | Description |
|---|---|---|---|---|
| **Panier de pommes** | 6 | Commun | « Le verger de Mère Pomponne » : sur Gobelin pillard, Pillard émérite (40 %) | Les pommes de Mère Pomponne, reprises une à une aux pillards. Il en manque une : la plus belle. |
| **Laissez-passer de Hautepierre** | 12 | Rare | récompense de « La palissade de Krasbouk » | Signé du bourgmestre Pansu, contresigné par personne. À présenter au bureau des laissez-passer, qui exige un laissez-passer pour y entrer. |
| **Caisse de minerai** | 14 | Commun | « Le convoi de Brokk » : sur Loup cendreux, Détrousseur des grands chemins, Chef de bande (40 %) | Du minerai pour les forges du Souverain. Sur le couvercle : « colliers, modèle gobelin, taille unique ». |
| **Malle de l'ambassadrice** | 14 | Peu commun | « Notes d'observatrice » : sur Détrousseur des grands chemins, Chef de bande (30 %) | Les bagages d'Ilyndra Tel'Hautaine : trois robes, deux siècles de correspondance et un herbier de feuilles qu'elle trouve vulgaires. |
| **Tampon officiel** | 14 | Peu commun | « Le tampon officiel » : sur Détrousseur des grands chemins, Chef de bande (30 %) | Le tampon de l'Intendance. Sans lui, aucun laissez-passer n'est valable. Avec lui, non plus, mais c'est plus joli. |
| **Liste du Héraut** | 23 | Rare | « Le registre des sacrifiés » : sur Gargouille, Gargouille de la Grande Porte (30 %) | La liste du Héraut Cendré. Première ligne : « Gobelins (rubrique consommables) ». |

## Panoplies

| Panoplie | Orientation | Pièces | Bonus par nombre de pièces |
|---|---|---|---|
| **Panoplie du Bonhomme de Neige** | givre | Coiffe du Bonhomme de Neige, Cape du Bonhomme de Neige, Amulette du Bonhomme de Neige, Anneau du Bonhomme de Neige, Ceinture du Bonhomme de Neige, Bottes du Bonhomme de Neige | 2 pièces : Chance +10<br>3 pièces : Chance +20, Dommages +2<br>4 pièces : Chance +30, Dommages +4, Vitalité +20<br>5 pièces : Chance +40, Dommages +6, Vitalité +30<br>6 pièces : Chance +50, Dommages +8, Vitalité +40, PA +1 |
| **Panoplie du Courant d'Air** | tempete | Coiffe du Courant d'Air, Cape du Courant d'Air, Amulette du Courant d'Air, Anneau du Courant d'Air, Ceinture du Courant d'Air, Bottes du Courant d'Air | 2 pièces : Agilité +10<br>3 pièces : Agilité +20, Dommages +2<br>4 pièces : Agilité +30, Dommages +4, Vitalité +20<br>5 pièces : Agilité +40, Dommages +6, Vitalité +30<br>6 pièces : Agilité +50, Dommages +8, Vitalité +40, PA +1 |
| **Panoplie de l'Enfant de Chœur** | sacre | Coiffe de l'Enfant de Chœur, Cape de l'Enfant de Chœur, Amulette de l'Enfant de Chœur, Anneau de l'Enfant de Chœur, Ceinture de l'Enfant de Chœur, Bottes de l'Enfant de Chœur | 2 pièces : Force +5, Intelligence +5<br>3 pièces : Force +10, Intelligence +10, Dommages +2<br>4 pièces : Force +15, Intelligence +15, Dommages +4, Vitalité +20<br>5 pièces : Force +20, Intelligence +20, Dommages +6, Vitalité +30<br>6 pièces : Force +25, Intelligence +25, Dommages +8, Vitalité +40, PA +1 |
| **Panoplie du Forgeron Hargneux** | acier | Coiffe du Forgeron Hargneux, Cape du Forgeron Hargneux, Amulette du Forgeron Hargneux, Anneau du Forgeron Hargneux, Ceinture du Forgeron Hargneux, Bottes du Forgeron Hargneux | 2 pièces : Force +10<br>3 pièces : Force +20, Dommages +2<br>4 pièces : Force +30, Dommages +4, Vitalité +20<br>5 pièces : Force +40, Dommages +6, Vitalité +30<br>6 pièces : Force +50, Dommages +8, Vitalité +40, PA +1 |
| **Panoplie du Fouineur** | Prospection | Coiffe du Fouineur, Amulette du Fouineur, Cape du Fouineur | 2 pièces : Prospection +20<br>3 pièces : Prospection +50, Chance +10 |
| **Panoplie du Mauvais Œil** | impie | Coiffe du Mauvais Œil, Cape du Mauvais Œil, Amulette du Mauvais Œil, Anneau du Mauvais Œil, Ceinture du Mauvais Œil, Bottes du Mauvais Œil | 2 pièces : Agilité +5, Chance +5<br>3 pièces : Agilité +10, Chance +10, Dommages +2<br>4 pièces : Agilité +15, Chance +15, Dommages +4, Vitalité +20<br>5 pièces : Agilité +20, Chance +20, Dommages +6, Vitalité +30<br>6 pièces : Agilité +25, Chance +25, Dommages +8, Vitalité +40, PA +1 |
| **Panoplie du Pressé** | Initiative et Dommages | Anneau du Pressé, Bottes du Pressé, Ceinture du Pressé | 2 pièces : Initiative +20, Dommages +2<br>3 pièces : Initiative +50, Dommages +5 |
| **Panoplie du Pyromane Repenti** | flamme | Coiffe du Pyromane Repenti, Cape du Pyromane Repenti, Amulette du Pyromane Repenti, Anneau du Pyromane Repenti, Ceinture du Pyromane Repenti, Bottes du Pyromane Repenti | 2 pièces : Intelligence +10<br>3 pièces : Intelligence +20, Dommages +2<br>4 pièces : Intelligence +30, Dommages +4, Vitalité +20<br>5 pièces : Intelligence +40, Dommages +6, Vitalité +30<br>6 pièces : Intelligence +50, Dommages +8, Vitalité +40, PA +1 |

## Sorts des Voies

### Arcaniste

Maître du feu et du givre. Lit beaucoup, court peu, explose parfois des choses par accident. PV 46, PA 6, PM 3, initiative 90. Départ : Bâton de novice, Anneau de cuivre.

| Sort | Caractéristiques | Effets | Description |
|---|---|---|---|
| **Boule de feu** | 4 PA, portée 2–6, cercle de rayon 1, 1/tour | 5–8 Flamme | Le grand classique. Brûle la cible et tout ce qui l'entoure, amis compris : visez bien. |
| **Éclat de givre** | 3 PA, portée 1–5, 2/tour | 4–6 Givre ; −1 PM au prochain tour | Un éclat de glace qui engourdit les jambes : la cible aura un PM de moins au prochain tour. |
| **Étincelle** | 2 PA, portée 1–4, 3/tour | 2–4 Flamme | Petit sort, petit coût, petits dégâts. Mais trois fois par tour. |
| **Soin mineur** | 3 PA, portée 0–3, 1/tour, relance 2 t. | soin 8–12 (Flamme) | Referme les petites plaies. Pour les grandes, prévoir une potion. Ou un autre arcaniste. |

### Guerrier

Au contact, il encaisse et rend les coups. Réfléchit après, de préférence. PV 60, PA 6, PM 3, initiative 100. Départ : Épée de fer, Ceinture de corde.

| Sort | Caractéristiques | Effets | Description |
|---|---|---|---|
| **Frappe** | 3 PA, portée 1, 2/tour | 8–12 Acier | Un bon coup d'épée, sans fioritures. Le classique indémodable. |
| **Lancer de hache** | 4 PA, portée 2–5, 1/tour | 6–9 Acier | Lance sa hache de secours. Pensez à aller la rechercher. |
| **Tourbillon** | 4 PA, portée soi, cercle de rayon 1 (sans le lanceur), sans ligne de vue, 1/tour | 7–10 Acier | Tourne sur lui-même lame tendue. Frappe tout ce qui est au contact, amis compris. |
| **Second souffle** | 2 PA, portée soi, sans ligne de vue, 1/tour, relance 3 t. | soin 12–18 (Acier) | Une grande inspiration, une gorgée de gourde, et ça repart. |

### Rôdeur

Tire de loin, file entre les arbres et prétend toujours connaître un raccourci. PV 52, PA 6, PM 3, initiative 120. Départ : Arc de frêne, Ceinture de corde.

| Sort | Caractéristiques | Effets | Description |
|---|---|---|---|
| **Flèche** | 3 PA, portée 2–6, 2/tour | 5–8 Tempête | Une flèche bien droite. Enfin, à peu près. |
| **Tir perçant** | 4 PA, portée 3–7, 1/tour | 8–11 Acier | Une flèche lourde à pointe d'acier. Traverse les armures, et parfois le chapeau d'un voisin. |
| **Coup de dague** | 2 PA, portée 1, 2/tour | 3–5 Acier | Pour ceux qui s'approchent trop près. Ce qui arrive plus souvent qu'on ne le croit. |
| **Roulade** | 2 PA, portée 1–2, sans ligne de vue, 1/tour, relance 2 t. | téléportation sur la case | Une roulade élégante vers une case libre, pour reprendre ses distances. |

### Théologue

Soigneur sacré. Bénit les alliés, sermonne les ennemis, et cite des textes que personne n'a lus. PV 48, PA 6, PM 3, initiative 85. Départ : Sceptre de novice, Anneau de cuivre.

| Sort | Caractéristiques | Effets | Description |
|---|---|---|---|
| **Châtiment** | 4 PA, portée 2–5, 2/tour | 8–12 Sacré | Un rayon de lumière tombe sur la cible. Le ciel a l'air contrarié. |
| **Imposition des mains** | 3 PA, portée 0–3, 1/tour | soin 12–18 (Sacré) | Une main sur l'épaule, une prière, et les plaies se referment. Les remerciements sont facultatifs mais conseillés. |
| **Rempart de foi** | 2 PA, portée 0–3, 1/tour, relance 2 t. | bouclier 12–16 (Sacré) | Un halo doré qui encaisse les coups à votre place jusqu'à votre prochain tour. |
| **Sermon** | 4 PA, portée 1–4, croix latine, en ligne, 1/tour | 4–7 Sacré aux ennemis ; soin 4–7 (Sacré) aux alliés | Une croix de paroles saintes : les ennemis qui s'y trouvent souffrent, les alliés reprennent courage. |

## Sorts de race

| Sort | Caractéristiques | Effets | Lanceurs | Description |
|---|---|---|---|---|
| **Coup bas** | 3 PA, portée 1, 1/tour | 4–7 Tempête ; −1 PM au prochain tour | Gobelin | Un coup dans le genou. Pas glorieux, mais la cible marchera moins vite au prochain tour. |
| **Pas léger** | 2 PA, portée 1–3, sans ligne de vue, 1/tour, relance 3 t. | téléportation sur la case | Elfe | Un bond gracieux vers une case libre. L'herbe n'en garde même pas la trace. |
| **Ralliement** | 1 PA, portée soi, sans ligne de vue, 1/tour, relance 4 t. | +2 PA tout de suite | Humain | Un cri d'encouragement. À soi-même, faute d'alliés pour l'instant. |

## Sorts des monstres

| Sort | Caractéristiques | Effets | Lanceurs | Description |
|---|---|---|---|---|
| **Attention, ça tombe !** | 4 PA, portée 2–4, croix latine, en ligne, 1/tour, relance 1 t. | 5–7 Acier | Abatteur en chef (élite) niv. 12, Bûcheron de Brumerive niv. 7–9 | Il crie toujours avant. Personne n'écoute jamais. |
| **Bal de minuit** | 3 PA, portée 0–3, 1/tour, relance 1 t. | soin 7–10 (Flamme) aux alliés | Cendrillon niv. 25–27, Marraine Cendrée (élite) niv. 30 | Une valse de cendre qui referme les plaies d'un fidèle. |
| **Barrissement** | 3 PA, portée soi, cercle de rayon 2 (sans le lanceur), sans ligne de vue, 1/tour, relance 1 t. | 3–5 Tempête aux ennemis ; −1 PM (1 t.) aux ennemis | Olifant de guerre niv. 28–30, Olifant-tour (élite) niv. 33 | Le cor d'origine. Les oreilles saignent, les jambes flanchent. |
| **Bouclier levé** | 2 PA, portée soi, sans ligne de vue, 1/tour, relance 2 t. | bouclier 8–12 (Acier) | Milicien de Hautepierre niv. 7–9, Sergent de la milice (élite) niv. 12 | Position de garde numéro 3. Il ne connaît que celle-là, mais il la connaît bien. |
| **Bouderie** | 2 PA, portée soi, sans ligne de vue, 1/tour, relance 2 t. | bouclier 4–6 (Givre) | Morille grincheuse niv. 1–3, Vieille Morille rancunière (élite) niv. 6 | Elle boude. C'est étonnamment efficace. |
| **Brasier** | 4 PA, portée 2–7, 1/tour | 12–18 Flamme | Le Souverain Cendré (mini-boss) niv. 50 | Le sol s'embrase sous vos pieds. |
| **Bélier humain** | 4 PA, portée 1–3, croix latine, en ligne, 1/tour | 5–8 Acier | Défonceur de portes (élite) niv. 15 | Il fonce tête baissée. Il n'a jamais compris pourquoi ça fait mal aux autres et pas à lui. |
| **Cendres ardentes** | 4 PA, portée 2–5, 1/tour | 6–9 Flamme | Cendrillon niv. 25–27, Marraine Cendrée (élite) niv. 30 | Une poignée de cendre du Souverain, jetée au visage. Ça ne part pas. |
| **Cercle de sève** | 3 PA, portée soi, cercle de rayon 2, sans ligne de vue, 1/tour, relance 3 t. | glyphe (2 t.) : [soin 8–12 (Tempête) aux alliés ; −2 PM (1 t.) aux ennemis] | Arbre millénaire (élite) niv. 10 | L'arbre plonge ses racines tout autour de lui. Ce qui pousse là le soigne ; ce qui marche là s'enlise. |
| **Champ maudit** | 3 PA, portée 1–4, cercle de rayon 1, sans ligne de vue, 1/tour, relance 2 t. | glyphe (2 t.) : [3–5 Tempête aux ennemis ; −1 PM (1 t.) aux ennemis] | Grand Épouvantail (élite) niv. 12 | La terre se couvre d'épis noirs qui piquent les chevilles. |
| **Charge d'olifant** | 5 PA, portée 1, 1/tour | 9–13 Acier ; poussée de 2 case(s) | Olifant de guerre niv. 28–30, Olifant-tour (élite) niv. 33 | Trois tonnes de bonne humeur, lancées droit sur vous. |
| **Charge de la Brèche** | 5 PA, portée 2–5, en ligne, 1/tour, relance 2 t. | 10–14 Acier ; poussée de 2 case(s) | Grondin, Bélier de la Brèche (mini-boss) niv. 30, phase 2 (50 % PV) | Les chaînes lâchent : le bélier dévale la pente. Ce qui est devant lui ne le reste pas. |
| **Charge du grand cerf** | 5 PA, portée 1, 1/tour | 14–20 Acier | Grand cerf de la Lisière (élite) niv. 9 | Majestueux. Puis très, très douloureux. |
| **Chausse-trape** | 3 PA, portée 1–4, sans ligne de vue, 1/tour, relance 2 t. | piège invisible : [8–12 Acier aux ennemis ; −2 PM (1 t.) aux ennemis] | Frondeur vétéran (élite) niv. 9 | Des cailloux pointus semés dans l'herbe. Vingt ans de métier : on ne les voit jamais avant de marcher dessus. |
| **Cocon** | 4 PA, portée 1–4, 1/tour, relance 1 t. | 6–9 Givre ; −2 PA (1 t.) | Grande Tisseuse (élite) niv. 15 | Elle vous emballe pour plus tard. |
| **Coup d'épée réglementaire** | 4 PA, portée 1, 1/tour | 7–10 Acier | Milicien de Hautepierre niv. 7–9, Sergent de la milice (élite) niv. 12 | Exécuté selon le manuel de la milice, page 12. |
| **Coup de baguette** | 4 PA, portée 1–4, cercle de rayon 1, 1/tour | 6–8 Flamme ; −1 PA (1 t.) | Marraine Cendrée (élite) niv. 30 | Un geste gracieux, une citrouille qui explose. |
| **Coup de bec** | 3 PA, portée 1, 1/tour | 5–7 Acier | Corbac chef espion (élite) niv. 24, Corbac espion niv. 19–21 | Toujours dans l'œil. Il vise bien, il a de l'entraînement. |
| **Coup de branche** | 4 PA, portée 1, 1/tour | 10–15 Acier | Arbre calciné niv. 19–21, Arbre millénaire (élite) niv. 10, Arbre vivant niv. 4–6 | Lent à venir, long à oublier. |
| **Coup de bâton** | 3 PA, portée 1–2, 2/tour | 5–7 Acier | Contremaître en chef (élite) niv. 15, Contremaître zélé niv. 10–12 | Motivation par l'exemple. Et par le bâton. |
| **Coup de bélier** | 5 PA, portée 1, 1/tour | 12–16 Acier ; poussée de 2 case(s) | Grondin, Bélier de la Brèche (mini-boss) niv. 30 | Le coup qui a fait trembler la Grande Porte. Vous êtes moins solide qu'une porte. |
| **Coup de cognée** | 4 PA, portée 1, 1/tour | 7–10 Acier | Abatteur en chef (élite) niv. 12, Bûcheron de Brumerive niv. 7–9 | Bien droit, comme pour un chêne. Vous n'êtes pas un chêne. |
| **Coup de fourche** | 4 PA, portée 1–2, 1/tour | 6–9 Acier | Grand Épouvantail (élite) niv. 12, Épouvantail démotivé niv. 7–9 | Trois dents, une seule intention. |
| **Coup de fronde** | 3 PA, portée 2–5, 2/tour | 3–6 Acier | Frondeur vétéran (élite) niv. 9, Gobelin frondeur niv. 4–6 | Un caillou bien ajusté. Le gobelin a été payé à la pièce. |
| **Coup de hache** | 4 PA, portée 1, 1/tour | 7–10 Acier | Défonceur de portes (élite) niv. 15, Gobelin briseur niv. 10–12 | Il brise les portes. Les genoux, c'est en bonus. |
| **Coup de massue** | 4 PA, portée 1, 1/tour | 8–11 Acier ; poussée de 1 case(s) | Troll des ponts niv. 16–18, Troll gastronome (élite) niv. 21 | Pas de technique, beaucoup de massue. |
| **Coup de ramure** | 4 PA, portée 1, 1/tour | 8–12 Acier | Cerf enchanté niv. 4–6, Grand cerf de la Lisière (élite) niv. 9 | Des bois enchantés, mais des bois quand même. |
| **Coup de surin** | 3 PA, portée 1, 2/tour | 5–7 Impie | Chef de bande (élite) niv. 18, Détrousseur des grands chemins niv. 13–15 | Dans l'ombre, sans prévenir, sans facture. |
| **Crachat acide** | 4 PA, portée 2–4, 1/tour | 5–8 Flamme | Grouilleur niv. 1–3, Grouilleur ancestral (élite) niv. 7 | Ça fume, ça pique, ça ne part pas au lavage. |
| **Crachat de feu** | 4 PA, portée 2–4, cercle de rayon 1, 1/tour | 5–7 Flamme | Grouilleur de braise niv. 16–18 | L'acide a pris feu. Il en est très fier. |
| **Crachat de lave** | 3 PA, portée 2–6, cercle de rayon 1, 1/tour | 4–6 Flamme | Le Balourd des Abîmes (mini-boss) niv. 12 | Il n'a pas de manières. Il a de la lave. |
| **Cri de raid** | 2 PA, portée soi, sans ligne de vue, 1/tour, relance 3 t. | +25 Force (2 t.) aux alliés | Krasbouk, Chef de Raid (syndiqué) (mini-boss) niv. 12 | « Pour la prime ! » Ses muscles y croient. |
| **Croc sanglant** | 4 PA, portée 1, 1/tour | 9–13 Acier | Loup alpha (élite) niv. 7 | Le chef de meute ne mord pas : il signe. |
| **Embuscade** | 3 PA, portée 1–4, sans ligne de vue, 1/tour, relance 2 t. | piège invisible : [9–13 Impie aux ennemis ; −2 PM (1 t.) aux ennemis] | Chef de bande (élite) niv. 18 | Ils étaient cachés dans le fossé. Ils y sont toujours, d'ailleurs. |
| **Estocade de pillard** | 3 PA, portée 1, 2/tour | 5–7 Acier | Gobelin pillard niv. 7–9, Pillard émérite (élite) niv. 12 | Un coup rapide, avant que la victime ne compte ses poules. |
| **Fouet de flammes** | 4 PA, portée 1–3, 1/tour | 6–9 Flamme ; attire de 1 case(s) | Le Balourd des Abîmes (mini-boss) niv. 12 | Il vous ramène vers lui, poliment, par le cou. |
| **Gargouillis** | 3 PA, portée 2–4, 1/tour | 5–7 Givre | Gargouille niv. 22–24, Gargouille de la Grande Porte (élite) niv. 27 | Elle crache l'eau de pluie de la semaine. Glacée. |
| **Gnôle de raid** | 2 PA, portée soi, sans ligne de vue, 1/tour, relance 3 t. | soin 6–9 (Acier) | Défonceur de portes (élite) niv. 15, Gobelin briseur niv. 10–12 | Une gorgée de gnôle. Ça soigne, d'après l'étiquette. |
| **Griffes de pierre** | 4 PA, portée 1, 1/tour | 7–10 Acier | Gargouille niv. 22–24, Gargouille de la Grande Porte (élite) niv. 27 | Trois siècles à garder une gouttière, ça aiguise les griffes. |
| **Grignotage** | 2 PA, portée 1, 1/tour | 1–2 Acier ; −1 PM au prochain tour | Rat des galeries niv. 1–3, Rat-roi (élite) niv. 5 | Le rat s'attaque aux lacets. On avance moins vite. |
| **Hachette de jet** | 3 PA, portée 2–5, 1/tour | 4–6 Acier | Krasbouk, Chef de Raid (syndiqué) (mini-boss) niv. 12 | Il en a toujours une de rechange, glissée dans la botte. |
| **Hachoir réglementaire** | 4 PA, portée 1, 1/tour | 7–10 Acier | Krasbouk, Chef de Raid (syndiqué) (mini-boss) niv. 12 | Coup porté selon l'article 3 du contrat de raid. |
| **Heures sup'** | 2 PA, portée 1–4, 1/tour, relance 2 t. | +2 PA tout de suite aux alliés | Contremaître en chef (élite) niv. 15, Contremaître zélé niv. 10–12 | Un collègue gagne 2 PA tout de suite. Non payés, évidemment. |
| **Jet d'acide ancestral** | 5 PA, portée 2–5, cercle de rayon 1, 1/tour | 7–11 Flamme | Grouilleur ancestral (élite) niv. 7 | Une recette transmise de grouilleur en grouilleur depuis mille générations. |
| **La bourse ou la vie** | 3 PA, portée 1–2, 1/tour | 3–5 Tempête ; −15 Chance (2 t.) | Chef de bande (élite) niv. 18, Détrousseur des grands chemins niv. 13–15 | Vous choisissez la bourse. Il prend quand même un peu de la vie. |
| **Lame de braise** | 4 PA, portée 1, 1/tour | 8–11 Flamme | Le Balourd des Abîmes (mini-boss) niv. 12 | Une épée faite de feu. Ou un feu en forme d'épée : il n'a jamais su. |
| **Lame de cendre** | 4 PA, portée 1, 2/tour | 22–30 Flamme | Le Souverain Cendré (mini-boss) niv. 50 | Une épée noire qui laisse des braises dans la plaie. |
| **Lancer de rocher** | 4 PA, portée 2–5, 1/tour | 5–8 Acier | Troll des ponts niv. 16–18, Troll gastronome (élite) niv. 21 | Il arrache un morceau de pont et vous le rend. |
| **Licenciement** | 4 PA, portée 1–2, 1/tour | 6–9 Acier ; poussée de 3 case(s) | Contremaître en chef (élite) niv. 15 | « Vous êtes viré ! » La porte, c'est par là. Loin. |
| **Marinade** | 3 PA, portée 1–2, 1/tour | poison 4–6 Flamme par tour (3 t.) ; −10 Résistance Flamme (3 t.) | Troll gastronome (élite) niv. 21 | Il vous assaisonne avant cuisson. Le feu vous fera plus mal ensuite. |
| **Morsure** | 3 PA, portée 1, 2/tour | 3–5 Acier | Loup alpha (élite) niv. 7, Loup cendreux niv. 13–15, Loup des collines niv. 1–3 |  |
| **Morsure brûlante** | 3 PA, portée 1, 1/tour | 4–6 Flamme ; poison 2–3 Flamme par tour (2 t.) | Loup cendreux niv. 13–15 | Ses crocs gardent la chaleur de la Cendre. |
| **Morsure de rat** | 3 PA, portée 1, 2/tour | 3–5 Acier | Rat des galeries niv. 1–3, Rat-roi (élite) niv. 5 | Petite, mais elle revient souvent. |
| **Morsure glacée** | 3 PA, portée 1, 1/tour | 4–6 Givre ; poison 2–3 Givre par tour (2 t.) | Grande Tisseuse (élite) niv. 15, La Mère-Toile (mini-boss) niv. 12, Tisseuse de brume niv. 10–12 | Le venin des tisseuses gèle le sang. Et l'humeur. |
| **Morsure royale** | 4 PA, portée 1, 1/tour | 7–10 Acier | Rat-roi (élite) niv. 5 | Une morsure par droit divin. |
| **Nuage de rancune** | 4 PA, portée 1–3, cercle de rayon 1, 1/tour | poison 2–3 Givre par tour (3 t.) ; −1 Portée (1 t.) | Vieille Morille rancunière (élite) niv. 6 | Elle n'oublie rien. Vos poumons non plus. |
| **Nuée de corbeaux** | 3 PA, portée 2–5, 1/tour | 4–6 Tempête | Grand Épouvantail (élite) niv. 12, Épouvantail démotivé niv. 7–9 | Il ne fait plus peur aux corbeaux, alors il travaille avec eux. |
| **Nuée de la comtesse** | 5 PA, portée 1–4, cercle de rayon 1, 1/tour | 5–7 Impie | Vampipistrelle comtesse (élite) niv. 9 | Toute la famille vient dîner. Vous êtes le dîner. |
| **Pinces** | 3 PA, portée 1, 2/tour | 4–7 Acier | Grouilleur niv. 1–3, Grouilleur ancestral (élite) niv. 7, Grouilleur de braise niv. 16–18 | Des dizaines de pattes, et deux pinces de trop. |
| **Piqué** | 4 PA, portée 2–5, 1/tour | 6–9 Tempête | Corbac chef espion (élite) niv. 24, Corbac espion niv. 19–21 | Il tombe du ciel comme un mauvais présage, et c'en est un. |
| **Piétinement** | 5 PA, portée soi, cercle de rayon 1 (sans le lanceur), sans ligne de vue, 1/tour | 10–13 Acier | Olifant-tour (élite) niv. 33 | Il danse. Personne n'a envie d'être son cavalier. |
| **Pluie de braises** | 3 PA, portée 1–5, cercle de rayon 2, sans ligne de vue, 1/tour, relance 3 t. | glyphe (2 t.) : [3–5 Flamme aux ennemis] | Le Balourd des Abîmes (mini-boss) niv. 12, phase 2 (40 % PV) | Le plafond de la galerie s'embrase. Personne ne va aimer la suite. |
| **Pluie de cailloux** | 5 PA, portée 2–6, cercle de rayon 1, 1/tour | 6–10 Acier | Frondeur vétéran (élite) niv. 9 | Vingt ans de service, et toujours pas de prime. Il se venge sur tout le monde. |
| **Pluie de cendres** | 3 PA, portée 1–3, cercle de rayon 1, sans ligne de vue, 1/tour, relance 2 t. | glyphe (2 t.) : [4–6 Flamme aux ennemis] | Arbre calciné niv. 19–21 | Il secoue ses branches mortes ; il en tombe des braises. |
| **Racines** | 3 PA, portée 1–3, 1/tour | 4–6 Acier ; −2 PM au prochain tour | Arbre calciné niv. 19–21, Arbre millénaire (élite) niv. 10, Arbre vivant niv. 4–6 | Les racines sortent de terre et vous retiennent. |
| **Rappel à l'ordre** | 3 PA, portée 2–4, en ligne, 1/tour, relance 1 t. | attire de 2 case(s) ; 4–6 Acier | Sergent de la milice (élite) niv. 12 | « Vous, là ! Approchez ! » On approche, c'est plus fort que soi. |
| **Rapport détaillé** | 3 PA, portée 1–6, 1/tour | −15 Résistance Tempête (2 t.) ; −1 Portée (1 t.) | Corbac chef espion (élite) niv. 24 | Il a tout noté. Vos faiblesses aussi. |
| **Razzia** | 4 PA, portée soi, cercle de rayon 1 (sans le lanceur), sans ligne de vue, 1/tour | 6–9 Acier | Pillard émérite (élite) niv. 12 | Il tourne sur lui-même en hurlant le nom de son raid. Tout ce qui l'entoure prend un coup. |
| **Regard de pierre** | 3 PA, portée 1–3, 1/tour, relance 2 t. | 3–5 Givre ; −2 PM (1 t.) ; −1 PA (1 t.) | Gargouille de la Grande Porte (élite) niv. 27 | Un regard figé. Vos jambes suivent l'exemple. |
| **Retenue sur salaire** | 3 PA, portée 2–5, 1/tour | 4–6 Tempête ; −3 Dommages (2 t.) | Contremaître en chef (élite) niv. 15, Contremaître zélé niv. 10–12 | Vos dégâts sont retenus à la source. |
| **Ronces millénaires** | 4 PA, portée 1–4, cercle de rayon 1, 1/tour | 8–12 Acier ; −1 PM au prochain tour | Arbre millénaire (élite) niv. 10 | Le sol se hérisse d'épines plus vieilles que les royaumes. |
| **Souche piégée** | 3 PA, portée 1–4, sans ligne de vue, 1/tour, relance 2 t. | piège invisible cercle de rayon 1 : [7–10 Acier aux ennemis ; −2 PM (1 t.) aux ennemis] | Abatteur en chef (élite) niv. 12 | Une souche, des pointes, et un abatteur qui sourit. |
| **Souffle cendré** | 5 PA, portée 1–4, cercle de rayon 1, 1/tour | 15–22 Flamme | Le Souverain Cendré (mini-boss) niv. 50 | Une vague de cendre brûlante autour de la cible. |
| **Souffle de forge** | 4 PA, portée 1–4, cercle de rayon 1, 1/tour | 8–11 Flamme | Grondin, Bélier de la Brèche (mini-boss) niv. 30, phase 3 (20 % PV) | La tête de loup crache le feu de la forge où on l'a coulée. |
| **Spores** | 3 PA, portée 1–3, 1/tour | 2–4 Givre ; poison 1–2 Givre par tour (2 t.) | Morille grincheuse niv. 1–3, Vieille Morille rancunière (élite) niv. 6 | Un nuage de mauvaise humeur, très contagieux. |
| **Suçon** | 3 PA, portée 1, 2/tour | 4–6 Impie | Vampipistrelle niv. 4–6, Vampipistrelle comtesse (élite) niv. 9 | Une petite morsure, très affectueuse, très impie. |
| **Toile collante** | 3 PA, portée 2–5, 1/tour | 2–4 Givre ; −2 PM (1 t.) | Grande Tisseuse (élite) niv. 15, La Mère-Toile (mini-boss) niv. 12, Tisseuse de brume niv. 10–12 | On se débat, on s'emmêle, on reste là. |
| **Toile géante** | 4 PA, portée 2–5, cercle de rayon 2, sans ligne de vue, 1/tour, relance 3 t. | glyphe (2 t.) : [2–4 Givre aux ennemis ; −2 PM (1 t.) aux ennemis] | La Mère-Toile (mini-boss) niv. 12, phase 1 (65 % PV) | Toute la clairière devient un piège. |
| **Tourbillon syndical** | 4 PA, portée soi, cercle de rayon 1 (sans le lanceur), sans ligne de vue, 1/tour | 7–10 Acier | Krasbouk, Chef de Raid (syndiqué) (mini-boss) niv. 12, phase 2 (30 % PV) | Il fait le tour de la question. Et de tous ceux qui l'entourent. |
| **Ultrason** | 3 PA, portée 1–4, 1/tour | 3–5 Tempête ; −1 Portée (1 t.) | Vampipistrelle niv. 4–6, Vampipistrelle comtesse (élite) niv. 9 | Un cri si aigu qu'on ne vise plus droit. |
| **Venin ancestral** | 4 PA, portée 1, 1/tour | 7–10 Givre ; poison 3–4 Givre par tour (3 t.) | La Mère-Toile (mini-boss) niv. 12 | Une seule morsure, et l'hiver s'installe dans vos veines. |
| **Vol à l'arraché** | 2 PA, portée 1, 1/tour | 2–4 Tempête ; −2 Dommages (2 t.) | Gobelin pillard niv. 7–9, Pillard émérite (élite) niv. 12 | Il vous prend quelque chose. Vous ne savez pas quoi, mais vous frappez moins fort. |
| **Éclat sylvestre** | 3 PA, portée 2–5, 2/tour | 5–8 Tempête | Cerf enchanté niv. 4–6, Grand cerf de la Lisière (élite) niv. 9 | Une lueur verte jaillit des bois du cerf. |
| **Éclats de porte** | 3 PA, portée 2–5, cercle de rayon 1, 1/tour | 4–6 Acier | Grondin, Bélier de la Brèche (mini-boss) niv. 30 | Il crache les morceaux des portes qu'il a déjà enfoncées. |
| **Élan** | 2 PA, portée soi, sans ligne de vue, 1/tour, relance 2 t. | +2 PM (1 t.) | Grondin, Bélier de la Brèche (mini-boss) niv. 30 | Les roues grincent, les chaînes claquent : il recule pour mieux frapper. |
| **Épaulée** | 3 PA, portée 1, 1/tour | 3–5 Acier ; poussée de 2 case(s) | Défonceur de portes (élite) niv. 15, Gobelin briseur niv. 10–12 | Un coup d'épaule de professionnel : on recule, on réfléchit. |
