# Catalogue implémenté

**20 Partitions actives** dans le proto (session 12 : la valeur ne résout plus de patterns sur les formes famille, seuls famille et rock restent actifs — voir [Axes de règles](axes-de-regles.md). Session 13 : 4 nouvelles formes — Plus, Cross, Ring, T. Session 14 : Rainbow sur l'axe famille + retour de la valeur sous vocabulaire casino confiné aux lignes, voir [Formes](formes.md) et [Axes de règles](axes-de-regles.md). Session 16 : retrait de l'axe directionnel, chaque Partition — lignes comprises — a désormais un multiplicateur fixe unique, calibré par tier de difficulté réelle plutôt que par géométrie brute. Session 19 : Minima, Maxima, Prime — trois nouvelles Partitions casino jouables sur tout le run, pas seulement en fin de run comme le tiroir rare/signature, voir [Axes de règles](axes-de-regles.md#genèse--pourquoi-ces-trois-là-session-19)).

Les slots équipés affichent `tag.label` tel quel (ex: "PRIME", "BRELAN"), le même nom que le shop et les hovers — `TagsUI._format_tag_label` (session 13-14) recomposait auparavant un libellé forme+règle+taille (ex: "LINE CASINO 3" pour Brelan) pour éviter les doublons entre Partitions, mais ce nom composé s'est révélé illisible en jeu ; simplifié en session 19 pour ne garder que le label + le multiplicateur.

| Partition       | Forme             | Règle                                               | Taille min | Direction | Mult  | Prix |
| --------------- | ----------------- | --------------------------------------------------- | ---------- | --------- | ----- | ---- |
| Line 3          | Ligne             | Famille                                             | 3          | any       | ×1.5  | 6    |
| Brelan          | Ligne             | Même valeur                                         | 3          | any       | ×1.5  | 6    |
| Line 4          | Ligne             | Famille                                             | 4          | any       | ×2    | 6    |
| Square 4        | Carré 2×2         | Famille                                             | 4          | —         | ×2    | 8    |
| Small T         | Tétromino         | Famille (orientation libre)                         | 4          | any       | ×2    | 7    |
| Line 4 Rainbow  | Ligne             | 4 familles distinctes                               | 4          | any       | ×1    | 10   |
| Square Rainbow  | Carré 2×2         | 4 familles distinctes                               | 4          | —         | ×1    | 12   |
| Line 5          | Ligne             | Famille                                             | 5          | any       | ×2.5  | 10   |
| Suite           | Ligne             | Valeurs consécutives (any sens)                     | 4          | any       | ×2.5  | 14   |
| Carré           | Ligne             | Même valeur (clin d'œil poker, pas la forme carrée) | 4          | any       | ×2.5  | 8    |
| Fibonacci       | Ligne             | 4 valeurs consécutives de 1,1,2,3,5,8 (any fenêtre, any sens) | 4          | any       | ×2.5  | 14   |
| Diamond         | Losange           | 4 jetons même famille, centre indifférent           | 4          | —         | ×2.5 (somme des 4) | 10   |
| Diamond Rainbow | Losange           | 4 familles distinctes, centre indifférent           | 4          | —         | ×2 (somme des 4) | 12   |
| Plus            | Croix orthogonale | Famille (centre inclus)                             | 5          | any       | ×3    | 10   |
| Cross           | Croix diagonale   | Famille (centre inclus)                             | 5          | any       | ×4    | 12   |
| Ring            | Cadre 3×3         | Famille (centre indifférent)                        | 8          | any       | ×5    | 15   |
| Diamond Rock    | Losange           | 4 rocks autour d'un centre scorable                 | 4          | —         | ×4 (sur centre + roll casino 1-5) | 12   |
| Minima          | Ligne             | Toutes les valeurs < 3                              | 3          | any       | ×1.5  | 6    |
| Maxima          | Ligne             | Toutes les valeurs > 7                              | 3          | any       | ×3    | 14   |
| Prime           | Ligne             | Au moins 3 valeurs consécutives de 2,3,5,7,11 (any fenêtre, any sens) | 3          | any       | ×2    | 14   |

Le multiplicateur ne dépend plus de la direction du match, y compris pour les Partitions "any direction" (Rainbow/Suite/Brelan/Carré/Fibonacci, qui vivent toutes sur la forme Ligne, voir [Formes](formes.md)) — chacune porte son propre `score_multiplier` fixe sur son `.tres`.

## Tiers de difficulté (session 16)

Logique de calibrage derrière le tableau ci-dessus, tranchée avec le user et synchronisée avec la Google Sheet (source de vérité pour ces données) :

| Tier | Partitions | Mult |
|---|---|---|
| Trivial | Line 4 Rainbow, Square Rainbow | ×1 |
| Amorce | Line 3, Brelan, Minima | ×1.5 |
| Facile | Line 4, Square 4, Small T, Diamond Rainbow, Prime | ×2 |
| Medium | Line 5, Suite, Carré (poker), Fibonacci, Diamond, Number Square (dormant) | ×2.5 |
| Difficile | Plus, Maxima | ×3 |
| Très dur | Cross | ×4 |
| Extrême | Ring | ×5 |
| Hors échelle | Diamond Rock, 777 (idée), 9999 (idée) | cas à part, voir ci-dessous |

Notes :
- **Rainbow revu nettement à la baisse en session 18**, après playtest confirmant l'intuition de session 16 : avec seulement `FAMILY_COUNT = 4` familles, obtenir 4 familles *distinctes* est statistiquement ~6× plus probable qu'obtenir 4 fois la *même* (24/256 arrangements contre 4/256) — Line 4 Rainbow et Square Rainbow tombent au tier Trivial (×1, plus de bonus réel, juste un flat), Diamond Rainbow rejoint Facile (×2) au lieu de Medium (la forme losange reste un peu plus dure à placer qu'un carré ou une ligne, d'où le cran au-dessus de ses cousines)
- **Fibonacci et Carré** : la contrainte de séquence/répétition pèse moins qu'il n'y paraît — rejoignent le tier Medium avec Line 5/Suite/Diamond plutôt que Facile. Note : le deck de départ a bougé deux fois en session 18 (`STARTER_COPIES_PER_VALUE` 2→1, puis copie additionnelle pour les valeurs 1-2 seulement, voir [Deck](../manche/deck.md)) — les valeurs 1-2 ont maintenant 8 copies dans le deck de base (deux par famille), les valeurs 3-5 seulement 4 (une par famille). Fibonacci profite de ce déséquilibre sur sa fenêtre basse (1,1,2,3), un peu moins sur ses fenêtres hautes (1,2,3,5 / 2,3,5,8, étendues session 19, qui demandent des valeurs 5+ obtenues par Fusion) ; Carré sur une valeur haute (4-5) reste plus dur qu'avant — à surveiller au playtest
- **Diamond Rock** reste hors de ce chantier — son score (centre + roll casino) suit sa propre question de recalibrage, voir [Rocks](../jetons/rocks.md) et [Questions ouvertes](../meta/questions-ouvertes.md)
- **Minima/Maxima/Prime (session 19)** : Minima reste au tier Amorce comme Line 3/Brelan (filet d'entrée facile à satisfaire avec le deck de départ) ; Maxima grimpe à Difficile comme Plus (nécessite plusieurs Fusions pour atteindre des valeurs > 7, jamais tirées telles quelles) ; Prime se cale au tier Facile, en dessous de Suite/Fibonacci/Carré — lire des nombres premiers demande le même effort de lecture que le reste de l'axe casino, mais 2/3/5/7 restent des valeurs courantes du deck de base
- **777/9999** dépendent de la Fusion (valeurs 7 et 9 impossibles autrement que par fusion de deux boutons de base) — signature de fin de run, pool "rare/signature" déjà noté comme non implémenté. La Sheet liste aussi d'autres idées non couvertes ici : **Big T** (family, description à préciser), **Skull Line 3** (rule `skull`, probablement la piste "Partition à roulette sur l'Entity" du brainstorm session 15), et **Wedding**/**Royal Court** (rule `faces`, débouché casino pour les figures — voir [Questions ouvertes](../meta/questions-ouvertes.md))

## Accès générique vs verrouillé (session 19)

Le split rareté-shop retiré ci-dessus (uniforme au sein d'une run) est distinct du **niveau d'accès meta** (voir [Trois niveaux d'accès](../shore/unlocks.md#trois-niveaux-daccès-au-contenu-session-16)) : sur une save neuve, seule une partie du catalogue est débloquée d'office. Le cutoff retenu suit les tiers de difficulté ci-dessus :

- **Générique (15)** — tiers Trivial à Medium, débloquées dès la toute première run : Line 3, Line 4, Line 5, Square 4, Small T, Line 4 Rainbow, Square Rainbow, Diamond Rainbow, Brelan, Carré, Suite, Fibonacci, Minima, Prime, Diamond
- **Verrouillée (5)** — tiers Difficile à Hors échelle, chacune liée à un [pack de démarrage](../progression/structure-run.md#choix-de-départ) vecteur : débloquer ce pack au Shore débloque aussi, pour toujours, sa Partition signature dans le pool générique du shop (double unlock, pas de Découverte séparée à inventer)

| Partition | Pack vecteur |
|---|---|
| Plus | Le Dégagé |
| Maxima | L'Ermite |
| Cross | Le Fortifié |
| Ring | Le Risque-Tout |
| Diamond Rock | Le Fortifié |

Le tiroir rare/signature (9999/Jackpot, Wedding, Royal Court, paires figées) reste un troisième niveau, non implémenté et séparé de ce split — voir [Questions ouvertes](../meta/questions-ouvertes.md).

## Rainbow, casino (session 14)

Détection dans `PatternMatcher` :
- **Rainbow** (Square/Diamond/Line 4) — `_all_families_distinct()`, un nouveau helper. Plafonné à taille 4 par `GameRules.FAMILY_COUNT` (4 familles existantes, impossible d'aligner plus sans répétition). Square/Diamond étendent `find_squares`/`find_diamonds` existants ; Line 4 Rainbow a sa propre fonction `find_line_rainbow` (fenêtre fixe, pas d'extension incrémentale comme les lignes famille).
- **Suite/Brelan/Carré** — aucune nouvelle logique de détection : ce sont les anciennes Partitions dormantes "chiffre" (`line_number_3`, `line_number_4_horizontal`, `suite_3_diagonal`) simplement renommées/relabellées (`brelan.tres`, `carre_poker.tres`, `suite.tres`) et remises dans `ShopManager.TAG_PATHS`. Le moteur (`find_lines`, rules `value`/`suite`) n'a pas changé.
- **Fibonacci** — fonction dédiée `find_fibonacci`, teste toutes les fenêtres de `GameRules.FIBONACCI_WINDOW_SIZE` (4) valeurs consécutives dans `GameRules.FIBONACCI_SEQUENCE` (1,1,2,3,5,8 — étendu session 19, initialement limité à la seule fenêtre 1,1,2,3), dans un sens ou l'autre le long de l'axe.
- **Prime** (session 19) — même mécanique que Fibonacci, factorisée dans un helper commun (`PatternMatcher._sequence_windows`/`_find_sequence_matches`) : fenêtre **minimale** `GameRules.PRIME_MIN_WINDOW` (3) plutôt que fixe, dans `GameRules.PRIME_SEQUENCE` (2,3,5,7,11 depuis la session 22 — un Valet est premier) — matche 2,3,5 / 3,5,7 / 5,7,11 / 2,3,5,7 / etc. La fenêtre avec 11 reste une extension haute rare (un Valet suppose d'avoir déjà poussé un jeton à MAX_BUTTON_VALUE puis de l'avoir fait promouvoir), le plancher de difficulté (2,3,5) ne change pas.
- **Minima/Maxima** (session 19) — deux nouvelles rules dans `find_lines` (`&"minima"`, `&"maxima"`), même mécanique d'extension que Suite/Family mais sur un seuil individuel par jeton (`value <= GameRules.MINIMA_MAX_VALUE` (2) / `value >= GameRules.MAXIMA_MIN_VALUE` (8) — seuils stricts "< 3"/"> 7" côté Sheet, encodés en constantes inclusives) plutôt qu'une comparaison entre jetons voisins.
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

## Sélection de départ — packs de démarrage (implémenté session 19)

L'ancien écran de tirage (3 Partitions au hasard, 2 choisies) est retiré : remplacé par le choix d'un **pack de démarrage déterministe**, voir [Structure du run](../progression/structure-run.md#choix-de-départ). Les 4 packs day-one (Le Simplet, Le Généreux, Le Prévoyant, Le Collectionneur — `resources/starter_packs/`) sont codés et sélectionnables dès le lancement du jeu ; les 6 packs à débloquer restent à construire.

Les Partitions non fixées par le pack restent achetables plus tard au shop.

## Catalogue complet (idées + statuts)

Les idées non implémentées sont listées dans la [Google Sheet](https://docs.google.com/spreadsheets/d/1JMEQf2W6H8fMZ24D63-jRQrJKz5424kR7Exyo4xvM_0/edit) (onglet "partitions", source de vérité pour les données catalogue depuis le 2026-07-10 — le `.tres` doit suivre en cas de divergence) et brassées dans `brainstorm-pattern-tags.md`. Pool cible final : 20-30 Partitions.

## Liens

- [Principe](principe.md)
- [Formes](formes.md)
- [Axes de règles](axes-de-regles.md)
- [Scoring](scoring.md)
- [Shop — packs](../shop/packs.md)
