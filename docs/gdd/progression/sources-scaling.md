# Sources de scaling

Les leviers qui font monter la puissance du joueur au fil d'un run.

## 1. Ajout de boutons (shop)

Un [bouton](../jetons/boutons.md) acheté à l'unité ou via [pack](../shop/packs.md) est **permanent pour la run** (le pool de boutons est [persistant](../manche/deck.md)). Le deck grossit → +1 drop par manche → scaling doux du nombre de coups, vers un deck fat.

## 2. Outils de deck "Dés à coudre" (shop, gatés)

Fusionner 2 boutons possédés (famille libre) en 1 seul, de valeur = somme des deux (**plafonnée à 10**, `MAX_BUTTON_VALUE`) et famille tirée au hasard entre les deux entrées — réduit le deck et concentre sa valeur, le levier "slim" opposé à l'ajout de boutons. Fusionner n'est plus qu'une des **10 actions** débloquées par l'achat d'un item **Dés à coudre** (`DECK_TOOL_ACTION_DRAW_SIZE` = 3 actions tirées, `DECK_TOOL_TARGET_DRAW_SIZE` = 8 boutons candidats), généralisée en session 16 — voir [Boutons — outils de deck](../jetons/boutons.md).

## 3. Partitions level up (par le jeu)

Les [Partitions](../partitions/principe.md) montent en niveau par le score cumulé. Une Partition **Forte** (lv.3) score beaucoup plus qu'une **Pianissimo** (lv.1), même avec les mêmes boutons. Source principale de scaling organique. Au-delà de Maestro (lv.5), le niveau continue en "dan" sans plafond (session 16) — c'est ce prolongement qui porte le scaling de fin de partie en [mode infini](structure-run.md#mode-infini). Voir [Level up](../partitions/level-up.md).

## 4. Sortilèges accumulées (shop)

Les passifs se combinent et créent des **synergies exponentielles**. Un Sortilège seul est un boost, trois Sortilèges qui synergisent c'est une machine. Voir [Principe](../sortileges/principe.md).

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
