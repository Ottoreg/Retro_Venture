"""Remet à jour les cartes et les ressources figées dans editeur_cartes.html depuis le dépôt du jeu.
Usage, depuis la racine du dépôt : python3 docs/outils/regenerer.py . docs/outils/editeur_cartes.html"""
import glob, json, re, subprocess, sys
depot, page = sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else 'editeur_cartes.html'
cartes = {d['id']: d for d in (json.load(open(f)) for f in sorted(glob.glob(f'{depot}/game/data/cartes/*.json'))) if re.match(r'.+_-?\d+_-?\d+$', d['id'])}
peche = ['Â', 'Ê', 'Î', 'Ô', 'Û']  # GameMap.FISHING_CHARS
ressources = {r['marqueur']: [r['nom'], r['couleur'], r['objet'], r['marqueur'] in peche]
              for f in sorted(glob.glob(f'{depot}/game/data/metiers/*.json')) for r in json.load(open(f)).get('ressources', [])}
disposition = open(f'{depot}/game/client/ui/world_map_layout.gd', encoding='utf-8').read()  # WorldMapLayout.ZONE_ORIGINS
origines = {z: [int(x), int(y)] for z, x, y in re.findall(r'"(\w+)": Vector2i\((-?\d+), (-?\d+)\)', disposition.split('const ZONE_ORIGINS', 1)[1].split('}', 1)[0])}
version = subprocess.run(['git', '-C', depot, 'log', '-1', '--format=%h %cs'], capture_output=True, text=True).stdout.strip()
donnees = json.dumps({'version': version, 'cartes': cartes, 'ressources': ressources, 'origines': origines}, ensure_ascii=False, separators=(',', ':'))
html = open(page, encoding='utf-8').read()
html = re.sub(r'/\*DONNEES\*/.*?/\*FIN\*/', lambda m: '/*DONNEES*/' + donnees + '/*FIN*/', html, flags=re.S)
open(page, 'w', encoding='utf-8').write(html)
print(origines, len(cartes), 'cartes,', len(ressources), 'ressources, commit', version)
