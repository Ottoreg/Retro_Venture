class_name Rig
extends RefCounted
## Personnages articulés, à la manière des animations de Dofus Rétro : des pièces (jambes, torse,
## bras, tête, arme, accessoires) assemblées et animées par le code. Les assemblages sont décrits
## dans `art.json` (« personnages ») : une liste de pièces par vue (« face » : de 3/4, tourné vers
## le bas de l'écran ; « dos » : tourné vers le haut), dans l'ordre de dessin.

const WALK_SWING := 0.5
const ARM_SWING := 0.42


## Apparence d'un personnage : { rig, couleurs, arme, accessoires } (voir `art.json`).
static func look(rig_name: String, colors: Dictionary = {}, weapon := "", accessories: Array = []) -> Dictionary:
	return {"rig": rig_name, "couleurs": colors, "arme": weapon, "accessoires": accessories}


## Apparence du personnage d'un joueur : assemblage de sa race, tenue de sa Voie, peau de sa race.
static func player_look(race_id: String, voie_id: String, data: GameData) -> Dictionary:
	var manifest := Art.manifest()
	var race_spec: Dictionary = manifest.get("races", {}).get(race_id, {"rig": "humain"})
	var outfit: Dictionary = manifest.get("tenues", {}).get(voie_id, {})
	var colors: Dictionary = outfit.get("couleurs", {}).duplicate()
	colors.merge(race_spec.get("couleurs", {}), true)
	if data != null:
		var skin: Variant = data.races.get(race_id, {}).get("apparence", {}).get("peau")
		if typeof(skin) == TYPE_STRING:
			colors["peau"] = skin
	return look(race_spec.get("rig", "humain"), colors, outfit.get("arme", ""), race_spec.get("accessoires", []))


## Vrai si l'assemblage existe.
static func exists(rig_name: String) -> bool:
	return Art.manifest().get("personnages", {}).has(rig_name)


## Pièces d'une vue, avec l'héritage (« base ») et les remplacements d'images résolus.
static func parts(rig_name: String, back: bool) -> Array:
	var rigs: Dictionary = Art.manifest().get("personnages", {})
	var spec: Dictionary = rigs.get(rig_name, {})
	var replaced: Dictionary = spec.get("remplacer", {})
	var source := spec
	while source.has("base"):
		source = rigs.get(source["base"], {})
	var result: Array = []
	for part: Dictionary in source.get("dos" if back else "face", []):
		var copy := part.duplicate()
		copy["image"] = replaced.get(part["image"], part["image"])
		result.append(copy)
	return result


static func scale_of(rig_name: String) -> float:
	return float(Art.manifest().get("personnages", {}).get(rig_name, {}).get("echelle", 1.0))


## Dessine le personnage, pieds en `base`. `pose` : { facing (1 ou -1), dos (bool), marche (bool),
## phase (marche), temps (respiration), attaque (0 à 1, ou négatif), zoom (agrandissement) }.
static func draw(canvas: CanvasItem, appearance: Dictionary, base: Vector2, pose: Dictionary, modulate := Color.WHITE) -> void:
	var rig_name: String = appearance["rig"]
	var colors: Dictionary = appearance.get("couleurs", {})
	var back: bool = pose.get("dos", false)
	var walking: bool = pose.get("marche", false)
	var phase: float = pose.get("phase", 0.0)
	var time: float = pose.get("temps", 0.0)
	var attack: float = pose.get("attaque", -1.0)
	var size := scale_of(rig_name) * float(pose.get("zoom", 1.0))
	Art.draw(canvas, "ombre", base, {}, false, Color(1, 1, 1, modulate.a), size)
	var root := Transform2D(0.0, Vector2(float(pose.get("facing", 1.0)) * size, size), 0.0, base)
	var bob := -absf(sin(phase)) * 1.6 if walking else sin(time * 2.2) * 0.45
	var swing := sin(phase) if walking else 0.0
	var breathe := sin(time * 2.2) * 0.04
	var placed := {}
	var manifest := Art.manifest()
	var view := "dos" if back else "face"
	for part: Dictionary in parts(rig_name, back):
		var role: String = part["role"]
		var angle := 0.0
		if role == "jambe_avant":
			angle = swing * WALK_SWING
		elif role == "jambe_arriere":
			angle = -swing * WALK_SWING
		elif role == "bras_libre":
			angle = swing * ARM_SWING + breathe
		elif role == "bras_arme":
			angle = -swing * ARM_SWING - breathe
			if attack >= 0.0:
				angle = _attack_angle(attack)
		elif role == "torse" and attack >= 0.0:
			angle = 0.08 * sin(attack * PI)
		var position := Vector2(part["position"][0], part["position"][1])
		if not role.begins_with("jambe"):
			position.y += bob
		var joint := root * Transform2D(angle, position)
		placed[role] = joint
		var tint := float(part.get("teinte", 1.0))
		_draw_accessories(canvas, appearance, part, role, view, joint, true, modulate)
		_draw_piece(canvas, part["image"], colors, joint, Color(tint, tint, tint) * modulate)
		# Arme dans la main, accessoires (chapeau, tablier…) posés sur leur pièce.
		if role == "bras_arme" and not str(appearance.get("arme", "")).is_empty():
			var weapon: Dictionary = manifest.get("armes", {}).get(appearance["arme"], {})
			var hand: Array = weapon.get("attache", [6, 28])
			var held := joint * Transform2D(float(weapon.get("angle", 0.0)), Vector2(hand[0], hand[1]) - Art.anchor(part["image"]))
			_draw_piece(canvas, appearance["arme"], colors, held, modulate)
		_draw_accessories(canvas, appearance, part, role, view, joint, false, modulate)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)


## Accessoires posés sur la pièce `role` : ceux de derrière (une cape) avant la pièce, les autres après.
static func _draw_accessories(canvas: CanvasItem, appearance: Dictionary, part: Dictionary, role: String, view: String,
		joint: Transform2D, behind: bool, modulate: Color) -> void:
	for accessory: String in appearance.get("accessoires", []):
		var spec: Dictionary = Art.manifest().get("accessoires", {}).get(accessory, {})
		if spec.get("parent", "") != role or view not in spec.get("vues", ["face"]) or bool(spec.get("derriere", false)) != behind:
			continue
		var spot: Array = spec.get("attache_dos", spec.get("attache", [0, 0])) if view == "dos" else spec.get("attache", [0, 0])
		var worn := joint * Transform2D(0.0, Vector2(spot[0], spot[1]) - Art.anchor(part["image"]))
		_draw_piece(canvas, spec.get("image", accessory), appearance.get("couleurs", {}), worn, modulate)


## Bras armé pendant une attaque : on lève l'arme (0 → 0,35), puis on frappe vers l'avant.
static func _attack_angle(progress: float) -> float:
	if progress < 0.35:
		return lerpf(0.0, -2.3, progress / 0.35)
	return lerpf(-2.3, 0.9, minf(1.0, (progress - 0.35) / 0.45))


## Pièce dessinée avec son ancre (pivot) sur `joint`.
static func _draw_piece(canvas: CanvasItem, image_name: String, colors: Dictionary, joint: Transform2D, modulate: Color) -> void:
	var tex := Art.texture(image_name, colors)
	if tex == null:
		return
	var pivot := Art.anchor(image_name)
	var local := Transform2D(0.0, Vector2.ONE / Art.SCALE, 0.0, -pivot)
	canvas.draw_set_transform_matrix(joint * local)
	canvas.draw_texture(tex, Vector2.ZERO, modulate)
