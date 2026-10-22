class_name QuestLinks
extends RefCounted
## Mots cliquables des textes de quête (proposition d'un PNJ, journal) : les noms des PNJ, des cartes
## et des zones deviennent des liens. Un clic pose un repère (`Session.quest_pin`) sur la minicarte
## et la carte du monde, là où est le PNJ (devant la porte s'il est dans une maison), la carte, ou
## la Pierre de Passage de la zone.
##
## Noms reconnus : le nom complet d'un PNJ, son nom court (sans sa fonction, avant la virgule) et
## chaque mot de ce nom qui le désigne seul (« Grumm », « Pansu ») : avec une majuscule, 4 lettres
## au moins, ni titre (`TITLES`) ni épithète après « le », « la » (« la Cogneuse »), et propre à
## un seul PNJ. Pour une carte : son nom complet, son nom court, avec ou sans majuscule. Pour une
## zone : son nom. Un nom qui désignerait deux endroits n'est pas un lien.

## Couleur des liens.
const LINK_COLOR := Color("8fc8ff")
## Titres qui ne désignent pas un PNJ à eux seuls.
const TITLES := ["Mère", "Père", "Frère", "Maître", "Mamie", "Tantine", "Sergent", "Sergente", "Capitaine"]
const EPITHET_ARTICLES := ["le", "la"]
const META_PREFIX := "repere:"

## Noms reconnus du dernier monde (voir `names`), indexés par leur première lettre.
static var _cache_key := 0
static var _cache: Dictionary = {}


## Repère d'un nom : { carte (à coordonnées), nom } ; index par première lettre : [{ texte, carte,
## nom }], du plus long au plus court.
static func names(world: World) -> Dictionary:
	if _cache_key == world.get_instance_id() and not _cache.is_empty():
		return _cache
	var found := {}  # texte → { carte, nom } ; {} si le texte est ambigu.
	var ids: Array[String] = world.map_ids.duplicate()
	if world.map != null and world.map.id not in ids:
		ids.append(world.map.id)
	ids.sort()
	# PNJ : les mots seuls ne comptent que s'ils sont propres à un PNJ.
	var words := {}
	for map_id in ids:
		var map := world.map_by_id(map_id)
		var outdoor := outdoor_map(world, map_id)
		if map == null or outdoor.is_empty():
			continue
		for npc: Dictionary in map.npcs:
			var full: String = npc["nom"]
			var short := full.split(",")[0].strip_edges()
			var pin := {"carte": outdoor, "nom": short}
			_add(found, full, pin)
			_add(found, short, pin)
			for word in _own_words(short):
				words[word] = pin if not words.has(word) else {}
	for word: String in words:
		if not words[word].is_empty():
			_add(found, word, words[word])
	# Cartes et zones (la zone : sa Pierre de Passage, à défaut sa première carte).
	var zones := {}
	for map_id in ids:
		var coordinates := WorldMapLayout.map_coordinates(map_id)
		var map := world.map_by_id(map_id)
		if coordinates.is_empty() or map == null:
			continue
		var short := WorldMapLayout.short_name(map.display_name)
		var bare := short.get_slice(" (", 0)
		var pin := {"carte": map_id, "nom": bare}
		for text in [map.display_name, short, bare, bare.left(1).to_lower() + bare.substr(1)]:
			_add(found, text, pin)
		var zone_name := map.display_name.get_slice(" — ", 0)
		if zone_name != map.display_name and not zones.has(zone_name):
			zones[zone_name] = {"carte": _zone_map(world, coordinates["zone"], map_id), "nom": zone_name}
	for zone_name: String in zones:
		_add(found, zone_name, zones[zone_name])
	var index := {}
	for text: String in found:
		if found[text].is_empty():
			continue
		var entry: Dictionary = found[text].duplicate()
		entry["texte"] = text
		var first := text.left(1)
		if not index.has(first):
			index[first] = []
		index[first].append(entry)
	for first: String in index:
		index[first].sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["texte"].length() > b["texte"].length())
	_cache_key = world.get_instance_id()
	_cache = index
	return index


## Texte en BBCode, les noms reconnus en liens (le reste échappé). Le nom du repère est encodé comme
## une URL : une apostrophe (« Feuille-d'Argent ») dans `[url=…]` casse l'analyse du BBCode de Godot.
static func linkify(text: String, world: World) -> String:
	var index := names(world)
	var out := ""
	var i := 0
	while i < text.length():
		var matched: Dictionary = {}
		if i == 0 or not _is_word_char(text[i - 1]):
			for entry: Dictionary in index.get(text[i], []):
				var length: int = entry["texte"].length()
				if text.substr(i, length) == entry["texte"] and (i + length >= text.length() or not _is_word_char(text[i + length])):
					matched = entry
					break
		if matched.is_empty():
			out += "[lb]" if text[i] == "[" else text[i]
			i += 1
			continue
		out += "[color=#%s][url=%s%s|%s]%s[/url][/color]" % [LINK_COLOR.to_html(false), META_PREFIX, matched["carte"],
			str(matched["nom"]).uri_encode(), matched["texte"].replace("[", "[lb]")]
		i += matched["texte"].length()
	return out


## Repère d'un lien cliqué ({ carte, nom }), ou {} si ce n'est pas un lien de quête.
static func parse(meta: Variant) -> Dictionary:
	var text := str(meta)
	if not text.begins_with(META_PREFIX):
		return {}
	var parts := text.substr(META_PREFIX.length()).split("|")
	return {"carte": parts[0], "nom": parts[1].uri_decode() if parts.size() > 1 else parts[0]}


## Texte riche aux liens de quête : un clic appelle `on_pin` avec le repère, le survol l'annonce.
static func make_label(font_size: int, color: Color, on_pin: Callable) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_color_override("default_color", color)
	label.meta_clicked.connect(func(meta: Variant) -> void:
		var pin := parse(meta)
		if not pin.is_empty():
			on_pin.call(pin))
	label.meta_hover_started.connect(func(meta: Variant) -> void:
		var pin := parse(meta)
		label.tooltip_text = "" if pin.is_empty() else "Poser un repère sur la carte : %s" % pin["nom"])
	label.meta_hover_ended.connect(func(_meta: Variant) -> void: label.tooltip_text = "")
	return label


## Carte à coordonnées d'une carte : elle-même, ou pour une maison celle où mène sa porte ("" sinon).
static func outdoor_map(world: World, map_id: String) -> String:
	if not WorldMapLayout.map_coordinates(map_id).is_empty():
		return map_id
	var map := world.map_by_id(map_id)
	if map != null:
		for target: String in map.doors.values():
			if not WorldMapLayout.map_coordinates(target).is_empty():
				return target
	return ""


static func _add(found: Dictionary, text: String, pin: Dictionary) -> void:
	if text.is_empty():
		return
	if found.has(text) and found[text] != pin:
		found[text] = {}
	elif not found.has(text):
		found[text] = pin


## Mots d'un nom court qui désignent le PNJ seuls (voir l'en-tête).
static func _own_words(short: String) -> Array[String]:
	var words := short.split(" ", false)
	var own: Array[String] = []
	if words.size() < 2:
		return own
	for i in words.size():
		var word := words[i]
		if word.length() < 4 or word.left(1) == word.left(1).to_lower() or word in TITLES:
			continue
		if i > 0 and words[i - 1] in EPITHET_ARTICLES:
			continue
		own.append(word)
	return own


static func _zone_map(world: World, zone_id: String, fallback: String) -> String:
	var stones: Array[String] = []
	for passage: Dictionary in world.data.passages.values():
		var stone_map := str(passage.get("carte", ""))
		if WorldMapLayout.map_coordinates(stone_map).get("zone", "") == zone_id:
			stones.append(stone_map)
	stones.sort()
	return stones[0] if not stones.is_empty() else fallback


static func _is_word_char(c: String) -> bool:
	return c.to_lower() != c.to_upper() or c.is_valid_int() or c == "-" or c == "_"
