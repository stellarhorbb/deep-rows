class_name TokenData
extends RefCounted

enum Kind { BASE, ROCK, RESIDUE, SPECIAL, ENTITY }
## Familles renommees session 18 sur le vocabulaire tarot (arcanes mineurs) —
## remplace CORAL/SHELL/RUST/INK. Ordre d'enum inchange pour ne pas perturber
## les entiers stockes (ex: target_family dans les .tres de Des a coudre).
enum Family { BATONS, COUPES, EPEES, DENIERS }
## ARMAGEDDON (session 25) ajoute a la fin — jamais inserer un SpecialType au
## milieu, les .tres de la famille explosifs/Des a coudre referencent ces
## index par entier brut (special_type = N), un decalage romprait tout.
enum SpecialType { NONE, FANTOME, BOMBE, MAREE, ENCLUME, PETARD_A_MECHE, CAVALIER, FROG, LIANE, CROW, UNDERGROUND, HYPERCUBE, ARMAGEDDON, CRISTAL, DIAMANT, COMETE, AMPLIFICATEUR, SIPHON }

var kind: Kind = Kind.BASE
var family: Family = Family.BATONS
## Fige la valeur d'un jeton contre toute mutation future -- promotion en
## figure meme s'il rescore, ou Boost de la roulette (voir RunManager.
## lock_button, action "Fixer" des Des a coudre). Marche aussi bien sur une
## figure (Valet+) que sur une valeur normale (retune : initialement limite
## aux figures, elargi suite a un retour playtest sur le Boost qui pouvait
## ruiner une valeur precise construite au dé a coudre).
var locked: bool = false
var value: int = 1
var special_type: SpecialType = SpecialType.NONE

## Compteur generique pour tout jeton dont l'effet se joue sur plusieurs
## tours : nombre de tours avant explosion (entity-skull du malus MÈCHE
## COURTE, special PETARD_A_MECHE), nombre de deplacements/croissances
## restants (CAVALIER, FROG, LIANE — tete uniquement, voir GridManager.
## tick_mobile_specials), ou etat idle/actif (CROW). -1 = pas de countdown
## (malus inactif, jeton non concerne, ou segment de corps de LIANE).
var countdown: int = -1

## Vrai pour un jeton a countdown/mobile qui vient d'etre pose CE TOUR-CI
## (voir GridManager._place_persistent_special) — les fonctions de tick
## (tick_special_countdowns, tick_mobile_specials) sautent son tour de jeu
## et remettent ce flag a false, pour qu'il n'agisse/ne decompte qu'a partir
## du PROCHAIN jeton joue, jamais des le tour ou il est pose (les deux
## fonctions de tick tournent juste apres le drop, dans le meme appel).
var just_placed: bool = false

## Vrai pour un jeton de base cree par Cristal/Diamant (conversion d'un Rock
## "pour la manche", voir SpecialEffects.execute_cristal_diamant) — s'il ne
## score jamais avant la fin de la manche, il ne persiste pas a la manche
## suivante (voir GridManager.get_top_base_tokens) : redevient un Rock,
## comme s'il n'avait jamais ete converti.
var temporary: bool = false


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
static func value_label(token_value: int) -> String:
	var idx: int = GameRules.FACE_CARD_VALUES.find(token_value)
	if idx >= 0:
		return GameRules.FACE_CARD_LABELS[idx]
	return str(token_value)


static func special_type_label(t: SpecialType) -> String:
	match t:
		SpecialType.FANTOME:        return "FANTOME"
		SpecialType.BOMBE:          return "BOMBE"
		SpecialType.MAREE:          return "MAREE"
		SpecialType.ENCLUME:        return "ENCLUME"
		SpecialType.PETARD_A_MECHE: return "PÉTARD À MÈCHE"
		SpecialType.CAVALIER:       return "CAVALIER"
		SpecialType.FROG:           return "FROG"
		SpecialType.LIANE:          return "LIANE"
		SpecialType.CROW:           return "CROW"
		SpecialType.UNDERGROUND:    return "UNDERGROUND"
		SpecialType.HYPERCUBE:      return "HYPERCUBE"
		SpecialType.ARMAGEDDON:     return "ARMAGEDDON"
		SpecialType.CRISTAL:        return "CRISTAL"
		SpecialType.DIAMANT:        return "DIAMANT"
		SpecialType.COMETE:         return "COMÈTE"
		SpecialType.AMPLIFICATEUR:  return "AMPLIFICATEUR"
		SpecialType.SIPHON:         return "SIPHON"
		_:                          return "?"
