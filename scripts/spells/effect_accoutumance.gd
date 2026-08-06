## Sortilège "Accoutumance" : reduit le risque affiche/reel de la Colonne
## Convoitée de GameRules.ACCOUTUMANCE_PER_SKULL par entity-skull
## actuellement present sur la grille -- plus le chaos s'accumule, plus les
## prochains paris redeviennent surs. Comme Fenêtre Longue, son effet ne
## passe pas par apply() -- EntityManager._cursed_column_chance verifie
## directement has_spell(&"accoutumance").
## Trigger : on_round_start (non utilise, voir ci-dessus)
extends SpellEffect


func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
