## Sortilège "Couronne" : chaque Roi (K) present dans une figure qui score ajoute
## +100% au multiplicateur de cette figure (comptage par figure, meme
## mecanisme que "Petites Mains" sur la valeur 1). Description reformulee en %
## (session 28, +1.0 -> +100%) pour rester lisible a cote des vrais
## multiplicateurs compounding (Colonne Convoitée/Fenêtre Longue) -- ADDITIF
## entre plusieurs Rois, pas multiplicatif : 2 Rois donnent +200% (x3 au
## total), pas x4.
## Trigger : on_round_start
extends SpellEffect

const BONUS_PER_KING: float = 1.0


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	run_manager.add_value_bonus_multiplier(GameRules.FACE_CARD_VALUES[3], BONUS_PER_KING, &"couronne")
