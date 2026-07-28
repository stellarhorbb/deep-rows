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
