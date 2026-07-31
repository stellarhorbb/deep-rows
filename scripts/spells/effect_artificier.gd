## Sortilège "Artificier" : chaque jeton de valeur 5 qui score a 1 chance sur 4 de
## créer un jeton spécial "Pétard à mèche", ajouté à l'inventaire de spéciaux
## du joueur comme s'il l'avait acheté (voir RunManager.add_special, session
## 25) -- silencieusement sans effet si l'inventaire est déjà plein.
## Trigger : on_turn_resolved
extends SpellEffect

const TARGET_VALUE: int = 5
const PROC_CHANCE: float = 0.25


func apply(event: Dictionary, run_manager: RunManager) -> void:
	var timeline: Array = event.get("timeline", [])
	for step in timeline:
		var e: Dictionary = step as Dictionary
		if e.get("type") != CascadeResolver.EventType.MATCH:
			continue
		for group in (e.get("groups", []) as Array):
			for scored in ((group as Dictionary).get("scored_tokens", []) as Array):
				if (scored as Dictionary).get("value", -1) != TARGET_VALUE:
					continue
				if randf() < PROC_CHANCE:
					run_manager.add_special(TokenData.SpecialType.PETARD_A_MECHE)
