## Sortilège "Regularite" : 3 tours resolus sans vraie cascade (niveau 1+) ->
## le prochain pattern qui score est x1.5. Contrepoids doux a Vertige, qui
## recompense la cascade au lieu de la punir.
## Trigger : on_turn_resolved
extends SpellEffect

const STREAK_TARGET: int = 3
const BONUS_MULT: float = 1.5
const STATE_KEY: StringName = &"regularite_streak"


func apply(event: Dictionary, run_manager: RunManager) -> void:
	var timeline: Array = event.get("timeline", [])
	var had_cascade: bool = false
	for step in timeline:
		var e: Dictionary = step as Dictionary
		if e.get("type") == CascadeResolver.EventType.MATCH and (e.get("cascade_level", 0) as int) >= 1:
			had_cascade = true
			break

	if had_cascade:
		run_manager.set_spell_state(STATE_KEY, 0)
		run_manager.set_global_multiplier(1.0, &"regularite")
		return

	var streak: int = run_manager.get_spell_state(STATE_KEY, 0) as int
	streak += 1
	if streak >= STREAK_TARGET:
		run_manager.set_spell_state(STATE_KEY, 0)
		run_manager.set_global_multiplier(BONUS_MULT, &"regularite")
	else:
		run_manager.set_spell_state(STATE_KEY, streak)
		run_manager.set_global_multiplier(1.0, &"regularite")


func get_progress_text(run_manager: RunManager) -> String:
	var streak: int = run_manager.get_spell_state(STATE_KEY, 0) as int
	return "%d/%d tours sans cascade" % [streak, STREAK_TARGET]
