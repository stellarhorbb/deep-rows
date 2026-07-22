## Badge Legendaire "Souffle Obscur" : au Dernier Souffle, une deuxieme vague
## fait disparaitre aussi les entity-skulls (seul obstacle normalement
## permanent du jeu) avant de declarer la defaite. Contrairement aux autres
## Badges, son effet ne passe pas par apply() — TurnController._on_
## resolution_complete verifie directement RunManager.has_badge(&"souffle_
## obscur") au moment de decider si la manche est perdue. Meme convention que
## "Econome"/"Dresseur Fou".
## Trigger : on_round_start (non utilise, voir ci-dessus)
extends BadgeEffect


func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
