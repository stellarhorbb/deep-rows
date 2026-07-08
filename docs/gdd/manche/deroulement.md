# Déroulement d'un tour

## Avant le premier tour

Au démarrage de chaque manche, la [grille cabossée](../grille/trous.md) génère 5 à 8 trous aléatoires (jamais en row 0) avant que le joueur ne joue son premier drop.

## Les 5 étapes d'un tour

### 1. Stream
Le jeton courant est présenté depuis le [deck](deck.md). La preview affiche les 3 suivants.

### 2. Hold (optionnel)
Le joueur peut [mettre le jeton courant en hold](stream-hold.md). Le suivant prend sa place.

### 3. Drop
Le joueur choisit une colonne. Le jeton tombe par gravité (voir [Gravité et résolution](../grille/gravite-resolution.md)).

Signal `token_dropped(token, col, row)` émis → déclenche les [Badges](../badges/triggers.md) avec trigger `on_token_drop`.

### 4. Résolution immédiate
Check des patterns sur toute la grille. Les figures correspondant à une [Partition équipée](../partitions/principe.md) scorent et disparaissent. La gravité redistribue. Cascades jusqu'à stabilisation.

Signal `cascade_step_resolved(level, earned)` émis pour chaque niveau MATCH → déclenche les Badges avec trigger `on_cascade_step`.

Puis `turn_resolved(timeline)` → déclenche `on_turn_resolved`.

### 5. Jeton suivant
[Entity](../univers/personnages/entity.md) : tous les 6 tours joueur, un [jeton entity-skull](../jetons/entity-skull.md) est lâché dans une colonne aléatoire non pleine.

Puis retour à l'étape 1 pour le prochain jeton.

## Fin de manche

Deux façons de finir :
- **Deck vide** → [Dernier Souffle](dernier-souffle.md)
- À tout moment pendant la résolution → check du [score cible](score-cible.md)

## Verdict

- Score cible **atteint** → récompense en [mouches](../progression/monnaies.md), transition vers shop puis manche suivante
- Score cible **pas atteint** après le Dernier Souffle → **game over, fin de run**

## Liens

- [Deck](deck.md)
- [Stream + Hold](stream-hold.md)
- [Score cible](score-cible.md)
- [Dernier Souffle](dernier-souffle.md)
- [Scoring](../partitions/scoring.md)
- [Badges — triggers](../badges/triggers.md)
- [Grille cabossée (trous)](../grille/trous.md)
