# Badges implémentés

**15 Badges actifs** dans le proto (4 batchs). Couvrent les 5 triggers (session 13 : `on_token_drop` a eu son premier consommateur, Dernier Carré).

| Badge                  | Trigger            | Effet                                                                                                           | Rareté   |
| ---------------------- | ------------------ | --------------------------------------------------------------------------------------------------------------- | -------- |
| **Mouches en Cascade** | `on_cascade_step`  | +3 mouches par cascade secondaire (level ≥ 1)                                                                   | Common   |
| **Cellule Triple**     | `on_round_start`   | Ajoute une cellule TRIPLE aléatoire chaque manche                                                               | Uncommon |
| **Tranchée**           | `on_round_start`   | Colonnes centrales BOOST (×1.5), colonnes extérieures HALF (×0.5)                                               | Rare     |
| **Famille Unie**       | `on_round_start`   | Les patterns de rule `family` scorent ×2                                                                        | Uncommon |
| **Cellule Double**     | `on_round_start`   | Ajoute une cellule DOUBLE aléatoire chaque manche                                                               | Common   |
| **Écume**              | `on_round_start`   | Toute la rangée du bas passe en BOOST (×1.5)                                                                    | Uncommon |
| **Pourboire**          | `on_round_start`   | +5 mouches fixes en début de manche                                                                             | Common   |
| **Collectionneur**     | `on_round_start`   | Les patterns de rule `rock` scorent ×2 (symétrique de Famille Unie, pour Diamond Rock)                          | Uncommon |
| **Vertige**            | `on_turn_resolved` | +8 mouches si une cascade de profondeur 2+ se déclenche ce tour                                                 | Common   |
| **Colonne Chanceuse**  | `on_round_start`   | Une colonne aléatoire entière passe en BOOST (×1.5)                                                             | Common   |
| **Bord à Bord**        | `on_round_start`   | Les 2 colonnes extérieures passent en BOOST (×1.5) — symétrique de Tranchée                                     | Rare     |
| **Un Pour Tous**       | `on_turn_resolved` | +2 mouches la 1ère fois qu'une famille donnée score, une fois par manche                                        | Common   |
| **Régularité**         | `on_turn_resolved` | 3 tours sans cascade → le prochain pattern résolu est ×1.5 (contrepoids de Vertige)                             | Uncommon |
| **Dernier Carré**      | `on_token_drop`    | Deck ≤ 4 jetons restants → tout ce qui résout ce tour est ×2                                                    | Rare     |
| **Petites Mains**      | `on_round_start`   | Chaque jeton de valeur 1 dans une figure qui score ajoute +0.5 à son multi (par figure, pas cumulé sur le tour) | Uncommon |

Chaque Badge = 1 script d'effet (`scripts/badges/effect_*.gd`) + 1 resource (`resources/badges/badge_*.tres`).

## Indicateur de progression au survol (session 13)

`BadgeEffect.get_progress_text(run_manager) -> String` — méthode virtuelle générique (chaîne vide par défaut), overridée par les Badges à compteur pour afficher leur état au survol dans `BadgesUI`. Régularité affiche "X/3 tours sans cascade", Un Pour Tous affiche "X/4 familles vues cette manche". Réutilisable pour tout futur Badge à compteur, zéro modif de `BadgesUI` nécessaire.

## Dormant

- **Numérologie** — boostait la rule `value` (×2). Hors catalogue actif depuis que la valeur ne résout plus de patterns (session 12) — plus aucun Tag ne l'utilise. Le `.tres` et le script restent sur le disque.

## Reportée

- **Bombe à retardement** ([HOB-10](https://linear.app/hobbes-game/issue/HOB-10)) — les bombes ne sautent plus à l'impact, elles attendent le Dernier Souffle. Plus complexe qu'un simple side-effect car elle modifie le comportement d'un [jeton spécial](../jetons/specials.md).
- **Slot de hold supplémentaire** — idée validée (voir `brainstorm-badges.md`) mais nécessite un refactor du hold (`DeckManager._hold` est un slot unique, pas un compteur) avant de pouvoir l'écrire comme un simple effet.

## Catalogue complet (idées + statuts)

Les pistes non implémentées sont brassées dans `brainstorm-badges.md` (produit cartésien Triggers × Effets). `on_token_drop` et `on_last_breath` restent câblés mais sans Badge qui les consomme.

## Debug

Chaque Badge a un flag `debug_start_equipped: bool` dans son `.tres`. Le cocher dans l'inspector Godot équipe le Badge au démarrage de run, bypass shop. Pratique pour playtester un Badge isolément.

## Liens

- [Principe](principe.md)
- [Triggers](triggers.md)
- [Modifiers de cellules](../grille/modifiers-cellules.md)
- [Scoring — rule multipliers](../partitions/scoring.md)
