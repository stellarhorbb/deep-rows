## Banniere centrale de decomposition du score, un groupe resolu a la fois :
## nom de la Partition -> valeur brute -> multi intrinseque -> (tilt Badge si
## applicable) -> resultat final en plus gros. Remplace les anciens popups
## "+X" et labels de pattern par groupe (GridVisual._animate_match), qui
## etaient trop discrets/rapides pour suivre le calcul. Zero style pour
## l'instant — priorite a la lisibilite de la sequence.
class_name ResolutionBanner
extends Label

@export var step_duration: float = 0.45
@export var result_pause_duration: float = 0.6
@export var result_font_size_boost: int = 20
@export var value_color: Color = Color("e2b714")
@export var mult_color: Color = Color("4ecdc4")
@export var badge_color: Color = Color("ff6b6b")
@export var result_color: Color = Color("f0e6c8")

@export var cascade_color: Color = Color("ff3d3d")
@export var cascade_font_size_boost: int = 28
@export var cascade_duration: float = 0.6

var _base_font_size: int = 0


func _ready() -> void:
	visible = false
	_base_font_size = get_theme_font_size("font_size")
	pivot_offset = size * 0.5


## Joue la sequence pour un groupe resolu. badges_ui peut etre null (pas de
## tilt dans ce cas). Rien ne bloque le score reel, deja calcule en amont —
## cette fonction ne fait qu'afficher sa decomposition.
func play_breakdown(breakdown: Dictionary, final_score: int, badges_ui: BadgesUI) -> void:
	var label: String = breakdown.get("label", "") as String
	var base_value: int = breakdown.get("base_value", 0) as int
	var base_mult: float = breakdown.get("base_mult", 1.0) as float
	var badge_mult: float = breakdown.get("badge_mult", 1.0) as float
	var badge_sources: Array = breakdown.get("badge_sources", []) as Array

	visible = true
	remove_theme_font_size_override("font_size")

	if label != "":
		_show_step(label, result_color)
		await get_tree().create_timer(step_duration).timeout

	_show_step("%d TICKETS" % base_value, value_color)
	await get_tree().create_timer(step_duration).timeout

	if base_mult > 1.0:
		_show_step("×%s MULTI" % _format_mult(base_mult), mult_color)
		await get_tree().create_timer(step_duration).timeout

	if badge_mult > 1.0:
		if badges_ui != null:
			for source in badge_sources:
				badges_ui.tilt_badge(source as StringName)
		_show_step("BADGE ×%s" % _format_mult(badge_mult), badge_color)
		await get_tree().create_timer(step_duration).timeout

	add_theme_font_size_override("font_size", _base_font_size + result_font_size_boost)
	_show_step("%d TICKETS" % final_score, result_color)
	await get_tree().create_timer(result_pause_duration).timeout

	visible = false


## Annonce dediee a une cascade (2+ resolutions chainees dans le meme tour,
## voir CascadeResolver — cascade_level >= 1). Jouee une fois par niveau,
## avant le detail des groupes de ce niveau. Le multiplicateur de cascade
## n'apparait plus dans le MULTI generique de play_breakdown — il a son
## propre temps fort ici, plus spectaculaire.
func play_cascade_announcement(mult: float) -> void:
	visible = true
	remove_theme_font_size_override("font_size")
	add_theme_font_size_override("font_size", _base_font_size + cascade_font_size_boost)
	_show_step("CASCADE ×%s !" % _format_mult(mult), cascade_color)

	scale = Vector2(0.7, 0.7)
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	await get_tree().create_timer(cascade_duration).timeout


func _show_step(msg: String, color: Color) -> void:
	text = msg
	add_theme_color_override("font_color", color)


func _format_mult(mult: float) -> String:
	if mult == float(int(mult)):
		return str(int(mult))
	return "%.1f" % mult
