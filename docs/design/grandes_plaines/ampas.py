"""Lot 1 de l'élevage (docs/design/elevage/etapes.md, 24/11/2026) : les 8 ampas des Grandes Plaines (GDD § 10.3).
Monstres, élites, sorts, plumes, dessins (fragment art/manifestes/ampas.json) et groupes sur les cartes des plaines.
Plumes : +1 % de résistance à chacun des deux éléments de la couleur (GDD § 10.3)
(demande de l'auteur du 24/11/2026) ; Onyx en dommages spectraux, Cristal en dévastateurs. Valeurs provisoires : palier 2, Onyx et Cristal palier 3, plus rares (moins de groupes, réapparition 5 à 8 min).
Usage, depuis la racine du dépôt : python3 docs/design/grandes_plaines/ampas.py (relancé aussi par plaines.py)."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "sous_zones"))
from produire_sous_zone import sort, deg, bonus, ressource, monstre, drop, lire, ecrire, verifier  # noqa: E402
from cartes import ecran, proposer, JEU  # noqa: E402
from PIL import Image  # noqa: E402


def planche(couleur, ombre, sortie):
    """Planche pixel art de l'ampa (art/sprites/ampa.png, plumage gris neutre, tirée de assets/ampa par
    tools/planche_sprites.py) recoloriée : chaque gris prend la couleur des plumes à sa luminosité, assombrie
    vers l'ombre ; le bec, les pattes (jaunes) et le contour (presque noir) restent tels quels."""
    im = Image.open(os.path.join(JEU, "art/sprites/ampa.png")).convert("RGBA")
    c, o = [tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) for h in (couleur, ombre)]
    px = im.load()
    for x in range(im.width):
        for y in range(im.height):
            r, g, b, a = px[x, y]
            if a and max(r, g, b) - min(r, g, b) < 24 and max(r, g, b) > 60:  # gris du plumage
                l = (r + g + b) / 765
                t = min(1.0, l * 1.25)  # 0 : ombre, 1 : couleur, au-delà : reflet
                px[x, y] = tuple(min(255, round(o[k] + (c[k] - o[k]) * t + max(0.0, l - 0.8) * 120)) for k in range(3)) + (a,)
    im.save(os.path.join(JEU, sortie), optimize=True)

CARAC = {"flamme": "intelligence", "tempete": "agilite", "acier": "force", "givre": "perception"}
SORT = {"flamme": "ampa_plumes_ardentes", "tempete": "ampa_battement_d_ailes", "acier": "ampa_coup_de_bec", "givre": "ampa_cri_glace"}
SORTS = [
    sort("ampa_plumes_ardentes", "Plumes ardentes", "Il s'ébroue. Les plumes qui tombent sont en feu. Lui, non.", 3, (2, 4), [deg("flamme", 4, 6)], 2),
    sort("ampa_battement_d_ailes", "Battement d'ailes", "Il ne sait pas voler. Il sait très bien souffler.", 3, (1, 2),
         [deg("tempete", 3, 5), {"type": "poussee", "min": 1, "max": 1}], 2),
    sort("ampa_coup_de_bec", "Coup de bec", "Un bec d'aigle au bout d'un cou d'autruche : il frappe de loin et de haut.", 3, (1, 1), [deg("acier", 5, 7)], 2),
    sort("ampa_cri_glace", "Cri glacé", "Un cri de rapace, en plus froid. On en a les jambes coupées.", 3, (1, 3),
         [deg("givre", 3, 5), {"type": "malus", "carac": "pm", "min": 1, "max": 1, "duree": 1}], 2),
    sort("ampa_course_folle", "Course folle", "Personne ne rattrape un ampa onyx. Surtout pas à la nuit tombée.", 2, (0, 0), [bonus("pm", 2, 1)], 1, 2),
    sort("ampa_plumage_scintillant", "Plumage scintillant", "La lumière le traverse. Lui en ressort plus vif.", 2, (0, 0), [bonus("pa", 2, 1)], 1, 2),
]
# couleur : nom, plumes, ombre, tête, éléments (ou sorts pour Onyx et Cristal), carac de la plume, palier, description
AMPAS = {
    "brun": ("brun", "7a5030", "4e3220", "9a6a40", ["flamme", "tempete"], "agilite", "Le plus commun des ampas. Il le sait, et compense par le caractère."),
    "ocre": ("ocre", "c8902e", "8e6420", "d8a848", ["flamme", "acier"], "intelligence", "Couleur de terre cuite, tempérament de forge."),
    "roux": ("roux", "c0502a", "862e18", "d06a3a", ["flamme", "givre"], "perception", "Chaud dehors, froid dedans. Comme son regard."),
    "cramoisi": ("cramoisi", "9a1e2a", "641018", "b03040", ["acier", "givre"], "force", "Rouge sang, bec d'acier : il ne pique pas, il transperce."),
    "stratos": ("stratos", "3a6ab0", "244a80", "5a8ad0", ["acier", "tempete"], "fuite", "Bleu comme le ciel qu'il ne touchera jamais. Ça le rend nerveux."),
    "empire": ("empire", "3a8a4a", "245e30", "5aa868", ["tempete", "givre"], "vitalite", "Vert impérial, port altier. Il attend qu'on s'incline."),
    "onyx": ("onyx", "2a2a32", "141418", "44444e", ["ampa_coup_de_bec", "ampa_battement_d_ailes", "ampa_course_folle"], "degats_spectraux",
             "Noir comme une nuit sans lune. On l'entend courir, on ne le voit jamais arriver."),
    "cristal": ("cristal", "bfe4f0", "88b8cc", "e4f6fa", ["ampa_coup_de_bec", "ampa_cri_glace", "ampa_plumage_scintillant"], "degats_devastateurs",
                "Ses plumes de verre tintent quand il court. Il court rarement : il pose."),
}
RARES = ("onyx", "cristal")

monstres, ressources, art, images = [], [], {}, {"ampa": {"fichier": "monstre/ampa.svgt", "ancre": [30, 60]}}
for c, (nom, plumes, ombre, tete, elements, carac, desc) in AMPAS.items():
    rare = c in RARES
    palier, pv, force_carac, xp, ecus = (3, 70, 22, 200, [15, 30]) if rare else (2, 45, 14, 110, [9, 20])
    sorts = elements if rare else [SORT[e] for e in elements]
    caracs = {CARAC[e]: force_carac for e in (["acier", "tempete"] if c == "onyx" else ["acier", "givre"] if rare else elements)}
    res = {e: (20 if e in elements else -10) for e in CARAC} if not rare else {e: 15 for e in CARAC}
    plume, couleurs = f"plume_d_ampa_{c}", {"plumes": plumes, "plumes_ombre": ombre, "tete": tete}
    if not rare:  # demande de l'auteur (24/11/2026) : +1 % de résistance à chacun des deux éléments du GDD
        carac = [f"resistance_{e}" for e in elements]
    ressources.append(ressource(plume, f"Plume d'ampa {nom}", "rare" if rare else "commun", palier, carac, f"ampa_{c}", "hautepierre",
                                f"Une plume {nom}. Les éleveurs la reconnaissent à l'odeur, les autres à la couleur."))
    taux = (0.25, 0.6) if rare else (0.55, 0.9)
    monstres.append(monstre(f"ampa_{c}", f"Ampa {nom}", desc, palier, pv, 6, 5, 110, caracs, res, sorts, xp, ecus,
                            [drop(plume, taux[0], [1, 2])], mot=f"d'Ampa {nom}"))
    monstres.append(monstre(f"grand_ampa_{c}", f"Grand ampa {nom}", "Le meneur de la harde. Il court devant, il frappe devant, il mange devant.",
                            palier, round(pv * 2.2), 7, 5, 125, {k: round(v * 1.5) for k, v in caracs.items()}, res, sorts, round(xp * 2.2),
                            [e * 2 for e in ecus], [drop(plume, taux[1], [2, 4])], elite=True, famille=f"ampa_{c}"))
    planche(plumes, ombre, f"art/sprites/ampa_{c}.png")  # pixel art de l'auteur (24/11/2026), recolorié par robe
    art[f"ampa_{c}"] = {"image": "ampa", "planche": f"sprites/ampa_{c}.png", "echelle": 1.3, "couleurs": couleurs}
    art[f"grand_ampa_{c}"] = {"image": "ampa", "planche": f"sprites/ampa_{c}.png", "echelle": 1.65, "couleurs": couleurs}
    images[f"objet_{plume}"] = {"fichier": "objets/plume_d_ampa.svgt", "ancre": [22, 22], "couleurs": {"plume": plumes}}

g = lambda *ids, n=None: {"parmi": list(ids), "nombre": n} if n else {"monstres": list(ids)}
RARE = lambda c: {"monstres": [f"ampa_{c}"], "reapparition": [300, 480]}
GROUPES = {  # carte (x, y) : groupes ; à l'est (vers Hautepierre) brun, ocre et stratos, à l'ouest roux, cramoisi et empire
    (-2, 0): [g("ampa_brun"), g("ampa_brun", "ampa_ocre", n=[2, 3])],
    (-3, 0): [g("ampa_ocre", "ampa_stratos"), g("ampa_stratos")],
    (-4, 0): [g("ampa_roux"), g("ampa_roux", "ampa_empire", n=[2, 3])],
    (-4, 1): [g("ampa_cramoisi", "ampa_roux"), RARE("onyx")],
    (-3, 1): [g("ampa_brun", "ampa_roux"), g("ampa_ocre", "ampa_ocre")],
    (-2, 1): [g("ampa_stratos", "ampa_empire", n=[2, 3]), g("ampa_brun")],
    (-1, 1): [g("ampa_brun", "ampa_brun"), g("ampa_ocre")],
    (0, 1): [g("ampa_brun"), g("ampa_stratos", "ampa_brun")],
    (-4, 2): [g("ampa_roux", "ampa_roux"), g("ampa_cramoisi")],
    (-3, 2): [g("ampa_cramoisi", "ampa_empire"), g("ampa_empire", "ampa_roux", "ampa_cramoisi", n=[2, 3])],
    (-2, 2): [g("ampa_brun", "ampa_ocre", "ampa_roux", "ampa_cramoisi", "ampa_stratos", "ampa_empire", n=[2, 3]), RARE("onyx"), g("ampa_empire")],
    (-1, 2): [g("ampa_empire"), g("ampa_stratos", "ampa_ocre")],
    (0, 2): [g("ampa_ocre", "ampa_brun", n=[1, 3]), g("ampa_stratos")],
    (-2, 3): [RARE("cristal"), g("ampa_cramoisi", "ampa_stratos")],
    (-1, 3): [g("ampa_empire", "ampa_cramoisi"), RARE("cristal")],
}
PLACES = [(0.25, 0.7), (0.75, 0.3), (0.75, 0.75), (0.25, 0.25)]


def poser_groupes(plan, n):
    """Pose les marqueurs 1…n sur les cases libres les plus proches des places prévues."""
    g = [list(l) for l in plan]
    libres = [(i, j) for i, l in enumerate(g) for j, ch in enumerate(l) if ch == "." and not (i % 2 and j == 0) and 2 < i < len(g) - 3]
    for k in range(n):
        u, v = PLACES[k]
        i, j = min(libres, key=lambda c: (ecran(*c)[0] - u) ** 2 + (ecran(*c)[1] - v) ** 2)
        g[i][j] = str(k + 1)
        libres.remove((i, j))
    return ["".join(l) for l in g]


for s in SORTS:
    ecrire(f"data/sorts/{s['id']}.json", s)
for o in ressources:
    ecrire(f"data/objets/{o['id']}.json", o)
for m in monstres:
    ecrire(f"data/monstres/{m['id']}.json", m)
# Lot 2 (24/11/2026) : maître éleveur des Courses d'Ampas, marchand (il vend le licol, comme tous les marchands).
ELEVEUR = {"marqueur": "a", "id": "maitre_eleveur_plumard", "nom": "Maître Plumard, éleveur", "marchand": True, "repliques": [
    "Bienvenue aux Courses ! Licols, conseils, pansements : tout se vend, surtout les pansements.",
    "Un ampa, ça s'apprivoise au licol, quand il est seul et à bout de souffle. Et ça se dresse à l'enclos. Pas encore ouvert, l'enclos : on cherche qui a gardé la clé."]}
images["objet_licol"] = {"fichier": "objets/licol.svgt", "ancre": [22, 22]}
ecrire("art/manifestes/ampas.json", {"monstres": art, "images": images, "pnj": {ELEVEUR["id"]: {"rig": "humain", "couleurs": {
    "tunique": "b07a30", "manches": "6a4a2a", "pantalon": "4a3a2a", "cheveux": "c0c0b8", "peau": "e0b890"}}}})
courses = lire("data/cartes/grandesplaines_-1_0.json")
courses["plan"][14] = courses["plan"][14][:12] + "a" + courses["plan"][14][13:]
courses["pnj"] = [ELEVEUR]
verifier(courses["id"], courses["plan"])
ecrire("data/cartes/grandesplaines_-1_0.json", courses)
for (x, y), groupes in GROUPES.items():
    carte = lire(f"data/cartes/grandesplaines_{x}_{y}.json")
    plan = [l.translate(str.maketrans("123456789", "." * 9)) for l in carte["plan"]]
    carte["plan"] = poser_groupes(plan, len(groupes))
    carte["groupes"], carte["placement"] = groupes, proposer(carte["plan"])
    verifier(carte["id"], carte["plan"])
    ecrire(f"data/cartes/{carte['id']}.json", carte)
print(f"{len(monstres)} monstres, {len(SORTS)} sorts, {len(ressources)} plumes, groupes sur {len(GROUPES)} cartes")
