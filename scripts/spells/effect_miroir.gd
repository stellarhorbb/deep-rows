## Sortilège "Miroir" : copie la contribution du Sortilège juste à sa gauche
## (canaux génériques de RunContext uniquement — rule/global/value_bonus/
## family/pair/top_row/retrigger/scaling/flat — voir RunManager.mirror_
## spell_contribution pour le détail et la limitation connue : ne fait rien
## si le voisin est un Sortilège "passif" vérifié directement par has_spell()
## ailleurs dans le code). Dernier de la ligne (slot 0, rien à gauche) :
## no-op.
## Trigger : on_round_start
extends SpellEffect


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	var equipped: Array[SpellData] = run_manager.get_equipped_spells()
	var my_index: int = -1
	for i in range(equipped.size()):
		if equipped[i].id == &"miroir":
			my_index = i
			break
	if my_index <= 0:
		return
	var neighbor: SpellData = equipped[my_index - 1]
	run_manager.mirror_spell_contribution(neighbor.id, &"miroir")
