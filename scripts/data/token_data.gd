class_name TokenData
extends RefCounted

enum Kind { BASE, ROCK, RESIDUE, SPECIAL, ENTITY }
## Familles renommees session 18 sur le vocabulaire tarot (arcanes mineurs) —
## remplace CORAL/SHELL/RUST/INK. Ordre d'enum inchange pour ne pas perturber
## les entiers stockes (ex: target_family dans les .tres de Des a coudre).
enum Family { BATONS, COUPES, EPEES, DENIERS }
enum SpecialType { NONE, FANTOME, BOMBE, MAREE }

var kind: Kind = Kind.BASE
var family: Family = Family.BATONS
## Fige une figure (Valet+) contre toute promotion future, meme si elle
## rescore (voir RunManager.lock_button, action "Fixer" des Des a coudre).
## Sans effet sur une valeur normale (< MAX_BUTTON_VALUE).
var locked: bool = false
var value: int = 1
var special_type: SpecialType = SpecialType.NONE


static func make_base(p_family: Family, p_value: int) -> TokenData:
	var token: TokenData = TokenData.new()
	token.kind = Kind.BASE
	token.family = p_family
	token.value = p_value
	return token


static func make_rock() -> TokenData:
	var token: TokenData = TokenData.new()
	token.kind = Kind.ROCK
	return token


static func make_residue() -> TokenData:
	var token: TokenData = TokenData.new()
	token.kind = Kind.RESIDUE
	return token


static func make_special(p_type: SpecialType) -> TokenData:
	var token: TokenData = TokenData.new()
	token.kind = Kind.SPECIAL
	token.special_type = p_type
	return token


static func make_entity() -> TokenData:
	var token: TokenData = TokenData.new()
	token.kind = Kind.ENTITY
	return token


func is_scorable() -> bool:
	return kind == Kind.BASE


static func family_label(f: Family) -> String:
	match f:
		Family.BATONS:  return "BÂTONS"
		Family.COUPES:  return "COUPES"
		Family.EPEES:   return "ÉPÉES"
		Family.DENIERS: return "DENIERS"
		_:              return "?"


## Affiche le nom de la figure (Valet/Chevalier/Reine/Roi) au lieu du chiffre
## brut pour les valeurs >= MAX_BUTTON_VALUE + 1, sinon le chiffre tel quel.
static func value_label(value: int) -> String:
	var idx: int = GameRules.FACE_CARD_VALUES.find(value)
	if idx >= 0:
		return GameRules.FACE_CARD_LABELS[idx]
	return str(value)


static func special_type_label(t: SpecialType) -> String:
	match t:
		SpecialType.FANTOME: return "FANTOME"
		SpecialType.BOMBE:   return "BOMBE"
		SpecialType.MAREE:   return "MAREE"
		_:                   return "?"
