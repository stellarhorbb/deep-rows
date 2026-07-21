# Triggers

Les moments où les Badges s'activent. 12 triggers au total — chaque Badge en a un.

## Liste des triggers

| Trigger (code) | Quand | Signal source |
|---|---|---|
| `on_round_start` | Début de chaque manche, avant la construction du RunContext | `TurnController.round_started` |
| `on_token_drop` | Quand un jeton est posé sur la grille | `TurnController.token_dropped` |
| `on_cascade_step` | À chaque niveau de cascade résolu | `TurnController.cascade_step_resolved` |
| `on_turn_resolved` | À la fin d'un tour, après toutes les cascades | `TurnController.turn_resolved` |
| `on_last_breath` | Pendant le [Dernier Souffle](../manche/dernier-souffle.md) | `TurnController.last_breath_started` |
| `on_round_end` | Fin de manche réussie, juste avant l'écran YouWinUI | `BadgeManager.dispatch_round_end()` (appelé par `GameScene`, pas un signal `TurnController`) |
| `on_level_up` (session 17) | Une Partition franchit un palier de niveau, en cours de manche | `RunManager.tag_leveled_up` |
| `on_deck_grown` (session 17) | Le pool de boutons vient de grandir (achat au shop, scission) — pas les retraits (fusion, vente) | `RunManager.button_pool_changed`, filtré par delta de taille dans `BadgeManager._on_button_pool_changed` |
| `on_shake_used` (session 22) | Un Shake vient d'être déclenché par le joueur (charge dépensée avec succès) | `TurnController.shake_used` |
| `on_sheet_sold` (session 22) | Une Partition équipée vient d'être vendue au shop | `RunManager.sheet_sold` |
| `on_figure_promoted` (session 22) | Une figure (Valet+) vient d'avancer d'un cran par le score (arcanes mineurs) | `RunManager.figure_promoted` |
| `on_deck_tool_shown` (session 22) | Un slot "Dé à coudre" vient d'apparaître dans l'offre du shop (au plus 1x par visite, pas à chaque reroll) | `BadgeManager.dispatch_deck_tool_shown()` (appelé par `ShopUI._ready()`, pas un signal `TurnController`) |

## Flow de dispatch

`TurnController` émet le signal → `BadgeManager._dispatch(trigger, event)` → pour chaque Badge équipé dont `badge.trigger == trigger`, appel de `badge.make_effect().apply(event, run_manager)`.

Le `BadgeManager` est câblé à chaque manche via `bind_round(turn_controller)` depuis `GameScene._create_managers()`. Particularité pour `on_level_up`/`on_deck_grown` (session 17) : leurs signaux sources vivent sur `RunManager`, qui persiste toute la run (contrairement à `TurnController`, recréé chaque manche) — `bind_round` s'y connecte quand même par cohérence avec le reste du câblage, mais protégé par `is_connected()` pour ne jamais dupliquer la connexion d'une manche à l'autre.

## Contenu typique de l'event

| Trigger | Event payload |
|---|---|
| `on_round_start` | `{}` (vide) |
| `on_token_drop` | `{token, col, row}` |
| `on_cascade_step` | `{cascade_level, earned}` |
| `on_turn_resolved` | `{timeline, grid_manager}` (grid_manager ajouté session 17, pour les Badges qui mutent la grille après coup — ex: Récif vivant) |
| `on_last_breath` | `{}` (vide) |
| `on_round_end` | `{}` (vide) |
| `on_level_up` | `{tag_name, new_level}` |
| `on_deck_grown` | `{count}` (nombre de jetons ajoutés depuis le dernier changement) |
| `on_shake_used` | `{}` (vide) |
| `on_sheet_sold` | `{sheet_name}` |
| `on_figure_promoted` | `{new_value}` (valeur de la figure APRÈS promotion — voir `GameRules.FACE_CARD_VALUES`) |
| `on_deck_tool_shown` | `{}` (vide) |

## Quels triggers sont exploités

11 des 12 ont au moins un Badge. `on_round_start` reste le plus chargé (la majorité des Badges à condition statique posée une fois par manche). `on_last_breath` reste câblé mais sans Badge qui le consomme.

**Contrainte technique historique, résolue en session 13** : `BadgeEffect` est instancié à neuf à chaque dispatch (`badge.make_effect()` dans `BadgeManager._dispatch`) — un effet ne peut pas accumuler d'état dans ses propres variables entre deux déclenchements. `RunManager` porte un état libre par badge (`get_badge_state`/`set_badge_state`, remis à zéro chaque manche) pour les compteurs de manche (streak de Régularité, familles vues de Un Pour Tous), et un second état **jamais remis à zéro en cours de run** (`get_run_badge_state`/`set_run_badge_state`, session 17) pour les Badges "scaling permanent" qui doivent survivre aux transitions de manche (Jetons sacrés, Quatre quart, Escalade musicale, Amélioration continue, Gourmand...).

**Cas particulier "Econome"** : son effet (reroll gratuit au shop) ne passe par aucun trigger — le shop n'a pas de moment "on_shop_enter" dans ce système, câblé uniquement sur les manches. `ShopUI` vérifie directement `RunManager.has_badge(&"econome")` à l'ouverture. Son `trigger` dans `BadgeData` n'est donc qu'une valeur de remplissage, jamais réellement dispatché pour cet effet.

## Liens

- [Principe](principe.md)
- [Badges implémentés](badges-implementes.md)
- [Déroulement du tour](../manche/deroulement.md)
- [Dernier Souffle](../manche/dernier-souffle.md)
