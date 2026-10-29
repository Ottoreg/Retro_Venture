class_name SupabaseStore
extends CharacterStore
## Personnages dans la base Supabase (table `personnages`, voir supabase/schema.sql), avec la clé
## secrète du serveur. Le pseudo est unique sans tenir compte des majuscules (index de la table).

var supabase: Supabase


func _init(p_supabase: Supabase) -> void:
	supabase = p_supabase


func load_character(account: String) -> Dictionary:
	var answer: Dictionary = await supabase.request(HTTPClient.METHOD_GET,
		"/rest/v1/personnages?select=etat&compte=eq.%s" % account.uri_encode())
	if answer["code"] == 200 and typeof(answer["data"]) == TYPE_ARRAY and not answer["data"].is_empty():
		var state: Variant = answer["data"][0].get("etat")
		return state if typeof(state) == TYPE_DICTIONARY else {}
	return {}


func name_taken(pseudo: String, account: String) -> bool:
	var answer: Dictionary = await supabase.request(HTTPClient.METHOD_GET,
		"/rest/v1/personnages?select=compte&pseudo_min=eq.%s" % pseudo.to_lower().uri_encode())
	if answer["code"] != 200 or typeof(answer["data"]) != TYPE_ARRAY:
		return true  # Dans le doute, refusé.
	for row: Variant in answer["data"]:
		if typeof(row) == TYPE_DICTIONARY and str(row.get("compte", "")) != account:
			return true
	return false


func save_report(report: Dictionary) -> bool:
	reports.append(report.duplicate(true))
	var row := {
		"auteur": report["auteur"],
		"auteur_nom": report["auteur_nom"],
		"cible": report["cible"],
		"cible_nom": report["cible_nom"],
		"motif": report["motif"],
		"commentaire": report["commentaire"],
		"messages": report["messages"],
		"carte": report["carte"],
	}
	var answer: Dictionary = await supabase.request(HTTPClient.METHOD_POST, "/rest/v1/signalements", row,
		["Prefer: return=minimal"])
	return answer["code"] in [200, 201, 204]


func save_character(account: String, pseudo: String, state: Dictionary) -> bool:
	return await save_characters([{"compte": account, "pseudo": pseudo, "etat": state}] as Array[Dictionary])


## Une seule requête pour toutes les lignes : PostgREST les écrit en une instruction, donc en une
## transaction (tout ou rien), ce qu'il faut pour les deux personnages d'un échange.
func save_characters(entries: Array[Dictionary]) -> bool:
	var rows: Array = []
	for entry in entries:
		rows.append(_row(entry["compte"], entry["pseudo"], entry["etat"]))
	var answer: Dictionary = await supabase.request(HTTPClient.METHOD_POST, "/rest/v1/personnages?on_conflict=compte", rows,
		["Prefer: resolution=merge-duplicates,return=minimal"])
	return answer["code"] in [200, 201, 204]


func _row(account: String, pseudo: String, state: Dictionary) -> Dictionary:
	var character: Dictionary = state.get("personnage", {})
	return {
		"compte": account,
		"pseudo": pseudo,
		"race": str(character.get("race", "")),
		"voie": str(character.get("voie", "")),
		"carte": str(state.get("carte", "")),
		"etat": state,
		"maj": Time.get_datetime_string_from_system(true) + "Z",
	}
