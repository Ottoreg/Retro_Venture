class_name ItemTooltipList
extends ItemList
## Liste d'objets dont l'infobulle décrit l'objet survolé et le compare à l'équipement porté au même
## emplacement : gains en vert, pertes en rouge. Le texte de l'infobulle (`set_item_tooltip`) est du
## BBCode, fait par `tooltip_text_for` ; il s'affiche dans l'infobulle native de Godot (fond opaque
## du thème, au premier plan et recalée dans l'écran).

const GAIN := Color(0.45, 0.85, 0.4)
const LOSS := Color(1.0, 0.45, 0.35)
const MIXED := Color(0.95, 0.76, 0.3)
const DIM := Color(0.62, 0.57, 0.48)


func _make_custom_tooltip(for_text: String) -> Object:
	return make_label(for_text)


## Texte riche d'une infobulle d'objet, à sa taille (sans retour à la ligne automatique).
static func make_label(bbcode: String) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("normal_font_size", 14)
	label.add_theme_color_override("default_color", UiTheme.TEXT)
	label.text = bbcode
	return label


## Infobulle d'un objet (ligne de `Character.inventory_sheet`, ou article de marchand avec ses
## plages « bonus ») : nom, type, bonus, attaque, puis la comparaison.
static func tooltip_text_for(entry: Dictionary, data: GameData, inventory: Inventory, show_ranges := false) -> String:
	var template: Dictionary = data.items.get(entry["objet"], {}) if data != null else {}
	var lines: PackedStringArray = [
		_colored(_escape(str(entry["nom"])) + (" ×%d" % int(entry["quantite"]) if int(entry.get("quantite", 1)) > 1 else ""),
			InventoryWindow.rarity_color(entry["rarete"])),
		_colored("%s, palier %d" % [InventoryWindow.TYPE_NAMES.get(entry["type"], entry["type"]), entry["niveau"]], DIM),
	]
	var bonus_lines := InventoryWindow.roll_lines(entry, template, show_ranges) if entry.has("jets") \
		else InventoryWindow.bonus_range_lines(entry.get("bonus", {}))
	for line in bonus_lines:
		lines.append(_escape(line))
	for line in InventoryWindow.attack_lines(template):
		lines.append(_escape(line))
	lines.append_array(comparison_lines(entry, data, inventory))
	return "\n".join(lines)


## Comparaison avec l'objet que l'équiper remplacerait (le premier emplacement libre, sinon le
## premier emplacement) : vide pour un objet porté, une ressource, ou sans inventaire.
static func comparison_lines(entry: Dictionary, data: GameData, inventory: Inventory) -> PackedStringArray:
	var lines: PackedStringArray = []
	var template: Dictionary = data.items.get(entry["objet"], {}) if data != null else {}
	if inventory == null or not Item.is_equipment(template):
		return lines
	if not str(entry.get("emplacement", "")).is_empty():
		lines.append("")
		lines.append(_colored("Porté", MIXED))
		return lines
	var worn := compared_entry(template, inventory)
	var worn_template: Dictionary = data.items.get(worn.get("objet", ""), {})
	lines.append("")
	lines.append(_colored("Par rapport à %s :" % _escape(str(worn_template.get("nom", worn.get("objet", "")))) if not worn.is_empty()
		else "Emplacement libre :", DIM))
	var worn_rolls: Dictionary = worn.get("jets", {})
	var ranges := {}
	if entry.has("jets"):
		for stat: String in entry["jets"]:
			ranges[stat] = [int(entry["jets"][stat]), int(entry["jets"][stat])]
	else:
		for stat: String in entry.get("bonus", {}):
			ranges[stat] = [int(entry["bonus"][stat][0]), int(entry["bonus"][stat][1])]
	var changed := false
	for stat: String in Item.bonus_stats():
		var base := int(worn_rolls.get(stat, 0))
		var span: Array = ranges.get(stat, [0, 0])
		var low := int(span[0]) - base
		var high := int(span[1]) - base
		if low == 0 and high == 0:
			continue
		changed = true
		var text := "%s %s" % [_signed(low), Item.stat_name(stat)] if low == high \
			else "%s à %s %s" % [_signed(low), _signed(high), Item.stat_name(stat)]
		lines.append(_colored(text, GAIN if low >= 0 else LOSS if high <= 0 else MIXED))
	var damage := average_damage(template) - average_damage(worn_template)
	if template.has("attaque") and absf(damage) >= 0.05:
		changed = true
		lines.append(_colored("%s dégâts moyens" % (("+" if damage > 0 else "") + String.num(damage, 1).replace(".", ",")),
			GAIN if damage > 0 else LOSS))
	if not changed:
		lines.append(_colored("Mêmes bonus", DIM))
	return lines


## Objet porté que l'équiper remplacerait : {} si un de ses emplacements est libre.
static func compared_entry(template: Dictionary, inventory: Inventory) -> Dictionary:
	var slots: Array = Item.SLOTS_BY_TYPE.get(template.get("type", ""), [])
	if slots.is_empty():
		return {}
	for slot: String in slots:
		if not inventory.equipped.has(slot):
			return {}
	return inventory.equipped_entry(slots[0])


## Dégâts moyens de l'attaque d'une arme (0 pour les autres objets).
static func average_damage(template: Dictionary) -> float:
	if not template.has("attaque"):
		return 0.0
	var total := 0.0
	for effect in Spell.from_dict(Item.weapon_spell_data(template)).effects:
		if effect["type"] == Spell.EFFECT_DAMAGE:
			total += (int(effect["min"]) + int(effect["max"])) / 2.0
	return total


static func _signed(value: int) -> String:
	return "+%d" % value if value >= 0 else str(value)


static func _colored(text: String, color: Color) -> String:
	return "[color=#%s]%s[/color]" % [color.to_html(false), text]


static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")
