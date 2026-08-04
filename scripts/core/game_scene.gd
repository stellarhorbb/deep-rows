## Scene racine du jeu. Cable les managers et l'UI pour une manche.
## RunManager et ShopManager vivent dans l'autoload RunService (persistent
## entre changements de scene). GameScene lit RunService.current_round au
## demarrage et appelle SceneRouter pour les transitions.
class_name GameScene
extends Node2D

# --- UI locale a cette scene (places dans la scene, references par @onready) ---
@onready var grid_visual: GridVisual = $GridVisual
@onready var grid_hover: GridHoverUI = $GridVisual/GridHover
@onready var stream_ui: StreamUI = $StreamUI
@onready var message_display: MessageDisplay = $MessageDisplay
@onready var input_handler: InputHandler = $InputHandler
@onready var resolution_banner: ResolutionBanner = $ResolutionBanner
@onready var you_win_ui: YouWinUI = $YouWinUI
@onready var score_label: Label = $ScoreLabel
@onready var target_label: Label = $TargetLabel
@onready var zone_label: Label = $ZoneLabel
@onready var background: ColorRect = $Background
@onready var flies_label: Label = $SaltLabel
@onready var roulette_gauge: ProgressBar = $RouletteGauge
@onready var roulette_gauge_label: Label = $RouletteGaugeLabel
@onready var roulette_multi_label: Label = $RouletteMultiLabel
@onready var shake_button: Button = $ShakeButton
@onready var debug_win_button: Button = $DebugWinButton

## Boucle du pulse "heartbeat" de RouletteMultiLabel -- voir _on_multi_status_changed.
var _multi_pulse_tween: Tween = null

## Resultat de la roulette mis en attente le temps que le score de CE drop
## s'affiche -- voir _on_roulette_triggered/_play_roulette_announcement.
## {} = rien en attente.
var _pending_roulette_announcement: Dictionary = {}

# --- UI persistante, portee par le Shell (voir scripts/core/shell.gd) ---
var sheets_ui: SheetsUI
var spells_ui: SpellsUI
var deck_button: Button
var deck_inspector_ui: DeckInspectorUI
var special_inventory_ui: SpecialInventoryUI

# --- Managers locaux a la manche (grid, deck, score, pattern, turn, entity) ---
var turn_controller: TurnController
var grid_manager: GridManager
var deck_manager: DeckManager
var score_manager: ScoreManager
var sheet_manager: SheetManager
var entity_manager: EntityManager

var _displayed_score: int = 0
var _score_tween: Tween = null


func _ready() -> void:
	RunService.ensure_run_started()
	sheets_ui = SceneRouter.shell.sheets_ui
	spells_ui = SceneRouter.shell.spells_ui
	deck_button = SceneRouter.shell.deck_button
	deck_inspector_ui = SceneRouter.shell.deck_inspector_ui
	special_inventory_ui = SceneRouter.shell.special_inventory_ui
	_create_managers()
	_wire_references()
	_wire_signals()
	_start_round()


func _create_managers() -> void:
	grid_manager = GridManager.new()
	grid_manager.name = "GridManager"
	add_child(grid_manager)

	deck_manager = DeckManager.new()
	deck_manager.name = "DeckManager"
	add_child(deck_manager)

	score_manager = ScoreManager.new()
	score_manager.name = "ScoreManager"
	add_child(score_manager)

	sheet_manager = SheetManager.new()
	sheet_manager.name = "SheetManager"
	add_child(sheet_manager)

	turn_controller = TurnController.new()
	turn_controller.name = "TurnController"
	turn_controller.grid_manager = grid_manager
	turn_controller.deck_manager = deck_manager
	turn_controller.score_manager = score_manager
	turn_controller.sheet_manager = sheet_manager
	turn_controller.run_manager = RunService.run_manager
	turn_controller.boss_malus_manager = RunService.boss_malus_manager
	add_child(turn_controller)

	entity_manager = EntityManager.new()
	entity_manager.name = "EntityManager"
	add_child(entity_manager)

	# Branche les sortilèges sur les hooks de la manche.
	RunService.spell_manager.bind_round(turn_controller)
	RunService.roulette_manager.bind_round(turn_controller)
	RunService.roulette_manager.roulette_triggered.connect(_on_roulette_triggered)
	RunService.roulette_manager.gauge_changed.connect(_on_roulette_gauge_changed)
	RunService.roulette_manager.multi_status_changed.connect(_on_multi_status_changed)
	RunService.roulette_manager.token_boosted.connect(_on_token_boosted)


func _wire_references() -> void:
	grid_visual.grid_manager = grid_manager
	grid_visual.spells_ui = spells_ui
	grid_visual.resolution_banner = resolution_banner
	grid_visual.setup()
	grid_hover.grid_manager = grid_manager
	stream_ui.deck_manager = deck_manager
	stream_ui.setup()
	# sheets_ui / spells_ui / special_inventory_ui sont cables au run_manager
	# (global) une seule fois par le Shell — rien a refaire ici a chaque manche.
	input_handler.grid_visual = grid_visual
	input_handler.stream_ui = stream_ui
	input_handler.turn_controller = turn_controller
	input_handler.deck_manager = deck_manager
	input_handler.grid_manager = grid_manager
	input_handler.special_inventory_ui = special_inventory_ui
	entity_manager.grid_manager = grid_manager
	deck_inspector_ui.deck_manager = deck_manager
	deck_button.disabled = false


func _wire_signals() -> void:
	grid_visual.group_score_revealed.connect(_on_group_score_revealed)
	turn_controller.turn_resolved.connect(_on_turn_resolved)
	turn_controller.last_breath_started.connect(_on_last_breath_started)
	turn_controller.second_wave_started.connect(_on_second_wave_started)
	turn_controller.round_won.connect(_on_round_won)
	turn_controller.round_lost.connect(_on_round_lost)
	turn_controller.petard_scored.connect(_on_petard_scored)
	turn_controller.comete_scored.connect(_on_comete_scored)
	turn_controller.va_tout_resolved.connect(_on_va_tout_resolved)
	turn_controller.dropped_token_mutated.connect(_on_dropped_token_mutated)
	turn_controller.mobile_specials_scored.connect(_on_mobile_specials_scored)
	grid_manager.token_placed.connect(_on_token_placed)
	grid_manager.special_landing.connect(_on_special_landing)
	grid_manager.special_executed.connect(_on_special_executed)
	grid_manager.residues_exploded.connect(_on_residues_exploded)
	grid_manager.entity_skulls_cleared.connect(_on_entity_skulls_cleared)
	grid_manager.mobile_specials_ticked.connect(_on_mobile_specials_ticked)
	grid_manager.petard_detonated.connect(_on_petard_detonated)
	grid_manager.holes_changed.connect(grid_visual.set_holes)
	grid_manager.blocked_column_changed.connect(grid_visual.set_blocked_column)
	grid_manager.mystery_cells_changed.connect(grid_visual.set_mystery_cells)
	turn_controller.mystery_cell_resolved.connect(_on_mystery_cell_resolved)
	RunService.run_manager.flies_changed.connect(_on_flies_changed)
	RunService.run_manager.grid_modifiers_changed.connect(grid_visual.set_grid_modifiers)
	RunService.run_manager.shake_charges_changed.connect(_on_shake_charges_changed)
	shake_button.pressed.connect(_on_shake_pressed)
	debug_win_button.pressed.connect(_on_debug_win_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_TAB:
		deck_inspector_ui.toggle()
		get_viewport().set_input_as_handled()


func _start_round() -> void:
	_displayed_score = 0
	entity_manager.reset()
	RunService.game_flow = RunService.GameFlow.PLAYING
	message_display.clear_message()
	# Centrer le pivot du score label pour le scale bump
	score_label.pivot_offset = score_label.size * 0.5
	turn_controller.start_round(RunService.current_round)

	# Fond/label de biome mis a jour AVANT l'animation de chute des jetons
	# persistes (voir plus bas) -- sinon le fond/nom affichent encore l'etat
	# de la manche precedente (ou un defaut editeur) pendant les ~3 secondes
	# de la chute, avant de sauter au bon biome une fois l'await termine (bug
	# remonte en playtest).
	_update_score_display()
	_update_zone_display()

	# Persistance entre manches (session 26) : jetons persistes tombent un a
	# un, gauche a droite, AVANT les cases mystere -- puis finish_round_start
	# genere les cases mystere (qui verront ces cases desormais occupees) et
	# rend la main au joueur.
	var carried_over: Array[TokenData] = await _play_carryover_intro()
	turn_controller.finish_round_start(carried_over)

	# Malus de boss GRANDE FAIM : l'Entity lache un skull 2x plus frequemment
	# pour la manche (voir BossMalusManager, entity_manager vit ici et pas
	# dans TurnController).
	if RunService.boss_malus_manager.active_malus == BossMalusManager.Type.GRANDE_FAIM:
		entity_manager.drop_chance_multiplier = 2.0

	_on_flies_changed(RunService.run_manager.get_flies())
	_on_shake_charges_changed(RunService.run_manager.get_shake_charges())
	_on_roulette_gauge_changed(RunService.roulette_manager.get_gauge(), GameRules.ROULETTE_THRESHOLD)
	grid_visual.refresh()
	stream_ui.queue_redraw()


## Persistance entre manches (session 26) : anime la chute de chaque jeton
## persiste (le plus haut de chaque colonne a la fin de la manche
## precedente), gauche a droite, une colonne a la fois -- avant que les cases
## mystere n'apparaissent (voir TurnController.finish_round_start, appele
## juste apres par _start_round). place_token_direct pose la donnee et
## retourne la row d'atterrissage, animate_drop s'occupe du visuel.
func _play_carryover_intro() -> Array[TokenData]:
	var tokens: Array[TokenData] = RunService.run_manager.pop_carryover_tokens()
	var depth: int = GameRules.CARRYOVER_MAX_DEPTH
	# Premiere manche d'une run (ou tout cas ou rien n'a encore ete stocke) :
	# tokens est vide plutot que dimensionne a COLS*depth, voir RunManager.
	# _carryover_tokens (defaut []).
	if tokens.size() < GameRules.COLS * depth:
		return tokens
	var vestige_active: bool = RunService.run_manager.has_spell(&"vestige")
	for col in range(GameRules.COLS):
		for k in range(depth):
			var token: TokenData = tokens[col * depth + k]
			if token == null:
				continue
			var row: int = grid_manager.place_token_direct(col, token)
			if row >= 0 and vestige_active:
				RunService.run_manager.add_grid_modifier(Vector2i(col, row), GameRules.MODIFIER_BOOST)
			if row >= 0:
				await grid_visual.animate_drop(col, row, token)
				grid_visual.refresh()
	return tokens


func _update_score_display() -> void:
	score_label.text = _format_tickets_label(score_manager.get_score())
	target_label.text = "TICKETS REQUIS : " + NumberFormat.with_spaces(score_manager.get_target())


func _format_tickets_label(value: int) -> String:
	return "TICKETS : " + NumberFormat.with_spaces(value)


func _update_zone_display() -> void:
	@warning_ignore("integer_division")
	var zone: int = (RunService.current_round - 1) / GameRules.ROUNDS_PER_ZONE + 1
	var round_in_zone: int = (RunService.current_round - 1) % GameRules.ROUNDS_PER_ZONE + 1
	var biome_index: int = clampi(zone - 1, 0, GameRules.BIOME_NAMES.size() - 1)
	zone_label.text = GameRules.BIOME_NAMES[biome_index] + "\nMANCHE " + str(round_in_zone) + "/" + str(GameRules.ROUNDS_PER_ZONE)
	# Hover sur le label pour voir ce que fait le malus actif — Label ignore
	# la souris par defaut, il faut l'activer pour que le tooltip declenche.
	zone_label.mouse_filter = Control.MOUSE_FILTER_STOP
	if RunService.boss_malus_manager.active_malus != -1:
		zone_label.text += "\nMALUS : " + RunService.boss_malus_manager.get_active_label()
		zone_label.tooltip_text = RunService.boss_malus_manager.get_active_description()
	else:
		zone_label.tooltip_text = ""
	background.color = GameRules.BIOME_BACKGROUND_COLORS[biome_index]


func _on_flies_changed(amount: int) -> void:
	flies_label.text = "MOUCHES\n" + str(amount)


func _on_shake_charges_changed(amount: int) -> void:
	shake_button.text = "SHAKE (%d)" % amount
	shake_button.disabled = amount <= 0


func _on_shake_pressed() -> void:
	turn_controller.request_shake()


## DEBUG : complete le score jusqu'a la cible de la manche courante, sans
## passer par une resolution de cascade. Ne declare pas la victoire tout de
## suite (ScoreManager.target_reached n'est ecoute nulle part, voir
## TurnController._on_resolution_complete qui poll is_target_reached() apres
## coup) — il suffit de rejouer un coup normal pour voir l'ecran de victoire,
## comme dans une vraie manche. Pour tester le ressenti de fin de run/biome
## sans avoir a scorer "pour de vrai".
func _on_debug_win_pressed() -> void:
	var missing: int = score_manager.get_target() - score_manager.get_score()
	if missing <= 0:
		return
	score_manager.add_score(missing)
	_animate_score_to(_displayed_score + missing)


## La reveal visuelle du score suit la banniere de resolution, pas l'ajout
## logique au ScoreManager (qui arrive plus tot, avant meme l'animation du
## match). Chaque groupe qui termine sa sequence sur la banniere ajoute son
## score au compteur affiche a ce moment precis, pas avant.
func _on_group_score_revealed(amount: int) -> void:
	_animate_score_to(_displayed_score + amount)


func _on_turn_resolved(timeline: Array[Dictionary]) -> void:
	grid_visual.clear_hover()
	if timeline.size() > 0:
		await grid_visual.play_timeline(timeline)
	grid_visual.refresh()

	# Annonce de la roulette (le cas echeant) mise en attente par
	# _on_roulette_triggered -- jouee ICI, apres le score, jamais avant
	# (retour playtest session 25 : la roulette peut se declencher sur le
	# meme drop qui vient de scorer une grosse Partition ; l'annoncer avant
	# donnait l'impression trompeuse qu'elle beneficiait a CE score, alors
	# que le Multi/Boost ne s'applique qu'au(x) prochain(s) drop(s). Ordre
	# fixe et stable, meme si plusieurs systemes se declenchent sur un
	# meme drop : cases mystere (deja resolues avant, synchrone au moment
	# du drop) -> score -> roulette).
	if not _pending_roulette_announcement.is_empty():
		var pending: Dictionary = _pending_roulette_announcement
		_pending_roulette_announcement = {}
		await _play_roulette_announcement(pending["tier"], pending["family"], pending["amount"])

	var meche_courte_active: bool = RunService.boss_malus_manager.active_malus == BossMalusManager.Type.MECHE_COURTE

	# Entity : chance croissante de lacher un skull depuis le dernier drop
	# (session 26, voir EntityManager.on_turn_resolved)
	var entity_col: int = entity_manager.on_turn_resolved()
	if entity_col >= 0:
		var entity_token: TokenData = TokenData.make_entity()
		if meche_courte_active:
			entity_token.countdown = GameRules.MECHE_COURTE_START_COUNTDOWN
		var entity_row: int = grid_manager.place_token_direct(entity_col, entity_token)
		if entity_row >= 0:
			await grid_visual.animate_drop(entity_col, entity_row, entity_token)
			grid_visual.refresh()

	# Ceder au moins une frame pour eviter le race si le controller
	# n'a pas encore arme son await timeline_done_ack (timeline vide).
	await get_tree().process_frame
	turn_controller.notify_timeline_done()


## Aspiration en fin de manche (session 26) : chaque jeton persiste (voir
## GridManager.get_top_base_tokens/get_top_base_token_rows) s'envole vers le
## haut, toutes les colonnes en meme temps -- pas sequentiel comme l'arrivee
## (_play_carryover_intro), on vise un seul geste lisible de ~3 secondes,
## pas un defile colonne par colonne. No-op silencieux si rien ne persiste.
## carried_over suit le layout fixe de GridManager.get_top_base_tokens (voir
## GameRules.CARRYOVER_MAX_DEPTH) -- jusqu'a 2 cases eligibles par colonne
## avec le Sortilège "Deux étages".
func _play_carryover_pickup(carried_over: Array[TokenData]) -> void:
	var depth: int = GameRules.CARRYOVER_MAX_DEPTH
	if carried_over.size() < GameRules.COLS * depth:
		return
	var eligible: Array[Vector2i] = []
	for col in range(GameRules.COLS):
		var rows: Array[int] = grid_manager.get_top_base_token_rows(col)
		for k in range(depth):
			if carried_over[col * depth + k] == null:
				continue
			if rows[k] >= 0:
				eligible.append(Vector2i(col, rows[k]))
	if eligible.is_empty():
		return

	await get_tree().create_timer(GameRules.CARRYOVER_PICKUP_PRE_DELAY).timeout
	for cell in eligible:
		grid_visual.animate_pickup(cell.x, cell.y)
	await get_tree().create_timer(GameRules.CARRYOVER_PICKUP_DURATION).timeout
	await get_tree().create_timer(GameRules.CARRYOVER_PICKUP_POST_DELAY).timeout


func _on_round_won(final_score: int, target: int) -> void:
	# Persistance entre manches (session 26) : snapshot avant que la grille de
	# cette manche ne soit remplacee -- consomme par TurnController.start_round
	# a la manche suivante (voir GridManager.get_top_base_tokens). Le layout
	# est toujours calcule jusqu'a CARRYOVER_MAX_DEPTH ; sans le Sortilège
	# "Deux étages" (session "Vague 1"), on efface les slots secondaires
	# avant stockage -- une seule case par colonne persiste, comme avant.
	var carried_over: Array[TokenData] = grid_manager.get_top_base_tokens()
	if not RunService.run_manager.has_spell(&"deux_etages"):
		var depth: int = GameRules.CARRYOVER_MAX_DEPTH
		for c in range(GameRules.COLS):
			for k in range(1, depth):
				carried_over[c * depth + k] = null
	RunService.run_manager.set_carryover_tokens(carried_over)

	var total_rounds: int = GameRules.ROUNDS_PER_ZONE * GameRules.ZONES_PER_RUN
	if RunService.current_round >= total_rounds:
		RunService.game_flow = RunService.GameFlow.RUN_WON
		RunService.last_score = final_score
		RunService.last_target = target
		RunService.run_manager.record_starter_win()
		await get_tree().create_timer(GameRules.ROUND_END_DELAY).timeout
		SceneRouter.go_to_end_screen()
		return

	# Aspiration visuelle des jetons persistes (session 26), juste avant le
	# message YOU WIN -- montre au joueur ce qui va lui revenir a la manche
	# suivante (voir GridVisual.animate_pickup).
	await _play_carryover_pickup(carried_over)

	# Manche gagnee (hors derniere) : recompense detaillee (base + bonus pack
	# de demarrage + bonus jetons restants + bonus sortilèges on_round_end) puis
	# transition vers le shop apres
	# que le joueur ait clique "ENCAISSER" sur YouWinUI. Le compteur mouches
	# (flies_label) ne doit visuellement bouger qu'a ce clic, pas avant — on
	# suspend l'ecoute de flies_changed pendant que le detail s'affiche pour
	# eviter de spoiler le total, puis on resynchronise l'affichage a la main.
	var base_flies: int = GameRules.FLIES_PER_ROUND_WON
	var starter_pack: StarterPackData = RunService.run_manager.get_starter_pack()
	var starter_bonus: int = RunService.run_manager.get_flies_per_round_bonus()
	var token_bonus: int = GameRules.get_round_end_flies_bonus(deck_manager.get_remaining())

	RunService.run_manager.flies_changed.disconnect(_on_flies_changed)
	RunService.run_manager.add_flies(base_flies + starter_bonus + token_bonus)
	var spell_breakdown: Dictionary = RunService.spell_manager.dispatch_round_end()

	RunService.game_flow = RunService.GameFlow.SHOPPING
	var starter_pack_name: String = starter_pack.pack_name if starter_pack != null else ""
	await you_win_ui.show_reward(base_flies, starter_pack_name, starter_bonus, token_bonus, spell_breakdown)

	RunService.run_manager.flies_changed.connect(_on_flies_changed)
	_on_flies_changed(RunService.run_manager.get_flies())
	SceneRouter.go_to_shop()


func _on_last_breath_started() -> void:
	message_display.show_message("DERNIER SOUFFLE...", &"cascade")


## Legendaire "Souffle Obscur" : deuxieme vague, voir TurnController.
## _trigger_second_wave.
func _on_second_wave_started() -> void:
	message_display.show_message("SOUFFLE OBSCUR...", &"cascade")


func _on_residues_exploded(positions: Array[Vector2i]) -> void:
	# Ceder une frame pour laisser le controller armer son await avant notify
	await get_tree().process_frame
	if positions.size() > 0:
		grid_visual.rebuild_sprites()
		await get_tree().create_timer(0.4).timeout
	turn_controller.notify_last_breath_ready()


## Meme raison que _on_residues_exploded — GridManager.clear_entity_skulls
## vide directement les cases dans _grid, le visuel doit rebuild avant que
## TurnController ne relance la resolution de la deuxieme vague.
func _on_entity_skulls_cleared(positions: Array[Vector2i]) -> void:
	await get_tree().process_frame
	if positions.size() > 0:
		grid_visual.rebuild_sprites()
		await get_tree().create_timer(0.4).timeout
	turn_controller.notify_last_breath_ready()


func _on_round_lost(final_score: int, target: int) -> void:
	RunService.game_flow = RunService.GameFlow.ROUND_LOST
	RunService.last_score = final_score
	RunService.last_target = target
	await get_tree().create_timer(GameRules.ROUND_END_DELAY).timeout
	SceneRouter.go_to_end_screen()


## Jeton basique/rock : anime la chute puis notifie le controller.
func _on_token_placed(col: int, row: int, token: TokenData) -> void:
	await grid_visual.animate_drop(col, row, token)
	turn_controller.notify_drop_complete()


## Special : anime la chute vers la landing row puis notifie le controller.
## L'effet logique n'est pas encore execute a ce stade.
func _on_special_landing(col: int, row: int, token: TokenData) -> void:
	await grid_visual.animate_drop(col, row, token)
	# Supprimer le sprite du special (il ne reste pas sur la grille)
	grid_visual.remove_sprite_at(Vector2i(col, row))
	turn_controller.notify_drop_complete()


## Apres que l'effet special instantane ait ete execute (logique) : rebuild
## les sprites + petite pause. Bombe est sortie de ce chemin en session 25
## (voir GridManager.execute_special) -- elle est maintenant a retardement
## comme Petard/Armageddon, son score passe par _on_petard_scored.
func _on_special_executed(_special_type: TokenData.SpecialType, _col: int, _row: int, _result: Dictionary) -> void:
	# Rebuild les sprites pour montrer l'etat apres l'effet
	grid_visual.rebuild_sprites()
	# Petite pause pour que le joueur voie le resultat de l'impact
	await get_tree().create_timer(0.3).timeout
	turn_controller.notify_special_effect_done()


## Un special mobile (Cavalier, Frog, Liane, Crow, Underground) vient de
## deplacer/reorganiser des jetons silencieusement (voir GridManager.
## tick_mobile_specials) — rebuild complet necessaire, sync_sprites (cree/
## detruit seulement) ne suffit pas a reconcilier une case dont le contenu a
## change sans passer par la creation/suppression. Appele AVANT resolve()
## (le signal est emis de facon synchrone depuis TurnController.
## play_current_to), donc les sprites sont a jour avant que la cascade
## normale ne commence a s'animer.
func _on_mobile_specials_ticked() -> void:
	grid_visual.rebuild_sprites()


## Un explosif de la famille Petard/Bombe/Armageddon (session 25) vide sa
## case (et celles couvertes par sa zone) directement dans _grid sans passer
## par un event de cascade (voir GridManager._detonate_explosive) — meme
## besoin de rebuild complet que _on_mobile_specials_ticked, sinon le sprite
## reste affiche alors qu'il n'existe plus cote logique.
func _on_petard_detonated() -> void:
	grid_visual.rebuild_sprites()


## Un explosif de la famille Petard/Bombe/Armageddon detone en dehors de la
## banniere de resolution (voir GridManager.tick_special_countdowns /
## TurnController.petard_scored) : reveler le score directement ici, sinon le
## compteur affiche n'a jamais de raison de bouger. Message generique (pas de
## nom precis) puisque le signal ne distingue pas quel membre de la famille a
## detone, et que plusieurs peuvent detoner le meme tour.
func _on_petard_scored(amount: int) -> void:
	message_display.show_message("EXPLOSION +" + str(amount) + " TICKETS", &"cascade")
	_animate_score_to(_displayed_score + amount)


## Comete (session "Vague 2") : meme raison que _on_petard_scored ci-dessus,
## message dedie plutot que de reutiliser "EXPLOSION" (ne colle pas au theme).
func _on_comete_scored(amount: int) -> void:
	message_display.show_message("COMÈTE +" + str(amount) + " TICKETS", &"cascade")
	_animate_score_to(_displayed_score + amount)


## Sortilège "Dernier dernier Souffle" (Va-tout, session "Vague 2") : moment
## dedie pour ce tirage all-in, distinct du reste de la banniere de
## resolution -- meme raison que petard_scored/comete_scored (score modifie
## en dehors du pipeline normal).
func _on_va_tout_resolved(final_score: int, won_gamble: bool) -> void:
	if won_gamble:
		message_display.show_message("VA-TOUT ! TICKETS DOUBLÉS", &"cascade")
	else:
		message_display.show_message("VA-TOUT PERDU...", &"cascade")
	_animate_score_to(final_score)


## Sortilège "Pile ou Face" (session "Vague 2") : bug remonte en playtest
## ("trigger jamais", puis "je ne vois jamais le +5") -- deux passes de
## feedback superposees, pas un echec de la logique elle-meme. 1) TurnController.
## dropped_token_mutated ne se declenchait jamais faute de signal dedie
## (spell_triggered de SpellManager ne s'emet que si des mouches ont bouge,
## jamais le cas ici). 2) rebuild_sprites() rafraichissait bien le sprite mais
## sans aucun highlight -- +5 sur un chiffre deja affiche est invisible au
## milieu d'une grille chargee, contrairement au Rock (sprite different, sans
## ambiguite). Reutilise maintenant le meme langage visuel que le Boost de la
## roulette (GridVisual.animate_boost, flash dore) pour le cas +5 valeur --
## le Rock garde un simple replace_sprite, deja suffisant.
func _on_dropped_token_mutated(col: int, row: int) -> void:
	var token: TokenData = grid_manager.get_cell(col, row)
	if token == null:
		return
	var cell: Vector2i = Vector2i(col, row)
	if token.kind == TokenData.Kind.BASE:
		await grid_visual.animate_boost(cell, token)
	else:
		grid_visual.replace_sprite(cell, token)
	spells_ui.tilt_spell(&"pile_ou_face")


## Cavalier/Frog/Liane (mangeurs/scoreurs, session 22) ont mange un jeton en
## se deplacant/grandissant ce tour-ci — meme raison que le Pétard ci-dessus,
## en dehors de la banniere de resolution normale (voir TurnController.
## tick_mobile_specials/mobile_specials_scored). Un seul message meme si
## plusieurs mobiles ont mange dans le meme tour (score deja cumule cote
## logique) — evite le spam de popups.
func _on_mobile_specials_scored(amount: int) -> void:
	message_display.show_message("+" + str(amount) + " TICKETS", &"cascade")
	_animate_score_to(_displayed_score + amount)


## Case mystere revelee (voir TurnController.mystery_cell_resolved) : message
## + refresh du label de cible si target_delta != 0 (SCORE_UP/SCORE_DOWN
## deplacent desormais la cible, pas le score actuel — voir ScoreManager.
## adjust_target). FAMILY_SHUFFLE/TELEPORT ont en plus besoin d'un refresh
## visuel — le jeton a mute ou change de case sans passer par un event de
## CascadeResolver, rien d'autre ne previent le sprite.
func _on_mystery_cell_resolved(col: int, row: int, effect: MysteryCellEffects.Type, target_delta: int) -> void:
	grid_visual.play_mystery_announcement(MysteryCellEffects.LABELS[effect] as String, MysteryCellEffects.DESCRIPTIONS[effect] as String)
	if target_delta != 0:
		_update_score_display()

	match effect:
		MysteryCellEffects.Type.FAMILY_SHUFFLE:
			var token: TokenData = grid_manager.get_cell(col, row)
			if token != null:
				grid_visual.replace_sprite(Vector2i(col, row), token)
		MysteryCellEffects.Type.TELEPORT:
			grid_visual.rebuild_sprites()


## Noms affiches pendant le defile de la roulette (voir _on_roulette_triggered)
## -- purement cosmetique, les deux vraies familles (RouletteRewards.Family)
## sont ce qui atterrit reellement.
const _ROULETTE_FLAVOR_POOL: Array[String] = ["MULTIPLICATEUR", "BOOST"]


## Jauge casino pleine (RouletteManager.roulette_triggered, session 25) --
## tirage deja resolu cote manager (tier/family/amount). Ne joue PAS l'annonce
## tout de suite (le signal arrive tot, avant meme l'animation de chute) --
## mise en attente ici, jouee par _on_turn_resolved APRES le score de ce
## drop (retour playtest : annoncer la roulette avant le score donnait
## l'impression fausse qu'elle beneficiait a ce score-la, alors que le
## Multi/Boost ne s'applique qu'aux prochains drops).
func _on_roulette_triggered(tier: RouletteRewards.Tier, family: RouletteRewards.Family, amount: float) -> void:
	_pending_roulette_announcement = {"tier": tier, "family": family, "amount": amount}


## Affiche reellement l'annonce de la roulette -- voir _on_roulette_triggered
## pour pourquoi c'est separe et appele en differe par _on_turn_resolved. Ne
## pas reutiliser le label "ROULETTE" : deja pris par play_roll_announcement
## (roll du Diamond Rock). Attend la fin de l'annonce avant de prevenir
## RouletteManager (notify_banner_done) -- sinon le popup et le highlight
## d'un Boost gagne se chevauchent visuellement.
func _play_roulette_announcement(tier: RouletteRewards.Tier, family: RouletteRewards.Family, amount: float) -> void:
	var landed_label: String
	var landed_description: String = RouletteRewards.tier_label(tier)
	match family:
		RouletteRewards.Family.MULTI:
			landed_label = "MULTIPLICATEUR x%s" % String.num(amount, 1)
		RouletteRewards.Family.BOOST:
			landed_label = "BOOST +%d !" % int(amount)
		_:
			landed_label = ""
	await grid_visual.play_prize_spin_announcement(_ROULETTE_FLAVOR_POOL, landed_label, landed_description)
	RunService.roulette_manager.notify_banner_done()


## Boost de la roulette applique (RouletteManager.token_boosted, session 25) --
## joue le highlight sur la case concernee (GridVisual.animate_boost).
func _on_token_boosted(cell: Vector2i, token: TokenData) -> void:
	await grid_visual.animate_boost(cell, token)


func _on_roulette_gauge_changed(current: int, threshold: int) -> void:
	roulette_gauge.max_value = threshold
	roulette_gauge.value = current
	roulette_gauge_label.text = "%d/%d" % [current, threshold]


## Multiplicateur roulette pret pour le prochain drop (RouletteManager.
## multi_status_changed, session 25) -- pulse en boucle façon heartbeat tant
## qu'actif, disparait des que le drop attendu s'est resolu (score ou non,
## voir RouletteManager._on_turn_resolved) : le joueur voit disparaitre le
## bonus meme s'il n'a servi a rien, pas de fausse promesse silencieuse.
func _on_multi_status_changed(active: bool, value: float) -> void:
	if _multi_pulse_tween != null:
		_multi_pulse_tween.kill()
		_multi_pulse_tween = null
	if not active:
		roulette_multi_label.visible = false
		return
	roulette_multi_label.visible = true
	roulette_multi_label.text = "MULTI x%s" % String.num(value, 1)
	roulette_multi_label.scale = Vector2.ONE
	_multi_pulse_tween = create_tween().set_loops()
	_multi_pulse_tween.tween_property(roulette_multi_label, "scale", Vector2(1.15, 1.15), 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_multi_pulse_tween.tween_property(roulette_multi_label, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _animate_score_to(target: int) -> void:
	var from: int = _displayed_score
	_displayed_score = target

	if _score_tween != null and _score_tween.is_valid():
		_score_tween.kill()

	_score_tween = create_tween()
	_score_tween.tween_method(func(val: float) -> void:
		# Garde-fou (session 25) : la scene peut se faire liberer (changement
		# d'ecran) avant que ce step de tween ne soit joue, notamment en
		# enchainant les manches vite via DEBUG: +CIBLE — sans ce check,
		# score_label deja libere declenche "Lambda capture was freed".
		if is_instance_valid(score_label):
			score_label.text = _format_tickets_label(int(val))
	, float(from), float(target), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Scale bump
	_score_tween.tween_property(score_label, "scale", Vector2(1.12, 1.12), 0.08).set_ease(Tween.EASE_OUT)
	_score_tween.tween_property(score_label, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_IN_OUT)
