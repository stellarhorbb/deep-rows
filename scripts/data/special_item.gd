## Item special vendable au shop (bombe, fantome, maree...).
## Les Sheets portent leurs label + price directement sur SheetData —
## SpecialItem n'est utilise que pour les jetons speciaux.
class_name SpecialItem
extends Resource

enum Rarity { COMMON, UNCOMMON, RARE, EPIC }

@export var label: String = ""
@export var description: String = ""
@export var price: int = 0
@export var rarity: Rarity = Rarity.COMMON
@export var special_type: TokenData.SpecialType = TokenData.SpecialType.NONE

## DEBUG : si true, ce special est auto-ajoute au deck a chaque manche.
## Utile pour tester l'effet d'un special en boucle sans passer par le shop.
## A laisser a false pour un run normal.
@export var debug_always_in_deck: bool = false
