## Tire et applique le malus de boss en debut de manche (une manche sur
## GameRules.ROUNDS_PER_ZONE, voir apply_for_round). Vit dans RunService (voir
## run_service.gd) pour que le pool "deja tire cette run" survive aux
## changements de scene entre les manches.
##
## Les malus qui ne touchent que RunManager (hold/shake/rocks/figures/scoring
## plafonne) sont appliques directement ici. Ceux qui touchent la grille ou
## l'Entity (L'ETAU, CIEL BAS, COLONNE MAUDITE, GRANDE FAIM, BOURRASQUE,
## MECHE COURTE) se contentent de publier leur etat sur ce manager — c'est
## TurnController/GameScene, qui detiennent grid_manager/entity_manager, qui
## lisent active_malus et appliquent l'effet (voir leurs commentaires).
class_name BossMalusManager
extends Node

enum Type {
	MAIN_LIEE,          # HOLD verrouille pour la manche
	SOL_GELE,           # SHAKE verrouille pour la manche
	PLUIE_DE_CAILLOUX,  # +BOSS_MALUS_ROCK_COUNT rocks dans le deck de la manche
	COUR_ENDORMIE,      # aucune promotion de figure (Valet+) pour la manche
	ETAU,               # grille perd 2 colonnes fixes pour la manche
	CIEL_BAS,            # grille perd la rangee du haut pour la manche
	COLONNE_MAUDITE,     # 1 colonne re-tiree au hasard, verrouillee jusqu'au prochain drop
	GRANDE_FAIM,         # l'Entity lache un skull 2x plus frequemment
	BOURRASQUE,          # le jeton tenu en Hold suit automatiquement chaque drop
	MECHE_COURTE,        # les entity-skulls ont un countdown et explosent a 0
	FAMILLE_TERNIE,      # une famille au hasard vaut 1 ticket pour la manche
	PARTITION_TERNIE,    # une partition equipee au hasard vaut 1 ticket pour la manche
}

const LABELS: Dictionary = {
	Type.MAIN_LIEE: "MAIN LIÉE",
	Type.SOL_GELE: "SOL GELÉ",
	Type.PLUIE_DE_CAILLOUX: "PLUIE DE CAILLOUX",
	Type.COUR_ENDORMIE: "COUR ENDORMIE",
	Type.ETAU: "L'ÉTAU",
	Type.CIEL_BAS: "CIEL BAS",
	Type.COLONNE_MAUDITE: "COLONNE MAUDITE",
	Type.GRANDE_FAIM: "GRANDE FAIM",
	Type.BOURRASQUE: "BOURRASQUE",
	Type.MECHE_COURTE: "MÈCHE COURTE",
	Type.FAMILLE_TERNIE: "FAMILLE TERNIE",
	Type.PARTITION_TERNIE: "PARTITION TERNIE",
}

const DESCRIPTIONS: Dictionary = {
	Type.MAIN_LIEE: "Le slot de Hold est verrouillé pour toute la manche.",
	Type.SOL_GELE: "Le bouton Shake est désactivé pour toute la manche.",
	Type.PLUIE_DE_CAILLOUX: "%d rocks supplémentaires sont injectés dans le deck de la manche." % GameRules.BOSS_MALUS_ROCK_COUNT,
	Type.COUR_ENDORMIE: "Aucune figure (Valet+) ne peut être promue pendant la manche, même si elle rescore.",
	Type.ETAU: "2 colonnes sont bloquées pour toute la manche.",
	Type.CIEL_BAS: "La rangée du haut de la grille est bloquée pour toute la manche.",
	Type.COLONNE_MAUDITE: "Une colonne verrouillée est re-tirée au hasard avant chaque drop.",
	Type.GRANDE_FAIM: "L'Entity lâche un skull deux fois plus souvent.",
	Type.BOURRASQUE: "Le jeton tenu en Hold tombe automatiquement dans la même colonne, juste après le vôtre.",
	Type.MECHE_COURTE: "Les entity-skulls explosent après %d tours, détruisant leurs deux voisins sans les scorer." % GameRules.MECHE_COURTE_START_COUNTDOWN,
	Type.FAMILLE_TERNIE: "Les jetons de la famille ciblée ne rapportent qu'1 ticket ce tour.",
	Type.PARTITION_TERNIE: "La Partition ciblée ne rapporte qu'1 ticket ce tour.",
}

const ACTIVE_POOL: Array[Type] = [
	Type.MAIN_LIEE,
	Type.SOL_GELE,
	Type.PLUIE_DE_CAILLOUX,
	Type.COUR_ENDORMIE,
	Type.ETAU,
	Type.CIEL_BAS,
	Type.COLONNE_MAUDITE,
	Type.GRANDE_FAIM,
	Type.BOURRASQUE,
	Type.MECHE_COURTE,
	Type.FAMILLE_TERNIE,
	Type.PARTITION_TERNIE,
]

## Type actif pour la manche en cours, -1 si la manche n'est pas une manche boss.
var active_malus: int = -1

## Detail lisible a coller apres le label pour l'annonce (ex: nom de la
## famille/Partition ciblee). Vide si le malus n'a pas de cible a afficher.
var active_detail: String = ""

## Colonnes verrouillees pour la manche (Type.ETAU uniquement) — tirees une
## fois a l'activation, lues par TurnController pour poser les trous.
var etau_columns: Array[int] = []

var _drawn_this_run: Array[Type] = []


func reset_run() -> void:
	_drawn_this_run.clear()
	active_malus = -1
	active_detail = ""
	etau_columns.clear()


## A appeler en debut de chaque manche, apres run_manager.reset_round_modifiers()
## et avant run_manager.build_context(). Ne fait rien hors manche boss.
func apply_for_round(round_number: int, run_manager: RunManager) -> int:
	active_malus = -1
	active_detail = ""
	etau_columns.clear()
	if round_number % GameRules.ROUNDS_PER_ZONE != 0:
		return active_malus

	active_malus = _draw()
	match active_malus:
		Type.MAIN_LIEE:
			run_manager.set_hold_locked(true)
		Type.SOL_GELE:
			run_manager.set_shake_locked(true)
		Type.PLUIE_DE_CAILLOUX:
			run_manager.add_rock_count_bonus(GameRules.BOSS_MALUS_ROCK_COUNT, &"boss_malus")
		Type.COUR_ENDORMIE:
			run_manager.set_figure_promotion_locked(true)
		Type.ETAU:
			# Les deux colonnes exterieures, jamais aleatoires (retune : "l'etau"
			# doit serrer depuis les bords, pas depuis n'importe ou sur la grille).
			etau_columns = [0, GameRules.COLS - 1]
		Type.FAMILLE_TERNIE:
			var family: TokenData.Family = TokenData.Family.values()[randi() % TokenData.Family.values().size()]
			run_manager.set_score_capped_family(family)
			active_detail = TokenData.family_label(family)
		Type.PARTITION_TERNIE:
			# Jamais une legendaire : son multiplicateur EST sa raison d'etre
			# (Royal Square = roll, Lost Corners = somme de la rangee du bas).
			# La neutraliser sur un build construit autour peut ecraser toute
			# la manche sans aucun moyen de s'y preparer — meme logique que le
			# "pas de RNG punitif" de session 19 sur les Partitions.
			var eligible: Array[SheetData] = run_manager.get_equipped_sheets().filter(
				func(s: SheetData) -> bool: return not s.is_legendary
			)
			if not eligible.is_empty():
				var sheet: SheetData = eligible[randi() % eligible.size()]
				run_manager.set_score_capped_sheet(sheet.sheet_name)
				active_detail = sheet.label
		# CIEL_BAS, COLONNE_MAUDITE, GRANDE_FAIM, BOURRASQUE, MECHE_COURTE :
		# aucun etat cote RunManager, juste le type actif lu ailleurs.
	return active_malus


func get_active_label() -> String:
	var base: String = LABELS.get(active_malus, "") as String
	if active_detail == "":
		return base
	return "%s (%s)" % [base, active_detail]


## Description longue pour le hover UI (voir GameScene._update_zone_display).
## Vide si aucun malus actif.
func get_active_description() -> String:
	return DESCRIPTIONS.get(active_malus, "") as String


## Exclut les types deja tires cette run — relache le pool complet si tout a
## deja ete pioche (jamais atteint avec 4 manches boss/run et 12 types actifs).
func _draw() -> Type:
	var available: Array[Type] = ACTIVE_POOL.filter(func(t: Type) -> bool: return not _drawn_this_run.has(t))
	if available.is_empty():
		_drawn_this_run.clear()
		available = ACTIVE_POOL.duplicate()
	var picked: Type = available[randi() % available.size()]
	_drawn_this_run.append(picked)
	return picked
