## Badge "Pourboire" : mouches fixes en debut de manche.
## Trigger : on_round_start
extends BadgeEffect

const FLIES_PER_ROUND: int = 5


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.add_flies(FLIES_PER_ROUND)
