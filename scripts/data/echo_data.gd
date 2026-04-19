## Donnees d'un echo : definition + chemin du script d'effet.
## L'execution reelle est portee par le script effect_script (derive de EchoEffect).
class_name EchoData
extends Resource

enum Rarity { COMMON, UNCOMMON, RARE, EPIC }

@export var id: StringName = &""
@export var label: String = ""
@export var description: String = ""
@export var price: int = 3
@export var rarity: Rarity = Rarity.COMMON
## Trigger : &"on_round_start" | &"on_token_drop" | &"on_cascade_step" | &"on_turn_resolved" | &"on_last_breath"
@export var trigger: StringName = &"on_round_start"
## Script derive de EchoEffect. Instancie a chaque dispatch par EchoManager.
@export var effect_script: GDScript = null

## DEBUG : si true, cet echo est equipe des le debut du run (bypass shop).
## A laisser a false pour un run normal.
@export var debug_start_equipped: bool = false


## Instancie l'effet. Retourne null si effect_script est absent ou invalide.
func make_effect() -> EchoEffect:
	if effect_script == null:
		return null
	return effect_script.new() as EchoEffect
