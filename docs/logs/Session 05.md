# Session 05 — Premier build Godot jouable

**Date** : 2026-04-13
**Theme** : Implementation du proto Godot, architecture complete, juice de resolution

---

## Contexte

Premiere grosse session de code. Objectif : passer du proto HTML a un vrai projet Godot jouable. Avant de coder, discussion architecture en 3 points (architecture, resources, resolution des points) pour valider les decisions.

---

## Decisions d'architecture validees

### GameRules
Reste en `const` dans un `.gd` (pas Resource). Permet des overrides dynamiques par Echoes plus tard. Thomas est a l'aise avec l'edition directe du fichier.

### PatternData
Evolue avec `shape: StringName` + `rule: StringName` au lieu de l'ancien `match_type` plat. Chaque Pattern Tag est un bundle forme+regle.

### Systems
- `PatternMatcher` et `GravitySystem` : classes statiques (fonctions pures)
- `CascadeResolver` : RefCounted (accumule la timeline d'evenements)

### Resources — quoi mettre en .tres et quoi garder en code
Regle : "beaucoup d'instances + valeurs uniques a tweaker = Resource, peu d'instances ou donnees previsibles = code."

**En .tres** : PatternData (tags), PackData, GridData, SpecialTokenData, EchoData
**En code** : jetons de base (generes depuis le Pack), token states (peu nombreux), game rules (const)

Thomas avait le sentiment sur les projets precedents que tout mettre en .tres etait overkill — valide, on reduit fortement le nombre de fichiers .tres.

### Pipeline de resolution (priorite n°1)
- CascadeResolver produit une timeline complete d'evenements
- Logique resout tout instantanement, visuel joue la timeline etape par etape
- Hooks prevus a chaque etape pour les Echoes futurs : on_drop, before_resolve, after_resolve, on_cascade, turn_end
- Thomas insiste : c'est la partie la plus importante du jeu. Sauvegarde en memoire long-terme.

---

## Implementation — 6 phases

### Phase 1 : Fondations
- `game_rules.gd` — constantes du proto (grille 6x8, deck 50+8+6, target 100, multipliers)
- `token_data.gd` — RefCounted avec enums Kind/Family/SpecialType, factories
- `pattern_data.gd` — Resource avec shape + rule
- `project.godot` — nom, viewport 1920x1080, stretch canvas_items/keep
- Structure de dossiers : scripts/{core,data,managers,systems,ui}, scenes/, resources/

### Phase 2 : Logique pure
- `gravity_system.gd` — compacte les colonnes, retourne les mouvements
- `pattern_matcher.gd` — lignes 3+ (4 axes) et carres 2x2, match family/value, filtrage par Tags
- `cascade_resolver.gd` — boucle gravite → match → score → remove → gravite, produit timeline
- `special_effects.gd` — fantome (shift+residu), bombe (3x3+score), maree (ecarte la ligne)

### Phase 3 : Deck & Stream
- `deck_manager.gd` — build_deck, advance_stream, do_hold, consume_current, get_preview

### Phase 4 : Managers & orchestration
- `grid_manager.gd` — possede la grille, place_token, execute_special, resolve
- `score_manager.gd` — score + target, score_changed, target_reached
- `pattern_manager.gd` — 4 tags proto hardcodes (line/square x family/value)
- `turn_controller.gd` — machine a etats AWAITING_INPUT → DROPPING → RESOLVING → ROUND_OVER

### Phase 5 : Visuel
- `token_visual.gd` — charge et cache les sprites (famille x valeur, rock, specials)
- `grid_visual.gd` — Sprite2D par jeton, fond en _draw(), animations Tween
- `stream_ui.gd` — current + hold + preview vertical
- `score_ui.gd`, `message_display.gd`, `input_handler.gd`
- `score_popup.gd` — labels flottants "+score" qui montent et fade
- `game_scene.gd` — cablage managers/UI, signaux
- `game.tscn` — scene avec tous les nodes UI dans le scene tree

### Phase 6 : Game flow
Boutons Nouvelle Manche / Nouveau Run crees puis supprimes — pas utiles pour le vrai jeu.

---

## Refactors en session

### UI dans le scene tree (pas en code)
Erreur initiale : toute l'UI etait creee par code dans `game_scene.gd`. Thomas a demande ou il pouvait modifier l'UI — tout etait hardcode. Refactor vers `game.tscn` avec les nodes dans le scene tree, `game_scene.gd` reduit au cablage des signals. Les managers (sans representation visuelle) restent crees en code.

### Timing des specials
Probleme de timing : les signals des specials etaient emis avant que `await drop_animated` soit atteint dans le TurnController, bloquant le jeu. Fix : `await get_tree().process_frame` avant notify, puis separation du flow en 3 etapes (special_landing → drop anime → execute_special → effect done → resolve).

### Grid visual : _draw() → Sprite2D individuels
Pour permettre les animations de juice (pulse, shrink, gravity tween), chaque jeton est maintenant un Sprite2D enfant de GridVisual au lieu d'un dessin dans `_draw()`. Le fond de grille reste en `_draw()`.

### rebuild_sprites() pour les specials
`sync_sprites()` ne suffisait pas apres Ghost/Tide car les jetons changent de cellule — l'ancien sprite montrait le mauvais jeton. `rebuild_sprites()` detruit tout et recree depuis l'etat de la grille.

---

## Changements de design

### Familles renommees
Ancien : Coral, Abyssal, Drift, Shell
Nouveau : **Coral, Shell, Ink, Rust** (2 claires, 2 sombres)

### Tide (Maree) — comportement change
Proto HTML : clic sur une cellule specifique, la maree ecarte cette ligne.
Godot : le Tide **tombe dans une colonne** comme les autres jetons et ecarte la ligne a son point d'impact. Plus intuitif et coherent avec le geste de drop.

### Residu Ghost
Utilise le sprite `ghost.png` semi-transparent au lieu d'un cercle generique.

---

## Fichiers crees

### Scripts (17 fichiers)
- `scripts/core/` : game_rules.gd, game_scene.gd, turn_controller.gd
- `scripts/data/` : token_data.gd, pattern_data.gd
- `scripts/managers/` : grid_manager.gd, deck_manager.gd, score_manager.gd, pattern_manager.gd
- `scripts/systems/` : gravity_system.gd, pattern_matcher.gd, cascade_resolver.gd, special_effects.gd
- `scripts/ui/` : grid_visual.gd, stream_ui.gd, input_handler.gd, token_visual.gd, score_popup.gd, score_ui.gd, message_display.gd

### Scenes
- `scenes/game/game.tscn`

### Assets (importes par Thomas)
- `assets/tokens/` : 20 jetons base (4 familles x 5 valeurs) + rock.png
- `assets/special-tokens/` : ghost.png, bomb.png, tide.png
- `assets/fonts/` : Londrina Solid (Black, Regular, Light, Thin)

---

## Deltas proto HTML vs Godot

| Element | Proto HTML | Godot |
|---|---|---|
| Grille | 6x8 | 6x8 (identique) |
| Familles | Corail/Abyssal/Drift/Shell | Coral/Shell/Ink/Rust |
| Tide | Clic cellule specifique | Drop dans colonne, impact en bas |
| Residu Ghost | Cercle pale pointille | Sprite ghost semi-transparent |
| Visuel jetons | Canvas 2D, chiffres | Sprites PNG, points style des |
| Animations | sleep() entre etapes | Tweens (bounce, pulse, shrink, gravity) |
| Score popup | Pas de popup | Labels flottants par groupe |

---

## Questions ouvertes

- Pas de hover preview encore (ghost du jeton sur la colonne survolee)
- Pas de Dernier Souffle implemente
- Les 4 Pattern Tags sont hardcodes — a migrer vers des .tres quand on introduira le shop
- Score_ui.gd cree mais pas utilise (labels crees dans game.tscn directement)

---

## Prochaines etapes

Le proto Godot est jouable. Prochaines priorites possibles :
1. Continuer le juice (hover preview, shake de cascade, score counter anime)
2. Pattern Tags comme vrai systeme (slots, .tres, resolution conditionnelle visible)
3. Flow de manche complet (deck → jouer → score cible → transition)
4. Shop entre les manches
