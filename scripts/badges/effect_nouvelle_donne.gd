## Badge "Nouvelle Donne" : chaque Shake declenche cumule +3 points, appliques
## a toutes les resolutions suivantes (scaling permanent, jamais remis a zero
## sur la run — meme principe que "Quatre quart"/"Amélioration continue").
## Trigger : on_shake_used
extends BadgeEffect

const BONUS_PER_SHAKE: int = 3
const STATE_KEY: StringName = &"nouvelle_donne_shakes"


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	var count: int = (run_manager.get_run_badge_state(STATE_KEY, 0) as int) + 1
	run_manager.set_run_badge_state(STATE_KEY, count)
	run_manager.set_flat_score_bonus(&"nouvelle_donne", count * BONUS_PER_SHAKE)


func get_progress_text(run_manager: RunManager) -> String:
	var count: int = run_manager.get_run_badge_state(STATE_KEY, 0) as int
	return "+%d points (%d Shake)" % [count * BONUS_PER_SHAKE, count]
