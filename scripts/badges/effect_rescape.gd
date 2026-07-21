## Badge "Rescapé" : chaque manche boss survécue cumule +2 au facteur de
## scaling permanent (jamais remis a zero, actif sur toute la run — meme
## principe qu'"Escalade musicale"). Manche boss = round_number multiple de
## GameRules.ROUNDS_PER_ZONE, meme detection que BossMalusManager.
## Trigger : on_round_end
extends BadgeEffect

const BONUS_PER_BOSS: float = 2.0
const STATE_KEY: StringName = &"rescape_boss_survived"


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	if RunService.current_round % GameRules.ROUNDS_PER_ZONE != 0:
		return
	var count: int = (run_manager.get_run_badge_state(STATE_KEY, 0) as int) + 1
	run_manager.set_run_badge_state(STATE_KEY, count)
	run_manager.set_scaling_mult_bonus(&"rescape", count * BONUS_PER_BOSS)


func get_progress_text(run_manager: RunManager) -> String:
	var count: int = run_manager.get_run_badge_state(STATE_KEY, 0) as int
	return "+%.1f mult (%d boss survécus)" % [count * BONUS_PER_BOSS, count]
