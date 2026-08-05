## Sortilège "Quitte ou Double" : chaque groupe qui score joue GameRules.
## QUITTE_OU_DOUBLE_CHANCE (50/50) a pile ou face -- double son score, ou le
## remet a zero. Comme Dresseur Fou/Pierre de Famille, son effet ne passe pas
## par apply() -- RunContext.has_quitte_ou_double (alimente directement
## depuis RunManager.has_spell dans build_context) est lu par CascadeResolver.
## _apply_score_gambles a chaque groupe score.
## Trigger : on_round_start (non utilise, voir ci-dessus)
extends SpellEffect


func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
