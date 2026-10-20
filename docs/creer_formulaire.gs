/**
 * Retro Venture — crée le questionnaire de l'alpha test 1 dans Google Forms (contenu :
 * docs/FORMULAIRE_ALPHA1.md ; version 2 : questions sur les mécaniques des Voies).
 *
 * Mode d'emploi (une seule fois, avec le compte Google qui doit posséder le formulaire) :
 *   1. Aller sur https://script.google.com → « Nouveau projet ».
 *   2. Remplacer tout le code par ce fichier, enregistrer.
 *   3. Choisir la fonction « creerFormulaire » et cliquer sur « Exécuter » ; accepter les
 *      autorisations demandées (création de formulaires dans votre Drive).
 *   4. Le « Journal d'exécution » affiche le lien des testeurs et le lien d'édition. Le
 *      formulaire est aussi dans votre Drive (« Retro Venture — Questionnaire alpha test 1 »).
 *   5. Ouvrir le lien des testeurs dans une fenêtre privée pour vérifier, puis donner ce lien à
 *      Claude pour le mettre dans le jeu (Session.FEEDBACK_URL) et le guide des testeurs.
 */

function creerFormulaire() {
  var form = FormApp.create('Retro Venture — Questionnaire alpha test 1');
  form.setDescription(
    "Merci d'avoir testé Retro Venture ! Ce questionnaire prend une dizaine de minutes. " +
    "Cet alpha test porte sur les mécaniques (combat, quêtes, exploration, interface, métiers) : " +
    "l'expérience est volontairement accélérée (×3,5) et il n'y a ni son ni dessins définitifs. " +
    "Répondez même si vous n'avez joué qu'un moment, et n'hésitez pas à remplir le formulaire " +
    "une fois par personnage.");
  form.setCollectEmail(false);
  form.setProgressBar(true);
  form.setAllowResponseEdits(false);
  form.setLimitOneResponsePerUser(false);
  form.setConfirmationMessage("Merci ! Vos retours vont directement façonner l'alpha test 2.");

  var echelle5 = function (titre, bas, haut, obligatoire) {
    form.addScaleItem().setTitle(titre).setBounds(1, 5).setLabels(bas, haut).setRequired(!!obligatoire);
  };
  var choix = function (titre, options, obligatoire, autre) {
    var item = form.addMultipleChoiceItem().setTitle(titre).setChoiceValues(options).setRequired(!!obligatoire);
    if (autre) item.showOtherOption(true);
  };
  var cases = function (titre, options) {
    form.addCheckboxItem().setTitle(titre).setChoiceValues(options);
  };
  var court = function (titre, aide) {
    var item = form.addTextItem().setTitle(titre);
    if (aide) item.setHelpText(aide);
  };
  var long = function (titre, aide) {
    var item = form.addParagraphTextItem().setTitle(titre);
    if (aide) item.setHelpText(aide);
  };
  var section = function (titre) {
    form.addPageBreakItem().setTitle(titre);
  };

  // 1. Vous et votre partie (première page).
  form.addSectionHeaderItem().setTitle('1. Vous et votre partie');
  court('Pseudo', 'Pour vous recontacter si besoin (facultatif).');
  choix('Avez-vous déjà joué à Dofus (ou Dofus Rétro) ?', ['Oui, beaucoup', 'Un peu', 'Jamais'], true);
  choix('Jouez-vous souvent à des jeux tactiques au tour par tour ?', ['Souvent', 'Parfois', 'Rarement', 'Jamais']);
  choix('Navigateur', ['Chrome', 'Firefox', 'Edge', 'Safari'], true, true);
  choix('Combien de temps avez-vous joué ?', ['Moins de 30 min', '30 min à 1 h', '1 à 2 h', '2 à 4 h', 'Plus de 4 h'], true);
  choix('Race du personnage', ['Humain', 'Gobelin', 'Elfe'], true);
  choix('Voie (classe)', ['Guerrier', 'Rôdeur', 'Arcaniste', 'Théologue'], true);
  court('Niveau atteint');
  choix("Jusqu'où êtes-vous allé dans l'histoire ?",
    ['Tutoriel', 'Acte I (zone de départ)', 'Mini-boss de la zone vaincu', 'Acte II (Hautepierre)',
     'Le Conseil des Peuples Libres', 'La Brèche (Grondin vaincu)'], true);

  section('2. Prise en main');
  echelle5("Le tutoriel vous a-t-il appris l'essentiel ?", 'Pas du tout', 'Tout à fait', true);
  choix('Avez-vous eu besoin du guide des testeurs ?', ['Jamais', 'Parfois', 'Souvent', "Je ne l'ai pas lu"]);
  long("Qu'est-ce qui vous a manqué pour comprendre le jeu au début ?");

  section('3. Combat');
  echelle5('Les combats sont-ils compréhensibles (portées, PA/PM, ordre de jeu, effets) ?', 'Confus', 'Très clairs', true);
  echelle5('Difficulté générale', 'Trop facile', 'Trop dur', true);
  choix('Durée des combats', ['Trop courts', 'Bien', 'Un peu longs', 'Beaucoup trop longs']);
  cases('Mini-boss affrontés', ['Krasbouk', 'Balourd des Abîmes', 'Mère-Toile', 'Grondin', 'Aucun']);
  long("Un mini-boss vous a-t-il bloqué ? Lequel, à quel niveau, en combien d'essais ?");
  choix('Avez-vous utilisé le mode tactique (touche T) ?',
    ['Oui, tout le temps', 'Parfois', "Non, je ne l'ai pas trouvé", 'Non, pas besoin']);
  long('Votre Voie vous a-t-elle semblé trop faible, trop forte, ou bien ? Pourquoi ?');
  echelle5("La mécanique propre à votre Voie (Charge du Guerrier, Collet du Rôdeur, Absolution du Théologue, états élémentaires de l'Arcaniste) vous a-t-elle plu ?",
    'Pas du tout', 'Beaucoup');
  cases("Si vous avez joué l'Arcaniste : composer ses états (Braise, Frimas) puis Créer un sort, c'était…",
    ['Clair', 'Confus au début', 'Amusant', 'Trop long à préparer', "Je n'ai pas joué l'Arcaniste"]);
  choix("Quel élément aimeriez-vous voir rejoindre la Flamme et le Givre de l'Arcaniste ?",
    ['Tempête', 'Acier', 'Sacré', 'Impie'], false, true);
  choix("Avez-vous utilisé l'historique du combat (en bas à gauche, touche H) ?",
    ['Oui, souvent', 'Parfois', "Non, je ne l'ai pas vu", 'Non, pas besoin']);
  long('Un sort ou un effet incompris ou inutile ?');

  section('4. Quêtes et histoire');
  echelle5('Saviez-vous quoi faire et où aller ?', 'Jamais', 'Toujours', true);
  echelle5('Les textes (dialogues, quêtes, objets) vous ont-ils fait sourire ?', 'Pas du tout', 'Beaucoup', true);
  echelle5('Le journal (Q) et le suivi sous la minicarte vous ont-ils aidé ?', 'Pas du tout', 'Beaucoup');
  court('Votre quête préférée, et pourquoi ?');
  long('Une quête vous a-t-elle bloqué ou semblé injuste ? Laquelle ?');
  choix('Avez-vous visité les zones des autres camps ?', ['Oui', 'Non', "Je ne savais pas que c'était possible"]);

  section('5. Exploration et interface');
  echelle5('Les cartes se lisent-elles bien (où marcher, sorties, portes, ce qui est cliquable) ?', 'Mal', 'Très bien', true);
  echelle5('La minicarte et la carte du monde (M) vous ont-elles aidé à vous orienter ?', 'Pas du tout', 'Beaucoup');
  long('Fenêtres les plus utiles ou les plus pénibles',
    'Inventaire, fiche, sorts, métiers, journal, boutique, atelier…');
  long('Un clic, une fenêtre ou un raccourci qui ne réagissait pas comme prévu ?');

  section('6. Progression, économie, métiers');
  choix('Rythme de montée en niveau', ['Trop rapide', 'Bien', 'Trop lent'], true);
  echelle5('Les écus, les prix des marchands et les récompenses vous ont-ils semblé cohérents ?', 'Pas du tout', 'Tout à fait');
  choix('Avez-vous utilisé les métiers (récolte, forge) ?', ['Beaucoup', 'Un peu', 'Pas du tout']);
  choix('Avez-vous obtenu une ressource rare (« Rare ! ») ou fabriqué une recette améliorée ?', ['Oui', 'Non']);
  long('Équipement et panoplies : des remarques ?');

  section('7. Bugs');
  choix('Avez-vous rencontré un bug ?', ['Non', 'Oui, gênant', 'Oui, bloquant']);
  long('Décrivez-le',
    "Ce que vous faisiez (carte, combat, quête), ce qui s'est passé, ce que vous attendiez, s'il revient en recommençant.");
  court("Lien vers une capture d'écran (si vous en avez une)");

  section('8. Bilan');
  form.addScaleItem().setTitle('Note globale de cette version').setBounds(1, 10)
    .setLabels('Décevant', 'Excellent').setRequired(true);
  choix("Auriez-vous envie de jouer à la suite (alpha test 2 : vraie progression, sorts par niveau, dessins et son) ?",
    ['Oui', 'Peut-être', 'Non'], true);
  long('Ce que vous avez préféré');
  long("Ce qu'il faut changer en priorité");
  long('Un dernier mot ?');

  // Réponses ouvertes à toute personne disposant du lien.
  form.setAcceptingResponses(true);
  try {
    form.setPublished(true);  // Nouveau modèle de publication de Google Forms.
  } catch (e) {
    Logger.log('Publication automatique impossible : cliquez sur « Publier » dans le formulaire.');
  }

  Logger.log('Lien des testeurs : ' + form.getPublishedUrl());
  Logger.log("Lien d'édition : " + form.getEditUrl());
}
