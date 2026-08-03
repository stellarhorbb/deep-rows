# Persistance entre manches

Ajouté en session 26. Le [bouton](../jetons/boutons.md) qui occupe la case la plus haute de chaque colonne à la fin d'une manche retombe sur la grille de la manche suivante, avant les cases mystère — plutôt qu'un reset complet à chaque fois.

## Le problème posé

Diagnostic creusé sur deux jours de discussion (comparaison à Cursed Words/CloverPit/Dogpile/Bills Must Be Paid) : les 5 à 10 premiers drops de chaque manche se sentaient "scolaires" — aucun système existant (résolution de [Partition](../partitions/principe.md), [roulette](../manche/roulette-casino.md), [cases mystère](../grille/modifiers-cellules.md)) ne peut mathématiquement se déclencher tant qu'il n'y a pas de matière assemblée sur la grille. Round-start est le cas extrême d'une asymétrie plus générale : une résolution efface plusieurs cases d'un coup, le remplissage n'en ajoute qu'une par tour.

## Pistes essayées et écartées avant celle-ci

- **Relief de grille seul** ([fond marin](../grille/trous.md)) — aide le ressenti visuel ("grille plate") mais un trou reste un vide, jamais de la matière. Gardé quand même, complémentaire.
- **"Ouverture"** (déverser 8-10 jetons du deck au hasard en début de manche) — rejeté : ça sacrifie au hasard le deck que le joueur construit délibérément pendant toute la run (achats shop, Dés à coudre), à l'encontre de l'investissement stratégique que représente le deck-building.
- **Réapprovisionnement continu façon Candy Crush/Two Dots** (jamais vide, cascade infinie) — rejeté : demande une génération infinie de jetons, incompatible avec le deck fini à un seul passage (pilier du jeu, source de la vraie tension de défaite).

## Fonctionnement

1. **À la fin d'une manche gagnée**, `GridManager.get_top_base_tokens()` regarde chaque colonne : la **case occupée la plus haute** — si c'est un jeton de base (`TokenData.Kind.BASE`), il persiste. Si c'est un [Rock](../jetons/rocks.md), un [entity-skull](../jetons/entity-skull.md) ou un spécial, **la colonne ne persiste rien**, même avec un bon jeton juste en dessous.
2. **Animation d'aspiration** (~3 secondes, toutes les colonnes concernées en même temps) juste avant l'écran YOU WIN — les jetons qui vont persister s'envolent vers le haut et s'estompent, façon "l'Entity les récupère". Sans texte explicite (cohérent avec le [sens caché jamais nommé](../univers/pitch.md#le-sens-caché-privé--jamais-montré-en-jeu)) — le joueur infère la règle en observant.
3. **Au début de la manche suivante**, une fois le fond marin généré : les jetons persistés retombent par gravité sur ce nouveau terrain, colonne par colonne, gauche à droite (animation de chute, avant que les cases mystère n'apparaissent).
4. **Exclusion du deck** — un jeton qui persiste ne redonne pas une deuxième copie jouable cette manche-là (`DeckManager.build_deck(button_pool, carried_over)` saute une copie fraîche par jeton persisté). Il fait déjà partie du deck possédé, on ne peut pas le jouer deux fois.

## Design intent — le côté tactique de la couverture

La règle "case occupée la plus haute, sans exception" (pas "creuser jusqu'au premier vrai jeton") est délibérée : **couvrir un jeton avec un Rock ou laisser un skull atterrir dessus le protège de la persistance**. Le joueur qui préfère garder le contrôle total du placement d'un jeton précis (plutôt que de le voir retomber au hasard la manche suivante) peut le planquer sous un obstacle. Donne une deuxième fonction aux obstacles déjà existants plutôt que d'ajouter un système à part.

## Lisibilité — question ouverte

Comment nommer/présenter cette règle intuitivement au joueur reste **non tranché** (voir [questions ouvertes](../meta/questions-ouvertes.md)). L'animation d'aspiration/chute aide (symétrie visuelle : ce qui part en haut à la fin revient en tombant au début), mais rien n'explicite encore le "pourquoi" en mots. À revisiter une fois la DA posée.

## Statut

Premier jet validé au playtest session 26 ("chaque starter est plus rempli, plus stratégique tout de suite"). Le plafond de matière (1 jeton max par colonne, donc max `GameRules.COLS`) n'a pas encore été calibré à l'usage prolongé — à surveiller si ça se révèle trop généreux ou trop maigre sur un run complet.

## Liens

- [Grille cabossée (trous)](../grille/trous.md)
- [Dernier Souffle](dernier-souffle.md)
- [Déroulement](deroulement.md)
- [Rocks](../jetons/rocks.md)
- [Entity-skull](../jetons/entity-skull.md)
- [Boutons](../jetons/boutons.md)
