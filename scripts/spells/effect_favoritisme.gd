## Sortilège "Favoritisme" : une Fusion prend toujours la famille du jeton de
## la plus haute valeur au lieu du pile ou face habituel. Contrairement aux
## autres Sortilèges, son effet ne passe pas par apply() — la Fusion n'a
## aucun des 6 triggers de manche (rien qui corresponde à "le joueur vient de
## fusionner deux boutons"). RunManager.fuse_buttons vérifie directement
## has_spell(&"favoritisme"). Le trigger ci-dessous n'est donc jamais
## réellement exploité, juste une valeur valide pour SpellData.
## Trigger : on_round_start (non utilisé, voir ci-dessus)
extends SpellEffect


func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
