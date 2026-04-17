class_name TokenData
extends RefCounted

enum Kind { BASE, ROCK, RESIDUE, SPECIAL, ENTITY }
enum Family { CORAL, SHELL, RUST }
enum SpecialType { NONE, FANTOME, BOMBE, MAREE }

var kind: Kind = Kind.BASE
var family: Family = Family.CORAL
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
