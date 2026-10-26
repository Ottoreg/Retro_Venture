class_name AccountCheck
extends RefCounted
## Vérifie le jeton qu'un client présente à l'ouverture (GDD § 16.5) et en tire son compte. Cette
## version sert au développement : elle accepte « dev:Pseudo » (compte « dev:pseudo »), sans mot de
## passe. `SupabaseAccounts` vérifie les vrais jetons auprès du service de comptes. Peut attendre.

const DEV_PREFIX := "dev:"


## Compte du jeton, ou "" s'il est refusé.
func account_of(token: String) -> String:
	if not token.begins_with(DEV_PREFIX):
		return ""
	var pseudo := token.substr(DEV_PREFIX.length()).strip_edges()
	if not Character.name_error(pseudo).is_empty():
		return ""
	return DEV_PREFIX + pseudo.to_lower()
