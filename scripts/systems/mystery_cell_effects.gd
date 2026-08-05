## Catalogue des effets de case mystere. Recentre sur la grille/le jeton en
## session 27 (retire les effets economiques -- mouches/cible -- diagnostiques
## comme detaches du geste, voir docs/brainstorms/brainstorm-geste-central.md
## et le log de session pour l'echange complet). Ratio bonus/malus pondere
## par palier vise ~70/30 -- volontairement genereux pour que chasser une
## case mystere reste un vrai attrait, jamais une pièce de monnaie neutre.
## Le Jackpot reste TOUJOURS bonus (jamais de "jackpot malus", ca n'a aucun
## sens pour un joueur).
##
## Malus retenus : uniquement ceux qui n'annulent jamais une decision de
## placement deja prise (contrairement a Mutation de famille/Teleportation,
## retirees du pool -- le retour du user est net : "j'ai jamais aime tomber
## dessus", parce que ca revient sur un choix deja fait plutot que d'ajouter
## un obstacle avec lequel composer). Petrification en particulier ne mute
## JAMAIS le jeton du joueur -- voir GridManager.petrify_below.
##
## Meme esprit que BossMalusManager : un enum + un pool + un taux fixe par
## palier (GameRules.MYSTERY_RARITY_RATES), pas par item.
class_name MysteryCellEffects
extends RefCounted

enum Type {
	VALUE_UP,          # +1 valeur sur le jeton pose
	HOLE_REMOVE,       # comble un trou existant ailleurs sur la grille
	VALUE_DOWN,        # -1 valeur sur le jeton pose (plancher TOKEN_MIN_VALUE)
	LOCK,              # verrouille le jeton pose contre toute mutation future
	FUSION,            # fusionne le jeton pose avec un voisin adjacent
	ROCK_FREED,        # convertit un Rock adjacent en jeton de base
	MULTI_X2,          # pose un modifier x2 permanent sur la case
	MULTI_X5,          # pose un modifier x5 permanent sur la case
	PETRIFICATION,     # un Rock apparait SOUS le jeton pose, qui monte d'une row
	MODIFIER_HALF,     # pose un modifier x0.5 permanent sur la case
	JACKPOT_MULTI_X10, # pose un modifier x10 permanent sur la case
}

const LABELS: Dictionary = {
	Type.VALUE_UP: "VALEUR EN HAUSSE",
	Type.HOLE_REMOVE: "TROU REBOUCHE",
	Type.VALUE_DOWN: "VALEUR EN BAISSE",
	Type.LOCK: "JETON VERROUILLE",
	Type.FUSION: "FUSION SPONTANEE",
	Type.ROCK_FREED: "PIERRE LIBEREE",
	Type.MULTI_X2: "MULTIPLICATEUR x2",
	Type.MULTI_X5: "MULTIPLICATEUR x5",
	Type.PETRIFICATION: "PETRIFICATION",
	Type.MODIFIER_HALF: "MODIFICATEUR x0.5",
	Type.JACKPOT_MULTI_X10: "JACKPOT DE MULTI",
}

const DESCRIPTIONS: Dictionary = {
	Type.VALUE_UP: "Augmente la valeur du jeton pose de %d." % GameRules.MYSTERY_VALUE_DELTA,
	Type.HOLE_REMOVE: "Comble un trou existant ailleurs.",
	Type.VALUE_DOWN: "Diminue la valeur du jeton pose de %d." % GameRules.MYSTERY_VALUE_DELTA,
	Type.LOCK: "Verrouille le jeton pose contre toute mutation future.",
	Type.FUSION: "Fusionne le jeton pose avec un voisin adjacent.",
	Type.ROCK_FREED: "Un Rock adjacent devient un jeton de base.",
	Type.MULTI_X2: "Cette case multiplie desormais tout pattern qui la traverse par x2.",
	Type.MULTI_X5: "Cette case multiplie desormais tout pattern qui la traverse par x5.",
	Type.PETRIFICATION: "Un Rock surgit sous le jeton pose, qui remonte d'une case.",
	Type.MODIFIER_HALF: "Cette case divise desormais tout pattern qui la traverse par 2.",
	Type.JACKPOT_MULTI_X10: "Cette case multiplie desormais tout pattern qui la traverse par x10 !",
}

## Index = palier (0 Commun, 1 Rare, 2 Jackpot), meme indexation que
## GameRules.MYSTERY_RARITY_RATES. Repartition bonus/malus par palier :
## Commun 2B/1M, Rare 5B/2M, Jackpot 1B/0M -- ratio global pondere ~70/30.
const TIERS: Array[Array] = [
	[Type.VALUE_UP, Type.HOLE_REMOVE, Type.VALUE_DOWN],
	[
		Type.LOCK, Type.FUSION, Type.ROCK_FREED, Type.MULTI_X2, Type.MULTI_X5,
		Type.PETRIFICATION, Type.MODIFIER_HALF,
	],
	[Type.JACKPOT_MULTI_X10],
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
