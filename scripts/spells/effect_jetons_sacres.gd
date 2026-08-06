## Sortilège "Jetons sacrés" : chaque jeton spécial joué cumule +0.1 au facteur de
## scaling permanent (jamais remis à zéro, actif sur toute la run).
## Trigger : on_token_drop
extends SpellEffect

const BONUS_PER_SPECIAL: float = 0.1
const STATE_KEY: StringName = &"jetons_sacres_played"


func apply(event: Dictionary, run_manager: RunManager) -> void:
	var token: TokenData = event.get("token") as TokenData
	if token != null and token.kind == TokenData.Kind.SPECIAL:
		var count: int = (run_manager.get_run_spell_state(STATE_KEY, 0) as int) + 1
		run_manager.set_run_spell_state(STATE_KEY, count)

	var played: int = run_manager.get_run_spell_state(STATE_KEY, 0) as int
	run_manager.set_scaling_mult_bonus(&"jetons_sacres", played * BONUS_PER_SPECIAL)


func get_progress_text(run_manager: RunManager) -> String:
	var played: int = run_manager.get_run_spell_state(STATE_KEY, 0) as int
	return "+%d%% mult (%d spéciaux joués)" % [int(round(played * BONUS_PER_SPECIAL * 100)), played]
