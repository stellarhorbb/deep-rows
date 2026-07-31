## Sortilège "Econome" : un reroll gratuit par visite au shop. Contrairement aux
## autres Sortilèges, son effet ne passe pas par apply() — le shop n'a aucun des
## 6 triggers de manche (rien qui corresponde à "le joueur vient d'ouvrir le
## shop"). ShopUI vérifie directement RunManager.has_spell(&"econome") à
## l'ouverture pour zapper le coût du premier reroll de la visite. Le trigger
## ci-dessous n'est donc jamais réellement exploité, juste une valeur valide
## pour SpellData.
## Trigger : on_round_start (non utilisé, voir ci-dessus)
extends SpellEffect


func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
