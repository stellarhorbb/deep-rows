## Sortilège "Brocante" : chaque Partition vendue cumule +3 points, appliques a
## toutes les resolutions suivantes (scaling permanent, jamais remis a zero
## sur la run — meme principe que "Quatre quart"/"Amélioration continue").
## Trigger : on_sheet_sold
extends SpellEffect

const BONUS_PER_SALE: int = 3
const STATE_KEY: StringName = &"brocante_sales"


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	var count: int = (run_manager.get_run_spell_state(STATE_KEY, 0) as int) + 1
	run_manager.set_run_spell_state(STATE_KEY, count)
	run_manager.set_flat_score_bonus(&"brocante", count * BONUS_PER_SALE)


func get_progress_text(run_manager: RunManager) -> String:
	var count: int = run_manager.get_run_spell_state(STATE_KEY, 0) as int
	return "+%d points (%d Partitions vendues)" % [count * BONUS_PER_SALE, count]
