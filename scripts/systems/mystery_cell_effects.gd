## Catalogue des effets de case mystere (session 24, axe casino) — voir
## GridManager.generate_random_mystery_cells/mystery_cell_triggered et
## TurnController._on_mystery_cell_triggered pour la pose/le declenchement.
## Meme esprit que BossMalusManager : un enum + un pool + un taux fixe par
## palier (GameRules.MYSTERY_RARITY_RATES), pas par item (voir _draw_spell_
## queued dans ShopManager pour le meme principe applique aux Sortilèges).
##
## "Fixe le jeton (ignore gravite)" volontairement absent du premier jet —
## seul effet qui toucherait GravitySystem, laisse de cote le temps de voir
## si le concept accroche (voir log de session).
class_name MysteryCellEffects
extends RefCounted

enum Type {
	SCORE_UP,          # cible de score -10% (retune : sur le score actuel, un tirage tot en manche donnait un delta de 0% de rien)
	SCORE_DOWN,        # cible de score +10%
	FLIES_UP_SMALL,    # +1 mouche
	FLIES_UP_BIG,      # +5 mouches
	FLIES_DOWN_SMALL,  # -1 mouche
	FLIES_DOWN_BIG,    # -2 mouches (retune session 25, etait -5)
	HOLE_ADD,          # ajoute un trou ailleurs sur la grille
	HOLE_REMOVE,       # bouche un trou existant ailleurs
	FAMILY_SHUFFLE,    # change le jeton pose en une autre famille aleatoire
	TELEPORT,          # teleporte le jeton pose dans une colonne aleatoire
	MULTI_X2,          # pose un modifier x2 permanent sur la case
	MULTI_X5,          # pose un modifier x5 permanent sur la case
	JACKPOT_FLIES,     # +20 mouches
	JACKPOT_MULTI_X10, # pose un modifier x10 permanent sur la case
}

const LABELS: Dictionary = {
	Type.SCORE_UP: "BONUS CIBLE -10%",
	Type.SCORE_DOWN: "MALUS CIBLE +10%",
	Type.FLIES_UP_SMALL: "MOUCHE TROUVEE",
	Type.FLIES_UP_BIG: "TRESOR DE MOUCHES",
	Type.FLIES_DOWN_SMALL: "MOUCHE PERDUE",
	Type.FLIES_DOWN_BIG: "PIEGE A MOUCHES",
	Type.HOLE_ADD: "TROU EN PLUS",
	Type.HOLE_REMOVE: "TROU REBOUCHE",
	Type.FAMILY_SHUFFLE: "MUTATION TEMPORAIRE",
	Type.TELEPORT: "TELEPORTATION",
	Type.MULTI_X2: "MULTIPLICATEUR x2",
	Type.MULTI_X5: "MULTIPLICATEUR x5",
	Type.JACKPOT_FLIES: "JACKPOT DE MOUCHES",
	Type.JACKPOT_MULTI_X10: "JACKPOT DE MULTI",
}

const DESCRIPTIONS: Dictionary = {
	Type.SCORE_UP: "Diminue la cible de score de %d%%." % int(GameRules.MYSTERY_SCORE_PERCENT * 100),
	Type.SCORE_DOWN: "Augmente la cible de score de %d%%." % int(GameRules.MYSTERY_SCORE_PERCENT * 100),
	Type.FLIES_UP_SMALL: "Gagne %d mouche." % GameRules.MYSTERY_FLIES_SMALL,
	Type.FLIES_UP_BIG: "Gagne %d mouches." % GameRules.MYSTERY_FLIES_BIG_GAIN,
	Type.FLIES_DOWN_SMALL: "Perd %d mouche." % GameRules.MYSTERY_FLIES_SMALL,
	Type.FLIES_DOWN_BIG: "Perd %d mouches." % GameRules.MYSTERY_FLIES_BIG_LOSS,
	Type.HOLE_ADD: "Ouvre un trou ailleurs sur la grille.",
	Type.HOLE_REMOVE: "Comble un trou existant ailleurs.",
	Type.FAMILY_SHUFFLE: "Le jeton change de famille au hasard.",
	Type.TELEPORT: "Le jeton est teleporte dans une colonne au hasard.",
	Type.MULTI_X2: "Cette case multiplie desormais tout pattern qui la traverse par x2.",
	Type.MULTI_X5: "Cette case multiplie desormais tout pattern qui la traverse par x5.",
	Type.JACKPOT_FLIES: "Gagne %d mouches !" % GameRules.MYSTERY_JACKPOT_FLIES,
	Type.JACKPOT_MULTI_X10: "Cette case multiplie desormais tout pattern qui la traverse par x10 !",
}

## Index = palier (0 Commun, 1 Rare, 2 Jackpot), meme indexation que
## GameRules.MYSTERY_RARITY_RATES.
const TIERS: Array[Array] = [
	[Type.SCORE_UP, Type.SCORE_DOWN, Type.FLIES_UP_SMALL, Type.FLIES_DOWN_SMALL],
	[
		Type.FLIES_UP_BIG, Type.FLIES_DOWN_BIG, Type.HOLE_ADD, Type.HOLE_REMOVE,
		Type.FAMILY_SHUFFLE, Type.TELEPORT, Type.MULTI_X2, Type.MULTI_X5,
	],
	[Type.JACKPOT_FLIES, Type.JACKPOT_MULTI_X10],
]


## Tire un effet : palier a taux fixe (GameRules.MYSTERY_RARITY_RATES), puis
## effet uniforme a l'interieur du palier — meme principe a deux temps que
## ShopManager._draw_spell_queued (SPELL_RARITY_RATES), sans la notion de
## file puisqu'il n'y a pas d'enjeu de "deja tire" a eviter ici.
static func pick_random() -> Type:
	var rates: Array[float] = GameRules.MYSTERY_RARITY_RATES
	var roll: float = randf()
	var cumulative: float = 0.0
	for tier in range(rates.size()):
		cumulative += rates[tier]
		if roll < cumulative:
			return TIERS[tier].pick_random() as Type
	return TIERS[0].pick_random() as Type
