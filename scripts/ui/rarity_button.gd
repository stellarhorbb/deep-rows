## Bouton qui affiche un badge de rarete colore dans son tooltip (voir
## RarityTooltip) quand `rarity` est assigne. Utilise partout ou le shop
## affiche un BadgeData/DeckToolData au clic/survol (unitaires, packs).
class_name RarityButton
extends Button

## -1 = pas de rarete connue (Special/Bouton/Partition/selection de Partition
## de depart) -> tooltip texte simple.
var rarity: int = -1


func _make_custom_tooltip(for_text: String) -> Object:
	if rarity < 0:
		return null
	return RarityTooltip.build(for_text, rarity)
