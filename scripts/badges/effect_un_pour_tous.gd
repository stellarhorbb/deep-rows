## Badge "Un Pour Tous" : +2 mouches la premiere fois qu'une famille donnee
## score dans la manche (une fois par famille distincte, pas par pattern).
## Trigger : on_turn_resolved
extends BadgeEffect

const FLIES_BONUS: int = 2
const STATE_KEY: StringName = &"un_pour_tous_seen_families"


func apply(event: Dictionary, run_manager: RunManager) -> void:
	var timeline: Array = event.get("timeline", [])
	var seen: Dictionary = run_manager.get_badge_state(STATE_KEY, {}) as Dictionary

	for step in timeline:
		var e: Dictionary = step as Dictionary
		if e.get("type") != CascadeResolver.EventType.MATCH:
			continue
		for group in (e.get("groups", []) as Array):
			var g: Dictionary = group as Dictionary
			if not g.has("family"):
				continue
			var family: TokenData.Family = g["family"]
			if not seen.has(family):
				seen[family] = true
				run_manager.add_flies(FLIES_BONUS)

	run_manager.set_badge_state(STATE_KEY, seen)


func get_progress_text(run_manager: RunManager) -> String:
	var seen: Dictionary = run_manager.get_badge_state(STATE_KEY, {}) as Dictionary
	return "%d/%d familles vues cette manche" % [seen.size(), GameRules.FAMILY_COUNT]
