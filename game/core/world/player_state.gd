class_name PlayerState
extends RefCounted
## Un personnage connecté : son `Character`, sa carte (une `MapInstance`) et sa case, ses quêtes,
## son combat en cours. Le `World` en tient un par joueur ; en solo, un seul (`World.PLAYER_ID`).

## Identifiant du personnage : celui de ses commandes (`entite`), de ses événements et de son
## combattant.
var id: String
var character: Character
## Carte où se trouve le personnage.
var instance: MapInstance
var map: GameMap:
	get:
		return instance.map if instance != null else null
## Case du personnage sur sa carte.
var cell: Vector2i:
	get:
		return instance.position_of(id)
	set(value):
		instance.positions[id] = value
## Cases du dernier trajet (départ compris), pour pouvoir l'interrompre en chemin.
var last_walk: Array[Vector2i] = []
## Assis : régénération plus rapide ; pas sauvegardé, on recharge debout.
var sitting := false
## Temps accumulé pour la régénération des PV hors combat.
var regen_time := 0.0
## Combat en cours, ou `null` en exploration.
var combat: Combat = null
## Groupe de monstres combattu.
var combat_group := ""
## Bonus de butin du combat en cours (élite ancienne), en fraction : 0.3 = +30 %.
var combat_loot_bonus := 0.0
## Déconnecté en plein combat avec d'autres joueurs (en ligne) : il reste dans le monde jusqu'à la fin
## du combat (ses tours passent), et le retrouve s'il revient avant.
var away := false
## Joueurs de son combat (ids, lui compris), gardés jusqu'au suivant : à qui envoyer ses événements.
var fight_mates: Array[String] = []
## Chef de son groupe de joueurs (id, le sien s'il est le chef), ou "" sans groupe.
var party_leader := ""
## Invitations reçues dans un groupe : id de qui a invité → true.
var invitations: Dictionary = {}
## Quêtes : propositions, avancement, récompenses (l'état est dans `character.quests`).
var quest_book: QuestBook


func _init(p_id: String, p_character: Character) -> void:
	id = p_id
	character = p_character


func in_combat() -> bool:
	return combat != null
