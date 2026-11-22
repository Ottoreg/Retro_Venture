"""Caravane marchande (décor de 4 × 2 cases) et sa pose sur grandesplaines_0_0.
Écrit game/art/batiment/caravane[_miroir].svgt, game/art/manifestes/grandes_plaines.json et les décors de la carte.
`caravane` : longue selon x de la grille (de haut à gauche vers bas à droite) ; `caravane_miroir` : longue selon y.
Usage, depuis la racine du dépôt : python3 docs/design/grandes_plaines/caravane.py"""
import json, math

LONG, LARGE = 4, 2  # emprise en cases : le long de l'essieu, en travers


def svg(miroir):
    def ecran(u, v, h):  # u le long de la caravane (0..4), v en travers (0..2), h hauteur ; case avant centrée en (0, 0)
        dx, dy = u - LONG + 0.5, v - LARGE + 0.5
        if miroir:
            dx, dy = dy, dx
        return (dx - dy) * 32, (dx + dy) * 16 - h
    formes = []
    def poly(points, fond, trait='#3a2618', extra=''):
        formes.append((points, f'fill="{fond}" stroke="{trait}" stroke-width="1.1" stroke-linejoin="round"{extra}'))
    def roue(u, v):
        x, y = ecran(u, v, 9)
        formes.append(([(x, y)], f'roue'))
    u0, u1, v0, v1 = 0.35, LONG - 0.35, 0.3, LARGE - 0.3
    poly([ecran(-0.1, -0.1, 0), ecran(LONG + 0.1, -0.1, 0), ecran(LONG + 0.1, LARGE + 0.1, 0), ecran(-0.1, LARGE + 0.1, 0)], '#000000', 'none', ' opacity="0.18"')
    roue(0.9, v0); roue(LONG - 0.9, v0)  # roues du fond, cachées en partie par la caisse
    caisse = lambda h: [ecran(u0, v0, h), ecran(u1, v0, h), ecran(u1, v1, h), ecran(u0, v1, h)]
    poly([ecran(u0, v1, 10), ecran(u1, v1, 10), ecran(u1, v1, 26), ecran(u0, v1, 26)], '#7a5230')  # flanc avant
    poly([ecran(u1, v0, 10), ecran(u1, v1, 10), ecran(u1, v1, 26), ecran(u1, v0, 26)], '#5e3e22')  # bout avant
    for u in (u0 + 0.6, u1 - 0.6):
        formes.append(([ecran(u, v1, 11), ecran(u, v1, 25)], 'planche'))
    # Bâche en arceau : des bandes le long de la caravane, du fond vers l'avant, plus claires vers le haut.
    arc = lambda t: (1.0 + 0.78 * math.cos(t), 26 + 30 * math.sin(t))
    pas = [math.pi * i / 10 for i in range(11)]
    for a, b in zip(pas, pas[1:]):
        (va, ha), (vb, hb) = arc(a), arc(b)
        lum = int(150 + 80 * math.sin((a + b) / 2) * (0.6 if (a + b) / 2 < math.pi / 2 else 1))
        poly([ecran(u0 - 0.05, va, ha), ecran(u1 + 0.05, va, ha), ecran(u1 + 0.05, vb, hb), ecran(u0 - 0.05, vb, hb)], f'#{lum:02x}{lum - 14:02x}{lum - 40:02x}', 'none')
    for u in (u0 + 0.25, (u0 + u1) / 2, u1 - 0.25):  # arceaux et bande rouge du marchand
        formes.append(([ecran(u, *arc(t)) for t in pas], 'arceau'))
    formes.append(([ecran(u0 + 0.9, *arc(t)) for t in pas], 'bande'))
    formes.append(([ecran(u1 - 0.9, *arc(t)) for t in pas], 'bande'))
    poly([ecran(u1 + 0.05, *arc(t)) for t in pas], '#d8c8a0')  # ouverture avant
    poly([ecran(u1 + 0.05, *arc(t)) for t in pas[2:9]] + [ecran(u1 + 0.05, 1.0, 30)], '#3a2618', 'none')
    for c, (u, h) in enumerate([(u1 - 0.1, 30), (u1 - 0.25, 36)]):  # caisses et tonneau à l'entrée
        x, y = ecran(u, 1.0 + (c - 0.5) * 0.5, h)
        formes.append(([(x, y)], 'tonneau' if c else 'caisse'))
    roue(0.9, v1); roue(LONG - 0.9, v1)
    formes.append(([ecran(u1, 0.75, 12), ecran(LONG + 0.9, 0.85, 4)], 'timon'))
    formes.append(([ecran(u1, 1.25, 12), ecran(LONG + 0.9, 1.15, 4)], 'timon'))
    # Mise en page : tout en coordonnées positives, ancre = centre de la case avant.
    xs = [p[0] for f in formes for p in f[0]]; ys = [p[1] for f in formes for p in f[0]]
    ox, oy = 14 - min(xs), 14 - min(ys)
    w, h = math.ceil(max(xs) + ox + 14), math.ceil(max(ys) + oy + 8)
    pt = lambda p: f'{p[0] + ox:.1f},{p[1] + oy:.1f}'
    lignes = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">']
    for points, style in formes:
        (x, y) = (points[0][0] + ox, points[0][1] + oy)
        if style == 'roue':
            lignes.append(f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="{5 if miroir else 9}" ry="10" fill="#5a3a20" stroke="#2a1a0c" stroke-width="1.6"/>'
                          f'<circle cx="{x:.1f}" cy="{y:.1f}" r="2.2" fill="#2a1a0c"/>')
        elif style in ('arceau', 'bande', 'planche', 'timon'):
            couleur, epaisseur = {'arceau': ('#8a7050', 1.2), 'bande': ('#b04030', 4), 'planche': ('#3a2618', 1), 'timon': ('#4a3020', 2.6)}[style]
            lignes.append(f'<polyline points="{" ".join(map(pt, points))}" fill="none" stroke="{couleur}" stroke-width="{epaisseur}" stroke-linecap="round"/>')
        elif style == 'caisse':
            lignes.append(f'<rect x="{x - 7:.1f}" y="{y - 8:.1f}" width="14" height="10" fill="#a07848" stroke="#3a2618" stroke-width="1"/>')
        elif style == 'tonneau':
            lignes.append(f'<rect x="{x - 5:.1f}" y="{y - 9:.1f}" width="10" height="12" rx="3" fill="#8a5a30" stroke="#3a2618" stroke-width="1"/>')
        else:
            lignes.append(f'<polygon points="{" ".join(map(pt, points))}" {style}/>')
    lignes.append('</svg>')
    return '\n'.join(lignes) + '\n', [round(ox), round(oy)]


manifeste = {'images': {}}
for nom, miroir in (('caravane', False), ('caravane_miroir', True)):
    texte, ancre = svg(miroir)
    open(f'game/art/batiment/{nom}.svgt', 'w').write(texte)
    manifeste['images'][nom] = {'fichier': f'batiment/{nom}.svgt', 'ancre': ancre, 'emprise': [LONG, LARGE] if not miroir else [LARGE, LONG]}
open('game/art/manifestes/grandes_plaines.json', 'w').write(json.dumps(manifeste, ensure_ascii=False, indent=2) + '\n')

# Pose : rectangles de cases de la grille (x0, y0) à (x1, y1) remplis de « # », décor sur la case avant (x1, y1).
POSES = [('caravane_miroir', 15, -1), ('caravane', 18, -4), ('caravane', 18, 4), ('caravane_miroir', 23, -1)]
chemin = 'game/data/cartes/grandesplaines_0_0.json'
carte = json.load(open(chemin))
plan = [list(l) for l in carte['plan']]
def case_du_plan(x, y):  # inverse de GameMap.plan_cell
    rangee, demi = x + y, x - y
    return rangee - 1, (demi - rangee % 2) // 2
plan = [[' ' if r % 2 and c == 0 else ('.' if ch == '#' else ch) for c, ch in enumerate(l)] for r, l in enumerate(plan)]
decors = []
for nom, x0, y0 in POSES:
    lx, ly = (LONG, LARGE) if nom == 'caravane' else (LARGE, LONG)
    for x in range(x0, x0 + lx):
        for y in range(y0, y0 + ly):
            r, c = case_du_plan(x, y)
            assert plan[r][c] == '.', (nom, x, y, plan[r][c])
            plan[r][c] = '#'
    decors.append({'image': nom, 'case': list(case_du_plan(x0 + lx - 1, y0 + ly - 1))})
carte['plan'] = [''.join(l) for l in plan]
carte['decors'] = decors
open(chemin, 'w').write(json.dumps(carte, ensure_ascii=False, indent=2) + '\n')
print(manifeste, decors)
