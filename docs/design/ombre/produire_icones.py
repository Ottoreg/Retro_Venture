"""Icônes des sorts de l'Ombre (SVG 44 × 44) et fragment de manifeste `art/manifestes/ombre.json`.

    python3 docs/design/ombre/produire_icones.py      # depuis la racine du dépôt
"""
import json
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "game", "art")
# Fond : Tempête bleu nuit à éclairs jaunes, Acier noir à liseré argent (couleurs de la classe).
FRAMES = {"t": ("#3b4a7a", "#0d1020", "#ffe27a"), "a": ("#5a5a66", "#0e0e12", "#c9ccd6")}
SILHOUETTE = '<circle cx="22" cy="13" r="4.5" fill="{c}"/><path d="M14 36 Q15 20 22 19 Q29 20 30 36 Z" fill="{c}"/>'
BOLT = '<path d="M{x} {y} l-5 9 h4 l-3 8 l8 -11 h-4 l3 -6 Z" fill="#ffe27a" stroke="#1a1408" stroke-width="0.8"/>'
BLADE = '<path d="M12 33 L30 12 L33 11 L32 14 L14 35 Z" fill="#dfe3ea" stroke="#0e0e12" stroke-width="1.2"/><path d="M11 30 L17 36" stroke="#c9ccd6" stroke-width="2.4" stroke-linecap="round"/>'
DRAWINGS = {
    "survoltage": ("t", SILHOUETTE.format(c="#9fd3ff") + BOLT.format(x=33, y=8)),
    "lame_eclair": ("t", BLADE + BOLT.format(x=30, y=20)),
    "shuriken_d_orage": ("t", '<path d="M22 7 L25 19 L37 22 L25 25 L22 37 L19 25 L7 22 L19 19 Z" fill="#dfe3ea" stroke="#0d1020" stroke-width="1.2"/><circle cx="22" cy="22" r="2.4" fill="#ffe27a"/>'),
    "coup_de_tonnerre": ("t", '<ellipse cx="22" cy="13" rx="12" ry="6" fill="#8a94b8"/><path d="M24 15 l-9 13 h6 l-4 10 l12 -15 h-6 l4 -8 Z" fill="#ffe27a" stroke="#1a1408" stroke-width="1"/>'),
    "court_circuit": ("t", SILHOUETTE.format(c="#5b7bd6") + '<path d="M22 6 L24 16 L34 12 L27 20 L37 24 L26 25 L30 35 L22 28 L14 35 L18 25 L7 24 L17 20 L10 12 L20 16 Z" fill="none" stroke="#ffe27a" stroke-width="1.6"/>'),
    "rafale": ("t", '<path d="M8 15 Q24 9 30 15 Q34 20 28 21" stroke="#dfe3ea" stroke-width="2.6" fill="none" stroke-linecap="round"/><path d="M6 23 H32 Q38 24 35 29" stroke="#9fd3ff" stroke-width="2.6" fill="none" stroke-linecap="round"/><path d="M10 31 H26" stroke="#dfe3ea" stroke-width="2.6" stroke-linecap="round"/>'),
    "foudroiement": ("t", '<path d="M6 24 L16 18 L18 23 L28 16 L27 21 L38 20 L28 27 L29 23 L19 29 L18 25 Z" fill="#ffe27a" stroke="#1a1408" stroke-width="1"/><circle cx="8" cy="31" r="3" fill="#9fd3ff" opacity="0.7"/>'),
    "pas_de_l_eclair": ("t", '<ellipse cx="15" cy="30" rx="4" ry="6" fill="#9fd3ff" opacity="0.6"/><ellipse cx="28" cy="18" rx="4" ry="6" fill="#dfe3ea"/>' + BOLT.format(x=24, y=22)),
    "corps_electrique": ("t", '<path d="M22 7 L34 12 Q34 28 22 37 Q10 28 10 12 Z" fill="#2c3a66" stroke="#9fd3ff" stroke-width="2"/>' + BOLT.format(x=25, y=12)),
    "vent_porteur": ("t", '<path d="M8 28 Q20 30 30 14" stroke="#dfe3ea" stroke-width="2.6" fill="none" stroke-linecap="round"/><path d="M26 12 L33 11 L31 18 Z" fill="#dfe3ea"/><path d="M8 20 Q16 22 22 14" stroke="#9fd3ff" stroke-width="2" fill="none" stroke-linecap="round"/>'),
    "fondu_au_noir": ("a", SILHOUETTE.format(c="#c9ccd6").replace("<circle", '<circle opacity="0.35"').replace("<path", '<path opacity="0.35" stroke-dasharray="2 2" stroke="#c9ccd6"')),
    "surin": ("a", '<path d="M15 30 L28 14 L31 13 L30 16 L17 32 Z" fill="#dfe3ea" stroke="#0e0e12" stroke-width="1.2"/><path d="M12 30 L18 35" stroke="#5a4632" stroke-width="3" stroke-linecap="round"/>'),
    "lame_de_jet": ("a", '<path d="M20 26 L32 14 L35 13 L34 16 L22 28 Z" fill="#dfe3ea" stroke="#0e0e12" stroke-width="1.2"/><path d="M8 24 H16 M10 29 H18 M12 34 H20" stroke="#c9ccd6" stroke-width="1.6" stroke-linecap="round"/>'),
    "execution": ("a", '<path d="M22 6 L27 10 L24 28 L20 28 L17 10 Z" fill="#dfe3ea" stroke="#0e0e12" stroke-width="1.2"/><path d="M14 28 H30" stroke="#c9ccd6" stroke-width="3" stroke-linecap="round"/><path d="M22 30 V38" stroke="#5a4632" stroke-width="3.4" stroke-linecap="round"/>'),
    "arme_d_obscurite": ("a", '<ellipse cx="22" cy="34" rx="12" ry="4" fill="#000" opacity="0.7"/><path d="M22 8 L26 26 L22 31 L18 26 Z" fill="#2a2a36" stroke="#c9ccd6" stroke-width="1.4"/>'),
    "coupe_jarret": ("a", '<path d="M18 6 L19 22 L16 38 M26 6 L26 22 L28 38" stroke="#c9ccd6" stroke-width="3" fill="none" stroke-linecap="round"/><path d="M10 27 L34 21" stroke="#e05a5a" stroke-width="2.4" stroke-linecap="round"/>'),
    "entaille": ("a", '<path d="M11 14 L33 20 M10 22 L34 28 M12 30 L32 35" stroke="#e05a5a" stroke-width="2.6" stroke-linecap="round"/><path d="M11 14 L33 20" stroke="#dfe3ea" stroke-width="1" stroke-linecap="round"/>'),
    "dans_le_dos": ("a", SILHOUETTE.format(c="#5a5a66") + '<path d="M8 30 Q6 8 22 7 Q36 8 35 24" stroke="#dfe3ea" stroke-width="2.4" fill="none" stroke-linecap="round"/><path d="M31 22 L35 28 L38 21 Z" fill="#dfe3ea"/>'),
    "monde_des_ombres": ("a", '<circle cx="22" cy="22" r="13" fill="#05050a" stroke="#c9ccd6" stroke-width="1.6"/><path d="M22 12 Q31 14 30 22 Q29 29 22 28 Q16 27 17 22 Q18 18 22 19" stroke="#8890a8" stroke-width="2" fill="none" stroke-linecap="round"/>'),
    "affutage": ("a", '<rect x="8" y="28" width="22" height="7" rx="2" fill="#7a6a58" stroke="#0e0e12" stroke-width="1"/><path d="M14 26 L32 9 L35 8 L34 11 L17 28 Z" fill="#dfe3ea" stroke="#0e0e12" stroke-width="1.2"/><path d="M31 27 l3 -2 M34 30 l3 0 M31 32 l2 2" stroke="#ffe27a" stroke-width="1.4" stroke-linecap="round"/>'),
    "coup_en_traitre": ("a", '<path d="M8 17 Q22 8 36 17 Q22 23 8 17 Z" fill="none" stroke="#c9ccd6" stroke-width="1.8"/><path d="M10 18 Q22 26 34 18" stroke="#c9ccd6" stroke-width="1.6" fill="none"/><path d="M18 40 L22 22 L26 40 Z" fill="#2a2a36" stroke="#c9ccd6" stroke-width="1.2"/>'),
}

images = {}
for name, (kind, body) in DRAWINGS.items():
    light, dark, edge = FRAMES[kind]
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="44" height="44" viewBox="0 0 44 44">\n'
           f'<defs><radialGradient id="f" cx="0.35" cy="0.3" r="0.9"><stop offset="0" stop-color="{light}"/><stop offset="1" stop-color="{dark}"/></radialGradient></defs>\n'
           f'<rect x="1.5" y="1.5" width="41" height="41" rx="7" fill="url(#f)" stroke="{edge}" stroke-width="2"/>\n{body}\n</svg>\n')
    open(os.path.join(ROOT, "sorts", f"ombre_{name}.svgt"), "w").write(svg)
    images[f"sort_ombre_{name}"] = {"fichier": f"sorts/ombre_{name}.svgt", "ancre": [22, 22]}
open(os.path.join(ROOT, "manifestes", "ombre.json"), "w").write(json.dumps({"images": images}, ensure_ascii=False, indent=2) + "\n")
