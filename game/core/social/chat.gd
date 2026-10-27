class_name Chat
extends RefCounted
## Chat par canaux (GDD § 16.5, jalon M3) : règles des messages, sans réseau. `World` dit qui
## reçoit chaque canal ; le chat vérifie le texte, limite le débit de chacun et garde un journal des
## derniers messages de chaque canal (pour les signalements, M3 lot 4).

## Canaux : la carte de l'auteur, son groupe, tout le serveur (annonces d'achat et de vente ;
## recherche de groupe puis de guilde), un seul joueur nommé par son pseudo.
const LOCAL := "local"
const PARTY := "groupe"
const TRADE := "commerce"
const RECRUIT := "recrutement"
const PRIVATE := "prive"
const CHANNELS := [LOCAL, PARTY, TRADE, RECRUIT, PRIVATE]
## Canaux de tout le serveur : un message par auteur et par canal toutes les WORLD_CHANNEL_DELAY s.
const WORLD_CHANNELS := [TRADE, RECRUIT]

## Longueur d'un message (caractères), au-delà coupé.
const MAX_LENGTH := 200
## Anti-flood : au plus FLOOD_MESSAGES messages (tous canaux) par FLOOD_SECONDS s.
const FLOOD_MESSAGES := 5
const FLOOD_SECONDS := 10.0
const WORLD_CHANNEL_DELAY := 60.0
## Messages gardés par canal dans le journal.
const JOURNAL_SIZE := 200

## Canal → derniers messages, du plus ancien au plus récent : { de (id), auteur (nom), texte,
## heure (horloge du monde), a (id du destinataire d'un privé, sinon "") }.
var journal: Dictionary = {}
## Auteur (id) → heures de ses derniers messages (anti-flood).
var _sent: Dictionary = {}
## Auteur (id) → canal → heure de son dernier message sur un canal de tout le serveur.
var _world_sent: Dictionary = {}


## Texte nettoyé : sans caractères de contrôle ni espaces autour, coupé à MAX_LENGTH ("" : rien à
## envoyer). Les crochets restent : le client les montre tels quels (pas de BBCode venu d'un joueur).
static func clean(text: String) -> String:
	var kept := ""
	for i in text.length():
		var code := text.unicode_at(i)
		kept += " " if code < 32 or code == 127 else text[i]
	return kept.strip_edges().left(MAX_LENGTH)


## Secondes à attendre avant que `sender_id` puisse écrire sur `channel` à l'heure `now` (0 : il peut).
func wait_time(sender_id: String, channel: String, now: float) -> float:
	var wait := 0.0
	var recent: Array = _sent.get(sender_id, []).filter(func(time: float) -> bool: return now - time < FLOOD_SECONDS)
	_sent[sender_id] = recent
	if recent.size() >= FLOOD_MESSAGES:
		wait = FLOOD_SECONDS - (now - float(recent[0]))
	if channel in WORLD_CHANNELS and _world_sent.get(sender_id, {}).has(channel):
		wait = maxf(wait, WORLD_CHANNEL_DELAY - (now - float(_world_sent[sender_id][channel])))
	return maxf(wait, 0.0)


## Note un message envoyé : débit de son auteur et journal du canal.
func record(sender_id: String, sender_name: String, channel: String, text: String, now: float, target_id := "") -> void:
	if not _sent.has(sender_id):
		_sent[sender_id] = []
	_sent[sender_id].append(now)
	if channel in WORLD_CHANNELS:
		if not _world_sent.has(sender_id):
			_world_sent[sender_id] = {}
		_world_sent[sender_id][channel] = now
	if not journal.has(channel):
		journal[channel] = []
	var lines: Array = journal[channel]
	lines.append({"de": sender_id, "auteur": sender_name, "texte": text, "heure": now, "a": target_id})
	if lines.size() > JOURNAL_SIZE:
		lines.pop_front()


## Derniers messages de `sender_id` gardés au journal, tous canaux, du plus ancien au plus récent
## (au plus `count`), chacun avec son `canal`.
func recent_by(sender_id: String, count := 20) -> Array:
	var found: Array = []
	for channel: String in journal:
		for line: Dictionary in journal[channel]:
			if line["de"] == sender_id:
				var copy := line.duplicate()
				copy["canal"] = channel
				found.append(copy)
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["heure"] < b["heure"])
	return found.slice(maxi(0, found.size() - count))



## Id du dernier auteur de ce pseudo encore au journal (sans tenir compte des majuscules), ou "" :
## on peut signaler un joueur parti après avoir écrit.
func author_id(author_name: String) -> String:
	var wanted := author_name.strip_edges().to_lower()
	var found := ""
	var latest := -INF
	for channel: String in journal:
		for line: Dictionary in journal[channel]:
			if str(line["auteur"]).to_lower() == wanted and float(line["heure"]) >= latest:
				latest = float(line["heure"])
				found = line["de"]
	return found
