## Badge "Mouche mélomane" : +5 mouches à chaque fois qu'une Partition gagne
## un niveau.
## Trigger : on_level_up
extends BadgeEffect

const FLIES_PER_LEVEL_UP: int = 5


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.add_flies(FLIES_PER_LEVEL_UP)
