## Texte de description au hover d'un jeton — partage entre StreamUI (current/
## hold/preview) et GridHoverUI (grille), pour ne pas dupliquer la logique
## famille/valeur/special (session 23). Lit uniquement TokenData + le
## catalogue des Speciaux (labels/descriptions deja ecrites pour le shop) —
## aucune dependance au rendu visuel (TokenVisual/sprites), donc valable tel
## quel une fois les illustrations finales importees : seul TokenVisual
## changera (chemins de texture), jamais ce fichier.
class_name TokenTooltip
extends RefCounted


static func describe(token: TokenData) -> String:
	match token.kind:
		TokenData.Kind.BASE:
			return "%s — %s" % [TokenData.family_label(token.family), TokenData.value_label(token.value)]
		TokenData.Kind.ROCK:
			return "ROCK — ne score pas"
		TokenData.Kind.SPECIAL:
			var item: SpecialItem = RunService.shop_manager.get_special_item(token.special_type)
			if item != null:
				return "%s — %s" % [item.label, item.description]
			return TokenData.special_type_label(token.special_type)
		_:
			return ""
