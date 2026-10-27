class_name WorldMapWindow
extends CanvasLayer
## Carte du monde (touche M, bouton du bandeau ou clic sur la minicarte), comme dans Dofus : tout le
## monde est montré dès le début (décision de l'auteur), sur un seul panneau : toutes les zones à leur
## place, reliées par leurs portes (`WorldMapLayout.world_layout`), chaque carte en vignette de la forme
## d'une carte, quel que soit le zoom (molette ; glisser pour se déplacer, un bouton par zone pour y
## aller). La carte actuelle est surlignée ; un losange
## marque une Pierre de Passage (plein si elle est connue, en creux sinon) ; une épingle, le repère
## posé depuis un texte de quête (`Session.quest_pin`, bouton « Retirer le repère ») ; une épingle
## jaune, l'objectif de la quête suivie (`QuestLinks.objective_pin`), posée et déplacée toute seule.

## Bouton « Retirer le repère ».
signal pin_cleared
## Clic droit sur une carte : un drapeau (repère) ; `shared` avec Maj (montré au groupe).
signal flag_requested(pin: Dictionary, shared: bool)
## Une sorte d'icône montrée ou masquée (la minicarte se redessine).
signal icons_changed

const GOLD := Color(0.95, 0.76, 0.3)
## Bleu des runes des Pierres de Passage.
const COLOR_STONE := Color("7fd0f0")
## Épingle du repère de quête.
const COLOR_PIN := Color("ff6a3d")
## Épingle de l'objectif de la quête suivie.
const COLOR_OBJECTIVE := Color("ffd23f")
## Membres du groupe de joueurs (point) et leurs repères (épingle).
const COLOR_PARTY := Color("5fd38a")
## Largeur / hauteur d'une case, sur la minicarte comme sur la carte du monde (une carte est plus
## large que haute) : toujours la même, quitte à faire défiler.
const MAP_RATIO := 1.6
## Carte du monde : largeur d'une case à chaque niveau de zoom (molette), et le niveau de départ.
const ZOOM_WIDTHS: Array[int] = [40, 56, 80, 104, 136, 176]
const DEFAULT_ZOOM := 3
## Marge autour du monde, jusqu'où l'on peut le faire glisser (pixels).
const WORLD_MARGIN := 24.0
## Plus étroite qu'une case (pixels), la carte du monde écrit en grand le nom de chaque zone par-dessus
## ses cartes, à la place des noms des cartes.
const ZONE_NAMES_BELOW := 80.0
## Largeur et hauteur maximales d'une case de la grille, et écart maximal entre deux cases (pixels).
const CELL_MAX := Vector2(150, 84)
const CELL_GAP := 6.0
## Pour une petite case, l'écart rétrécit avec elle : au plus cette part de la case.
const GAP_RATIO := 0.08
## Coupure des noms dans les cases : aux mots seulement ; un mot trop long pour la case finit par
## des points de suspension (voir `_centered_text`).
const NAME_BREAKS := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND
## Distance entre le bas de la fenêtre et le bas de l'écran.
const BOTTOM_MARGIN := 110.0


## Drapeau posé d'un clic droit sur une case de la grille : { carte, nom } (comme un repère de quête).
static func flag_pin(case: Dictionary) -> Dictionary:
	var coordinates: Vector2i = case["coordonnees"]
	var named := str(case.get("nom_complet", ""))
	return {"carte": case["id"], "nom": "Drapeau [%d, %d]%s" % [coordinates.x, coordinates.y,
		"" if named.is_empty() else " " + WorldMapLayout.short_name(named)]}


## Autres membres du groupe de joueurs, pour les grilles : [{ nom, carte, repere }].
static func party_markers(world: ClientState) -> Array:
	var markers: Array = []
	for member: Dictionary in world.party.get("membres", []):
		if member["id"] != world.player_id:
			markers.append({"nom": member["nom"], "carte": member.get("carte", ""), "repere": member.get("repere", {})})
	return markers


## Grille d'une zone, dessinée d'après le résultat de `WorldMapLayout.zone_layout`.
class ZoneGrid extends Control:
	var layout: Dictionary = {}
	## Vrai si l'on est dans une maison : la case actuelle est alors la carte où mène sa porte.
	var indoors := false
	## Version de la minicarte : petites cases sans nom (dans la bulle de survol), le joueur en point
	## bleu au milieu de la sienne.
	var compact := false
	## Repère de quête { carte, nom } (voir `QuestLinks`), ou {}.
	var pin: Dictionary = {}
	## Objectif de la quête suivie { carte, nom } (voir `QuestLinks.objective_pin`), ou {}.
	var objective: Dictionary = {}
	## Autres membres du groupe de joueurs : [{ nom, carte, repere }] (voir `party_markers`).
	var party: Array = []
	## Copie de l'état du jeu (`ClientState`) : vignettes des cartes (`MapThumbnail`) et icônes
	## (`MapIcons`) ; sans elle, des cases unies.
	var world: Variant = null
	## Taille fixe des cases (carte du monde : selon le zoom), ou zéro : d'après la place.
	var cell_fixed := Vector2.ZERO
	## Zone de la carte survolée (carte du monde : ses cartes sont entourées), ou "".
	var hover_zone := ""
	## Glissement de la grille (pixels, vers le haut et la gauche), quand elle dépasse (voir `cell_fixed`).
	var pan := Vector2.ZERO

	func _init() -> void:
		# Rien n'est dessiné hors de la grille, même pour une zone immense.
		clip_contents = true

	## Taille d'une case : la plus grande qui laisse tenir toute la zone, écarts compris, sans
	## plancher (cases plus petites pour une grande zone).
	func cell_size() -> Vector2:
		if cell_fixed != Vector2.ZERO:
			return cell_fixed
		if compact:
			# Minicarte : cases jointives, à peu près à la forme d'une carte (plus larges que hautes).
			var width := minf(size.x / maxi(1, int(layout.get("colonnes", 1))), size.y * MAP_RATIO / maxi(1, int(layout.get("lignes", 1))))
			return Vector2(floorf(width), floorf(width / MAP_RATIO))
		return Vector2(_fit(size.x, int(layout.get("colonnes", 1)), CELL_MAX.x),
			_fit(size.y, int(layout.get("lignes", 1)), CELL_MAX.y))

	## Écart entre deux cases, en largeur et en hauteur (il rétrécit avec les cases).
	func cell_gap() -> Vector2:
		if compact:
			return Vector2.ZERO
		var cell_px := cell_size()
		return Vector2(minf(CELL_GAP, cell_px.x * GAP_RATIO), minf(CELL_GAP, cell_px.y * GAP_RATIO))

	## Taille du texte des noms : d'après la hauteur et la largeur de la case.
	func font_size() -> int:
		var cell_px := cell_size()
		return clampi(int(minf(cell_px.y * 0.2, cell_px.x * 0.12)), 9, 15)

	## Côté d'une case pour en faire tenir `count`, avec `count + 1` écarts (bords compris), dans
	## `room` pixels, sans dépasser `largest`.
	static func _fit(room: float, count: int, largest: float) -> float:
		count = maxi(1, count)
		var cell := (room - CELL_GAP * (count + 1)) / count
		if cell * GAP_RATIO < CELL_GAP:
			# Écart réduit à GAP_RATIO de la case : count cases + (count + 1) écarts = room.
			cell = room / (count + GAP_RATIO * (count + 1))
		return maxf(0.0, floorf(minf(largest, cell)))

	## Rectangle d'une case de la grille (colonne, ligne), centré dans la zone de dessin.
	func cell_rect(cell: Vector2i) -> Rect2:
		var cell_px := cell_size()
		var gap := cell_gap()
		var step := cell_px + gap
		var origin := ((size - whole_size()) / 2.0).floor() - clamped_pan(pan)
		return Rect2(origin + Vector2(cell) * step, cell_px)

	## Taille de toute la grille, écarts compris (pixels).
	func whole_size() -> Vector2:
		var gap := cell_gap()
		return Vector2(int(layout.get("colonnes", 0)), int(layout.get("lignes", 0))) * (cell_size() + gap) - gap

	## Glissement ramené à ce qui garde la grille à l'écran (une marge au-delà de ses bords) ; rien
	## sur une grille qui tient.
	func clamped_pan(wanted: Vector2) -> Vector2:
		if cell_fixed == Vector2.ZERO:
			return Vector2.ZERO
		var limit := ((whole_size() - size) / 2.0 + Vector2(WORLD_MARGIN, WORLD_MARGIN)).max(Vector2.ZERO)
		return wanted.clamp(-limit, limit)

	## Glissement qui met ce point de la grille (pixels depuis son coin haut gauche) au milieu.
	func pan_to(point: Vector2) -> void:
		pan = clamped_pan(point - whole_size() / 2.0)
		queue_redraw()

	## Case de la carte `map_id` dans la grille, ou `null` (autre zone, sans coordonnées).
	func map_cell(map_id: String) -> Variant:
		return pin_cell({"carte": map_id})

	## Case affichée sous ce point ({} s'il n'y en a pas).
	func case_at(point: Vector2) -> Dictionary:
		for case: Dictionary in layout.get("cases", []):
			if cell_rect(case["case"]).has_point(point):
				return case
		return {}

	func _get_tooltip(at_position: Vector2) -> String:
		var case := case_at(at_position)
		return "" if case.is_empty() else case_tooltip(case)

	## Bulle de survol d'une case : nom complet, coordonnées, Pierre de Passage, et où l'on est.
	func case_tooltip(case: Dictionary) -> String:
		var coordinates: Vector2i = case["coordonnees"]
		var text := "Carte inconnue" if not case["visitee"] else str(case["nom_complet"])
		text += "  [%d, %d]" % [coordinates.x, coordinates.y]
		if case["pierre"] == WorldMapLayout.STONE_KNOWN:
			text += "\nPierre de Passage découverte"
		elif case["pierre"] == WorldMapLayout.STONE_UNKNOWN:
			text += "\nPierre de Passage pas encore découverte : touchez-la pour pouvoir y revenir en voyage."
		if world != null and case["visitee"]:
			var names: PackedStringArray = []
			for kind in MapIcons.of(world, case["id"]):
				if kind != "pierre":
					names.append(MapIcons.NAMES[kind])
			if not names.is_empty():
				text += "\n" + ", ".join(names)
		if case["actuelle"]:
			text += "\nVous êtes dans une maison de cette carte." if indoors else "\nVous êtes ici."
		if case["id"] == pin.get("carte", ""):
			text += "\nRepère : %s" % pin["nom"]
		if case["id"] == objective.get("carte", ""):
			text += "\nQuête suivie : %s" % objective["nom"]
		for member: Dictionary in party:
			if case["id"] == member["carte"]:
				text += "\nGroupe : %s est ici" % member["nom"]
			if case["id"] == member["repere"].get("carte", ""):
				text += "\nRepère de %s : %s" % [member["nom"], member["repere"]["nom"]]
		return text

	## Case du repère dans la grille (hors de la grille si la minicarte ne la montre pas), ou `null`
	## s'il n'y a pas de repère dans cette zone.
	func pin_cell(marker: Dictionary = pin) -> Variant:
		var coordinates := WorldMapLayout.map_coordinates(marker.get("carte", ""))
		if coordinates.is_empty():
			return null
		# Grille du monde : une origine par zone ; grille d'une zone : la sienne.
		var origins: Dictionary = layout.get("origines", {layout.get("zone", ""): layout.get("origine", Vector2i.ZERO)})
		if not origins.has(coordinates["zone"]):
			return null
		return coordinates["position"] - origins[coordinates["zone"]]

	## Vrai si le repère (ou l'objectif suivi) est sur une case de la grille.
	func pin_in_grid(marker: Dictionary = pin) -> bool:
		var cell: Variant = pin_cell(marker)
		return cell != null and Rect2i(0, 0, int(layout.get("colonnes", 0)), int(layout.get("lignes", 0))).has_point(cell)

	func _draw() -> void:
		if layout.get("cases", []).is_empty():
			return
		var cell_px := cell_size()
		var font := get_theme_default_font()
		var name_size := font_size()
		if compact:
			# Emplacements vides de la fenêtre, à peine marqués : on lit la grille du monde.
			for row in int(layout.get("lignes", 0)):
				for col in int(layout.get("colonnes", 0)):
					draw_rect(cell_rect(Vector2i(col, row)), Color(1, 1, 1, 0.035))
		# Les liens d'abord : un chemin entre deux cartes voisines (inutile entre des cases jointives).
		var link_width := clampf(minf(cell_px.x, cell_px.y) * 0.08, 1.5, 4.0)
		if not (compact and world != null):
			for link: Array in layout.get("liens", []):
				draw_line(cell_rect(link[0]).get_center(), cell_rect(link[1]).get_center(), UiTheme.BRONZE, link_width)
		var hidden: Array = Options.hidden_icons
		var current_rect := Rect2()
		for case: Dictionary in layout["cases"]:
			var rect := cell_rect(case["case"])
			var visited: bool = case["visitee"]
			var picture: Texture2D = MapThumbnail.texture(case["id"], world.map_by_id) if world != null and visited else null
			if picture != null:
				draw_texture_rect(picture, rect, false)
				if compact:
					draw_rect(rect, Color(0, 0, 0, 0.3), false, 1.0)
					if case["actuelle"]:
						current_rect = rect  # Son cadre doré se dessine après les autres cases.
				else:
					var frame := StyleBoxFlat.new()
					frame.bg_color = Color(0, 0, 0, 0)
					frame.set_border_width_all(3 if case["actuelle"] else 1)
					frame.border_color = GOLD if case["actuelle"] else UiTheme.BRONZE
					draw_style_box(frame, rect)
				_draw_icons(rect, case, hidden)
				if compact or (layout.has("zones") and cell_px.x < ZONE_NAMES_BELOW):
					continue  # Dézoomée, la carte du monde nomme ses zones (les cartes : bulle de survol).
				var inner := rect.grow(-4)
				_centered_text(get_theme_default_font(), inner, case["nom"], name_size, GOLD if case["actuelle"] else Color.WHITE, 3, true)
				continue
			var box := StyleBoxFlat.new()
			box.set_corner_radius_all(mini(5, int(minf(cell_px.x, cell_px.y) * 0.15)))
			box.set_border_width_all(3 if case["actuelle"] else 1)
			if case["actuelle"]:
				box.bg_color = Color("6b4a26")
				box.border_color = GOLD
			elif visited:
				box.bg_color = UiTheme.WOOD_LIGHT
				box.border_color = UiTheme.BRONZE
			else:
				box.bg_color = UiTheme.INK
				box.border_color = Color("5a4630")
			draw_style_box(box, rect)
			if not visited:
				var mark_size := clampi(int(minf(cell_px.x, cell_px.y) * 0.45), 9, 34)
				_centered_text(font, rect, WorldMapLayout.UNKNOWN_NAME, mark_size, UiTheme.TEXT_DIM, 1)
				continue
			if compact:
				if case["pierre"] != WorldMapLayout.STONE_NONE and "pierre" not in hidden:
					var small := minf(4.0, minf(cell_px.x, cell_px.y) * 0.18)
					_draw_stone(rect.position + Vector2(rect.size.x - small - 2, small * 1.3 + 2), small,
						case["pierre"] == WorldMapLayout.STONE_KNOWN)
				if case["actuelle"]:
					draw_circle(rect.get_center(), 3.5, Color("4d8fff"))
					draw_arc(rect.get_center(), 3.5, 0, TAU, 16, Color.WHITE, 1.2)
				continue
			# Marges intérieures, plus fines pour une petite case.
			var pad := Vector2(minf(6.0, cell_px.x * 0.08), minf(4.0, cell_px.y * 0.08))
			var text_rect := rect.grow_individual(-pad.x, -pad.y, -pad.x, -pad.y)
			if case["pierre"] != WorldMapLayout.STONE_NONE and "pierre" not in hidden:
				var radius := minf(6.0, minf(cell_px.x, cell_px.y) * 0.12)
				var stone_center := rect.position + Vector2(rect.size.x - radius - 3, radius * 1.3 + 3)
				_draw_stone(stone_center, radius, case["pierre"] == WorldMapLayout.STONE_KNOWN)
				if cell_px.y >= 40:
					# Place gardée pour le losange (une petite case le laisse sur le coin du nom).
					text_rect = text_rect.grow_individual(0, -8, -6, 0)
			_centered_text(font, text_rect, case["nom"], name_size, GOLD if case["actuelle"] else UiTheme.TEXT, 3)
			if case["actuelle"] and cell_px.y >= 52:
				# Le joueur : un point bleu sous le nom.
				draw_circle(Vector2(rect.get_center().x, rect.end.y - 8), 4.0, Color("4d8fff"))
				draw_arc(Vector2(rect.get_center().x, rect.end.y - 8), 4.0, 0, TAU, 16, Color.WHITE, 1.2)
		if current_rect.has_area():
			# Carte actuelle de la minicarte : cadre doré et point bleu, par-dessus les cases voisines.
			draw_rect(current_rect.grow(-1.0), GOLD, false, 2.0)
			draw_circle(current_rect.get_center(), 3.5, Color("4d8fff"))
			draw_arc(current_rect.get_center(), 3.5, 0, TAU, 16, Color.WHITE, 1.2)
		if not compact:
			_draw_zone_outline(hover_zone)
		if not compact and cell_px.x < ZONE_NAMES_BELOW:
			_draw_zone_names()
		_draw_pin(objective, COLOR_OBJECTIVE, true)
		_draw_pin(pin, COLOR_PIN, false)
		_draw_party()

	## Grille du monde : le contour des cartes d'une zone (celle de la carte survolée), à mi-écart
	## autour d'elles, en suivant sa forme.
	func _draw_zone_outline(zone_id: String) -> void:
		if zone_id.is_empty():
			return
		var cells := {}
		for case: Dictionary in layout.get("cases", []):
			if case.get("zone", "") == zone_id:
				cells[case["case"]] = true
		var half := cell_gap() / 2.0
		for cell: Vector2i in cells:
			var box := cell_rect(cell).grow_individual(half.x, half.y, half.x, half.y)
			var corners := [box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)]
			# Côtés haut, droite, bas, gauche : tracés là où la voisine n'est pas de la zone.
			var sides := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
			for i in 4:
				if not cells.has(cell + sides[i]):
					draw_line(corners[i], corners[(i + 1) % 4], GOLD, 2.0)

	## Grille du monde dézoomée : le nom de chaque zone en grand, cerné, au milieu de ses cartes.
	func _draw_zone_names() -> void:
		var font := get_theme_default_font()
		for zone: Dictionary in layout.get("zones", []):
			var area: Rect2i = zone["cases"]
			var box := cell_rect(area.position).merge(cell_rect(area.end - Vector2i.ONE))
			var text_size := clampi(int(box.size.y * 0.22), 12, 22)
			# Une petite zone (une seule carte) : son nom déborde sur les côtés plutôt que d'être coupé.
			box = box.grow_individual(maxf(0.0, (160.0 - box.size.x) / 2.0), 0, maxf(0.0, (160.0 - box.size.x) / 2.0), 0)
			_centered_text(font, box, str(zone["nom"]), text_size, GOLD, 2, true)

	## Membres du groupe : un point vert dans leur case (en bas à droite), leurs repères en épingle verte.
	func _draw_party() -> void:
		for member: Dictionary in party:
			_draw_pin(member["repere"], COLOR_PARTY, false, 1)
			var at := {"carte": member["carte"]}
			if pin_in_grid(at):
				var rect := cell_rect(pin_cell(at))
				var radius := clampf(minf(rect.size.x, rect.size.y) * 0.1, 2.5, 4.5)
				var center := rect.end - Vector2(radius + 3, radius + 3)
				draw_circle(center, radius, COLOR_PARTY)
				draw_arc(center, radius, 0, TAU, 16, Color.WHITE, 1.0)

	## Un repère : une épingle dans le coin haut gauche de sa case (bas gauche pour l'objectif suivi) ;
	## sur la minicarte, une flèche au bord quand sa case est hors de la fenêtre (même zone).
	func _draw_pin(marker: Dictionary, color: Color, low: bool, shift := 0) -> void:
		var cell: Variant = pin_cell(marker)
		if cell == null:
			return
		var rect := cell_rect(cell)
		if pin_in_grid(marker):
			var radius := clampf(minf(rect.size.x, rect.size.y) * 0.12, 3.0, 7.0)
			var head := rect.position + Vector2(radius + 3 + shift * radius * 2.2, radius + 3)
			if low:
				head.y = rect.end.y - radius * 3.2 - 3
			var tip := head + Vector2(0, radius * 2.2)
			draw_colored_polygon(PackedVector2Array([head + Vector2(-radius * 0.7, radius * 0.5), head + Vector2(radius * 0.7, radius * 0.5), tip]), color)
			draw_circle(head, radius, color)
			draw_arc(head, radius, 0, TAU, 16, Color("2a1208"), 1.2)
			draw_circle(head, radius * 0.35, Color.WHITE)
			return
		if not compact:
			return
		var middle := size / 2.0
		var direction := (rect.get_center() - middle).normalized()
		var half := middle - Vector2(6, 6)
		var reach := minf(half.x / maxf(absf(direction.x), 0.001), half.y / maxf(absf(direction.y), 0.001))
		var point := middle + direction * reach
		var side := Vector2(-direction.y, direction.x) * 4.0
		draw_colored_polygon(PackedVector2Array([point + direction * 5.0, point - direction * 3.0 + side, point - direction * 3.0 - side]), color)

	## Icônes d'une carte (`MapIcons`, sauf celles masquées), en ligne en bas à gauche de sa case :
	## un rond de couleur avec sa lettre, un simple point sur une petite case. Le losange de la Pierre
	## de Passage, en haut à droite.
	func _draw_icons(rect: Rect2, case: Dictionary, hidden: Array) -> void:
		var small := rect.size.x < 60.0
		if rect.size.x < 34.0:
			return  # Trop petite (minicarte dézoomée) : les icônes cacheraient la carte.
		var radius := 2.5 if small else clampf(rect.size.y * 0.1, 5.0, 8.0)
		var position := rect.position + Vector2(radius + 3, rect.size.y - radius - 3)
		var font := get_theme_default_font()
		for kind in MapIcons.of(world, case["id"]):
			if kind in hidden:
				continue
			if kind == "pierre":
				var stone := minf(6.0, maxf(3.0, rect.size.y * 0.12))
				_draw_stone(rect.position + Vector2(rect.size.x - stone - 3, stone * 1.3 + 3), stone, case["pierre"] != WorldMapLayout.STONE_UNKNOWN)
				continue
			draw_circle(position, radius, MapIcons.COLORS[kind])
			draw_arc(position, radius, 0, TAU, 16, Color(0.1, 0.07, 0.04), 1.0)
			if not small:
				var letter_size := int(radius * 1.5)
				var width := font.get_string_size(MapIcons.LETTERS[kind], HORIZONTAL_ALIGNMENT_LEFT, -1, letter_size).x
				draw_string(font, position + Vector2(-width / 2.0, letter_size * 0.36), MapIcons.LETTERS[kind], HORIZONTAL_ALIGNMENT_LEFT, -1, letter_size, Color(0.1, 0.07, 0.04))
			position.x += radius * 2.0 + 2.0
			if position.x > rect.end.x - radius:
				break

	## Texte centré dans le rectangle, sur `max_lines` lignes au plus et sans en sortir : coupé aux
	## mots (un mot trop long finit par « … »), et réduit aux lignes qui tiennent en hauteur (rien s'il
	## n'en tient aucune ; le nom reste dans la bulle de survol). `outline` : cerné de noir (sur une vignette).
	func _centered_text(font: Font, rect: Rect2, text: String, text_size: int, color: Color, max_lines: int, outline := false) -> void:
		var lines := mini(max_lines, int(rect.size.y / font.get_height(text_size)))
		if lines < 1 or rect.size.x < text_size:
			return
		text = fit_words(font, text, rect.size.x, text_size)
		var block := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, text_size, lines, NAME_BREAKS)
		var top := rect.position.y + (rect.size.y - block.y) / 2.0 + font.get_ascent(text_size)
		if outline:
			draw_multiline_string_outline(font, Vector2(rect.position.x, top), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x,
				text_size, lines, 4, Color(0.08, 0.05, 0.03), NAME_BREAKS)
		draw_multiline_string(font, Vector2(rect.position.x, top), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x,
			text_size, lines, color, NAME_BREAKS)

	## Le texte, chaque mot trop large pour `width` raccourci et terminé par « … » (« Clairi… » plutôt
	## que « Clairièr / e » sur une case étroite).
	static func fit_words(font: Font, text: String, width: float, text_size: int) -> String:
		var words := text.split(" ", false)
		for i in words.size():
			var word := words[i]
			if font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x <= width:
				continue
			while word.length() > 1 and font.get_string_size(word + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x > width:
				word = word.left(-1)
			words[i] = word + "…"
		return " ".join(words)

	## Losange d'une Pierre de Passage : plein si elle est découverte, en creux sinon.
	func _draw_stone(center: Vector2, radius: float, known: bool) -> void:
		var points := PackedVector2Array([center + Vector2(0, -radius * 1.3), center + Vector2(radius, 0),
			center + Vector2(0, radius * 1.3), center + Vector2(-radius, 0)])
		if known:
			draw_colored_polygon(points, COLOR_STONE)
		points.append(points[0])
		draw_polyline(points, COLOR_STONE if not known else Color("1d3a4a"), 1.5)


var map_view: MapView

var _backdrop: ColorRect
var _panel: PanelContainer
## Boutons des zones (id → Button) : un clic y amène la vue.
var _zone_buttons := {}
var _zone_row: HFlowContainer
var _zone_title: Label
var _zone_info: Label
var _grid: ZoneGrid
## Cases de la légende des icônes : sorte → CheckBox.
var _icon_toggles := {}
var _clear_pin: Button
## Zones du jeu (ids), celles visitées d'abord.
var _zone_ids: Array[String] = []
## Zone nommée en haut (celle de la carte survolée, ou choisie).
var _focus_zone := ""
var _drag_from := Minimap.NO_POINT
var _drag_pan := Vector2.ZERO
var _dragged := false


func _ready() -> void:
	_build()
	_set_visible(false)


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.combat_started.connect(close)
	map_view.map_changed.connect(refresh)
	map_view.quests_changed.connect(func(_journal: Dictionary) -> void: refresh())
	map_view.party_changed.connect(refresh)


func toggle() -> void:
	if is_open():
		close()
	else:
		open()


## Ouvre la carte du monde centrée sur la carte où l'on est.
func open() -> void:
	if map_view == null or map_view.mode == MapView.Mode.COMBAT:
		return
	_set_visible(true)
	_focus_zone = _here_zone()
	refresh()
	center_on(here_map(map_view.world))


## Ouvre la carte du monde centrée sur le repère de quête.
func show_pin() -> void:
	open()
	if is_open():
		var target := str(Session.quest_pin.get("carte", ""))
		_focus_zone = WorldMapLayout.map_coordinates(target).get("zone", _focus_zone)
		refresh()
		center_on(target)


func close() -> void:
	_set_visible(false)
	_grid.hover_zone = ""


func is_open() -> bool:
	return _panel.visible


## Zone nommée en haut de la fenêtre ("" s'il n'y en a pas).
func current_zone() -> String:
	return _focus_zone


## Amène la vue sur une zone (bouton de la zone).
func select_zone(zone_id: String) -> void:
	if not _zone_ids.has(zone_id):
		return
	_focus_zone = zone_id
	refresh()
	for zone: Dictionary in _grid.layout.get("zones", []):
		if zone["zone"] == zone_id:
			var area: Rect2i = zone["cases"]
			var box := _grid.cell_rect(area.position).merge(_grid.cell_rect(area.end - Vector2i.ONE))
			_grid.pan_to(box.get_center() - _grid.cell_rect(Vector2i.ZERO).position)


## Amène la vue sur une carte (rien si elle n'a pas de coordonnées).
func center_on(map_id: String) -> void:
	var cell: Variant = _grid.map_cell(map_id)
	if cell != null:
		_grid.pan_to(_grid.cell_rect(cell).get_center() - _grid.cell_rect(Vector2i.ZERO).position)


## Grille affichée : tout le monde (voir `WorldMapLayout.world_layout`).
func shown_layout() -> Dictionary:
	return _grid.layout


## Taille d'une case au zoom actuel (`Options.world_map_zoom`) : toujours de la forme d'une carte.
static func zoom_cell() -> Vector2:
	var width := float(ZOOM_WIDTHS[clampi(Options.world_map_zoom, 0, ZOOM_WIDTHS.size() - 1)])
	return Vector2(width, roundf(width / MAP_RATIO))


## Molette : un cran de zoom (`step` : + pour grossir), le point `at` de la grille restant sous la souris.
func zoom(step: int, at: Vector2 = Vector2(-1, -1)) -> void:
	var level := clampi(Options.world_map_zoom + step, 0, ZOOM_WIDTHS.size() - 1)
	if level == Options.world_map_zoom:
		return
	if at == Vector2(-1, -1):
		at = _grid.size / 2.0
	var corner := _grid.cell_rect(Vector2i.ZERO).position
	var spot := (at - corner) / (_grid.cell_size() + _grid.cell_gap())
	Options.world_map_zoom = level
	Options.save_options()
	_grid.cell_fixed = zoom_cell()
	var step_px := _grid.cell_size() + _grid.cell_gap()
	_grid.pan = _grid.clamped_pan(((_grid.size - _grid.whole_size()) / 2.0).floor() + spot * step_px - at)
	_grid.queue_redraw()


func refresh() -> void:
	if map_view == null or not is_open():
		return
	var world := map_view.world
	_update_zones()
	# Dans une maison, la carte devant sa porte est encadrée comme carte actuelle.
	var here := here_map(world)
	var layout := WorldMapLayout.world_layout(map_infos(world, _zone_ids), shown_maps(world), here,
		world.data.passages, known_passages(world))
	_grid.layout = layout
	_grid.cell_fixed = zoom_cell()
	_grid.indoors = here != world.map.id
	_grid.pin = Session.quest_pin
	_grid.objective = QuestLinks.objective_pin(world)
	_grid.party = party_markers(world)
	_grid.world = world
	_grid.queue_redraw()
	_clear_pin.visible = not Session.quest_pin.is_empty()
	_clear_pin.text = "Retirer le repère (%s)" % Session.quest_pin.get("nom", "")
	_refresh_zone_title()


## En haut : nom de la zone nommée (`_focus_zone`) et ses cartes visitées.
func _refresh_zone_title() -> void:
	for zone_id: String in _zone_buttons:
		_zone_buttons[zone_id].set_pressed_no_signal(zone_id == _focus_zone)
	if _grid.layout.get("cases", []).is_empty():
		_zone_title.text = "Aucune carte extérieure visitée"
		_zone_info.text = ""
		return
	var total := 0
	var visited := 0
	var seen := visited_here(map_view.world)
	for case: Dictionary in _grid.layout["cases"]:
		if case["zone"] == _focus_zone:
			total += 1
			if seen.has(case["id"]):
				visited += 1
	_zone_title.text = ""
	for zone: Dictionary in _grid.layout.get("zones", []):
		if zone["zone"] == _focus_zone:
			_zone_title.text = zone["nom"]
	_zone_info.text = "%d / %d carte%s visitée%s" % [visited, total, "s" if visited > 1 else "", "s" if visited > 1 else ""]


## Cartes des zones demandées : id → { nom, sorties, portes } (voir `WorldMapLayout.world_layout`).
## Les cartes viennent de `World.map_ids` (toutes celles du jeu), et des cartes visitées à défaut.
static func map_infos(world: ClientState, zone_ids: Array) -> Dictionary:
	var ids: Array[String] = world.map_ids.duplicate()
	for map_id in world.visited_maps():
		if not ids.has(map_id):
			ids.append(map_id)
	var infos := {}
	for map_id in ids:
		var coordinates := WorldMapLayout.map_coordinates(map_id)
		if coordinates.is_empty() or not zone_ids.has(coordinates["zone"]):
			continue
		var map := world.map_by_id(map_id)
		if map != null:
			infos[map_id] = {"nom": map.display_name, "sorties": map.exits.values(), "portes": map.doors.values()}
	return infos


## Pierres de Passage découvertes (ids).
static func known_passages(world: ClientState) -> Array[String]:
	var known: Array[String] = []
	for passage_id: String in world.data.passages:
		if world.is_passage_known(passage_id):
			known.append(passage_id)
	return known


## Carte à coordonnées où l'on est : la carte actuelle ; dans une maison, celle où mène sa porte
## ("" s'il n'y en a pas).
static func here_map(world: ClientState) -> String:
	var map := world.map
	if not WorldMapLayout.map_coordinates(map.id).is_empty():
		return map.id
	for target: String in map.doors.values():
		if not WorldMapLayout.map_coordinates(target).is_empty():
			return target
	return ""


## Zone à montrer à l'ouverture : celle de `here_map`.
func _here_zone() -> String:
	return WorldMapLayout.map_coordinates(here_map(map_view.world)).get("zone", "")


## Cartes visitées, plus celle où mène la porte de la maison où l'on est : on la connaît même si l'on
## n'y est pas encore sorti (départ dans la maison, ou sauvegarde antérieure à la liste des visites).
static func visited_here(world: ClientState) -> Array[String]:
	var visited := world.visited_maps()
	var here := here_map(world)
	if not here.is_empty() and not visited.has(here):
		visited.append(here)
	return visited


## Cartes montrées sur la carte du monde et la minicarte : toutes celles du jeu qui ont des
## coordonnées (comme dans Dofus, rien n'est caché), celles visitées en premier (ordre des zones).
static func shown_maps(world: ClientState) -> Array[String]:
	var shown := visited_here(world)
	var all_ids: Array[String] = world.map_ids.duplicate()
	all_ids.sort()
	for map_id in all_ids:
		if not shown.has(map_id) and not WorldMapLayout.map_coordinates(map_id).is_empty():
			shown.append(map_id)
	return shown


## Grille du monde : toutes les zones, chacune à sa place (`WorldMapLayout.zone_origins`).
static func world_grid_layout(world: ClientState, here := "") -> Dictionary:
	var shown := shown_maps(world)
	return WorldMapLayout.world_layout(map_infos(world, WorldMapLayout.visited_zones(shown)), shown, here,
		world.data.passages, known_passages(world))


## Un bouton par zone du jeu, celles visitées d'abord.
func _update_zones() -> void:
	var world := map_view.world
	var zones := WorldMapLayout.visited_zones(shown_maps(world))
	if zones == _zone_ids:
		return
	_zone_ids = zones
	var infos := map_infos(world, zones)
	for button in _zone_buttons.values():
		button.queue_free()
	_zone_buttons.clear()
	for zone_id in _zone_ids:
		var button := Button.new()
		button.text = WorldMapLayout.zone_name(zone_id, infos, world.data.passages)
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 13)
		button.pressed.connect(select_zone.bind(zone_id))
		_zone_row.add_child(button)
		_zone_buttons[zone_id] = button


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_M:
		toggle()
		get_viewport().set_input_as_handled()


func _on_backdrop_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.pressed:
		close()


func _set_visible(shown: bool) -> void:
	_panel.visible = shown
	_backdrop.visible = shown


# --- Construction des contrôles ----------------------------------------------------------------

func _build() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0, 0, 0, 0.35)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.gui_input.connect(_on_backdrop_input)
	add_child(_backdrop)
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 1.0
	# Assez étroite pour laisser voir la minicarte (bande gauche) ; fenêtre au premier plan, elle
	# peut couvrir le haut de la barre du bas.
	_panel.offset_left = -410
	_panel.offset_right = 410
	_panel.offset_top = 76
	_panel.offset_bottom = -BOTTOM_MARGIN
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.1, 0.07, 0.97)
	style.border_color = Color(0.55, 0.42, 0.22)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var window_title := _label(22, GOLD)
	window_title.text = "Carte du monde"
	window_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(window_title)
	var close_button := Button.new()
	close_button.text = "×"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(close)
	header.add_child(close_button)

	_zone_row = HFlowContainer.new()
	_zone_row.add_theme_constant_override("h_separation", 6)
	column.add_child(_zone_row)

	var zone_row := HBoxContainer.new()
	column.add_child(zone_row)
	_zone_title = _label(19, Color(0.95, 0.92, 0.85))
	_zone_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone_row.add_child(_zone_title)
	_clear_pin = Button.new()
	_clear_pin.focus_mode = Control.FOCUS_NONE
	_clear_pin.pressed.connect(pin_cleared.emit)
	zone_row.add_child(_clear_pin)
	_zone_info = _label(14, Color(0.78, 0.75, 0.66))
	_zone_info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	zone_row.add_child(_zone_info)

	var frame := PanelContainer.new()
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.09, 0.07, 0.05)
	frame_style.border_color = Color("5a4630")
	frame_style.set_border_width_all(1)
	frame_style.set_corner_radius_all(4)
	frame_style.set_content_margin_all(4)
	frame.add_theme_stylebox_override("panel", frame_style)
	column.add_child(frame)
	_grid = ZoneGrid.new()
	_grid.cell_fixed = zoom_cell()
	_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	_grid.mouse_default_cursor_shape = Control.CURSOR_MOVE
	_grid.resized.connect(_grid.queue_redraw)
	_grid.gui_input.connect(_on_grid_input)
	_grid.mouse_exited.connect(hover.bind(Vector2(-1e6, -1e6)))
	frame.add_child(_grid)

	# Légende : une case par sorte d'icône, pour l'afficher ou la masquer (minicarte comprise).
	var filters := HFlowContainer.new()
	filters.add_theme_constant_override("h_separation", 10)
	column.add_child(filters)
	for kind in MapIcons.KINDS:
		var toggle := CheckBox.new()
		toggle.text = MapIcons.NAMES[kind]
		toggle.focus_mode = Control.FOCUS_NONE
		toggle.add_theme_font_size_override("font_size", 12)
		toggle.add_theme_color_override("font_color", MapIcons.COLORS[kind])
		toggle.add_theme_color_override("font_hover_color", MapIcons.COLORS[kind].lightened(0.2))
		toggle.add_theme_color_override("font_pressed_color", MapIcons.COLORS[kind])
		toggle.button_pressed = kind not in Options.hidden_icons
		toggle.toggled.connect(_on_icon_toggled.bind(kind))
		filters.add_child(toggle)
		_icon_toggles[kind] = toggle
	var legend := _label(13, Color(0.7, 0.67, 0.6))
	legend.text = "Cadre doré : vous êtes ici.  Épingle rouge : repère ou drapeau.  Épingle jaune : objectif de la " \
		+ "quête suivie.  Vert : membres du groupe et leurs repères.  Icônes : A atelier, M marchand, C coffre, B mini-boss, ! quête."
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(legend)
	var hint := _label(12, Color(0.6, 0.58, 0.52))
	hint.text = "M : ouvrir / fermer.  Molette : zoom.  Glisser : se déplacer.  Clic droit : drapeau (Maj : montré au groupe)."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hint)


func _on_icon_toggled(shown: bool, kind: String) -> void:
	Options.hidden_icons.erase(kind)
	if not shown:
		Options.hidden_icons.append(kind)
	Options.save_options()
	_grid.queue_redraw()
	icons_changed.emit()


## Molette : zoom ; glisser : déplace la vue ; survol : nomme la zone en haut ; clic droit : drapeau
## (Maj : montré au groupe).
func _on_grid_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null:
		if button.pressed and button.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			zoom(1 if button.button_index == MOUSE_BUTTON_WHEEL_UP else -1, button.position)
			_grid.accept_event()
		elif button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed:
				_drag_from = button.position
				_drag_pan = _grid.clamped_pan(_grid.pan)
				_dragged = false
			else:
				_drag_from = Minimap.NO_POINT
		elif button.button_index == MOUSE_BUTTON_RIGHT and button.pressed:
			var case := _grid.case_at(button.position)
			if not case.is_empty():
				flag_requested.emit(flag_pin(case), button.shift_pressed)
		return
	var motion := event as InputEventMouseMotion
	if motion == null:
		return
	if _drag_from != Minimap.NO_POINT and motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
		drag_to(motion.position)
		return
	hover(motion.position)


## Survol de ce point de la grille : les cartes de la zone survolée sont entourées, et la zone est
## nommée en haut.
func hover(point: Vector2) -> void:
	var case := _grid.case_at(point)
	var zone_id: String = case.get("zone", "")
	if zone_id != _grid.hover_zone:
		_grid.hover_zone = zone_id
		_grid.queue_redraw()
	if not zone_id.is_empty() and zone_id != _focus_zone:
		_focus_zone = zone_id
		_refresh_zone_title()


## Glisser jusqu'à ce point de la grille (depuis l'appui).
func drag_to(point: Vector2) -> void:
	var moved := point - _drag_from
	if moved.length() > 4.0:
		_dragged = true
	if _dragged:
		_grid.pan = _grid.clamped_pan(_drag_pan - moved)
		_grid.queue_redraw()


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
