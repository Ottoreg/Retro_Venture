class_name Session
extends RefCounted
## Informations passées d'un écran à l'autre (menu → création → monde).

## Personnage tout juste créé, ou `null`.
static var new_character: Character = null
## Vrai pour reprendre la partie sauvegardée.
static var continue_game := false
## Carte de départ imposée (outils de capture d'écran), ou "" pour celle de la race.
static var start_map := ""
## Suivi de quête replié par le joueur (gardé pendant la partie, pas dans la sauvegarde).
static var tracker_folded := false
## Historique replié (même règle), et onglet choisi (`MessageLog.CHANNEL_*`).
static var message_log_folded := false
static var message_log_channel := "tout"
## Repère posé depuis un texte de quête ({ carte, nom }, voir `QuestLinks`), ou {} : montré sur la
## minicarte et la carte du monde, retiré en arrivant sur sa carte (pas dans la sauvegarde).
static var quest_pin: Dictionary = {}

## Jeu en ligne (GDD § 16.5) : connexion au serveur ouverte par l'écran de connexion, ou `null` en
## solo.
static var online_connection: RemoteConnection = null
## Message à montrer sur l'écran de connexion (connexion perdue ou refusée), ou "".
static var online_error := ""
## Dernière connexion réussie, pour revenir sans retaper le mot de passe après une coupure :
## { jeton, renouvellement } (Supabase : le jeton ne vaut qu'une heure, le renouvellement en redonne
## un), ou { jeton } seul sur un serveur de développement ; {} sans connexion.
static var online_login: Dictionary = {}
## Vrai quand la connexion vient d'être coupée : l'écran de connexion la rouvre tout seul.
static var online_resume := false

## Questionnaire des testeurs (menu principal et menu pause : « Donner son avis »).
const FEEDBACK_URL := "https://docs.google.com/forms/d/e/1FAIpQLSdwoJr5-OnRuVcVNbvRGnjtO4MqxJTUe7SIIbgfeKJlRuYcxQ/viewform"
