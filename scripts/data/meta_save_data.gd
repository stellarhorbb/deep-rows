## Sauvegarde du Shore (session 25) — ce qui persiste entre les sessions du
## jeu. Un seul point de verite : la liste des IDs de contenu debloques
## (sheet_name, pack_name...), jamais un flag "locked" coche/decoche a la
## main sur chaque .tres. Voir docs/gdd/shore/unlocks.md et MetaProgression.
class_name MetaSaveData
extends Resource

@export var unlocked_ids: Array[String] = []
