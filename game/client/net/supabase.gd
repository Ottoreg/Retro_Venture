class_name Supabase
extends RefCounted
## Accès à Supabase (GDD § 16.5) par son API HTTP : comptes (Auth), tables (PostgREST). Sert au
## client (clé publique : inscription, connexion, adresse du serveur) et au serveur (clé secrète :
## vérification des jetons, personnages, serveur actuel). Toutes les requêtes attendent (`await`).

## Vue des serveurs vivants (marqueur rafraîchi depuis moins de 90 s, voir server/supabase/schema.sql).
const LIVE_SERVER_VIEW := "serveur_en_ligne"
const REQUEST_TIMEOUT := 15.0

var url: String
var key: String
## Nœud où accrocher les requêtes HTTP (`HTTPRequest` doit être dans l'arbre).
var _host: Node


func _init(p_url: String, p_key: String, host: Node) -> void:
	url = p_url.strip_edges().trim_suffix("/").trim_suffix("/rest/v1")  # L'adresse du projet, sans le chemin de l'API.
	key = p_key
	_host = host


## Requête HTTP ; renvoie { code: int (0 si pas de réponse), data: Variant (JSON relu, ou null) }.
## `bearer` : jeton d'un joueur (sinon la clé, si c'est un ancien jeton JWT).
func request(method: HTTPClient.Method, path: String, body: Variant = null, extra_headers: Array[String] = [],
		bearer := "") -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = REQUEST_TIMEOUT
	_host.add_child(http)
	var headers: Array[String] = ["apikey: %s" % key, "Content-Type: application/json"]
	if not bearer.is_empty():
		headers.append("Authorization: Bearer %s" % bearer)
	elif not key.begins_with("sb_"):
		headers.append("Authorization: Bearer %s" % key)  # Anciennes clés (anon, service_role).
	headers.append_array(extra_headers)
	var error := http.request(url + path, PackedStringArray(headers), method, JSON.stringify(body) if body != null else "")
	if error != OK:
		http.queue_free()
		return {"code": 0, "data": null}
	var result: Array = await http.request_completed
	http.queue_free()
	var text := (result[3] as PackedByteArray).get_string_from_utf8()
	var code: int = result[1] if result[0] == HTTPRequest.RESULT_SUCCESS else 0
	return {"code": code, "data": JSON.parse_string(text) if not text.is_empty() else null}


# --- Comptes ---

## Inscription ; renvoie { confirmer: bool } (vrai si un courriel de confirmation part, faux si le
## compte est utilisable tout de suite) ou { erreur }.
func sign_up(email: String, password: String) -> Dictionary:
	var answer := await request(HTTPClient.METHOD_POST, "/auth/v1/signup", {"email": email, "password": password})
	if answer["code"] in [200, 201]:
		var data: Variant = answer["data"]
		return {"confirmer": not (typeof(data) == TYPE_DICTIONARY and data.has("access_token"))}
	return {"erreur": _auth_error(answer)}


## Connexion ; renvoie { jeton } ou { erreur }.
func sign_in(email: String, password: String) -> Dictionary:
	var answer := await request(HTTPClient.METHOD_POST, "/auth/v1/token?grant_type=password", {"email": email, "password": password})
	if answer["code"] == 200 and typeof(answer["data"]) == TYPE_DICTIONARY and answer["data"].has("access_token"):
		return {"jeton": str(answer["data"]["access_token"])}
	return {"erreur": _auth_error(answer)}


## Compte (id) d'un jeton de joueur, ou "" s'il n'est pas valable.
func user_of(token: String) -> String:
	if token.is_empty():
		return ""
	var answer := await request(HTTPClient.METHOD_GET, "/auth/v1/user", null, [], token)
	if answer["code"] == 200 and typeof(answer["data"]) == TYPE_DICTIONARY:
		return str(answer["data"].get("id", ""))
	return ""


static func _auth_error(answer: Dictionary) -> String:
	if answer["code"] == 0:
		return "Le service de comptes ne répond pas."
	var data: Variant = answer["data"]
	var code := ""
	if typeof(data) == TYPE_DICTIONARY:
		code = str(data.get("error_code", data.get("code", "")))
		match code:
			"invalid_credentials":
				return "Adresse ou mot de passe incorrect."
			"email_not_confirmed":
				return "Adresse pas encore confirmée : ouvrez le lien du courriel reçu."
			"user_already_exists":
				return "Un compte existe déjà avec cette adresse."
			"weak_password":
				return "Mot de passe trop faible (6 caractères au moins)."
			"over_email_send_rate_limit", "over_request_rate_limit":
				return "Trop de tentatives : réessayez dans quelques minutes."
		var text := str(data.get("msg", data.get("error_description", data.get("message", ""))))
		if not text.is_empty():
			return text
	return "Erreur du service de comptes (%s)." % (code if not code.is_empty() else str(answer["code"]))


# --- Serveur de test (table « serveur_actuel ») ---

## Adresse (wss://…) du serveur de test en ligne, ou "" s'il n'y en a pas.
func live_server_address() -> String:
	var answer := await request(HTTPClient.METHOD_GET, "/rest/v1/%s?select=adresse" % LIVE_SERVER_VIEW)
	if answer["code"] == 200 and typeof(answer["data"]) == TYPE_ARRAY and not answer["data"].is_empty():
		return str(answer["data"][0].get("adresse", ""))
	return ""
