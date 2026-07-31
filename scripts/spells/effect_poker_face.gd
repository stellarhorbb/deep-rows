## Sortilège "Poker Face" : chaque jeton qui score a 10% de chance de voir sa
## valeur augmentée de +1 dans le deck (même effet que l'action "Augmenter"
## des Dés à coudre, mais auto-déclenchée). Le tirage et l'animation ont lieu
## en direct dans la résolution (voir CascadeResolver._roll_upgrades,
## GridVisual._animate_upgrade) — ce sortilège se contente de poser la chance,
## il ne décide plus rien après coup.
## Trigger : on_round_start
extends SpellEffect

const PROC_CHANCE: float = 0.1


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.set_token_upgrade_chance(&"poker_face", PROC_CHANCE)
