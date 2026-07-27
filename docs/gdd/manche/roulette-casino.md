# Axe casino — Jauge, roulette et cases mystère

Système conçu en session 25, pas encore implémenté. Né d'une comparaison avec Raccoin (coin-pusher roguelite) : là où les cascades de Deep Rows restent structurellement rares (gating par [Partition](../partitions/principe.md) — chaque maillon d'une chaîne doit matcher un slot équipé), la roulette ajoute une couche de spectacle garanti à intervalle prévisible, sans toucher au [pilier de résolution conditionnelle](decisions-tranchees.md).

## Cases mystère — rappel

Déjà codées (session 24, `MysteryCellEffects`, `GameRules.ROUND_START_MYSTERY_MIN/MAX`) : 2-4 cases "?" posées au début de chaque manche, effet caché révélé quand un jeton atterrit dessus, paliers de rareté Commun/Rare/Jackpot (`MYSTERY_RARITY_RATES = [0.55, 0.40, 0.05]`).

**Décision session 25 : le quota de départ reste.** Un temps envisagé de tout faire venir de la roulette seule (voir plus bas), mais ça laissait la grille sans aucune case mystère tant que la jauge n'a pas fait un premier tour — le quota de départ garde une texture "pari spatial" présente du premier au dernier coup de la manche.

## La jauge

**Ce qui la remplit** — la valeur brute du jeton posé, telle quelle (poser un 9 avance la jauge de 9, un 1 de 1). Choix déterministe, pas un tirage indépendant : la première piste envisagée (tirage aléatoire à chaque drop, façon loterie) posait un problème de lisibilité — impossible pour le joueur de justifier pourquoi un 1 avancerait plus qu'un 9. La valeur imprimée sur le jeton EST la justification, aucun apprentissage requis.

- **Rocks** — ne remplissent rien (poids mort, cohérent avec leur rôle)
- **Spéciaux** — un forfait fixe généreux (valeur exacte à caler), puisqu'ils n'ont pas de valeur numérique porteuse de sens (`TokenData.value` reste à 1 par défaut pour `Kind.SPECIAL`)

**Le seuil : fixe à 21, pour toute la run.** Pas un ratio recalculé par manche (rejeté — "chiffre qui scale sur une décision arbitraire du dev", et surtout ça amortirait le snowball recherché). Choisi à dessein pour qu'aucun jeton seul, même un Roi (`FACE_CARD_VALUES` max = 20), ne puisse déclencher la roulette à lui seul — il faut toujours au moins 2 drops. Clin d'œil discret à l'ADN blackjack du projet (pivot de Salt House), jamais dit au joueur.

**Effet recherché, assumé** : un deck de départ (budget total ~72 en valeur cumulée — voir calcul ci-dessous) tourne à 3-4 déclenchements par manche en zone 1. Un deck bien buildé plus tard dans la run (Fusion/Augmenter jusqu'à `MAX_BUTTON_VALUE = 10`, figures jusqu'à Roi = 20) fait sauter le même seuil fixe en une poignée de drops — la roulette spamme. C'est volontaire : le joueur "casse le jeu" avec son propre build, à la Balatro, sans qu'aucun plafond artificiel ne vienne l'en empêcher.

> Calcul du budget de départ (`GameRules`, session 25) : deck de base = 28 boutons (valeurs 1-2 en double copie par famille, 3-5 en simple) + 4 rocks. Somme des valeurs = 8×1 + 8×2 + 4×3 + 4×4 + 4×5 = **72**. Avec un seuil à 21, ça donne ~3-4 tours de roulette en manche 1.

## Duo Planter / Récolter

Deux prix parmi ceux de la roulette, pensés comme complémentaires plutôt que redondants avec le système de cases mystère :

- **Planter** — pose une nouvelle case mystère sur la grille (mise en attente, pari futur, spatial et différé — le joueur doit encore y faire atterrir un jeton)
- **Récolter** — résout instantanément une case mystère déjà posée, sans attendre qu'un jeton y tombe (encaissement immédiat, garanti)

Ce sont les seuls prix de la roulette qui touchent au système de cases mystère. **Aucun autre chevauchement volontaire** : les autres prix (voir ci-dessous) sont exclusivement instantanés et non-spatiaux, pour que le joueur distingue clairement les deux vecteurs de surprise du jeu — "la roulette me donne un truc maintenant" vs "une case mystère, c'est un pari sur un endroit de la grille". La première version envisagée (la roulette peut *seulement* ajouter des cases mystère) créait un emboîtement confus (une surprise qui en déclenche une autre, en différé) ; distinguer clairement timing immédiat vs timing différé règle le problème sans jeter l'idée.

## Autres catégories de prix (roulette)

Toutes instantanées et garanties, orientées momentum/stream plutôt que grille :

- Pluie de spéciaux (salve immédiate dans le stream à venir)
- Charge de [Shake](decisions-tranchees.md) supplémentaire (ressource rare, `SHAKE_CHARGES_DEFAULT = 2`)
- Résolution forcée d'une figure clognée (immédiate, pas une case posée)
- Nettoyage direct (Rocks retirés / trous rebouchés tout de suite)
- Multiplicateur temporaire sur les prochains drops

**Ampleur du prix** — piste évoquée mais pas tranchée : faire dépendre le palier (Commun/Rare/Jackpot) du **dépassement du seuil** plutôt que d'un tirage complètement détaché (un gros dépassement, ex. poser un Roi alors que la jauge était presque pleine, piocherait dans un meilleur palier). Cohérent avec le principe "la valeur affichée justifie l'effet" qui gouverne le remplissage de la jauge. Pas encore spécifié en détail.

## Synergies futures (Badges / Boss malus)

Pas conçu en détail, mais l'architecture s'y prête directement — `BossMalusManager` a déjà un précédent exact (Pluie de cailloux injecte `BOSS_MALUS_ROCK_COUNT` rocks via une simple constante `GameRules`). Pistes évoquées :

- **Badge positif** — plus de cases mystère au départ, meilleures odds de rareté, seuil de roulette abaissé
- **Malus de boss** — cases mystère réduites/absentes, seuil relevé, pool de prix appauvri

À spécifier (noms, valeurs, triggers précis) le jour où on passe à l'implémentation.

## Ce qui a été écarté

- **Tirage aléatoire pur pour remplir la jauge** — illisible (voir ci-dessus)
- **Seuil relatif à la valeur du deck de la manche** — corrigeait le snowball recherché, contraire à l'effet voulu
- **Plafonner la contribution d'un drop** (ex. à `TOKEN_MAX_VALUE = 5`) — même raison, tuerait le power-fantasy
- **Roulette qui donne un accès de vitesse de drop (temps réel)** — le jeu n'a aucune mécanique temps réel nulle part (tous les countdowns existants sont par tour, pas par horloge) ; récompenser la nervosité irait frontalement contre l'identité "jeu de stratégie" affirmée cette même session

## Liens

- [Décisions tranchées](decisions-tranchees.md)
- [Spéciaux — famille réactive](../jetons/specials.md#spéciaux-réactifs--famille-identifiée-session-25)
- [Dernier Souffle](dernier-souffle.md)
- [Rocks](../jetons/rocks.md)
