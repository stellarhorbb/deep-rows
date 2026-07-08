## Bouton qui affiche un badge de rarete colore dans son tooltip (voir
## RarityTooltip) quand `rarity` est assigne. Utilise partout ou le shop
## affiche un PatternData/BadgeData au clic/survol (unitaires, packs,
## selection de Partition de depart).
class_name RarityButton
extends Button

## -1 = pas de rarete connue (Special/Bouton/Des a coudre) -> tooltip texte simple.
var rarity: int = -1


func _make_custom_tooltip(for_text: String) -> Object:
	if rarity < 0:
		return null
	return RarityTooltip.build(for_text, rarity)
