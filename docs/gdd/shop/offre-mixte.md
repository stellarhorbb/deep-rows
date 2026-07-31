# Shop — offre mixte

À chaque visite, les [grenouilles orchestre](../univers/personnages/grenouilles-orchestre.md) proposent une **offre en deux rangées séparées**, à la Balatro.

## Les deux rangées

- **Packs** — `GameRules.SHOP_PACK_SLOT_COUNT` (2) slots, catégorie aléatoire, contenu révélé à l'ouverture. **Fixes pour toute la visite**, jamais régénérés par le [reroll](reroll.md).
- **Unitaires "en vitrine"** — `GameRules.SHOP_UNITAIRE_SLOT_COUNT` (2) slots, visibles directement (item + prix affichés), catégorie aléatoire. **Régénérés à chaque reroll.**

Premier jet à 5 slots plats, tout-aléatoire (catégorie + format indépendants par slot) — abandonné après un retour de test : trop imprévisible, le joueur pouvait ne jamais croiser une catégorie donnée de toute la visite. La séparation packs fixes / unitaires rerollables règle ça, et colle davantage à la vraie structure Balatro (2 boosters + 2 cartes visibles, reroll uniquement sur les cartes).

## Ce qu'on achète

Catégories possibles pour un slot :

| Catégorie | Unitaire | Pack |
|---|---|---|
| [Boutons](../jetons/boutons.md) | +1 drop permanent pour la run | Contenu : 5 candidats, tu en gardes 1 (exception à la règle des 3, voir [Packs](packs.md)) |
| [Partitions](../partitions/principe.md) | Équipe un slot (max 4) | Contenu : 3 candidats, tu en gardes 1 |
| [Spéciaux](../jetons/specials.md) | One-shot ajouté au deck | Contenu : 3 candidats, tu en gardes 1 |
| [Sortilèges](../sortileges/principe.md) | Équipe un slot (max 5) | Contenu : 3 candidats, tu en gardes 1 |
| **Dés à coudre** | Tire 3 [actions de deck](../jetons/boutons.md#outils-de-deck-gatés-par-dés-à-coudre-session-12-généralisé-session-16) (Augmenter, Fusionner, Fixer...) parmi 10, applique celle choisie | — (pas de version pack) |

Dés à coudre n'apparaît que côté unitaire — ce n'est pas un tirage-et-choix-1 comme les autres, juste un déblocage d'action.

## Le dilemme

Le budget [Mouches](../progression/monnaies.md) est limité :

- Renforcer le build (partition, sortilège) ou se préparer au court terme (spéciaux) ?
- Payer un unitaire visible ou parier sur un pack (ratio meilleur mais random) ?
- [Reroll](reroll.md) pour chercher mieux côté vitrine, ou accepter et garder des mouches ?

C'est le cœur stratégique entre les manches.

## Statut

**Implémenté** (session 12, ex-HOB-13). Voir [Packs](packs.md), [Génération de l'offre](generation-offre.md), [Reroll](reroll.md) pour le détail de chaque brique.

## Liens

- [Packs](packs.md)
- [Reroll](reroll.md)
- [Économie](economie.md)
- [Génération de l'offre](generation-offre.md)
- [Grenouilles orchestre](../univers/personnages/grenouilles-orchestre.md)
