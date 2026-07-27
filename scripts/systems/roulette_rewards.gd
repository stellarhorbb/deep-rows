## Catalogue des recompenses de la roulette (session 25, axe casino) — voir
## RouletteManager._trigger_roulette et docs/gdd/manche/roulette-casino.md.
## Meme principe a deux temps que MysteryCellEffects (GameRules.ROULETTE_
## RARITY_RATES) : palier tire a taux fixe, mais ICI pas de tirage uniforme
## sur une liste d'effets varies -- volontairement reduit a 2 familles
## coherentes (Multiplicateur / Frog), la rarete ne changeant jamais que
## l'ampleur ("juste le nombre"), jamais la mecanique elle-meme.
class_name RouletteRewards
extends RefCounted

enum Tier { COMMUN, RARE, LEGENDAIRE }
enum Family { MULTI, FROG }

const TIER_LABELS: Dictionary = {
	Tier.COMMUN: "COMMUN",
	Tier.RARE: "RARE",
	Tier.LEGENDAIRE: "LÉGENDAIRE",
}


static func roll_tier() -> Tier:
	var rates: Array[float] = GameRules.ROULETTE_RARITY_RATES
	var roll: float = randf()
	var cumulative: float = 0.0
	for i in range(rates.size()):
		cumulative += rates[i]
		if roll < cumulative:
			return i as Tier
	return Tier.COMMUN


## 50/50 entre les deux familles, independant du palier -- le palier decide
## uniquement l'ampleur (multi_value/frog_count ci-dessous), pas quelle
## famille sort.
static func roll_family() -> Family:
	return Family.MULTI if randf() < 0.5 else Family.FROG


static func multi_value(tier: Tier) -> float:
	return GameRules.ROULETTE_MULTI_VALUES[tier]


static func frog_count(tier: Tier) -> int:
	return randi_range(GameRules.ROULETTE_FROG_MIN_COUNTS[tier], GameRules.ROULETTE_FROG_MAX_COUNTS[tier])


static func tier_label(tier: Tier) -> String:
	return TIER_LABELS.get(tier, "") as String
