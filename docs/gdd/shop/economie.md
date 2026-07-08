# Shop — économie

Les prix reflètent l'accessibilité voulue par catégorie.

## Hiérarchie des prix

- **[Boutons](../jetons/boutons.md) + [Spéciaux](../jetons/specials.md)** → **très accessibles.**
- **Dés à coudre** (débloque une [fusion de boutons](../jetons/boutons.md)) → accessible, remplace l'ancien prix plat par fusion depuis que la fusion est gatée (session 12).
- **[Partitions](../partitions/principe.md) + [Badges](../badges/principe.md)** → **plus chers.** Choix structurants pour la run.
- **Packs** → plus chers que leur équivalent unitaire cumulé, mais **meilleur ratio par item**. Tu payes le "plus mais random".

## Valeurs actuelles (proto)

Unitaires :

| Catégorie | Item | Prix (mouches) |
|---|---|---|
| Spécial | Fantôme / Bombe / Marée | 2 |
| Partition | Family Line 4 / Family Line 3 Diag | 6 |
| Partition | Square Family 4 | 8 |
| Partition | Family Line 5 / Family Diamond | 10 |
| Partition | Diamond Rock | 12 |
| Badge | Mouches en Cascade / Cellule Double / Pourboire | 3 |
| Badge | Cellule Triple / Famille Unie / Écume / Vertige / Colonne Chanceuse | 4 |
| Badge | Tranchée / Collectionneur | 5 |
| Bouton | Achat unitaire | `BUTTON_UNIT_PRICE` = 3 |

Packs (`GameRules.PACK_PRICE_*`) et Dés à coudre :

| Item | Prix (mouches) |
|---|---|
| Pack Spécial | 4 |
| Pack Badge | 8 |
| Pack Bouton | 10 |
| Pack Partition | 14 |
| Dés à coudre | 6 |

Toutes ces valeurs sont des premiers jets, à rééquilibrer avec plus de playtest.

## Gains de mouches

| Source | Montant |
|---|---|
| Manche réussie | Fixe de base (`FLIES_PER_ROUND_WON` = 10 actuellement) |
| Vente d'une Partition/Badge équipé | 50% de son prix d'achat (`SELL_REFUND_RATIO`, session 12) |
| Surplus de score | À designer (bonus selon score au-dessus de la cible ?) |
| Badges | Ex : Mouches en Cascade +3 par cascade secondaire, Pourboire +5/manche, Vertige +8 si cascade profonde |

## Liens

- [Offre mixte](offre-mixte.md)
- [Packs](packs.md)
- [Reroll](reroll.md)
- [Monnaies](../progression/monnaies.md)
