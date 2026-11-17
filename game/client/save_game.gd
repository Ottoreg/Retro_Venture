class_name SaveGame
extends RefCounted
## Sauvegarde de la partie dans `user://` (un fichier sur PC, le stockage du navigateur sur le web).
## Export et import : la sauvegarde compressée puis chiffrée (AES-256-CBC, clé tirée de `SECRET`)
## devient une image PNG dont chaque pixel porte 3 octets (rouge, vert, bleu) : un brouillard coloré.
## En-tête : `MAGIC`, vecteur d'initialisation (16 octets), taille compressée (4 octets).

const PATH := "user://sauvegarde.json"
const SECRET := "Brumes de Hautepierre, gobelins syndiqués et elfes snobs"
const MAGIC := "RVS1"
const EXPORT_NAME := "retro_venture_sauvegarde.png"


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


## Contenu de la sauvegarde, ou `{}` si elle est absente ou illisible.
static func read() -> Dictionary:
	if not exists():
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return data if typeof(data) == TYPE_DICTIONARY else {}


static func write(data: Dictionary) -> bool:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Sauvegarde impossible : %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


## Résumé affiché dans le menu (« Elara — Rôdeur »), ou "".
static func summary() -> String:
	var save := read()
	var hero: Variant = save.get("personnage")
	if typeof(hero) != TYPE_DICTIONARY:
		return ""
	return "%s — %s" % [str(hero.get("nom", "?")), str(hero.get("voie", "?")).capitalize()]


## Image PNG chiffrée de la sauvegarde (à n'appeler que si elle existe).
static func to_png() -> PackedByteArray:
	var plain := FileAccess.get_file_as_bytes(PATH).compress(FileAccess.COMPRESSION_GZIP)
	var size := plain.size()
	plain.resize(size + 16 - size % 16)  # Bourrage par blocs de 16 : la vraie taille est dans l'en-tête.
	var iv := Crypto.new().generate_random_bytes(16)
	var data := MAGIC.to_ascii_buffer() + iv + PackedByteArray([0, 0, 0, 0]) + _aes(AESContext.MODE_CBC_ENCRYPT, iv, plain)
	data.encode_u32(20, size)
	var side := ceili(sqrt(ceili(data.size() / 3.0)))
	if side * side * 3 > data.size():  # Pixels restants : du brouillard aléatoire.
		data += Crypto.new().generate_random_bytes(side * side * 3 - data.size())
	return Image.create_from_data(side, side, false, Image.FORMAT_RGB8, data).save_png_to_buffer()


## Remplace la sauvegarde par celle d'une image exportée ; faux si l'image n'en contient pas.
static func from_png(png: PackedByteArray) -> bool:
	var image := Image.new()
	if image.load_png_from_buffer(png) != OK:
		return false
	image.convert(Image.FORMAT_RGB8)
	var data := image.get_data()
	if data.size() < 40 or data.slice(0, 4).get_string_from_ascii() != MAGIC:
		return false
	var size := data.decode_u32(20)
	var end := 24 + size + 16 - size % 16
	if data.size() < end:
		return false
	var plain := _aes(AESContext.MODE_CBC_DECRYPT, data.slice(4, 20), data.slice(24, end)).slice(0, size)
	var save: Variant = JSON.parse_string(plain.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP).get_string_from_utf8())
	return typeof(save) == TYPE_DICTIONARY and typeof(save.get("personnage")) == TYPE_DICTIONARY and write(save)


static func _aes(mode: AESContext.Mode, iv: PackedByteArray, bytes: PackedByteArray) -> PackedByteArray:
	var aes := AESContext.new()
	aes.start(mode, SECRET.sha256_buffer(), iv)
	var result := aes.update(bytes)
	aes.finish()
	return result
