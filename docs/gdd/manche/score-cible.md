# Score cible

Le score cible augmente à chaque manche (`BASE_TARGET` + `TARGET_INCREMENT × (manche - 1)` dans `game_rules.gd`). C'est la source de pression naturelle qui remplace toute mécanique de mise ou de timer.

## Courbe actuelle

| Manche | Score cible (exemple) |
|---|---|
| 1 | 100 |
| 2 | 130 |
| 3 | 160 |
| ... | +30 par manche |

Un run complet = **3 manches par zone × 4 zones = 12 manches**.

## Condition de défaite

**Deck vide + score cible pas atteint = game over, fin de run.**

Pas de vies, pas de seconde chance, pas de perte progressive. C'est brutal et clair. Le joueur sait exactement pourquoi il a perdu — son build n'était pas assez fort ou son placement était mauvais.

## Questions ouvertes

- **Courbe linéaire ou exponentielle ?** Actuellement linéaire (+30 par manche). À revoir avec les multiplicateurs directionnels et le level up des Partitions qui scalent différemment.
- **Surplus de score** → bonus de mouches ? À tester.

## Liens

- [Déroulement](deroulement.md)
- [Défaite](../progression/defaite.md)
- [Scoring](../partitions/scoring.md)
- [Structure du run](../progression/structure-run.md)
