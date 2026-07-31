## Sortilège "Visionnaire" : +1 jeton visible dans la preview du stream.
## Trigger : on_round_start
extends SpellEffect

const PREVIEW_BONUS: int = 1


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.add_preview_size_bonus(PREVIEW_BONUS, &"visionnaire")
