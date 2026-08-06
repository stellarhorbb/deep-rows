## Sortilège "Diadème" : chaque Dame (Q) presente dans une figure qui score
## ajoute +300% au multiplicateur de cette figure (comptage par figure, meme
## mecanisme que "Petites Mains" sur la valeur 1 -- description reformulee en
## % session 28, +3.0 -> +300%, ADDITIF entre plusieurs Dames, pas
## multiplicatif). Bonus plus haut que
## "Couronne" (Roi) : une Dame est plus fragile a conserver, elle peut se
## faire promouvoir en Roi malgre elle, sauf a la Fixer activement — le
## multiplicateur compense ce cout d'opportunite.
## Trigger : on_round_start
extends SpellEffect

const BONUS_PER_QUEEN: float = 3.0


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.add_value_bonus_multiplier(GameRules.FACE_CARD_VALUES[2], BONUS_PER_QUEEN, &"diademe")
