# Les Boutons

Les **jetons de base** — l'identité thématique des éléments qu'on drop. Objet du quotidien, légèrement inquiétant en grande quantité. Déclinable à l'infini (taille, couleur, nombre de trous), dessinable en 2 secondes, familier dans un monde qui ne l'est pas.

## Attributs

Chaque bouton a deux attributs :
- **Famille** (matière) : **4 familles** en code (`TokenData.Family.CORAL/SHELL/RUST/INK`, ajoutée en session 12). Nommage encore provisoire — le rename vers les noms thématiques (Bone/Wood/Brass envisagés en session 10) n'a jamais été appliqué au code, à faire à un moment.
- **Valeur** (chiffre) : 1 à 5 au tirage initial, **plafonnée à 10 après fusion** (`GameRules.MAX_BUTTON_VALUE`, tranché en session 12).

**Changement important (session 12)** : la valeur **ne résout plus jamais de pattern**. Seule la famille (et le rock, pour Diamond Rock) détermine si une figure matche une [Partition](../partitions/principe.md) équipée. La valeur est devenue un **pur levier de score** — elle amplifie ce qui a déjà matché, elle ne décide plus quoi matche. Les Partitions et le Badge liés à la valeur (lignes/carré/suite chiffre, Numérologie) restent dans le code mais hors catalogue actif — voir [Catalogue implémenté](../partitions/catalogue-implemente.md).

C'est le carburant du deck. Les boutons ne sont pas spectaculaires seuls — ce sont les [Partitions](../partitions/principe.md) et les [Badges](../badges/principe.md) qui les rendent puissants.

## Le deck de boutons est persistant

Le **pool de boutons possédés** (génération de départ + achats + fusions) n'est pas régénéré au hasard à chaque manche : il est fixé progressivement et **suit le joueur sur toute la run**. Chaque manche pioche dans ce pool, mélangé, en un seul passage (voir [Deck](../manche/deck.md)) — mais le pool lui-même ne change qu'au shop.

## Pool de départ

**Structuré, pas aléatoire** (session 13) — `RunManager._generate_starter_buttons()` génère exactement `STARTER_COPIES_PER_VALUE` (2) exemplaires de chaque combinaison (famille, valeur) possible, soit `FAMILY_COUNT × (TOKEN_MAX_VALUE - TOKEN_MIN_VALUE + 1) × STARTER_COPIES_PER_VALUE` = **40 boutons** (`GameRules.DECK_BASE_COUNT`, calculé plutôt que codé en dur). Avant, la composition était 100% aléatoire (30 boutons, famille/valeur tirées indépendamment) — un mauvais tirage pouvait saboter une Partition équipée sans faute du joueur, à l'encontre du principe "pas de RNG punitif" déjà appliqué à l'Entity. Le seul hasard qui reste, c'est l'ordre de pioche (shuffle du deck).

**Toujours pas de "pack de boutons" comme choix structurant** — le pool de départ est fixe pour toute run, aucun choix du joueur là-dessus. Le vrai choix structurant de départ implémenté aujourd'hui, c'est l'[écran de sélection de Partition](../partitions/catalogue-implemente.md) (2 Partitions gratuites parmi 3, tirées dans tout le catalogue) — pas les boutons.

**Statut** : packs concrets de boutons (Polyvalent, Mono-famille, Escalier…) toujours à designer, pas de priorité immédiate. Idée évoquée en session 13 : des **decks de départ façon Balatro** (bonus/malus, choix de rejouabilité) — distincts des grilles spéciales, réservées à la progression du Shore plutôt qu'au choix de départ. Pas encore implémenté.

## Évolution au shop

Deux leviers, qui tirent le deck dans des sens opposés sur l'axe [slim vs fat](../manche/deck.md) :

- **Ajouter un bouton unitaire ou un pack de boutons** — voir [Shop — packs](../shop/packs.md) pour le format. → vers le fat.
- **Les outils de deck** ("Dés à coudre", voir ci-dessous) — Fusion (2→1, concentre) mais aussi Scinder (1→2, étale), Augmenter/Réduire, Changer de famille, Suppression. → slim ou fat selon l'outil.

### Outils de deck gatés par "Dés à coudre" (session 12, généralisé session 16)

La Fusion seule n'est plus un bouton permanent toujours accessible — avec la valeur devenue un pur levier de score, elle était trop facile à spammer pour faire gonfler les chiffres sans limite. Elle est désormais une des **9 actions possibles** débloquées par l'achat d'un item **Dés à coudre** au shop (catégorie au même titre que Partition/Badge/Spécial/Bouton dans l'offre curatée), généralisée en session 16 façon Tarot de Balatro — voir [Brainstorm — outils de deck](../../brainstorms/brainstorm-outils-deck.md) pour la genèse complète.

Un achat de Dés à coudre tire **3 actions distinctes** du pool de 9, pondérées par rareté (`GameRules.RARITY_WEIGHTS`, même échelle que Partitions/Badges), et **8 candidats** (`GameRules.DECK_TOOL_TARGET_DRAW_SIZE`) du pool possédé — les deux affichés en même temps dans le même panneau (revu en session 16 : voir les cibles avant de choisir l'action évite de choisir une action sans cible valide dans le tirage). Sélectionner 1 ou 2 boutons (selon l'action) active/désactive les 3 actions ; cliquer une action activée l'applique immédiatement.

| Rareté | Action | Effet |
|---|---|---|
| Common | Augmenter | +1 sur un bouton |
| Common | Réduire | -1 sur un bouton |
| Common | Changer vers Coral/Shell/Rust/Ink | Recolore un bouton (4 actions distinctes, une par famille) |
| Uncommon | Scinder | 1 bouton de valeur **paire** → 2 boutons de moitié valeur (ex : 6 → 3+3). Inverse de la Fusion |
| Uncommon | Fusionner | 2 boutons → 1, valeur = somme (plafonnée à 10), famille tirée au hasard entre les deux — **nerfée en session 16** : n'est plus garantie à chaque achat, un tirage pondéré comme les autres |
| Rare | Suppression | Retire un bouton du deck, jamais remplacé — le plus fort des neuf vu le sans-reshuffle (améliore les probas de tirage de tout ce qui reste) |

Duplication et jeton arc-en-ciel (toutes familles à la fois) mis de côté pour plus tard (tier Epic vide) — voir le brainstorm pour le detail et la question ouverte sur l'interaction avec les Partitions Rainbow.

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
