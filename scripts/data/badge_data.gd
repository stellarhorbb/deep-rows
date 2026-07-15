## Donnees d'un badge : definition + chemin du script d'effet.
## L'execution reelle est portee par le script effect_script (derive de BadgeEffect).
class_name BadgeData
extends Resource

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export var id: StringName = &""
@export var label: String = ""
@export var description: String = ""
@export var price: int = 3
@export var rarity: Rarity = Rarity.COMMON
## Trigger : &"on_round_start" | &"on_token_drop" | &"on_cascade_step" | &"on_turn_resolved" | &"on_last_breath" | &"on_round_end" | &"on_level_up" | &"on_deck_grown"
@export var trigger: StringName = &"on_round_start"
## Script derive de BadgeEffect. Instancie a chaque dispatch par BadgeManager.
@export var effect_script: GDScript = null

## DEBUG : si true, ce badge est equipe des le debut du run (bypass shop).
## A laisser a false pour un run normal.
@export var debug_start_equipped: bool = false


## Instancie l'effet. Retourne null si effect_script est absent ou invalide.
func make_effect() -> BadgeEffect:
	if effect_script == null:
		return null
	return effect_script.new() as BadgeEffect
