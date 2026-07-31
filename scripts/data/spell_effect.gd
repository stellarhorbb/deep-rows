## Base class pour les effets de sortilèges. Chaque sortilège a son propre script derive.
## Instancie et appele par SpellManager quand le trigger correspondant se declenche.
class_name SpellEffect
extends RefCounted


## Applique l'effet. A override dans les scripts concrets.
## event : Dictionary specifique au trigger (ex: { "cascade_level": 0, "earned": 50 })
## run_manager : accessible pour muter flies, grid_modifiers, rule_multipliers, etc.
func apply(_event: Dictionary, _run_manager: RunManager) -> void:
	pass


## Texte de progression optionnel affiche au survol du sortilège (ex: "2/3 tours
## sans cascade"). Chaine vide si le sortilège n'a rien a afficher (comportement
## par defaut). A override par les sortilèges a compteur/condition, qui lisent
## leur etat via run_manager.get_spell_state().
func get_progress_text(_run_manager: RunManager) -> String:
	return ""


## Pioche une cellule hors des trous de la grille cabossee (holes vient de
## l'event on_round_start, voir SpellManager._on_round_started). Evite qu'un
## modifier a cellule unique (Cellule Double/Triple) se gaspille sur une case
## jamais accessible pendant toute la manche.
func random_open_cell(holes: Dictionary) -> Vector2i:
	var cell: Vector2i = Vector2i(randi() % GameRules.COLS, randi() % GameRules.ROWS)
	while holes.has(cell):
		cell = Vector2i(randi() % GameRules.COLS, randi() % GameRules.ROWS)
	return cell
