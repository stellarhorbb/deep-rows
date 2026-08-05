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
- **Si ça corrompt** : swap, pas destruction — un skull tombe à la place du jeton visé, mais celui-ci n'est **jamais consommé** : il reste en tête de stream pour retenter au prochain tour. Coût réel = le tour, pas le jeton.
- **Si ça passe** : récompense ciblée sur CE jeton précis (jamais un jeton aléatoire ailleurs — défaut identifié de l'ancienne roulette), tirée à deux temps comme avant : palier (Commun/Rare/Légendaire) puis famille (Multiplicateur/Boost), voir `CursedColumnRewards`.
  - **Multiplicateur** — s'applique aux `GameRules.CURSED_COLUMN_MULTI_DROPS` (3) prochains drops qui scorent, jamais celui qui déclenche.
  - **Boost** — mute directement la valeur du jeton dropé, plafonnée à `MAX_BUTTON_VALUE`, appliqué **avant** résolution de cascade (peut donc compléter/upgrader un pattern sur ce même tour).

**Contrepoids risque/récompense (retour user, session 27)** : sans lui, une colonne à haut risque n'offre aucune contrepartie et devient juste une case à fuir. Le palier Légendaire scale avec le risque affiché — multiplicatif, ×1 à risque nul jusqu'à `GameRules.CURSED_COLUMN_JACKPOT_MULTIPLIER_MAX` (×4) à 100%. **Affiché en conditionnel** ("si ça passe : X% bonus, Y% jackpot"), jamais en absolu — un bug trouvé en playtest montrait un jackpot absolu qui chutait mécaniquement vers 0 à haut risque (moins d'espace de récompense total quand le risque de skull grandit), donnant l'impression fausse que le risque payait moins alors que le tirage réel scalait bien. Le tooltip au survol du % (`GridHoverUI`, réutilise le système de tooltip natif déjà en place pour les jetons) affiche le détail Skull/Bonus/Jackpot.

**Compteur de dread partagé** entre les deux couches — un skull qui apparaît, peu importe la source, calme la pression pour un moment (reset de `_turns_since_corruption`).

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

Reste ouvert : calibrage au playtest prolongé de `CURSED_COLUMN_SKULL_BONUS` (0.30) et `CURSED_COLUMN_JACKPOT_MULTIPLIER_MAX` (×4), posés sur un premier jet de raisonnement plutôt que des données de jeu étendues.

## Liens

- [Décisions tranchées](../meta/decisions-tranchees.md)
- [Brainstorm — remettre en question le geste central](../../brainstorms/brainstorm-geste-central.md)
- [Cases mystère](../grille/trous.md)
- [Dernier Souffle](dernier-souffle.md)
- [Rocks](../jetons/rocks.md)
