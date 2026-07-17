# Les Boutons

Les **jetons de base** — l'identité thématique des éléments qu'on drop. Objet du quotidien, légèrement inquiétant en grande quantité. Déclinable à l'infini (taille, couleur, nombre de trous), dessinable en 2 secondes, familier dans un monde qui ne l'est pas.

## Attributs

Chaque bouton a deux attributs :
- **Famille** (matière) : **4 familles** en code (`TokenData.Family.BATONS/COUPES/EPEES/DENIERS`, ajoutée en session 12). Renommées en session 18 sur le vocabulaire tarot (arcanes mineurs) — remplace `CORAL/SHELL/RUST/INK` et le projet Bone/Wood/Brass de session 10, jamais appliqué. Chaque famille a une correspondance élémentaire classique (Bâtons/Feu, Coupes/Eau, Épées/Air, Deniers/Terre) qui pourra nourrir la DA et de futurs contenus (Badges, Partitions) sans copier Balatro (qui n'utilise jamais élément/saison/astro).
- **Valeur** (chiffre) : 1 à 5 au tirage initial, **plafonnée à 10** par Fusion/Augmenter (`GameRules.MAX_BUTTON_VALUE`, tranché en session 12) — au-delà, voir [Figures](#figures-arcanes-mineurs) ci-dessous, un chemin séparé qui n'existe que via le score.

**Changement important (session 12)** : la valeur **ne résout plus jamais de pattern**. Seule la famille (et le rock, pour Diamond Rock) détermine si une figure matche une [Partition](../partitions/principe.md) équipée. La valeur est devenue un **pur levier de score** — elle amplifie ce qui a déjà matché, elle ne décide plus quoi matche. Les Partitions et le Badge liés à la valeur (lignes/carré/suite chiffre, Numérologie) restent dans le code mais hors catalogue actif — voir [Catalogue implémenté](../partitions/catalogue-implemente.md).

C'est le carburant du deck. Les boutons ne sont pas spectaculaires seuls — ce sont les [Partitions](../partitions/principe.md) et les [Badges](../badges/principe.md) qui les rendent puissants.

## Figures (arcanes mineurs)

**Implémenté session 18.** Un jeton de base déjà à `MAX_BUTTON_VALUE` (10) qui **score** avance automatiquement d'un cran dans la suite des figures — Valet(11) → Chevalier(12) → Reine(15) → Roi(20), plafond définitif. Affichage : J/C/Q/K sur le jeton, sprite de famille inchangé. La valeur continue d'alimenter le `value_sum` normalement (11 à 20 points), aucune formule à part.

**Chemin exclusivement accessible par le jeu, jamais par le shop** — Fusion, Augmenter et Poker Face restent plafonnés à 10 (voir `RunManager.increase_button_value`/`fuse_buttons`), seul un jeton qui score au-delà de ce plafond progresse (`RunManager.promote_matching_button`, `CascadeResolver._roll_face_promotions`). Décision délibérée après discussion (session 18) : une figure achetable directement aurait cassé le partage shop=acquérir / jeu=faire grandir qui structure déjà le level up des Partitions.

**Rareté par construction** : atteindre 10 demande déjà plusieurs Fusions (cher), puis chaque palier suivant demande un score de plus avec ce jeton précis. Une fois promu, un jeton **ne peut plus redescendre** — Réduire est refusé sur une figure (`RunManager.decrease_button_value`). Fusion/Scinder restent ouverts (replafonnent à 10, une façon de "encaisser" une figure dont on ne veut plus).

**Verrouillage ("Fixer", Dés à coudre, rare)** : protège une figure contre toute promotion future, même si elle rescore — permet de stabiliser volontairement une Reine ou un Chevalier plutôt que de la laisser filer vers Roi malgré elle. Gratuit hors coût du Dés à coudre lui-même — ce n'est pas un raccourci d'achat vers une figure, juste un contrôle de timing sur un chemin qui reste entièrement gagné par le jeu.

**Tension connue** : au-delà de Chevalier, une figure devient orpheline de l'axe casino — Reine(15) et Roi(20) n'ont aucun voisin à distance 1 (pas de Suite possible), et le Brelan demanderait 3 exemplaires de la même figure (structurellement quasi impossible). Seul l'axe famille (Ligne, Carré, Losange, Plus, Cross, Ring, T, Rainbow) reste ouvert passé ce stade. Un futur pattern "Wedding" (Roi+Reine assemblés, voir [Questions ouvertes](../meta/questions-ouvertes.md)) est pensé comme le débouché casino dédié aux figures.

## Le deck de boutons est persistant

Le **pool de boutons possédés** (génération de départ + achats + fusions) n'est pas régénéré au hasard à chaque manche : il est fixé progressivement et **suit le joueur sur toute la run**. Chaque manche pioche dans ce pool, mélangé, en un seul passage (voir [Deck](../manche/deck.md)) — mais le pool lui-même ne change qu'au shop.

## Pool de départ

**Structuré, pas aléatoire** (session 13) — `RunManager._generate_starter_buttons()` génère `STARTER_COPIES_PER_VALUE` (1, réduit de 2 en session 18) exemplaire de chaque combinaison (famille, valeur) possible, soit `FAMILY_COUNT × (TOKEN_MAX_VALUE - TOKEN_MIN_VALUE + 1) × STARTER_COPIES_PER_VALUE` = 20 boutons, **plus une copie additionnelle pour les valeurs ≤ `STARTER_LOW_VALUE_EXTRA_COPY_MAX`** (2 — session 18, deuxième passe suite au playtest : 20+4 s'est révélé trop juste, mais regonfler uniformément aurait aussi re-fragilisé les valeurs hautes 3-5, qui doivent rester rares et précieuses à placer), soit +8 boutons. Total **28 boutons** (`GameRules.DECK_BASE_COUNT`, calculé plutôt que codé en dur). Avant, la composition était 100% aléatoire (30 boutons, famille/valeur tirées indépendamment) — un mauvais tirage pouvait saboter une Partition équipée sans faute du joueur, à l'encontre du principe "pas de RNG punitif" déjà appliqué à l'Entity. Le seul hasard qui reste, c'est l'ordre de pioche (shuffle du deck).

**Aujourd'hui, aucun choix du joueur sur ce pool** — il est fixe pour toute run. Le choix structurant de départ actuellement en jeu, c'est l'[écran de sélection de Partition](../partitions/catalogue-implemente.md) (2 Partitions gratuites parmi 3, tirées dans tout le catalogue) — pas les boutons.

**Statut** : remplacé, à terme, par le [pack de démarrage déterministe](../progression/structure-run.md#choix-de-départ) (session 19, pas encore implémenté) — ce pool de boutons deviendrait l'un des ingrédients modifiables du pack (taille, quelques valeurs pré-fusionnées...), pas un choix de "pack de boutons" isolé façon Polyvalent/Mono-famille/Escalier comme envisagé en session 13. Voir le [Brainstorm — Packs de démarrage](../../brainstorms/brainstorm-starter-packs.md).

## Évolution au shop

Deux leviers, qui tirent le deck dans des sens opposés sur l'axe [slim vs fat](../manche/deck.md) :

- **Ajouter un bouton unitaire ou un pack de boutons** — voir [Shop — packs](../shop/packs.md) pour le format. → vers le fat.
- **Les outils de deck** ("Dés à coudre", voir ci-dessous) — Fusion (2→1, concentre) mais aussi Scinder (1→2, étale), Augmenter/Réduire, Changer de famille, Suppression. → slim ou fat selon l'outil.

### Outils de deck gatés par "Dés à coudre" (session 12, généralisé session 16)

La Fusion seule n'est plus un bouton permanent toujours accessible — avec la valeur devenue un pur levier de score, elle était trop facile à spammer pour faire gonfler les chiffres sans limite. Elle est désormais une des **10 actions possibles** débloquées par l'achat d'un item **Dés à coudre** au shop (catégorie au même titre que Partition/Badge/Spécial/Bouton dans l'offre curatée), généralisée en session 16 façon Tarot de Balatro — voir [Brainstorm — outils de deck](../../brainstorms/brainstorm-outils-deck.md) pour la genèse complète.

Un achat de Dés à coudre tire **3 actions distinctes** du pool de 10, pondérées par rareté (`GameRules.RARITY_WEIGHTS`, même échelle que Partitions/Badges), et **8 candidats** (`GameRules.DECK_TOOL_TARGET_DRAW_SIZE`) du pool possédé — les deux affichés en même temps dans le même panneau (revu en session 16 : voir les cibles avant de choisir l'action évite de choisir une action sans cible valide dans le tirage). Sélectionner 1 ou 2 boutons (selon l'action) active/désactive les 3 actions ; cliquer une action activée l'applique immédiatement.

| Rareté | Action | Effet |
|---|---|---|
| Common | Augmenter | +1 sur un bouton |
| Common | Réduire | -1 sur un bouton (refusé sur une figure, voir [Figures](#figures-arcanes-mineurs)) |
| Uncommon | Scinder | 1 bouton de valeur **paire** → 2 boutons de moitié valeur (ex : 6 → 3+3). Inverse de la Fusion |
| Uncommon | Fixer | Verrouille une figure (Valet+) contre toute promotion future, même si elle rescore — seul moyen de "stabiliser" une figure sans jamais l'acheter directement (voir [Figures](#figures-arcanes-mineurs)) — **descendue de Rare à Uncommon en session 19**, cohérent avec son faible intérêt tant que Wedding n'existe pas (voir [Questions ouvertes](../meta/questions-ouvertes.md)) |
| Uncommon | Changer vers Bâtons/Coupes/Épées/Deniers | Recolore **2 boutons sélectionnés** (4 actions distinctes, une par famille) — **passé de 1 à 2 cibles et de Common à Uncommon en session 19**, pour mieux ouvrir les builds mono-famille |
| Rare | Fusionner | 2 boutons → 1, valeur = somme (plafonnée à 10), famille tirée au hasard entre les deux — nerfée en session 16 (plus garantie à chaque achat), **montée de Uncommon à Rare en session 19** |
| Epic | Suppression | Retire un bouton du deck, jamais remplacé — améliore les probas de tirage de tout ce qui reste vu le sans-reshuffle — **montée de Rare à Epic en session 19**, premier outil à occuper ce tier |

Duplication et jeton arc-en-ciel (toutes familles à la fois) mis de côté pour plus tard — voir le brainstorm pour le detail et la question ouverte sur l'interaction avec les Partitions Rainbow.

### Coût

Le prix du Dés à coudre reste un prix unique pour le paquet, pas par action — voir [Économie](../shop/economie.md) pour la valeur actuelle.

Les boutons et le Dés à coudre sont vendus au shop par les [grenouilles orchestre](../univers/personnages/grenouilles-orchestre.md) — voir [Shop — offre mixte](../shop/offre-mixte.md).

## Liens

- [Partitions](../partitions/principe.md)
- [Rocks](rocks.md)
- [Spéciaux](specials.md)
- [Entity-skull](entity-skull.md)
- [États de jetons (réserve)](etats-reserve.md)
- [Deck](../manche/deck.md)
- [Inspecteur de deck](../manche/inspecteur-deck.md)
- [Shop — packs](../shop/packs.md)
