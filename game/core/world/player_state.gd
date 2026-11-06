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
## Récolte en cours : { case, fin (heure du monde) }, vide sinon ; finie par `World.update`.
var harvesting: Dictionary = {}
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
## Combat regardé en spectateur, ou `null`.
var watching: Combat = null
## Dernier combat du joueur, gardé après sa fin : ses spectateurs reçoivent encore les derniers
## événements.
var last_combat: Combat = null
## Repère posé sur la carte du monde, montré aux membres de son groupe ({} sans).
var pin: Dictionary = {}
## PNJ qui ont déjà fait leur cadeau pendant cette visite de la carte (champ `don`).
var gifts: Array[String] = []
## Invitations reçues dans un groupe : id de qui a invité → true.
var invitations: Dictionary = {}
## Amis et joueurs ignorés (jalon M3), par pseudo, gardés dans sa sauvegarde (`World.player_save`).
var friends: Array[String] = []
var ignored: Array[String] = []
## Race et Voie de chaque ami, la dernière fois qu'on l'a vu connecté (pseudo en minuscules →
## { race, voie }) : son portrait dans la liste, même hors ligne.
var friend_looks: Dictionary = {}
## Signalements faits : pseudo signalé (en minuscules) → heure du monde (un par heure et par joueur).
var reports: Dictionary = {}
## Échange en cours avec un autre joueur (jalon M4), ou `null`.
var exchange: Exchange = null
## Joueur à qui il a proposé un échange, sans réponse encore (id), ou "".
var exchange_asked := ""
## Mode héros (GDD § 4.6) : ids des héros que contrôle le même joueur, lui compris (tableau partagé
## par toute l'équipe), vide hors de ce mode.
var heroes: Array[String] = []
## Héros non contrôlé : absent de la liste des joueurs de la carte (invisible), toujours sur la case
## du héros contrôlé, avec qui il combat.
var hidden := false
## Héros de l'équipe qui reçoit tout le butin et les brumes des combats (id), ou "" : partage.
var hero_receiver := ""
## Quêtes : propositions, avancement, récompenses (l'état est dans `character.quests`).
var quest_book: QuestBook


func _init(p_id: String, p_character: Character) -> void:
	id = p_id
	character = p_character


func in_combat() -> bool:
	return combat != null
