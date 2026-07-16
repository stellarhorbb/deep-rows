# Score cible

Le score cible augmente à chaque manche. C'est la source de pression naturelle qui remplace toute mécanique de mise ou de timer.

## Courbe actuelle (session 18 — figée, valeurs hardcodées)

Le linéaire (+30/manche) devenait trivial dès qu'un build multiplicatif prenait (`value_sum × shape_mult × cascade_mult × rule_mult × level_mult × global_mult × scaling_mult`, voir [Scoring](../partitions/scoring.md)) — signal confirmé en session 17 avec un run gagné à 637/390. Remplacé par une courbe exponentielle à accélération quadratique tardive, **hardcodée dans `GameRules.ROUND_TARGETS`** plutôt que calculée en live, pour rendre le retuning manuel plus simple.

| Manche | Zone | Cible | | Manche | Zone | Cible |
|---|---|---|---|---|---|---|
| 1 | Plage | 60 | | 11 | Marais | 400 |
| 2 | Plage | 70 | | 12 | Marais | 500 |
| 3 | Plage | 85 | | 13 | Marais | 620 |
| 4 | Plage | 100 | | 14 | Marais | 770 |
| 5 | Plage (boss) | 120 | | 15 | Marais (boss) | 950 |
| 6 | Forêt | 150 | | 16 | Rêves | 1200 |
| 7 | Forêt | 180 | | 17 | Rêves | 1500 |
| 8 | Forêt | 220 | | 18 | Rêves | 1900 |
| 9 | Forêt | 270 | | 19 | Rêves | 2400 |
| 10 | Forêt (boss) | 330 | | 20 | Rêves (boss) | 3000 |

**Formule de dérivation** (pour retuner la table si besoin, pas utilisée en live) :

```
f(n) = (n - 1) + ACCEL × (n - 1)²
target(n) = round_to_2_sig_figs(BASE_TARGET × GROWTH^f(n))   (grain minimum 5)

BASE_TARGET = 60
GROWTH = 2^(1/4)  ≈ 1.1892   (doublement tous les 4 manches)
ACCEL = 0.01
```

**Boss sans spike** : les manches boss (5, 10, 15, 20) restent sur la même courbe lissée, aucun multiplicateur de cible dédié — le [malus de boss](../progression/structure-run.md#boss-de-zone) porte déjà la difficulté du tour, doubler la peine (malus + cible gonflée) aurait été punitif sans raison.

Un run complet = **5 manches par zone (4 + boss) × 4 zones = 20 manches** (`ROUNDS_PER_ZONE = 5`, `ZONES_PER_RUN = 4` dans `game_rules.gd`).

## Mode infini

Passé la manche 20, la même formule continue de s'appliquer (`f(n)` n'est pas bornée) — l'accélération quadratique garantit un game over inévitable à terme : le ratio de croissance entre paliers de 5 manches grimpe lui-même (×3.3 en manche 25, ×4.5 en manche 40...). Pas encore de table hardcodée au-delà de la manche 20 tant que la boucle de manches du [mode infini](../progression/structure-run.md#mode-infini) n'est pas implémentée — à générer avec la formule ci-dessus le moment venu.

## Condition de défaite

**Deck vide + score cible pas atteint = game over, fin de run.**

Pas de vies, pas de seconde chance, pas de perte progressive. C'est brutal et clair. Le joueur sait exactement pourquoi il a perdu — son build n'était pas assez fort ou son placement était mauvais.

## Questions ouvertes

- **Surplus de score** → bonus de mouches ? À tester.
- **Calibrage réel** — la table ci-dessus repose sur un seul vrai data point (637/390 en session 17, sur l'ancienne courbe à 12 manches). À observer au premier run complet sur les 20 manches avant de retoucher les valeurs.

## Liens

- [Déroulement](deroulement.md)
- [Défaite](../progression/defaite.md)
- [Scoring](../partitions/scoring.md)
- [Structure du run](../progression/structure-run.md)
