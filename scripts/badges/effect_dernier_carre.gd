## Badge "Dernier Carre" : quand il reste 4 jetons ou moins dans le deck,
## tout ce qui resout ce tour est x2.
## Trigger : on_token_drop
extends BadgeEffect

const DECK_THRESHOLD: int = 4
const BONUS_MULT: float = 2.0


func apply(event: Dictionary, run_manager: RunManager) -> void:
	var remaining: int = event.get("deck_remaining", DECK_THRESHOLD + 1) as int
	run_manager.set_global_multiplier(BONUS_MULT if remaining <= DECK_THRESHOLD else 1.0)
