## Badge "Bord a Bord" : les 2 colonnes exterieures passent en BOOST dedie
## (x1.2, retune session 25 -- modifier propre pour ne pas affecter Ecume/
## Colonne Chanceuse/Trench qui partagent MODIFIER_BOOST).
## Symetrique de Tranchee, qui favorise le centre.
## Trigger : on_round_start
extends BadgeEffect


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	var cols: int = GameRules.COLS
	var rows: int = GameRules.ROWS
	for c in [0, cols - 1]:
		for r in range(rows):
			run_manager.add_grid_modifier(Vector2i(c, r), GameRules.MODIFIER_BORD_A_BORD)
