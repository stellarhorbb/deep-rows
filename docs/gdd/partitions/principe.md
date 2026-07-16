# Les Partitions — principe

Ce qui fait vivre la grille. **Sans Partition correspondante équipée, rien ne se résout.**

Thématiquement : ce sont littéralement **des partitions musicales** vendues par les [grenouilles orchestre](../univers/personnages/grenouilles-orchestre.md), avec la forme dessinée dessus. Le joueur comprend la règle par l'image.

*Nom code : `PatternData`, slots "pattern tags". "Partition" est le terme thématique affiché.*

## La règle fondamentale

Une Partition combine une **forme** (ligne 3+, carré 2×2, losange) et une **règle** (même famille, même chiffre, suite…). Pour qu'une figure alignée sur la grille se résolve, elle doit correspondre **à au moins une Partition équipée** :

- Figure alignée + Partition correspondante équipée → résolution + score
- Figure alignée + aucune Partition correspondante → **rien ne se passe**, les jetons restent sur la grille

C'est le cœur du puzzle. Le joueur ne choisit pas juste comment scorer — il choisit **quoi résoudre**. Ce qui n'a pas de Partition compatible s'accumule et clogge l'espace. Les [rocks](../jetons/rocks.md) sont l'expression permanente de cette logique.

## Slots et démarrage

- **4 slots max** actifs à un instant donné (`MAX_PATTERN_SLOTS` dans `game_rules.gd`)
- **Écran de sélection en début de run** (session 12) : 3 Partitions tirées au hasard dans tout le catalogue, le joueur en choisit **2, gratuites**. Remplace l'ancienne idée de "pack de boutons qui livre 1-2 Partitions pré-équipées" — jamais implémentée telle quelle, cette version-là l'a été à la place. (Une seule Partition de départ a été testée en premier jet et jugée trop punitive — voir le log de session 12.)
- Les 2 slots restants se remplissent au shop via des partitions unitaires ou des **packs**
- Pool cible : **20-30 Partitions** (voir `brainstorm-pattern-tags.md`) — 17 actives aujourd'hui, voir [Catalogue implémenté](catalogue-implemente.md)

## Vente (session 12)

N'importe quelle Partition équipée peut être **vendue à tout moment** contre 50% de son prix d'achat en mouches (`RunManager.sell_tag`, `GameRules.SELL_REFUND_RATIO`), aucun plancher — vendable jusqu'à 0 Partition équipée, façon Balatro. Vendre en cours de manche ne perturbe pas la résolution en cours (déjà snapshotée au début de la manche) — l'affichage se met à jour à la manche suivante.

## Choix stratégiques

- **Quoi résoudre ?** — un mauvais loadout transforme des familles en déchet qui clogge. Punition assumée qui donne du poids au choix au shop.
- **Largeur vs profondeur** — acheter une nouvelle Partition (plus de manières de résoudre) ou investir dans celles qu'on a (level up plus rapide) ?
- **Build sniper** — peu de Partitions mais très haut niveau
- **Build flexible** — beaucoup de Partitions bas niveau, tu résous sur tout ce qui tombe
- **Respec via la vente** — un mauvais choix de départ ou un axe qui ne paye plus n'est plus figé pour toute la run

## Liens

- [Formes](formes.md)
- [Axes de règles](axes-de-regles.md)
- [Scoring](scoring.md)
- [Level up (Pianissimo → Maestro)](level-up.md)
- [Catalogue implémenté](catalogue-implemente.md)
