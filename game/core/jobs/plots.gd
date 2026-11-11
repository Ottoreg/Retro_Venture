class_name Plots
extends RefCounted
## Instances de métier (GDD § 10.3) : chaque métier de récolte a sa carte personnelle (`MAPS`), ouverte à
## `OPEN_REPUTATION` de réputation, où le joueur pose sur des emplacements les ressources qu'il a débloquées par des
## points de maîtrise. Une ressource récoltée repousse seule ; le temps passé dehors compte (horloge réelle), une
## ressource mûre attend sans se cumuler. L'état est gardé dans le métier du personnage (`instance`).

const OPEN_REPUTATION := 2500
const MAPS := {"agriculteur": "instance_champ", "herboriste": "instance_jardin", "pecheur": "instance_etang",
	"bucheron": "instance_bosquet", "mineur": "instance_mine"}
## Selon la réputation : [seuil, emplacements, % de quantité, % de pousse en moins, % de temps de récolte en moins,
## points de % de rare en plus].
const LEVELS := [[2500, 10, 0, 0, 0, 0.0], [15000, 15, 10, 0, 0, 0.0], [40000, 25, 25, 15, 10, 0.0], [100000, 40, 50, 30, 20, 0.5]]
## Pousse : 10 min au niveau 1 de la ressource, + 5 min par niveau.
const GROW_BASE := 600.0
const GROW_PER_LEVEL := 300.0


## Ligne de `LEVELS` de cette réputation ([] avant l'ouverture).
static func level(reputation: int) -> Array:
	var found: Array = []
	for line: Array in LEVELS:
		if reputation >= line[0]:
			found = line
	return found


## Points de maîtrise pour débloquer une ressource de ce niveau : 1 jusqu'au 8, 2 jusqu'au 22, 3 au-delà.
static func unlock_cost(node_level: int) -> int:
	return 1 if node_level <= 8 else 2 if node_level <= 22 else 3


## Durée de pousse en secondes, moins `bonus_percent` % (bonus d'instance et Main verte de l'outil, 90 % au plus).
static func grow_time(node_level: int, bonus_percent := 0.0) -> float:
	return (GROW_BASE + GROW_PER_LEVEL * (node_level - 1)) * (1.0 - minf(bonus_percent, 90.0) / 100.0)


## État de l'instance d'un métier : { debloquees: [marqueurs], parcelles: { "x,y": [marqueur, mûre à (horloge réelle)] } }.
static func state_of(job_entry: Dictionary) -> Dictionary:
	if typeof(job_entry.get("instance")) != TYPE_DICTIONARY:
		job_entry["instance"] = {"debloquees": [], "parcelles": {}}
	return job_entry["instance"]


static func key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


static func cell_of(cell_key: String) -> Vector2i:
	return Vector2i(int(cell_key.get_slice(",", 0)), int(cell_key.get_slice(",", 1)))


## Ressources posées : case → marqueur.
static func markers(state: Dictionary) -> Dictionary:
	var placed := {}
	for cell_key: String in state.get("parcelles", {}):
		placed[cell_of(cell_key)] = state["parcelles"][cell_key][0]
	return placed
