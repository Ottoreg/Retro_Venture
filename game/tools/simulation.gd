extends SceneTree
## Combats simulés pour vérifier l'équilibrage, sans affichage :
##   godot --headless --path game -s res://tools/simulation.gd -- [combats] [sortie.md] [filtre] [detail] [+niveaux] [trio]
## Pour chaque groupe de chaque carte (`filtre` : début des ids de cartes, « brumerive,crasse_roc »),
## chaque Voie affronte `combats` fois le groupe (10 par défaut), avec un profil du niveau équivalent
## au palier moyen des monstres tirés (`TIER_LEVELS`, celui du boss s'il y en a un).
## Le joueur est joué par l'IA des monstres (« basique » pour le guerrier, « distance » sinon), sa
## race est celle de la zone (humain ailleurs), ses points vont dans la caractéristique de sa Voie,
## et l'équipement est modélisé comme dans `balance.py` : +3 par niveau à cette caractéristique et
## aux PV, +1 dommage tous les 5 niveaux. Le rapport (Markdown) compare la durée des combats et les
## PV perdus à la référence du modèle : 2 monstres de son niveau en 2 + n/10 tours, 40 % des PV.
## Sixième argument « trio » : un groupe guerrier + rôdeur + théologue à la place des Voies seules
## (donjons), PV perdus en moyenne sur les trois.

const BUILDS := {
	"guerrier": {"force": 1.0},
	"arcaniste": {"intelligence": 1.0},
	"rodeur": {"agilite": 0.5, "force": 0.5},
	"theologue": {"force": 0.5, "intelligence": 0.5},
	"chronomancien": {"agilite": 0.5, "perception": 0.5},
}
const ZONE_RACES := {"brumerive": "humain", "crasse_roc": "gobelin", "sylvebrume": "elfe"}
## Hors de ces bornes, la ligne du rapport est signalée (victoires, PV perdus en rapport à la référence).
## Niveau équivalent maximal des profils simulés, et points par niveau (ancien système).
const MAX_LEVEL := 30
const POINTS_PER_LEVEL := 5
## Niveau équivalent du profil simulé contre chaque palier de monstre (moyenne des anciens niveaux du palier).
const TIER_LEVELS := [1, 3, 10, 17, 26, 40]
const MIN_WIN_RATE := 0.8
const HP_RATIO_RANGE := [0.25, 1.8]

var data: GameData
## Quatrième argument « detail » : une ligne par combat (issue, tours, PV restants de chacun).
var detail := false
## Cinquième argument : niveaux d'avance du joueur sur les monstres (« +3 »), 0 par défaut.
var level_bonus := 0
## Équipes simulées : chaque Voie seule, ou le trio (sixième argument).
var teams: Array = BUILDS.keys().map(func(voie: String) -> Array: return [voie])
var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var fights := int(args[0]) if args.size() > 0 else 10
	var output := args[1] if args.size() > 1 else ""
	var filters: Array = Array(args[2].split(",")) if args.size() > 2 and not args[2].is_empty() else []
	detail = args.size() > 3 and args[3] == "detail"
	level_bonus = int(args[4]) if args.size() > 4 else 0
	if args.size() > 5 and args[5] == "trio":
		teams = [["guerrier", "rodeur", "theologue"]]
	rng.seed = 12345
	data = GameData.load_all()
	var lines: Array[String] = [
		"# Combats simulés", "",
		"%d combats par Voie et par groupe (`tools/simulation.gd`). Tours : tours du joueur ; référence : " % fights
			+ "2 + n/10 tours et 40 % des PV pour 2 monstres de son niveau, au prorata du nombre de monstres. "
			+ "Rapport PV : PV perdus / référence (1 = conforme). ⚠ : moins de %d %% de victoires ou rapport hors de %.2f–%.2f." % [
				roundi(MIN_WIN_RATE * 100), HP_RATIO_RANGE[0], HP_RATIO_RANGE[1]], "",
		"Progression (GDD § 4.5) : facteur de difficulté du combat et réputation gagnée par combat gagné, "
			+ "pour un joueur au niveau équivalent (`Progression`).", "",
		"| Carte | Groupe | Niv. | Victoires (%s) |" % "/".join(teams.map(func(t: Array) -> String:
			return "+".join(t.map(func(voie: String) -> String: return voie[0].to_upper())))) + " Tours (réf.) | PV perdus % (réf.) | Rapport PV | Facteur | Rép./combat | |",
		"|---|---|---|---|---|---|---|---|---|---|",
	]
	var summary := {}
	for map_id in DataLoader.map_ids():
		if not filters.is_empty() and not filters.any(func(f: String) -> bool: return map_id.begins_with(f)):
			continue
		var map := DataLoader.load_map(DataLoader.map_path(map_id))
		if map == null or map.groups.is_empty():
			continue
		for group in map.groups:
			var row := _simulate_group(map, group, fights)
			lines.append(row["ligne"])
			var zone := map_id.rsplit("_", true, 2)[0]
			if not summary.has(zone):
				summary[zone] = {"groupes": 0, "alertes": 0}
			summary[zone]["groupes"] += 1
			summary[zone]["alertes"] += 1 if row["alerte"] else 0
	lines.append("")
	lines.append("| Zone | Groupes | Alertes |")
	lines.append("|---|---|---|")
	for zone: String in summary:
		lines.append("| %s | %d | %d |" % [zone, summary[zone]["groupes"], summary[zone]["alertes"]])
	var text := "\n".join(lines) + "\n"
	if output.is_empty():
		print(text)
	else:
		var file := FileAccess.open(output, FileAccess.WRITE)
		file.store_string(text)
		print("rapport : ", output)
	quit()


func _simulate_group(map: GameMap, group: Dictionary, fights: int) -> Dictionary:
	var wins: Array[String] = []
	var rounds := 0.0
	var lost := 0.0
	var won_total := 0
	var levels_total := 0.0
	var size_total := 0.0
	var factor_total := 0.0
	var reputation_total := 0.0
	var names := {}
	for team: Array in teams:
		var won := 0
		for i in fights:
			var composed := GameMap.compose_group(group, rng)
			var result := _fight(map, composed, team)
			levels_total += result["niveau"]
			factor_total += result["facteur"]
			size_total += composed["monstres"].size()
			for monster_id: String in composed["monstres"]:
				names[data.monsters[monster_id]["nom"]] = true
			if result["victoire"]:
				won += 1
				rounds += result["tours"]
				lost += result["pv_perdus"]
				reputation_total += result["reputation"]
		wins.append("%d" % roundi(100.0 * won / fights))
		won_total += won
	var count := fights * teams.size()
	var level := levels_total / count
	var size := size_total / count
	var ref_turns := (2.0 + level / 10.0) * size / 2.0
	var ref_lost := 40.0 * size / 2.0
	var mean_rounds := rounds / maxi(1, won_total)
	var mean_lost := 100.0 * lost / maxi(1, won_total)
	var ratio := mean_lost / ref_lost
	var alert := float(won_total) / count < MIN_WIN_RATE or ratio < HP_RATIO_RANGE[0] or ratio > HP_RATIO_RANGE[1]
	var label := ", ".join(names.keys())
	var line := "| %s | %s | %.0f | %s | %.1f (%.1f) | %.0f (%.0f) | %.2f | %.2f | %.0f | %s |" % [map.id, label, level,
		"/".join(wins), mean_rounds, ref_turns, mean_lost, ref_lost, ratio, factor_total / count,
		reputation_total / maxi(1, won_total), "⚠" if alert else ""]
	return {"ligne": line, "alerte": alert}


## Un combat du joueur (IA) contre le groupe : { victoire, tours, pv_perdus (fraction), niveau, facteur
## (de difficulté), reputation (gagnée par la pratique et les monstres vaincus) }.
func _fight(map: GameMap, group: Dictionary, team: Array) -> Dictionary:
	var tiers: Array = group["monstres"].map(data.monster_tier)
	var tier := roundi(tiers.reduce(func(sum: int, value: int) -> int: return sum + value, 0) / float(tiers.size()))
	for i in tiers.size():
		if data.monsters[group["monstres"][i]].get("boss", false):
			tier = tiers[i]  # Contre un boss : le joueur est à son palier.
	var level := clampf(TIER_LEVELS[tier] + level_bonus, 1, MAX_LEVEL)
	var race: String = ZONE_RACES.get(map.id.rsplit("_", true, 2)[0], "humain")
	# Profil équivalent à l'ancien niveau (plus de niveau depuis la refonte, GDD § 4.5) : 5 points de
	# caractéristique et 5 PV par niveau au-dessus du 1er, répartis selon le build (les caractéristiques
	# gagnées par la pratique y arrivent à peu près, plafonnées).
	var fighters: Array[Fighter] = []
	var cells: Array[Vector2i] = map.placement_monsters.duplicate()
	var placement: Array[Vector2i] = map.placement_players.duplicate()
	if rng.randi_range(0, 1) == 1 and placement.size() >= GameMap.MIN_PLACEMENT:
		# Côtés tirés au sort, comme en jeu (`World._create_combat`).
		var swap_sides := cells
		cells = placement
		placement = swap_sides
	for i in range(cells.size() - 1, 0, -1):
		var k := rng.randi_range(0, i)
		var swap := cells[i]
		cells[i] = cells[k]
		cells[k] = swap
	for i in group["monstres"].size():
		var monster := data.create_monster(group["monstres"][i], "m%d" % i)
		monster.cell = cells[i]
		fighters.append(monster)
	var players: Array[Fighter] = []
	for k in team.size():
		var voie: String = team[k]
		var character := Character.create("Simulé", race, voie)
		var build: Dictionary = BUILDS[voie]
		var points := POINTS_PER_LEVEL * int(level - 1)
		character.gain_stat("vitalite", points)
		for stat_name: String in build:
			character.gain_stat(stat_name, roundi(points * float(build[stat_name])))
		var player := data.create_character_fighter(character, "joueur%d" % k)
		# Équipement modélisé (voir l'en-tête).
		for stat_name: String in build:
			player.stats[stat_name] = int(player.stats.get(stat_name, 0)) + roundi(3 * level * float(build[stat_name]))
		player.max_hp += roundi(3 * level)
		player.hp = player.max_hp
		player.dommages += int(level) / 5
		player.ai = CombatAI.BASIC if voie == "guerrier" else CombatAI.RANGED
		player.cell = placement[k]
		players.append(player)
	fighters.append_array(players)
	var combat := Combat.new(map, fighters, placement, rng.randi())
	combat.start()
	# Les joueurs se déclarent prêts sans IA (sinon c'est refusé) ; les monstres jouent jusqu'au tour d'un joueur.
	for player in players:
		player.ai = ""
		combat.execute({"type": Protocol.CMD_READY, "entite": player.id})
	for k in players.size():
		players[k].ai = CombatAI.BASIC if team[k] == "guerrier" else CombatAI.RANGED
	if combat.state == Combat.State.FIGHTING:
		# Ce premier tour joué par l'IA, puis tout le combat se déroule seul.
		var events: Array[Dictionary] = []
		combat._play_ai_turn(combat.current_fighter(), events)
		if combat.state == Combat.State.FIGHTING:
			combat._next_turn(events)
	if detail:
		var states: Array[String] = []
		for fighter in fighters:
			states.append("%s %d/%d" % [fighter.kind, fighter.hp, fighter.max_hp])
		print("%s %s niv. %d : %s en %d tours — %s" % [map.id, "+".join(team), level,
			{Fighter.TEAM_PLAYERS: "victoire", -1: "nul"}.get(combat.winner_team, "défaite"), combat.round_number, ", ".join(states)])
	# Progression d'un joueur à ce niveau équivalent (GDD § 4.5), comme `World._end_combat`.
	var fallen_xp := 0
	for fighter in fighters:
		if fighter.team != Fighter.TEAM_PLAYERS:
			fallen_xp += fighter.xp if not fighter.is_alive() else 0
	var factor := Progression.difficulty(tiers, players.map(func(_p: Fighter) -> int: return tier))
	var gains := Progression.gains(combat.practice.get("joueur0", {}), factor, fallen_xp * Progression.KILL_SHARE * factor / players.size())
	return {
		"facteur": factor,
		"reputation": float(gains["reputation"]),
		"victoire": combat.winner_team == Fighter.TEAM_PLAYERS,
		"tours": float(combat.round_number),
		"pv_perdus": 1.0 - players.reduce(func(sum: float, p: Fighter) -> float: return sum + float(p.hp) / p.max_hp, 0.0) / players.size(),
		"niveau": level,
	}
