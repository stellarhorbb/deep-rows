## Donnees d'un outil de deck ("Des a coudre") : une action de manipulation du
## pool de boutons (voir RunManager). Generalise l'ancienne Fusion seule en une
## vraie rubrique, voir docs/brainstorms/brainstorm-outils-deck.md.
class_name DeckToolData
extends Resource

enum Rarity { COMMON, UNCOMMON, RARE, EPIC }
enum Action { INCREASE, DECREASE, CHANGE_FAMILY, SPLIT, FUSE, REMOVE }

@export var id: StringName = &""
@export var label: String = ""
@export var description: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var action: Action = Action.INCREASE
## Uniquement pertinent pour action == CHANGE_FAMILY.
@export var target_family: TokenData.Family = TokenData.Family.CORAL


## Nombre de jetons cibles a selectionner avant de pouvoir confirmer.
func target_count() -> int:
	return 2 if action == Action.FUSE else 1
