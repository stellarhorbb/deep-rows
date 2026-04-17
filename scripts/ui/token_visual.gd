class_name TokenVisual

## Mapping famille -> sprite path
const FAMILY_SPRITES: Dictionary = {
	TokenData.Family.CORAL: "res://assets/tokens/coral_",
	TokenData.Family.SHELL: "res://assets/tokens/shell_",
	TokenData.Family.RUST: "res://assets/tokens/rust_",
}

const ROCK_SPRITE_PATH: String = "res://assets/tokens/rock.png"

const SPECIAL_SPRITES: Dictionary = {
	TokenData.SpecialType.FANTOME: "res://assets/special-tokens/ghost.png",
	TokenData.SpecialType.BOMBE: "res://assets/special-tokens/bomb.png",
	TokenData.SpecialType.MAREE: "res://assets/special-tokens/tide.png",
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
			var prefix: String = FAMILY_SPRITES.get(token.family, "") as String
			if prefix.is_empty():
				return ""
			return prefix + str(token.value) + ".png"
		TokenData.Kind.ROCK:
			return ROCK_SPRITE_PATH
		TokenData.Kind.SPECIAL:
			return SPECIAL_SPRITES.get(token.special_type, "") as String
		TokenData.Kind.RESIDUE:
			# Pas de sprite pour le residu — on le dessine par code
			return ""
	return ""
