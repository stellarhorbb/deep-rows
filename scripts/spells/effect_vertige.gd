## Sortilège "Vertige" : +10 mouches si une cascade de profondeur 2+ (donc deux
## vagues de gravite apres le match initial, pas juste une) s'est declenchee
## ce tour. Seuil remonte a 2 et valeur a 10 en session 16 : deux cascades
## d'affilee est juge assez rare pour justifier le montant.
## Trigger : on_turn_resolved
extends SpellEffect

const FLIES_ON_CASCADE: int = 10
const MIN_CASCADE_LEVEL: int = 2


func apply(event: Dictionary, run_manager: RunManager) -> void:
	var timeline: Array = event.get("timeline", [])
	for step in timeline:
		var e: Dictionary = step as Dictionary
		if e.get("type") == CascadeResolver.EventType.MATCH and (e.get("cascade_level", 0) as int) >= MIN_CASCADE_LEVEL:
			run_manager.add_flies(FLIES_ON_CASCADE)
			return
