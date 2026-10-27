class_name PartyUi
extends CanvasLayer
## Groupes de joueurs (multijoueur, GDD § 16.5, M2) : un clic sur un autre joueur propose de
## l'inviter (ou de le suivre, s'il est du groupe), une invitation reçue demande d'accepter ou de refuser. Les membres s'affichent dans la
## bande droite (`CombatHud`).
##
## Chat (M3) : le même menu s'ouvre au clic sur le nom d'un auteur dans l'historique, avec en plus
## « Message privé » (le joueur n'est alors connu que par son pseudo).

## Le joueur veut écrire en privé à ce pseudo (la ligne de saisie de l'historique s'ouvre).
signal whisper_requested(player_name: String)

var map_view: MapView
var _menu: PopupMenu
var _invitation: ConfirmationDialog
## Joueur cliqué (id) et chef qui invite (id).
var _clicked := ""
var _clicked_name := ""
var _inviter := ""


func _ready() -> void:
	_menu = PopupMenu.new()
	_menu.id_pressed.connect(_on_menu_pressed)
	add_child(_menu)
	_invitation = ConfirmationDialog.new()
	_invitation.title = "Invitation"
	_invitation.ok_button_text = "Accepter"
	_invitation.cancel_button_text = "Refuser"
	_invitation.confirmed.connect(_answer.bind(true))
	_invitation.canceled.connect(_answer.bind(false))
	add_child(_invitation)


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.player_clicked.connect(_on_player_clicked)
	map_view.party_invited.connect(_on_invited)


func _on_player_clicked(player_id: String, player_name: String) -> void:
	_clicked = player_id
	_clicked_name = player_name
	_menu.clear()
	if map_view.world.is_party_member(player_id):
		_menu.add_item(("Ne plus suivre %s" if map_view.follow_id == player_id else "Suivre %s") % player_name, 2)
	elif not player_id.is_empty():
		_menu.add_item("Inviter %s dans le groupe" % player_name, 0)
	_menu.add_item("Message privé à %s" % player_name, 1)
	_menu.position = Vector2i(get_viewport().get_mouse_position())
	_menu.popup()


## Nom d'auteur cliqué dans l'historique du chat : son menu, sans son id (le serveur le trouve par
## son pseudo).
func on_author_clicked(player_name: String) -> void:
	if player_name == map_view.world.player_name:
		return
	var player: Dictionary = map_view.world.player_named(player_name)
	_on_player_clicked(str(player.get("id", "")), player_name)


func _on_menu_pressed(id: int) -> void:
	if id == 0:
		map_view.send_command({"type": Protocol.CMD_PARTY_INVITE, "entite": map_view.world.player_id, "joueur": _clicked})
		map_view.notice.emit("Invitation envoyée.")
	elif id == 1:
		whisper_requested.emit(_clicked_name)
	elif id == 2:
		map_view.toggle_follow(_clicked)


func _on_invited(event: Dictionary) -> void:
	_inviter = event["chef"]
	_invitation.dialog_text = "%s vous invite dans son groupe." % event["nom"]
	_invitation.popup_centered()


## Vrai tant qu'une invitation attend sa réponse (tests).
func is_asking() -> bool:
	return _invitation.visible


func _answer(accepted: bool) -> void:
	if _inviter.is_empty():
		return
	map_view.send_command({"type": Protocol.CMD_PARTY_ANSWER, "entite": map_view.world.player_id, "chef": _inviter, "accepte": accepted})
	_inviter = ""
