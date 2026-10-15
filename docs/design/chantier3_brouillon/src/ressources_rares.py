"""Ressources rares de récolte et recettes améliorées (demande de l'auteur, après le chantier 3).

    python3 src/ressources_rares.py      (depuis docs/design/chantier3_brouillon)

Chaque bois et chaque minerai a sa version rare : 1 % de chance par récolte d'en obtenir un exemplaire
à la place de la récolte normale (`Profession.RARE_CHANCE`). Ce script écrit les 10 ressources rares,
le champ `rare` des nœuds de récolte, 6 recettes améliorées du forgeron (qui utilisent toutes les
ressources rares) et leurs objets, les icônes (celles des ressources rares reprennent l'icône de
base avec un halo doré) et le fragment de manifeste `ressources_rares`. Relancer le réécrit.
"""
import json
import os

ICI = os.path.dirname(os.path.abspath(__file__))
JEU = os.path.normpath(os.path.join(ICI, "..", "..", "..", "..", "game"))

# Ressource de base → (id rare, nom, description).
RARES = {
    "bois_de_frene": ("coeur_de_frene", "Cœur de frêne", "Le centre d'un frêne qui a tenu trois tempêtes. Il en garde la souplesse, et la rancune."),
    "bois_de_chene": ("chene_des_anciens", "Chêne des Anciens", "Une bûche si vieille qu'elle se souvient de l'Âge de l'Aube. Elle refuse d'en parler."),
    "bois_d_if": ("if_funebre", "If funèbre", "Il pousse près des tombes. Les archers l'adorent ; les fossoyeurs, moins."),
    "bois_de_hetre": ("hetre_centenaire", "Hêtre centenaire", "Cent ans de patience dans chaque cerne. Il se fend quand il l'a décidé."),
    "bois_de_malorme": ("malorme_ensorcelee", "Malorme ensorcelée", "Ses feuilles dorées chuchotent. Ce qu'elles disent n'est pas très gentil."),
    "minerai_de_cuivre": ("cuivre_vert_de_gris", "Cuivre vert-de-gris", "Un cuivre qui a pris l'air pendant un siècle. Il a de la patine, et de l'opinion."),
    "minerai_de_fer": ("fer_meteorique", "Fer météorique", "Tombé du ciel il y a longtemps. Les gobelins disent que c'était une réclamation."),
    "minerai_d_etain": ("etain_chantant", "Étain chantant", "Il crie quand on le plie. Les forgerons trouvent ça touchant ; les voisins, non."),
    "minerai_d_argent": ("argent_lunaire", "Argent lunaire", "Il brille même la nuit, surtout la nuit. Les loups le regardent bizarrement."),
    "obsidienne": ("obsidienne_sanglante", "Obsidienne sanglante", "Un verre noir veiné de rouge. Il coupe, et il a l'air content de couper."),
}

RECETTES = [
    ({"id": "anneau_vert_de_gris", "nom": "Anneau vert-de-gris", "type": "anneau", "rarete": "rare", "niveau": 5,
      "description": "Il verdit les doigts et porte chance. Les deux sont liés, assure le forgeron.",
      "bonus": {"chance": [4, 6], "agilite": [4, 6], "prospection": [8, 12]}},
     {"cuivre_vert_de_gris": 1, "minerai_de_cuivre": 6, "croc_de_loup": 3}, 30),
    ({"id": "arc_coeur_de_frene", "nom": "Arc du Cœur de frêne", "type": "arme", "rarete": "rare", "niveau": 7,
      "description": "Taillé dans le cœur d'un frêne têtu : il plie, mais c'est lui qui décide quand.",
      "bonus": {"agilite": [6, 9], "initiative": [15, 22]},
      "attaque": {"cout_pa": 4, "portee": {"min": 2, "max": 6}, "ligne_de_vue": True, "relance": {"par_tour": 1},
                  "effets": [{"type": "degats", "element": "tempete", "min": 9, "max": 13}]}},
     {"coeur_de_frene": 1, "bois_de_frene": 8, "peau_de_loup": 2}, 40),
    ({"id": "masse_meteorique", "nom": "Masse météorique", "type": "arme", "rarete": "rare", "niveau": 12,
      "description": "Une tête de fer tombée du ciel sur un manche de chêne des Anciens. Elle retombe souvent.",
      "bonus": {"force": [8, 12], "vitalite": [8, 12], "dommages": [1, 1]},
      "attaque": {"cout_pa": 4, "portee": {"min": 1, "max": 1}, "relance": {"par_tour": 1},
                  "effets": [{"type": "degats", "element": "acier", "min": 14, "max": 20}]}},
     {"fer_meteorique": 1, "chene_des_anciens": 1, "minerai_de_fer": 8}, 60),
    ({"id": "amulette_chantante", "nom": "Amulette chantante", "type": "amulette", "rarete": "epique", "niveau": 14,
      "description": "Étain chantant et if funèbre : elle fredonne des airs d'enterrement, juste assez faux.",
      "bonus": {"intelligence": [8, 11], "sagesse": [4, 6], "vitalite": [8, 12]}},
     {"etain_chantant": 1, "if_funebre": 1, "minerai_d_etain": 6, "fil_de_brume": 2}, 70),
    ({"id": "epee_lunaire", "nom": "Épée lunaire", "type": "arme", "rarete": "epique", "niveau": 20,
      "description": "Une lame d'argent lunaire sur une garde de hêtre centenaire. Elle éclaire le chemin, et la cible.",
      "bonus": {"force": [9, 13], "vitalite": [6, 9], "critique": [2, 3]},
      "attaque": {"cout_pa": 4, "portee": {"min": 1, "max": 1}, "relance": {"par_tour": 1},
                  "effets": [{"type": "degats", "element": "acier", "min": 17, "max": 24}]}},
     {"argent_lunaire": 1, "hetre_centenaire": 1, "minerai_d_argent": 6}, 90),
    ({"id": "sceptre_de_malorme", "nom": "Sceptre de malorme", "type": "arme", "rarete": "epique", "niveau": 26,
      "description": "Malorme ensorcelée et obsidienne sanglante : il murmure des sorts que personne ne lui a appris.",
      "bonus": {"intelligence": [12, 16], "sagesse": [5, 7], "dommages": [1, 2]},
      "attaque": {"cout_pa": 4, "portee": {"min": 1, "max": 3}, "relance": {"par_tour": 1},
                  "effets": [{"type": "degats", "element": "flamme", "min": 16, "max": 23}]}},
     {"malorme_ensorcelee": 1, "obsidienne_sanglante": 1, "bois_de_malorme": 6, "obsidienne": 4}, 120),
]
ICONES_ARMES = {"arc_coeur_de_frene": "sort_arme_arc", "masse_meteorique": "sort_arme_masse",
                "epee_lunaire": "sort_arme_epee", "sceptre_de_malorme": "sort_arme_sceptre"}

O = "#2a1c10"
OMBRE = '<ellipse cx="22" cy="39.5" rx="13" ry="2.6" fill="#000000" fill-opacity="0.18"/>'
# Halo doré et étincelles ajoutés à l'icône de base d'une ressource rare.
HALO = ('<circle cx="22" cy="22" r="19" fill="#ffd860" fill-opacity="0.16"/>'
        '<path d="M36 4 L37.4 8.6 L42 10 L37.4 11.4 L36 16 L34.6 11.4 L30 10 L34.6 8.6 Z" fill="#fff4b0" stroke="#c9a04e" stroke-width="0.6"/>'
        '<path d="M7 28 L7.8 30.2 L10 31 L7.8 31.8 L7 34 L6.2 31.8 L4 31 L6.2 30.2 Z" fill="#fff4b0" stroke="#c9a04e" stroke-width="0.5"/>')
ICONES = {
    "anneau_vert_de_gris": f'<ellipse cx="22" cy="26" rx="12" ry="10" fill="none" stroke="{O}" stroke-width="5.6"/><ellipse cx="22" cy="26" rx="12" ry="10" fill="none" stroke="#5aa88a" stroke-width="3.4"/><circle cx="22" cy="15" r="4.6" fill="#c07a3a" stroke="{O}" stroke-width="1.2"/><path d="M14 30 L16 28 M28 31 L30 29" stroke="#8ad8b8" stroke-width="1.2"/>',
    "arc_coeur_de_frene": f'<path d="M12 6 Q34 22 12 38" stroke="{O}" stroke-width="5" fill="none" stroke-linecap="round"/><path d="M12 6 Q34 22 12 38" stroke="#c8a46a" stroke-width="3.2" fill="none" stroke-linecap="round"/><path d="M12 6 L12 38" stroke="#efe8da" stroke-width="1.2"/><circle cx="23.5" cy="22" r="2.6" fill="#7ab84a" stroke="{O}" stroke-width="0.8"/>',
    "masse_meteorique": f'<path d="M10 40 L22 20" stroke="{O}" stroke-width="5" stroke-linecap="round"/><path d="M10 40 L22 20" stroke="#6a4a2a" stroke-width="3" stroke-linecap="round"/><circle cx="26" cy="14" r="9" fill="#3a3640" stroke="{O}" stroke-width="1.4"/><path d="M21 10 L24 14 L22 18 M28 8 L30 13 L34 15" stroke="#e2622a" stroke-width="1.4" fill="none"/>',
    "amulette_chantante": f'<path d="M10 4 Q22 22 34 4" stroke="#a8a8a0" stroke-width="1.6" fill="none"/><ellipse cx="22" cy="26" rx="8" ry="10" fill="#c8c8c0" stroke="{O}" stroke-width="1.4"/><path d="M19 22 L19 30 M19 22 L25 20 L25 28" stroke="#2a2420" stroke-width="1.2" fill="none"/><circle cx="18" cy="30" r="1.6" fill="#2a2420"/><circle cx="24" cy="28" r="1.6" fill="#2a2420"/>',
    "epee_lunaire": f'<path d="M34 6 L37 9 L18 28 L15 25 Z" fill="#f4f8ff" stroke="{O}" stroke-width="1.4" stroke-linejoin="round"/><path d="M12 22 L22 32" stroke="{O}" stroke-width="4" stroke-linecap="round"/><path d="M12 22 L22 32" stroke="#a8a8a0" stroke-width="2.2" stroke-linecap="round"/><path d="M16 28 L9 35" stroke="{O}" stroke-width="3.6" stroke-linecap="round"/><path d="M16 28 L9 35" stroke="#c8b898" stroke-width="2" stroke-linecap="round"/><path d="M30 8 Q34 4 36 8 Q32 7 30 8 Z" fill="#fff8d0"/>',
    "sceptre_de_malorme": f'<path d="M10 40 L28 12" stroke="{O}" stroke-width="4.4" stroke-linecap="round"/><path d="M10 40 L28 12" stroke="#e0b830" stroke-width="2.6" stroke-linecap="round"/><path d="M28 4 L34 10 L30 16 L24 10 Z" fill="#141018" stroke="{O}" stroke-width="1.2"/><path d="M28 6 L30 14" stroke="#c0302a" stroke-width="1.2"/>',
}


def ecrire(chemin, donnees):
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(donnees, f, ensure_ascii=False, indent=2)
        f.write("\n")


def lire(chemin):
    with open(chemin, encoding="utf-8") as f:
        return json.load(f)


def main():
    images = {}
    for base, (rid, nom, desc) in RARES.items():
        base_obj = lire(os.path.join(JEU, "data", "objets", base + ".json"))
        ecrire(os.path.join(JEU, "data", "objets", rid + ".json"),
               {"id": rid, "nom": nom, "type": "ressource", "rarete": "rare", "niveau": base_obj.get("niveau", 1),
                "description": desc, "boutique": False})
        with open(os.path.join(JEU, "art", "objets", base + ".svgt"), encoding="utf-8") as f:
            svg = f.read()
        with open(os.path.join(JEU, "art", "objets", rid + ".svgt"), "w", encoding="utf-8") as f:
            f.write(svg.replace("</svg>", HALO + "\n</svg>"))
        images["objet_" + rid] = {"fichier": f"objets/{rid}.svgt", "ancre": [22, 22]}
    for metier in ("bucheron", "mineur"):
        chemin = os.path.join(JEU, "data", "metiers", metier + ".json")
        m = lire(chemin)
        for r in m["ressources"]:
            if r["objet"] in RARES:
                r["rare"] = RARES[r["objet"]][0]
        ecrire(chemin, m)
    chemin = os.path.join(JEU, "data", "metiers", "forgeron.json")
    forge = lire(chemin)
    nouveaux = {o["id"] for o, _, _ in RECETTES}
    forge["recettes"] = [r for r in forge["recettes"] if r["objet"] not in nouveaux]
    for objet, ingredients, xp in RECETTES:
        # Ni les ressources rares ni ce qu'on en tire ne se vendent en boutique : il faut récolter.
        ecrire(os.path.join(JEU, "data", "objets", objet["id"] + ".json"), dict(objet, boutique=False))
        forge["recettes"].append({"objet": objet["id"], "niveau": objet["niveau"], "xp": xp, "ingredients": ingredients})
        with open(os.path.join(JEU, "art", "objets", objet["id"] + ".svgt"), "w", encoding="utf-8") as f:
            f.write(f'<svg xmlns="http://www.w3.org/2000/svg" width="44" height="44" viewBox="0 0 44 44">\n{OMBRE}\n{ICONES[objet["id"]]}\n</svg>\n')
        images["objet_" + objet["id"]] = {"fichier": f"objets/{objet['id']}.svgt", "ancre": [22, 22]}
    ecrire(chemin, forge)
    ecrire(os.path.join(JEU, "art", "manifestes", "ressources_rares.json"), {"images": images, "icones_armes": ICONES_ARMES})
    print(f"{len(RARES)} ressources rares, {len(RECETTES)} recettes améliorées")


if __name__ == "__main__":
    main()
