## Pack de demarrage (session 19) — choix de depart deterministe, remplace
## l'ancien tirage 3/2 de Partitions. Voir docs/gdd/progression/structure-run.md#choix-de-depart
## et docs/brainstorms/brainstorm-starter-packs.md pour le roster complet.
class_name StarterPackData
extends Resource

@export var pack_name: String = ""

## ID stable pour la sauvegarde du Shore (MetaProgression), independant du
## nom affiche. Prefixe "pack:" pour eviter toute collision avec les autres
## categories de contenu debloquable. Jamais renomme une fois pose.
@export var unlock_id: String = ""
@export_multiline var description: String = ""

## 1-2 Partitions equipees gratuitement des le debut de la run. Deux champs
## simples plutot qu'un Array[SheetData] — tous les packs du roster en
## portent exactement 2, pas besoin de la flexibilite d'un tableau.
@export var fixed_sheet_a: SheetData = null
@export var fixed_sheet_b: SheetData = null


## Les Partitions fixes de ce pack, sans les entrees nulles (pour un pack a
## une seule Partition fixe le cas echeant).
func get_fixed_sheets() -> Array[SheetData]:
	var sheets: Array[SheetData] = []
	if fixed_sheet_a != null:
		sheets.append(fixed_sheet_a)
	if fixed_sheet_b != null:
		sheets.append(fixed_sheet_b)
	return sheets

## Modificateurs de regle/economie — un curseur sur un systeme existant.
## Tous a 0 = pack "neutre" (Le Simplet). Permanents pour toute la run,
## contrairement aux bonus de Sortilège equivalents qui se reinitialisent chaque
## manche (voir RunManager.reset_round_modifiers/apply_starter_pack).
@export var hold_slot_bonus: int = 0
@export var spell_slot_bonus: int = 0
@export var preview_size_bonus: int = 0
@export var flies_per_round_bonus: int = 0
@export var rock_count_bonus: int = 0

## Acces meta (Shore) : un pack verrouille reste visible a l'ecran de
## selection (voir RunManager.is_pack_locked/get_all_starter_packs) mais pas
## selectionnable tant qu'il n'a pas ete debloque. Seul Le Simplet reste a
## false (day-one). Voir docs/gdd/shore/unlocks.md.
@export var locked: bool = false

## Si renseigne, ce pack reste verrouille tant que le pack reference n'a pas
## ete gagne au moins une fois (voir RunManager.record_starter_win). Ignore
## si locked = false. Null = pas de prerequis connu pour l'instant (le pack
## reste verrouille sans condition, a trancher plus tard).
@export var unlock_requires_win_of: StarterPackData = null
