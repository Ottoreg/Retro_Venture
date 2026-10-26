class_name PartyUi
extends CanvasLayer
## Groupes de joueurs (multijoueur, GDD § 16.5, M2) : un clic sur un autre joueur propose de
## l'inviter, une invitation reçue demande d'accepter ou de refuser. Les membres s'affichent dans la
## bande droite (`CombatHud`).

var map_view: MapView
var _menu: PopupMenu
var _invitation: ConfirmationDialog
## Joueur cliqué (id) et chef qui invite (id).
var _clicked := ""
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
	_menu.clear()
	if map_view.world.is_party_member(player_id):
		_menu.add_item("%s est dans votre groupe" % player_name, 1)
		_menu.set_item_disabled(0, true)
	else:
		_menu.add_item("Inviter %s dans le groupe" % player_name, 0)
	_menu.position = Vector2i(get_viewport().get_mouse_position())
	_menu.popup()


func _on_menu_pressed(id: int) -> void:
	if id == 0:
		map_view.send_command({"type": Protocol.CMD_PARTY_INVITE, "entite": map_view.world.player_id, "joueur": _clicked})
		map_view.notice.emit("Invitation envoyée.")


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
