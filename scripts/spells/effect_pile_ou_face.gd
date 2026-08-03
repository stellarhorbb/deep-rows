## Sortilège "Pile ou Face" : au drop d'un jeton de base (hors figures), 10%
## de chance de déclencher un mini pile ou face — pile : +5 de valeur
## (plafonné à MAX_BUTTON_VALUE) ; face : devient un Rock pour la manche.
## Mutation directe de l'objet déjà posé sur la grille (même référence que
## GridManager._grid) -- un Rock est déjà exclu de la persistance entre
## manches par nature, pas besoin de flag temporaire (contrairement à
## Cristal/Diamant qui vont dans l'autre sens).
## Trigger : on_token_drop
extends SpellEffect

const TRIGGER_CHANCE: float = 0.1
const VALUE_BONUS: int = 5


func apply(event: Dictionary, _run_manager: RunManager) -> void:
	var token: TokenData = event.get("token") as TokenData
	if token == null or token.kind != TokenData.Kind.BASE:
		return
	# Les figures (Valet+) restent hors de portee -- jamais touchees par un
	# systeme d'economie/gamble, seulement par le score reel.
	if token.value >= GameRules.MAX_BUTTON_VALUE:
		return
	if randf() >= TRIGGER_CHANCE:
		return
	if randi() % 2 == 0:
		token.value = min(token.value + VALUE_BONUS, GameRules.MAX_BUTTON_VALUE)
	else:
		token.kind = TokenData.Kind.ROCK
