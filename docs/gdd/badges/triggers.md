# Triggers

Les moments où les Badges s'activent. 5 triggers au total — chaque Badge en a un.

## Liste des triggers

| Trigger (code) | Quand | Signal source |
|---|---|---|
| `on_round_start` | Début de chaque manche, avant la construction du RunContext | `TurnController.round_started` |
| `on_token_drop` | Quand un jeton est posé sur la grille | `TurnController.token_dropped` |
| `on_cascade_step` | À chaque niveau de cascade résolu | `TurnController.cascade_step_resolved` |
| `on_turn_resolved` | À la fin d'un tour, après toutes les cascades | `TurnController.turn_resolved` |
| `on_last_breath` | Pendant le [Dernier Souffle](../manche/dernier-souffle.md) | `TurnController.last_breath_started` |

## Flow de dispatch

`TurnController` émet le signal → `BadgeManager._dispatch(trigger, event)` → pour chaque Badge équipé dont `badge.trigger == trigger`, appel de `badge.make_effect().apply(event, run_manager)`.

Le `BadgeManager` est câblé à chaque manche via `bind_round(turn_controller)` depuis `GameScene._create_managers()`.

## Contenu typique de l'event

| Trigger | Event payload |
|---|---|
| `on_round_start` | `{}` (vide) |
| `on_token_drop` | `{token, col, row}` |
| `on_cascade_step` | `{cascade_level, earned}` |
| `on_turn_resolved` | `{timeline}` |
| `on_last_breath` | `{}` (vide) |

## Quels triggers sont exploités

Depuis la session 13, les 5 triggers ont au moins un Badge : `on_round_start` (10 Badges), `on_cascade_step` (1, Mouches en Cascade), `on_turn_resolved` (3 : Vertige, Un Pour Tous, Régularité), `on_token_drop` (1, Dernier Carré). `on_last_breath` reste câblé mais sans Badge qui le consomme.

**Contrainte technique historique, résolue en session 13** : `BadgeEffect` est instancié à neuf à chaque dispatch (`badge.make_effect()` dans `BadgeManager._dispatch`) — un effet ne peut pas accumuler d'état dans ses propres variables entre deux déclenchements. `RunManager` porte maintenant un état libre par badge (`get_badge_state`/`set_badge_state`, clé `StringName` → `Variant`, remis à zéro chaque manche) qui contourne cette limite — c'est ce qui permet à Régularité (streak de tours sans cascade) et Un Pour Tous (familles déjà vues) de fonctionner malgré l'instanciation à neuf.

**Piste future** : un 6e trigger `on_fusion` (shop, hors-manche) est envisagé pour des Badges qui interagissent avec la [fusion de boutons](../jetons/boutons.md) — nécessiterait un câblage séparé du `TurnController` puisque le shop n'est pas une manche. Voir [brainstorm-badges.md](../../brainstorms/brainstorm-badges.md).

## Liens

- [Principe](principe.md)
- [Badges implémentés](badges-implementes.md)
- [Déroulement du tour](../manche/deroulement.md)
- [Dernier Souffle](../manche/dernier-souffle.md)
