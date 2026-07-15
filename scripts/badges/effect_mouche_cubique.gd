## Badge "Mouche cubique" : +1 mouche à chaque fois qu'un 3 score dans une
## Partition.
## Trigger : on_turn_resolved
extends BadgeEffect

const TARGET_VALUE: int = 3
const FLIES_PER_TOKEN: int = 1


func apply(event: Dictionary, run_manager: RunManager) -> void:
	var timeline: Array = event.get("timeline", [])
	var count: int = 0
	for step in timeline:
		var e: Dictionary = step as Dictionary
		if e.get("type") != CascadeResolver.EventType.MATCH:
			continue
		for group in (e.get("groups", []) as Array):
			for scored in ((group as Dictionary).get("scored_tokens", []) as Array):
				if (scored as Dictionary).get("value", -1) == TARGET_VALUE:
					count += 1

	if count > 0:
		run_manager.add_flies(count * FLIES_PER_TOKEN)
