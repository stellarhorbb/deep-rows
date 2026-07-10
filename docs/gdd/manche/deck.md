# Le deck

Le deck du joueur contient :
- Son **stock de base** : pack de [boutons](../jetons/boutons.md) + upgrades achetées au shop
- **4 [rocks](../jetons/rocks.md)** par défaut (`DECK_ROCK_COUNT` dans `game_rules.gd`)
- Ses **[jetons spéciaux](../jetons/specials.md)** achetés au shop (persistants tant qu'ils ne sont pas joués sur la grille)

Deck actuel : **40 boutons + 4 rocks + spéciaux** (`DECK_BASE_COUNT`, `DECK_ROCK_COUNT`). Le pool de départ est structuré depuis la session 13 (2 exemplaires de chaque famille/valeur) — voir [Boutons — pool de départ](../jetons/boutons.md).

## Persistance entre manches

Le pool de boutons possédés n'est **pas régénéré au hasard à chaque manche** — il persiste sur toute la run, et n'évolue qu'au shop (achat unitaire, [bocal](../shop/packs.md), [fusion](../jetons/boutons.md)). Chaque manche pioche dans ce pool, mélangé, en un seul passage. C'est le pool qui persiste, pas l'ordre de tirage.

Les spéciaux suivent la même logique (session 15) : un spécial acheté et non joué (encore dans le deck, en hold, ou en main) reste possédé à la manche suivante — il n'est retiré de l'inventaire qu'au moment où il est réellement posé sur la grille (`RunManager.consume_special`). Seul l'achat au shop en ajoute.

## Règles du deck

**Un seul passage** dans le deck par manche. Pas de reshuffle, pas de défausse.

Raisons :
- **Pas de reshuffle** → sinon le joueur ne peut jamais perdre
- **Pas de défausse** → serait spammée pour chercher les spéciaux, les boutons deviendraient du bruit

Une [Badge](../badges/principe.md) rare pourrait débloquer la défausse pour un nombre limité de skips par manche.

## Deck slim vs deck fat

Deux leviers du shop tirent le deck dans des sens opposés (voir [Boutons — évolution au shop](../jetons/boutons.md)) :

- **Fusion** → **deck slim** : moins de jetons, valeur concentrée par jeton (plafonnée à 10, `MAX_BUTTON_VALUE`) → moins de drops mais chaque coup compte plus. Gatée par l'achat d'un Dés à coudre depuis la session 12.
- **Achat unitaire / bocal** → **deck fat** : plus de boutons dilués → plus de drops, plus d'opportunités de patterns

Le joueur choisit son axe manche après manche, pas une fois pour toutes.

## Liens

- [Stream + Hold](stream-hold.md)
- [Inspecteur de deck](inspecteur-deck.md)
- [Déroulement](deroulement.md)
- [Boutons](../jetons/boutons.md)
- [Spéciaux](../jetons/specials.md)
