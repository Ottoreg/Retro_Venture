class_name SupabaseAccounts
extends AccountCheck
## Vérifie les jetons des joueurs auprès de Supabase Auth (GDD § 16.5) : le compte est l'id de
## l'utilisateur. Le mot de passe ne passe jamais par le serveur de jeu. Pas de jetons « dev: » ici.

var supabase: Supabase


func _init(p_supabase: Supabase) -> void:
	supabase = p_supabase


func account_of(token: String) -> String:
	if token.begins_with(DEV_PREFIX):
		return ""
	return await supabase.user_of(token)
