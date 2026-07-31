## Sortilège "Numerologie" : les patterns de l'axe casino (Brelan/Carre/Suite/
## Fibonacci) doublent leur score. Number Square partage la rule "value"
## mais reste hors catalogue (shop_manager.gd), donc jamais concerne.
## Trigger : on_round_start
extends SpellEffect


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.set_rule_multiplier(&"value", 2.0)
	run_manager.set_rule_multiplier(&"suite", 2.0)
	run_manager.set_rule_multiplier(&"fibonacci", 2.0)
