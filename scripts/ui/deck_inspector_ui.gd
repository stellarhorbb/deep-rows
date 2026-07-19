## Affiche les comptes agreges (famille+valeur, rocks, speciaux) du deck.
## En manche, montre ce qu'il reste a tirer (deck_manager). Hors manche (shop,
## ouverture de pack) ou deck_manager est null, retombe sur un apercu de la
## composition qui alimentera la prochaine manche (run_manager) pour que le
## joueur puisse toujours consulter son deck. L'ordre de tirage n'est jamais
## revele — seulement des totaux, pour ne pas casser la tension du stream.
class_name DeckInspectorUI
extends Control

@onready var content_label: Label = $Box/VBox/ContentLabel
@onready var close_button: Button = $Box/VBox/CloseButton

var deck_manager: DeckManager = null
var run_manager: RunManager = null


func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)


func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()


func _refresh() -> void:
	var tokens: Array[TokenData]
	var header: String
	if deck_manager != null:
		tokens = deck_manager.get_remaining_tokens()
		header = "RESTANT CETTE MANCHE"
	elif run_manager != null:
		tokens = run_manager.build_next_round_deck_preview()
		header = "PROCHAINE MANCHE"
	else:
		content_label.text = ""
		return
	var base_counts: Dictionary = {}
	var rock_count: int = 0
	var special_counts: Dictionary = {}

	for token in tokens:
		match token.kind:
			TokenData.Kind.BASE:
				var key: String = "%s %s" % [TokenData.family_label(token.family), TokenData.value_label(token.value)]
				base_counts[key] = (base_counts.get(key, 0) as int) + 1
			TokenData.Kind.ROCK:
				rock_count += 1
			TokenData.Kind.SPECIAL:
				var label: String = TokenData.special_type_label(token.special_type)
				special_counts[label] = (special_counts.get(label, 0) as int) + 1

	var lines: Array[String] = [header, ""]

	var total_base: int = 0
	for c in base_counts.values():
		total_base += c as int
	lines.append("BOUTONS RESTANTS (%d)" % total_base)

	var base_keys: Array = base_counts.keys()
	base_keys.sort()
	for key in base_keys:
		lines.append("  %s  x%d" % [key, base_counts[key]])

	lines.append("")
	lines.append("ROCKS RESTANTS : %d" % rock_count)

	if not special_counts.is_empty():
		lines.append("")
		lines.append("SPÉCIAUX RESTANTS :")
		var special_keys: Array = special_counts.keys()
		special_keys.sort()
		for label in special_keys:
			lines.append("  %s  x%d" % [label, special_counts[label]])

	content_label.text = "\n".join(lines)


func _on_close_pressed() -> void:
	visible = false
