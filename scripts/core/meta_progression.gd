## Autoload global. Porte les unlocks du Shore, persistants sur disque entre
## les lancements du jeu — independant de RunService qui ne vit que le temps
## d'une run. Le contenu gate (SheetData.locked, StarterPackData.locked...)
## reste un flag de design statique ; is_unlocked() croise ce flag avec la
## sauvegarde reelle du joueur. Voir docs/gdd/shore/unlocks.md.
extends Node

const SAVE_PATH: String = "user://meta_save.tres"

## DEBUG : bypass total de la sauvegarde, tout contenu verrouille est traite
## comme debloque. Pour tester le jeu au complet sans jouer chaque unlock un
## par un. A false au lancement normal.
var debug_force_unlock_all: bool = false

var _save: MetaSaveData = null


func _ready() -> void:
	_load()


func is_unlocked(id: String) -> bool:
	if debug_force_unlock_all:
		return true
	return _save.unlocked_ids.has(id)


func unlock(id: String) -> void:
	if _save.unlocked_ids.has(id):
		return
	_save.unlocked_ids.append(id)
	_save_to_disk()


## DEBUG : repart d'une sauvegarde vierge, comme un joueur qui n'a encore
## rien debloque.
func reset_save_debug() -> void:
	_save = MetaSaveData.new()
	_save_to_disk()


func _load() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		_save = ResourceLoader.load(SAVE_PATH) as MetaSaveData
	if _save == null:
		_save = MetaSaveData.new()


func _save_to_disk() -> void:
	ResourceSaver.save(_save, SAVE_PATH)
