# Badges implémentés

**37 Badges actifs** dans le proto (8 batchs). Couvrent les 8 triggers (session 13 : `on_token_drop` a eu son premier consommateur, Dernier Carré ; session 16 : `on_round_end` ajouté, premier consommateur Pourboire, voir [Monnaies](../progression/monnaies.md) ; session 17 : `on_level_up` et `on_deck_grown` ajoutés, voir [Triggers](triggers.md)).

| Badge                  | Trigger            | Effet                                                                                                           | Rareté   |
| ---------------------- | ------------------ | --------------------------------------------------------------------------------------------------------------- | -------- |
| **Mouches en Cascade** | `on_cascade_step`  | +3 mouches par cascade secondaire (level ≥ 1)                                                                   | Common   |
| **Cellule Triple**     | `on_round_start`   | Ajoute une cellule TRIPLE aléatoire chaque manche                                                               | Uncommon |
| **Tranchée**           | `on_round_start`   | Colonnes centrales BOOST (×1.5), colonnes extérieures HALF (×0.5)                                               | Rare     |
| **Famille Unie**       | `on_round_start`   | Les patterns de rule `family` scorent ×2                                                                        | Uncommon |
| **Cellule Double**     | `on_round_start`   | Ajoute une cellule DOUBLE aléatoire chaque manche                                                               | Common   |
| **Écume**              | `on_round_start`   | Toute la rangée du bas passe en BOOST (×1.5)                                                                    | Uncommon |
| **Pourboire**          | `on_round_end`     | +3 mouches fixes en fin de manche, visible sur l'écran YouWinUI (session 16, était `on_round_start`)             | Common   |
| **Collectionneur**     | `on_round_start`   | Les patterns de rule `rock` scorent ×2 (symétrique de Famille Unie, pour Diamond Rock)                          | Uncommon |
| **Vertige**            | `on_turn_resolved` | +10 mouches si une cascade de profondeur **2+** se déclenche ce tour (session 16 : seuil et valeur remontés depuis 1+/+5)                                                 | Common   |
| **Colonne Chanceuse**  | `on_round_start`   | Une colonne aléatoire entière passe en BOOST (×1.5)                                                             | Common   |
| **Bord à Bord**        | `on_round_start`   | Les 2 colonnes extérieures passent en BOOST (×1.5) — symétrique de Tranchée                                     | Rare     |
| **Un Pour Tous**       | `on_turn_resolved` | +2 mouches la 1ère fois qu'une famille donnée score, une fois par manche                                        | Common   |
| **Régularité**         | `on_turn_resolved` | 3 tours sans cascade → le prochain pattern résolu est ×1.5 (contrepoids de Vertige)                             | Uncommon |
| **Dernier Carré**      | `on_token_drop`    | Deck ≤ 4 jetons restants → tout ce qui résout ce tour est ×2                                                    | Rare     |
| **Petites Mains**      | `on_round_start`   | Chaque jeton de valeur 1 dans une figure qui score ajoute +0.5 à son multi (par figure, pas cumulé sur le tour) | Uncommon |
| **Vingt-trois**        | `on_round_start`   | Les jetons de valeur 2 et 3 qui scorent recomptent leur valeur une deuxième fois (session 17)                   | Common   |
| **Saint Pair**         | `on_round_start`   | Les jetons de valeur paire qui scorent recomptent leur valeur une deuxième fois (session 17)                    | Uncommon |
| **Impair profane**     | `on_round_start`   | Les jetons de valeur impaire qui scorent recomptent leur valeur une deuxième fois (session 17)                  | Uncommon |
| **Y'en a pas deux**    | `on_round_start`   | +5 points quand une Partition score avec une paire de chiffres (session 17)                                     | Common   |
| **Sommet**             | `on_round_start`   | +10 points à chaque Partition qui score tant qu'un jeton occupe la rangée la plus haute (session 17)            | Uncommon |
| **Tickets Hivernal**   | `on_round_start`   | +2 points par jeton DENIERS qui score, peu importe le pattern (session 17, renommée session 18 ex-Encrée/INK, passé de +5/pattern à +2/jeton session 19)         | Common   |
| **Tickets Automnal**   | `on_round_start`   | +2 points par jeton EPEES qui score, peu importe le pattern (session 17, renommée session 18 ex-Rouillée/RUST, passé de +5/pattern à +2/jeton session 19)        | Common   |
| **Tickets Estival**    | `on_round_start`   | +2 points par jeton COUPES qui score, peu importe le pattern (session 17, renommée session 18 ex-Nacrée/SHELL, passé de +5/pattern à +2/jeton session 19)        | Common   |
| **Tickets Printanier** | `on_round_start`   | +2 points par jeton BATONS qui score, peu importe le pattern (session 17, renommée session 18 ex-Coraillée/CORAL, passé de +5/pattern à +2/jeton session 19)     | Common   |
| **Jetons sacrés**      | `on_token_drop`    | Chaque spécial joué ajoute +0.1 au multi, cumulé sur toute la run — scaling permanent (session 17)               | Uncommon |
| **Quatre quart**       | `on_turn_resolved` | Chaque Partition de 4 jetons scorée ajoute +1 point, cumulé sur toute la run — scaling permanent (session 17, nerfé de +5 après playtest : +20 en une manche) | Uncommon |
| **Poker Face**         | `on_round_start`   | Chaque jeton qui score a 10% de chance de gagner +1 de valeur dans le deck, animé en direct sur le jeton avant qu'il disparaisse (session 17, nerfé de 25% après playtest : +6 jetons upgradés en une manche — voir [Scoring — upgrade en direct](../partitions/scoring.md#upgrade-en-direct-poker-face-session-17)) | Legendary |
| **Mouche cubique**     | `on_turn_resolved` | +1 mouche à chaque fois qu'un 3 score dans une Partition (session 17)                                            | Uncommon |
| **Visionnaire**        | `on_round_start`   | +1 jeton visible dans la preview du stream (session 17)                                                          | Rare     |
| **Bénédiction**        | `on_round_start`   | +1 slot de hold — refonte de `DeckManager` en slots multiples, hold cliquable individuellement (session 17)      | Rare     |
| **Récif vivant**       | `on_round_start`   | Quand une Partition score, un jeton aléatoire parmi ceux scorés laisse place à un rock au lieu de disparaître (session 17) | Uncommon |
| **Mouche dorée**       | `on_turn_resolved` | Ajoute au score de chaque Partition un bonus de points égal aux mouches possédées — lecture live, pas un compteur (session 17) | Uncommon |
| **Mouche mélomane**    | `on_level_up`      | +5 mouches à chaque fois qu'une Partition gagne un niveau (session 17)                                           | Uncommon |
| **Escalade musicale**  | `on_level_up`      | Chaque level up de Partition cumule +0.1 au multi, cumulé sur toute la run — scaling permanent (session 17)      | Epic     |
| **Amélioration continue** | `on_level_up`   | Chaque level up de Partition cumule +5 points, cumulé sur toute la run — scaling permanent (session 17)          | Uncommon |
| **Gourmand**           | `on_deck_grown`    | Chaque jeton ajouté au deck (achat ou scission) cumule +5 points, cumulé sur toute la run — scaling permanent (session 17) | Rare |
| **Économe**            | (aucun — voir note)| Un reroll gratuit par visite au shop, vérifié directement par `ShopUI` (session 17)                              | Common   |

Chaque Badge = 1 script d'effet (`scripts/badges/effect_*.gd`) + 1 resource (`resources/badges/badge_*.tres`). Les 9 Badges "bonus flat au value_sum" et les 3 Badges "scaling permanent" de session 17 partagent chacun une fondation commune : voir [Scoring — bonus flat au value_sum](../partitions/scoring.md#bonus-flat-au-value_sum-session-17) et [Scoring — scaling permanent](../partitions/scoring.md#scaling-permanent-session-17).

## Indicateur de progression au survol (session 13)

`BadgeEffect.get_progress_text(run_manager) -> String` — méthode virtuelle générique (chaîne vide par défaut), overridée par les Badges à compteur pour afficher leur état au survol dans `BadgesUI`. Régularité affiche "X/3 tours sans cascade", Un Pour Tous affiche "X/4 familles vues cette manche". Réutilisable pour tout futur Badge à compteur, zéro modif de `BadgesUI` nécessaire.

## Dormant

- **Numérologie** — boostait la rule `value` (×2). Hors catalogue actif depuis que la valeur ne résout plus de patterns (session 12) — plus aucun Tag ne l'utilise. Le `.tres` et le script restent sur le disque.

## Reportée

- **Bombe à retardement** ([HOB-10](https://linear.app/hobbes-game/issue/HOB-10)) — les bombes ne sautent plus à l'impact, elles attendent le Dernier Souffle. Plus complexe qu'un simple side-effect car elle modifie le comportement d'un [jeton spécial](../jetons/specials.md).

## Catalogue complet (idées + statuts)

Les pistes non implémentées sont brassées dans `brainstorm-badges.md` (produit cartésien Triggers × Effets). Seul `on_last_breath` reste câblé sans Badge qui le consomme (voir [Triggers](triggers.md)) — `on_token_drop` a bien des consommateurs (Dernier Carré, Jetons sacrés).

## Debug

Chaque Badge a un flag `debug_start_equipped: bool` dans son `.tres`. Le cocher dans l'inspector Godot équipe le Badge au démarrage de run, bypass shop. Pratique pour playtester un Badge isolément.

## Liens

- [Principe](principe.md)
- [Triggers](triggers.md)
- [Modifiers de cellules](../grille/modifiers-cellules.md)
- [Scoring — rule multipliers](../partitions/scoring.md)
