## Sortilège "Mouches en cascade" : +3 mouches par cascade secondaire (cascade_level >= 1).
## Trigger : on_cascade_step
extends SpellEffect

const FLIES_PER_CASCADE: int = 3


func apply(event: Dictionary, run_manager: RunManager) -> void:
	var level: int = event.get("cascade_level", 0) as int
	if level >= 1:
		run_manager.add_flies(FLIES_PER_CASCADE)
