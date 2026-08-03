# Déroulement d'un tour

## Avant le premier tour

Au démarrage de chaque manche, dans cet ordre (revu session 26) :

1. La [grille cabossée](../grille/trous.md) génère le fond marin + les trous rouges
2. La [persistance entre manches](persistance-entre-manches.md) fait retomber les jetons qui ont survécu à la manche précédente (animation de chute, gauche à droite)
3. Les cases mystère apparaissent (en évitant trous ET jetons persistés), avec un petit effet de particules

... avant que le joueur ne joue son premier drop.

## Les 5 étapes d'un tour

### 1. Stream
Le jeton courant est présenté depuis le [deck](deck.md). La preview affiche les 3 suivants.

### 2. Hold (optionnel)
Le joueur peut [mettre le jeton courant en hold](stream-hold.md). Le suivant prend sa place.

### 3. Drop
Le joueur choisit une colonne. Le jeton tombe par gravité (voir [Gravité et résolution](../grille/gravite-resolution.md)).

Signal `token_dropped(token, col, row)` émis → déclenche les [Sortilèges](../sortileges/triggers.md) avec trigger `on_token_drop`.

### 4. Résolution immédiate
Check des patterns sur toute la grille. Les figures correspondant à une [Partition équipée](../partitions/principe.md) scorent et disparaissent. La gravité redistribue. Cascades jusqu'à stabilisation.

Signal `cascade_step_resolved(level, earned)` émis pour chaque niveau MATCH → déclenche les Sortilèges avec trigger `on_cascade_step`.

Puis `turn_resolved(timeline)` → déclenche `on_turn_resolved`.

### 5. Jeton suivant
[Entity](../univers/personnages/entity.md) : chance croissante depuis le dernier drop (revu session 26, plus d'intervalle fixe) qu'un [jeton entity-skull](../jetons/entity-skull.md) soit lâché dans une colonne aléatoire non pleine.

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
- [Sortilèges — triggers](../sortileges/triggers.md)
- [Grille cabossée (trous)](../grille/trous.md)
- [Persistance entre manches](persistance-entre-manches.md)
