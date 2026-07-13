## Ecran de fin de manche (hors derniere manche du run) : decompose la
## recompense en mouches (base + bonus jetons restants + bonus badges) avant
## de laisser le joueur continuer vers le shop. Le layout de jeu reste visible
## derriere (Background couvre uniquement ce panneau, meme principe que
## ResolutionBanner), ce n'est pas un changement de scene.
class_name YouWinUI
extends Control

@export var max_bonus_lines: int = 4

@onready var _base_label: Label = $VBox/BaseLabel
@onready var _total_label: Label = $VBox/TotalLabel
@onready var _collect_button: Button = $VBox/CollectButton
@onready var _bonus_labels: Array[Label] = _find_bonus_labels()

signal collected


func _ready() -> void:
	visible = false
	_collect_button.pressed.connect(_on_collect_pressed)


## base : mouches fixes de la manche (GameRules.FLIES_PER_ROUND_WON).
## token_bonus : bonus jetons restants (0 si aucun palier atteint, voir
## GameRules.get_round_end_flies_bonus). badge_breakdown : {label_badge:
## mouches} venu de BadgeManager.dispatch_round_end(). Affiche le detail et
## n'ecrase la main qu'une fois "ENCAISSER" clique.
func show_reward(base: int, token_bonus: int, badge_breakdown: Dictionary) -> void:
	_base_label.text = "BASE : +%d" % base

	var bonus_lines: Array[String] = []
	if token_bonus > 0:
		bonus_lines.append("JETONS RESTANTS : +%d" % token_bonus)
	for badge_label in badge_breakdown:
		bonus_lines.append("%s : +%d" % [badge_label, badge_breakdown[badge_label] as int])

	for i in range(_bonus_labels.size()):
		var has_line: bool = i < bonus_lines.size()
		_bonus_labels[i].visible = has_line
		if has_line:
			_bonus_labels[i].text = bonus_lines[i]

	var badge_total: int = 0
	for amount in badge_breakdown.values():
		badge_total += amount as int
	_total_label.text = "TOTAL : +%d MOUCHES" % (base + token_bonus + badge_total)

	visible = true
	await collected
	visible = false


func _on_collect_pressed() -> void:
	collected.emit()


func _find_bonus_labels() -> Array[Label]:
	var labels: Array[Label] = []
	for i in range(1, max_bonus_lines + 1):
		labels.append(get_node("VBox/BonusLabel%d" % i) as Label)
	return labels
