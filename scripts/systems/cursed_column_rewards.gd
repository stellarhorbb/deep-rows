## Catalogue des recompenses de la Colonne Convoitée (remplace l'axe casino
## "roulette" de session 25 en session 27, meme catalogue, juste retarget sur
## le geste central) — voir EntityManager.roll_reward et
## docs/gdd/manche/roulette-casino.md (a renommer/reprendre). Meme principe a
## deux temps que MysteryCellEffects (GameRules.CURSED_COLUMN_RARITY_RATES) :
## palier tire a taux fixe, mais ICI pas de tirage uniforme sur une liste
## d'effets varies -- volontairement reduit a 2 familles coherentes
## (Multiplicateur / Boost), la rarete ne changeant jamais que l'ampleur
## ("juste le nombre"), jamais la mecanique elle-meme.
class_name CursedColumnRewards
extends RefCounted

enum Tier { COMMUN, RARE, LEGENDAIRE }
enum Family { MULTI, BOOST }


## `skull_chance` : le % de corruption affiche sur la Colonne Convoitée au
## moment du drop (voir EntityManager.roll_reward) -- plus il est haut, plus
## le palier Legendaire devient probable en retour (voir _scaled_rates), pour
## qu'une colonne qui semble insensee (80%+) reste un vrai pari plutot qu'un
## choix a fuir systematiquement des qu'elle depasse un seuil de confort.
static func roll_tier(skull_chance: float) -> Tier:
	var rates: Array[float] = _scaled_rates(skull_chance)
	var roll: float = randf()
	var cumulative: float = 0.0
	for i in range(rates.size()):
		cumulative += rates[i]
		if roll < cumulative:
			return i as Tier
	return Tier.COMMUN


## Taux du palier Legendaire seul, expose pour EntityManager.get_cursed_
## column_jackpot_chance (hover, voir GridHoverUI) -- evite de dupliquer
## _scaled_rates cote appelant.
static func legendary_rate(skull_chance: float) -> float:
	return _scaled_rates(skull_chance)[Tier.LEGENDAIRE]


## Multiplicatif, pas additif (session 27, retour user), sur le CARRE du
## risque plutot que le risque lui-meme (retune session 28, retour user :
## "75% de skull, 16% de Jackpot conditionnel, ca fait pas assez") -- x1 au
## risque le plus bas, jusqu'a GameRules.CURSED_COLUMN_JACKPOT_MULTIPLIER_MAX
## au risque maximal (skull_chance = 100%). Le carre garde le bas de la
## courbe quasi inchange (30% de risque minimum -> encore ~14% de Jackpot
## conditionnel, contre ~9,5% avant) mais fait exploser le haut (75% -> ~58%
## au lieu de 16%, 100% -> Jackpot garanti si le drop passe) -- une vraie
## montee tardive plutot qu'une droite, sans les deux pools/branches que le
## user proposait au depart. Reglait aussi un defaut structurel trouve en le
## calculant : avec l'ancienne courbe lineaire, la VRAIE probabilite absolue
## de toucher le Jackpot (skull_chance pris en compte) culminait a 33% de
## risque puis redescendait -- viser 75%+ etait donc mathematiquement une
## MAUVAISE strategie malgre le nom "plus de risque, plus de jackpot". Avec
## le carre, ce pic remonte vers ~63% de risque, bien plus proche de la
## promesse du systeme. Commun/Rare se retassent proportionnellement a leur
## poids de base pour compenser la place prise par Legendaire.
static func _scaled_rates(skull_chance: float) -> Array[float]:
	var base: Array[float] = GameRules.CURSED_COLUMN_RARITY_RATES
	var multiplier: float = 1.0 + (GameRules.CURSED_COLUMN_JACKPOT_MULTIPLIER_MAX - 1.0) * skull_chance * skull_chance
	var legendary: float = minf(base[2] * multiplier, 1.0)
	var remaining: float = 1.0 - legendary
	var common_share: float = base[0] / (base[0] + base[1])
	var common: float = remaining * common_share
	var rare: float = remaining - common
	return [common, rare, legendary]


## 50/50 entre les deux familles, independant du palier -- le palier decide
## uniquement l'ampleur (multi_value/boosted_value ci-dessous), pas quelle
## famille sort.
static func roll_family() -> Family:
	return Family.MULTI if randf() < 0.5 else Family.BOOST


static func multi_value(tier: Tier) -> float:
	return GameRules.CURSED_COLUMN_MULTI_VALUES[tier]


## Valeur finale d'un jeton apres Boost (retune session 28) -- Commun/Rare
## restent additifs (GameRules.CURSED_COLUMN_BOOST_VALUES), Legendaire
## devient multiplicatif (GameRules.CURSED_COLUMN_JACKPOT_VALUE_MULTIPLIER)
## pour rendre le risque proportionnel a l'enjeu plutot qu'un plafond plat.
## Plafonne a MAX_BUTTON_VALUE dans tous les cas -- les figures restent
## exclusivement accessibles par le score reel, jamais offertes gratuitement.
static func boosted_value(tier: Tier, pre_value: int) -> int:
	if tier == Tier.LEGENDAIRE:
		return mini(int(pre_value * GameRules.CURSED_COLUMN_JACKPOT_VALUE_MULTIPLIER), GameRules.MAX_BUTTON_VALUE)
	return mini(pre_value + GameRules.CURSED_COLUMN_BOOST_VALUES[tier], GameRules.MAX_BUTTON_VALUE)
