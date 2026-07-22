## Badge Legendaire "Sacre" : chaque figure (Valet/Chevalier/Dame/Roi) dans un
## groupe qui score ajoute +1.0 au multiplicateur de CE groupe — meme
## mecanisme que "Petites Mains" (add_value_bonus_multiplier), applique aux 4
## valeurs de GameRules.FACE_CARD_VALUES au lieu d'une seule.
## Trigger : on_round_start
extends BadgeEffect

const BONUS_PER_FIGURE: float = 1.0


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	for value in GameRules.FACE_CARD_VALUES:
		run_manager.add_value_bonus_multiplier(value, BONUS_PER_FIGURE, &"sacre")
