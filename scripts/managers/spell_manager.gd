## Dispatch les triggers de sortilèges vers les effets des sortilèges equipes.
## Vit dans RunService (persistant entre manches). Se branche sur les signaux
## de TurnController a chaque manche via bind_round().
class_name SpellManager
extends Node

## Emis a chaque sortilège qui ajoute des mouches lors d'un dispatch (n'importe
## quel trigger) — permet a l'UI de tilter son slot au moment ou il agit
## reellement, meme pour les Sortilèges qui ne passent jamais par la banniere de
## resolution (Vertige, Pourboire, Un Pour Tous, Mouches en Cascade...).
signal spell_triggered(spell_id: StringName)

var run_manager: RunManager
var _deck_manager: DeckManager
var _grid_manager: GridManager
var _last_button_pool_size: int = -1


## Connecte tous les hooks de la manche en cours. Les signaux seront
## automatiquement nettoyes quand le turn_controller sera free (fin de scene).
func bind_round(turn_controller: TurnController) -> void:
	_deck_manager = turn_controller.deck_manager
	_grid_manager = turn_controller.grid_manager
	turn_controller.round_started.connect(_on_round_started)
	turn_controller.token_dropped.connect(_on_token_dropped)
	turn_controller.cascade_step_resolved.connect(_on_cascade_step)
	turn_controller.turn_resolved.connect(_on_turn_resolved)
	turn_controller.last_breath_started.connect(_on_last_breath)
	turn_controller.shake_used.connect(_on_shake_used)
	turn_controller.special_ate.connect(_on_special_ate)

	# sheet_leveled_up/button_pool_changed/sheet_sold/figure_promoted vivent sur
	# RunManager (persistant toute la run), pas sur TurnController (recree
	# chaque manche) — se connecter ici quand meme (garde is_connected) pour
	# rester au meme endroit que le reste du cablage, sans dupliquer la
	# connexion a chaque nouvelle manche.
	if not run_manager.sheet_leveled_up.is_connected(_on_sheet_leveled_up):
		run_manager.sheet_leveled_up.connect(_on_sheet_leveled_up)
	if not run_manager.button_pool_changed.is_connected(_on_button_pool_changed):
		run_manager.button_pool_changed.connect(_on_button_pool_changed)
	if not run_manager.sheet_sold.is_connected(_on_sheet_sold):
		run_manager.sheet_sold.connect(_on_sheet_sold)
	if not run_manager.figure_promoted.is_connected(_on_figure_promoted):
		run_manager.figure_promoted.connect(_on_figure_promoted)
	_last_button_pool_size = run_manager.get_button_pool().size()


func _on_round_started() -> void:
	# Trous deja generes a ce stade (TurnController.start_round, etape 0 avant
	# l'emission de round_started) — les sortilèges a cellule unique (Cellule
	# Double/Triple) s'en servent pour ne jamais cibler une case inaccessible.
	var holes: Dictionary = _grid_manager.get_holes() if _grid_manager != null else {}
	_dispatch(&"on_round_start", {"holes": holes})


func _on_token_dropped(token: TokenData, col: int, row: int) -> void:
	var deck_remaining: int = _deck_manager.get_remaining() if _deck_manager != null else 0
	_dispatch(&"on_token_drop", {"token": token, "col": col, "row": row, "deck_remaining": deck_remaining})


func _on_cascade_step(level: int, earned: int) -> void:
	_dispatch(&"on_cascade_step", {"cascade_level": level, "earned": earned})


func _on_turn_resolved(timeline: Array[Dictionary]) -> void:
	# grid_manager expose ici pour les Sortilèges qui doivent muter la grille APRES
	# la resolution (ex: "Récif vivant" transforme un jeton en rock) — les
	# autres sortilèges qui ne lisent que "timeline" ignorent cette cle sans effet.
	_dispatch(&"on_turn_resolved", {"timeline": timeline, "grid_manager": _grid_manager})


func _on_last_breath() -> void:
	_dispatch(&"on_last_breath", {})


func _on_shake_used() -> void:
	_dispatch(&"on_shake_used", {})


## Un special "mangeur" (Cavalier/Frog/Liane/Siphon) vient de manger `count`
## jeton(s) ce tour-ci (voir TurnController.special_ate) — ex: "Gourmand".
func _on_special_ate(count: int) -> void:
	_dispatch(&"on_special_ate", {"count": count})


func _on_sheet_sold(sheet_name: StringName) -> void:
	_dispatch(&"on_sheet_sold", {"sheet_name": sheet_name})


func _on_figure_promoted(new_value: int) -> void:
	_dispatch(&"on_figure_promoted", {"new_value": new_value})


## Level up d'une Partition (score cumule qui franchit un palier) — declenche
## en cours de manche, pas seulement au round_start (ex: "Mouche mélomane",
## "Escalade musicale", "Amélioration continue").
func _on_sheet_leveled_up(sheet_name: StringName, new_level: int) -> void:
	_dispatch(&"on_level_up", {"sheet_name": sheet_name, "new_level": new_level})


## Le pool de boutons vient de changer (achat, scission, fusion, vente...).
## Ne dispatch que si le pool a GRANDI (achat/scission) — une fusion ou une
## vente le fait rétrécir, "Gourmand" ne doit compter que les ajouts.
func _on_button_pool_changed() -> void:
	var size: int = run_manager.get_button_pool().size()
	var delta: int = size - _last_button_pool_size
	_last_button_pool_size = size
	if delta > 0:
		_dispatch(&"on_deck_grown", {"count": delta})


## Declenche les sortilèges on_round_end (ex : Pourboire) et retourne le detail
## des mouches ajoutees par sortilège, pour l'ecran de fin de manche (voir
## GameScene._on_round_won / YouWinUI). grid_manager expose ici (comme pour
## on_turn_resolved) pour les sortilèges qui lisent l'etat de la grille en fin de
## manche (ex: "Cairn" compte les Rocks encore en place).
func dispatch_round_end() -> Dictionary:
	return _dispatch(&"on_round_end", {"grid_manager": _grid_manager})


## Declenche les sortilèges on_deck_tool_shown (ex: "Petit Point") — a appeler par
## ShopUI quand un slot "Des a coudre" vient d'apparaitre dans l'offre (voir
## ShopManager.has_deck_tool_offer), au plus une fois par visite (pas a
## chaque reroll, voir ShopUI._ready).
func dispatch_deck_tool_shown() -> void:
	_dispatch(&"on_deck_tool_shown", {})


## Retourne {label_spell: mouches_ajoutees} pour les sortilèges qui ont augmente
## les mouches pendant ce dispatch (diff avant/apres chaque effet) — les
## appelants qui n'en ont pas besoin (tous les autres triggers) ignorent
## simplement la valeur de retour.
func _dispatch(trigger: StringName, event: Dictionary) -> Dictionary:
	var flies_breakdown: Dictionary = {}
	if run_manager == null:
		return flies_breakdown
	for spell in run_manager.get_equipped_spells():
		if spell.trigger != trigger:
			continue
		var effect: SpellEffect = spell.make_effect()
		if effect == null:
			continue
		var flies_before: int = run_manager.get_flies()
		effect.apply(event, run_manager)
		var flies_delta: int = run_manager.get_flies() - flies_before
		if flies_delta > 0:
			flies_breakdown[spell.label] = (flies_breakdown.get(spell.label, 0) as int) + flies_delta
			spell_triggered.emit(spell.id)
	return flies_breakdown
