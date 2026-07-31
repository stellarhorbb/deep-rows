## Sortilège "Regain" : chaque level up de Partition accorde +1 charge de Shake.
## Trigger : on_level_up
extends SpellEffect

const CHARGES_PER_LEVEL_UP: int = 1


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.add_shake_charges(CHARGES_PER_LEVEL_UP)
