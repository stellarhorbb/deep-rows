## Badge "Amélioration continue" : chaque level up de Partition cumule +5
## points, appliqués à toutes les résolutions suivantes (scaling permanent,
## jamais remis à zéro sur la run).
## Trigger : on_level_up
extends BadgeEffect

const BONUS_PER_LEVEL_UP: int = 5
const STATE_KEY: StringName = &"amelioration_continue_level_ups"


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	var count: int = (run_manager.get_run_badge_state(STATE_KEY, 0) as int) + 1
	run_manager.set_run_badge_state(STATE_KEY, count)
	run_manager.set_flat_score_bonus(&"amelioration_continue", count * BONUS_PER_LEVEL_UP)


func get_progress_text(run_manager: RunManager) -> String:
	var count: int = run_manager.get_run_badge_state(STATE_KEY, 0) as int
	return "+%d points (%d level up)" % [count * BONUS_PER_LEVEL_UP, count]
