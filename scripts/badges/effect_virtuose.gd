## Badge Legendaire "Virtuose" : les Partitions equipees demarrent directement
## au niveau Maestro (le palier max actuel). Verifie a chaque debut de manche
## pour couvrir aussi bien les Partitions deja equipees au moment de l'achat
## que celles achetees plus tard en cours de run — voir RunManager.
## force_sheet_max_level (pousse le cumul, pas juste le niveau, pour que ca
## tienne face au prochain vrai score gagne). Les Partitions legendaires
## (Lost Corners...) ne level up jamais, hors sujet ici.
## Trigger : on_round_start
extends BadgeEffect


func apply(_event: Dictionary, run_manager: RunManager) -> void:
	for sheet in run_manager.get_equipped_sheets():
		if sheet.is_legendary:
			continue
		run_manager.force_sheet_max_level(sheet.sheet_name)
