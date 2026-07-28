class_name TokenVisual

## Mapping famille -> sprite (sans points ; la valeur est affichee en texte par-dessus).
## Arcanes mineurs (session 18) — remplace les sprites coral/shell/rust/ink-nude.
const FAMILY_SPRITES: Dictionary = {
	TokenData.Family.BATONS: "res://assets/tokens/tarot/batons.png",
	TokenData.Family.COUPES: "res://assets/tokens/tarot/coupes.png",
	TokenData.Family.EPEES: "res://assets/tokens/tarot/epees.png",
	TokenData.Family.DENIERS: "res://assets/tokens/tarot/deniers.png",
}

const ROCK_SPRITE_PATH: String = "res://assets/tokens/rock.png"

const SPECIAL_SPRITES: Dictionary = {
	TokenData.SpecialType.FANTOME: "res://assets/special-tokens/ghost.png",
	TokenData.SpecialType.BOMBE: "res://assets/special-tokens/bomb.png",
	TokenData.SpecialType.MAREE: "res://assets/special-tokens/tide.png",
	TokenData.SpecialType.ENCLUME: "res://assets/special-tokens/enclume.png",
	# Sprite neutre pour le stream/hold, avant qu'il soit pose (voir
	# TokenVisual.get_texture, utilise par StreamUI). Une fois pose sur la
	# grille, GridVisual._create_sprite bascule sur le sprite a countdown
	# clignotant rouge/noir (_setup_countdown_sprite), meme traitement que
	# l'entity-skull de MÈCHE COURTE.
	TokenData.SpecialType.PETARD_A_MECHE: "res://assets/special-tokens/petard.png",
	TokenData.SpecialType.CAVALIER: "res://assets/special-tokens/cavalier.png",
	TokenData.SpecialType.FROG: "res://assets/special-tokens/frog.png",
	TokenData.SpecialType.LIANE: "res://assets/special-tokens/liane.png",
	TokenData.SpecialType.CROW: "res://assets/special-tokens/crow.png",
	TokenData.SpecialType.UNDERGROUND: "res://assets/special-tokens/underground.png",
	TokenData.SpecialType.HYPERCUBE: "res://assets/special-tokens/hypercube.png",
	TokenData.SpecialType.ARMAGEDDON: "res://assets/special-tokens/arma.png",
}

## Cache de textures chargees
static var _cache: Dictionary = {}


static func get_texture(token: TokenData) -> Texture2D:
	var path: String = _get_path(token)
	if path.is_empty():
		return null

	if _cache.has(path):
		return _cache[path] as Texture2D

	var tex: Texture2D = load(path) as Texture2D
	if tex != null:
		_cache[path] = tex
	return tex


static func _get_path(token: TokenData) -> String:
	match token.kind:
		TokenData.Kind.BASE:
			return FAMILY_SPRITES.get(token.family, "") as String
		TokenData.Kind.ROCK:
			return ROCK_SPRITE_PATH
		TokenData.Kind.SPECIAL:
			return SPECIAL_SPRITES.get(token.special_type, "") as String
		TokenData.Kind.RESIDUE:
			# Pas de sprite pour le residu — on le dessine par code
			return ""
	return ""
