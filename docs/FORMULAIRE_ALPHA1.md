# Questionnaire des testeurs — alpha test 1 (version de référence)

Contenu du Google Forms « Retro Venture — Questionnaire alpha test 1 » (version 2, créée par
`creer_formulaire.gs` ; lien d'édition : dans le Drive de l'auteur, et dans le journal d'exécution
du script)
(lien des testeurs : https://docs.google.com/forms/d/e/1FAIpQLSdwoJr5-OnRuVcVNbvRGnjtO4MqxJTUe7SIIbgfeKJlRuYcxQ/viewform,
aussi dans le jeu : « Donner son avis », et dans `client/session.gd`, `Session.FEEDBACK_URL`).

**Création automatique** : le script Apps Script [`creer_formulaire.gs`](creer_formulaire.gs) crée ce
formulaire complet (sections, types, questions obligatoires, publication) dans le Drive du compte
qui l'exécute : https://script.google.com → Nouveau projet → coller le script → exécuter
`creerFormulaire` ; le journal donne le lien des testeurs, à mettre ensuite dans
`Session.FEEDBACK_URL` et le guide. Sinon, ce fichier sert de modèle pour le remplir à la main. Types : *choix unique*, *cases* (plusieurs choix), *échelle*
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
20. La mécanique propre à votre Voie (Charge du Guerrier, Collet du Rôdeur, Absolution du Théologue,
    états élémentaires de l'Arcaniste) vous a-t-elle plu ? — *échelle* : 1 « Pas du tout » … 5
    « Beaucoup »
21. Si vous avez joué l'Arcaniste : composer ses états (Braise, Frimas) puis Créer un sort, c'était…
    — *cases* : Clair / Confus au début / Amusant / Trop long à préparer / Je n'ai pas joué
    l'Arcaniste
22. Quel élément aimeriez-vous voir rejoindre la Flamme et le Givre de l'Arcaniste ? — *choix
    unique* : Tempête / Acier / Sacré / Impie / Autre (« Autre » libre)
23. Avez-vous utilisé l'historique du combat (en bas à gauche, touche H) ? — *choix unique* : Oui,
    souvent / Parfois / Non, je ne l'ai pas vu / Non, pas besoin
24. Un sort ou un effet incompris ou inutile ? — *long*

## 4. Quêtes et histoire

25. ★ Saviez-vous quoi faire et où aller ? — *échelle* : 1 « Jamais » … 5 « Toujours »
26. ★ Les textes (dialogues, quêtes, objets) vous ont-ils fait sourire ? — *échelle* : 1 « Pas du
    tout » … 5 « Beaucoup »
27. Le journal (Q) et le suivi sous la minicarte vous ont-ils aidé ? — *échelle* : 1 … 5
28. Votre quête préférée, et pourquoi ? — *court*
29. Une quête vous a-t-elle bloqué ou semblé injuste ? Laquelle ? — *long*
30. Avez-vous visité les zones des autres camps ? — *choix unique* : Oui / Non / Je ne savais pas que
    c'était possible

## 5. Exploration et interface

31. ★ Les cartes se lisent-elles bien (où marcher, sorties, portes, ce qui est cliquable) ? —
    *échelle* : 1 … 5
32. La minicarte et la carte du monde (M) vous ont-elles aidé à vous orienter ? — *échelle* : 1 … 5
33. Fenêtres les plus utiles ou les plus pénibles (inventaire, fiche, sorts, métiers, journal,
    boutique, atelier) — *long*
34. Un clic, une fenêtre ou un raccourci qui ne réagissait pas comme prévu ? — *long*

## 6. Progression, économie, métiers

35. ★ Rythme de montée en niveau — *choix unique* : Trop rapide / Bien / Trop lent
36. Les écus, les prix des marchands et les récompenses vous ont-ils semblé cohérents ? — *échelle* :
    1 … 5
37. Avez-vous utilisé les métiers (récolte, forge) ? — *choix unique* : Beaucoup / Un peu / Pas du
    tout
38. Avez-vous obtenu une ressource rare (« Rare ! ») ou fabriqué une recette améliorée ? — *choix
    unique* : Oui / Non
39. Équipement et panoplies : des remarques ? — *long*

## 7. Bugs

40. Avez-vous rencontré un bug ? — *choix unique* : Non / Oui, gênant / Oui, bloquant
41. Décrivez-le : ce que vous faisiez (carte, combat, quête), ce qui s'est passé, ce que vous
    attendiez, s'il revient en recommençant — *long*
42. Lien vers une capture d'écran (si vous en avez une) — *court*

## 8. Bilan

43. ★ Note globale de cette version — *échelle* : 1 … 10
44. ★ Auriez-vous envie de jouer à la suite (alpha test 2 : vraie progression, sorts par niveau,
    dessins et son) ? — *choix unique* : Oui / Peut-être / Non
45. Ce que vous avez préféré — *long*
46. Ce qu'il faut changer en priorité — *long*
47. Un dernier mot ? — *long*

---

### Version 2 (identité des Voies)

Formulaire regénéré par `creer_formulaire.gs` après l'ajout des mécaniques de Voie : 4 questions
de plus dans la section 3 (mécanique de sa Voie, composition de l'Arcaniste, élément souhaité pour
l'Arcaniste, historique du combat). Le lien des testeurs change : le reporter dans
`Session.FEEDBACK_URL`, ce document et le guide des testeurs.

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
