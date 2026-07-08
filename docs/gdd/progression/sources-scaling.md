# Sources de scaling

Les leviers qui font monter la puissance du joueur au fil d'un run.

## 1. Ajout de boutons (shop)

Un [bouton](../jetons/boutons.md) acheté à l'unité ou via [bocal](../shop/packs.md) est **permanent pour la run** (le pool de boutons est [persistant](../manche/deck.md)). Le deck grossit → +1 drop par manche → scaling doux du nombre de coups, vers un deck fat.

## 2. Fusion de boutons (shop, gatée)

Fusionner 2 boutons possédés (famille libre) en 1 seul, de valeur = somme des deux (**plafonnée à 10**, `MAX_BUTTON_VALUE`) et famille tirée au hasard entre les deux entrées. Réduit le deck et concentre sa valeur — le levier "slim" opposé à l'ajout de boutons. Sélection parmi un tirage random de 8-10 boutons du pool, pas le pool entier.

Depuis la session 12, l'accès à la fusion est gaté par l'achat d'un item **Dés à coudre** au shop — une seule fusion par achat, plus un bouton permanent spammable. Voir [Boutons — évolution au shop](../jetons/boutons.md).

## 3. Partitions level up (par le jeu)

Les [Partitions](../partitions/principe.md) montent en niveau par le score cumulé. Une Partition **Forte** (lv.3) score beaucoup plus qu'une **Pianissimo** (lv.1), même avec les mêmes boutons. Source principale de scaling organique. Voir [Level up](../partitions/level-up.md).

## 4. Badges accumulées (shop)

Les passifs se combinent et créent des **synergies exponentielles**. Un Badge seul est un boost, trois Badges qui synergisent c'est une machine. Voir [Principe](../badges/principe.md).

## 5. Spéciaux (one-shot, shop)

Les [spéciaux](../jetons/specials.md) scalent la puissance **ponctuelle** d'une manche. Pas de scaling permanent — mais un outil pour passer un mur.

## 6. Modifiers de cellules (plusieurs vecteurs à terme)

La grille elle-même évolue. Voir [Modifiers de cellules](../grille/modifiers-cellules.md) pour l'inventaire des sources.

## 7. États de boutons (réserve)

Voir [États de jetons](../jetons/etats-reserve.md). Déprioritisé — à implémenter plus tard si le jeu manque de profondeur.

## Liens

- [Structure du run](structure-run.md)
- [Monnaies](monnaies.md)
- [Shore — unlocks (enrichit les pools)](../shore/unlocks.md)
