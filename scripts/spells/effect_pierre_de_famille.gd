## Sortilège "Pierre de Famille" : un Rock compte comme n'importe quelle
## famille manquante pour compléter un groupe rule="family". Comme Dresseur
## Fou (mobiles_never_expire), son effet ne passe pas par apply() --
## RunManager.build_context() vérifie directement has_spell(&"pierre_de_
## famille") pour poser RunContext.rock_wildcard_family, lu par
## CascadeResolver._apply_rock_wildcard.
## Trigger : on_round_start (non utilisé, voir ci-dessus)
extends SpellEffect


func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
