# Shop — reroll

Le joueur peut **reroll** pour voir de nouveaux items. **Ne touche que la rangée "en vitrine" (unitaires)** — les [packs](packs.md) restent fixes pour toute la visite, comme dans Balatro (le reroll n'y rafraîchit jamais les boosters, seulement la rangée de cartes visibles).

## Prix croissant

`GameRules.REROLL_BASE_PRICE = 2`, `GameRules.REROLL_INCREMENT = 1` — chaque reroll suivant coûte +1 mouche dans la même visite.

Exemple :
- 1er reroll : 2 mouches
- 2e reroll : 3 mouches
- 3e reroll : 4 mouches
- ...

**Statut** : implémenté (session 12) avec ces valeurs de départ, à réequilibrer au fil du playtest.

## Design intent

Force le **dilemme "j'accepte ou je pousse le destin"** :
- À chaque reroll, tu dépenses des mouches que tu ne pourras pas mettre dans des items
- Pousse à ne reroll que quand l'offre actuelle est vraiment décevante
- Crée de la tension émotionnelle (frustration / espoir / regret)

## Reset

Le compteur de reroll **reset à chaque nouvelle visite du shop** (manche suivante).

## Liens

- [Offre mixte](offre-mixte.md)
- [Packs](packs.md)
- [Économie](economie.md)
- [Monnaies](../progression/monnaies.md)
