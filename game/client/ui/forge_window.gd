class_name ForgeWindow
extends CanvasLayer
## Forge à l'enclume de la maison (`Forge`) : à gauche le sac (ressources de forge et plans, en icônes),
## qu'on clique ou glisse vers les 8 cases de la recette en bas au centre ; au centre le type d'objet,
## l'aperçu (lignes, jets possibles, palier) et le nom fait de mots proposés ; à droite le jet obtenu. Trois onglets
## (`Infusion`, sur le modèle de l'atelier d'objets HTML) : Forge ; Essences (ressources identiques → une essence) ;
## Infusion (une essence sur un équipement, sa fiche à droite avec ses lignes d'exo, et l'historique des essais).

const GOLD := Color(0.95, 0.76, 0.3)
const REFUSALS := {
	Protocol.REASON_MISSING_INGREDIENTS: "Il manque des ressources.",
	Protocol.REASON_INVENTORY_FULL: "Inventaire plein.",
	Protocol.REASON_TOO_FAR: "L'enclume est trop loin.",
	Protocol.REASON_TOO_MANY_LINES: "Trop de lignes : %d au plus par objet." % Forge.MAX_LINES,
}

var map_view: MapView
var _anvil := Vector2i.ZERO
var _type := "coiffe"
## Ressources posées sur l'enclume, dans l'ordre des cases : id : quantité.
var _chosen := {}
## Plan choisi (id), ou "".
var _plan := ""
## Vrai quand une feuille de papier est dans la 9e case : elle recevra le patron de l'objet.
var _paper := false
## Vrai quand le joueur a touché au nom : on ne lui remet plus les mots proposés.
var _named := false
var _backdrop: ColorRect
var _panel: PanelContainer
var _job_label: Label
var _types: OptionButton
var _bag: ItemList
var _slots: Array[Button] = []
var _paper_slot: Button
var _preview: Label
var _words: Array[OptionButton] = []
var _forge_button: Button
var _message: Label
## Avertissement en rouge : ressources perdues si l'on forge (caractéristique hors de portée du palier de forge).
var _warning: Label
var _result_icon: TextureRect
var _result: Label
## Onglet (`MODES`), ressource choisie (id), essence et équipement choisis (uids), contrôles, essais d'infusion.
const MODES := {"forge": "Forge", "essence": "Essences", "infusion": "Infusion"}
var _mode := "forge"
var _source := ""
var _essence := ""
var _target := ""
var _forge_parts: Array[Control] = []
var _tabs: TabBar
var _essence_box: VBoxContainer
var _essence_text: Label
var _infusion_box: VBoxContainer
var _infusion_text: Label
var _journal: PackedStringArray = []
var _journal_label: RichTextLabel
var _card: RichTextLabel
var _right_title: Label
var _result_scroll: Control
var _stat_choice: OptionButton
var _perfect: CheckBox


## Lignes de forge d'un modèle pour ses infobulles : caractéristique et matière d'une ressource
## (cachée sans la réputation d'artisan), contenu d'un plan ou d'un patron (ses jets et ses effets).
static func forge_lines(template: Dictionary, data: GameData, character: Character) -> PackedStringArray:
	var lines: PackedStringArray = []
	if template.has("caracteristique") and character != null:
		var tier := int(template.get("niveau", 1))
		lines.append("Forge : %s" % (", ".join(Forge.stats_of(template).map(func(s: String) -> String:
			return "+%d %s" % [Forge.value(s, tier, template.get("rarete") == "rare"), Item.stat_name(s)])) if Forge.reveals(character, tier) else "caractéristique inconnue (réputation de forgeron trop basse pour le palier %d)" % tier))
	if template.has("matiere"):
		lines.append("Matière : %s" % template["matiere"])
	var plan: Dictionary = template.get("recette", template.get("patron", {}))
	if not plan.is_empty() and data != null:
		lines.append("%s : %s" % [Forge.TYPE_NAMES.get(plan.get("type"), "Objet"), plan["nom"]])
		for item_id: String in plan["ressources"]:
			lines.append("  • %d %s" % [plan["ressources"][item_id], data.items.get(item_id, {}).get("nom", item_id)])
		if plan.has("objet"):
			return lines
		var details := roll_lines(plan["jets"], plan["bonus"]) + InventoryWindow.attack_lines(Item.entry_template({"objet": Forge.template_id(plan["type"]),
			"forge": {"nom": "", "artisan": "", "palier": plan["palier"], "bonus": plan["bonus"]}}, data.items)) if plan.has("jets") \
			else InventoryWindow.bonus_range_lines(Forge.preview(plan["type"], plan["ressources"], data.items, character, false)["bonus"])
		for line in details:
			lines.append("  " + line)
	return lines


## Jets obtenus avec leur plage : « +9 Initiative (8 à 11) ».
static func roll_lines(jets: Dictionary, bonus: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	for stat: String in jets:
		var span: Array = bonus.get(stat, [])
		lines.append("+%d %s%s" % [jets[stat], Item.stat_name(stat), " (%d à %d)" % span if span.size() == 2 and span[0] != span[1] else ""])
	return lines


func _ready() -> void:
	_build()
	_set_visible(false)


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.anvil_opened.connect(open)
	map_view.craft_result.connect(_on_result)
	map_view.inventory_changed.connect(refresh)
	map_view.combat_started.connect(close)
	map_view.map_changed.connect(close)


func open(event: Dictionary) -> void:
	_anvil = event["case"]
	_chosen = {}
	_plan = ""
	_named = false
	_paper = false
	_message.text = ""
	_result.text = "Le jet obtenu s'affichera ici."
	_result_icon.texture = null
	_source = ""
	_essence = ""
	_target = ""
	_journal = []
	_set_visible(true)
	_set_mode("forge")


func close() -> void:
	_set_visible(false)


func is_open() -> bool:
	return _panel.visible


func refresh() -> void:
	if map_view == null or not is_open():
		return
	var world := map_view.world
	var character := world.character
	var reputation_value := character.job_reputation(Forge.JOB)
	_job_label.text = "Forgeron %s (réputation %d)" % [Character.tier_name(Character.tier_index(reputation_value)), reputation_value]
	_types.select(Forge.TYPES.keys().find(_type))
	_bag.clear()
	for entry: Dictionary in character.inventory_sheet(world.data)["objets"]:
		var template := Item.entry_template(character.inventory.entries.get(entry["uid"], entry), world.data.items)
		var left := int(entry["quantite"]) - ((1 if _paper else 0) if entry["objet"] == Forge.PAPER else int(_chosen.get(entry["objet"], 0)))
		if _mode != "forge":
			if template.has("caracteristique") if _mode == "essence" else entry["objet"] == Infusion.TEMPLATE or Item.is_equipment(template):
				InventoryWindow.add_bag_item(_bag, entry, "\n".join([entry["nom"]] + Array(forge_lines(template, world.data, character))))
		elif template.has("recette") or template.has("patron") or (left > 0 and (entry["objet"] == Forge.PAPER or template.get("type") == Item.TYPE_RESOURCE and (template.has("caracteristique") or template.has("matiere")))):
			InventoryWindow.add_bag_item(_bag, entry.merged({"quantite": left}, true),
				"\n".join([entry["nom"] + (" (cliquer pour le suivre)" if template.has("recette") or template.has("patron") else "")] + Array(forge_lines(template, world.data, character))))
	var ids := _chosen.keys()
	for i in _slots.size():
		var item_id: String = ids[i] if i < ids.size() else ""
		_slots[i].set_meta("objet", item_id)
		_slots[i].icon = InventoryWindow.item_icon(item_id) if not item_id.is_empty() else null
		_slots[i].text = "×%d" % _chosen[item_id] if not item_id.is_empty() else ""
		_slots[i].tooltip_text = "%s ×%d (clic : en retirer un, Ctrl + clic : tout retirer)" % [world.data.items[item_id]["nom"], _chosen[item_id]] if not item_id.is_empty() else ""
	_paper_slot.icon = InventoryWindow.item_icon(Forge.PAPER) if _paper else null
	_show_essence() if _mode == "essence" else _show_infusion() if _mode == "infusion" else _show_preview()


## Onglet Essences : ressource choisie et caractéristiques possibles (miroirs au palier Maître), essence obtenue.
func _show_essence() -> void:
	var world := map_view.world
	var inventory := world.character.inventory
	var resource: Dictionary = world.data.items.get(_source, {})
	var mirror := Character.tier_index(world.character.job_reputation(Forge.JOB)) >= Infusion.MIRROR_TIER
	var chosen: Variant = _stat_choice.get_item_metadata(_stat_choice.selected) if _stat_choice.selected >= 0 else ""
	_stat_choice.clear()
	for stat: String in Forge.stats_of(resource):
		for option: String in [stat] + (Infusion.mirrors(stat) if mirror else []):
			_stat_choice.add_item(Item.stat_name(option) + ("" if option == stat else " (miroir)"))
			_stat_choice.set_item_metadata(_stat_choice.item_count - 1, option)
			if option == chosen:
				_stat_choice.select(_stat_choice.item_count - 1)
	_essence_text.text = "Cliquez une ressource du sac."
	if not resource.is_empty() and _stat_choice.item_count > 0:
		var result := Infusion.essence(resource, _stat_choice.get_item_metadata(_stat_choice.selected), _perfect.button_pressed, mirror)
		_essence_text.text = "%s : %d en stock, %d par essence\n\n%s" % [resource["nom"], inventory.quantity_of(_source), result.get("quantite", 0),
			"Essence obtenue : %s\nRéussite à l'infusion : %d %%" % [Infusion.essence_name(result["essence"]), _chance(result["essence"])] if result["erreur"].is_empty() else "Impossible : valeur nulle."]


## Onglet Infusion : essence et équipement choisis, ce que ferait l'essence et sa chance ; fiche de l'objet à droite.
func _show_infusion() -> void:
	var world := map_view.world
	var inventory := world.character.inventory
	var essence: Dictionary = inventory.entries.get(_essence, {}).get("forge", {}).get("essence", {})
	var target: Dictionary = inventory.entries.get(_target, {})
	var lines: PackedStringArray = ["Essence : %s" % (Infusion.essence_name(essence) if not essence.is_empty() else "cliquez une essence du sac."),
		"Équipement : %s" % (Item.entry_template(target, world.data.items)["nom"] if not target.is_empty() else "cliquez un équipement du sac.")]
	if not essence.is_empty() and not target.is_empty():
		var preview := Infusion.apply_preview(target, essence)
		lines.append("\n" + ("Refusée : ligne au plafond, ou plus de %d points de score d'exo." % Infusion.MAX_EXO_SCORE if not preview["erreur"].is_empty() else
			"%s : %s passe à %d\nRéussite : %d %% (un échec perd l'essence, jamais l'objet)" % ["Renfort d'une ligne du jet" if preview["renfort"] else "Ligne en exo",
				Item.stat_name(essence["caracteristique"]), preview["valeur"], _chance(essence)]))
	_infusion_text.text = "\n".join(lines)
	_card.text = card_text(target, world.data) if not target.is_empty() else "[color=#999]Cliquez un équipement du sac.[/color]"
	_journal_label.text = "\n".join(_journal)


func _chance(essence: Dictionary) -> int:
	return Infusion.chance(essence, map_view.world.character.tool_stat(Forge.JOB, "distillation"))


## Fiche d'un équipement : nom, palier, jets avec leur plage, lignes d'exo en bleu et score d'exo (BBCode).
static func card_text(entry: Dictionary, data: GameData) -> String:
	var exo: Dictionary = entry.get("exo", {})
	var forge: Dictionary = entry.get("forge", {})
	var jets := {}
	for stat: String in entry.get("jets", {}):
		if not exo.has(stat):
			jets[stat] = entry["jets"][stat]
	var lines: PackedStringArray = ["[b]%s[/b]" % Item.entry_template(entry, data.items)["nom"]] + (["Palier %d" % forge["palier"]] if forge.has("palier") else [])
	lines.append_array(roll_lines(jets, forge.get("bonus", {})))
	var score := 0.0
	for stat: String in exo:
		lines.append("[color=#7fd3e8]+%d %s (exo)[/color]" % [exo[stat], Item.stat_name(stat)])
		score += Infusion.score(stat, exo[stat])
	lines.append("[color=#999]Exo : %d / %d points de score[/color]" % [roundi(score), Infusion.MAX_EXO_SCORE])
	return "\n".join(lines)


func _send_infusion(apply: bool) -> void:
	var command := {"type": Protocol.CMD_INFUSE, "entite": map_view.world.player_id, "case": _anvil}
	command.merge({"essence": _essence, "objet": _target} if apply else {"ressource": _source, "parfaite": _perfect.button_pressed,
		"caracteristique": _stat_choice.get_item_metadata(_stat_choice.selected) if _stat_choice.selected >= 0 else ""})
	map_view.send_command(command)


func _set_mode(mode: String) -> void:
	_mode = mode
	_tabs.current_tab = MODES.keys().find(mode)
	for part in _forge_parts:
		part.visible = mode == "forge"
	_essence_box.visible = mode == "essence"
	_infusion_box.visible = mode == "infusion"
	_card.visible = mode == "infusion"
	_result_icon.visible = mode == "forge"
	_result_scroll.visible = mode == "forge"
	_right_title.text = "Équipement choisi" if mode == "infusion" else "Objet forgé"
	_right_title.get_parent().visible = mode != "essence"
	(_bag.get_parent().get_child(0) as Label).text = {"forge": "Sac : ressources, plans, patrons et papier (clic, Ctrl + clic : tout, ou glisser vers la recette)",
		"essence": "Sac : ressources de forge (clic pour choisir)", "infusion": "Sac : essences et équipements (clic pour choisir)"}[mode]
	_message.text = ""
	refresh()


func _show_preview() -> void:
	var data := map_view.world.data
	var plan: Dictionary = data.items.get(_plan, {}).get("recette", {})
	if plan.has("objet"):  # Objet tout fait (clé de donjon) : ses ressources, rien à tirer.
		_update_words({}, {}, plan)
		_preview.text = "\n".join(PackedStringArray(["Objet : %s" % plan["nom"], "", "Nom : %s" % _name()]))
		_warn_lost({}, false)
		_forge_button.disabled = not _owns_all()
		return
	var preview := Forge.preview(_type, _chosen, data.items, map_view.world.character, plan.is_empty())
	# Adjectifs et élément d'attaque d'après toutes les lignes, même cachées : ils laissent deviner l'objet.
	var complete := Forge.preview(_type, _chosen, data.items, map_view.world.character, false)
	var full: Dictionary = complete["bonus"]
	var places := {}
	for key: String in complete["lieux"]:
		places[key] = Forge.place_word(key, data)
	_update_words(full, places, plan)
	var lines: PackedStringArray = ["%s, palier %d" % [Forge.TYPE_NAMES[_type], preview["palier"]]]
	lines.append_array(InventoryWindow.bonus_range_lines(preview["bonus"]))
	lines.append_array(InventoryWindow.attack_lines(Item.entry_template({"objet": Forge.template_id(_type),
		"forge": {"nom": "", "artisan": "", "palier": preview["palier"], "bonus": full}}, data.items)))
	if preview["cachees"] > 0:
		lines.append("+ %d ressource(s) à la caractéristique inconnue" % preview["cachees"])
	lines.append("")
	lines.append("Ressources différentes : %d / %d · matières : %s" % [_chosen.size(), Forge.MAX_SLOTS,
		", ".join(PackedStringArray(Forge.TYPES[_type]["matieres"]))])
	if not preview["manquantes"].is_empty():
		lines.append("Manque : %s" % ", ".join(PackedStringArray(preview["manquantes"])))
	if preview["erreur"] == Protocol.REASON_TOO_MANY_LINES:
		lines.append(REFUSALS[Protocol.REASON_TOO_MANY_LINES])
	lines.append("Nom : %s" % _name())
	if plan.is_empty() and not _name().is_empty():
		var keys: Array = Forge.keywords(_words_chosen(), _type, full.keys(), places)
		lines.append("Panoplies : %s" % (", ".join(keys.map(func(key: String) -> String: return Forge.set_title(key, data))) if not keys.is_empty() else "aucune"))
	_preview.text = "\n".join(lines)
	_warn_lost(preview["perdues"], plan.is_empty())
	_forge_button.disabled = not preview["erreur"].is_empty() or not _owns_all()


## Ressources posées dont une caractéristique dépasse le palier de forge : avertissement et cases en rouge (sans
## nommer une caractéristique cachée).
func _warn_lost(lost: Dictionary, hidden: bool) -> void:
	var items := map_view.world.data.items
	var lines: PackedStringArray = []
	for slot: Button in _slots:
		slot.modulate = Color(1.0, 0.45, 0.4) if lost.has(slot.get_meta("objet", "")) else Color.WHITE
	for item_id: String in lost:
		var known: bool = not hidden or Forge.reveals(map_view.world.character, int(items[item_id].get("niveau", 1)))
		for stat: String in lost[item_id]:
			var what: String = Item.stat_name(stat) if known else "sa caractéristique"
			lines.append("ATTENTION, perdu si vous forgez : %s ×%d ne donnera rien, %s %s." % [items[item_id]["nom"], _chosen.get(item_id, 0), what,
				"ne sert pas à cet outil" if lost[item_id][stat] == 0 else "demande le palier de forge %d (vous êtes au palier %d)" % [
				lost[item_id][stat], Forge.tier(map_view.world.character)]])
	_warning.text = "\n".join(lines)
	_warning.visible = not lines.is_empty()


## Choix du nom : le nom du type puis trois mots clés, adjectifs des lignes de l'objet ou mots de famille et de zone
## permis (`places`, mot clé → mot ; un plan impose son nom). Les mots proposés ne s'appliquent que tant que le joueur
## n'a pas touché au nom ; un adjectif choisi suit le genre du nom.
func _update_words(bonus: Dictionary, places: Dictionary, plan: Dictionary) -> void:
	var noun: String = _words[0].get_item_text(_words[0].selected) if _words[0].selected >= 0 else ""
	var wanted := Forge.default_words(_type, bonus)
	if Forge.gender(_type, noun).is_empty():
		noun = wanted[0]
	var previous: Array = _words.slice(1).map(func(option: OptionButton) -> Variant:
		return option.get_item_metadata(option.selected) if option.selected > 0 else null)
	_words[0].clear()
	for entry: Array in Forge.TYPES[_type]["noms"]:
		_words[0].add_item(entry[0])
		if entry[0] == noun:
			_words[0].select(_words[0].item_count - 1)
	for i in range(1, _words.size()):
		var option := _words[i]
		option.clear()
		option.add_item("—")
		option.select(0)
		for stat: String in bonus:
			for k in Forge.WORDS[stat].size():
				option.add_item(Forge.adjective(Forge.WORDS[stat][k], Forge.gender(_type, noun)))
				option.set_item_metadata(option.item_count - 1, [stat, k])
				if typeof(previous[i - 1]) == TYPE_ARRAY and previous[i - 1] == [stat, k] or (not _named and i < wanted.size() and Forge.adjective(Forge.WORDS[stat][k], Forge.gender(_type, wanted[0])) == wanted[i]):
					option.select(option.item_count - 1)
		for key: String in places:
			option.add_item(places[key])
			option.set_item_metadata(option.item_count - 1, key)
			if typeof(previous[i - 1]) == TYPE_STRING and previous[i - 1] == key:
				option.select(option.item_count - 1)
	for option in _words:
		option.disabled = not plan.is_empty()


func _words_chosen() -> Array:
	var words: Array = []
	for option in _words:
		if option.selected >= 0 and option.get_item_text(option.selected) != "—" and option.get_item_text(option.selected) not in words:
			words.append(option.get_item_text(option.selected))
	return words


func _name() -> String:
	var plan: Dictionary = map_view.world.data.items.get(_plan, {}).get("recette", {})
	return plan["nom"] if not plan.is_empty() else " ".join(_words_chosen())


func _owns_all() -> bool:
	var inventory := map_view.world.character.inventory
	for item_id: String in _chosen:
		if inventory.quantity_of(item_id) < int(_chosen[item_id]):
			return false
	return not _chosen.is_empty()


func _change(item_id: String, delta: int) -> void:
	if item_id == Forge.PAPER:
		_paper = delta > 0
		refresh()
		return
	if delta > 0 and not _chosen.has(item_id) and _chosen.size() >= Forge.MAX_SLOTS:
		_message.text = "%d ressources différentes au plus." % Forge.MAX_SLOTS
		return
	_plan = ""
	_chosen[item_id] = int(_chosen.get(item_id, 0)) + delta
	if _chosen[item_id] <= 0:
		_chosen.erase(item_id)
	_message.text = ""
	refresh()


func _can_drop_on_recipe(_at: Vector2, dragged: Variant) -> bool:
	return typeof(dragged) == TYPE_DICTIONARY and dragged.has("forge")


func _drop_on_recipe(at: Vector2, dragged: Variant) -> void:
	if _can_drop_on_recipe(at, dragged):
		_change(dragged["forge"], 1)


## Suit un plan (`plan_id` : son nom est imposé) ou un patron (le nom reste à choisir) : type et ressources.
func _follow(recipe: Dictionary, plan_id: String) -> void:
	_plan = plan_id
	_type = recipe.get("type", _type)
	_chosen = recipe["ressources"].duplicate()
	refresh()


func _on_forge_pressed() -> void:
	var command := {"type": Protocol.CMD_FORGE, "entite": map_view.world.player_id, "case": _anvil}
	command.merge({"recette": _plan} if not _plan.is_empty() else {"type_objet": _type, "ressources": _chosen.duplicate(), "mots": _words_chosen()})
	command["papier"] = _paper
	map_view.send_command(command)


func _on_result(event: Dictionary) -> void:
	var refused: bool = event["type"] == Protocol.EVT_REFUSED
	if event["type"] == Protocol.EVT_INFUSED or refused and event["commande"] == Protocol.CMD_INFUSE:
		_message.text = REFUSALS.get(event.get("raison"), "Impossible.") if refused else "Essence créée : " + event["nom"] if not event.has("objet") else ""
		_message.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4) if refused else Color(0.55, 0.9, 0.5))
		if event.has("objet"):  # Essai d'infusion : en tête de l'historique.
			_journal.insert(0, "[color=%s]%s sur %s : %s (%d %%)[/color]" % ["#8fce7a" if event["reussi"] else "#e2726a", Infusion.essence_name(event["essence"]),
				event["nom"], "réussite" if event["reussi"] else "échec, l'essence est perdue", event["chance"]])
			_journal = _journal.slice(0, 30)
			_essence = ""
		refresh()
		return
	_message.text = REFUSALS.get(event.get("raison"), "Impossible.") if refused else "Forgé : %s%s%s" % [event["nom"], ", et son patron" if event.get("patron", false) else "",
		" (épargnées : %d ressources)" % event["epargne"].values().reduce(func(a: int, b: int) -> int: return a + b, 0) if not event.get("epargne", {}).is_empty() else ""]
	_message.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4) if refused else Color(0.55, 0.9, 0.5))
	if not refused:
		_chosen = {}
		_plan = ""
		_named = false
		_result_icon.texture = InventoryWindow.item_icon(event["objet"])
		_paper = false
		_result.text = "\n".join(PackedStringArray([event["nom"], "Palier %d" % event.get("palier", 1), ""]) + roll_lines(event.get("jets", {}), event.get("bonus", {})))
	refresh()


func _set_visible(shown: bool) -> void:
	_panel.visible = shown
	_backdrop.visible = shown


# --- Construction des contrôles ----------------------------------------------------------------

func _build() -> void:
	var frame := UiTheme.window_frame(self, "Enclume", close)
	_backdrop = frame.backdrop
	_panel = frame.panel
	var column: VBoxContainer = frame.column
	_job_label = UiTheme.header_add(frame, _label(15, GOLD))
	_tabs = UiTheme.tabs(MODES.values(), func(tab: int) -> void:
		if MODES.keys()[tab] != _mode:
			_set_mode(MODES.keys()[tab]))
	for tab in MODES.size():
		_tabs.set_tab_tooltip(tab, ["Forger un équipement", "Infuser des ressources identiques en une essence", "Appliquer une essence à un équipement"][tab])
	column.add_child(_tabs)

	# Variante B (choix de l'auteur) : la recette et le bouton Forger en bandeau en haut, le sac dessous à
	# gauche, l'aperçu au centre, la fiche de l'objet à droite sur toute la hauteur.
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	column.add_child(row)
	var main := VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 10)
	row.add_child(main)
	var band := HBoxContainer.new()
	band.add_theme_constant_override("separation", 14)
	main.add_child(band)
	var lower := HBoxContainer.new()
	lower.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lower.add_theme_constant_override("separation", 14)
	main.add_child(lower)
	# Gauche : le sac en icônes. Un clic gauche relâché ajoute une ressource (ou suit un plan), sans la
	# molette ; on peut aussi glisser une ressource vers les cases de la recette.
	_bag = ItemList.new()
	InventoryWindow.make_bag_grid(_bag)
	_bag.custom_minimum_size = Vector2(300, 0)
	_bag.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bag.gui_input.connect(func(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		var index := _bag.get_item_at_position(click.position, true) if click != null and click.button_index == MOUSE_BUTTON_LEFT and not click.pressed else -1
		if index >= 0:  # Ctrl + clic : toute la quantité d'un coup.
			var entry: Dictionary = map_view.world.character.inventory.entries[_bag.get_item_metadata(index)]
			var template := Item.entry_template(entry, map_view.world.data.items)
			if _mode != "forge":
				if _mode == "essence":
					_source = entry["objet"]
				elif entry["objet"] == Infusion.TEMPLATE:
					_essence = entry["uid"]
				else:
					_target = entry["uid"]
				refresh()
			elif template.has("recette") or template.has("patron"):
				_follow(template.get("recette", template.get("patron")), entry["objet"] if template.has("recette") else "")
			else:
				_change(entry["objet"], int(entry["quantite"]) - int(_chosen.get(entry["objet"], 0)) if click.ctrl_pressed else 1))
	_bag.set_drag_forwarding(func(at: Vector2) -> Variant:
		var index := _bag.get_item_at_position(at, true)
		if index < 0 or map_view.world.data.items.get(_bag.get_item_metadata(index), {"recette": true}).has("recette"):  # Ni plan ni patron.
			return null
		var preview := TextureRect.new()
		preview.texture = _bag.get_item_icon(index)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.size = Vector2(40, 40)
		_bag.set_drag_preview(preview)
		return {"forge": _bag.get_item_metadata(index)}, Callable(), Callable())
	var left := _titled("Sac : ressources, plans, patrons et papier (clic, Ctrl + clic : tout, ou glisser vers la recette)", _bag)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	(left.get_child(0) as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lower.add_child(left)

	# Centre : type, nom, aperçu.
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lower.add_child(center)
	_types = OptionButton.new()
	for type: String in Forge.TYPES:
		_types.add_item(Forge.TYPE_NAMES[type])
	_types.item_selected.connect(func(index: int) -> void:
		_type = Forge.TYPES.keys()[index]
		_plan = ""
		_named = false
		refresh())
	center.add_child(_titled("Type d'objet", _types))
	_preview = _label(14, Color(0.92, 0.9, 0.85))
	_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(UiTheme.scroll_area(_preview))
	_warning = _label(15, Color(1.0, 0.35, 0.3))
	_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(_warning)
	var names := HBoxContainer.new()
	for i in 1 + Forge.MAX_KEYWORDS:
		var option := OptionButton.new()
		option.fit_to_longest_item = false
		option.custom_minimum_size = Vector2(110, 0)
		option.clip_text = true
		option.item_selected.connect(func(_index: int) -> void:
			_named = true
			_show_preview())
		names.add_child(option)
		_words.append(option)
	center.add_child(_titled("Nom de l'objet", names))
	center.move_child(center.get_child(-1), 1)  # Sous le type, au-dessus de l'aperçu.
	var slots := HBoxContainer.new()
	for i in Forge.MAX_SLOTS + 1:  # 8 cases de ressources, puis celle de la feuille de papier.
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(48, 62)
		slot.focus_mode = Control.FOCUS_NONE
		slot.expand_icon = true
		slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		slot.add_theme_font_size_override("font_size", 11)
		slot.pressed.connect(func() -> void:
			if not str(slot.get_meta("objet", "")).is_empty():
				_change(slot.get_meta("objet"), -int(_chosen.get(slot.get_meta("objet"), 1)) if Input.is_key_pressed(KEY_CTRL) else -1))
		slot.set_drag_forwarding(Callable(), _can_drop_on_recipe, _drop_on_recipe)
		slots.add_child(slot)
		_slots.append(slot)
	_paper_slot = _slots.pop_back()
	_paper_slot.set_meta("objet", Forge.PAPER)
	_paper_slot.text = "patron"
	_paper_slot.tooltip_text = "Feuille de papier (vendue par les marchands) : elle reçoit le patron de l'objet forgé"
	_paper_slot.modulate = Color(1.0, 0.9, 0.7)
	band.add_child(_titled("Recette (cliquer une case pour en retirer)", slots))
	_forge_button = Button.new()
	_forge_button.text = "Forger"
	_forge_button.focus_mode = Control.FOCUS_NONE
	_forge_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_forge_button.size_flags_vertical = Control.SIZE_SHRINK_END
	_forge_button.custom_minimum_size = Vector2(0, 62)
	_forge_button.add_theme_font_size_override("font_size", 20)
	_forge_button.pressed.connect(_on_forge_pressed)
	band.add_child(_forge_button)
	_message = _label(14, Color(0.55, 0.9, 0.5))
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_forge_parts.assign(center.get_children() + [band])
	center.add_child(_message)
	# Onglets Essences et Infusion : à la place du type, de l'aperçu, du nom et de la recette.
	_essence_box = VBoxContainer.new()
	_infusion_box = VBoxContainer.new()
	for box: VBoxContainer in [_essence_box, _infusion_box]:
		box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.visible = false
		center.add_child(box)
		center.move_child(box, 0)
	_stat_choice = OptionButton.new()
	_stat_choice.item_selected.connect(func(_index: int) -> void: refresh())
	_essence_box.add_child(_titled("Caractéristique de l'essence", _stat_choice))
	_perfect = CheckBox.new()
	_perfect.text = "Essence parfaite (× %d ressources, réussite assurée)" % Infusion.PERFECT_FACTOR
	_perfect.toggled.connect(func(_on: bool) -> void: refresh())
	_essence_box.add_child(_perfect)
	_essence_text = _label(14, Color(0.92, 0.9, 0.85))
	_infusion_text = _label(14, Color(0.92, 0.9, 0.85))
	for pair: Array in [[_essence_box, _essence_text, "Créer l'essence", false], [_infusion_box, _infusion_text, "Infuser l'essence", true]]:
		pair[1].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pair[0].add_child(pair[1])
		var button := Button.new()
		button.text = pair[2]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_send_infusion.bind(pair[3]))
		pair[0].add_child(button)
	_journal_label = RichTextLabel.new()
	_journal_label.bbcode_enabled = true
	_journal_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_infusion_box.add_child(_titled("Historique des essais", _journal_label))
	_journal_label.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Droite : l'objet forgé et ses jets.
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(220, 0)
	row.add_child(right)
	_right_title = _label(15, GOLD)
	_right_title.text = "Objet forgé"
	right.add_child(_right_title)
	_card = RichTextLabel.new()
	_card.bbcode_enabled = true
	_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_card)
	_result_icon = TextureRect.new()
	_result_icon.custom_minimum_size = Vector2(64, 64)
	_result_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_result_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	right.add_child(_result_icon)
	_result = _label(14, Color(0.92, 0.9, 0.85))
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_scroll = UiTheme.scroll_area(_result)
	right.add_child(_result_scroll)
	var hint := _label(12, Color(0.6, 0.58, 0.52))
	hint.text = "Les jets sont tirés au hasard dans les plages affichées ; votre nom est gravé sur l'objet · Échap : fermer"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hint)


func _titled(text: String, content: Control) -> VBoxContainer:
	var box := VBoxContainer.new()
	var label := _label(13, Color(0.8, 0.78, 0.7))
	label.text = text
	box.add_child(label)
	box.add_child(content)
	return box


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
