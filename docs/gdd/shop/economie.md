# Shop — économie

Les prix reflètent l'accessibilité voulue par catégorie.

## Hiérarchie des prix

- **[Boutons](../jetons/boutons.md) + [Spéciaux](../jetons/specials.md)** → **très accessibles.**
- **Dés à coudre** (débloque une [fusion de boutons](../jetons/boutons.md)) → accessible, remplace l'ancien prix plat par fusion depuis que la fusion est gatée (session 12).
- **[Partitions](../partitions/principe.md) + [Badges](../badges/principe.md)** → **plus chers.** Choix structurants pour la run.
- **Packs** → plus chers que leur équivalent unitaire cumulé, mais **meilleur ratio par item**. Tu payes le "plus mais random".

## Valeurs actuelles (proto)

Constantes globales (`game_rules.gd`) :

| Item | Prix (mouches) |
|---|---|
| Bouton à l'unité | `BUTTON_UNIT_PRICE` = 5 |
| Spécial à l'unité (Fantôme / Bombe / Marée) | 2 (`price` sur chaque `.tres`) |
| Dés à coudre | `DES_A_COUDRE_PRICE` = 6 |
| Pack Spécial | `PACK_PRICE_SPECIAL` = 4 |
| Pack Bouton | `PACK_PRICE_BUTTON` = 4 |
| Pack Badge | `PACK_PRICE_BADGE` = 6 |
| Pack Partition | `PACK_PRICE_TAG` = 8 |

Les prix unitaires de chaque Partition (6 à 15 selon le tier) et de chaque Badge (3 à 8 selon la rareté) vivent sur leur `.tres` respectif, synchronisés avec le [Google Sheet](https://docs.google.com/spreadsheets/d/1JMEQf2W6H8fMZ24D63-jRQrJKz5424kR7Exyo4xvM_0/edit) (source de vérité depuis le 2026-07-10) — voir [Catalogue implémenté](../partitions/catalogue-implemente.md) pour la table Partitions à jour plutôt que de la dupliquer ici.

Toutes ces valeurs sont des premiers jets, à rééquilibrer avec plus de playtest.

## Gains de mouches

| Source | Montant |
|---|---|
| Manche réussie | `FLIES_PER_ROUND_WON` = 8 |
| Bonus deck confortable en fin de manche | +`FLIES_BONUS_REMAINING` (2) si `>= FLIES_BONUS_REMAINING_THRESHOLD` (10) boutons restants au moment de la victoire (session 18, seuil inclusif corrigé session 19) |
| Vente d'une Partition/Badge équipé | 50% de son prix d'achat (`SELL_REFUND_RATIO`) |
| Surplus de score | À designer (bonus selon score au-dessus de la cible ?) |
| Badges | Ex : Mouches en Cascade +3 par cascade secondaire, Pourboire +3/manche, Vertige +10 si cascade profonde — voir [Badges implémentés](../badges/badges-implementes.md) pour le détail à jour |

## Liens

- [Offre mixte](offre-mixte.md)
- [Packs](packs.md)
- [Reroll](reroll.md)
- [Monnaies](../progression/monnaies.md)
