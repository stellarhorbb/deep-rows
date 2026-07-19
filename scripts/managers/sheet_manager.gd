class_name SheetManager
extends Node

signal sheets_changed(sheets: Array[SheetData])

var _active_sheets: Array[SheetData] = []


## Definit les sheets actifs pour la manche en cours. Appele par le TurnController
## avec les sheets equipes du RunManager.
func set_active_sheets(sheets: Array[SheetData]) -> void:
	_active_sheets = sheets.duplicate()
	sheets_changed.emit(_active_sheets)


func get_active_sheets() -> Array[SheetData]:
	return _active_sheets
