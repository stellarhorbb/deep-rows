## Badge "Numerologie" : les patterns de rule "value" doublent leur score.
## Trigger : on_round_start
extends BadgeEffect


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.set_rule_multiplier(&"value", 2.0)
