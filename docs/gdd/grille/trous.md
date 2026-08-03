# Grille cabossée (trous)

Ajouté en session 12 pour casser la routine — chaque manche démarre légèrement différente, sans toucher au geste ni au moteur de résolution. Génération revue en session 26 (voir "Fond marin" ci-dessous) après un diagnostic de playtest : le scatter uniforme d'origine réglait le côté "grille plate" mais rien de la vraie cause du ressenti "chiant en début de manche" — voir [Persistance entre manches](../manche/persistance-entre-manches.md) pour l'autre moitié de la réponse.

## Fonctionnement (session 26 — "fond marin")

Deux couches, générées dans cet ordre (`GridManager.generate_random_holes`) :

1. **Le fond marin** — plusieurs pics indépendants (`GameRules.SEAFLOOR_PEAK_COUNT_MIN/MAX`, 2 à 4 par manche), chacun une pyramide en escalier ancrée sur une colonne au hasard : hauteur 1/2/3 tirée à taux fixe (`SEAFLOOR_PEAK_HEIGHT_RATES`, 45/35/20%), largeur de base 1/3/5 selon la hauteur. Pas forcément centrée — un pic ancré près d'un bord est naturellement "coupé", une partie de sa base sort du cadre.
2. **Les trous rouges** — 2 à 4 en plus (`ROUND_START_RED_HOLES_MIN/MAX`), dispersés au hasard sur toute la grille, toujours en plus du fond marin, jamais en row 0.

Le fond marin lui-même peut toucher row 0 (un pic "casse la surface" jusqu'en bas) — seuls les trous rouges respectent la règle "jamais row 0".

## Historique des versions (session 26)

Trois jets avant celui-ci, chacun rejeté par un vrai defaut trouve au playtest ou en discussion :
1. **Marche aléatoire continue** (hauteur ±1 d'une colonne à l'autre) — pouvait dériver et laisser les 7 colonnes non-nulles en même temps, donnant un mur plein sur toute la rangée du bas (jamais vu dans les mockups de référence).
2. **Tirage indépendant par colonne** (taux fixe par hauteur, sans corrélation entre colonnes) — réglait le mur plein mais donnait un relief trop diffus/uniforme, pas le "pic net" voulu.
3. **Pic unique centré** — bien, mais toujours au même endroit (col 0) ou pas assez varié en position/taille selon le retour du user ("il faut que ça soit partout, milieu, gauche, droite, petit, plus grand").

## Différence avec un Rock

## Différence avec un Rock

C'est la distinction importante : un [Rock](../jetons/rocks.md) **bloque et sert d'appui** (les jetons peuvent atterrir dessus, il occupe une case). Un trou fait l'inverse : **transparent à la gravité**, un jeton qui tombe le traverse sans jamais pouvoir s'y arrêter. Visuellement, un trou est une case foncée distincte des cases vides normales.

## Impact sur la gravité et les spéciaux

Un vrai trou touche la gravité elle-même, pas juste le point d'atterrissage — `GravitySystem` et `CascadeResolver` en tiennent compte pendant la compaction (les trous ne comptent jamais comme un emplacement occupé ni disponible). Les trois jetons spéciaux ([Fantôme, Bombe, Marée](../jetons/specials.md)) sont trou-aware également, via `SpecialEffects`.

## Pourquoi

Diagnostic posé en playtest : la grille se vidait presque à chaque manche, ce qui laissait le joueur retomber sur le stacking colonne (toujours sûr, jamais de vraie lecture 2D nécessaire). Une grille légèrement irrégulière dès le premier drop force à regarder la grille avant de jouer, sans réintroduire toute la densité d'un plateau façon Candy Crush (piste explorée puis abandonnée — voir le log de session 12).

## Statut

Fond marin + trous rouges validés au playtest session 26 (relief visible, plus varié que le scatter d'origine) — total et répartition exacte (nombre de pics, taux par hauteur) restent un premier jet à surveiller. Pas encore de source supplémentaire (Sortilège, zone, Entity) qui ajouterait des trous — pourrait être une piste de contenu future.

## Liens

- [Format de la grille](format.md)
- [Gravité et résolution](gravite-resolution.md)
- [Rocks](../jetons/rocks.md)
- [Spéciaux](../jetons/specials.md)
- [Persistance entre manches](../manche/persistance-entre-manches.md)
