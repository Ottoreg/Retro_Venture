# Questionnaire des testeurs — alpha test 1 (version de référence)

Contenu à jour du Google Forms « Retro Venture — Questionnaire de test Alpha Solo »
(lien des testeurs : https://docs.google.com/forms/d/1FjElWO0e9AP0lCeaVXw6DzaL0U_hO2MZkGy-05V9gKk/viewform,
aussi dans le jeu : « Donner son avis », et dans `client/session.gd`, `Session.FEEDBACK_URL`).

Le formulaire lui-même se modifie à la main dans Google Forms (aucun outil ne peut l'éditer depuis
le dépôt) : ce fichier sert de modèle. Types : *choix unique*, *cases* (plusieurs choix), *échelle*
(1 à 5, libellés aux extrémités), *court* / *long* (réponse texte). Les questions marquées ★ sont
obligatoires ; toutes les autres sont facultatives, pour qu'on puisse répondre même après une
courte partie.

**Paramètres conseillés** : ne pas collecter les adresses e-mail (pseudo facultatif à la place),
autoriser plusieurs réponses (un testeur peut jouer plusieurs personnages), afficher une barre de
progression, message de confirmation : « Merci ! Vos retours vont directement façonner l'alpha
test 2. »

---

## Introduction (texte du formulaire)

> Merci d'avoir testé Retro Venture ! Ce questionnaire prend une dizaine de minutes. Cet alpha test
> porte sur les **mécaniques** (combat, quêtes, exploration, interface, métiers) : l'expérience est
> volontairement accélérée (×3,5) et il n'y a ni son ni dessins définitifs. Répondez même si vous
> n'avez joué qu'un moment, et n'hésitez pas à remplir le formulaire une fois par personnage.

## 1. Vous et votre partie

1. Pseudo (pour vous recontacter si besoin) — *court*
2. ★ Avez-vous déjà joué à Dofus (ou Dofus Rétro) ? — *choix unique* : Oui, beaucoup / Un peu /
   Jamais
3. Jouez-vous souvent à des jeux tactiques au tour par tour ? — *choix unique* : Souvent / Parfois /
   Rarement / Jamais
4. ★ Navigateur et système — *choix unique* : Chrome / Firefox / Edge / Safari / Autre (+ système
   dans « Autre » ou en commentaire)
5. ★ Combien de temps avez-vous joué ? — *choix unique* : Moins de 30 min / 30 min à 1 h / 1 à 2 h /
   2 à 4 h / Plus de 4 h
6. ★ Race du personnage — *choix unique* : Humain / Gobelin / Elfe
7. ★ Voie (classe) — *choix unique* : Guerrier / Rôdeur / Arcaniste / Théologue
8. Niveau atteint — *court*
9. ★ Jusqu'où êtes-vous allé dans l'histoire ? — *choix unique* : Tutoriel / Acte I (zone de départ) /
   Mini-boss de la zone vaincu / Acte II (Hautepierre) / Le Conseil des Peuples Libres / La Brèche
   (Grondin vaincu)

## 2. Prise en main

10. ★ Le tutoriel vous a-t-il appris l'essentiel ? — *échelle* : 1 « Pas du tout » … 5 « Tout à fait »
11. Avez-vous eu besoin du guide des testeurs ? — *choix unique* : Jamais / Parfois / Souvent / Je ne
    l'ai pas lu
12. Qu'est-ce qui vous a manqué pour comprendre le jeu au début ? — *long*

## 3. Combat

13. ★ Les combats sont-ils compréhensibles (portées, PA/PM, ordre de jeu, effets) ? — *échelle* :
    1 « Confus » … 5 « Très clairs »
14. ★ Difficulté générale — *échelle* : 1 « Trop facile » … 3 « Bien » … 5 « Trop dur »
15. Durée des combats — *choix unique* : Trop courts / Bien / Un peu longs / Beaucoup trop longs
16. Mini-boss affrontés — *cases* : Krasbouk / Balourd des Abîmes / Mère-Toile / Grondin / Aucun
17. Un mini-boss vous a-t-il bloqué ? Lequel, à quel niveau, en combien d'essais ? — *long*
18. Avez-vous utilisé le mode tactique (touche T) ? — *choix unique* : Oui, tout le temps / Parfois /
    Non, je ne l'ai pas trouvé / Non, pas besoin
19. Votre Voie vous a-t-elle semblé trop faible, trop forte, ou bien ? Pourquoi ? — *long*
20. Un sort ou un effet incompris ou inutile ? — *long*

## 4. Quêtes et histoire

21. ★ Saviez-vous quoi faire et où aller ? — *échelle* : 1 « Jamais » … 5 « Toujours »
22. ★ Les textes (dialogues, quêtes, objets) vous ont-ils fait sourire ? — *échelle* : 1 « Pas du
    tout » … 5 « Beaucoup »
23. Le journal (Q) et le suivi sous la minicarte vous ont-ils aidé ? — *échelle* : 1 … 5
24. Votre quête préférée, et pourquoi ? — *court*
25. Une quête vous a-t-elle bloqué ou semblé injuste ? Laquelle ? — *long*
26. Avez-vous visité les zones des autres camps ? — *choix unique* : Oui / Non / Je ne savais pas que
    c'était possible

## 5. Exploration et interface

27. ★ Les cartes se lisent-elles bien (où marcher, sorties, portes, ce qui est cliquable) ? —
    *échelle* : 1 … 5
28. La minicarte et la carte du monde (M) vous ont-elles aidé à vous orienter ? — *échelle* : 1 … 5
29. Fenêtres les plus utiles ou les plus pénibles (inventaire, fiche, sorts, métiers, journal,
    boutique, atelier) — *long*
30. Un clic, une fenêtre ou un raccourci qui ne réagissait pas comme prévu ? — *long*

## 6. Progression, économie, métiers

31. ★ Rythme de montée en niveau — *choix unique* : Trop rapide / Bien / Trop lent
32. Les écus, les prix des marchands et les récompenses vous ont-ils semblé cohérents ? — *échelle* :
    1 … 5
33. Avez-vous utilisé les métiers (récolte, forge) ? — *choix unique* : Beaucoup / Un peu / Pas du
    tout
34. Avez-vous obtenu une ressource rare (« Rare ! ») ou fabriqué une recette améliorée ? — *choix
    unique* : Oui / Non
35. Équipement et panoplies : des remarques ? — *long*

## 7. Bugs

36. Avez-vous rencontré un bug ? — *choix unique* : Non / Oui, gênant / Oui, bloquant
37. Décrivez-le : ce que vous faisiez (carte, combat, quête), ce qui s'est passé, ce que vous
    attendiez, s'il revient en recommençant — *long*
38. Lien vers une capture d'écran (si vous en avez une) — *court*

## 8. Bilan

39. ★ Note globale de cette version — *échelle* : 1 … 10
40. ★ Auriez-vous envie de jouer à la suite (alpha test 2 : vraie progression, sorts par niveau,
    dessins et son) ? — *choix unique* : Oui / Peut-être / Non
41. Ce que vous avez préféré — *long*
42. Ce qu'il faut changer en priorité — *long*
43. Un dernier mot ? — *long*

---

### Changements par rapport au brouillon

À reporter dans le Google Forms existant, en comparant avec ce modèle. Le brouillon n'a pas pu être
relu automatiquement : un Google Forms ne s'exporte pas par le connecteur Drive. Points qui ont
changé dans le jeu depuis qu'il a été commencé :

- version **0.6.0, alpha test 1** ; l'XP accélérée ×3,5 et le but du test (mécaniques, pas
  progression) ;
- **4 Voies** dont le **Théologue** ; 3 races ;
- **quêtes** (tutoriel, actes I à III, 15 secondaires, journal Q, suivi) : section 4 ;
- **mini-boss** et Grondin, **mode tactique**, menu pause et options ;
- Hautepierre (13 → 30) et les variantes corrompues ;
- métiers étendus et récolte rare ; panoplies.
