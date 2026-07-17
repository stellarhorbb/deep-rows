## Pack de demarrage (session 19) — choix de depart deterministe, remplace
## l'ancien tirage 3/2 de Partitions. Voir docs/gdd/progression/structure-run.md#choix-de-depart
## et docs/brainstorms/brainstorm-starter-packs.md pour le roster complet.
class_name StarterPackData
extends Resource

@export var pack_name: String = ""
@export_multiline var description: String = ""

## 1-2 Partitions equipees gratuitement des le debut de la run. Deux champs
## simples plutot qu'un Array[PatternData] — tous les packs du roster en
## portent exactement 2, pas besoin de la flexibilite d'un tableau.
@export var fixed_tag_a: PatternData = null
@export var fixed_tag_b: PatternData = null


## Les Partitions fixes de ce pack, sans les entrees nulles (pour un pack a
## une seule Partition fixe le cas echeant).
func get_fixed_tags() -> Array[PatternData]:
	var tags: Array[PatternData] = []
	if fixed_tag_a != null:
		tags.append(fixed_tag_a)
	if fixed_tag_b != null:
		tags.append(fixed_tag_b)
	return tags

## Modificateurs de regle/economie — un curseur sur un systeme existant.
## Tous a 0 = pack "neutre" (Le Simplet). Permanents pour toute la run,
## contrairement aux bonus de Badge equivalents qui se reinitialisent chaque
## manche (voir RunManager.reset_round_modifiers/apply_starter_pack).
@export var hold_slot_bonus: int = 0
@export var badge_slot_bonus: int = 0
@export var preview_size_bonus: int = 0
@export var flies_per_round_bonus: int = 0
@export var rock_count_bonus: int = 0
