## Sortilège "Consolation" : GameRules.CONSOLATION_FLIES mouches fixes
## gagnees a chaque corruption par la Colonne Convoitée -- compense la perte
## du jeton sans l'annuler. Comme Fenêtre Longue/Renaissance, son effet ne
## passe pas par apply() -- TurnController.play_current_to verifie
## directement has_spell(&"consolation") au moment de la corruption.
## Trigger : on_round_start (non utilise, voir ci-dessus)
extends SpellEffect


func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
