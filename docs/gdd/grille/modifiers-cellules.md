# Modifiers de cellules

Une couche qui fait évoluer la grille au fil du run. Certaines cellules portent un multiplicateur appliqué à tout pattern qui les traverse.

## Types implémentés

| Type (code) | Multi | Couleur UI |
|---|---|---|
| `MODIFIER_HALF` | ×0.5 | rouge |
| `MODIFIER_BOOST` | ×1.5 | vert |
| `MODIFIER_DOUBLE` | ×2.0 | bleu foncé |
| `MODIFIER_TRIPLE` | ×3.0 | violet |

Autres pistes non implémentées : TRAP, VOID.

## Fonctionnement technique

`RunManager` porte un dict `_grid_modifiers: Vector2i → StringName`, snapshooté dans `RunContext.grid_modifiers`, lu par `CascadeResolver._grid_modifier_multiplier`.

**Dédupliqué par type, pas par cellule (bug corrigé session 18)** : toucher une case d'un type donné suffit à activer son multiplicateur pour tout le groupe — plusieurs cases du même type dans le même pattern ne le cumulent plus (ex : une Ligne 5 entièrement dans une colonne DOUBLE reste ×2, pas ×32). Des **types différents** sur des cases différentes du même pattern restent cumulatifs entre eux (ex : une case DOUBLE + une case BOOST dans le même groupe → ×2 × ×1.5 = ×3).

## Sources

| Source | Statut |
|---|---|
| [Badges](../badges/badges-implementes.md) (`on_round_start`) | **Implémenté** — ex : Cellule Triple, Tranchée |
| Layouts de zone | Prévu — certaines zones démarrent avec des modifiers pré-placés |
| Jetons spéciaux | Prévu — un special qui laisse un modifier après résolution |
| Shop | Prévu — acheter un modifier à placer librement |
| [Entity](../univers/personnages/entity.md) | Prévu — perturbations hostiles (cases HALF, TRAP...) |

**Actuellement 1 source active (Badges).** Les règles d'override, la lisibilité UI et la coexistence de sources sont tracées dans [HOB-11](https://linear.app/hobbes-game/issue/HOB-11).

## Liens

- [Scoring](../partitions/scoring.md)
- [Badges — cartes implémentées](../badges/badges-implementes.md)
- [Entity — perturbations](../univers/personnages/entity.md)
