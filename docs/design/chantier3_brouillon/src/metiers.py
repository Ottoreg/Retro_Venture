"""Métiers : nouvelles essences, nouveaux minerais, recettes de forgeron, panoplies."""
from common import *

# ---------- ressources de récolte ----------
ressource("bois_d_if", "Bois d'if", "peu_commun", "Sombre, souple, toxique. Les rôdeurs l'adorent, les chèvres beaucoup moins.",
          "recolte:bucheron (Y)", "bûche sombre rouge-brun, quelques aiguilles vert foncé et une baie rouge")
ressource("bois_de_hetre", "Bois de hêtre", "peu_commun", "Blond, dur, régulier. On en fait des manches, des tables et des excuses.",
          "recolte:bucheron (H)", "bûche claire à écorce grise lisse, deux feuilles vert vif")
ressource("bois_de_malorme", "Bois de malorme", "rare", "Un orme aux feuilles d'or. Les elfes jurent qu'ils l'ont vu en premier.",
          "recolte:bucheron (L)", "bûche à écorce argentée, feuilles dorées scintillantes")
ressource("minerai_d_etain", "Minerai d'étain", "commun", "Il crie quand on le tord. Si, si : écoutez bien.",
          "recolte:mineur (T)", "pierre grise à veines blanc mat")
ressource("minerai_d_argent", "Minerai d'argent", "peu_commun", "Brillant, précieux, et mortel pour les choses qui ne devraient pas exister.",
          "recolte:mineur (G)", "pierre sombre à veines blanc argent brillant, petit éclat")
ressource("obsidienne", "Obsidienne", "rare", "Verre de volcan. Elle coupe mieux que l'acier et se casse mieux que le verre.",
          "recolte:mineur (D)", "éclat de verre noir aux reflets violets, arête tranchante")

NOEUDS = [
    {"metier": "bucheron", "marqueur": "Y", "nom": "If", "objet": "bois_d_if", "niveau": 8, "quantite": [1, 2], "xp": 12,
     "repousse": [90, 150], "apparence": "arbre", "couleur": "1e4a2a", "image": "if",
     "image_manifeste": {"fichier": "decor/arbre_haut.svgt", "ancre": [36, 114], "couleurs": {"feuillage": "2a5a34", "feuillage_ombre": "1a3e24", "feuillage_clair": "3e7a46", "tronc": "6a3a2a"}},
     "zones": ["brumerive (7–12)", "sylvebrume (4–12)", "hautepierre (13–21)"]},
    {"metier": "bucheron", "marqueur": "H", "nom": "Hêtre", "objet": "bois_de_hetre", "niveau": 15, "quantite": [1, 2], "xp": 18,
     "repousse": [90, 150], "apparence": "arbre", "couleur": "8ab84a", "image": "hetre",
     "image_manifeste": {"fichier": "decor/arbre_large.svgt", "ancre": [50, 106], "couleurs": {"feuillage": "8ab84a", "feuillage_ombre": "6a9a3a", "feuillage_clair": "aad46a", "tronc": "a8a8a0"}},
     "zones": ["hautepierre (16–24)"]},
    {"metier": "bucheron", "marqueur": "L", "nom": "Malorme", "objet": "bois_de_malorme", "niveau": 22, "quantite": [1, 2], "xp": 25,
     "repousse": [120, 180], "apparence": "arbre", "couleur": "e0b830", "image": "malorme",
     "image_manifeste": {"fichier": "decor/arbre_haut.svgt", "ancre": [36, 114], "couleurs": {"feuillage": "e0b830", "feuillage_ombre": "b88a20", "feuillage_clair": "f8e070", "tronc": "c8c8c0"}},
     "zones": ["hautepierre (19–30)"]},
    {"metier": "mineur", "marqueur": "T", "nom": "Étain", "objet": "minerai_d_etain", "niveau": 8, "quantite": [1, 2], "xp": 12,
     "repousse": [90, 150], "apparence": "rocher", "couleur": "d8d8d0", "image": "minerai_etain",
     "image_manifeste": {"fichier": "decor/minerai.svgt", "ancre": [25, 32], "couleurs": {"veine": "e0e0d8"}},
     "zones": ["brumerive (7–12)", "crasse_roc (4–12)", "sylvebrume (10–12)", "hautepierre (13–18)"]},
    {"metier": "mineur", "marqueur": "G", "nom": "Argent", "objet": "minerai_d_argent", "niveau": 15, "quantite": [1, 2], "xp": 18,
     "repousse": [90, 150], "apparence": "rocher", "couleur": "f4f8ff", "image": "minerai_argent",
     "image_manifeste": {"fichier": "decor/minerai.svgt", "ancre": [25, 32], "couleurs": {"veine": "f4f8ff"}},
     "zones": ["hautepierre (16–27)"]},
    {"metier": "mineur", "marqueur": "D", "nom": "Obsidienne", "objet": "obsidienne", "niveau": 22, "quantite": [1, 2], "xp": 25,
     "repousse": [120, 180], "apparence": "rocher", "couleur": "6a3a8a", "image": "minerai_obsidienne",
     "image_manifeste": {"fichier": "decor/minerai.svgt", "ancre": [25, 32], "couleurs": {"veine": "6a3a8a"}},
     "zones": ["hautepierre (22–30, cartes cendrées)"]},
]

# ---------- objets fabriqués ----------
equipement("anneau_d_etain", "Anneau d'étain", "anneau", "commun", 8,
            "Il crie quand on le tord. Évitez de vous ronger les ongles en le portant.",
            {"vitalite": 0.5, "sagesse": 0.5}, "recette", "anneau gris mat, petite encoche gravée")
equipement("arc_d_if", "Arc d'if", "arme", "peu_commun", 10,
           "Un vrai arc, cette fois. Taillé par quelqu'un qui en avait vu plus d'un.",
           {"agilite": 0.7, "initiative": 0.3}, "recette", "arc long sombre rouge-brun, corde de fil de brume argentée",
           attaque=attaque(10, "peu_commun", "tempete", 4, (2, 6)))
equipement("baton_gele", "Bâton gelé", "arme", "peu_commun", 11,
           "Un bâton d'if cerclé d'étain, couvert de givre en permanence. Ne pas lécher.",
           {"perception": 0.7, "sagesse": 0.3}, "recette", "bâton d'if cerclé d'étain, cristaux de givre bleu au sommet",
           attaque=attaque(11, "peu_commun", "givre", 3, (1, 4), par_tour=2))
equipement("epee_d_argent", "Épée d'argent", "arme", "rare", 15,
           "Brillante et tranchante. Les Corrompus détestent son reflet.",
           {"force": 0.6, "vitalite": 0.2, "sagesse": 0.2}, "recette", "épée droite à lame d'argent brillante, garde en croix noire",
           attaque=attaque(15, "rare", "acier", 4, (1, 1)))
equipement("amulette_d_argent", "Amulette d'argent", "amulette", "peu_commun", 16,
           "Une médaille d'argent à l'effigie d'un héros inconnu. Peut-être vous, un jour. Peut-être pas.",
           {"vitalite": 0.4, "force": 0.2, "intelligence": 0.2, "perception": 0.2}, "recette",
           "médaille ronde d'argent au profil gravé, chaîne fine")
equipement("sceptre_de_hautepierre", "Sceptre de Hautepierre", "arme", "rare", 18,
           "Surmonté d'une petite Tour Blanche en argent. Béni par Frère Bénitier, pouce compris.",
           {"force": 0.3, "intelligence": 0.3, "sagesse": 0.2, "vitalite": 0.2}, "recette",
           "sceptre d'argent surmonté d'une tour blanche miniature, ruban bleu",
           attaque=attaque(18, "rare", "sacre", 4, (1, 2)))
equipement("heaume_d_argent", "Heaume d'argent", "coiffe", "rare", 20,
           "Le casque des officiers de Hautepierre. Les miliciens le saluent par réflexe.",
           {"vitalite": 0.5, "force": 0.3, "sagesse": 0.2}, "recette", "heaume d'argent poli à nasal, petit plumet bleu")
equipement("dague_d_obsidienne", "Dague d'obsidienne", "arme", "rare", 23,
           "Noire, tranchante, fragile. Comme le caractère de celui qui l'a forgée.",
           {"agilite": 0.4, "perception": 0.4, "critique": 0.2}, "recette", "dague à lame de verre noir aux reflets violets, manche de malorme doré",
           attaque=attaque(23, "rare", "impie", 3, (1, 1), par_tour=2))
equipement("arc_de_malorme", "Arc de malorme", "arme", "rare", 25,
           "Doré, léger, parfait. Les elfes prétendent qu'il est mal fait, par principe.",
           {"agilite": 0.6, "initiative": 0.2, "sagesse": 0.2}, "recette",
           "arc long doré aux branches fines, corde de soie argentée",
           attaque=attaque(25, "rare", "tempete", 4, (2, 7)))
equipement("ceinture_d_obsidienne", "Ceinture d'obsidienne", "ceinture", "rare", 27,
           "Des plaques de verre noir sur du cuir d'olifant. Elle tinte quand on court.",
           {"vitalite": 0.5, "intelligence": 0.25, "perception": 0.25}, "recette",
           "ceinture de cuir gris à plaques d'obsidienne violettes, boucle en corne")

RECETTES = [
    {"objet": "anneau_forgeron_hargneux", "niveau": 4, "xp": 20, "ingredients": {"minerai_de_fer": 3, "minerai_de_cuivre": 3, "croc_de_loup": 2}},
    {"objet": "amulette_forgeron_hargneux", "niveau": 5, "xp": 24, "ingredients": {"minerai_de_fer": 4, "peau_de_loup": 2, "dent_de_rat": 2}},
    {"objet": "coiffe_forgeron_hargneux", "niveau": 6, "xp": 28, "ingredients": {"minerai_de_fer": 5, "bois_de_chene": 2, "carapace_de_grouilleur": 3}},
    {"objet": "anneau_d_etain", "niveau": 8, "xp": 32, "ingredients": {"minerai_d_etain": 5, "minerai_de_cuivre": 2}},
    {"objet": "arc_d_if", "niveau": 10, "xp": 38, "ingredients": {"bois_d_if": 6, "fil_de_brume": 3, "aile_de_vampipistrelle": 2}},
    {"objet": "baton_gele", "niveau": 11, "xp": 40, "ingredients": {"bois_d_if": 5, "minerai_d_etain": 3, "spores_grincheuses": 1}},
    {"objet": "epee_d_argent", "niveau": 15, "xp": 55, "ingredients": {"minerai_d_argent": 6, "bois_de_hetre": 2, "maillon_de_cotte": 4}},
    {"objet": "amulette_d_argent", "niveau": 16, "xp": 58, "ingredients": {"minerai_d_argent": 4, "dent_de_troll": 3, "bourse_vide": 2}},
    {"objet": "sceptre_de_hautepierre", "niveau": 18, "xp": 65, "ingredients": {"minerai_d_argent": 5, "bois_de_hetre": 3, "ecusson_de_milice": 2, "ordre_de_raid": 1}},
    {"objet": "heaume_d_argent", "niveau": 20, "xp": 72, "ingredients": {"minerai_d_argent": 6, "maillon_de_cotte": 6, "plume_de_corbac": 3}},
    {"objet": "dague_d_obsidienne", "niveau": 23, "xp": 82, "ingredients": {"obsidienne": 5, "bois_de_malorme": 2, "crochet_d_araignee": 3, "eclat_de_cendre": 1}},
    {"objet": "arc_de_malorme", "niveau": 25, "xp": 90, "ingredients": {"bois_de_malorme": 6, "soie_de_la_mere_toile": 1, "plume_de_corbac": 4}},
    {"objet": "ceinture_d_obsidienne", "niveau": 27, "xp": 98, "ingredients": {"obsidienne": 6, "cuir_d_olifant": 3, "corne_du_balourd": 1}},
]

PANOPLIES = [
    ("forgeron_hargneux", "Forgeron Hargneux (Acier)", "Recettes de forgeron : anneau (niv. 4), amulette (5), coiffe (6). Butin du Milicien de Hautepierre (Crasse-Roc 7–9) : cape, ceinture, bottes (3 %, 9–13 % sur le Sergent)."),
    ("pyromane_repenti", "Pyromane Repenti (Flamme)", "Épouvantail démotivé (Brumerive 7–9 : il garde ces pièces « pour se rassurer ») : coiffe, cape, amulette ; Contremaître zélé (Crasse-Roc 10–12) : anneau, ceinture, bottes (3 % chacune)."),
    ("bonhomme_de_neige", "Bonhomme de Neige (Givre)", "Tisseuse de brume (Sylvebrume 10–12) : coiffe, cape, amulette ; Vampipistrelle (Crasse-Roc 4–6) : anneau, ceinture, bottes (3 %)."),
    ("courant_d_air", "Courant d'Air (Tempête)", "Cerf enchanté (Sylvebrume 4–6) : coiffe, cape, amulette (3 %) ; Gobelin frondeur (Brumerive 4–6) : anneau, ceinture, bottes (2 %)."),
    ("enfant_de_choeur", "Enfant de Chœur (Sacré)", "Gobelin pillard (Brumerive 7–9, volées à la chapelle) : coiffe, cape, amulette ; Bûcheron de Brumerive (Sylvebrume 7–9, il chante à la chorale le dimanche) : anneau, ceinture, bottes (3 %)."),
    ("mauvais_oeil", "Mauvais Œil (Impie)", "Morille grincheuse (Sylvebrume 1–3) : coiffe, cape, amulette ; Loup des collines (Brumerive 1–3) : anneau, ceinture, bottes (2 %)."),
    ("presse", "Pressé (Initiative, 3 pièces)", "Grouilleur (Crasse-Roc 1–3, beaucoup de pattes, toujours pressé) : anneau, bottes, ceinture (2 %, 6 % sur l'Ancestral)."),
    ("fouineur", "Fouineur (Prospection, 3 pièces)", "Rat des galeries (Crasse-Roc 1–3) : coiffe, amulette, cape (2 %, 6 % sur le Rat-roi)."),
]
PANOPLIES_REGLE = ("Les 8 panoplies restent en vente chez les marchands (jets fixes de niveau 3). En plus, chacune s'obtient **sans marchand** : "
                   "chaque panoplie élémentaire est partagée entre **deux familles de deux zones différentes** (3 pièces chacune), et le Forgeron Hargneux se fabrique à moitié. "
                   "Chaque race trouve ainsi 3 à 4 panoplies chez elle et doit voyager (Pierres de Passage) pour compléter les autres. Les élites lâchent ces pièces 3 fois plus souvent.")


def MARKDOWN():
    L = ["## 9. Métiers", "",
         "Trois nouvelles essences et trois nouveaux minerais, aux niveaux de métier 8, 15 et 22 (XP de métier : 5·n·(n−1) ; ~40 récoltes pour le niveau 8, ~65 de plus pour le 15, ~70 de plus pour le 22). "
         "Aucun nouveau dessin : chaque ressource réutilise `arbre_haut`, `arbre_large` ou `minerai` avec ses couleurs (entrées `images` + `ressources` du manifeste).", "",
         "| Marqueur | Métier | Ressource | Objet | Niveau | Quantité | XP | Repousse (s) | Image | Où |",
         "|---|---|---|---|---|---|---|---|---|---|"]
    for n in NOEUDS:
        L.append(f"| `{n['marqueur']}` | {n['metier']} | {n['nom']} | `{n['objet']}` | {n['niveau']} | {n['quantite'][0]}–{n['quantite'][1]} | {n['xp']} | {n['repousse'][0]}–{n['repousse'][1]} | `{n['image']}` (#{n['couleur']}) | {', '.join(n['zones'])} |")
    L += ["", "Marqueurs choisis hors de la légende (`. @ 1-9 a-z A M R E : # + * $ = F C U I`) : **Y** (if, *yew*), **H** (hêtre), **L** (malorme), **T** (étain, *tin*), **G** (ar**g**ent), **D** (obsi**d**ienne).", "",
          "### 9.1 Recettes de forgeron (10 existantes + 13 = 23)", "",
          "| Objet | Niveau | XP | Ingrédients |", "|---|---|---|---|"]
    for r in RECETTES:
        L.append(f"| `{r['objet']}` | {r['niveau']} | {r['xp']} | " + ", ".join(f"{v} {k}" for k, v in r["ingredients"].items()) + " |")
    L += ["", "Les recettes utilisent les ressources de monstres de toutes les zones (crocs, carapaces, fils, maillons, plumes, ordres de raid…) et des trophées de mini-boss "
          "(Soie de la Mère-Toile, Corne du Balourd) : fabriquer haut niveau pousse à voyager entre les zones.", "",
          "### 9.2 Panoplies : comment les obtenir sans marchand", "", PANOPLIES_REGLE, ""]
    for pid, nom, txt in PANOPLIES:
        L.append(f"- **{nom}** (`{pid}`) : {txt}")
    L.append("")
    return "\n".join(L)
