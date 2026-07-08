# Deep Rows — Conventions & Architecture

*Reference permanente pour le developpement Godot. A consulter avant toute implementation.*

---

## 1. Principes Fondamentaux

### 1.0 Langue du code : noms en anglais

**Tous les identifiants sont en anglais** — variables, fonctions, classes, constantes, signaux, noms de fichiers.
Les commentaires peuvent etre en francais ou en anglais, au choix.

```gdscript
# ❌ Interdit
var sel_joueur: int = 0
var famille_corail: StringName = &"corail"

# ✅ Correct
var player_salt: int = 0                    # Salt du joueur
var family_coral: StringName = &"coral"
```

---

### 1.1 Resource-driven design
Toute valeur susceptible d'etre modifiee (balancing, contenu, comportement) **vit dans un `.tres`**, jamais dans le code.

- Un jeton, un pattern, un Badge, une grille, un pack = un fichier `.tres`
- Le code ne connait que des types (`TokenData`, `PatternData`...), jamais des valeurs en dur
- Ajouter un nouveau jeton ou un nouveau pattern = creer un `.tres`, zero modification de code

### 1.2 Pas de magic numbers
```gdscript
# ❌ Interdit
if group_size > 3:
    mult = 2.0

# ✅ Correct
if group_size > GameRules.TRIO_SIZE:
    mult = GameRules.QUARTET_MULTIPLIER
```

Toutes les constantes globales de regles vivent dans `res://scripts/core/game_rules.gd`.

### 1.3 Communication par Signals
Les systemes ne se parlent pas directement — ils emettent et ecoutent des signaux.

```gdscript
# ❌ Interdit — couplage fort
ScoreManager.add_score(amount)

# ✅ Correct — decouplage
pattern_resolved.emit(cells, pattern_data, score)
# ScoreManager ecoute ce signal
```

Chaque Manager declare ses propres signaux en haut de fichier.

### 1.4 Un seul responsable par donnee
- Le score courant → `ScoreManager` uniquement
- L'etat de la grille → `GridManager` uniquement
- Le deck et la main → `DeckManager` uniquement
- Le Salt du joueur → `SaltManager` uniquement

Aucun autre noeud ne modifie ces valeurs directement — il emet un signal, le Manager decide.

### 1.5 Separation logique / visuel
La logique de jeu (resolution, patterns, gravite) est **pure** — elle manipule des donnees et emet des signaux. Le visuel ecoute et anime. On doit pouvoir faire tourner 10000 manches en headless pour tester le balancing sans ouvrir le jeu.

```gdscript
# La logique emet des evenements
signal tokens_matched(cells: Array, pattern: PatternData, score: int)
signal tokens_fell(movements: Array)
signal cascade_triggered(level: int)

# Le visuel ecoute et anime
func _on_tokens_matched(cells: Array, _pattern: PatternData, _score: int) -> void:
    for cell in cells:
        _play_resolve_animation(cell)
```

---

## 2. Structure des Dossiers

```
res://
├── scenes/
│   ├── game/
│   │   ├── game.tscn                  ← racine, contient les Managers
│   │   ├── grid.tscn                  ← la grille visuelle
│   │   ├── cell.tscn                  ← une case de la grille
│   │   └── token.tscn                 ← un jeton (visuel + animation)
│   ├── ui/
│   │   ├── hand_ui.tscn               ← la main du joueur
│   │   ├── score_ui.tscn              ← score + cible + deck restant
│   │   ├── shop_ui.tscn               ← ecran du shop
│   │   └── pattern_slots_ui.tscn      ← patterns actifs + niveaux
│   └── menus/
│       ├── main_menu.tscn
│       └── game_over.tscn
│
├── resources/
│   ├── tokens/
│   │   ├── base/                      ← jetons de base par famille
│   │   │   ├── coral_1.tres
│   │   │   ├── coral_2.tres
│   │   │   └── ...
│   │   └── specials/                  ← jetons speciaux (outils)
│   │       ├── bomb.tres
│   │       ├── anchor.tres
│   │       └── ...
│   ├── patterns/
│   │   ├── color_trio.tres
│   │   ├── value_trio.tres
│   │   ├── color_quartet.tres
│   │   └── ...
│   ├── packs/
│   │   ├── versatile.tres
│   │   ├── mono_coral.tres
│   │   └── ...
│   ├── grids/
│   │   ├── abyss.tres
│   │   ├── reef.tres
│   │   ├── trench.tres
│   │   └── ...
│   ├── badges/
│   │   ├── coral_x2.tres
│   │   └── ...
│   ├── token_states/                  ← recettes d'etats (Explosif, Magnetique...)
│   │   ├── explosive.tres
│   │   ├── magnetic.tres
│   │   └── ...
│   └── game_rules.tres                ← valeurs globales de balancing
│
├── scripts/
│   ├── core/
│   │   ├── game_rules.gd              ← constantes de regles
│   │   └── game_manager.gd            ← autoload, etat global du run
│   ├── managers/
│   │   ├── grid_manager.gd            ← etat de la grille, drop, gravite
│   │   ├── deck_manager.gd            ← deck, pioche, main
│   │   ├── score_manager.gd           ← score courant, cible
│   │   ├── pattern_manager.gd         ← detection, scoring, level up
│   │   ├── shop_manager.gd            ← generation offre, achats
│   │   ├── badge_manager.gd           ← passifs actifs, effets
│   │   └── salt_manager.gd            ← economie Salt
│   ├── systems/                       ← logique pure, pas de noeud
│   │   ├── pattern_matcher.gd         ← flood fill, detection patterns
│   │   ├── gravity_system.gd          ← logique de gravite
│   │   └── cascade_resolver.gd        ← boucle resolution → gravite → re-check
│   ├── data/                          ← definitions des Resource classes
│   │   ├── token_data.gd
│   │   ├── special_token_data.gd
│   │   ├── pattern_data.gd
│   │   ├── grid_data.gd
│   │   ├── pack_data.gd
│   │   ├── badge_data.gd
│   │   └── token_state_data.gd
│   └── ui/
│       ├── token_visual.gd
│       ├── grid_visual.gd
│       ├── hand_ui.gd
│       └── score_ui.gd
│
├── assets/
│   ├── tokens/
│   ├── ui/
│   │   ├── frames/
│   │   ├── buttons/
│   │   └── backgrounds/
│   └── grids/                         ← visuels de grille par type
│
├── sfx/
│   ├── tokens/                        ← drop, resolve, cascade
│   ├── ui/                            ← hover, click, transition
│   └── game/                          ← win, lose, last_breath
│
└── vfx/
    ├── particles/
    └── shaders/
```

---

## 3. Definition des Resources

### TokenData
```gdscript
# scripts/data/token_data.gd
class_name TokenData
extends Resource

@export var family: StringName          # &"coral" | &"abyssal" | &"drift" | &"shell"
@export var value: int                  # 1-9
@export var display_name: String
@export var state: TokenStateData       # null si pas d'etat applique
@export var sprite: Texture2D
```

### SpecialTokenData
```gdscript
# scripts/data/special_token_data.gd
class_name SpecialTokenData
extends Resource

@export var token_name: String
@export var description: String
@export var is_instant: bool = true     # true = sort, false = pose sur la grille
@export var effect_id: StringName       # &"bomb" | &"anchor" | &"transformer" | ...
@export var effect_params: Dictionary   # parametres specifiques a l'effet
@export var last_breath_bonus: int = 0  # score bonus au Dernier Souffle (si pose)
@export var sprite: Texture2D
@export var rarity: StringName          # &"common" | &"rare" | &"epic"
```

### PatternData
```gdscript
# scripts/data/pattern_data.gd
class_name PatternData
extends Resource

@export var pattern_name: String
@export var description: String
@export var match_type: StringName      # &"family" | &"value" | &"mixed"
@export var min_size: int = 3           # minimum de jetons connectes
@export var base_multiplier: float = 1.0
@export var level_thresholds: Array[int] = [0, 150, 400, 800]  # score cumule pour level up
@export var multiplier_per_level: float = 0.5  # bonus mult par niveau
@export var icon: Texture2D
```

### GridData
```gdscript
# scripts/data/grid_data.gd
class_name GridData
extends Resource

@export var grid_name: String
@export var description: String
@export var cols: int = 7
@export var rows: int = 6
@export var blocked_cells: Array[Vector2i] = []     # cases inaccessibles
@export var special_cells: Dictionary = {}           # { Vector2i: "x2" | "cursed" | ... }
@export var icon: Texture2D
```

### PackData
```gdscript
# scripts/data/pack_data.gd
class_name PackData
extends Resource

@export var pack_name: String
@export var description: String
@export var tokens: Array[TokenData] = []   # liste des jetons de base du pack
@export var icon: Texture2D
```

### BadgeData
```gdscript
# scripts/data/badge_data.gd
class_name BadgeData
extends Resource

@export var badge_name: String
@export var description: String
@export var trigger: StringName          # &"on_resolve" | &"on_cascade" | &"on_drop" | ...
@export var effect_id: StringName        # &"mult_family" | &"cascade_bonus" | ...
@export var effect_params: Dictionary    # { "family": "coral", "multiplier": 2.0 }
@export var icon: Texture2D
@export var rarity: StringName           # &"common" | &"uncommon" | &"rare" | &"epic"
```

### TokenStateData
```gdscript
# scripts/data/token_state_data.gd
class_name TokenStateData
extends Resource

@export var state_name: String
@export var description: String
@export var trigger: StringName          # &"on_resolve" | &"on_drop"
@export var effect_id: StringName        # &"explosive" | &"magnetic" | &"replicator"
@export var effect_params: Dictionary
@export var icon_overlay: Texture2D      # icone superposee au jeton de base
```

---

## 4. game_rules.gd — Constantes Globales

```gdscript
# scripts/core/game_rules.gd
class_name GameRules

# Grille
const DEFAULT_COLS: int = 7
const DEFAULT_ROWS: int = 6

# Patterns
const MIN_MATCH_SIZE: int = 3
const TRIO_MULTIPLIER: float = 1.0
const QUARTET_MULTIPLIER: float = 2.0
const QUINTET_MULTIPLIER: float = 3.0
const SEXTET_PLUS_MULTIPLIER: float = 5.0
const CASCADE_MULTIPLIER: float = 2.0         # x2 par niveau de cascade

# Deck
const STARTING_DECK_SIZE: int = 40
const HAND_SIZE: int = 5

# Scoring
const BASE_TARGET: int = 80                    # score cible de la premiere manche
const TARGET_INCREMENT: int = 30               # augmentation par manche

# Economie
const STARTING_SALT: int = 100
const SALT_REWARD_BASE: int = 20               # Salt gagne en atteignant le score
const SHOP_REROLL_BASE_COST: int = 5
const SHOP_REROLL_INCREMENT: int = 5

# Dernier Souffle
const LAST_BREATH_SPECIAL_BONUS: int = 10      # score bonus par special pose
```

---

## 5. Conventions de Nommage

### Fichiers
| Type | Convention | Exemple |
|---|---|---|
| Scenes | `snake_case.tscn` | `game.tscn` |
| Scripts | `snake_case.gd` | `grid_manager.gd` |
| Resources `.tres` | `snake_case.tres` | `color_trio.tres` |
| Assets | `snake_case.png` | `token_coral.png` |

### Code GDScript
| Element | Convention | Exemple |
|---|---|---|
| Classes | `PascalCase` | `TokenData` |
| Variables | `snake_case` | `current_score` |
| Constantes | `UPPER_SNAKE_CASE` | `MIN_MATCH_SIZE` |
| Signaux | `snake_case` (passe) | `pattern_resolved`, `tokens_dropped` |
| Fonctions privees | `_snake_case` | `_apply_gravity()` |

### Typage explicite obligatoire
```gdscript
# ❌ Interdit — type ambigu
var tokens := deck.pop_back()

# ✅ Correct — type explicite
var token: TokenData = deck.pop_back() as TokenData
```

Toujours `var x: Type = value`, jamais `:=` sur des retours Variant.

### Resources `.tres`
Nommees par contenu, prefixees par type si ambiguite :
- `coral_3.tres` (jeton Corail valeur 3)
- `color_trio.tres` (pattern Trio couleur)
- `badge_cascade_bonus.tres`
- `grid_abyss.tres`
- `pack_versatile.tres`
- `state_explosive.tres`

---

## 6. Resolution & Affichage

- **Resolution de reference** : 1920 x 1080px
- Configurer dans `project.godot` : `display/window/size/viewport_width = 1920`, `viewport_height = 1080`
- Stretch mode : `canvas_items`, aspect : `keep`

---

## 7. Conventions UI — Editabilite dans l'editeur Godot

### 6.1 Principes

**Tout noeud visible dans la scene, pas de generation cachee.**
Les elements UI sont places dans le scene tree — pas crees dynamiquement par un script sauf si absolument necessaire (listes de longueur variable comme les items de shop).

```gdscript
# ❌ Interdit — UI invisible dans l'editeur
func _ready():
    var label = Label.new()
    label.text = "Score"
    add_child(label)

# ✅ Correct — Label place dans la scene, le script le trouve par @onready
@onready var score_label: Label = $ScoreDisplay/Label
```

**Toutes les valeurs visuelles configurables via `@export`.**
Couleurs, tailles, durees d'animation, espacements — tout ce qui peut varier est `@export` et visible dans l'Inspector, jamais dans le code.

```gdscript
# ✅ Configurable dans l'Inspector sans toucher au code
@export var resolve_color: Color = Color.WHITE
@export var cascade_color: Color = Color.GOLD
@export var animation_duration: float = 0.3
```

**Un Theme Godot par type d'element, pas de styles inline.**

**Les popups et modals sont des scenes completes.**

### 6.2 Ce qu'un script UI fait et ne fait pas

| ✅ Fait | ❌ Ne fait pas |
|---|---|
| `@onready` pour referencer les noeuds | Creer des noeuds UI dynamiquement |
| Mettre a jour le texte/couleur d'un Label | Definir des styles ou tailles |
| Emettre un signal sur input utilisateur | Contenir de la logique de jeu |
| Appeler une animation Tween | Calculer des valeurs de jeu |

---

## 8. Regles d'Or

1. **Avant d'ajouter une valeur dans le code, demande-toi si elle pourrait changer lors du balancing.** Si oui → Resource ou `game_rules.gd`.
2. **Un Manager = une responsabilite.** Si un script fait deux choses, c'est deux scripts.
3. **Les scenes UI n'ont pas de logique de jeu.** Elles affichent ce qu'on leur donne et emettent des inputs utilisateur — c'est tout.
4. **Toujours creer le `.tres` template avant les instances.** Dupliquer un template > creer de zero.
5. **Les effets de Badges et d'etats ne sont jamais hardcodes dans la resolution.** Le CascadeResolver emet des signaux, les Resources decrivent les effets.
6. **Tout element UI est visible dans le scene tree.** Si tu ne peux pas le voir dans l'editeur sans lancer le jeu, c'est mal fait.
7. **Logique et visuel sont separes.** La logique manipule des donnees et emet des signaux. Le visuel ecoute et anime. Jamais de Tween dans un Manager.

---

## 9. Conventions Git

Format des commits : `type: description courte`

| Type | Usage |
|---|---|
| `build:` | Mise en place technique, architecture, scripts core |
| `feat:` | Nouvelle fonctionnalite de gameplay |
| `fix:` | Correction de bug |
| `design:` | Ajout ou modification d'assets, UI, DA |
| `content:` | Ajout de contenu (nouveaux jetons, badges, patterns en .tres) |
| `docs:` | GDD, conventions, session logs, documentation |
| `balance:` | Modification de valeurs dans game_rules.gd ou .tres |

Regles :
- Court et concis — une ligne suffit le plus souvent
- Decrire ce qui a change, pas comment
