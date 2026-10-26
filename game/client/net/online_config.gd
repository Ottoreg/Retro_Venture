class_name OnlineConfig
extends RefCounted
## Projet Supabase du jeu en ligne (GDD § 16.5) : comptes, personnages et adresse du serveur de
## test. L'adresse du projet et sa clé **publique** (« publishable key », faite pour être dans le
## client) ; jamais la clé secrète, qui ne va que dans le `.env` du serveur. Vides : le jeu en ligne
## ne marche qu'avec un serveur de développement (adresse dans les options, pseudo sans mot de passe).

## Ex. « https://abcdefgh.supabase.co ».
const SUPABASE_URL := "https://gvwgmtvlrlnaefvwsuuu.supabase.co/rest/v1/"
## Ex. « sb_publishable_… ».
const PUBLISHABLE_KEY := "sb_publishable_tzX0sWfrdjk8CYpoJKo3YQ_Yh1QW-3E"


static func has_accounts() -> bool:
	return not SUPABASE_URL.is_empty() and not PUBLISHABLE_KEY.is_empty()
