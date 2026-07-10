## Badge "Vertige" : +5 mouches si une vraie cascade (niveau 1+, donc au
## moins une vague de gravite apres le match initial) s'est declenchee ce
## tour. Premier badge sur on_turn_resolved.
## Trigger : on_turn_resolved
extends BadgeEffect

const FLIES_ON_CASCADE: int = 5


func apply(event: Dictionary, run_manager: RunManager) -> void:
	var timeline: Array = event.get("timeline", [])
	for step in timeline:
		var e: Dictionary = step as Dictionary
		if e.get("type") == CascadeResolver.EventType.MATCH and (e.get("cascade_level", 0) as int) >= 1:
			run_manager.add_flies(FLIES_ON_CASCADE)
			return
