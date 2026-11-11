"""Premier donjon (GDD § 12, demande de l'auteur du 11/11/2026, contenu provisoire) : la Grange du Père Fauchard, sous la
ferme de Brumerive (brumerive_1_2). Vestibule qui mène au grenier, à l'étable et au bureau du boss ; épouvantail exclusif,
boss à phases, ressources exclusives, clé forgée sur plan à l'enclume (en attendant le Joaillier).

    python3 docs/design/donjons/produire.py && (cd game && for f in data/cartes/grange_*.json; do python3 tools/placement.py $f --ecrire; done)
"""
import json
import os
import sys

RACINE = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
sys.path.insert(0, os.path.join(RACINE, "docs", "design", "chantier3_brouillon", "src"))
from cartes import JEU, Plan, verifier  # noqa: E402

VESTIBULE = "grange_vestibule"
FERME = "brumerive_1_2"


def ecrire(dossier, contenu):
    with open(os.path.join(JEU, "data", dossier, contenu["id"] + ".json"), "w") as f:
        f.write(json.dumps(contenu, ensure_ascii=False, indent=2) + "\n")


def sort(id, nom, description, pa, portee, effets, par_tour=1, **autres):
    ecrire("sorts", {"id": id, "nom": nom, "description": description, "cout_pa": pa,
                     "portee": {"min": portee[0], "max": portee[1]}, "ligne_de_vue": True, "relance": {"par_tour": par_tour},
                     **autres, "effets": effets})


def degats(mini, maxi, **autres):
    return {"type": "degats", "element": "tempete", "min": mini, "max": maxi, **autres}


sort("malade_eternuement", "Éternuement", "Un éternuement de paille humide : on en reste collé sur place.", 3, (1, 3),
     [degats(6, 9), {"type": "retrait_pm", "min": 1, "max": 1}])
sort("fauchard_faux", "Coup de faux", "Le Père Fauchard fauche tout ce qui dépasse. Vous dépassez.", 4, (1, 1), [degats(14, 20)], par_tour=2)
sort("fauchard_bourrasque", "Bourrasque de grange", "Il ouvre les portes de la grange : le courant d'air fait le reste.", 3, (2, 5),
     [degats(8, 12), {"type": "poussee", "min": 2, "max": 2}])
sort("fauchard_moisson", "Grande moisson", "Un moulinet de faux autour de lui. Rien ne repousse, surtout pas vous.", 4, (0, 0),
     [degats(15, 22, cibles="ennemis")], zone={"type": "cercle", "taille": 1}, lanceur_exclu=True)

RESSOURCES = {  # monstre → [(id, nom, rareté, taux, caractéristique, description)]
    "epouvantail_en_arret_maladie": [
        ("paille_d_arret_maladie", "Paille d'arrêt maladie", "commun", 0.5, "agilite", "Elle tousse encore un peu."),
        ("certificat_medical_de_paille", "Certificat médical de paille", "rare", 0.1, "resistance_tempete",
         "Signé par un médecin introuvable. Valable trois semaines, renouvelable.")],
    "pere_fauchard": [
        ("chapeau_du_pere_fauchard", "Chapeau du Père Fauchard", "commun", 0.6, "initiative", "Troué par quarante ans d'orages et de corbeaux."),
        ("faux_du_pere_fauchard", "Lame de la faux du Père Fauchard", "rare", 0.15, "dommages_tempete", "Aiguisée tous les dimanches, par principe."),
        ("coeur_de_paille", "Cœur de paille", "legendaire", 0.01, "vitalite", "Il bat à peine, mais il ne s'arrête jamais.")],
}
for monstre_id, ressources in RESSOURCES.items():
    for id, nom, rarete, _, carac, description in ressources:
        ecrire("objets", {"id": id, "nom": nom, "type": "ressource", "rarete": rarete, "niveau": 2, "description": description,
                          "caracteristique": carac, "famille": monstre_id, "zone": "brumerive", "boutique": False})
ecrire("objets", {"id": "cle_de_la_grange", "nom": "Clé de la grange", "type": "ressource", "rarete": "commun", "niveau": 2,
                  "description": "Certifiée inviolable par son forgeron. La serrure de la grange, elle, n'a rien certifié du tout."})
ecrire("objets", {"id": "plan_cle_de_la_grange", "nom": "Plan : Clé de la grange", "type": "recette", "rarete": "commun", "niveau": 2,
                  "boutique": True, "description": "Plan de forge : la clé de la Grange du Père Fauchard. Une clé par personne, "
                  "le Père Fauchard tient à ses courants d'air.",
                  "recette": {"nom": "Clé de la grange", "objet": "cle_de_la_grange",
                              "ressources": {"paille_ensorcelee": 3, "caillou_de_fronde": 3, "croc_de_loup": 2}}})


def monstre(id, nom, description, pv, pa, pm, initiative, carac, sorts, xp, ecus, mot, **autres):
    ecrire("monstres", {"id": id, "nom": nom, "description": description, **autres, "palier": 2,
                        "caracteristiques": {"pv": pv, "pa": pa, "pm": pm, "initiative": initiative, **carac},
                        "resistances": {"acier": 10, "tempete": 15, "givre": 5, "flamme": -30}, "sorts": sorts, "ia": "basique",
                        "xp": xp, "butin": [{"objet": r[0], "taux": r[3]} for r in RESSOURCES[id]], "ecus": ecus, "mot": mot})


monstre("epouvantail_en_arret_maladie", "Épouvantail en arrêt maladie",
        "Il ne fait plus peur à personne depuis trois saisons. Il a un certificat. Il éternue sur ceux qui le contestent.",
        48, 6, 3, 70, {"force": 12, "agilite": 16}, ["malade_eternuement", "epouvantail_fourche"], 90, [8, 18], "du Malade",
        donjon=True)  # Exclusif au donjon : pas d'élite (GDD § 12).
monstre("pere_fauchard", "Père Fauchard, Épouvantail en chef",
        "Il garde la grange depuis quarante ans. Personne ne lui a dit que la ferme avait changé de propriétaire.",
        360, 7, 3, 110, {"force": 30, "agilite": 20}, ["fauchard_faux", "fauchard_bourrasque"], 900, [60, 110], "du Père Fauchard",
        boss=True, phases=[
            {"pv": 60, "message": "« On ne touche pas à ma récolte ! » Le Père Fauchard redresse sa faux.",
             "effets": [{"type": "bonus", "carac": "pm", "min": 1, "max": 1, "duree": 3},
                        {"type": "bonus", "carac": "dommages", "min": 3, "max": 3, "duree": 3}]},
            {"pv": 30, "message": "« Grande moisson ! » Il fait tourner sa faux comme aux plus beaux jours.",
             "sorts": ["fauchard_moisson"], "effets": [{"type": "bonus", "carac": "critique", "min": 20, "max": 20, "duree": 3}]}])


def salle(id, nom, sorties, groupes=(), pnj=(), graine=1):
    """Salle de la grange : murs de planches (M), ouvertures vers les salles voisines, groupes 1, 2… et PNJ a, b."""
    ouvertures = {"haut": {"haut": (0.42, 0.58)}, "bas": {"bas": (0.42, 0.58)}, "droite": {"droite": (0.42, 0.58)},
                  "gauche": {"gauche": (0.42, 0.58)}}
    p = Plan(graine=graine)
    bords = {}
    for cote in sorties:
        bords.update(ouvertures[cote])
    p.bord("M", **bords)
    p.poser("@", 0.5, 0.55)
    for n, (u, v) in enumerate([(0.3, 0.3), (0.7, 0.7)][:len(groupes)], 1):
        p.poser(str(n), u, v)
    for marqueur, u, v in [("a", 0.5, 0.88), ("b", 0.2, 0.75)][:len(pnj)]:
        p.poser(marqueur, u, v)
    p.semer("R", 10)
    p.boucher("M")
    texte = p.texte()
    assert verifier(id, texte), id
    carte = {"id": id, "nom": "Grange du Père Fauchard — " + nom, "donjon": VESTIBULE, "palette": "brumerive", "sol": "parquet",
             "sorties": sorties, "plan": texte}
    if groupes:
        carte["groupes"] = [{"monstres": g} for g in groupes]
    if pnj:
        carte["pnj"] = list(pnj)
    ecrire("cartes", carte)


SORTIE = {"marqueur": "a", "id": "garcon_de_ferme", "nom": "Garçon de ferme", "entree": {"carte": FERME},
          "repliques": ["Vous sortez ? Je referme derrière vous. Pour revenir, il faudra une autre clé : le Père Fauchard change "
                        "la serrure à chaque visite."]}
salle(VESTIBULE, "Vestibule", {"haut": "grange_grenier", "droite": "grange_etable", "bas": "grange_bureau"}, pnj=[SORTIE], graine=3)
salle("grange_grenier", "Grenier", {"bas": VESTIBULE}, graine=5, groupes=[
    ["epouvantail_en_arret_maladie", "epouvantail_demotive"],
    ["epouvantail_en_arret_maladie", "loup_des_collines", "loup_des_collines"]])
salle("grange_etable", "Étable", {"gauche": VESTIBULE}, graine=7, groupes=[
    ["epouvantail_demotive", "epouvantail_demotive", "epouvantail_en_arret_maladie"],
    ["epouvantail_en_arret_maladie", "epouvantail_en_arret_maladie"]])
salle("grange_bureau", "Bureau du Père Fauchard", {"haut": VESTIBULE}, graine=9,
      groupes=[["pere_fauchard", "epouvantail_en_arret_maladie", "epouvantail_demotive"]],
      pnj=[{"marqueur": "a", "id": "porte_de_derriere", "nom": "Porte de derrière", "entree": {"carte": FERME, "salle_videe": True},
            "repliques": ["La porte de derrière est bloquée par une faux. Celle du Père Fauchard, bien sûr."]}])

# Entrée : le gardien de la grange, sur la ferme de Brumerive, à côté de la cabane du fermier Gaudin.
chemin = os.path.join(JEU, "data", "cartes", FERME + ".json")
ferme = json.load(open(chemin))
plan = [list(ligne) for ligne in ferme["plan"]]
plan[30][8] = "b"
ferme["plan"] = ["".join(ligne) for ligne in plan]
ferme["pnj"] = [p for p in ferme["pnj"] if p["id"] != "gardien_de_la_grange"] + [{
    "marqueur": "b", "id": "gardien_de_la_grange", "nom": "Bouzin, gardien de la grange", "entree": {"carte": VESTIBULE, "cle": "cle_de_la_grange"},
    "repliques": ["La grange du Père Fauchard ? Entrée sur clé, une par personne. C'est le règlement de la ferme.",
                  "La clé se forge à l'enclume : le plan se vend chez les marchands, la paille et les cailloux se trouvent dans le coin."]}]
assert verifier(FERME, ferme["plan"])
with open(chemin, "w") as f:
    f.write(json.dumps(ferme, ensure_ascii=False, indent=2) + "\n")

ICONES = {"paille_d_arret_maladie": "paille_ensorcelee", "certificat_medical_de_paille": "fiche_de_paie_gobeline",
          "chapeau_du_pere_fauchard": "chapeau_de_morille", "faux_du_pere_fauchard": "coeur_de_pierre", "coeur_de_paille": "coeur_de_frene",
          "cle_de_la_grange": "cle_celeste"}  # Icônes provisoires : des dessins d'objets existants.
with open(os.path.join(JEU, "art", "manifestes", "donjons.json"), "w") as f:
    paille = {"peau": "c9b27a", "cheveux": "e0c060", "manches": "a08a5a", "bottes": "5a4632", "ceinture": "8a6a3a", "chapeau": "c8a85a"}
    f.write(json.dumps({
        "images": {"objet_" + id: {"fichier": "objets/%s.svgt" % image, "ancre": [22, 22]} for id, image in ICONES.items()},
        "monstres": {
            "epouvantail_en_arret_maladie": {"rig": "humain", "couleurs": {**paille, "tunique": "8aa0b0", "pantalon": "e8e8e0"},
                                             "arme": "fourche", "accessoires": ["chapeau_paille"]},
            "pere_fauchard": {"rig": "humain_grand", "couleurs": {**paille, "cheveux": "f0e8c0", "tunique": "6a4a2a", "pantalon": "3a4a6a"},
                              "arme": "fourche", "accessoires": ["chapeau_paille", "barbe"]}},
        "pnj": {
            "gardien_de_la_grange": {"rig": "humain", "couleurs": {"tunique": "7a5a3a", "manches": "e8e0c8", "pantalon": "4a5a3a",
                                                                   "cheveux": "5a3a1a"}, "accessoires": ["chapeau_paille"]},
            "garcon_de_ferme": {"rig": "humain", "couleurs": {"tunique": "9a6a3a", "manches": "e8e0c8", "pantalon": "3a3028",
                                                              "cheveux": "c08a3a"}},
            "porte_de_derriere": {"rig": "humain", "couleurs": {"tunique": "5a4632", "manches": "5a4632", "pantalon": "5a4632",
                                                                "cheveux": "5a4632"}}}}, ensure_ascii=False, indent=2) + "\n")
