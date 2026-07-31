## Sortilège Legendaire "Dresseur Fou" : les speciaux mobiles (Cavalier/Frog/
## Liane/Underground) ne disparaissent plus jamais. Contrairement aux autres
## Sortilèges, son effet ne passe pas par apply() — RunContext.mobiles_
## never_expire (alimente directement depuis RunManager.has_spell dans
## build_context) est lu par GridManager.tick_mobile_specials a chaque tick.
## Le trigger ci-dessous n'est donc jamais reellement exploite, meme
## convention que "Econome" — juste une valeur valide pour SpellData.
## Trigger : on_round_start (non utilise, voir ci-dessus)
extends SpellEffect


func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass
