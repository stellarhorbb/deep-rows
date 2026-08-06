## Sortilège "Renaissance" : GameRules.RENAISSANCE_CHANCE (1/3) qu'un jeton
## corrompu par la Colonne Convoitée soit reinsere dans le stream de la
## manche en cours (DeckManager.insert_random) plutot que de devoir attendre
## la manche suivante. Comme Fenêtre Longue/Favoritisme, son effet ne passe
## pas par apply() -- TurnController.play_current_to verifie directement
## has_spell(&"renaissance") au moment de la corruption.
## Trigger : on_round_start (non utilise, voir ci-dessus)
extends SpellEffect


func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
