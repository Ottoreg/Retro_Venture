class_name Relations
extends RefCounted
## Amis, joueurs ignorés et signalements (GDD § 16.5, jalon M3), sans réseau : constantes et règles
## qui ne dépendent pas du monde. `World` applique les commandes et dit qui reçoit quoi.
##
## Les listes sont par pseudo (uniques sur le serveur), gardées dans la sauvegarde du joueur. Une
## liste d'amis est à sens unique, comme Dofus, mais on ne voit le statut (en ligne, carte, combat)
## que d'un ami qui nous compte aussi parmi les siens. Un joueur ignoré n'atteint plus rien : ni ses
## messages, ni ses invitations, et il ne le sait pas (le serveur les retient).

const ADD := "ajouter"
const REMOVE := "retirer"
const IGNORE := "ignorer"
const UNIGNORE := "ne_plus_ignorer"
const ACTIONS := ["", ADD, REMOVE, IGNORE, UNIGNORE]
## Taille de chaque liste.
const MAX_ENTRIES := 100

## Motifs d'un signalement : texte montré au joueur.
const REPORT_REASONS := {
	"insultes": "Insultes ou harcèlement",
	"triche": "Triche ou exploitation de bug",
	"spam": "Spam ou publicité",
	"pseudo": "Pseudo inapproprié",
	"autre": "Autre",
}
## Messages du joueur signalé joints au signalement (pris dans le journal du chat).
const REPORT_MESSAGES := 20
## Un même joueur ne se signale qu'une fois par heure (de jeu sur le serveur).
const REPORT_DELAY := 3600.0
## Longueur du commentaire d'un signalement.
const COMMENT_LENGTH := 200


## Position d'un pseudo dans une liste, sans tenir compte des majuscules (-1 s'il n'y est pas).
static func find(names: Array[String], player_name: String) -> int:
	var wanted := player_name.strip_edges().to_lower()
	for i in names.size():
		if names[i].to_lower() == wanted:
			return i
	return -1


## Vrai si la liste contient ce pseudo (sans tenir compte des majuscules).
static func has(names: Array[String], player_name: String) -> bool:
	return find(names, player_name) >= 0


## Liste lue d'une sauvegarde : des pseudos valides, sans doublon, au plus MAX_ENTRIES.
static func read_list(value: Variant) -> Array[String]:
	var names: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return names
	for entry: Variant in value:
		if typeof(entry) == TYPE_STRING and Character.name_error(entry).is_empty() and not has(names, entry) \
				and names.size() < MAX_ENTRIES:
			names.append(entry)
	return names
