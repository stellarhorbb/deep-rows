## Sortilège "Fenêtre Longue" : la fenêtre de délai pour profiter d'un
## Multiplicateur de la Colonne Convoitée passe de GameRules.CURSED_COLUMN_
## MULTI_DROPS (3) à CURSED_COLUMN_MULTI_DROPS_EXTENDED (5, session 27,
## remplace la roulette). Comme Favoritisme, son effet ne passe pas par
## apply() -- EntityManager._activate_multi vérifie directement
## has_spell(&"fenetre_longue").
## Trigger : on_round_start (non utilisé, voir ci-dessus)
extends SpellEffect


func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
