class_name Figures
extends RefCounted
## Silhouettes provisoires dessinées par le code (en attendant les vrais graphismes), utilisables
## sur n'importe quel CanvasItem : carte, écran de création…
## `base` : point au sol ; `body` : base décalée pendant les petits sauts de la marche ;
## `facing` : 1 tourné vers la droite, -1 vers la gauche ; `swing` : balancement des jambes.

const SHADOW := Color(0, 0, 0, 0.25)
const LEGS := Color("3b2a1c")

## Couleur de cape et couvre-chef par Voie.
const VOIE_LOOKS := {
	"guerrier": {"cape": Color("8a3b2f"), "coiffe": Color("8d9097"), "forme": "casque"},
	"rodeur": {"cape": Color("3f6b34"), "coiffe": Color("2f5428"), "forme": "capuche"},
	"arcaniste": {"cape": Color("34407a"), "coiffe": Color("27305e"), "forme": "pointu"},
	"theologue": {"cape": Color("e8dfc4"), "coiffe": Color("c9a04e"), "forme": "capuche"},
}
const DEFAULT_LOOK := {"cape": Color("2f5d8a"), "coiffe": Color("8a3b2f"), "forme": "pointu"}
const RACE_SKINS := {"humain": Color("f0c8a0"), "elfe": Color("f3dcc4"), "gobelin": Color("6f9a3e")}


static func ellipse(center: Vector2, radius_x: float, radius_y: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points


## Point d'un dessin tourné vers la droite (`facing` = 1) ou la gauche (-1).
static func at(origin: Vector2, x: float, y: float, facing: float) -> Vector2:
	return origin + Vector2(x * facing, y)


## Personnage joueur, d'après sa race et sa Voie.
static func player(ci: CanvasItem, base: Vector2, body: Vector2, facing: float, swing: float, race: String, voie: String) -> void:
	var look: Dictionary = VOIE_LOOKS.get(voie, DEFAULT_LOOK)
	if race == "gobelin":
		goblin(ci, base, body, facing, swing, look["cape"])
		return
	var skin: Color = RACE_SKINS.get(race, RACE_SKINS["humain"])
	humanoid(ci, base, body, facing, swing, look["cape"], skin, look["coiffe"], look["forme"], race == "elfe")


## Humanoïde : jambes, cape, tête, couvre-chef (« pointu », « chapeau », « casque », « capuche »).
static func humanoid(ci: CanvasItem, base: Vector2, body: Vector2, facing: float, swing: float, cloak: Color,
		skin: Color, hat: Color, hat_kind: String, pointed_ears := false) -> void:
	ci.draw_colored_polygon(ellipse(base, 14, 7), SHADOW)
	ci.draw_line(base + Vector2(-4, -8), base + Vector2(-4 + swing, 0), LEGS, 4.0)
	ci.draw_line(base + Vector2(4, -8), base + Vector2(4 - swing, 0), LEGS, 4.0)
	ci.draw_colored_polygon(PackedVector2Array([
		body + Vector2(-11, -6), body + Vector2(11, -6), body + Vector2(7, -30), body + Vector2(-7, -30),
	]), cloak)
	if pointed_ears:
		for side in [-1.0, 1.0]:
			ci.draw_colored_polygon(PackedVector2Array([
				body + Vector2(6 * side, -40), body + Vector2(15 * side, -46), body + Vector2(7 * side, -35),
			]), skin)
	ci.draw_circle(body + Vector2(0, -38), 8, skin)
	ci.draw_circle(at(body, 4, -39, facing), 1.3, Color(0.15, 0.1, 0.1))
	match hat_kind:
		"chapeau":
			ci.draw_colored_polygon(ellipse(body + Vector2(0, -43), 13, 4), hat)
			ci.draw_colored_polygon(PackedVector2Array([body + Vector2(-6, -43), body + Vector2(6, -43), body + Vector2(4, -52), body + Vector2(-4, -52)]), hat)
		"casque":
			ci.draw_colored_polygon(PackedVector2Array([
				body + Vector2(-9, -40), body + Vector2(-8, -47), body + Vector2(0, -50), body + Vector2(8, -47), body + Vector2(9, -40),
			]), hat)
			ci.draw_line(at(body, 2, -40, facing), at(body, 2, -34, facing), hat.darkened(0.3), 2.0)
		"capuche":
			ci.draw_colored_polygon(PackedVector2Array([
				body + Vector2(-10, -32), body + Vector2(-9, -44), at(body, -4, -50, facing), body + Vector2(9, -44), body + Vector2(10, -32),
				body + Vector2(7, -36), body + Vector2(-7, -36),
			]), hat)
		_:
			ci.draw_colored_polygon(PackedVector2Array([
				body + Vector2(-9, -40), body + Vector2(9, -40), at(body, -2, -57, facing),
			]), hat)


static func wolf(ci: CanvasItem, base: Vector2, body: Vector2, facing: float, swing: float) -> void:
	var fur := Color("7d7f86")
	var dark := Color("6b6d73")
	ci.draw_colored_polygon(ellipse(base, 18, 7), SHADOW)
	for leg_x in [-9.0, 9.0]:
		var direction := 1.0 if leg_x < 0.0 else -1.0
		ci.draw_line(at(body, leg_x, -10, facing), at(base, leg_x + swing * direction, 0, facing), dark, 3.0)
	ci.draw_colored_polygon(ellipse(body + Vector2(0, -14), 16, 9), fur)
	ci.draw_circle(at(body, 13, -22, facing), 7, Color("8e9097"))
	ci.draw_colored_polygon(PackedVector2Array([at(body, 10, -27, facing), at(body, 13, -36, facing), at(body, 16, -27, facing)]), dark)
	ci.draw_colored_polygon(PackedVector2Array([at(body, 17, -21, facing), at(body, 25, -19, facing), at(body, 17, -17, facing)]), dark)
	ci.draw_colored_polygon(PackedVector2Array([at(body, -15, -16, facing), at(body, -26, -24 + swing, facing), at(body, -14, -11, facing)]), dark)
	ci.draw_circle(at(body, 15, -23, facing), 1.5, Color(0.9, 0.8, 0.2))


static func goblin(ci: CanvasItem, base: Vector2, body: Vector2, facing: float, swing: float, tunic := Color("5a4630")) -> void:
	var skin := Color("6f9a3e")
	ci.draw_colored_polygon(ellipse(base, 12, 6), SHADOW)
	ci.draw_line(base + Vector2(-3, -6), base + Vector2(-3 + swing, 0), LEGS, 3.0)
	ci.draw_line(base + Vector2(3, -6), base + Vector2(3 - swing, 0), LEGS, 3.0)
	ci.draw_colored_polygon(PackedVector2Array([
		body + Vector2(-9, -5), body + Vector2(9, -5), body + Vector2(6, -22), body + Vector2(-6, -22),
	]), tunic)
	ci.draw_circle(body + Vector2(0, -29), 8, skin)
	ci.draw_colored_polygon(PackedVector2Array([body + Vector2(-6, -31), body + Vector2(-17, -36), body + Vector2(-7, -26)]), skin)
	ci.draw_colored_polygon(PackedVector2Array([body + Vector2(6, -31), body + Vector2(17, -36), body + Vector2(7, -26)]), skin)
	ci.draw_colored_polygon(PackedVector2Array([at(body, 5, -30, facing), at(body, 12, -27, facing), at(body, 5, -26, facing)]), Color("5d8433"))
	ci.draw_circle(at(body, -1, -31, facing), 1.5, Color(1, 0.3, 0.2))
	ci.draw_circle(at(body, 4, -31, facing), 1.5, Color(1, 0.3, 0.2))


static func blob(ci: CanvasItem, base: Vector2, body: Vector2) -> void:
	ci.draw_colored_polygon(ellipse(base, 14, 7), SHADOW)
	ci.draw_colored_polygon(ellipse(body + Vector2(0, -12), 13, 12), Color("9a5fb0"))
