# Axe casino — Jauge, roulette et cases mystère

Système conçu et implémenté en session 25. Né d'une comparaison avec Raccoin (coin-pusher roguelite) : là où les cascades de Deep Rows restent structurellement rares (gating par [Partition](../partitions/principe.md) — chaque maillon d'une chaîne doit matcher un slot équipé), la roulette ajoute une couche de spectacle garanti à intervalle prévisible, sans toucher au [pilier de résolution conditionnelle](decisions-tranchees.md).

**Décision structurante, après plusieurs allers-retours** : la roulette et les [cases mystère](#cases-mystère) sont **deux systèmes totalement indépendants**, jamais l'un ne déclenche l'autre. Chacun a sa propre famille d'effets, cognitivement séparée — voir [Ce qui a été écarté](#ce-qui-a-été-écarté) pour l'historique des versions qui les mélangeaient et pourquoi ça ne marchait pas.

## Cases mystère

Codées en session 24 (`MysteryCellEffects`, `GameRules.ROUND_START_MYSTERY_MIN/MAX = 2/4`) : cases "?" posées au début de chaque manche, effet caché révélé quand un jeton atterrit dessus, paliers de rareté Commun/Rare/Jackpot (`MYSTERY_RARITY_RATES = [0.55, 0.40, 0.05]`). **Restent la seule source** — pas d'apport de la roulette, quota resté à 2-4 tel quel depuis session 24.

## La jauge (roulette)

**Ce qui la remplit** — la valeur brute du jeton posé, telle quelle (poser un 9 avance la jauge de 9, un 1 de 1). Choix déterministe, pas un tirage indépendant : la première piste envisagée (tirage aléatoire à chaque drop, façon loterie) posait un problème de lisibilité — impossible pour le joueur de justifier pourquoi un 1 avancerait plus qu'un 9. La valeur imprimée sur le jeton EST la justification, aucun apprentissage requis.

- **Rocks** — ne remplissent rien (poids mort, cohérent avec leur rôle)
- **Spéciaux** — `GameRules.ROULETTE_SPECIAL_GAUGE_VALUE` (forfait fixe, 5), puisqu'ils n'ont pas de valeur numérique porteuse de sens (`TokenData.value` reste à 1 par défaut pour `Kind.SPECIAL`)

**Le seuil : fixe à `GameRules.ROULETTE_THRESHOLD` (21), pour toute la run.** Pas un ratio recalculé par manche (rejeté — amortirait le snowball recherché, voir plus bas). Choisi à dessein pour qu'aucun jeton seul, même un Roi (`FACE_CARD_VALUES` max = 20), ne puisse déclencher la roulette à lui seul — toujours au moins 2 drops. Clin d'œil discret à l'ADN blackjack du projet (pivot de Salt House), jamais dit au joueur.

**Effet recherché, assumé** : un deck de départ (budget total ~72 en valeur cumulée) tourne à 3-4 déclenchements par manche en zone 1. Un deck bien buildé plus tard dans la run (Fusion/Augmenter jusqu'à `MAX_BUTTON_VALUE = 10`, figures jusqu'à Roi = 20) fait sauter le même seuil fixe en une poignée de drops — la roulette spamme. C'est volontaire : le joueur "casse le jeu" avec son propre build, à la Balatro, sans plafond artificiel.

> Calcul du budget de départ : deck de base = 28 boutons (valeurs 1-2 en double copie par famille, 3-5 en simple) + 4 rocks. Somme des valeurs = 8×1 + 8×2 + 4×3 + 4×4 + 4×5 = **72**. Avec un seuil à 21, ça donne ~3-4 tours de roulette en manche 1.

## Le pool de prix — deux familles, rareté = juste le nombre

Après plusieurs tentatives plus larges (voir [Ce qui a été écarté](#ce-qui-a-été-écarté)), le pool est volontairement réduit à **deux familles**, chacune reconnaissable et où la rareté ne change *jamais* la mécanique, seulement son ampleur — inspiré de Raccoin (pièces vs capsules, "la rareté c'est juste le nombre") mais traduit dans le vocabulaire de Deep Rows plutôt que copié tel quel :

| Palier | Taux | Multiplicateur | Frog |
|---|---|---|---|
| Commun | 55% | x1.2 | 1 Frog |
| Rare | 40% | x3 | 2-3 Frogs |
| Légendaire | 5% | x10 (fixe, pas de roll) | 5 Frogs |

Tirage à deux temps (`RouletteRewards`, même principe que `MysteryCellEffects`) : palier tiré au taux fixe, puis 50/50 entre les deux familles à ce palier.

**Multiplicateur** — s'applique uniquement au **prochain drop** après le déclenchement (jamais celui qui déclenche la roulette lui-même — pas de bonus rétroactif). Implémenté via `RunManager.set_global_multiplier(mult, &"roulette")`, activé à la fin du tour de déclenchement (`turn_resolved`) et effacé à la fin du tour suivant. Un vrai wildcard : si le joueur déclenche la roulette juste avant de compléter une grosse figure, le prochain drop qui la complète empoche le x10 ; si le drop suivant ne score rien, le bonus fizzle pour rien. Durée à un seul drop choisie plutôt qu'une fenêtre de plusieurs coups — plus lisible, élimine un axe de tuning (durée par palier) sans perdre le côté explosif.

**Frog** — lâche N exemplaires du spécial [Frog](../jetons/specials.md) (mangeur mobile déjà codé, session 22) en colonnes aléatoires, en sautant les colonnes déjà pleines. Choisi plutôt qu'un pool de spéciaux variés parce que Frog n'a pas besoin d'être ciblé stratégiquement (son propre effet est déjà aléatoire — saute dans une diagonale tirée au hasard à chaque bond), contrairement à une Bombe ou une Enclume qui perdraient tout leur sens lâchées au hasard. Double tranchant assumé : Frog mange ce qu'il traverse (score la valeur brute mais retire le jeton de la grille), donc pas un pur cadeau — cohérent avec l'esprit casino plutôt qu'un bonus toujours positif comme un achat de shop.

**Lien narratif (léger, pas de DA)** — le jeton Frog comme "cadeau des grenouilles orchestre" (elles tiennent déjà le shop, les mouches sont leur monnaie). Justifie pourquoi c'est Frog spécifiquement et pas un autre spécial mobile (Cavalier, Liane) : le lien narratif ne marche qu'avec Frog. Pure justification thématique pour l'instant, aucun travail de DA engagé (cohérent avec la priorité "pas de DA avant validation du fun").

## Ce qui a été écarté

Plusieurs versions intermédiaires ont été conçues puis abandonnées avant d'arriver au pool final — notées pour ne pas les rouvrir sans nouvel angle :

- **Tirage aléatoire pur pour remplir la jauge** — illisible, aucune justification visible pour le joueur
- **Seuil relatif à la valeur du deck de la manche** — corrigeait le snowball recherché, contraire à l'effet voulu
- **Plafonner la contribution d'un drop** — même raison, tuerait le power-fantasy
- **Palier de prix dépendant du dépassement du seuil** — encore une règle/exception en plus, écarté au profit d'un tirage de palier totalement indépendant (comme les cases mystère)
- **Roulette liée à la vitesse de drop (temps réel)** — le jeu n'a aucune mécanique temps réel nulle part ; récompenser la nervosité irait contre l'identité "jeu de stratégie" affirmée cette même session
- **Duo Planter/Récolter (la roulette pose/résout des cases mystère)** — première tentative de faire cohabiter les deux systèmes. Beaucoup d'itérations : nesting confus (une surprise qui en déclenche une autre), puis chevauchement de contenu avec `MysteryCellEffects` (+10% score, +1 mouche dupliqués), puis tentative de règle "grille vs économie du joueur" pour trancher quel effet va où — jamais totalement satisfaisant. **Tranché en session 25 : séparation totale**, aucun pont entre les deux systèmes. Le quota de départ des cases mystère (réduit un temps à 1-2 en pariant sur cet apport) est revenu à 2-4
- **Récolter / Résolution forcée d'une figure clognée** — rejetés par le user ("ça colle pas avec le jeu") : touchent à une case/figure ailleurs sur la grille plutôt qu'à l'action du joueur lui-même, contrairement à tout le reste du pool
- **Pièces/Capsules façon Raccoin (jetons de base + spéciaux ajoutés au stream)** — mapping direct de Raccoin, écarté sur deux points : (1) 4 à 20 jetons en plus par manche perturbe le budget de deck calibré finement (single-pass, no reshuffle) ; (2) ajouter des jetons/spéciaux au stream est invisible/pas spectaculaire (contrairement aux pièces de Raccoin qui scorent instantanément), et dilue/retarde ce que le joueur est en train de construire puisque le stream est fini et ordonné — aucun des deux problèmes n'existe côté Raccoin (deck infini, sans coût d'opportunité)
- **Spéciaux en auto-drop aléatoire sur la grille** — retire l'agency du joueur sur le timing ("le joueur les time — LE bon moment dans LA bonne manche", principe déjà posé pour les Spéciaux), un spécial mal placé se gâche tout seul
- **Rouille (négatif pur), Domino (redondant avec CascadeResolver), Résine (glu figeant la gravité)** — voir [Spéciaux — famille réactive](../jetons/specials.md#spéciaux-réactifs--famille-identifiée-session-25) pour le détail, sans rapport direct avec le pool de la roulette mais écartés dans la même session
- **Accélérer le level up d'une Partition** — jugé trop plat/peu spectaculaire par le user comparé à Multiplicateur/Frog

## Synergies futures (Badges / Boss malus)

Pas conçu en détail, mais l'architecture s'y prête directement — `BossMalusManager` a déjà un précédent exact (Pluie de cailloux injecte `BOSS_MALUS_ROCK_COUNT` rocks via une simple constante `GameRules`). Pistes évoquées, à spécifier le jour venu :

- **Badge positif** — meilleures odds de rareté sur la roulette, seuil abaissé, plus de cases mystère au départ
- **Malus de boss** — l'inverse (seuil relevé, cases mystère réduites)

## Statut d'implémentation

Codé en session 25 : `RouletteManager` (jauge, seuil, tirage palier/famille, multiplicateur différé au prochain drop, lâcher de Frogs), `RouletteRewards` (catalogue), constantes `GameRules.ROULETTE_*`, jauge visible en HUD (`RouletteGauge`/`RouletteGaugeLabel` dans `game.tscn`), animation de défilement (`ResolutionBanner.play_prize_spin_announcement`).

**Note technique** — les nodes ajoutés dans `game.tscn` ont été édités directement en texte (pas d'accès à l'éditeur Godot dans cet environnement pour vérifier visuellement). À ouvrir dans l'éditeur pour confirmer avant de considérer cette tranche testée.

**Deux bugs corrigés au premier playtest, même famille de cause** — poser un jeton sur la grille en dehors du pipeline normal du joueur est plus fragile qu'il n'y paraît :

1. **Blocage complet** — les Frogs posés par `_trigger_roulette` en plein milieu du tour du joueur (avant que son propre pipeline drop/animation/résolution ne soit terminé) entraient en collision avec le système d'animation de la grille (`Tween started with no Tweeners`). Fix initial : mettre les Frogs en attente et les lâcher plus tard plutôt qu'immédiatement.
2. **Frog invisible jusqu'au coup suivant** — même en décalant à `turn_resolved`, le Frog apparaissait sans animation de chute, en "pop" au tour suivant. Cause réelle : `GridManager.place_token` pour un Special n'écrit pas encore dans la grille, il attend `execute_special` (censé arriver **après** la fin de l'animation de chute, via `await drop_animated`) — appeler `execute_special` immédiatement après `place_token` désynchronisait la pose logique de l'animation visuelle. Fix : nouvelle méthode `TurnController.drop_bonus_token(token, col)` qui réutilise le vrai pipeline animé (pose → attendre la chute → effet → attendre son animation), sans consommer l'inventaire de Spéciaux du joueur ni ré-émettre `token_dropped` (sinon le cadeau rechargerait sa propre jauge). Et le déclenchement lui-même a été déplacé de `turn_resolved` à `awaiting_input` — le premier sort *avant* que `TurnController` ait fini de repasser en `AWAITING_INPUT`, laissant encore une fenêtre de course.

Leçon générale : tout ce qui pose un jeton sur la grille en dehors d'un vrai coup joueur doit repasser par le pipeline animé de `TurnController`, jamais appeler `GridManager` directement.

**Séquencement popup → Frog** — le lâcher de Frogs attend maintenant deux conditions indépendantes avant de se déclencher (`RouletteManager._maybe_drop_frogs`) : le tour qui a déclenché la roulette doit être réellement terminé (`awaiting_input`) ET l'annonce visuelle (`play_prize_spin_announcement`) doit avoir fini de jouer (`notify_banner_done`, appelé par `GameScene` une fois l'animation terminée) — sinon le popup et la chute du Frog se chevauchent. Les deux peuvent arriver dans n'importe quel ordre.

**Indicateur du multiplicateur en attente** — `RouletteMultiLabel` (HUD, sous la jauge) s'affiche et pulse en boucle ("heartbeat", `Tween.set_loops`) tant que le multiplicateur est actif (prêt pour le prochain drop), disparaît dès que ce drop s'est résolu — qu'il ait scoré ou non. Le joueur voit donc explicitement quand le bonus retombe à plat plutôt que de deviner en silence. Câblé via un nouveau signal `RouletteManager.multi_status_changed(active, value)`.

Reste à faire : passe UI/juice (voir [Questions ouvertes](../meta/questions-ouvertes.md)), les synergies Badges/Boss malus, calibrage des chiffres au playtest.

## Liens

- [Décisions tranchées](decisions-tranchees.md)
- [Spéciaux — famille réactive](../jetons/specials.md#spéciaux-réactifs--famille-identifiée-session-25)
- [Dernier Souffle](dernier-souffle.md)
- [Rocks](../jetons/rocks.md)
