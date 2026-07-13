## Badge "Pourboire" : mouches fixes en fin de manche (visible sur l'ecran
## "you win", voir YouWinUI).
## Trigger : on_round_end
extends BadgeEffect

const FLIES_PER_ROUND: int = 3


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.add_flies(FLIES_PER_ROUND)
