## Sortilège "Escalade musicale" : chaque level up de Partition cumule +0.25 au
## facteur de scaling permanent (jamais remis à zéro, actif sur toute la run).
## Retravaillé de +0.5 à +0.25 en session 23 après playtest (jugé trop fort).
## Trigger : on_level_up
extends SpellEffect

const BONUS_PER_LEVEL_UP: float = 0.25
const STATE_KEY: StringName = &"escalade_musicale_level_ups"


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	var count: int = (run_manager.get_run_spell_state(STATE_KEY, 0) as int) + 1
	run_manager.set_run_spell_state(STATE_KEY, count)
	run_manager.set_scaling_mult_bonus(&"escalade_musicale", count * BONUS_PER_LEVEL_UP)


func get_progress_text(run_manager: RunManager) -> String:
	var count: int = run_manager.get_run_spell_state(STATE_KEY, 0) as int
	return "+%.2f mult (%d level up)" % [count * BONUS_PER_LEVEL_UP, count]
