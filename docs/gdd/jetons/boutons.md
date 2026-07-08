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
- **Fusionner** — combine 2 boutons possédés, **famille libre**, en 1 seul. Valeur = **somme des deux, plafonnée à 10**. Famille du résultat = **tirée au hasard entre les deux familles d'entrée** (donc déterministe si les deux boutons sont déjà de la même famille). Réduit le deck, concentre sa valeur. → vers le slim.

### Fusion gatée par "Dés à coudre" (session 12)

La fusion n'est plus un bouton permanent toujours accessible — avec la valeur devenue un pur levier de score, elle était trop facile à spammer pour faire gonfler les chiffres sans limite. Elle est désormais débloquée par l'achat d'un item **Dés à coudre** au shop (catégorie au même titre que Partition/Badge/Spécial/Bouton dans l'offre curatée) : un achat = **une seule fusion**, le panel se ferme ensuite automatiquement.

### Sélection pour la fusion

Pas d'accès libre à tout le pool (casserait la lisibilité et transformerait la fusion en calcul d'optimisation plutôt qu'en décision rapide). À la place : un **tirage random de 8-10 boutons** (`GameRules.FUSION_DRAW_SIZE`, actuellement 10) du pool possédé, parmi lesquels le joueur choisit sa paire à fusionner.

Comme la famille du résultat est déjà random entre les deux entrées, **n'importe quelle paire du tirage est fusionnable** — pas de risque de "tirage mort" sans paire valide, pas besoin de règle de pity.

### Coût

Le prix du Dés à coudre remplace l'ancien prix plat par fusion — voir [Économie](../shop/economie.md) pour la valeur actuelle.

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
