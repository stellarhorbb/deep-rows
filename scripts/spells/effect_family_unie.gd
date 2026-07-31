## Sortilège "Famille unie" : les patterns de rule "family" doublent leur score.
## Trigger : on_round_start
extends SpellEffect


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.set_rule_multiplier(&"family", 2.0, &"family_unie")
