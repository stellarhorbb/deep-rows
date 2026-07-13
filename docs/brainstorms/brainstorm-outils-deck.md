# Brainstorm — Outils de deck ("Dés à coudre", session 16)

**Statut : implémenté** (session 16) — `scripts/data/deck_tool_data.gd`, 9 `.tres` dans `resources/deck_tools/`, `RunManager`/`ShopManager`/`ShopUI` étendus. Voir [Boutons](../gdd/jetons/boutons.md) pour la doc GDD à jour.

Généralisation de la Fusion (voir [Boutons](../gdd/jetons/boutons.md)) en une vraie rubrique de manipulation du deck, façon Tarot de Balatro adapté aux boutons de Deep Rows. Parti d'un constat en remplissant la Google Sheet des Badges : trois rubriques existent déjà (économie/grille/multi), mais rien ne touche directement au deck/aux jetons — ni côté Badges, ni côté shop au-delà de la seule Fusion.

## Pourquoi maintenant, malgré peu de Badges deck-aware

Le système a un intérêt dès aujourd'hui via les **Partitions**, pas besoin d'attendre des Badges qui lisent la composition du deck :
- Changer la famille d'un jeton pour compléter une Family Line/Square/Diamond/Plus/Cross/Ring/T
- Réduire/Augmenter une valeur pour viser un Fibonacci ou une Suite exacte
- Supprimer un jeton pour épurer le deck — impact démultiplié par le **sans reshuffle, un seul passage** (chaque retrait améliore mécaniquement les probas de tirage de tout ce qui reste)

Ça renforce aussi un levier déjà identifié dans [Sources de scaling](../gdd/progression/sources-scaling.md) (la Fusion y est déjà le levier "slim", opposé à l'achat de boutons) plutôt que d'introduire un axe spéculatif.

Le vrai plafond de profondeur arrivera plus tard, avec les futurs Badges deck-aware (le trou "scaling"/manipulation identifié dans `brainstorm-badges.md`) — mais ce n'est pas une condition pour que le système vaille le coup maintenant.

## Mécanique (revue en cours d'implémentation, session 16)

Premier jet : un écran en 2 temps (choisir l'action, puis voir les cibles). Changé après un 1er test en jeu — le user a fait remarquer que voir cibles et actions **en même temps** guide le choix et évite de choisir une action qui n'aurait finalement aucune cible valide dans le tirage. Version finale, un seul panneau :

1. Achat d'un **Dés à coudre** (nom provisoire, catégorie shop existante) au même titre que Partition/Badge/Spécial/Bouton
2. Tire **3 actions distinctes** (pas de doublon) parmi le pool ci-dessous, pondérées par rareté — réutilise l'échelle Common/Uncommon/Rare/Epic (poids 10/5/2/1) déjà en place pour Partitions/Badges — **et** tire **8 candidats** (`GameRules.DECK_TOOL_TARGET_DRAW_SIZE`) du pool possédé, affichés dans le même panneau, en même temps
3. Le joueur sélectionne librement 1 ou 2 boutons (jusqu'au max requis par Fusionner) — aucune contrainte à la sélection elle-même
4. Les 3 actions s'activent/désactivent en fonction de ce qui est sélectionné (bon nombre de cibles + contrainte respectée : parité pour Scinder, plafond/plancher pour Augmenter/Réduire, famille différente pour Changer, somme ≤10 pour Fusionner)
5. Cliquer une action activée l'applique **immédiatement** — pas de confirmation séparée, le clic sur l'action est la confirmation

Toujours pas d'accès libre à tout le deck pour la sélection de cible (tirage random de 8), cohérent avec le shop RNG-forward — mais le tirage est maintenant visible avant de s'engager sur une action, contrairement au principe de la Fusion seule qui précédait.

## Pool d'actions (v1)

Chaque famille de destination est une action **distincte** dans le pool (pas "changer de famille" + un choix de destination libre) — reste cohérent avec le principe RNG-forward : le joueur ne contrôle ni la cible ni la famille d'arrivée, juste laquelle des 3 actions tirées il retient.

| Rareté | Action | Effet |
|---|---|---|
| Common | Augmenter une valeur | +1 fixe sur un jeton |
| Common | Réduire une valeur | -1 fixe sur un jeton |
| Common | Changer vers Coral | Recolore un jeton vers la famille Coral |
| Common | Changer vers Shell | Recolore un jeton vers la famille Shell |
| Common | Changer vers Rust | Recolore un jeton vers la famille Rust |
| Common | Changer vers Ink | Recolore un jeton vers la famille Ink |
| Uncommon | Scinder | Inverse de la Fusion : 1 jeton de valeur **paire** → 2 jetons de valeur moitié-moitié (ex : 6 → 3+3). Uniquement sur les valeurs paires — les jetons impairs ne sont pas des cibles valides |
| Uncommon | Fusionner | Existant, voir [Boutons](../gdd/jetons/boutons.md) — **nerfé** : n'est plus garantie à chaque achat de Dés à coudre, devient un tirage pondéré comme les autres |
| Rare | Suppression | Retire un jeton du deck, jamais remplacé — le plus fort des neuf vu le sans-reshuffle |

Total : 9 actions distinctes dans le pool aujourd'hui.

## Mis de côté pour plus tard (tier Epic vide)

- **Duplication** — copie un jeton existant (famille + valeur)
- **Jeton arc-en-ciel** — un jeton qui compte comme les 4 familles à la fois. Question ouverte non résolue avant de le coder : comment il se comporte sur une Partition **Rainbow**, qui exige 4 familles *distinctes* — wildcard qui prend la famille manquante, ou casse la condition de distinction si deux arc-en-ciel se retrouvent dans la même figure ?

Le tier Epic reste vide exprès plutôt que vidé de sens — pas besoin de retasser les poids des 9 actions actuelles quand ces deux-là seront réintroduites.

## Points non tranchés

- **Nom final** — "Dés à coudre" reste un placeholder hérité de la Fusion seule, à revoir maintenant que la rubrique s'élargit
- **Suppression vs décision "pas de défausse"** — vérifié que ça n'entre pas en collision : la décision verrouillée visait la défausse *en cours de manche* (pêche aux spéciaux), la Suppression ici est un achat au shop entre deux manches, axe différent

## Tranché (session 16)

- **Augmenter/Réduire** : +1 / -1 fixe sur la valeur du jeton cible
- **Scinder** : uniquement sur les jetons de valeur paire, split exact moitié-moitié (6 → 3+3, 4 → 2+2, 2 → 1+1) — pas de répartition aléatoire, et les jetons impairs ne sont simplement pas des cibles valides pour cette action
- **Prix** : un prix unique pour le Dés à coudre lui-même (comme aujourd'hui, `GameRules.DES_A_COUDRE_PRICE = 6`), pas un prix par action — le joueur achète avant de voir les 3 actions tirées, donc un prix variable par action n'aurait aucun sens. La variance de puissance entre les 9 actions se gère par leur poids d'apparition (rareté), pas par le prix.

## Liens

- [Boutons](../gdd/jetons/boutons.md) — Fusion existante, à généraliser
- [Sources de scaling](../gdd/progression/sources-scaling.md) — levier "slim" déjà identifié
- [Décisions tranchées](../gdd/meta/decisions-tranchees.md) — sélection de fusion, pas de défausse
- [Brainstorm Badges](brainstorm-badges.md) — trou "scaling"/deck-manipulation, futur plafond de profondeur
- [Questions ouvertes](../gdd/meta/questions-ouvertes.md)
