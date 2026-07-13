# Score cible

Le score cible augmente à chaque manche (`BASE_TARGET` + `TARGET_INCREMENT × (manche - 1)` dans `game_rules.gd`). C'est la source de pression naturelle qui remplace toute mécanique de mise ou de timer.

## Courbe actuelle

| Manche | Score cible (exemple) |
|---|---|
| 1 | 60 |
| 2 | 90 |
| 3 | 120 |
| ... | +30 par manche |

*(Corrigé session 15 — le tableau affichait 100/130/160 alors que `BASE_TARGET = 60` dans `game_rules.gd`.)*

Un run complet = **3 manches par zone × 4 zones = 12 manches** au format actuel — chiffre remis en question depuis la session 16 avec l'introduction d'une manche boss par zone, voir [Structure du run](../progression/structure-run.md).

## Condition de défaite

**Deck vide + score cible pas atteint = game over, fin de run.**

Pas de vies, pas de seconde chance, pas de perte progressive. C'est brutal et clair. Le joueur sait exactement pourquoi il a perdu — son build n'était pas assez fort ou son placement était mauvais.

## Questions ouvertes

- **Courbe linéaire ou exponentielle ?** Actuellement linéaire (+30 par manche) sur une campagne dont la longueur elle-même est en chantier (voir ci-dessus). Le scoring accumule de plus en plus de sources multiplicatives qui se composent entre elles (`shape_mult × cascade_mult × modifier_mult × rule_mult × level_mult × global_mult × value_bonus_mult`, voir [Scoring](../partitions/scoring.md)) — une cible linéaire risque de devenir triviale dès qu'un build multiplicatif prend. Session 16 : c'est surtout en [mode infini](../progression/structure-run.md#mode-infini) qu'une courbe exponentielle devient nécessaire pour garantir un game over inévitable ; la campagne fixe peut rester plus douce. À trancher une fois plus de leviers multiplicatifs en place pour avoir de vraies données de scaling à calibrer dessus plutôt que deviner à vide.
- **Surplus de score** → bonus de mouches ? À tester.

## Liens

- [Déroulement](deroulement.md)
- [Défaite](../progression/defaite.md)
- [Scoring](../partitions/scoring.md)
- [Structure du run](../progression/structure-run.md)
