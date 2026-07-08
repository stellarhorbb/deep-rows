# Gravité et résolution immédiate

## Le geste

Le jeton tombe au bas de la colonne choisie, comme au puissance 4. Le joueur choisit uniquement la colonne — la gravité décide de la ligne.

## Résolution immédiate

Chaque drop déclenche les interactions **instantanément** :

1. Drop → le jeton atterrit
2. Check des patterns sur toute la grille
3. Les patterns compatibles avec une [Partition équipée](../partitions/principe.md) scorent et disparaissent
4. La gravité redistribue les jetons restants
5. Re-check pour cascades
6. Boucle jusqu'à stabilisation

La grille ne se fige jamais. Chaque drop la reconfigure.

## Cascades

Quand des jetons disparaissent, ceux du dessus tombent. Ces retombées peuvent créer de nouvelles adjacences, qui déclenchent de nouvelles résolutions.

**Scoring cascade** : x2 par niveau (`CASCADE_MULTIPLIER_BASE` dans `game_rules.gd`). Voir [Scoring](../partitions/scoring.md) pour le détail.

Les cascades sont le **moment spectaculaire** du jeu. Le joueur construit les conditions, mais la cascade elle-même est automatique et souvent surprenante.

## Trous

Depuis la session 12, quelques cases de la grille peuvent être des [trous](trous.md) — la gravité les traverse sans jamais y poser de jeton. À ne pas confondre avec un [Rock](../jetons/rocks.md), qui bloque et sert d'appui.

## Liens

- [Format de la grille](format.md)
- [Grille cabossée (trous)](trous.md)
- [Scoring](../partitions/scoring.md)
- [Modifiers de cellules](modifiers-cellules.md)
- [Dernier Souffle](../manche/dernier-souffle.md)
