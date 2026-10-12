extends Control
## Illustration du menu : un coin de Brumerive dessiné avec les images du jeu (maison, arbres,
## Pierre de Passage) et un personnage de chaque race, qui respirent.

var _time := 0.0
var _looks: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Art.palette = ""
	var data := GameData.load_all()
	_looks = [
		Rig.player_look("humain", "guerrier", data),
		Rig.player_look("elfe", "rodeur", data),
		Rig.player_look("gobelin", "arcaniste", data),
	]


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var center := Vector2(size.x / 2.0, size.y - 150.0)
	# Un grand losange d'herbe, bordé d'une ombre.
	var reach := Vector2(560, 280)
	var ground := PackedVector2Array([center + Vector2(0, -reach.y), center + Vector2(reach.x, 0), center + Vector2(0, reach.y), center + Vector2(-reach.x, 0)])
	draw_colored_polygon(ground, Art.color("herbe"))
	for i in 46:
		var spot := center + Vector2(posmod(i * 137, 900) - 450, posmod(i * 71, 360) - 180) * Vector2(1, 0.9)
		if absf(spot.x - center.x) / reach.x + absf(spot.y - center.y) / reach.y > 0.92:
			continue
		var names := ["tache_claire", "tache_sombre", "touffes", "fleurs", "cailloux"]
		Art.draw(self, names[i % names.size()], spot)
	for k in 7:
		var step := center + Vector2(-260 + k * 40, -40 + k * 20)
		Art.draw(self, "chemin_bord", step)
	for k in 7:
		Art.draw(self, "chemin", center + Vector2(-260 + k * 40, -40 + k * 20))
	# Décor et personnages, du fond vers l'avant.
	var items: Array = [
		[center + Vector2(-250, -40), "maison"], [center + Vector2(150, -170), "arbre_3"], [center + Vector2(250, -110), "arbre_1"],
		[center + Vector2(330, -40), "arbre_2"], [center + Vector2(-420, -10), "arbre_2"], [center + Vector2(120, -20), "pierre_passage"],
		[center + Vector2(-60, 60), 0], [center + Vector2(10, 90), 1], [center + Vector2(80, 70), 2],
		[center + Vector2(300, 60), "rocher"], [center + Vector2(-330, 110), "arbre_1"],
	]
	items.sort_custom(func(a: Array, b: Array) -> bool: return a[0].y < b[0].y)
	for item: Array in items:
		if typeof(item[1]) == TYPE_INT:
			var index: int = item[1]
			Rig.draw(self, _looks[index], item[0], {"facing": -1.0 if index == 2 else 1.0, "temps": _time + index, "zoom": 1.5})
		else:
			Art.draw(self, item[1], item[0])
	# Fondu vers le fond, en haut.
	var fade := Color(0.168627, 0.129412, 0.0941176)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, size.y * 0.62), Vector2(0, size.y * 0.62)]),
		PackedColorArray([fade, fade, Color(fade, 0.0), Color(fade, 0.0)]))
