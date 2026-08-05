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

C'est la distinction importante : un [Rock](../jetons/rocks.md) **bloque et sert d'appui** (les jetons peuvent atterrir dessus, il occupe une case). Un trou fait l'inverse : **transparent à la gravité**, un jeton qui tombe le traverse sans jamais pouvoir s'y arrêter. Visuellement, un trou est une case foncée distincte des cases vides normales.

## Impact sur la gravité et les spéciaux

Un vrai trou touche la gravité elle-même, pas juste le point d'atterrissage — `GravitySystem` et `CascadeResolver` en tiennent compte pendant la compaction (les trous ne comptent jamais comme un emplacement occupé ni disponible). Les trois jetons spéciaux ([Fantôme, Bombe, Marée](../jetons/specials.md)) sont trou-aware également, via `SpecialEffects`.

## Pourquoi

Diagnostic posé en playtest : la grille se vidait presque à chaque manche, ce qui laissait le joueur retomber sur le stacking colonne (toujours sûr, jamais de vraie lecture 2D nécessaire). Une grille légèrement irrégulière dès le premier drop force à regarder la grille avant de jouer, sans réintroduire toute la densité d'un plateau façon Candy Crush (piste explorée puis abandonnée — voir le log de session 12).

## Statut

Fond marin + trous rouges validés au playtest session 26 (relief visible, plus varié que le scatter d'origine) — total et répartition exacte (nombre de pics, taux par hauteur) restent un premier jet à surveiller. Pas encore de source supplémentaire (Sortilège, zone, Entity) qui ajouterait des trous — pourrait être une piste de contenu future.

## Cases mystère

Codées en session 24 (`MysteryCellEffects`), posées au début de chaque manche (`GameRules.ROUND_START_MYSTERY_MIN/MAX`, 2 à 4), en dernier dans l'ordre de génération pour éviter les cases déjà occupées par le fond marin/les jetons persistés. Cases "?" visibles-mais-inconnues, effet caché révélé quand un jeton atterrit dessus, paliers de rareté Commun/Rare/Jackpot (`GameRules.MYSTERY_RARITY_RATES` = 55/40/5%).

**Catalogue recentré sur la grille/le jeton (session 27)** — retire les effets purement économiques (cible de score, mouches) diagnostiqués comme détachés du geste, voir [Colonne Convoitée](../manche/colonne-convoitee.md#ce-qui-a-été-écarté) pour le même diagnostic appliqué à la roulette. Ratio bonus/malus pondéré par palier visé à ~70/30 — volontairement généreux pour que chasser une case mystère reste un vrai attrait, jamais une pièce de monnaie neutre :

| Palier | Effet | Bonus/Malus | Description |
|---|---|---|---|
| Commun | Valeur +1 | Bonus | Augmente la valeur du jeton posé |
| Commun | Trou rebouché | Bonus | Comble un trou existant ailleurs |
| Commun | Valeur -1 | Malus | Diminue la valeur du jeton posé (plancher `TOKEN_MIN_VALUE`) |
| Rare | Verrou | Bonus | Verrouille le jeton posé contre toute mutation future |
| Rare | Fusion spontanée | Bonus | Fusionne le jeton posé avec un voisin adjacent (même formule que la Fusion du deck) |
| Rare | Pierre libérée | Bonus | Convertit un Rock adjacent en jeton de base |
| Rare | Multiplicateur ×2 | Bonus | Pose un modifier ×2 permanent sur la case |
| Rare | Multiplicateur ×5 | Bonus | Pose un modifier ×5 permanent sur la case |
| Rare | Pétrification | Malus | Un Rock surgit **sous** le jeton posé, qui remonte d'une case — le jeton lui-même n'est jamais muté |
| Rare | Modifier ×0.5 | Malus | Pose un modifier ×0.5 permanent sur la case |
| Jackpot | Multiplicateur ×10 | Bonus | Toujours bonus — pas de "jackpot malus", n'aurait aucun sens pour le joueur |

**Retirés du pool (session 27)** : Mutation de famille et Téléportation — retour direct du user en playtest, jamais appréciées : elles reviennent sur une décision de placement déjà prise (le jeton posé change d'identité ou de position après coup) plutôt que d'ajouter un obstacle avec lequel composer. Pétrification et Modifier ×0.5 gardés/préférés précisément parce qu'ils ne touchent jamais à ce qui a été décidé — un Rock ou un malus de case, pas une remise en cause du jeton lui-même.

**Désamorçage par l'Entity (session 27)** — un skull qui atterrit sur une case mystère non révélée la désamorce au lieu de la déclencher, voir [Colonne Convoitée](../manche/colonne-convoitee.md#cases-mystère-et-désamorçage).

## Liens

- [Format de la grille](format.md)
- [Gravité et résolution](gravite-resolution.md)
- [Rocks](../jetons/rocks.md)
- [Spéciaux](../jetons/specials.md)
- [Persistance entre manches](../manche/persistance-entre-manches.md)
- [Colonne Convoitée](../manche/colonne-convoitee.md)
