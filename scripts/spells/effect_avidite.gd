## Sortilège "Avidité" (renommé depuis "Gourmand" en session 28 -- le nom
## "Gourmand" a ete repris par un nouveau Sortilège distinct sur les
## speciaux "mangeurs", voir effect_gourmand.gd) : chaque jeton ajoute au
## deck (achat au shop ou scission) cumule +2 points, appliques a toutes les
## resolutions suivantes (scaling permanent, jamais remis a zero sur la run).
## Retravaille de +5 a +2 en session 23 apres playtest (juge trop fort).
## Trigger : on_deck_grown
extends SpellEffect

const BONUS_PER_TOKEN: int = 2
const STATE_KEY: StringName = &"avidite_tokens_added"


func apply(event: Dictionary, run_manager: RunManager) -> void:
	var added: int = event.get("count", 0) as int
	if added <= 0:
		return
	var total: int = (run_manager.get_run_spell_state(STATE_KEY, 0) as int) + added
	run_manager.set_run_spell_state(STATE_KEY, total)
	run_manager.set_flat_score_bonus(&"avidite", total * BONUS_PER_TOKEN)


func get_progress_text(run_manager: RunManager) -> String:
	var total: int = run_manager.get_run_spell_state(STATE_KEY, 0) as int
	return "+%d points (%d jetons ajoutés)" % [total * BONUS_PER_TOKEN, total]
