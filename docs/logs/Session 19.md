# Session 19 — Nettoyage GDD, rééquilibrages, et refonte du démarrage de run

**Date** : 2026-07-17
**Thème** : Session en deux temps. D'abord un passage de nettoyage complet du GDD (resynchronisation avec le code après plusieurs sessions denses), suivi d'une série de petits fixes/rééquilibrages au fil du playtest. Finit par un gros chantier de design purement conversationnel : repenser le démarrage de run de fond en comble, de "ça sent le proto" à un vrai système de packs de démarrage déterministes.

---

## Nettoyage global du GDD

Demande du user : trier, mettre à jour, synchroniser avec le code réel, retirer l'obsolète. Passage chapitre par chapitre (Univers → Grille → Jetons → Partitions → Manche → Badges → Shop → Progression → Shore → Meta), 22 fichiers touchés. Points notables trouvés :

- Un bug de doc identique à un vrai bug de code de session 18 (cumul des modificateurs de cellule) répété deux fois dans le GDD
- Le refactor `RunContext` de session 18 jamais documenté
- Tous les chiffres de prix/mouches périmés après les retunes de session 18 (`REROLL_BASE_PRICE`, `BUTTON_UNIT_PRICE`, `FLIES_PER_ROUND_WON`, prix des packs)
- "12 manches", score cible linéaire, "3 manches/zone" encore présents partout malgré la refonte session 18 (20 manches, courbe exponentielle)
- L'inspecteur de deck marqué "pas encore implémenté" alors qu'il est en jeu
- Contenants de shop thématiques (Bocal/Malle/Recueil) présentés comme actuels à plusieurs endroits, alors que la décision (contenant générique) date de la session 12

`questions-ouvertes.md` et `decisions-tranchees.md` synchronisés (items tranchés retirés, décisions manquantes ajoutées). Committé séparément en cours de session (`docs: nettoyage global du GDD`).

## Fix — inspecteur de deck

`DeckManager.get_remaining_tokens()` ne comptait que la pioche restante, oubliant le jeton courant et les jetons en hold — sous-comptait ce qu'il restait réellement à jouer. Corrigé, et la doc de `inspecteur-deck.md` remise à jour au passage (elle disait encore "pas implémenté"). Committé séparément (`fix: inspecteur de deck inclut le jeton courant et le hold`).

## Badges Tickets — bonus par jeton plutôt que par pattern

Discussion partie d'une remarque du user : les 4 Badges "Tickets" (Hivernal/Automnal/Estival/Printanier) ne se déclenchaient qu'une fois par pattern de rule `family` de la bonne famille — mort sur tout l'axe casino (Suite, Brelan, Rainbow...). Passés à +2 par jeton de la famille qui score, peu importe le pattern (`CascadeResolver._value_sum_bonus` boucle maintenant par jeton comme le retrigger, au lieu de checker `group.match_rule`). Descendus de +5 à +2 pour compenser le fait qu'un gros pattern (Ring) peut maintenant en cumuler plusieurs.

## Fix — seuil mouches confortables

`GameRules.get_round_end_flies_bonus` utilisait `>` strict sur `FLIES_BONUS_REMAINING_THRESHOLD` (10) — exactement 10 jetons restants ne déclenchait pas le bonus. Passé à `>=`.

## Outils de deck — Changer de famille à 2 cibles, rééquilibrage rareté

Suite à une discussion sur l'intérêt de recolorer 2 jetons plutôt qu'1 pour mieux ouvrir les builds mono-famille : `DeckToolData.target_count()` étend le multi-cible (déjà utilisé par Fusionner) à Changer de famille. Rééquilibrage complet de la rareté des 10 actions du Dés à coudre en synchro avec la feuille `deck-control` de la Google Sheet (trouvée cette session — un onglet qui existait déjà mais jamais surfacé) :

| Action | Avant | Après |
|---|---|---|
| Changer de famille (×4) | Common, 1 cible | **Uncommon, 2 cibles** |
| Fusionner | Uncommon | **Rare** |
| Fixer | Rare | **Uncommon** |
| Suppression | Rare | **Epic** (premier outil à occuper ce tier) |

## Fibonacci étendu, 3 nouvelles Partitions, suppression de la rareté des Partitions

Trois sujets distincts mais qui se sont enchaînés dans la même conversation :

**Fibonacci** — passe d'une cible fixe (1,1,2,3) à n'importe quelle fenêtre de 4 valeurs consécutives dans la suite étendue 1,1,2,3,5,8. `PatternMatcher` généralisé (`_sequence_windows`/`_find_sequence_matches`, partagé avec la nouvelle Partition Prime).

**3 nouvelles Partitions casino** — constat du user : 17 Partitions actives se sentaient courtes pour un pool cible de 20-30. Premiers candidats évoqués (Mariage/Wedding, Cour/Royal Court, Jackpot/9999 — liés aux figures) se sont révélés être du contenu de fin de run, pas une réponse au manque ressenti *pendant* le run — gardés de côté dans le tiroir rare/signature. À la place : **Minima** (valeurs < 3, ×1.5), **Maxima** (valeurs > 7, ×3), **Prime** (2,3,5,7, fenêtre minimale 3 — même mécanique que Fibonacci généralisée). Balancing final (mult, noms) posé par le user directement sur la Sheet au fil de la conversation. Catalogue passe de 17 à 20 actives.

**Suppression de la rareté des Partitions** — le plus gros changement de design du lot. Parti d'une simple question du user ("des idées pour la rareté des Partitions ?"), la discussion a montré que le principe "plus fort = plus rare" (qui marche pour les Badges, un bonus optionnel) est incohérent pour les Partitions : ce sont la mécanique de résolution elle-même, pas un bonus. Gater les plus fortes derrière une rareté basse revient à priver le joueur d'une partie du jeu qu'il ne croiserait quasiment jamais sur 20 manches — contraire au principe "pas de RNG punitif" déjà appliqué ailleurs. Prix jugé pas totalement fiable non plus comme signal (beaucoup de Partitions viennent de packs à prix plat). Conclusion : le champ `rarity` est supprimé de `PatternData`, toutes les Partitions sont tirées uniformément au shop (unitaires et packs), comme Spéciaux/Boutons.

## Fix — catégories du shop sans doublon par rangée

Repéré par le user : les 4 slots du shop (2 packs + 2 unitaires) tiraient leur catégorie indépendamment — rien n'empêchait de retomber sur "spécial" sur toute une visite. `ShopManager._regenerate_packs`/`_regenerate_unitaires` tirent maintenant les catégories via un shuffle plutôt qu'un tirage indépendant par slot — plus jamais deux packs ou deux unitaires de la même catégorie dans une même rangée.

## Chantier design — refonte du démarrage de run

Discussion longue, entièrement conversationnelle (rien codé), partie d'une remarque du user sur l'écran actuel de sélection de Partition (3 tirées au hasard, 2 choisies) : "ça sent très proto". Plusieurs itérations :

1. **Constat** : le tirage 3/2 est recommençable à volonté en relançant la run — pas un vrai choix, un filtre RNG déguisé. Comparaison Balatro (choix de deck, presque jamais de composition retouchée) / Slay the Spire (personnage = archétype complet).
2. **Direction retenue** : un **pack de démarrage déterministe** (aucun random) remplace l'écran actuel — combine un deck éventuellement retouché, un modificateur de règle/économie (hold, grille, mouches, spéciaux...), et 1-2 Partitions fixes.
3. **Écueil identifié et corrigé** : un deck mono-famille ou mono-valeur casse la mécanique plutôt que de la colorer (mono-famille = résolution quasi garantie, recrée en pire le problème que la grille cabossée corrige déjà ; mono-valeur = tue des pans entiers du catalogue casino). Règle retenue : jouer sur la taille/le contenu spécial/une inclinaison, jamais sur une uniformité totale.
4. **Philosophie bonus-first** : après un premier jet trop orienté malus, pivot vers une majorité de bonus francs — l'objectif est de donner envie de tester TOUS les packs (complétionniste), pas de trouver son préféré. Vérifié que l'interaction avec les Badges existants reste propre sans code spécial (ex : pack "0 hold" + Badge Bénédiction +1 = retour au niveau normal, simple addition).
5. **Fonction du Shore** : finir une run avec un pack débloque du contenu permanent (nouveau pack, Badge, Partition, Spécial) — donne enfin une vraie fonction au Shore. Préféré le modèle "Découvertes" (exploit en jeu) déjà posé dans `shore/unlocks.md` plutôt que "gagner avec X débloque Y", pour rester proche de l'identité du jeu plutôt que de copier un mécanisme de genre.
6. **Vigilance anti-copie-Balatro** — le user a lui-même flagué que le système ressemblait beaucoup à Balatro. Distinction faite entre le squelette (partagé par tout le genre, pas un problème) et l'exécution (modificateurs secs façon stat-block, ça oui c'est très Balatro). Trois leviers retenus pour recoller à l'identité Deep Rows : habillage narratif de chaque pack, préférer les leviers propres au jeu (rocks/grille/hold/cascades) à l'économie pure (mouches/reroll), et le modèle Découvertes plutôt que "gagner avec X".

Tout capturé dans un nouveau brainstorm (`docs/brainstorms/brainstorm-starter-packs.md`) avec deux listes de packs candidats (V1 trop dure, V2 rééquilibrée bonus-first), et répercuté dans `structure-run.md`, `partitions/principe.md`, `shore/unlocks.md`, `shore/principe.md`, `decisions-tranchees.md`, `questions-ouvertes.md`. Rien codé — direction actée, roster et implémentation à faire.

## Chantier design — verrouillage des Partitions et roster final des packs

Suite directe du chantier packs de démarrage ci-dessus, toujours entièrement conversationnelle. Point de départ : aucune Partition n'était jamais verrouillée nulle part — les 20 actives sont toutes tirables au shop dès la première run (session 19, suppression de la rareté). Ça prive le Shore d'une vraie fonction sur les Partitions, et rend le "1-2 Partitions fixes" des packs un peu creux (n'importe quel pack peut piocher n'importe quoi).

1. **Split générique/verrouillé** — proposé sur la base du tableau des tiers de difficulté déjà existant. Premier jet à 10/10 (Trivial+Amorce+Facile vs le reste) jugé trop maigre une fois 2 Partitions déjà prises par le pack de départ (8 restantes à acheter sur toute une run). Resserré au cutoff **Difficile+ seulement** : 15 génériques (Trivial à Medium), 5 verrouillées (**Plus, Maxima, Cross, Ring, Diamond Rock** — Difficile à Hors échelle).
2. **Mécanisme d'unlock** — les 5 verrouillées recoupent exactement les Partitions fixes de 4 packs candidats du brainstorm (Dégagé→Plus, Risque-Tout→Ring, Fortifié→Cross+Diamond Rock, Ermite→Maxima). Plutôt que d'inventer une Découverte séparée par Partition, le pack lui-même fait double emploi : débloquer le pack (déjà une catégorie d'unlock Shore existante) débloque aussi sa Partition signature, pour toujours, dans le pool générique — cohérent avec la règle déjà écrite ("un contenu débloqué reste acquis pour toujours").
3. **Pas assez de packs day-one** — remarque du user : sur une save neuve, un seul pack de base ne donne pas un vrai choix. Sur les 9 packs candidats du brainstorm V2, 5 ne s'appuient que sur des Partitions génériques (donc peuvent être day-one sans paradoxe) ; les 4 autres sont justement les vecteurs d'unlock ci-dessus, donc doivent rester à débloquer. Sélection des day-one filtrée par le principe déjà posé "leviers Deep Rows plutôt qu'économie pure" (écarte Clairvoyant/Marchand du jour 1).
4. **Roster final (10 packs)** :
   - **Day-one** : Le Simplet (Line 3 + Brelan, aucun modificateur — nouveau nom du pack de base), Le Généreux (+2 mouches/manche gagnée, Diamond + Fibonacci), Le Prévoyant (+1 hold, Line 4 + Suite), Le Collectionneur (+1 Badge, Square + Prime — Brelan initialement prévu, swappé pour éviter un doublon avec Le Simplet)
   - **À débloquer** : Le Clairvoyant, Le Marchand, Le Dégagé (vecteur Plus), Le Risque-Tout (vecteur Ring), Le Fortifié (vecteur Cross + Diamond Rock), L'Ermite (vecteur Maxima)

Répercuté dans `partitions/catalogue-implemente.md`, `progression/structure-run.md`, `shore/unlocks.md`, `brainstorms/brainstorm-starter-packs.md`, `decisions-tranchees.md`, `questions-ouvertes.md`. Rien codé — reste ouvert : les conditions de déblocage précises (Découverte/biome) des 6 packs à débloquer, l'habillage narratif, l'implémentation technique (y compris la sauvegarde inter-runs, toujours pas construite).

## Implémentation — packs de démarrage day-one et champ `locked`

Passage du design au code, suite directe des deux chantiers ci-dessus.

- **`PatternData.locked`** (`scripts/data/pattern_data.gd`) — nouveau champ bool, `false` sur les 20 `.tres` existants (non touchés, la valeur par défaut suffit). Filtré dans `ShopManager._available_tags` : une Partition `locked` ne sort plus jamais du tirage shop. Tout reste décoché pour l'instant — aucun changement de comportement en jeu tant que le système d'unlock du Shore n'existe pas, mais le levier est prêt.
- **`StarterPackData`** (`scripts/data/starter_pack_data.gd`) — nouvelle Resource : `pack_name`, `description`, `fixed_tag_a`/`fixed_tag_b` (deux champs simples plutôt qu'un `Array[PatternData]`, tous les packs du roster en portent exactement 2), et les modificateurs permanents `hold_slot_bonus`/`badge_slot_bonus`/`preview_size_bonus`/`flies_per_round_bonus`.
- **4 `.tres`** dans `resources/starter_packs/` : Le Simplet (Line 3 + Brelan, neutre), Le Généreux (Diamond + Fibonacci, +2 mouches/manche), Le Prévoyant (Line 4 + Suite, +1 hold), Le Collectionneur (Square 4 + Prime, +1 Badge).
- **`RunManager`** — `apply_starter_pack()` équipe les Partitions fixes et mémorise le pack ; `get_badge_slot_count()`/`get_flies_per_round_bonus()` nouveaux getters ; les bonus hold/preview réutilisent le mécanisme existant des Badges (`_hold_slot_bonuses`/`_preview_size_bonuses`, réamorcés à chaque `reset_round_modifiers` comme une source de plus) plutôt qu'un canal séparé. `draft_starter_partitions` retiré (mort, remplacé par `get_available_starter_packs`).
- **Slots de Badge dynamiques** — `RunManager.equip_badge`, `ShopManager.can_equip_slot` et les 3 usages de `GameRules.MAX_BADGE_SLOTS` dans `BadgesUI` passent par `get_badge_slot_count()`. Les boutons VENDRE de `BadgesUI` sont créés en avance pour `MAX_BADGE_SLOTS + STARTER_PACK_MAX_BADGE_SLOT_BONUS` (nouvelle constante) car `Shell._ready()` tourne avant le choix de pack.
- **Nouvel écran `StarterPackSelectUI`** (`scenes/starter_pack_select/`) remplace entièrement `PartitionSelectUI`/`partition_select.tscn` (supprimés) — sélection exclusive d'un seul pack parmi les 4, au lieu du tirage 3/2. `SceneRouter`/`Shell`/`EndScreenUI` repointés (`go_to_starter_pack_select`).
- Vérifié en headless (`godot --headless --editor --quit` pour régénérer le cache de classes globales après l'ajout de `StarterPackData`, puis `--quit-after 10` sans erreur) — pas de test manuel en éditeur encore fait par le user à ce stade.

Rien débloqué côté Shore (les 6 packs restants et leurs conditions de déblocage restent à construire), sauvegarde inter-runs toujours absente.

## Balance — Prévoyant et Collectionneur, contrepartie après premier playtest

Retour à chaud du user dès les premiers essais en jeu : Le Prévoyant (+1 hold) et Le Collectionneur (+1 Badge) étaient de purs bonus sans contrepartie — des choix strictement dominants, pas une identité de build. Correction sur un levier propre à Deep Rows plutôt que l'économie, et sans piocher dans les combos déjà réservés ailleurs (0 hold = Risque-Tout, grille -1 = Fortifié) :

- **Le Prévoyant** : +1 hold, **preview -1** (2 au lieu de 3)
- **Le Collectionneur** : +1 Badge, **+2 rocks** dans le deck

Nouveau champ `StarterPackData.rock_count_bonus`, câblé comme `hold_slot_bonus`/`preview_size_bonus` (nouveau canal `RunManager._rock_count_bonuses`, seedé a chaque `reset_round_modifiers`, propagé via `RunContext.rock_count_bonus` jusqu'à `DeckManager.build_deck` — `GameRules.DECK_ROCK_COUNT + rock_count_bonus`). `preview_size_bonus` négatif fonctionnait déjà sans changement (simple somme).

## Fix — libellés des Partitions équipées

Repéré par le user en playtest : les slots de Partitions équipées affichaient des noms composés illisibles ("LINE PRIME 3", "LINE CASINO 3" pour Brelan) au lieu du nom simple utilisé partout ailleurs (shop, hovers). `TagsUI._format_tag_label` recomposait un libellé forme+règle+taille depuis session 13-14 pour éviter les doublons visuels — simplifié pour reprendre directement `tag.label` (+ le multiplicateur, conservé). `_shape_label`, devenue inutile, retirée au passage.

## Discussion — cible Steam Neo Fest

Le user a remonté les dates des prochains Steam Neo Fest (octobre 2026, février 2027, juin 2027) et demandé un avis honnête sur la faisabilité d'une démo. Octobre écarté d'emblée : zéro DA commencée (volontairement, voir [[feedback_no_da_before_fun]]) et la mécanique centrale encore en mouvement (cette session seule : scoring, rareté des Partitions, démarrage de run). Février 2027 retenu comme ligne de mire, avec deux nuances posées en discussion :

- Le user cherche des missions de Product Design en parallèle (bande passante dev réelle incertaine) — mais se dit solide côté création (DA/illustration/UI), moins expérimenté sur l'implémentation Godot et le "juice" (animations, triggers, SFX/VFX), qui est pourtant l'axe déjà identifié comme priorité n°1 du projet.
- Point relevé par le user : ~20 sessions ont déjà produit tout le squelette mécanique (grille, cascades, Partitions, scoring, deck, shop, 37 Badges, starters), à un rythme qui s'accélère. Nuance apportée : ce rythme vient surtout du fait que ce travail est de la logique pure (testable headless), le terrain où l'assistance IA porte le plus — le futur travail de juice/implémentation visuelle est plus manuel/itératif dans l'éditeur, donc pas garanti d'aller aussi vite.

Rien de tranché en dur — février 2027 gardé comme ligne de mire, à réévaluer une fois la bascule fun→feel amorcée. Capturé dans la mémoire persistante (`user_background.md`, `project_content_priority.md`), pas dans le GDD (pas une décision de design).

## Statut

- GDD entièrement resynchronisé avec le code (22 fichiers)
- Plusieurs petits fixes/rééquilibrages joués et prêts à tester (Tickets, seuil mouches, Dés à coudre, shop sans doublon)
- Catalogue de Partitions à 20, plus de rareté dessus, Fibonacci généralisé
- **Roster complet des packs de démarrage tranché** (10 packs : 4 day-one + 6 à débloquer) et split générique/verrouillé des Partitions posé (15/5) — **les 4 packs day-one et le champ `locked` sont maintenant codés et jouables** (`StarterPackData`, `StarterPackSelectUI`, remplace l'ancien tirage 3/2). Reste : les conditions de déblocage précises des 6 packs restants, la sauvegarde inter-runs pour le Shore (n'existe pas encore dans le code)
- Idée notée pour plus tard, volontairement différée : un système de Stakes façon Balatro pour les joueurs qui ont tout débloqué
