## Jauge casino (session 25, axe casino) : accumule la valeur brute des jetons
## poses sur toute la run, declenche la roulette quand le seuil est atteint --
## tirage a deux temps (voir RouletteRewards) : palier, puis 50/50
## Multiplicateur/Frog. Vit dans RunService (persistant entre manches), se
## branche sur TurnController a chaque manche via bind_round() -- meme
## pattern que BadgeManager. Voir docs/gdd/manche/roulette-casino.md pour le
## design complet (et l'historique : Planter/cases mystere ont ete retires de
## la roulette pour garder les deux systemes casino totalement independants).
class_name RouletteManager
extends Node

## Emis quand la jauge atteint GameRules.ROULETTE_THRESHOLD, avec le resultat
## deja resolu (palier, famille, ampleur reelle -- le meme nombre que celui
## reellement applique, jamais un re-tirage cote UI) -- l'UI (spin + banniere)
## s'y abonne pour l'annonce.
signal roulette_triggered(tier: RouletteRewards.Tier, family: RouletteRewards.Family, amount: float)

## Emis a chaque changement de jauge (remplissage ou reset apres declenchement)
## -- l'UI (barre de progression) s'y abonne pour rester synchronisee sans
## avoir a lire l'etat interne du manager.
signal gauge_changed(current: int, threshold: int)

## Emis quand le multiplicateur roulette s'active (pret pour le PROCHAIN
## drop) ou s'efface (le drop attendu vient de se resoudre, qu'il ait scoré
## ou non) -- l'UI (indicateur pulsant) s'y abonne pour savoir quand
## l'afficher/le cacher, sans avoir a interroger l'etat interne du manager.
signal multi_status_changed(active: bool, value: float)

var run_manager: RunManager

var _gauge: int = 0
var _grid_manager: GridManager
var _turn_controller: TurnController

## Multiplicateur tire ce tour-ci mais applique seulement au tour SUIVANT
## (voir _on_turn_resolved) -- le tour qui declenche la roulette garde sa
## resolution normale, pas de bonus retroactif sur le meme drop. -1.0 =
## rien en attente.
var _pending_multi: float = -1.0

## true tant qu'un multiplicateur roulette est actif sur RunManager -- efface
## a la fin du tour qui vient d'en beneficier.
var _multi_active: bool = false

## Nombre de Frogs a lacher, mis en attente jusqu'a ce que DEUX conditions
## soient reunies (voir _maybe_drop_frogs) : le tour en cours doit etre
## reellement termine (_turn_ready, voir _on_awaiting_input -- JAMAIS muter
## la grille pendant qu'un tour est encore en train de s'animer/se resoudre,
## bug session 25) ET l'annonce visuelle de la roulette doit avoir fini de
## jouer (_banner_ready, voir notify_banner_done -- sinon le spin et la
## chute du Frog se chevauchent). 0 = rien en attente.
var _pending_frogs: int = 0
var _turn_ready: bool = false
var _banner_ready: bool = false


## Reset au demarrage d'un run (RunService.start_new_run), jamais au
## round_start -- le seuil est fixe pour toute la run, voir decisions-tranchees.
func reset_run() -> void:
	_gauge = 0
	_pending_multi = -1.0
	if _multi_active:
		_multi_active = false
		multi_status_changed.emit(false, 1.0)
	if run_manager != null:
		run_manager.set_global_multiplier(1.0, &"roulette")
	gauge_changed.emit(_gauge, GameRules.ROULETTE_THRESHOLD)


func bind_round(turn_controller: TurnController) -> void:
	_grid_manager = turn_controller.grid_manager
	_turn_controller = turn_controller
	# Securite anti-fuite entre manches : si une roulette s'est declenchee au
	# tout dernier coup d'une manche, ni le multiplicateur ni les Frogs en
	# attente n'ont de raison de survivre au changement de manche.
	_pending_multi = -1.0
	_pending_frogs = 0
	_turn_ready = false
	_banner_ready = false
	if _multi_active:
		_multi_active = false
		multi_status_changed.emit(false, 1.0)
	if run_manager != null:
		run_manager.set_global_multiplier(1.0, &"roulette")
	turn_controller.token_dropped.connect(_on_token_dropped)
	turn_controller.turn_resolved.connect(_on_turn_resolved)
	turn_controller.awaiting_input.connect(_on_awaiting_input)


func _on_token_dropped(token: TokenData, _col: int, _row: int) -> void:
	_gauge += _gauge_value(token)
	if _gauge >= GameRules.ROULETTE_THRESHOLD:
		_gauge -= GameRules.ROULETTE_THRESHOLD
		gauge_changed.emit(_gauge, GameRules.ROULETTE_THRESHOLD)
		_trigger_roulette()
	else:
		gauge_changed.emit(_gauge, GameRules.ROULETTE_THRESHOLD)


## Valeur brute du jeton, sans plafond -- deliberement lisible (voir
## docs/gdd/manche/roulette-casino.md) : la valeur affichee sur le jeton EST
## la justification du remplissage, pas un tirage independant.
func _gauge_value(token: TokenData) -> int:
	match token.kind:
		TokenData.Kind.SPECIAL:
			return GameRules.ROULETTE_SPECIAL_GAUGE_VALUE
		TokenData.Kind.BASE:
			return token.value
		_:
			return 0


## Ne mute JAMAIS la grille ici -- ce handler tourne en plein milieu du tour
## en cours (juste apres le drop du joueur, avant que son animation/
## resolution ne soit terminee). Tout effet qui touche la grille (Frogs) est
## simplement mis en attente ; seul le multiplicateur (qui ne touche que
## RunManager, jamais GridManager/GridVisual) peut sans risque attendre la
## meme mise en attente sans besoin d'etre retarde plus que ca.
func _trigger_roulette() -> void:
	var tier: RouletteRewards.Tier = RouletteRewards.roll_tier()
	var family: RouletteRewards.Family = RouletteRewards.roll_family()
	var amount: float = 0.0
	match family:
		RouletteRewards.Family.MULTI:
			amount = RouletteRewards.multi_value(tier)
			_pending_multi = amount
		RouletteRewards.Family.FROG:
			var count: int = RouletteRewards.frog_count(tier)
			amount = float(count)
			_pending_frogs += count
			# Repart a zero sur les deux conditions -- sinon un _turn_ready
			# laisse a true par un tour precedent sans Frog en attente
			# ferait lacher celui-ci des que le popup finit, sans attendre
			# que CE tour (celui qui vient de declencher) soit vraiment
			# termine -- meme risque de collision qu'avant.
			_turn_ready = false
			_banner_ready = false
	roulette_triggered.emit(tier, family, amount)


## Active/efface le multiplicateur -- ne touche jamais a la grille/l'UI donc
## pas de risque a le faire ici, des la fin de la resolution du tour (avant
## meme que TurnController ne soit revenu a AWAITING_INPUT). Efface celui qui
## vient de servir sur CE tour (actif depuis le tour precedent) et active
## celui tout juste gagne (pret pour le PROCHAIN drop).
func _on_turn_resolved(_timeline: Array[Dictionary]) -> void:
	if _multi_active:
		run_manager.set_global_multiplier(1.0, &"roulette")
		_multi_active = false
		multi_status_changed.emit(false, 1.0)
	if _pending_multi > 0.0:
		run_manager.set_global_multiplier(_pending_multi, &"roulette")
		_multi_active = true
		multi_status_changed.emit(true, _pending_multi)
		_pending_multi = -1.0


func _on_awaiting_input() -> void:
	_turn_ready = true
	_maybe_drop_frogs()


## Appele par l'UI (GameScene) une fois l'annonce de la roulette
## (ResolutionBanner.play_prize_spin_announcement) terminee -- evite que le
## popup et la chute du Frog ne se chevauchent visuellement.
func notify_banner_done() -> void:
	_banner_ready = true
	_maybe_drop_frogs()


## Lache les Frogs en attente des que les DEUX conditions sont reunies (voir
## _pending_frogs) -- peu importe laquelle arrive en dernier (le tour ou le
## popup), les deux flags sont reset a chaque declenchement suivant.
func _maybe_drop_frogs() -> void:
	if _pending_frogs <= 0 or not _turn_ready or not _banner_ready:
		return
	var count: int = _pending_frogs
	_pending_frogs = 0
	_turn_ready = false
	_banner_ready = false
	_drop_frogs(count)


## Lache `count` Frogs (cadeau des grenouilles orchestre) en colonnes
## aleatoires, en sautant les colonnes deja pleines. Chaque Frog attend son
## propre pipeline anime complet (TurnController.drop_bonus_token) avant de
## lacher le suivant -- appeler execute_special avant que l'animation de
## chute soit terminee desynchronise le sprite (bug session 25 : le Frog
## etait pose en donnees instantanement mais n'apparaissait visuellement
## qu'au prochain drop du joueur).
func _drop_frogs(count: int) -> void:
	if _grid_manager == null or _turn_controller == null:
		return
	for i in range(count):
		var frog: TokenData = TokenData.make_special(TokenData.SpecialType.FROG)
		var columns: Array[int] = []
		for col in range(GameRules.COLS):
			columns.append(col)
		columns.shuffle()
		for col in columns:
			if _grid_manager.can_play_token(frog, col, 0):
				await _turn_controller.drop_bonus_token(frog, col)
				break


func get_gauge() -> int:
	return _gauge
