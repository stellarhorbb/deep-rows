## Jauge casino (session 25, axe casino) : accumule la valeur brute des jetons
## poses sur toute la run, declenche la roulette quand le seuil est atteint --
## tirage a deux temps (voir RouletteRewards) : palier, puis 50/50
## Multiplicateur/Boost. Vit dans RunService (persistant entre manches), se
## branche sur TurnController a chaque manche via bind_round() -- meme
## pattern que SpellManager. Voir docs/gdd/manche/roulette-casino.md pour le
## design complet (et l'historique : Planter/cases mystere ont ete retires de
## la roulette pour garder les deux systemes casino totalement independants ;
## Frog a ete remplace par Boost, trop souvent destructeur des Partitions en
## cours de construction).
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

## Emis une fois qu'un jeton a reellement ete boosté sur la grille (voir
## _apply_boost) -- l'UI (GameScene) s'y abonne pour jouer le highlight
## (GridVisual.animate_boost). RouletteManager ne touche jamais GridVisual
## directement (separation logique/visuel).
signal token_boosted(cell: Vector2i, token: TokenData)

var run_manager: RunManager

var _gauge: int = 0
var _grid_manager: GridManager
var _turn_controller: TurnController

## Multiplicateur tire ce tour-ci mais applique seulement au tour SUIVANT
## (voir _on_turn_resolved) -- le tour qui declenche la roulette garde sa
## resolution normale, pas de bonus retroactif sur le meme drop. -1.0 =
## rien en attente.
var _pending_multi: float = -1.0

## Nombre de drops restants a couvrir par le multiplicateur actif sur
## RunManager (voir GameRules.ROULETTE_MULTI_DROPS) -- decremente d'1 a
## chaque tour resolu, efface quand ça atteint 0. 0 = aucun multiplicateur actif.
var _multi_drops_remaining: int = 0

## Ampleur du Boost a appliquer, mis en attente jusqu'a ce que DEUX conditions
## soient reunies (voir _maybe_apply_boost) : le tour en cours doit etre
## reellement termine (_turn_ready, voir _on_awaiting_input) ET l'annonce
## visuelle de la roulette doit avoir fini de jouer (_banner_ready, voir
## notify_banner_done -- sinon le spin et le highlight du Boost se
## chevauchent). Pas de risque de collision d'animation comme Frog avant lui
## (Boost ne mute que la valeur d'un jeton deja en place, jamais de nouveau
## sprite anime), mais le meme delai garde le highlight lisible plutot que
## noye dans l'animation du tour en cours. 0 = rien en attente.
var _pending_boost_amount: int = 0
var _turn_ready: bool = false
var _banner_ready: bool = false


## Reset au demarrage d'un run (RunService.start_new_run) -- la jauge se
## remet AUSSI a zero a chaque manche (voir bind_round, retune session 25),
## donc ce reset_run ne fait plus qu'une redondance defensive au tout premier
## round de la run, avant que bind_round n'ait jamais tourne.
func reset_run() -> void:
	_gauge = 0
	_pending_multi = -1.0
	if _multi_drops_remaining > 0:
		_multi_drops_remaining = 0
		multi_status_changed.emit(false, 1.0)
	if run_manager != null:
		run_manager.set_global_multiplier(1.0, &"roulette")
	gauge_changed.emit(_gauge, GameRules.ROULETTE_THRESHOLD)


func bind_round(turn_controller: TurnController) -> void:
	_grid_manager = turn_controller.grid_manager
	_turn_controller = turn_controller
	# Retune equilibrage (session 25) : la jauge repart aussi a zero a chaque
	# manche, plus seulement au demarrage d'une run -- revient sur la decision
	# initiale ("seuil fixe pour toute la run", voir decisions-tranchees.md),
	# a retoucher dans le GDD si ca se confirme au playtest prolonge.
	_gauge = 0
	gauge_changed.emit(_gauge, GameRules.ROULETTE_THRESHOLD)
	# Securite anti-fuite entre manches : si une roulette s'est declenchee au
	# tout dernier coup d'une manche, ni le multiplicateur ni le Boost en
	# attente n'ont de raison de survivre au changement de manche.
	_pending_multi = -1.0
	_pending_boost_amount = 0
	_turn_ready = false
	_banner_ready = false
	if _multi_drops_remaining > 0:
		_multi_drops_remaining = 0
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
## la justification du remplissage, pas un tirage independant. Les speciaux
## ne contribuent plus rien (retune session 25) : depuis qu'ils vivent dans
## l'inventaire possede et se jouent a la demande SANS consommer de tour de
## stream (voir TurnController.play_special_from_inventory), leur laisser un
## forfait fixe aurait permis de remplir la jauge gratuitement en spammant un
## outil "sans valeur" -- l'ancien forfait datait du systeme ou ils etaient
## piochés dans le stream comme n'importe quel jeton.
func _gauge_value(token: TokenData) -> int:
	match token.kind:
		TokenData.Kind.BASE:
			return token.value
		_:
			return 0


## Ne mute JAMAIS la grille ici -- ce handler tourne en plein milieu du tour
## en cours (juste apres le drop du joueur, avant que son animation/
## resolution ne soit terminee). Le Boost est simplement mis en attente ;
## seul le multiplicateur (qui ne touche que RunManager, jamais GridManager/
## GridVisual) peut sans risque attendre la meme mise en attente sans besoin
## d'etre retarde plus que ca.
func _trigger_roulette() -> void:
	var tier: RouletteRewards.Tier = RouletteRewards.roll_tier()
	var family: RouletteRewards.Family = RouletteRewards.roll_family()
	var amount: float = 0.0
	match family:
		RouletteRewards.Family.MULTI:
			amount = RouletteRewards.multi_value(tier)
			_pending_multi = amount
		RouletteRewards.Family.BOOST:
			var boost: int = RouletteRewards.boost_amount(tier)
			amount = float(boost)
			_pending_boost_amount = boost
			# Repart a zero sur les deux conditions -- sinon un _turn_ready
			# laisse a true par un tour precedent sans Boost en attente
			# ferait appliquer celui-ci des que le popup finit, sans attendre
			# que CE tour (celui qui vient de declencher) soit vraiment
			# termine.
			_turn_ready = false
			_banner_ready = false
	roulette_triggered.emit(tier, family, amount)


## Decompte/efface le multiplicateur et active celui tout juste gagne -- ne
## touche jamais a la grille/l'UI donc pas de risque a le faire ici, des la
## fin de la resolution du tour (avant meme que TurnController ne soit
## revenu a AWAITING_INPUT). GameRules.ROULETTE_MULTI_DROPS est un DELAI
## MAXIMUM pour s'en servir (retune session 25 : 1 seul drop etait "trop
## chaud a caler" au playtest), pas une duree garantie -- des qu'un tour
## scoré profite du multiplicateur, il s'efface tout de suite (pas de
## deuxieme/troisieme coup gratuit en plus), sinon decompte d'1 a chaque
## tour resolu jusqu'a expiration.
func _on_turn_resolved(_timeline: Array[Dictionary]) -> void:
	if _multi_drops_remaining > 0:
		if _turn_scored(_timeline):
			_multi_drops_remaining = 0
			run_manager.set_global_multiplier(1.0, &"roulette")
			multi_status_changed.emit(false, 1.0)
		else:
			_multi_drops_remaining -= 1
			if _multi_drops_remaining <= 0:
				run_manager.set_global_multiplier(1.0, &"roulette")
				multi_status_changed.emit(false, 1.0)
	if _pending_multi > 0.0:
		run_manager.set_global_multiplier(_pending_multi, &"roulette")
		_multi_drops_remaining = GameRules.ROULETTE_MULTI_DROPS
		multi_status_changed.emit(true, _pending_multi)
		_pending_multi = -1.0


## true si ce tour a score au moins une figure (peu importe la Partition) --
## sert uniquement a savoir si le multiplicateur roulette actif vient d'etre
## consomme, voir _on_turn_resolved.
func _turn_scored(timeline: Array[Dictionary]) -> bool:
	for event in timeline:
		if event.get("type") != CascadeResolver.EventType.MATCH:
			continue
		var scores: Array = event.get("scores", []) as Array
		for group_score in scores:
			if (group_score as int) > 0:
				return true
	return false


func _on_awaiting_input() -> void:
	_turn_ready = true
	_maybe_apply_boost()


## Appele par l'UI (GameScene) une fois l'annonce de la roulette
## (ResolutionBanner.play_prize_spin_announcement) terminee -- evite que le
## popup et le highlight du Boost ne se chevauchent visuellement.
func notify_banner_done() -> void:
	_banner_ready = true
	_maybe_apply_boost()


## Applique le Boost en attente des que les DEUX conditions sont reunies
## (voir _pending_boost_amount) -- peu importe laquelle arrive en dernier (le
## tour ou le popup), les deux flags sont reset a chaque declenchement suivant.
func _maybe_apply_boost() -> void:
	if _pending_boost_amount <= 0 or not _turn_ready or not _banner_ready:
		return
	var amount: int = _pending_boost_amount
	_pending_boost_amount = 0
	_turn_ready = false
	_banner_ready = false
	_apply_boost(amount)


## Applique le Boost sur deux plans independants : le pool possede (voir
## RunManager.boost_random_button -- l'effet REEL, acquis pour le reste de la
## run) et un jeton de base pris au hasard sur la grille (voir
## GridManager.boost_random_token -- purement visuel/immediat, sert juste a
## donner un highlight concret sur ce tour, plus un petit bonus de score pour
## la manche en cours). Les deux tirages sont independants (pas de lien
## garanti entre "quel jeton flashe" et "quel jeton du pool progresse") --
## faire correspondre les deux exigerait de tracer l'origine de chaque copie
## de grille jusqu'au pool, complexite non justifiee vu que plusieurs
## exemplaires du meme family/valeur existent generalement. Ne fait rien cote
## grille si aucun jeton de base n'y est present (grille encore vide, edge
## case rarissime).
func _apply_boost(amount: int) -> void:
	if run_manager != null:
		run_manager.boost_random_button(amount)
	if _grid_manager == null:
		return
	var cell: Vector2i = _grid_manager.boost_random_token(amount)
	if cell.x < 0:
		return
	var token: TokenData = _grid_manager.get_cell(cell.x, cell.y)
	if token != null:
		token_boosted.emit(cell, token)


func get_gauge() -> int:
	return _gauge
