## Item vendable au shop. Type TAG ou SPECIAL, avec payload correspondant.
class_name ShopItem
extends Resource

enum ItemType { TAG, SPECIAL }

@export var item_type: ItemType = ItemType.TAG
@export var label: String = ""
@export var price: int = 0

# Utilise si item_type == TAG
@export var tag_data: PatternData = null

# Utilise si item_type == SPECIAL
@export var special_type: TokenData.SpecialType = TokenData.SpecialType.NONE
