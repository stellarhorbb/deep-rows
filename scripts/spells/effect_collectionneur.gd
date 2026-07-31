## Sortilège "Collectionneur" : les patterns de rule "rock" doublent leur score.
## Symetrique de Famille Unie, mais pour Diamond Rock.
## Trigger : on_round_start
extends SpellEffect


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.set_rule_multiplier(&"rock", 2.0, &"collectionneur")
