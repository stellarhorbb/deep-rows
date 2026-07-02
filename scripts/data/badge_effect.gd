## Base class pour les effets de badges. Chaque badge a son propre script derive.
## Instancie et appele par BadgeManager quand le trigger correspondant se declenche.
class_name BadgeEffect
extends RefCounted


## Applique l'effet. A override dans les scripts concrets.
## event : Dictionary specifique au trigger (ex: { "cascade_level": 0, "earned": 50 })
## run_manager : accessible pour muter flies, grid_modifiers, rule_multipliers, etc.
func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
