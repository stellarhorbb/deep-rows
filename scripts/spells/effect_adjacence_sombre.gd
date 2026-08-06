## Sortilège "Adjacence Sombre" : chaque Partition qui score gagne un
## multiplicateur LOCAL (pas un global_multiplier) de GameRules.
## ADJACENCE_SOMBRE_PER_SKULL par entity-skull adjacent orthogonalement a
## une de ses cellules. Comme Echo/Quitte ou Double, son effet ne passe pas
## par apply() -- RunContext.has_adjacence_sombre (alimente directement
## depuis RunManager.has_spell dans build_context) est lu par
## CascadeResolver._score_group via _count_adjacent_skulls.
## Trigger : on_round_start (non utilise, voir ci-dessus)
extends SpellEffect


func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
