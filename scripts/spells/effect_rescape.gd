## Sortilège "Rescapé" : chaque manche boss survécue cumule +1 au facteur de
## scaling permanent (jamais remis a zero, actif sur toute la run — meme
## principe qu'"Escalade musicale"). Manche boss = round_number multiple de
## GameRules.ROUNDS_PER_ZONE, meme detection que BossMalusManager.
## Retravaille de +2.0 a +1.0 en session 25 apres retour playtest : le premier
## palier (des la manche 5) triplait deja tout le score d'un coup, trop
## brutal compare a la progression lisse de Cairn (meme canal, ~x8.6 en fin
## de run mais en douceur). A +1.0/boss, Rescapé plafonne vers x5 sur un run
## de 20 manches (4 boss) — sous Cairn plutot qu'au-dessus, palier d'entree
## ramene a un simple doublement.
## Trigger : on_round_end
extends SpellEffect

const BONUS_PER_BOSS: float = 1.0
const STATE_KEY: StringName = &"rescape_boss_survived"


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	if RunService.current_round % GameRules.ROUNDS_PER_ZONE != 0:
		return
	var count: int = (run_manager.get_run_spell_state(STATE_KEY, 0) as int) + 1
	run_manager.set_run_spell_state(STATE_KEY, count)
	run_manager.set_scaling_mult_bonus(&"rescape", count * BONUS_PER_BOSS)


func get_progress_text(run_manager: RunManager) -> String:
	var count: int = run_manager.get_run_spell_state(STATE_KEY, 0) as int
	return "+%d%% mult (%d boss survécus)" % [int(round(count * BONUS_PER_BOSS * 100)), count]
