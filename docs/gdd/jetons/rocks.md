# Les Rocks

Le **scaffold** — jetons sans famille ni valeur qui ne participent à aucun pattern et ne scorent jamais. **4 rocks par défaut** dans chaque deck (`DECK_ROCK_COUNT` dans `game_rules.gd`).

## Pourquoi ils existent

- **Du relief sur la grille** — un rock posé au milieu d'une colonne force des diagonales et des constructions au-dessus
- **Un puzzle de placement** — "où est-ce que je le cale pour qu'il me serve plus tard plutôt que de me gêner ?"
- **De la texture au deck** — piocher un rock change le rythme, oblige à improviser
- **Un terrain pour les Badges** — les rocks sont une dimension dédiée à exploiter

## Comportement

- Tombent par gravité comme n'importe quel jeton
- Ne se résolvent pas, ne scorent pas, **restent sur la grille** pendant toute la manche
- **Au [Dernier Souffle](../manche/dernier-souffle.md), ils explosent** — leurs trous déclenchent une cascade finale

## Exception : Diamond Rock

Les rocks participent à **une seule Partition** : le [Losange Rock](../partitions/catalogue-implemente.md) — 4 rocks disposés autour d'un jeton central (haut/bas/gauche/droite). C'est le centre qui score, les rocks restent où ils sont.

Depuis la session 12, la forme losange existe aussi en version **famille** (Family Diamond — 4 jetons de même famille autour d'un centre indifférent, sans rock). Les deux variantes partagent la même détection (`PatternMatcher.find_diamonds`) mais scorent différemment — voir [Scoring](../partitions/scoring.md).

## Liens

- [Boutons](boutons.md)
- [Dernier Souffle](../manche/dernier-souffle.md)
- [Catalogue de partitions](../partitions/catalogue-implemente.md)
