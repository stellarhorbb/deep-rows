## Badge "Bénédiction" : +1 slot de hold (peut mettre 2 jetons de côté au
## lieu d'1).
## Trigger : on_round_start
extends BadgeEffect

const HOLD_SLOT_BONUS: int = 1


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.add_hold_slot_bonus(HOLD_SLOT_BONUS, &"benediction")
