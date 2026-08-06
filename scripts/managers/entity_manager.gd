## Gere l'intervention de l'Entity (session 27, remplace le double systeme
## skull-ailleurs + roulette de sessions 25-26 -- voir docs/brainstorms/
## brainstorm-geste-central.md). Deux mecanismes bien separes, retunes apres
## un premier playtest (le skull tombait TOUJOURS exactement sur le jeton
## que le joueur venait de choisir, donc systematiquement au pire endroit --
## contrairement a l'ancien systeme, qui touchait une colonne aleatoire et
## avait donc une vraie variance de gravite) :
## - Corruption ambiante : chance croissante et cachee (formule d'avant
##   session 27, voir GameRules.ENTITY_DROP_BASE_CHANCE/INCREMENT), roulee
##   une fois par tour APRES resolution (voir on_turn_resolved), totalement
##   independante du geste du joueur -- retombe sur une colonne aleatoire non
##   pleine, comme avant. Menace de fond subie, pas une consequence de choix.
## - Colonne Convoitée (placeholder) : une colonne signalee, re-tiree a
##   chaque retour en attente d'un coup (meme timing que le malus de boss
##   COLONNE MAUDITE, voir TurnController._reroll_colonne_maudite -- nom
##   distinct choisi expres pour ne pas entrer en collision, l'un bloque,
##   l'autre incite). Y droper est un pari VISIBLE et delibere : risque de
##   corruption plus eleve (ambiant du moment + GameRules.
##   CURSED_COLUMN_SKULL_BONUS, affiche par GridVisual) -- si ca corrompt, le
##   jeton vise n'est jamais consomme (swap, pas destruction, voir
##   TurnController.play_current_to) -- mais recompense ciblee sur CE jeton
##   si ca passe (Multiplicateur des prochains tours, ou Boost immediat de sa
##   valeur). Impact maximal assume ici puisque le joueur a choisi le risque
##   en connaissance de cause -- contrairement a l'ambiant, subi.
class_name EntityManager
extends Node

## Colonne Convoitée re-tiree (voir reroll_cursed_column) -- l'UI (GridVisual)
## s'y abonne pour dessiner l'overlay + le %. skull_chance deja resolu ici
## (pas de re-calcul cote UI, meme discipline que roulette_triggered avant).
signal cursed_column_changed(col: int, skull_chance: float)

## Recompense tiree sur un drop reussi dans la Colonne Convoitée -- l'UI
## (banniere) s'y abonne pour l'annonce, differee jusqu'apres le score du
## tour (meme raison que l'ancienne roulette, voir GameScene).
signal reward_triggered(tier: CursedColumnRewards.Tier, family: CursedColumnRewards.Family, amount: float)

## Multiplicateur actif/expire -- l'UI (indicateur pulsant) s'y abonne.
signal multi_status_changed(active: bool, value: float)

## Boost applique sur la case tout juste dropee -- l'UI (GameScene) s'y
## abonne pour jouer le highlight (GridVisual.animate_boost).
signal token_boosted(cell: Vector2i, token: TokenData)

var grid_manager: GridManager
var run_manager: RunManager

## Malus de boss GRANDE FAIM : double l'ambiant ET la Colonne Convoitée
## (meme intention que l'ancien "intervalle divise par 2").
var drop_chance_multiplier: float = 1.0

var _turns_since_corruption: int = 0
var _cursed_column: int = -1
var _multi_drops_remaining: int = 0


func reset() -> void:
	_turns_since_corruption = 0
	drop_chance_multiplier = 1.0
	_cursed_column = -1
	_multi_drops_remaining = 0


## Re-tire la Colonne Convoitée -- appele par TurnController au round-start
## et apres chaque tour resolu (meme timing que _reroll_colonne_maudite),
## pour qu'un joueur prudent ne puisse pas juste l'ignorer indefiniment sur
## la meme case.
func reroll_cursed_column() -> void:
	_cursed_column = _pick_random_col()
	var chance: float = _cursed_column_chance() if _cursed_column >= 0 else 0.0
	cursed_column_changed.emit(_cursed_column, chance)


func get_cursed_column() -> int:
	return _cursed_column


## Detail du pari pour le hover (voir GridHoverUI) -- recalcule a la demande,
## pas de cache : les deux dependent uniquement de l'etat courant (compteur
## de dread, multiplicateur de boss), aucun interet a le stocker a part.
func get_cursed_column_skull_chance() -> float:
	return _cursed_column_chance()


## Chance CONDITIONNELLE (si le drop ne corrompt pas) de tomber sur le palier
## Legendaire -- volontairement PAS la chance absolue. L'absolue ((1-skull) x
## legendary_rate) chute mecaniquement vers 0 quand skull_chance approche
## 100% -- il ne reste plus d'espace de recompense du tout -- ce qui afficherait
## un jackpot moins bon a mesure que le risque grimpe, exactement l'inverse
## de l'intention (bug trouve par le user en session 27 : "35% skull pour 7%
## jackpot mais 65% skull pour 5%"). La conditionnelle grimpe bien avec le
## risque, voir CursedColumnRewards.legendary_rate/_scaled_rates.
func get_cursed_column_jackpot_chance() -> float:
	return CursedColumnRewards.legendary_rate(_cursed_column_chance())


## Chance ambiante (cachee, menace de fond) -- croissante depuis le dernier
## skull, voir GameRules.ENTITY_DROP_BASE_CHANCE/INCREMENT.
func _ambient_chance() -> float:
	var increment: float = GameRules.ENTITY_DROP_INCREMENT * drop_chance_multiplier
	return minf(GameRules.ENTITY_DROP_BASE_CHANCE + float(_turns_since_corruption) * increment, 1.0)


## Chance de corruption si le joueur droppe dans la Colonne Convoitée --
## toujours l'ambiant du moment + un bonus (GameRules.CURSED_COLUMN_SKULL_
## BONUS), jamais un taux fixe independant, sinon un ambiant deja monte haut
## (longue serie sans skull) finirait par depasser le "risque eleve" affiche
## sur la colonne, qui doit pourtant rester la pire option. Au niveau de base
## (ambiant 5%, bonus 30%) ca retombe sur 35%, mais les deux grimpent ensemble.
## Sortilège "Accoutumance" (session 28) : si equipe, retranche GameRules.
## ACCOUTUMANCE_PER_SKULL par entity-skull present sur la grille -- plus le
## chaos ambiant s'accumule, plus le prochain pari redevient sur. Plafonne a
## 0, jamais negatif.
func _cursed_column_chance() -> float:
	var chance: float = minf(_ambient_chance() + GameRules.CURSED_COLUMN_SKULL_BONUS * drop_chance_multiplier, 1.0)
	if run_manager.has_spell(&"accoutumance"):
		chance = maxf(chance - GameRules.ACCOUTUMANCE_PER_SKULL * grid_manager.count_entity_skulls(), 0.0)
	return chance


## Jette le de de corruption pour un drop dans la Colonne Convoitée -- voir
## TurnController.play_current_to. true = le jeton du joueur doit etre
## remplace par un skull (swap). Reset le compteur d'ambiance seulement en
## cas de succes -- l'echec n'incremente PAS le compteur ici, c'est le role
## exclusif de on_turn_resolved (sinon un tour joue dans la Colonne Convoitée
## ferait progresser l'ambiant deux fois).
func roll_cursed_column_corruption() -> bool:
	var triggered: bool = randf() < _cursed_column_chance()
	if triggered:
		_turns_since_corruption = 0
	return triggered


## Corruption ambiante (formule d'avant session 27, restauree apres playtest
## -- voir le commentaire de classe) -- appele une fois par tour APRES
## resolution, INDEPENDAMMENT de ce que le joueur vient de droper. Retourne
## la colonne aleatoire touchee, -1 si rien ne se passe ce tour-ci.
func on_turn_resolved() -> int:
	if randf() >= _ambient_chance():
		_turns_since_corruption += 1
		return -1
	_turns_since_corruption = 0
	return _pick_random_col()


## Appele quand le joueur droppe reellement dans la Colonne Convoitée sans
## se faire corrompre -- tire palier + famille, applique Multi (en attente,
## prochains drops) ou Boost (immediat, mutation directe de `token`, DEJA
## place sur `cell` par l'appelant, avant resolution de cascade -- pour
## qu'un Boost puisse completer/upgrader un pattern sur ce meme tour). Le
## palier tient compte du risque assume : voir CursedColumnRewards.roll_tier.
func roll_reward(cell: Vector2i, token: TokenData) -> void:
	var tier: CursedColumnRewards.Tier = CursedColumnRewards.roll_tier(_cursed_column_chance())
	var family: CursedColumnRewards.Family = CursedColumnRewards.roll_family()
	var amount: float = 0.0
	match family:
		CursedColumnRewards.Family.MULTI:
			amount = CursedColumnRewards.multi_value(tier)
			_activate_multi(amount)
		CursedColumnRewards.Family.BOOST:
			var new_value: int = CursedColumnRewards.boosted_value(tier, token.value)
			amount = float(new_value - token.value)
			_apply_boost(cell, token, new_value)
	reward_triggered.emit(tier, family, amount)


func _activate_multi(value: float) -> void:
	run_manager.set_global_multiplier(value, &"colonne_convoitee")
	_multi_drops_remaining = GameRules.CURSED_COLUMN_MULTI_DROPS_EXTENDED if run_manager.has_spell(&"fenetre_longue") else GameRules.CURSED_COLUMN_MULTI_DROPS
	multi_status_changed.emit(true, value)


## Mutation directe du jeton dropé -- jamais un jeton aleatoire ailleurs
## (ancien defaut de la roulette, voir GameRules.CURSED_COLUMN_BOOST_VALUES).
## `new_value` deja calcule et plafonne par CursedColumnRewards.boosted_value
## (additif Commun/Rare, multiplicatif Legendaire -- voir GameRules.
## CURSED_COLUMN_JACKPOT_VALUE_MULTIPLIER). No-op silencieux sur un jeton
## non-base. Banque aussi le gain cote pool possede (RunManager.
## bank_column_boost) AVANT de muter la copie de la grille -- sans ca,
## l'incrementation ne vit que sur cette copie ephemere (voir DeckManager.
## build_deck, copies fraiches a chaque manche) et se perd des que ce jeton
## ne persiste pas jusqu'au sommet de sa colonne en fin de manche (bug trouve
## session 28, meme defaut que l'ancien Boost roulette avant sa fix session
## 25 -- voir RunManager.boost_random_button).
func _apply_boost(cell: Vector2i, token: TokenData, new_value: int) -> void:
	if token.kind != TokenData.Kind.BASE:
		return
	run_manager.bank_column_boost(token.family, token.value, new_value)
	token.value = new_value
	token_boosted.emit(cell, token)


## Decompte/efface le multiplicateur actif -- appele par TurnController juste
## avant turn_resolved.emit. Meme logique que l'ancien RouletteManager.
## _on_turn_resolved : des qu'un tour scoré en profite, il s'efface tout de
## suite (pas de deuxieme coup gratuit), sinon decompte d'1 jusqu'a expiration.
func tick_multi(timeline: Array[Dictionary]) -> void:
	if _multi_drops_remaining <= 0:
		return
	if _turn_scored(timeline):
		_multi_drops_remaining = 0
		run_manager.set_global_multiplier(1.0, &"colonne_convoitee")
		multi_status_changed.emit(false, 1.0)
	else:
		_multi_drops_remaining -= 1
		if _multi_drops_remaining <= 0:
			run_manager.set_global_multiplier(1.0, &"colonne_convoitee")
			multi_status_changed.emit(false, 1.0)


func _turn_scored(timeline: Array[Dictionary]) -> bool:
	for event in timeline:
		if event.get("type") != CascadeResolver.EventType.MATCH:
			continue
		var scores: Array = event.get("scores", []) as Array
		for group_score in scores:
			if (group_score as int) > 0:
				return true
	return false


func _pick_random_col() -> int:
	var available: Array[int] = []
	for c in range(GameRules.COLS):
		if grid_manager.column_height(c) < GameRules.ROWS:
			available.append(c)
	if available.is_empty():
		return -1
	return available[randi() % available.size()]
