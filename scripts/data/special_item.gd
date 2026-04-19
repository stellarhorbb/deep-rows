## Item special vendable au shop (bombe, fantome, maree...).
## Les Pattern Tags portent leurs label + price directement sur PatternData —
## SpecialItem n'est utilise que pour les jetons speciaux.
class_name SpecialItem
extends Resource

@export var label: String = ""
@export var price: int = 0
@export var special_type: TokenData.SpecialType = TokenData.SpecialType.NONE
