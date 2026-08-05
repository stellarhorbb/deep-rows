## Sortilège "Echo" : chaque groupe qui score a GameRules.ECHO_RETRIGGER_
## CHANCE (15%) de se retrigger, doublant son score. Comme Dresseur Fou/
## Pierre de Famille, son effet ne passe pas par apply() -- RunContext.
## has_echo (alimente directement depuis RunManager.has_spell dans
## build_context) est lu par CascadeResolver._apply_score_gambles a chaque
## groupe score.
## Trigger : on_round_start (non utilise, voir ci-dessus)
extends SpellEffect


func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
