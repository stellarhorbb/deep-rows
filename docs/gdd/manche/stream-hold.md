# Stream + Hold

## Stream

Le joueur ne pioche pas une main. Les jetons arrivent **un par un** depuis le [deck](deck.md), dans un flux continu.

Une **preview** affiche les 3 prochains jetons à venir (`PREVIEW_SIZE` dans `game_rules.gd`), pour permettre l'anticipation.

Raison : une main filtrerait, tout part sur la grille de toute façon. Le stream colle à l'ADN cascade — on ne trie pas, on pose ce qui arrive.

## Hold (1 slot)

À tout moment, le joueur peut **mettre le jeton courant en hold** dans un slot dédié. Le jeton suivant prend sa place. Si le slot est déjà occupé, les deux s'échangent (le hold devient le jeton courant).

- **Un seul slot par défaut**
- **Slot upgradable via [Badge](../badges/principe.md) / unlock** (+1 slot supplémentaire)
- Fonctionne pour **n'importe quel jeton** ([bouton](../jetons/boutons.md) ou [special](../jetons/specials.md))

## Design intent

Le skill vient de **trois décisions à chaque drop** :
- Dans quelle colonne je drop ?
- Hold ou pas ? (mettre de côté pour plus tard)
- Anticiper ce qui arrive dans la preview

Tempo nerveux — pas de micro-gestion, pas de menus. La planification se fait sur la grille, pas sur une main à trier.

## Liens

- [Deck](deck.md)
- [Inspecteur de deck](inspecteur-deck.md)
- [Déroulement](deroulement.md)
- [Badges — principe](../badges/principe.md)
