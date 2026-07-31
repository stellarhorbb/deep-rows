# Grille cabossée (trous)

Ajouté en session 12 pour casser la routine — chaque manche démarre légèrement différente, sans toucher au geste ni au moteur de résolution.

## Fonctionnement

- **5 à 8 trous** générés aléatoirement sur la grille au tout début de chaque manche, avant le premier drop (`GameRules.ROUND_START_HOLES_MIN/MAX`)
- **Jamais en row 0** — le sol reste toujours garanti dans chaque colonne, aucune colonne ne peut se retrouver totalement bouchée
- Un trou peut apparaître n'importe où au-dessus (row 1, 2, 3…), potentiellement plusieurs par colonne

## Différence avec un Rock

C'est la distinction importante : un [Rock](../jetons/rocks.md) **bloque et sert d'appui** (les jetons peuvent atterrir dessus, il occupe une case). Un trou fait l'inverse : **transparent à la gravité**, un jeton qui tombe le traverse sans jamais pouvoir s'y arrêter. Visuellement, un trou est une case foncée distincte des cases vides normales.

## Impact sur la gravité et les spéciaux

Un vrai trou touche la gravité elle-même, pas juste le point d'atterrissage — `GravitySystem` et `CascadeResolver` en tiennent compte pendant la compaction (les trous ne comptent jamais comme un emplacement occupé ni disponible). Les trois jetons spéciaux ([Fantôme, Bombe, Marée](../jetons/specials.md)) sont trou-aware également, via `SpecialEffects`.

## Pourquoi

Diagnostic posé en playtest : la grille se vidait presque à chaque manche, ce qui laissait le joueur retomber sur le stacking colonne (toujours sûr, jamais de vraie lecture 2D nécessaire). Une grille légèrement irrégulière dès le premier drop force à regarder la grille avant de jouer, sans réintroduire toute la densité d'un plateau façon Candy Crush (piste explorée puis abandonnée — voir le log de session 12).

## Statut

Premiers jets (5-8 trous, jamais row 0) — intensité à retuner selon le ressenti. Pas encore de source supplémentaire (Sortilège, zone, Entity) qui ajouterait des trous — pourrait être une piste de contenu future.

## Liens

- [Format de la grille](format.md)
- [Gravité et résolution](gravite-resolution.md)
- [Rocks](../jetons/rocks.md)
- [Spéciaux](../jetons/specials.md)
