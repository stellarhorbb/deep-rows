## Donnees d'un sortilège : definition + chemin du script d'effet.
## L'execution reelle est portee par le script effect_script (derive de SpellEffect).
class_name SpellData
extends Resource

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export var id: StringName = &""
@export var label: String = ""
@export var description: String = ""
@export var price: int = 3
@export var rarity: Rarity = Rarity.COMMON
## Trigger : &"on_round_start" | &"on_token_drop" | &"on_cascade_step" | &"on_turn_resolved" | &"on_last_breath" | &"on_round_end" | &"on_level_up" | &"on_deck_grown" | &"on_shake_used" | &"on_sheet_sold" | &"on_figure_promoted" | &"on_deck_tool_shown"
@export var trigger: StringName = &"on_round_start"
## Script derive de SpellEffect. Instancie a chaque dispatch par SpellManager.
@export var effect_script: GDScript = null

## DEBUG : si true, ce sortilège est equipe des le debut du run (bypass shop).
## A laisser a false pour un run normal.
@export var debug_start_equipped: bool = false


## Instancie l'effet. Retourne null si effect_script est absent ou invalide.
func make_effect() -> SpellEffect:
	if effect_script == null:
		return null
	return effect_script.new() as SpellEffect
