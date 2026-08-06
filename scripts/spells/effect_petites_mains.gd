## Sortilège "Petites Mains" : chaque jeton de valeur 1 present dans une figure
## qui score ajoute +50% au multiplicateur de cette figure (comptage par
## figure, pas cumule sur le tour entier -- description reformulee en %
## session 28, +0.5 -> +50%, ADDITIF entre plusieurs jetons, pas
## multiplicatif).
## Trigger : on_round_start
extends SpellEffect

const BONUS_VALUE: int = 1
const BONUS_PER_TOKEN: float = 0.5


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.add_value_bonus_multiplier(BONUS_VALUE, BONUS_PER_TOKEN, &"petites_mains")
