# Catalogue implémenté

**17 Partitions actives** dans le proto (session 12 : la valeur ne résout plus de patterns sur les formes famille, seuls famille et rock restent actifs — voir [Axes de règles](axes-de-regles.md). Session 13 : 4 nouvelles formes — Plus, Cross, Ring, T. Session 14 : Rainbow sur l'axe famille + retour de la valeur sous vocabulaire casino confiné aux lignes, voir [Formes](formes.md) et [Axes de règles](axes-de-regles.md)).

Les labels affichés en jeu ne montrent plus "FAMILY" (redondant, quasi tout le catalogue actif est en rule `family`) — nettoyé en session 13, voir `TagsUI._format_tag_label`. Depuis la session 14, `_format_tag_label` distingue aussi `value`/`rainbow`/`fibonacci` (sinon Brelan et Line 3 auraient affiché le même libellé en jeu).

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
| Square Rainbow | Carré 2×2 | 4 familles distinctes | 4 | — | ×3 fixe | 12 |
| Diamond Rainbow | Losange | 4 familles distinctes, centre indifférent | 4 | — | ×3.5 fixe (somme des 4) | 14 |
| Line 4 Rainbow | Ligne | 4 familles distinctes | 4 | any | direction | 10 |
| Suite | Ligne | Valeurs consécutives (any sens) | 3 | any | direction | 14 |
| Brelan | Ligne | Même valeur | 3 | any | direction | 6 |
| Carré | Ligne | Même valeur (clin d'œil poker, pas la forme carrée) | 4 | any | direction | 8 |
| Fibonacci | Ligne | 1, 1, 2, 3 (dans un sens ou l'autre) | 4 | any | direction | 14 |

Pour les lignes "any direction", le multiplicateur est celui de la direction du match au moment de la résolution — vrai aussi pour Rainbow/Suite/Brelan/Carré/Fibonacci puisqu'ils vivent tous sur la forme Ligne (voir [Formes](formes.md)).

## Rainbow, casino (session 14)

Détection dans `PatternMatcher` :
- **Rainbow** (Square/Diamond/Line 4) — `_all_families_distinct()`, un nouveau helper. Plafonné à taille 4 par `GameRules.FAMILY_COUNT` (4 familles existantes, impossible d'aligner plus sans répétition). Square/Diamond étendent `find_squares`/`find_diamonds` existants ; Line 4 Rainbow a sa propre fonction `find_line_rainbow` (fenêtre fixe, pas d'extension incrémentale comme les lignes famille).
- **Suite/Brelan/Carré** — aucune nouvelle logique de détection : ce sont les anciennes Partitions dormantes "chiffre" (`line_number_3`, `line_number_4_horizontal`, `suite_3_diagonal`) simplement renommées/relabellées (`brelan.tres`, `carre_poker.tres`, `suite.tres`) et remises dans `ShopManager.TAG_PATHS`. Le moteur (`find_lines`, rules `value`/`suite`) n'a pas changé.
- **Fibonacci** — cible fixe `GameRules.FIBONACCI_SEQUENCE` (1,1,2,3), nouvelle fonction dédiée `find_fibonacci` (fenêtre fixe, matche la cible dans un sens ou l'autre le long de l'axe).
- Le Badge Numérologie (`rule == "value"` ×2) reste hors catalogue actif mais boosterait déjà Brelan/Carré sans changement — non réactivé pour l'instant, à décider séparément.

## Chevauchement de figures (session 13)

## Chevauchement de figures (session 13)

Deux Tags différents peuvent matcher des groupes qui se recouvrent (ex : un Plus complet contient toujours un T valide sur 4 de ses 5 cellules). `CascadeResolver.resolve` trie les groupes candidats par score décroissant et n'accepte un groupe que si le nombre de ses cellules déjà revendiquées par un groupe mieux payé ne dépasse pas `GameRules.PATTERN_SHARED_CELL_TOLERANCE` (1 actuellement) :
- **1 cellule commune** (typiquement le jeton qui vient d'être posé, point de convergence de deux figures distinctes) → les deux scorent, combo délibéré récompensé
- **2+ cellules communes** (une figure contient largement une autre, ex Plus ⊃ T, Ligne 4 ⊃ Ligne 3) → seule la mieux payée compte

Voir [Décisions tranchées](../meta/decisions-tranchees.md) pour le raisonnement complet, y compris pourquoi certaines paires de Partitions (T + Plus, Ligne 3 + Ligne 4...) restent volontairement anti-synergiques par construction — au joueur de gérer via la vente.

## Dormantes (hors catalogue actif)

| Partition | Forme | Règle | Statut |
|---|---|---|---|
| Number Square | Carré 2×2 | Chiffre | Dormant — l'axe casino reste volontairement confiné à la Ligne (session 14), voir [Axes de règles](axes-de-regles.md) |

Number Line 3, Number Line 4 Horiz et Suite 3 Diagonal ont été réactivées en session 14 sous les noms Brelan/Carré/Suite (voir tableau ci-dessus) — mêmes `.tres` renommés, même moteur de détection.

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
