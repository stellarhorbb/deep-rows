class_name TurnController
extends Node

signal turn_started()
signal awaiting_input()
signal drop_animated()
signal special_effect_done()
signal last_breath_ready()
signal timeline_done_ack()
## Emis a la fin d'une passe de resolution "intermediaire" (voir _pre_pass) —
## uniquement pour reveiller l'await dans play_current_to, jamais consomme
## ailleurs (contrairement a turn_resolved, qui ne sort qu'une fois par tour
## reel, apres la 2e passe).
signal resolution_pass_done()
signal turn_resolved(timeline: Array[Dictionary])
signal last_breath_started()
## Legendaire "Souffle Obscur" (session 23) : emis quand la deuxieme vague du
## Dernier Souffle demarre (les entity-skulls disparaissent) — voir
## _trigger_second_wave. Meme role que last_breath_started, pour sa propre
## banniere/message dedie.
signal second_wave_started()
## Sortilège "Dernier dernier Souffle" (Va-tout, session "Vague 2") : emis
## une fois le tirage all-in resolu, avec le score final APRES le tirage --
## le visuel doit reveler ce moment explicitement (voir GameScene._on_va_
## tout_resolved), meme raison que petard_scored/comete_scored.
signal va_tout_resolved(final_score: int, won_gamble: bool)
signal round_won(score: int, target: int)
signal round_lost(score: int, target: int)
## Emis quand un explosif de la famille Petard/Bombe/Armageddon (session 25)
## detone et rapporte des points, en dehors de la banniere de resolution
## normale (voir GridManager.tick_special_countdowns) — le visuel doit
## reveler ce score explicitement (voir GameScene._on_petard_scored).
signal petard_scored(amount: int)
## Emis quand le special "Comete" (session "Vague 2") score en traversant sa
## diagonale -- meme raison que petard_scored, en dehors de la banniere de
## resolution normale (instant a l'impact, voir GridManager.execute_special).
signal comete_scored(amount: int)
## Sortilège "Pile ou Face" (session "Vague 2") : le jeton qui vient d'etre
## pose a ete mute en place (valeur ou kind) -- rien d'autre dans le jeu ne
## mute le jeton dropped lui-meme pendant on_token_drop, donc une diff avant/
## apres suffit a detecter le declenchement sans coupler TurnController a un
## id de Sortilège precis. Emis seulement une fois l'animation de chute
## terminee (apres drop_animated), pas au moment du drop -- le joueur doit
## voir le jeton atterrir avant de voir sa valeur changer, meme langage
## visuel que le Boost de la roulette (voir GameScene._on_dropped_token_
## mutated / GridVisual.animate_boost).
signal dropped_token_mutated(col: int, row: int)
## Emis quand un special "mangeur/scoreur" (Cavalier, Frog, Liane) mange un
## jeton en se deplacant/grandissant — meme raison que petard_scored, en
## dehors de la banniere de resolution normale (voir tick_mobile_specials).
signal mobile_specials_scored(amount: int)
## Case mystere revelee et resolue (voir GridManager.mystery_cell_triggered /
## _on_mystery_cell_triggered) — le visuel affiche un message et, si
## target_delta != 0 (SCORE_UP/SCORE_DOWN, retune : deplacent la cible plutot
## que le score actuel, voir ScoreManager.adjust_target), rafraichit le label
## de cible.
signal mystery_cell_resolved(col: int, row: int, effect: MysteryCellEffects.Type, target_delta: int)

## Hooks consommes par SpellManager (dispatch vers les SpellEffect equipes).
signal round_started()
signal token_dropped(token: TokenData, col: int, row: int)
signal cascade_step_resolved(level: int, earned: int)
signal shake_used()

enum State { AWAITING_INPUT, DROPPING, RESOLVING, LAST_BREATH, ROUND_OVER }

var _state: State = State.AWAITING_INPUT

## Legendaire "Souffle Obscur" : vrai des que la deuxieme vague a ete tentee
## pour la manche en cours, pour ne jamais la redeclencher (voir _on_
## resolution_complete). Remis a faux a chaque nouveau Dernier Souffle.
var _second_wave_triggered: bool = false

## Sortilège "Dernier dernier Souffle" (Va-tout, session "Vague 2") : vrai
## des que le tirage all-in a ete tente pour la manche en cours, pour ne
## jamais le redeclencher (voir _on_resolution_complete). Remis a faux a
## chaque nouveau Dernier Souffle, meme convention que _second_wave_triggered.
var _vatout_triggered: bool = false

## Vrai pendant la 1ere des deux passes de resolution d'un tour normal (voir
## play_current_to) — resout un pattern deja complet AVANT que les mobiles/
## petards ne puissent le perturber (retour de playtest session 23 : Underground
## qui bouge juste avant qu'un pattern ne soit vu = perte silencieuse). Fait
## sauter la fin de tour habituelle dans _on_resolution_complete (avance du
## stream, verif defaite...), qui n'a lieu qu'a la 2e passe — sinon ces effets
## se declencheraient deux fois par tour reel.
var _pre_pass: bool = false
var _pre_pass_timeline: Array[Dictionary] = []

## Vrai pour un tour normal (jeton tire du stream), faux pour un tour venu de
## l'inventaire de speciaux (session 25, voir play_special_from_inventory) --
## lu par _on_resolution_complete pour sauter l'avancee du deck/stream
## (advance_stream, verif d'epuisement, coup legal) quand aucun jeton n'a
## reellement ete tire. Remis a true par defaut a la fin de chaque tour.
var _current_turn_from_stream: bool = true

@export var grid_manager: GridManager
@export var deck_manager: DeckManager
@export var score_manager: ScoreManager
@export var sheet_manager: SheetManager
@export var run_manager: RunManager
@export var boss_malus_manager: BossMalusManager


func _ready() -> void:
	grid_manager.resolution_complete.connect(_on_resolution_complete)
	grid_manager.mystery_cell_triggered.connect(_on_mystery_cell_triggered)


func start_round(round_number: int) -> void:
	score_manager.reset_round(round_number)
	grid_manager.init_grid()

	# 0. Grille cabossee : fond marin + trous rouges deja en place avant le
	# premier drop, differents a chaque manche.
	grid_manager.generate_random_holes()

	# 0a. Persistance entre manches (session 26) : place les jetons persistes
	# en donnee seule -- l'animation (chute gauche a droite) et les cases
	# mystere (qui doivent les voir deja poses) sont orchestrees par
	# GameScene, voir finish_round_start() plus bas.

	# 1. Reset de la couche modifiers de manche.
	run_manager.reset_round_modifiers()

	# 1b. Malus de boss (manche 5, 10, 15, 20) : pose ses verrous/bonus via les
	# memes hooks qu'un Sortilège on_round_start, avant que le contexte ne soit construit.
	boss_malus_manager.apply_for_round(round_number, run_manager)

	# 1c. L'ÉTAU / CIEL BAS : trous fixes en plus de la grille cabossee
	# aleatoire ci-dessus, colonnes/rangee entierement bloquees pour la manche.
	match boss_malus_manager.active_malus:
		BossMalusManager.Type.ETAU:
			var etau_cells: Array[Vector2i] = []
			for col in boss_malus_manager.etau_columns:
				for row in range(GameRules.ROWS):
					etau_cells.append(Vector2i(col, row))
			grid_manager.add_holes(etau_cells)
		BossMalusManager.Type.CIEL_BAS:
			var ciel_bas_cells: Array[Vector2i] = []
			for col in range(GameRules.COLS):
				ciel_bas_cells.append(Vector2i(col, GameRules.ROWS - 1))
			grid_manager.add_holes(ciel_bas_cells)

	_reroll_colonne_maudite()

	# Suite dans finish_round_start(), appelee par GameScene une fois l'intro
	# visuelle des jetons persistes terminee (voir GameScene._start_round).


## Appele par GameScene apres l'animation des jetons persistes (chute gauche
## a droite, session 26) -- genere les cases mystere en dernier, expres,
## pour qu'elles evitent les cases desormais occupees par ces jetons, puis
## rend la main au joueur. `carried_over` : les jetons que GameScene vient de
## poser sur la grille, pour que build_deck() ne leur redonne pas une
## deuxieme copie jouable (ils font deja partie du pool possede).
func finish_round_start(carried_over: Array[TokenData] = []) -> void:
	var mystery_count: int = randi_range(GameRules.ROUND_START_MYSTERY_MIN, GameRules.ROUND_START_MYSTERY_MAX)
	grid_manager.generate_random_mystery_cells(mystery_count)

	# 2. Les sortilèges on_round_start peuplent grid_modifiers et rule_multipliers.
	round_started.emit()

	# 3. Publie le dict final pour l'UI et snapshot le contexte.
	run_manager.notify_grid_modifiers_ready()
	var context: RunContext = run_manager.build_context()
	sheet_manager.set_active_sheets(context.equipped_sheets)
	grid_manager.set_run_context(context)

	deck_manager.hold_capacity = 0 if context.hold_locked else GameRules.BASE_HOLD_SLOTS + context.hold_slot_bonus
	deck_manager.preview_bonus = context.preview_size_bonus
	deck_manager.rock_count_bonus = context.rock_count_bonus
	deck_manager.build_deck(run_manager.get_button_pool(), carried_over)
	deck_manager.advance_stream()
	_state = State.AWAITING_INPUT
	turn_started.emit()
	awaiting_input.emit()


func play_current_to(col: int, row: int) -> void:
	if _state != State.AWAITING_INPUT:
		return

	var token: TokenData = deck_manager.get_current()
	if token == null:
		return
	if not grid_manager.can_play_token(token, col, row):
		return

	_current_turn_from_stream = true
	_state = State.DROPPING
	deck_manager.consume_current()
	await _drop_token(token, col)

	# Malus de boss BOURRASQUE (voir BossMalusManager, DeckManager.
	# take_first_held) : le jeton tenu en Hold (premier slot non vide) tombe
	# automatiquement dans la meme colonne, juste au-dessus -- silencieux si
	# rien n'est tenu, ou si la colonne est deja pleine (pas de perte de
	# jeton, il reste en Hold). Special au sens stream uniquement -- n'a pas
	# de sens pour un tour venu de l'inventaire (voir play_special_from_
	# inventory), donc reste ici plutot que dans le pipeline commun _resolve_turn.
	if boss_malus_manager.active_malus == BossMalusManager.Type.BOURRASQUE:
		var held_token: TokenData = deck_manager.get_hold()
		if held_token != null and grid_manager.can_play_token(held_token, col, 0):
			deck_manager.take_first_held()
			await _drop_token(held_token, col)

	await _resolve_turn()


## Joue un special depuis l'inventaire possede du joueur (session 25, voir
## RunManager.get_special_inventory/remove_special_from_inventory) a la place
## du coup normal -- meme pipeline de resolution que play_current_to (pre-
## passe, countdowns/mobiles, cascade, voir _resolve_turn), mais ne touche
## jamais au deck/stream puisque ce jeton n'en vient pas (_current_turn_
## from_stream = false, lu par _on_resolution_complete pour sauter l'avancee
## du stream/la verif de coup legal cote deck).
func play_special_from_inventory(inventory_index: int, col: int) -> void:
	if _state != State.AWAITING_INPUT:
		return
	var inventory: Array[TokenData.SpecialType] = run_manager.get_special_inventory()
	if inventory_index < 0 or inventory_index >= inventory.size():
		return
	var token: TokenData = TokenData.make_special(inventory[inventory_index])
	if not grid_manager.can_play_token(token, col, 0):
		return

	_current_turn_from_stream = false
	_state = State.DROPPING
	run_manager.remove_special_from_inventory(inventory_index)
	await _drop_token(token, col)
	await _resolve_turn()


## Pipeline de resolution commun a play_current_to et play_special_from_
## inventory : 1ere passe (voir _pre_pass), countdowns entity/petard,
## speciaux mobiles, puis la cascade complete. La fin de tour (avancee du
## deck/stream) est geree separement dans _on_resolution_complete, selon
## _current_turn_from_stream.
func _resolve_turn() -> void:
	# 1ere passe de resolution (session 23) : score un pattern deja complet
	# suite au drop AVANT que MÈCHE COURTE/petards/mobiles n'aient la moindre
	# chance de le perturber. Voir _pre_pass.
	_state = State.RESOLVING
	_pre_pass = true
	grid_manager.resolve()
	await resolution_pass_done
	_pre_pass = false
	_state = State.DROPPING

	# Malus de boss MÈCHE COURTE (voir BossMalusManager) : decompte/detone les
	# entity-skulls AVANT resolve(), pour que la gravite et les matchs eventuels
	# de la chute soient pris en compte dans le meme cycle de resolution — pas
	# apres coup, sinon rien ne se resout tant que le joueur n'a pas rejoue.
	if boss_malus_manager.active_malus == BossMalusManager.Type.MECHE_COURTE:
		grid_manager.tick_entity_countdowns()

	# Special "Pétard à mèche" : decompte/detone AVANT resolve(), meme raison
	# que MÈCHE COURTE ci-dessus — inconditionnel, ce n'est pas un malus de
	# boss mais un outil achete par le joueur.
	var petard_score: int = grid_manager.tick_special_countdowns(_explosive_multipliers())
	if petard_score > 0:
		score_manager.add_score(petard_score)
		petard_scored.emit(petard_score)

	# Speciaux mobiles (Cavalier, Frog, Liane, Crow, Underground) : meme
	# timing, AVANT resolve(), inconditionnel.
	var mobile_score: int = grid_manager.tick_mobile_specials()
	if mobile_score > 0:
		score_manager.add_score(mobile_score)
		mobile_specials_scored.emit(mobile_score)

	# Resolution cascade
	_state = State.RESOLVING
	grid_manager.resolve()


## Place un jeton (logique + animation + effet special) et attend que
## l'animation de chute (et l'effet special, le cas echeant) soit terminee.
## Factorise pour que BOURRASQUE puisse rejouer la meme sequence sur un 2e
## jeton dans la meme colonne (voir play_current_to).
func _drop_token(token: TokenData, col: int) -> void:
	var landing_row: int = grid_manager.place_token(token, col, 0)
	var pre_value: int = token.value
	var pre_kind: TokenData.Kind = token.kind
	token_dropped.emit(token, col, 0)
	var mutated: bool = token.value != pre_value or token.kind != pre_kind

	await drop_animated

	if mutated and landing_row >= 0:
		dropped_token_mutated.emit(col, landing_row)

	# Pour les specials : executer l'effet apres la chute, attendre l'animation
	# d'impact. Retire de l'inventaire AVANT cet appel desormais (voir
	# play_special_from_inventory) -- ce jeton ne vient plus jamais du deck/
	# stream (session 25).
	if token.kind == TokenData.Kind.SPECIAL:
		var special_score: int = grid_manager.execute_special(token, col)
		if special_score > 0:
			score_manager.add_score(special_score)
			comete_scored.emit(special_score)
		await special_effect_done


func notify_drop_complete() -> void:
	drop_animated.emit()


func notify_special_effect_done() -> void:
	special_effect_done.emit()


func request_hold(slot_index: int = -1) -> void:
	if _state != State.AWAITING_INPUT:
		return
	deck_manager.do_hold(slot_index)


## Bouton d'urgence "Shake" (voir GameRules.SHAKE_CHARGES_DEFAULT) : remelange
## current + pioche, le Hold reste intact (voir DeckManager.shake). Ne fait rien si aucune
## charge restante -- l'UI se base sur run_manager.shake_charges_changed pour
## se desactiver, mais on regarde quand meme la charge reelle ici, seule
## source de verite.
func request_shake() -> void:
	if _state != State.AWAITING_INPUT:
		return
	if run_manager.is_shake_locked():
		return
	if run_manager.spend_shake_charge():
		deck_manager.shake()
		shake_used.emit()


func get_state() -> State:
	return _state


## Applique l'effet reel d'une case mystere revelee (voir GridManager.
## mystery_cell_triggered/MysteryCellEffects) — cible/mouches/trous/famille/
## teleport/multi. SCORE_UP/SCORE_DOWN deplacent la cible de %, pas le score
## actuel (retune : un tirage tot en manche, score encore a 0, donnait un
## delta de 0% de rien), voir GameRules.MYSTERY_SCORE_PERCENT.
func _on_mystery_cell_triggered(col: int, row: int, effect: MysteryCellEffects.Type, _token: TokenData) -> void:
	var target_delta: int = 0
	match effect:
		MysteryCellEffects.Type.SCORE_UP:
			target_delta = -int(round(score_manager.get_target() * GameRules.MYSTERY_SCORE_PERCENT))
			score_manager.adjust_target(target_delta)
		MysteryCellEffects.Type.SCORE_DOWN:
			target_delta = int(round(score_manager.get_target() * GameRules.MYSTERY_SCORE_PERCENT))
			score_manager.adjust_target(target_delta)
		MysteryCellEffects.Type.FLIES_UP_SMALL:
			run_manager.add_flies(GameRules.MYSTERY_FLIES_SMALL)
		MysteryCellEffects.Type.FLIES_UP_BIG:
			run_manager.add_flies(GameRules.MYSTERY_FLIES_BIG_GAIN)
		MysteryCellEffects.Type.FLIES_DOWN_SMALL:
			run_manager.spend_flies(mini(GameRules.MYSTERY_FLIES_SMALL, run_manager.get_flies()))
		MysteryCellEffects.Type.FLIES_DOWN_BIG:
			run_manager.spend_flies(mini(GameRules.MYSTERY_FLIES_BIG_LOSS, run_manager.get_flies()))
		MysteryCellEffects.Type.HOLE_ADD:
			grid_manager.add_random_hole()
		MysteryCellEffects.Type.HOLE_REMOVE:
			grid_manager.remove_random_hole()
		MysteryCellEffects.Type.FAMILY_SHUFFLE:
			grid_manager.randomize_token_family(col, row)
		MysteryCellEffects.Type.TELEPORT:
			grid_manager.move_token_to_random_column(col, row)
		MysteryCellEffects.Type.MULTI_X2:
			run_manager.add_grid_modifier(Vector2i(col, row), GameRules.MODIFIER_MYSTERY_X2)
			run_manager.notify_grid_modifiers_ready()
		MysteryCellEffects.Type.MULTI_X5:
			run_manager.add_grid_modifier(Vector2i(col, row), GameRules.MODIFIER_MYSTERY_X5)
			run_manager.notify_grid_modifiers_ready()
		MysteryCellEffects.Type.JACKPOT_FLIES:
			run_manager.add_flies(GameRules.MYSTERY_JACKPOT_FLIES)
		MysteryCellEffects.Type.JACKPOT_MULTI_X10:
			run_manager.add_grid_modifier(Vector2i(col, row), GameRules.MODIFIER_MYSTERY_X10)
			run_manager.notify_grid_modifiers_ready()
	mystery_cell_resolved.emit(col, row, effect, target_delta)


func _on_resolution_complete(timeline: Array[Dictionary], total_score: int) -> void:
	if total_score > 0:
		score_manager.add_score(total_score)

	# Emet un hook par MATCH event pour les sortilèges on_cascade_step, et
	# remonte le score de chaque groupe a sa Partition pour le level up.
	# UPGRADE (ex: Poker Face) : le tirage a deja eu lieu dans CascadeResolver
	# (avant que le visuel n'anime la montee en valeur) — ici on applique juste
	# la mutation reelle sur le pool de boutons.
	for event in timeline:
		if event["type"] == CascadeResolver.EventType.MATCH:
			var groups: Array = event["groups"] as Array
			var scores: Array = event["scores"] as Array
			for i in range(groups.size()):
				var group: Dictionary = groups[i] as Dictionary
				var sheet_name: StringName = group.get("sheet_name", &"") as StringName
				run_manager.add_sheet_score(sheet_name, scores[i] as int)
			cascade_step_resolved.emit(event["cascade_level"] as int, event["total_earned"] as int)
		elif event["type"] == CascadeResolver.EventType.UPGRADE:
			for entry in (event["upgrades"] as Array):
				var data: Dictionary = entry as Dictionary
				var family: TokenData.Family = data["family"] as TokenData.Family
				var value: int = data["value"] as int
				# >= MAX_BUTTON_VALUE : suite des figures (arcanes mineurs),
				# chemin distinct du +1 normal (voir GameRules.next_face_value).
				if value >= GameRules.MAX_BUTTON_VALUE:
					run_manager.promote_matching_button(family, value)
				else:
					run_manager.upgrade_matching_button(family, value)
		elif event["type"] == CascadeResolver.EventType.TRANSFORM:
			# Legendaire "Last Trick" OU special "Hypercube" : le tirage a deja
			# eu lieu dans CascadeResolver — ici on ajoute reellement le jeton
			# au pool possede, definitivement. Last Trick ne porte pas de cle
			# "value" (toujours GameRules.LAST_TRICK_VALUE) ; Hypercube en
			# porte une (family ET value varient, voir CascadeResolver.resolve).
			for entry in (event["transforms"] as Array):
				var data: Dictionary = entry as Dictionary
				var family: TokenData.Family = data["family"] as TokenData.Family
				var value: int = data.get("value", GameRules.LAST_TRICK_VALUE) as int
				run_manager.add_button(family, value)

	# turn_resolved ne sort qu'une fois par tour REEL, jamais a la 1ere passe
	# seule (voir _pre_pass) — sinon les sortilèges on_turn_resolved (Refrain,
	# Vertige, Artificier...) et le compteur de drop d'entity-skull (GameScene.
	# _on_turn_resolved) se declencheraient deux fois pour un seul tour joue.
	# Exception : si la 1ere passe suffit deja a gagner la manche, on emet
	# quand meme tout de suite — sinon le tour gagnant ne dispatcherait jamais
	# ses sortilèges on_turn_resolved (la 2e passe n'a alors jamais lieu). Les
	# deux timelines sont fusionnees pour que rien de la 1ere passe ne soit
	# perdu pour ces consommateurs.
	var full_timeline: Array[Dictionary] = timeline
	if _pre_pass:
		_pre_pass_timeline = timeline
	else:
		full_timeline = _pre_pass_timeline + timeline
		_pre_pass_timeline = []

	if not _pre_pass or score_manager.is_target_reached():
		turn_resolved.emit(full_timeline)

	if score_manager.is_target_reached():
		# Attend toujours la fin de l'animation (banniere de resolution comprise)
		# avant de declarer la victoire — sinon la transition peut demarrer
		# pendant que le decompte du score est encore en train de se derouler.
		await timeline_done_ack
		_state = State.ROUND_OVER
		round_won.emit(score_manager.get_score(), score_manager.get_target())
		return

	if _pre_pass:
		# Deferre (voir _finish_pre_pass) : resolve() est 100% synchrone quand
		# rien ne se passe (cas courant), donc ce point du code s'execute AVANT
		# que play_current_to() n'ait pu atteindre son "await resolution_pass_
		# done" — emettre ici, sans deferrer, ferait partir le signal dans le
		# vide (personne n'ecoute encore) et bloquerait le tour pour toujours
		# (bug trouve en session 23 : plus rien ne se passait apres le 1er drop).
		call_deferred(&"_finish_pre_pass")
		return

	if _state == State.LAST_BREATH:
		# Legendaire "Souffle Obscur" : une deuxieme vague avant de declarer
		# la defaite, une seule fois par manche (voir _second_wave_triggered).
		if run_manager.has_spell(&"souffle_obscur") and not _second_wave_triggered:
			_second_wave_triggered = true
			await timeline_done_ack
			_trigger_second_wave()
			return

		# Sortilège "Dernier dernier Souffle" (Va-tout, session "Vague 2") :
		# mise tout le score final de la manche sur un tirage, une seule fois
		# (voir _vatout_triggered) -- APRES Souffle Obscur, pour parier sur le
		# score reellement definitif. 20% double (peut transformer la defaite
		# en victoire si ca depasse la cible), sinon le score tombe a 0.
		if run_manager.has_spell(&"dernier_dernier_souffle") and not _vatout_triggered:
			_vatout_triggered = true
			var vatout_stake: int = score_manager.get_score()
			var vatout_won: bool = randf() < GameRules.VA_TOUT_WIN_CHANCE
			if vatout_won:
				score_manager.add_score(vatout_stake)
			else:
				score_manager.subtract_score(vatout_stake)
			va_tout_resolved.emit(score_manager.get_score(), vatout_won)
			if score_manager.is_target_reached():
				await timeline_done_ack
				_state = State.ROUND_OVER
				round_won.emit(score_manager.get_score(), score_manager.get_target())
				return

		await timeline_done_ack
		_state = State.ROUND_OVER
		round_lost.emit(score_manager.get_score(), score_manager.get_target())
		return

	# Tour venu de l'inventaire de speciaux (voir play_special_from_inventory) :
	# rien n'a ete tire du deck/stream, donc rien a avancer -- juste revalider
	# qu'un coup reste possible (la grille a change, le stream non) avant de
	# rendre la main.
	if not _current_turn_from_stream:
		_current_turn_from_stream = true
		if not _has_legal_move():
			_trigger_last_breath()
			return
		_state = State.AWAITING_INPUT
		awaiting_input.emit()
		return

	deck_manager.advance_stream()

	if deck_manager.is_exhausted():
		_trigger_last_breath()
		return

	deck_manager.force_hold_to_current()

	# Malus de boss COLONNE MAUDITE : re-tiree avant le check de coup legal
	# pour que celui-ci reflete la colonne que le joueur va reellement affronter.
	_reroll_colonne_maudite()

	# Grille pleine, deck pas vide : aucun coup legal possible (sauf un
	# Fantome en main/hold, qui peut cibler une colonne pleine). Sans lui, le
	# joueur serait bloque indefiniment — meme traitement que le deck vide.
	if not _has_legal_move():
		_trigger_last_breath()
		return

	_state = State.AWAITING_INPUT
	awaiting_input.emit()


## Malus de boss COLONNE MAUDITE (voir BossMalusManager) : re-tire la colonne
## bloquee a chaque retour en attente d'un coup du joueur (round_start et
## apres chaque tour resolu). Relache le verrou si le malus n'est pas actif.
func _reroll_colonne_maudite() -> void:
	if boss_malus_manager.active_malus == BossMalusManager.Type.COLONNE_MAUDITE:
		grid_manager.set_blocked_column(randi() % GameRules.COLS)
	else:
		grid_manager.set_blocked_column(-1)


## Verifie si le jeton courant ou l'un des jetons tenus (voir hold_capacity,
## potentiellement plusieurs slots depuis "Benediction") a au moins une
## colonne jouable. Utilise pour detecter un plateau bloque (voir
## _on_resolution_complete).
func _has_legal_move() -> bool:
	var current: TokenData = deck_manager.get_current()
	var held: Array[TokenData] = deck_manager.get_hold_slots()
	for col in range(GameRules.COLS):
		if current != null and grid_manager.can_play_token(current, col, 0):
			return true
		for hold in held:
			if hold != null and grid_manager.can_play_token(hold, col, 0):
				return true
	return false


## Voir l'appel differe dans _on_resolution_complete — separe pour que
## call_deferred() ait un vrai nom de methode a cibler (emit() seul n'est pas
## directement differable de façon fiable).
func _finish_pre_pass() -> void:
	resolution_pass_done.emit()


func notify_last_breath_ready() -> void:
	last_breath_ready.emit()


func notify_timeline_done() -> void:
	timeline_done_ack.emit()


## Sortilèges Décuple Pétard/Quintuple Bombe/Triple Armageddon (session
## "Vague 1") -- chacun boost le score d'un seul type d'explosif. Construit
## ici (pas dans GridManager, qui reste pure logique de grille sans notion
## de Sortilèges) et passe a tick_special_countdowns/detonate_remaining_
## explosives.
func _explosive_multipliers() -> Dictionary:
	var mults: Dictionary = {}
	if run_manager.has_spell(&"decuple_petard"):
		mults[TokenData.SpecialType.PETARD_A_MECHE] = GameRules.DECUPLE_PETARD_MULT
	if run_manager.has_spell(&"quintuple_bombe"):
		mults[TokenData.SpecialType.BOMBE] = GameRules.QUINTUPLE_BOMBE_MULT
	if run_manager.has_spell(&"triple_armageddon"):
		mults[TokenData.SpecialType.ARMAGEDDON] = GameRules.TRIPLE_ARMAGEDDON_MULT
	return mults


func _trigger_last_breath() -> void:
	_state = State.LAST_BREATH
	_second_wave_triggered = false
	_vatout_triggered = false
	last_breath_started.emit()
	grid_manager.explode_residues()
	grid_manager.clear_remaining_mobile_specials()
	# Toute la famille Petard/Bombe/Armageddon encore active explose aussi
	# (decision verrouillee : "les jetons speciaux poses explosent" au
	# Dernier Souffle), meme si son countdown n'est pas termine.
	var petard_score: int = grid_manager.detonate_remaining_explosives(_explosive_multipliers())
	if petard_score > 0:
		score_manager.add_score(petard_score)
		petard_scored.emit(petard_score)
	await last_breath_ready
	grid_manager.resolve()


## Legendaire "Souffle Obscur" : deuxieme vague apres un Dernier Souffle normal
## qui n'a pas suffi — les entity-skulls (seul obstacle normalement permanent
## du jeu, voir GridManager.clear_entity_skulls) disparaissent a leur tour,
## ouvrant potentiellement une nouvelle gravite/cascade. _state reste
## LAST_BREATH : si cette deuxieme resolution ne suffit toujours pas, _on_
## resolution_complete tombera sur la defaite normale (_second_wave_triggered
## est deja vrai, pas de 3e tentative).
func _trigger_second_wave() -> void:
	second_wave_started.emit()
	grid_manager.clear_entity_skulls()
	await last_breath_ready
	grid_manager.resolve()
