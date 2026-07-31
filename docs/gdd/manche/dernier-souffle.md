# Le Dernier Souffle

Le moment de vérité. Se déclenche **toujours** quand le [deck](deck.md) est vide, même sans jetons spéciaux.

## Les étapes

1. Signal `last_breath_started` émis → déclenche les [Sortilèges](../sortileges/triggers.md) avec trigger `on_last_breath`
2. Les **[rocks](../jetons/rocks.md) et résidus** sur la grille disparaissent (explosion visuelle)
3. Leur disparition crée des trous → la **gravité redistribue** les [boutons](../jetons/boutons.md) restants
4. Les retombées peuvent créer de nouveaux patterns → **cascade surprise** non planifiable
5. Les [jetons entity](../jetons/entity-skull.md) survivent (restent obstacles)
6. Les boutons restants après ça ne scorent plus — c'est fini
7. Verdict final sur le [score cible](score-cible.md)

## Ce qui disparaît / survit

| Type de jeton | Dernier Souffle |
|---|---|
| Rocks | **Explosent** — créent des trous |
| Résidus (fantômes posés) | **Explosent** — créent des trous |
| Jetons entity-skull | **Survivent** — restent obstacles |
| Boutons | Survivent mais ne scorent plus |

## Design intent

- **Moment de tension pure** à chaque fin de manche, même dans les runs sans spéciaux
- Placement des rocks devient stratégique — bien placés, leur explosion libère des cascades
- Les cascades surprises créent des moments mémorables
- **Coup de pouce**, pas une stratégie principale — tu peux le provoquer mais tu ne le contrôles pas
- **Double Partition sans chevauchement (session 23)** — l'explosion touche plusieurs colonnes à la fois (contrairement à un coup normal, limité à une seule), donc c'est le seul moment du jeu où deux figures totalement séparées peuvent scorer dans la même passe de résolution. Comptent comme [Double Partition](../partitions/catalogue-implemente.md#chevauchement-de-figures--double-partition-session-13-révisé-session-15) au même titre qu'un chevauchement délibéré — aucune règle spéciale ajoutée, conséquence mécanique de la règle générale

## Sortilèges liés

Les Cartes avec trigger `on_last_breath` (ex : [Bombe à retardement](../sortileges/sortileges-implementes.md), HOB-10) s'exécutent pendant cette phase. Elles respectent la mécanique — les cascades post-explosion ne se résolvent que si elles matchent une [Partition équipée](../partitions/principe.md).

## Liens

- [Déroulement](deroulement.md)
- [Score cible](score-cible.md)
- [Rocks](../jetons/rocks.md)
- [Sortilèges — triggers](../sortileges/triggers.md)
- [Cartes implémentées](../sortileges/sortileges-implementes.md)
