## Construit un tooltip personnalise avec un petit badge colore de rarete
## au-dessus du texte de description habituel. Utilise par tout controle qui
## affiche un BadgeData au survol (BadgesUI, RarityButton) — les Partitions
## n'ont plus de rarete depuis la session 19 (voir PatternData).
class_name RarityTooltip
extends RefCounted


static func build(text: String, rarity: int) -> Object:
	var panel: PanelContainer = PanelContainer.new()
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color("2b2b3d")
	panel_style.set_content_margin_all(8.0)
	panel_style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", panel_style)

	# Godot enveloppe systematiquement le control retourne par
	# _make_custom_tooltip dans son propre panneau par defaut (theme
	# "TooltipPanel", fond noir semi-transparent) — sans ca, ce fond par
	# defaut restait visible derriere/autour du notre (le "double bloc").
	# tree_entered ne se declenche qu'une fois ce parent connu.
	panel.tree_entered.connect(_clear_wrapper_background.bind(panel), CONNECT_ONE_SHOT)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	vbox.add_child(_build_chip(rarity))

	var label: Label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color.WHITE)
	label.custom_minimum_size = Vector2(220.0, 0.0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(label)

	return panel


static func _clear_wrapper_background(panel: PanelContainer) -> void:
	var wrapper: Node = panel.get_parent()
	if wrapper is Control:
		(wrapper as Control).add_theme_stylebox_override("panel", StyleBoxEmpty.new())


static func _build_chip(rarity: int) -> Control:
	var idx: int = clampi(rarity, 0, GameRules.RARITY_COLORS.size() - 1)

	var chip: PanelContainer = PanelContainer.new()
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var chip_style: StyleBoxFlat = StyleBoxFlat.new()
	chip_style.bg_color = GameRules.RARITY_COLORS[idx]
	chip_style.set_content_margin(SIDE_LEFT, 8.0)
	chip_style.set_content_margin(SIDE_TOP, 2.0)
	chip_style.set_content_margin(SIDE_RIGHT, 8.0)
	chip_style.set_content_margin(SIDE_BOTTOM, 2.0)
	chip_style.set_corner_radius_all(4)
	chip.add_theme_stylebox_override("panel", chip_style)

	var label: Label = Label.new()
	label.text = GameRules.RARITY_NAMES[idx]
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_font_size_override("font_size", 12)
	chip.add_child(label)

	return chip
