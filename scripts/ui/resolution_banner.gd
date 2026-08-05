## Banniere centrale de decomposition du score, un groupe resolu a la fois :
## nom de la Partition -> valeur brute -> Sortilèges "points" un par un (ordre des
## slots) -> multi intrinseque -> Sortilèges "multi" un par un (ordre des slots)
## -> resultat final en plus gros (session 17 : les Sortilèges points collent aux
## jetons bruts, avant tout multi, plutot que d'etre melanges avec les Sortilèges
## multi dans un seul passage). Remplace les anciens popups "+X" et labels de
## pattern par groupe (GridVisual._animate_match), qui etaient trop
## discrets/rapides pour suivre le calcul. Zero style pour l'instant —
## priorite a la lisibilite de la sequence.
class_name ResolutionBanner
extends Label

@export var step_duration: float = 1.0
@export var result_pause_duration: float = 1.0
@export var result_font_size_boost: int = 20
@export var value_color: Color = Color("e2b714")
@export var mult_color: Color = Color("4ecdc4")
@export var spell_color: Color = Color("ff6b6b")
@export var result_color: Color = Color("f0e6c8")

@export var cascade_color: Color = Color("ff3d3d")
@export var cascade_font_size_boost: int = 28
@export var cascade_duration: float = 0.6

@export var combo_color: Color = Color("ffb400")
@export var combo_font_size_boost: int = 28
@export var combo_duration: float = 0.6

@export var mystery_color: Color = Color("b968f0")
@export var mystery_font_size_boost: int = 24
@export var mystery_duration: float = 0.9

@export var roll_color: Color = Color("2ecc71")
@export var roll_font_size_boost: int = 24
@export var roll_spin_count: int = 10
@export var roll_spin_start_interval: float = 0.05
@export var roll_spin_end_interval: float = 0.25
@export var roll_result_duration: float = 0.7

## Toutes les annonces (breakdown/cascade/combo/roll/mystere/roulette)
## partagent ce meme Label. Sans serialisation, deux qui se declenchent sur le
## meme drop (ex: le dernier jeton d'une Partition atterrit sur une case
## mystere) se marchent dessus : le "visible = false" differe de la premiere
## s'execute pendant que la seconde est en plein milieu de sa sequence,
## la rendant invisible (bug remonte au playtest). Verrou cooperatif simple
## plutot qu'une vraie file — pas de vraie race possible entre le while et le
## _locked = true qui suit (GDScript est single-threaded, aucun yield entre
## les deux) — et un tour ne genere jamais assez d'annonces pour que l'ordre
## d'arrivee ait besoin d'etre garanti au-dela du FIFO naturel.
var _locked: bool = false


func _acquire_lock() -> void:
	while _locked:
		await get_tree().process_frame
	_locked = true


func _release_lock() -> void:
	_locked = false


var _base_font_size: int = 0

## Valeurs actuellement affichees dans le duo (avant l'etape en cours),
## point de depart de chaque compte-a-rebours anime — voir _animate_tickets_to/
## _animate_multi_to.
var _tickets_shown: int = 0
var _multi_shown: float = 1.0
var _tickets_tween: Tween = null
var _multi_tween: Tween = null

## Sous-titre en petit sous le texte principal — pour l'instant uniquement
## utilise par play_mystery_announcement (descriptif de l'effet). Cache par
## defaut, jamais touche par les autres annonces (cascade/combo/roll/
## breakdown) qui n'en ont pas besoin.
@onready var subtitle: Label = $Subtitle

## Duo Tickets/Multi (session 25) utilise uniquement par play_breakdown — les
## autres annonces (cascade/combo/roll/mystere) restent sur le texte unique
## de `self` (Label racine) via _show_step, inchange.
@onready var title_label: Label = $TitleLabel
@onready var tickets_caption: Label = $TicketsCaption
@onready var tickets_value: Label = $TicketsValue
@onready var x_label: Label = $XLabel
@onready var multi_caption: Label = $MultiCaption
@onready var multi_value: Label = $MultiValue
@onready var result_value: Label = $ResultValue


func _ready() -> void:
	visible = false
	subtitle.visible = false
	_hide_breakdown_children()
	_base_font_size = get_theme_font_size("font_size")
	pivot_offset = size * 0.5


## Joue la sequence pour un groupe resolu sur le duo Tickets/Multi, dans
## l'ordre du calcul reel (session 25) : jetons + multi intrinseque de la
## Partition affiches ensemble des le depart (forme x level up deja fondus,
## pas de ligne "level up" separee) -> Sortilèges un par un dans l'ordre des slots
## (chacun modifie soit les tickets soit le multi, tilte le Sortilège concerne) ->
## bascule sur un chiffre unique (deja le resultat final si rien ne suit) ->
## multiplicateur externe (cellules de grille), qui devient le dernier temps
## fort si present. spells_ui peut etre null (pas de tilt dans ce cas). Rien
## ne bloque le score reel, deja calcule en amont — cette fonction ne fait
## qu'afficher sa decomposition. Le multi de cascade reste hors de ce calcul,
## affiche a part par play_cascade_announcement (voir GridVisual).
func play_breakdown(breakdown: Dictionary, final_score: int, spells_ui: SpellsUI) -> void:
	await _acquire_lock()
	var label: String = breakdown.get("label", "") as String
	var raw_value: int = breakdown.get("raw_value", 0) as int
	var base_mult: float = breakdown.get("base_mult", 1.0) as float
	var cell_mult: float = breakdown.get("cell_mult", 1.0) as float
	var spell_steps: Array = breakdown.get("spell_steps", []) as Array

	visible = true
	text = ""
	remove_theme_font_size_override("font_size")
	_show_pair()
	_tickets_shown = 0
	_multi_shown = 1.0
	tickets_value.text = "0"
	multi_value.text = "1"

	var tickets: int = raw_value
	var multi: float = maxf(base_mult, 1.0)
	_set_title(label if label != "" else "PARTITION", result_color)

	# 1a. Jetons bruts de la Partition — compte jusqu'a la valeur, pas un saut.
	_animate_tickets_to(tickets)
	await get_tree().create_timer(step_duration).timeout

	# 1b. Multi intrinseque (forme x level up, deja fondus — pas de ligne
	# "level up" separee).
	_animate_multi_to(multi)
	await get_tree().create_timer(step_duration).timeout

	# 2. Sortilèges, un par un, dans l'ordre des slots — chacun modifie soit les
	# tickets soit le multi, en tiltant le Sortilège concerne au meme moment.
	for step in spell_steps:
		var data: Dictionary = step as Dictionary
		var source: StringName = data.get("source", &"") as StringName
		if spells_ui != null and source != &"":
			spells_ui.tilt_spell(source)
		var step_label: String = data.get("label", "") as String
		if (data.get("kind", "flat") as String) == "mult":
			multi *= data.get("amount", 1.0) as float
			_animate_multi_to(multi)
		else:
			tickets += data.get("amount", 0) as int
			_animate_tickets_to(tickets)
		_set_title("+ %s" % step_label, spell_color)
		await get_tree().create_timer(step_duration).timeout

	# 3. Total intermediaire : bascule du duo vers un chiffre unique. Sans
	# multiplicateur externe derriere, ce chiffre EST deja le resultat final —
	# on affiche alors final_score (source de verite) plutot qu'un calcul
	# local qui pourrait diverger d'un arrondi.
	_show_single()
	var is_last_step: bool = cell_mult <= 1.0
	if is_last_step:
		add_theme_font_size_override("font_size", _base_font_size + result_font_size_boost)
	_set_title("TOTAL", value_color)
	result_value.text = str(final_score if is_last_step else int(tickets * multi))
	await get_tree().create_timer(result_pause_duration if is_last_step else step_duration).timeout

	# 4. Multiplicateur externe (cellules de grille, ex: Cellule Triple,
	# Mystere MULTI) — dernier facteur avant le resultat, hors Sortilèges/jetons.
	# Devient le dernier temps fort de la sequence quand il est present.
	if cell_mult > 1.0:
		add_theme_font_size_override("font_size", _base_font_size + result_font_size_boost)
		_set_title("CELLULE x%s" % _format_mult(cell_mult), mult_color)
		result_value.text = str(final_score)
		await get_tree().create_timer(result_pause_duration).timeout

	visible = false
	_hide_breakdown_children()
	_release_lock()


## Annonce dediee a une cascade (2+ resolutions chainees dans le meme tour,
## voir CascadeResolver — cascade_level >= 1). Jouee une fois par niveau,
## avant le detail des groupes de ce niveau. Le multiplicateur de cascade
## n'apparait plus dans le MULTI generique de play_breakdown — il a son
## propre temps fort ici, plus spectaculaire.
func play_cascade_announcement(mult: float) -> void:
	await _acquire_lock()
	visible = true
	_hide_breakdown_children()
	remove_theme_font_size_override("font_size")
	add_theme_font_size_override("font_size", _base_font_size + cascade_font_size_boost)
	_show_step("CASCADE x%s !" % _format_mult(mult), cascade_color)

	scale = Vector2(0.7, 0.7)
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	await get_tree().create_timer(cascade_duration).timeout
	visible = false
	_release_lock()


## Annonce dediee a un "Double Partition" (CascadeResolver.resolve —
## combo_bonus > 0) : deux figures distinctes se chevauchent sur au moins une
## cellule sans que l'une soit incluse dans l'autre. Jouee une fois par
## niveau, apres le detail des groupes de ce niveau (voir GridVisual._animate_match) —
## meme principe que play_cascade_announcement, son propre temps fort plutot
## que noye dans un MULTI generique.
func play_combo_announcement(mult: float) -> void:
	await _acquire_lock()
	visible = true
	_hide_breakdown_children()
	remove_theme_font_size_override("font_size")
	add_theme_font_size_override("font_size", _base_font_size + combo_font_size_boost)
	_show_step("DOUBLE PARTITION x%s !" % _format_mult(mult), combo_color)

	scale = Vector2(0.7, 0.7)
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	await get_tree().create_timer(combo_duration).timeout
	visible = false
	_release_lock()


## Petite roulette casino avant un Diamond Rock (CascadeResolver._score_group —
## breakdown.roll). Defile des chiffres aleatoires dans [min_value, max_value]
## de plus en plus lentement, puis s'arrete sur `result` — deja tire par le
## resolver avant meme cette animation, jamais rerolle ici : ceci n'est qu'un
## reveal, le score est fige en amont.
func play_roll_announcement(result: int, min_value: int, max_value: int) -> void:
	await _acquire_lock()
	visible = true
	_hide_breakdown_children()
	remove_theme_font_size_override("font_size")
	add_theme_font_size_override("font_size", _base_font_size + roll_font_size_boost)

	for i in range(roll_spin_count):
		var fake: int = randi_range(min_value, max_value)
		_show_step("ROULETTE... %d" % fake, roll_color)
		var progress: float = float(i) / float(maxi(roll_spin_count - 1, 1))
		var interval: float = lerpf(roll_spin_start_interval, roll_spin_end_interval, progress)
		await get_tree().create_timer(interval).timeout

	_show_step("ROULETTE : %d !" % result, roll_color)
	scale = Vector2(0.7, 0.7)
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	await get_tree().create_timer(roll_result_duration).timeout
	visible = false
	_release_lock()


## Recompense de la Colonne Convoitée (session 27, EntityManager.
## reward_triggered, remplace la roulette de session 25) -- defile parmi des
## noms de prix (meme cadence que play_roll_announcement, couleur mystere
## plutot que roll_color pour rester dans le meme registre visuel que les
## cases mystere) puis s'arrete sur le prix reellement gagne. `flavor_pool`
## est purement cosmetique pendant le defile (le vrai resultat est deja tire
## par EntityManager avant l'appel, voir CursedColumnRewards) -- deux
## familles possibles, Multiplicateur ou Boost.
func play_prize_spin_announcement(flavor_pool: Array[String], landed_label: String, landed_description: String = "") -> void:
	await _acquire_lock()
	visible = true
	_hide_breakdown_children()
	remove_theme_font_size_override("font_size")
	add_theme_font_size_override("font_size", _base_font_size + mystery_font_size_boost)
	subtitle.visible = false

	for i in range(roll_spin_count):
		var flavor: String = flavor_pool.pick_random() if not flavor_pool.is_empty() else landed_label
		_show_step(flavor, mystery_color)
		var progress: float = float(i) / float(maxi(roll_spin_count - 1, 1))
		var interval: float = lerpf(roll_spin_start_interval, roll_spin_end_interval, progress)
		await get_tree().create_timer(interval).timeout

	_show_step(landed_label, mystery_color)
	subtitle.text = landed_description
	subtitle.visible = landed_description != ""

	scale = Vector2(0.7, 0.7)
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	await get_tree().create_timer(mystery_duration).timeout
	visible = false
	subtitle.visible = false
	_release_lock()


## Case mystere revelee (session 24, voir TurnController.mystery_cell_resolved) —
## meme temps fort que play_cascade_announcement/play_combo_announcement,
## en dehors de toute resolution de Partition (retour de playtest : le
## message_display discret ne suffisait pas, passait inapercu).
func play_mystery_announcement(label: String, description: String = "") -> void:
	await _acquire_lock()
	visible = true
	_hide_breakdown_children()
	remove_theme_font_size_override("font_size")
	add_theme_font_size_override("font_size", _base_font_size + mystery_font_size_boost)
	_show_step(label, mystery_color)

	subtitle.text = description
	subtitle.visible = description != ""

	scale = Vector2(0.7, 0.7)
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	await get_tree().create_timer(mystery_duration).timeout
	visible = false
	subtitle.visible = false
	_release_lock()


## Anime tickets_value en comptant de sa valeur actuelle jusqu'a target, au
## lieu d'un saut instantane — voir _tickets_shown.
func _animate_tickets_to(target: int) -> void:
	if _tickets_tween != null and _tickets_tween.is_valid():
		_tickets_tween.kill()
	var from: int = _tickets_shown
	_tickets_shown = target
	_tickets_tween = create_tween()
	_tickets_tween.tween_method(func(val: float) -> void:
		# Garde-fou : la scene peut se faire liberer avant ce step (meme
		# raison que GameScene._animate_score_to).
		if is_instance_valid(tickets_value):
			tickets_value.text = str(int(round(val)))
	, float(from), float(target), step_duration * 0.7).set_ease(Tween.EASE_OUT)


## Anime multi_value en comptant de sa valeur actuelle jusqu'a target — meme
## principe que _animate_tickets_to.
func _animate_multi_to(target: float) -> void:
	if _multi_tween != null and _multi_tween.is_valid():
		_multi_tween.kill()
	var from: float = _multi_shown
	_multi_shown = target
	_multi_tween = create_tween()
	_multi_tween.tween_method(func(val: float) -> void:
		if is_instance_valid(multi_value):
			multi_value.text = _format_mult(val)
	, from, target, step_duration * 0.7).set_ease(Tween.EASE_OUT)


func _show_step(msg: String, color: Color) -> void:
	text = msg
	add_theme_color_override("font_color", color)


## Affiche le duo Tickets/Multi, cache le chiffre unique (etape 1-2 de
## play_breakdown).
func _show_pair() -> void:
	title_label.visible = true
	tickets_caption.visible = true
	tickets_value.visible = true
	x_label.visible = true
	multi_caption.visible = true
	multi_value.visible = true
	result_value.visible = false


## Affiche le chiffre unique, cache le duo Tickets/Multi (etape 3-4 de
## play_breakdown).
func _show_single() -> void:
	title_label.visible = true
	tickets_caption.visible = false
	tickets_value.visible = false
	x_label.visible = false
	multi_caption.visible = false
	multi_value.visible = false
	result_value.visible = true


## Masque tout le duo/chiffre unique — appele au repos et au debut des autres
## annonces (cascade/combo/roll/mystere) pour ne pas laisser de texte perime
## derriere leur propre message sur `self`.
func _hide_breakdown_children() -> void:
	title_label.visible = false
	tickets_caption.visible = false
	tickets_value.visible = false
	x_label.visible = false
	multi_caption.visible = false
	multi_value.visible = false
	result_value.visible = false


func _set_title(text_value: String, color: Color) -> void:
	title_label.text = text_value
	title_label.add_theme_color_override("font_color", color)


func _format_mult(mult: float) -> String:
	if mult == float(int(mult)):
		return str(int(mult))
	return "%.1f" % mult
