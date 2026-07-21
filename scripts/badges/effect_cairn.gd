## Badge "Cairn" : a chaque manche gagnée, compte les Rocks encore sur la
## grille et cumule +0.1 au facteur de scaling permanent PAR Rock compté
## (jamais remis a zero — meme principe qu'"Escalade musicale", meme ordre de
## grandeur en fin de run : ~4 Rocks/manche * 0.1 * 19 manches = +7.6, soit
## un scaling_mult ~8.6). Pousse a NE PAS utiliser le Dernier Souffle (qui
## detruit les Rocks) pour laisser le temps au total de grossir — deja
## naturellement le cas a chaque manche, puisque explode_residues() vide les
## Rocks avant que ce badge ne compte si la manche est passee par le Dernier
## Souffle.
## Trigger : on_round_end
extends BadgeEffect

const BONUS_PER_ROCK: float = 0.1
const STATE_KEY: StringName = &"cairn_rock_count"


func apply(event: Dictionary, run_manager: RunManager) -> void:
	var grid_manager: GridManager = event.get("grid_manager") as GridManager
	if grid_manager == null:
		return
	var total: int = (run_manager.get_run_badge_state(STATE_KEY, 0) as int) + grid_manager.count_rocks()
	run_manager.set_run_badge_state(STATE_KEY, total)
	run_manager.set_scaling_mult_bonus(&"cairn", total * BONUS_PER_ROCK)


func get_progress_text(run_manager: RunManager) -> String:
	var total: int = run_manager.get_run_badge_state(STATE_KEY, 0) as int
	return "%d Rocks cumulés (+%.1f mult)" % [total, total * BONUS_PER_ROCK]
