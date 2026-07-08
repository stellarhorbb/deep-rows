# Catalogue implémenté

**10 Partitions actives** dans le proto (session 12 : la valeur ne résout plus de patterns, seuls famille et rock restent actifs — voir [Axes de règles](axes-de-regles.md). Session 13 : 4 nouvelles formes — Plus, Cross, Ring, T — voir [Formes](formes.md)).

Les labels affichés en jeu ne montrent plus "FAMILY" (redondant, quasi tout le catalogue actif est en rule `family`) — nettoyé en session 13, voir `TagsUI._format_tag_label`.

| Partition | Forme | Règle | Taille min | Direction | Mult | Prix |
|---|---|---|---|---|---|---|
| Line 4 | Ligne | Famille | 4 | any | direction | 6 |
| Line 3 | Ligne | Famille | 3 | any | direction | 6 |
| Line 5 | Ligne | Famille | 5 | any | direction | 10 |
| Square 4 | Carré 2×2 | Famille | 4 | — | ×2 fixe | 8 |
| Diamond Rock | Losange | 4 rocks autour d'un centre scorable | 4 | — | ×4 fixe (sur le centre) | 12 |
| Diamond | Losange | 4 jetons même famille, centre indifférent | 4 | — | ×2.5 fixe (somme des 4) | 10 |
| Plus | Croix orthogonale | Famille (centre inclus) | 5 | any | ×3 fixe | 10 |
| Cross | Croix diagonale | Famille (centre inclus) | 5 | any | ×3 fixe | 12 |
| Ring | Cadre 3×3 | Famille (centre indifférent) | 8 | any | ×5 fixe | 15 |
| T | Tétromino | Famille (orientation libre) | 4 | any | ×2 fixe | 7 |

Pour les lignes "any direction", le multiplicateur est celui de la direction du match au moment de la résolution.

## Chevauchement de figures (session 13)

Deux Tags différents peuvent matcher des groupes qui se recouvrent (ex : un Plus complet contient toujours un T valide sur 4 de ses 5 cellules). `CascadeResolver.resolve` trie les groupes candidats par score décroissant et n'accepte un groupe que si le nombre de ses cellules déjà revendiquées par un groupe mieux payé ne dépasse pas `GameRules.PATTERN_SHARED_CELL_TOLERANCE` (1 actuellement) :
- **1 cellule commune** (typiquement le jeton qui vient d'être posé, point de convergence de deux figures distinctes) → les deux scorent, combo délibéré récompensé
- **2+ cellules communes** (une figure contient largement une autre, ex Plus ⊃ T, Ligne 4 ⊃ Ligne 3) → seule la mieux payée compte

Voir [Décisions tranchées](../meta/decisions-tranchees.md) pour le raisonnement complet, y compris pourquoi certaines paires de Partitions (T + Plus, Ligne 3 + Ligne 4...) restent volontairement anti-synergiques par construction — au joueur de gérer via la vente.

## Dormantes (valeur/suite — hors catalogue actif)

Les .tres existent toujours sur le disque et le moteur les supporte encore, juste retirées de `ShopManager.TAG_PATHS` :

| Partition | Forme | Règle | Statut |
|---|---|---|---|
| Number Line 3 | Ligne | Chiffre | Dormant |
| Number Line 4 Horiz | Ligne | Chiffre | Dormant |
| Number Square | Carré 2×2 | Chiffre | Dormant |
| Suite 3 Diagonal | Ligne | Chiffres consécutifs | Dormant |

À réactiver le jour où la valeur redevient un axe de résolution (contenu rare, Shore...).

## Sélection de départ (session 12)

Plus de starter pack hardcodé. Au démarrage de la run (et après chaque fin de run), un **écran de sélection** tire 3 Partitions au hasard dans tout le catalogue actif ; le joueur en choisit **2, gratuites**. Voir [Principe](principe.md).

Les Partitions non choisies au démarrage restent achetables plus tard au shop.

## Catalogue complet (idées + statuts)

Les idées non implémentées sont listées dans `docs/content/partitions.csv` et brassées dans `brainstorm-pattern-tags.md`. Pool cible final : 20-30 Partitions.

## Liens

- [Principe](principe.md)
- [Formes](formes.md)
- [Axes de règles](axes-de-regles.md)
- [Scoring](scoring.md)
- [Shop — packs](../shop/packs.md)
