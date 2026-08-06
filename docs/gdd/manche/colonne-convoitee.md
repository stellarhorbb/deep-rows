# Colonne Convoitée — corruption ambiante et pari sur le geste

Remplace l'axe casino "roulette" (session 25) et le skull ambiant "classique" (session 26) — refondus en session 27 après un diagnostic de session 27 (voir [Brainstorm — remettre en question le geste central](../../brainstorms/brainstorm-geste-central.md)) : la roulette (jauge/seuil/Multiplicateur-Boost) et le skull (chance croissante, colonne aléatoire indépendante du joueur) étaient deux systèmes **parallèles** que le joueur devait suivre en tête, en plus de la grille elle-même. Objectif du redesign : un seul mécanisme, greffé directement sur le geste de drop plutôt qu'à côté.

**Décision structurante, héritée de la roulette (session 25)** : la Colonne Convoitée et les [cases mystère](#cases-mystère-et-désamorçage) restent deux systèmes indépendants, aucun ne déclenche l'autre — sauf sur un point précis, le désamorçage (voir plus bas).

## Deux couches bien séparées

Un skull peut apparaître par deux voies distinctes, avec des règles différentes :

### Corruption ambiante — menace de fond, subie

Chance croissante et **cachée**, formule identique à l'ancien skull d'avant session 27 (`GameRules.ENTITY_DROP_BASE_CHANCE` 5% + `ENTITY_DROP_INCREMENT` 5% par tour depuis le dernier skull, plafond naturel à 100%). Roulée une fois par tour **après résolution** (`EntityManager.on_turn_resolved`, appelé depuis `GameScene._on_turn_resolved`), totalement indépendante de la colonne où le joueur vient de jouer — retombe sur une colonne aléatoire non pleine, exactement comme avant la refonte.

**Pourquoi séparée du geste** : un premier jet (session 27) roulait cette chance sur le drop du joueur lui-même, dans SA colonne — retour direct en playtest : "le skull tombe toujours pile où je construis, c'est trop punitif". Contrairement à la Colonne Convoitée (pari choisi), l'ambiant est subi — il doit garder la variance d'un vrai hasard de position, pas cibler systématiquement le pire endroit.

### Colonne Convoitée — pari délibéré et visible

Une colonne signalée (overlay rouge sur `GridVisual`), re-tirée à **chaque tour** (`EntityManager.reroll_cursed_column`, même timing que le malus de boss COLONNE MAUDITE — nom volontairement distinct pour ne pas entrer en collision : l'un bloque, l'autre incite) — empêche un joueur prudent de simplement l'ignorer indéfiniment sur la même case.

Droper là est un choix informé :
- **Risque affiché** : `ambiant du moment + GameRules.CURSED_COLUMN_SKULL_BONUS` (0.30), jamais un taux fixe indépendant — sinon un ambiant déjà monté haut dépasserait le risque affiché comme "élevé". Au niveau de base (ambiant 5%), ça retombe sur 35%.
- **Si ça corrompt** : le jeton visé est **consommé** (retune session 28, retour user) — un skull tombe à sa place, le jeton disparaît sans avoir scoré pour cette manche. Pas de retry au tour suivant (l'ancien swap-sans-perte diluait le risque : "pas grave, je tente ailleurs"). Pas perdu pour la run pour autant : `TurnController.play_current_to` appelle `DeckManager.consume_current()`, qui ne touche que le stream de la manche en cours, jamais le pool possédé (`RunManager._button_pool`) — le jeton réapparaît normalement au deck de la manche suivante, comme n'importe quel jeton non joué.
- **Si ça passe** : récompense ciblée sur CE jeton précis (jamais un jeton aléatoire ailleurs — défaut identifié de l'ancienne roulette), tirée à deux temps comme avant : palier (Commun/Rare/Légendaire) puis famille (Multiplicateur/Boost), voir `CursedColumnRewards`.
  - **Multiplicateur** — s'applique aux `GameRules.CURSED_COLUMN_MULTI_DROPS` (3) prochains drops qui scorent, jamais celui qui déclenche.
  - **Boost** — mute directement la valeur du jeton dropé, appliqué **avant** résolution de cascade (peut donc compléter/upgrader un pattern sur ce même tour). Commun/Rare restent additifs et plats (`GameRules.CURSED_COLUMN_BOOST_VALUES`, +1/+2), mais le Légendaire est **multiplicatif** depuis la session 28 (`GameRules.CURSED_COLUMN_JACKPOT_VALUE_MULTIPLIER`, ×2) plutôt qu'un ancien +10 plat qui fixait n'importe quel jeton pile à `MAX_BUTTON_VALUE` (10). L'ancien +10 profitait toujours plus (en relatif) à un jeton pourri qu'à un bon — le ×2 rend le risque proportionnel à l'enjeu : un "5" qui double tombe pile sur 10 (le vrai sweet spot), doubler un "1" reste volontairement fade. Voir `CursedColumnRewards.boosted_value`, plafonné à `MAX_BUTTON_VALUE` dans tous les cas.

**Contrepoids risque/récompense (retour user, session 27)** : sans lui, une colonne à haut risque n'offre aucune contrepartie et devient juste une case à fuir. Le palier Légendaire scale avec le risque affiché — multiplicatif, ×1 à risque nul jusqu'à `GameRules.CURSED_COLUMN_JACKPOT_MULTIPLIER_MAX` (×4) à 100%. Ce taux Légendaire reste calculé en interne comme un conditionnel ("si le drop passe", voir `CursedColumnRewards.legendary_rate`), pour que le signal "plus de risque = jackpot bien plus probable en cas de réussite" reste correct dans les données.

**Affichage — retour user, session 28** : deux essais avant de se fixer. Le tout-indépendant (Skull/Bonus/Jackpot en % absolus sommant à 100%) a été testé puis abandonné : il rendait le Jackpot mécaniquement décroissant à mesure que le skull grimpe (le skull mange une part croissante du pool), ce qui va à l'encontre du but recherché — donner envie de tenter la CC *justement* quand le risque est élevé. Le tooltip (`GridHoverUI`) reste donc conditionnel comme à l'origine, mais reformaté en bloc plutôt qu'en phrase "si ça passe" pour rester lisible à la volée : `Skull : X%` sur sa propre ligne, puis `Drop réussi → Bonus Y%, Jackpot Z%`. Le taux interne (`CursedColumnRewards`) n'a jamais changé au fil de ces essais, seul l'affichage a bougé.

**Compteur de dread partagé** entre les deux couches — un skull qui apparaît, peu importe la source, calme la pression pour un moment (reset de `_turns_since_corruption`).

### Sortilèges dédiés (session 28)

Quatre Sortilèges scopés exclusivement à ce système, ajoutés une fois la corruption retravaillée pour vraiment coûter un jeton :

- **Renaissance** (Rare) — 1 jeton corrompu sur 3 revient à une place aléatoire du stream de la manche en cours (`DeckManager.insert_random`) au lieu d'attendre la manche suivante.
- **Consolation** (Uncommon) — +2 mouches à chaque corruption, compense la perte sans l'annuler.
- **Adjacence Sombre** (Rare) — +20% de score, mais LOCAL (pas un `global_multiplier`) : par skull adjacent orthogonalement à la Partition qui score, même canal que l'Amplificateur (`grid_mult`).
- **Accoutumance** (Rare) — le risque affiché/réel baisse de 3% par skull actuellement présent sur la grille (`GridManager.count_entity_skulls`, branché dans `EntityManager._cursed_column_chance`) — plus le chaos s'accumule, plus les prochains paris redeviennent sûrs.

Brainstorm : un premier jet générique (multiplicateur global +10%/skull, "Emprise") a été écarté car déconnecté du placement — préféré une version locale liée à l'adjacence, plus proche de l'identité "puzzle de placement" du jeu.

## Cases mystère et désamorçage

Un skull qui atterrit sur une case mystère non révélée la **désamorce** plutôt que de la déclencher (`GridManager._check_mystery_trigger`, branche `Kind.ENTITY`) — évite qu'une corruption distribue accidentellement un bonus, cohérent avec le principe "systèmes indépendants". La case est consommée, l'effet n'est jamais appliqué, une annonce dédiée révèle ce qui a été raté ("CASE DÉSAMORCÉE — C'était : X") — donne du poids à la perte sans info exploitable puisque c'est déjà trop tard pour agir dessus. Voir [Cases mystère](../grille/trous.md) (catalogue recentré la même session, effets grille/jeton plutôt qu'économiques).

## Ce qui a été écarté

Historique conservé de la roulette (session 25) pour ne pas relitiger sans nouvel angle :

- **Tirage aléatoire pur pour remplir une jauge** — illisible, aucune justification visible.
- **Seuil relatif à la valeur du deck** — amortirait le snowball recherché.
- **Roulette liée à la vitesse de drop (temps réel)** — contraire à l'identité "jeu de stratégie".
- **Duo Planter/Récolter (roulette et cases mystère pontées)** — plusieurs tentatives, jamais de règle de tri satisfaisante. Tranché : séparation totale (le désamorçage de cette session reste asymétrique, pas un vrai pont).
- **Pièces/Capsules façon Raccoin, Frog en prix** — Frog cassait trop souvent des Partitions en cours de construction, remplacé par Boost dès session 25.
- **Boost ciblant un jeton aléatoire de la grille** — défaut corrigé en session 27 : cible désormais toujours le jeton dropé dans la Colonne Convoitée.

## Statut d'implémentation

Codé en session 27 : `EntityManager` (corruption ambiante + Colonne Convoitée, remplace `RouletteManager` et l'ancien `on_turn_resolved` skull-ailleurs), `CursedColumnRewards` (catalogue, remplace `RouletteRewards`), constantes `GameRules.CURSED_COLUMN_*`/`ENTITY_DROP_*`, overlay + tooltip dans `GridVisual`/`GridHoverUI`.

Retuné en session 28 : la corruption consomme désormais vraiment le jeton visé (plus de swap-sans-perte) et le Boost Légendaire devient multiplicatif (×2) au lieu d'un +10 plat — voir ci-dessus. L'annonce de récompense est aussi passée d'un double défilement type roulette à un affichage direct (retour user : "trop long"), `JACKPOT` en titre uniquement sur le palier Légendaire.

Reste ouvert : calibrage au playtest prolongé de `CURSED_COLUMN_SKULL_BONUS` (0.30) — potentiellement à revoir maintenant que la corruption coûte vraiment un jeton (avant session 28 elle ne coûtait qu'un tour), mais pas de décision a priori, à recalibrer avec de vraies données de run plutôt qu'à l'instinct.

## Liens

- [Décisions tranchées](../meta/decisions-tranchees.md)
- [Brainstorm — remettre en question le geste central](../../brainstorms/brainstorm-geste-central.md)
- [Cases mystère](../grille/trous.md)
- [Dernier Souffle](dernier-souffle.md)
- [Rocks](../jetons/rocks.md)
