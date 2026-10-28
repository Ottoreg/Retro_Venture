class_name PartyUi
extends CanvasLayer
## Groupes de joueurs (multijoueur, GDD § 16.5, M2) : un clic sur un autre joueur propose de
## l'inviter (ou de le suivre, s'il est du groupe), une invitation reçue demande d'accepter ou de refuser. Les membres s'affichent dans la
## bande droite (`CombatHud`).
##
## Chat (M3) : le même menu s'ouvre au clic sur le nom d'un auteur dans l'historique, avec en plus
## « Message privé » (le joueur n'est alors connu que par son pseudo). Il propose aussi d'ajouter le
## joueur en ami, de l'ignorer et de le signaler (fenêtre du motif et d'un commentaire).
##
## Échange (M4) : « Échanger » propose un échange à un joueur de la même carte ; une proposition
## reçue demande d'accepter ou de refuser (la fenêtre d'échange, `ExchangeWindow`, s'ouvre ensuite).

## Le joueur veut écrire en privé à ce pseudo (la ligne de saisie de l'historique s'ouvre).
signal whisper_requested(player_name: String)

var map_view: MapView
var _menu: PopupMenu
var _invitation: ConfirmationDialog
var _report: ConfirmationDialog
var _report_reason: OptionButton
var _report_comment: LineEdit
var _exchange_request: ConfirmationDialog
## Joueur qui propose un échange (id).
var _exchange_asker := ""
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
	_exchange_request = ConfirmationDialog.new()
	_exchange_request.title = "Échange"
	_exchange_request.ok_button_text = "Accepter"
	_exchange_request.cancel_button_text = "Refuser"
	_exchange_request.confirmed.connect(_answer_exchange.bind(true))
	_exchange_request.canceled.connect(_answer_exchange.bind(false))
	add_child(_exchange_request)
	_build_report()


func setup(p_map_view: MapView) -> void:
	map_view = p_map_view
	map_view.player_clicked.connect(_on_player_clicked)
	map_view.party_invited.connect(_on_invited)
	map_view.exchange_requested.connect(_on_exchange_requested)
	map_view.exchange_closed.connect(func(event: Dictionary) -> void:
		if _exchange_request.visible and event["raison"] != Exchange.CLOSED_DONE:
			_exchange_request.hide()  # Proposition retirée (ou son auteur est parti).
			_exchange_asker = "")


func _on_player_clicked(player_id: String, player_name: String) -> void:
	_clicked = player_id
	_clicked_name = player_name
	_menu.clear()
	if map_view.world.is_party_member(player_id):
		_menu.add_item(("Ne plus suivre %s" if map_view.follow_id == player_id else "Suivre %s") % player_name, 2)
	elif not player_id.is_empty():
		_menu.add_item("Inviter %s dans le groupe" % player_name, 0)
	_menu.add_item("Message privé à %s" % player_name, 1)
	var world := map_view.world
	_menu.add_item("Retirer %s des amis" % player_name if world.has_relation("amis", player_name)
		else "Ajouter %s en ami" % player_name, 3)
	_menu.add_item("Ne plus ignorer %s" % player_name if world.has_relation("ignores", player_name)
		else "Ignorer %s" % player_name, 4)
	_menu.add_item("Signaler %s…" % player_name, 5)
	# Échange (jalon M4) : seulement sur la même carte.
	var here: Array = world.other_players().filter(func(other: Dictionary) -> bool: return other["nom"] == player_name)
	if not here.is_empty():
		_clicked = str(here[0]["id"])
		_menu.add_item("Échanger avec %s" % player_name, 6)
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
	elif id == 3:
		var friend := map_view.world.has_relation("amis", _clicked_name)
		_relation(Relations.REMOVE if friend else Relations.ADD)
	elif id == 4:
		var ignored := map_view.world.has_relation("ignores", _clicked_name)
		_relation(Relations.UNIGNORE if ignored else Relations.IGNORE)
	elif id == 5:
		open_report(_clicked_name)
	elif id == 6:
		map_view.send_command({"type": Protocol.CMD_EXCHANGE, "entite": map_view.world.player_id,
			"action": Exchange.PROPOSE, "joueur": _clicked})
		map_view.notice.emit("Proposition d'échange envoyée à %s." % _clicked_name)


func _relation(action: String) -> void:
	map_view.send_command({"type": Protocol.CMD_RELATIONS, "entite": map_view.world.player_id, "action": action,
		"nom": _clicked_name})


## Fenêtre du signalement de ce joueur : motif et commentaire facultatif.
func open_report(player_name: String) -> void:
	_clicked_name = player_name
	_report.title = "Signaler %s" % player_name
	_report_reason.select(0)
	_report_comment.clear()
	_report.popup_centered()


## Vrai tant que la fenêtre de signalement est ouverte (tests).
func is_reporting() -> bool:
	return _report.visible


func _send_report() -> void:
	var reasons := Relations.REPORT_REASONS.keys()
	map_view.send_command({"type": Protocol.CMD_REPORT, "entite": map_view.world.player_id, "nom": _clicked_name,
		"motif": reasons[maxi(0, _report_reason.selected)], "commentaire": _report_comment.text})


func _build_report() -> void:
	_report = ConfirmationDialog.new()
	_report.ok_button_text = "Signaler"
	_report.cancel_button_text = "Annuler"
	_report.confirmed.connect(_send_report)
	add_child(_report)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_report.add_child(column)
	var hint := Label.new()
	hint.text = "Ses derniers messages sont joints au signalement."
	column.add_child(hint)
	_report_reason = OptionButton.new()
	for reason: String in Relations.REPORT_REASONS:
		_report_reason.add_item(Relations.REPORT_REASONS[reason])
	column.add_child(_report_reason)
	_report_comment = LineEdit.new()
	_report_comment.placeholder_text = "Commentaire (facultatif)"
	_report_comment.max_length = Relations.COMMENT_LENGTH
	column.add_child(_report_comment)


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


func _on_exchange_requested(event: Dictionary) -> void:
	_exchange_asker = event["de"]
	_exchange_request.dialog_text = "%s vous propose un échange." % event["nom"]
	_exchange_request.popup_centered()


## Vrai tant qu'une proposition d'échange attend sa réponse (tests).
func is_asking_exchange() -> bool:
	return _exchange_request.visible


func _answer_exchange(accepted: bool) -> void:
	if _exchange_asker.is_empty():
		return
	map_view.send_command({"type": Protocol.CMD_EXCHANGE, "entite": map_view.world.player_id,
		"action": Exchange.ACCEPT if accepted else Exchange.DECLINE, "joueur": _exchange_asker})
	_exchange_asker = ""
