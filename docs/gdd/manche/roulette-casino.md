# Axe casino — Jauge, roulette et cases mystère

Système conçu et implémenté en session 25. Né d'une comparaison avec Raccoin (coin-pusher roguelite) : là où les cascades de Deep Rows restent structurellement rares (gating par [Partition](../partitions/principe.md) — chaque maillon d'une chaîne doit matcher un slot équipé), la roulette ajoute une couche de spectacle garanti à intervalle prévisible, sans toucher au [pilier de résolution conditionnelle](decisions-tranchees.md).

**Décision structurante, après plusieurs allers-retours** : la roulette et les [cases mystère](#cases-mystère) sont **deux systèmes totalement indépendants**, jamais l'un ne déclenche l'autre. Chacun a sa propre famille d'effets, cognitivement séparée — voir [Ce qui a été écarté](#ce-qui-a-été-écarté) pour l'historique des versions qui les mélangeaient et pourquoi ça ne marchait pas.

## Cases mystère

Codées en session 24 (`MysteryCellEffects`, `GameRules.ROUND_START_MYSTERY_MIN/MAX = 2/4`) : cases "?" posées au début de chaque manche, effet caché révélé quand un jeton atterrit dessus, paliers de rareté Commun/Rare/Jackpot (`MYSTERY_RARITY_RATES = [0.55, 0.40, 0.05]`). **Restent la seule source** — pas d'apport de la roulette, quota resté à 2-4 tel quel depuis session 24.

## La jauge (roulette)

**Ce qui la remplit** — la valeur brute du jeton posé, telle quelle (poser un 9 avance la jauge de 9, un 1 de 1). Choix déterministe, pas un tirage indépendant : la première piste envisagée (tirage aléatoire à chaque drop, façon loterie) posait un problème de lisibilité — impossible pour le joueur de justifier pourquoi un 1 avancerait plus qu'un 9. La valeur imprimée sur le jeton EST la justification, aucun apprentissage requis.

- **Rocks** — ne remplissent rien (poids mort, cohérent avec leur rôle)
- **Spéciaux** — ne remplissent rien non plus (retune session 25). Avaient un forfait fixe à l'origine (`ROULETTE_SPECIAL_GAUGE_VALUE`, 5) quand ils étaient encore piochés dans le stream comme n'importe quel jeton ; retiré une fois les spéciaux passés en [inventaire possédé joué à la demande](../jetons/specials.md) — un forfait aurait permis de remplir la jauge gratuitement en jouant des outils "sans valeur" qui, en plus, ne consomment même pas de tour de stream

**Le seuil : fixe à `GameRules.ROULETTE_THRESHOLD` (21).** Pas un ratio recalculé par manche (rejeté — amortirait le snowball recherché, voir plus bas). Choisi à dessein pour qu'aucun jeton seul, même un Roi (`FACE_CARD_VALUES` max = 20), ne puisse déclencher la roulette à lui seul — toujours au moins 2 drops. Clin d'œil discret à l'ADN blackjack du projet (pivot de Salt House), jamais dit au joueur.

**Retune session 25 (playtest)** : la jauge (la progression accumulée) se remet à zéro au début de chaque manche (`RouletteManager.bind_round`), plutôt que de courir sur toute la run comme prévu initialement — revient sur la décision d'origine ("seuil fixe pour toute la run", encore vraie pour la *valeur* du seuil elle-même, qui elle ne change toujours pas). Le snowball recherché (un bon build fait spammer la roulette en fin de run) reste intact : chaque manche repart de zéro, mais un deck buildé continue de la remplir en une poignée de drops à l'intérieur de cette même manche.

**Effet recherché, assumé** : un deck de départ (budget total ~72 en valeur cumulée) tourne à 3-4 déclenchements par manche en zone 1. Un deck bien buildé plus tard dans la run (Fusion/Augmenter jusqu'à `MAX_BUTTON_VALUE = 10`, figures jusqu'à Roi = 20) fait sauter le même seuil fixe en une poignée de drops — la roulette spamme. C'est volontaire : le joueur "casse le jeu" avec son propre build, à la Balatro, sans plafond artificiel.

> Calcul du budget de départ : deck de base = 28 boutons (valeurs 1-2 en double copie par famille, 3-5 en simple) + 4 rocks. Somme des valeurs = 8×1 + 8×2 + 4×3 + 4×4 + 4×5 = **72**. Avec un seuil à 21, ça donne ~3-4 tours de roulette en manche 1.

## Le pool de prix — deux familles, rareté = juste le nombre

Après plusieurs tentatives plus larges (voir [Ce qui a été écarté](#ce-qui-a-été-écarté)), le pool est volontairement réduit à **deux familles**, chacune reconnaissable et où la rareté ne change *jamais* la mécanique, seulement son ampleur — inspiré de Raccoin (pièces vs capsules, "la rareté c'est juste le nombre") mais traduit dans le vocabulaire de Deep Rows plutôt que copié tel quel :

| Palier | Taux | Multiplicateur | Boost |
|---|---|---|---|
| Commun | 55% | x1.2 | +1 |
| Rare | 40% | x3 | +3 |
| Légendaire | 5% | x10 (fixe, pas de roll) | +10 (revient à fixer la valeur pile à 10) |

Tirage à deux temps (`RouletteRewards`, même principe que `MysteryCellEffects`) : palier tiré au taux fixe, puis 50/50 entre les deux familles à ce palier.

**Multiplicateur** — s'applique au premier des **`GameRules.ROULETTE_MULTI_DROPS` (3) prochains drops** qui score effectivement quelque chose, après le déclenchement (jamais celui qui déclenche la roulette lui-même — pas de bonus rétroactif). `GameRules.ROULETTE_MULTI_DROPS` est un **délai maximum**, pas une durée garantie : dès qu'un tour scoré en profite, le multiplicateur s'efface immédiatement (pas de deuxième ou troisième coup gratuit en plus) ; sinon il décompte normalement et expire au bout de 3 tours sans score. Implémenté via `RunManager.set_global_multiplier(mult, &"roulette")`, activé à la fin du tour de déclenchement (`turn_resolved`). Un vrai wildcard : si le joueur déclenche la roulette juste avant de compléter une grosse figure, le prochain drop qui la complète empoche le x10 et le bonus s'arrête là ; si les 3 drops suivants ne scorent rien, le bonus fizzle pour rien. **Retune session 25** : un seul drop de couverture était le choix initial (plus lisible, élimine un axe de tuning) mais s'est révélé "trop chaud à caler" au playtest — remonté à 3 comme fenêtre de timing, avec annulation immédiate à la première utilisation pour ne pas transformer un coup de chance en 3 coups gratuits d'affilée.

**Boost** (remplace Frog, voir [Ce qui a été écarté](#ce-qui-a-été-écarté)) — augmente de façon **permanente** la valeur d'**UN** bouton de base pris au hasard dans le pool possédé (`RunManager.boost_random_button`), plafonnée à `MAX_BUTTON_VALUE` (10) — les figures restent exclusivement accessibles par le score réel, jamais offertes gratuitement. En parallèle, un jeton de base pris au hasard **sur la grille** reçoit le même highlight visuel immédiat (`GridManager.boost_random_token` + `GridVisual.animate_boost`, même langage que `_animate_upgrade`) — tirage indépendant, purement cosmétique/immédiat pour ce tour, l'effet qui compte pour la suite de la run est celui sur le pool. Ne retire, ne déplace, ne touche jamais à rien d'autre : zéro risque pour une Partition en cours de construction, contrairement à Frog. L'ampleur (pas le nombre — toujours 1 jeton) varie par palier, même forme que `ROULETTE_MULTI_VALUES` pour rester cohérent visuellement dans le pool.

**Bug corrigé (même session)** — la toute première implémentation ne touchait que la copie de grille (éphémère, recréée par `DeckManager.build_deck` à chaque manche), donc l'effet ne survivait jamais à la fin de la manche, qu'il ait scoré ou non — contraire à sa raison d'être ("scale avec la run", voir plus bas). Signalé en playtest par le user ("je l'ai scoré donc il est passé en J, mais je ne le vois plus dans mon deck sur la manche d'après").

Bonus non cherché mais bienvenu : comme la jauge se remplit sur la valeur brute des jetons posés, booster un jeton fait remplir la jauge plus vite à son prochain passage — une petite boucle de rétroaction économique, complémentaire à l'explosion de score que porte Multiplicateur.

**Lien narratif (léger, pas de DA)** — abandonné avec Frog. Rien de spécifique encore trouvé pour Boost ; pas bloquant (cohérent avec la priorité "pas de DA avant validation du fun").

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
- **Frog** (deuxième famille du pool, remplacée par Boost après plusieurs manches jouées) — lâchait N exemplaires du spécial [Frog](../jetons/specials.md) en colonnes aléatoires. Choisi initialement parce que Frog n'a pas besoin d'être ciblé stratégiquement (son propre effet est déjà aléatoire), contrairement à une Bombe/Enclume. Justifié narrativement comme "cadeau des grenouilles orchestre" (shop + mouches = leur monnaie). **Écarté après retour de playtest prolongé** : Frog mange ce qu'il traverse, et "casse souvent la grille qu'on a mis plusieurs drops à préparer" pour une Partition — le double tranchant assumé au départ s'est révélé trop pénalisant en pratique, pas juste un wildcard occasionnel. Piste de repli envisagée (limiter Frog à 1 seule bouchée) jugée insuffisante — le risque existe dès la première morsure, pas seulement en cumulé. Remplacé par Boost, voir plus haut
- **Résoudre des jetons "isolés"** — étape intermédiaire avant Boost : faire scorer directement quelques jetons choisis pour leur faible connexion au reste de la grille. Deux définitions tentées, deux échecs différents : (1) isolement par famille seule — angle mort réel, une Partition à base de valeur (Suite/Fibonacci/Minima/Maxima/Prime, confinées à la forme Ligne) peut avoir besoin d'un jeton sans voisin de même famille ; (2) isolement total (zéro voisin dans les 8 cases, toutes familles confondues) — sûr à 100% mais quasi inexistant en fin de manche, pile quand la roulette se déclenche le plus. Abandonné pour Boost, qui ne retire jamais rien donc n'a pas ce problème de définition
- **Sommer la valeur de N jetons piochés sans les retirer** — étape suivante avant Boost, séduisante (zéro risque, scale avec la progression des valeurs) mais recalculée avec les vrais chiffres : en manche 20 (cible ~3000), même avec des jetons à forte valeur, la somme reste anecdotique (~2,5% de la cible) comparée à son impact en manche 1 (~25%) — les valeurs de jetons plafonnent trop bas (20 max) face à l'explosion du score via les multiplicateurs. Palliatif envisagé (appliquer `ROULETTE_MULTI_VALUES` en multiplicateur sur la somme) rejeté : ça fait empiéter la logique de Multi sur l'autre moitié du pool. Résolu autrement avec Boost — augmenter la valeur d'un jeton en place scale naturellement puisque les valeurs de jetons grossissent tout du long de la run, sans avoir besoin d'un multiplicateur en plus

## Synergies futures (Sortilèges / Boss malus)

Pas conçu en détail, mais l'architecture s'y prête directement — `BossMalusManager` a déjà un précédent exact (Pluie de cailloux injecte `BOSS_MALUS_ROCK_COUNT` rocks via une simple constante `GameRules`). Pistes évoquées, à spécifier le jour venu :

- **Sortilège positif** — meilleures odds de rareté sur la roulette, seuil abaissé, plus de cases mystère au départ
- **Malus de boss** — l'inverse (seuil relevé, cases mystère réduites)

## Statut d'implémentation

Codé en session 25 : `RouletteManager` (jauge, seuil, tirage palier/famille, multiplicateur différé au prochain drop, Boost de jeton), `RouletteRewards` (catalogue), constantes `GameRules.ROULETTE_*`, jauge visible en HUD (`RouletteGauge`/`RouletteGaugeLabel` dans `game.tscn`), animation de défilement (`ResolutionBanner.play_prize_spin_announcement`).

**Note technique** — les nodes ajoutés dans `game.tscn` ont été édités directement en texte (pas d'accès à l'éditeur Godot dans cet environnement pour vérifier visuellement). À ouvrir dans l'éditeur pour confirmer avant de considérer cette tranche testée.

**Deux bugs corrigés au premier playtest, même famille de cause** — poser un jeton sur la grille en dehors du pipeline normal du joueur est plus fragile qu'il n'y paraît :

1. **Blocage complet** — les Frogs posés par `_trigger_roulette` en plein milieu du tour du joueur (avant que son propre pipeline drop/animation/résolution ne soit terminé) entraient en collision avec le système d'animation de la grille (`Tween started with no Tweeners`). Fix initial : mettre les Frogs en attente et les lâcher plus tard plutôt qu'immédiatement.
2. **Frog invisible jusqu'au coup suivant** — même en décalant à `turn_resolved`, le Frog apparaissait sans animation de chute, en "pop" au tour suivant. Cause réelle : `GridManager.place_token` pour un Special n'écrit pas encore dans la grille, il attend `execute_special` (censé arriver **après** la fin de l'animation de chute, via `await drop_animated`) — appeler `execute_special` immédiatement après `place_token` désynchronisait la pose logique de l'animation visuelle. Fix : nouvelle méthode `TurnController.drop_bonus_token(token, col)` qui réutilise le vrai pipeline animé (pose → attendre la chute → effet → attendre son animation), sans consommer l'inventaire de Spéciaux du joueur ni ré-émettre `token_dropped` (sinon le cadeau rechargerait sa propre jauge). Et le déclenchement lui-même a été déplacé de `turn_resolved` à `awaiting_input` — le premier sort *avant* que `TurnController` ait fini de repasser en `AWAITING_INPUT`, laissant encore une fenêtre de course.

Leçon générale : tout ce qui pose un jeton sur la grille en dehors d'un vrai coup joueur doit repasser par le pipeline animé de `TurnController`, jamais appeler `GridManager` directement.

**Troisième bug trouvé au playtest, pas dans `RouletteManager` cette fois** — freeze après un score normal (Small T) une fois plusieurs Frogs déjà vivants sur la grille. Cause : plusieurs fonctions d'animation dans `GridVisual` (`_animate_match` shake, `_animate_gravity`, `_animate_upgrade`, `_animate_remove`) créent un `Tween` sans condition puis n'y ajoutent des `tween_property` QUE pour les cases qui ont encore un sprite à ce moment précis — si un Frog a mangé/déplacé un jeton entre-temps, une case scorée peut se retrouver sans sprite, et le Tween reste vide (`Tween started with no Tweeners`, même crash que le premier bug). Fix : les 4 fonctions filtrent maintenant les cases valides avant de créer le Tween, et le sautent proprement si aucune ne l'est. Bug préexistant dans le code de base, jamais déclenché avant parce qu'avoir plusieurs specials mobiles vivants en même temps était rarissime en jeu normal — la roulette (5 Frogs d'un coup au palier Légendaire) l'a rendu courant.

**Séquencement popup → Boost** — l'application du Boost attend deux conditions indépendantes (`RouletteManager._maybe_apply_boost`) : le tour qui a déclenché la roulette doit être réellement terminé (`awaiting_input`) ET l'annonce visuelle (`play_prize_spin_announcement`) doit avoir fini de jouer (`notify_banner_done`) — sinon le popup et le highlight du jeton boosté se chevauchent. Les deux peuvent arriver dans n'importe quel ordre. Hérité du même principe que Frog avant lui, même si Boost lui-même (une simple mutation de valeur) n'a pas le risque de collision d'animation qui affectait Frog — gardé pour que le highlight reste lisible plutôt que noyé dans l'animation du tour en cours.

**Ordre d'affichage fixe : mystère → score → roulette (session 25)** — signalé en playtest : l'annonce de la roulette pouvait s'afficher AVANT le score d'un drop qui déclenche les deux à la fois (case mystère + gros score de Partition + roulette, tout sur le même drop). Ça donnait une fausse impression de lien causal — "je viens de gagner ce Multi" — alors que le Multi/Boost ne profite jamais au drop qui déclenche la roulette (voir plus haut, "pas de bonus rétroactif"). Fix : `GameScene._on_roulette_triggered` ne joue plus l'annonce immédiatement (le signal arrive tôt, avant même l'animation de chute) — le résultat est mis en attente (`_pending_roulette_announcement`) et affiché par `_on_turn_resolved`, juste après que le score du drop ait fini de s'afficher. Les cases mystère n'ont pas eu besoin du même traitement : leur résolution est déjà synchrone au moment du drop, donc déjà réglée avant que le score n'apparaisse. Effet de bord assumé : le popup de la roulette bloque désormais la main du joueur jusqu'à sa fin (il ne pouvait pas jouer pendant, avant non plus, mais rien ne l'empêchait explicitement) — cohérent avec l'objectif d'un ordre stable, pas de deuxième drop qui viendrait mélanger sa propre séquence d'annonces avec celle en cours.

**Boost remplace Frog** — voir [Ce qui a été écarté](#ce-qui-a-été-écarté) pour l'historique complet (Frog cassait trop souvent des Partitions en cours de construction) et les deux pistes intermédiaires tentées avant d'arriver à Boost (jetons isolés, somme de valeurs piochées).

**Indicateur du multiplicateur en attente** — `RouletteMultiLabel` (HUD, sous la jauge) s'affiche et pulse en boucle ("heartbeat", `Tween.set_loops`) tant que le multiplicateur est actif (prêt pour le prochain drop), disparaît dès que ce drop s'est résolu — qu'il ait scoré ou non. Le joueur voit donc explicitement quand le bonus retombe à plat plutôt que de deviner en silence. Câblé via un nouveau signal `RouletteManager.multi_status_changed(active, value)`.

Reste à faire : passe UI/juice (voir [Questions ouvertes](../meta/questions-ouvertes.md)), les synergies Sortilèges/Boss malus, calibrage des chiffres au playtest.

## Liens

- [Décisions tranchées](decisions-tranchees.md)
- [Spéciaux — famille réactive](../jetons/specials.md#spéciaux-réactifs--famille-identifiée-session-25)
- [Dernier Souffle](dernier-souffle.md)
- [Rocks](../jetons/rocks.md)
