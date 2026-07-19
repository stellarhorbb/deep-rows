class_name SheetData
extends Resource

@export var sheet_name: StringName = &""
@export var shape: StringName = &""       # &"line" | &"square" | &"diamond" | &"plus" | &"cross" | &"ring" | &"t" | &"corners"
@export var rule: StringName = &""        # &"family" | &"value" | &"suite" | &"rock" | &"rainbow" | &"fibonacci" | &"minima" | &"maxima" | &"prime"
@export var min_size: int = 3             # 3 pour lignes, 4 pour carres (2x2 = 4 cells)
@export var direction: StringName = &"any"  # &"horizontal" | &"diagonal" | &"any" (jamais &"vertical")
@export var score_multiplier: float = 1.0   # Multiplicateur applique au score du groupe

## Petit pool a part (session 20), jamais dans le tirage uniforme normal du
## catalogue (voir ShopManager.LEGENDARY_SHEET_PATHS) — narratif : le joueur
## ouvre des packs "au cas ou" meme un build deja bon, en esperant en croiser
## une. Flat, ne level up jamais (voir RunManager.add_sheet_score) : la
## puissance vient de la rarete/du multiplicateur dynamique, pas d'un
## investissement en plus — cumuler les deux ferait un objet strictement
## superieur a tout le reste du jeu. Effet reel code en dur dans
## CascadeResolver/SheetMatcher par sheet_name, pas via un systeme generique.
@export var is_legendary: bool = false

## Shop
## Pas de champ rarity (session 19) : contrairement aux Badges (bonus optionnel,
## rarete = puissance), les Partitions sont la mecanique de resolution elle-meme
## — les gater par rarete privait le joueur d'une partie du jeu plutot que d'un
## bonus, a l'encontre du principe "pas de RNG punitif". Tirees uniformement,
## voir ShopManager._draw_unitaire/open_pack.
@export var label: String = ""
@export var price: int = 0

## Acces meta (session 19) : une Partition verrouillee n'apparait ni au
## tirage du shop ni dans les packs de demarrage tant qu'elle n'a pas ete
## debloquee au Shore (voir docs/gdd/partitions/catalogue-implemente.md#acces-generique-vs-verrouille).
## Toutes decochees pour l'instant (aucune sauvegarde inter-runs encore
## construite) — a cocher une fois le systeme d'unlock du Shore implemente.
@export var locked: bool = false

## DEBUG : si true, cette Partition est equipee des le debut du run (bypass
## shop) — meme principe que BadgeData.debug_start_equipped. Pratique pour
## tester une legendaire sans attendre son tirage. A laisser a false pour un
## run normal.
@export var debug_start_equipped: bool = false


## Texte de hover en langage clair, reutilise en jeu (SheetsUI) et au shop.
func describe() -> String:
	var shape_desc: String
	match shape:
		&"line":    shape_desc = "Ligne de %d+ jetons" % min_size
		&"square":  shape_desc = "Carré 2x2"
		&"diamond": shape_desc = "Losange autour d'un centre"
		&"plus":    shape_desc = "Croix orthogonale (centre inclus)"
		&"cross":   shape_desc = "Croix diagonale (centre inclus)"
		&"ring":    shape_desc = "Cadre 3x3 autour d'un centre"
		&"t":       shape_desc = "Tétromino T, 4 jetons, orientation libre"
		&"corners": shape_desc = "Les 2 coins inférieurs de la grille"
		_:          shape_desc = "Figure"

	var rule_desc: String
	match rule:
		&"family": rule_desc = "même famille"
		&"value":  rule_desc = "même valeur"
		&"suite":  rule_desc = "valeurs consécutives"
		&"rock":   rule_desc = "autour d'un Rock"
		&"rainbow":   rule_desc = "toutes familles différentes"
		&"fibonacci": rule_desc = "suite Fibonacci (1,1,2,3,5,8)"
		&"minima":    rule_desc = "toutes les valeurs ≤ %d" % GameRules.MINIMA_MAX_VALUE
		&"maxima":    rule_desc = "toutes les valeurs ≥ %d" % GameRules.MAXIMA_MIN_VALUE
		&"prime":     rule_desc = "suite de nombres premiers (2,3,5,7)"
		_:         rule_desc = ""

	var text: String = label
	text += "\n" + shape_desc
	if rule_desc != "":
		text += ", " + rule_desc

	if is_legendary:
		text += "\nMultiplicateur variable (légendaire)"
	elif score_multiplier > 1.0:
		text += "\nMultiplicateur fixe x%.1f" % score_multiplier

	return text
