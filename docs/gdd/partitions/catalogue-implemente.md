# Catalogue implémenté

**17 Partitions actives** dans le proto (session 12 : la valeur ne résout plus de patterns sur les formes famille, seuls famille et rock restent actifs — voir [Axes de règles](axes-de-regles.md). Session 13 : 4 nouvelles formes — Plus, Cross, Ring, T. Session 14 : Rainbow sur l'axe famille + retour de la valeur sous vocabulaire casino confiné aux lignes, voir [Formes](formes.md) et [Axes de règles](axes-de-regles.md). Session 16 : retrait de l'axe directionnel, chaque Partition — lignes comprises — a désormais un multiplicateur fixe unique, calibré par tier de difficulté réelle plutôt que par géométrie brute).

Les labels affichés en jeu ne montrent plus "FAMILY" (redondant, quasi tout le catalogue actif est en rule `family`) — nettoyé en session 13, voir `TagsUI._format_tag_label`. Depuis la session 14, `_format_tag_label` distingue aussi `value`/`rainbow`/`fibonacci` (sinon Brelan et Line 3 auraient affiché le même libellé en jeu).

| Partition       | Forme             | Règle                                               | Taille min | Direction | Mult  | Prix |
| --------------- | ----------------- | --------------------------------------------------- | ---------- | --------- | ----- | ---- |
| Line 3          | Ligne             | Famille                                             | 3          | any       | ×1.5  | 6    |
| Brelan          | Ligne             | Même valeur                                         | 3          | any       | ×1.5  | 6    |
| Line 4          | Ligne             | Famille                                             | 4          | any       | ×2    | 6    |
| Square 4        | Carré 2×2         | Famille                                             | 4          | —         | ×2    | 8    |
| T               | Tétromino         | Famille (orientation libre)                         | 4          | any       | ×2    | 7    |
| Line 4 Rainbow  | Ligne             | 4 familles distinctes                               | 4          | any       | ×2    | 10   |
| Square Rainbow  | Carré 2×2         | 4 familles distinctes                               | 4          | —         | ×2    | 12   |
| Line 5          | Ligne             | Famille                                             | 5          | any       | ×2.5  | 10   |
| Suite           | Ligne             | Valeurs consécutives (any sens)                     | 3          | any       | ×2.5  | 14   |
| Carré           | Ligne             | Même valeur (clin d'œil poker, pas la forme carrée) | 4          | any       | ×2.5  | 8    |
| Fibonacci       | Ligne             | 1, 1, 2, 3 (dans un sens ou l'autre)                | 4          | any       | ×2.5  | 14   |
| Diamond         | Losange           | 4 jetons même famille, centre indifférent           | 4          | —         | ×2.5 (somme des 4) | 10   |
| Diamond Rainbow | Losange           | 4 familles distinctes, centre indifférent           | 4          | —         | ×2.5 (somme des 4) | 12   |
| Plus            | Croix orthogonale | Famille (centre inclus)                             | 5          | any       | ×3    | 10   |
| Cross           | Croix diagonale   | Famille (centre inclus)                             | 5          | any       | ×4    | 12   |
| Ring            | Cadre 3×3         | Famille (centre indifférent)                        | 8          | any       | ×5    | 15   |
| Diamond Rock    | Losange           | 4 rocks autour d'un centre scorable                 | 4          | —         | ×4 (sur centre + roll casino 1-5) | 12   |

Le multiplicateur ne dépend plus de la direction du match, y compris pour les Partitions "any direction" (Rainbow/Suite/Brelan/Carré/Fibonacci, qui vivent toutes sur la forme Ligne, voir [Formes](formes.md)) — chacune porte son propre `score_multiplier` fixe sur son `.tres`.

## Tiers de difficulté (session 16)

Logique de calibrage derrière le tableau ci-dessus, tranchée avec le user et synchronisée avec la Google Sheet (source de vérité pour ces données) :

| Tier | Partitions | Mult |
|---|---|---|
| Amorce | Line 3, Brelan | ×1.5 |
| Facile | Line 4, Square 4, T, Line 4 Rainbow, Square Rainbow | ×2 |
| Medium | Line 5, Suite, Carré (poker), Fibonacci, Diamond, Diamond Rainbow, Number Square (dormant) | ×2.5 |
| Difficile | Plus | ×3 |
| Très dur | Cross | ×4 |
| Extrême | Ring | ×5 |
| Hors échelle | Diamond Rock, 777 (idée), 9999 (idée) | cas à part, voir ci-dessous |

Notes :
- **Rainbow revu à la baisse** par rapport à l'intuition initiale : avec seulement `FAMILY_COUNT = 4` familles, obtenir 4 familles *distinctes* est statistiquement plus facile qu'obtenir 4 fois la *même* — Line 4 Rainbow et Square Rainbow rejoignent le tier Facile, Diamond Rainbow le tier Medium (la forme losange reste un peu plus dure à placer qu'un carré ou une ligne, d'où le cran au-dessus de ses cousines)
- **Fibonacci et Carré** pareil : les valeurs 1-5 sont courantes (`TOKEN_MIN_VALUE`-`TOKEN_MAX_VALUE`, 8 copies chacune dans le deck de base), la contrainte de séquence/répétition pèse moins qu'il n'y paraît — rejoignent le tier Medium avec Line 5/Suite/Diamond plutôt que Facile
- **Diamond Rock** reste hors de ce chantier — son score (centre + roll casino) suit sa propre question de recalibrage, voir [Rocks](../jetons/rocks.md) et [Questions ouvertes](../meta/questions-ouvertes.md)
- **777/9999** dépendent de la Fusion (valeurs 7 et 9 impossibles autrement que par fusion de deux boutons de base) — signature de fin de run, pool "rare/signature" déjà noté comme non implémenté. La Sheet liste aussi deux nouvelles idées non couvertes ici : **Big T** (family, description à préciser) et **Skull Line 3** (rule `skull`, probablement la piste "Partition à roulette sur l'Entity" du brainstorm session 15)

## Rainbow, casino (session 14)

Détection dans `PatternMatcher` :
- **Rainbow** (Square/Diamond/Line 4) — `_all_families_distinct()`, un nouveau helper. Plafonné à taille 4 par `GameRules.FAMILY_COUNT` (4 familles existantes, impossible d'aligner plus sans répétition). Square/Diamond étendent `find_squares`/`find_diamonds` existants ; Line 4 Rainbow a sa propre fonction `find_line_rainbow` (fenêtre fixe, pas d'extension incrémentale comme les lignes famille).
- **Suite/Brelan/Carré** — aucune nouvelle logique de détection : ce sont les anciennes Partitions dormantes "chiffre" (`line_number_3`, `line_number_4_horizontal`, `suite_3_diagonal`) simplement renommées/relabellées (`brelan.tres`, `carre_poker.tres`, `suite.tres`) et remises dans `ShopManager.TAG_PATHS`. Le moteur (`find_lines`, rules `value`/`suite`) n'a pas changé.
- **Fibonacci** — cible fixe `GameRules.FIBONACCI_SEQUENCE` (1,1,2,3), nouvelle fonction dédiée `find_fibonacci` (fenêtre fixe, matche la cible dans un sens ou l'autre le long de l'axe).
- Le Badge Numérologie (`rule == "value"` ×2) reste hors catalogue actif mais boosterait déjà Brelan/Carré sans changement — non réactivé pour l'instant, à décider séparément.

## Chevauchement de figures — Double Partition (session 13, révisé session 15)

Deux Tags différents peuvent matcher des groupes qui se recouvrent (ex : un Plus complet contient toujours un T valide sur 4 de ses 5 cellules). `CascadeResolver.resolve` trie les groupes candidats par score décroissant et compare chaque candidat à l'ensemble de cellules de chaque groupe déjà retenu :
- **Inclusion totale** (une figure contient entièrement une autre, mêmes jetons, ex Plus ⊃ T, Ligne 4 ⊃ Ligne 3) → seule la mieux payée compte
- **Chevauchement partiel** (au moins 1 cellule commune, aucune inclusion totale — typiquement le jeton qui vient d'être posé, point de convergence de deux figures distinctes) → **Double Partition** : les deux scorent, total combiné x`GameRules.PATTERN_COMBO_MULTIPLIER` (2 actuellement), bannière dédiée

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

Les idées non implémentées sont listées dans la [Google Sheet](https://docs.google.com/spreadsheets/d/1JMEQf2W6H8fMZ24D63-jRQrJKz5424kR7Exyo4xvM_0/edit) (onglet "partitions", source de vérité pour les données catalogue depuis le 2026-07-10 — le `.tres` doit suivre en cas de divergence) et brassées dans `brainstorm-pattern-tags.md`. Pool cible final : 20-30 Partitions.

## Liens

- [Principe](principe.md)
- [Formes](formes.md)
- [Axes de règles](axes-de-regles.md)
- [Scoring](scoring.md)
- [Shop — packs](../shop/packs.md)
