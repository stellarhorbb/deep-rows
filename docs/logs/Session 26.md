# Session 26 — Le doute sur le core, diagnostic du round-start, fond marin + persistance + Entity imprévisible

**Date** : 2026-08-02 → 2026-08-03 (conversation continue sur deux jours)
**Thème** : Session mixte, en deux temps. D'abord une longue discussion de design pure (le user doute du fun du jeu après quelques jours sans dev), qui isole un vrai problème mécanique précis (le début de chaque manche). Ensuite implémentation, playtest et retunes en continu de plusieurs systèmes qui répondent à ce diagnostic.

---

## Le doute et le diagnostic

Point de départ : "comme à chaque fois que je passe quelques jours à ne pas dev le jeu, je trouve que mon core gameplay est pas dingue dingue." Plutôt que de prendre ça pour argent comptant, la discussion a creusé pour distinguer un vrai signal d'un artefact de recul (cf. [fatigue de testeur vs signal](../../CLAUDE.md), déjà noté par le passé) — cette fois le signal s'est confirmé précis et reproductible, pas de la fatigue.

**Comparaison à 4 jeux du marché actuel** (Cursed Words, CloverPit, Dogpile, Bills Must Be Paid) : le point commun trouvé en creusant leurs pages Steam — chaque action individuelle du joueur (mot posé, spin tiré, tirelire cassée, fusion au contact) paie immédiatement, sans distance setup→payoff. Dogpile, le plus proche structurellement (grille, adjacence), fusionne au contact plutôt que d'exiger une ligne de 3+ assemblée sur plusieurs tours. Deep Rows, avec sa résolution conditionnelle aux Partitions équipées, paie plus tard et de façon gatée — coût direct du pilier qui fait sa profondeur, pas un défaut d'exécution.

**Framework de Derek Yu (Spelunky)** appliqué : Deep Rows a choisi le pari "haut risque, haute expérimentation" (mécanique novatrice) plutôt qu'un reskin de template éprouvé — plus cher à roder, mais l'espace de design (spatial + persistance + géométrie + cascades, déjà posé en genèse du projet) reste réel. Conclusion : le concept n'est pas cassé, mais l'ouverture de chaque manche méritait un vrai diagnostic chiffré.

**Diagnostic chiffré** (vérifié dans le code, pas à l'instinct) :
- Seuil de la roulette = 21, jeton moyen = 3, jauge remise à zéro chaque manche → ~7 drops avant le premier déclenchement possible, à chaque manche.
- Cases mystère : 2-4 sur 49 cases (7×7), sparse, pas fiable en ouverture.
- Résolution de Partition : besoin de 3-4 jetons assemblés au minimum.
- Les trois systèmes de feedback existants sont donc mathématiquement incapables de se déclencher dans les 5-8 premiers drops de chaque manche — pas une coïncidence, une résonance entre systèmes indépendants.

Recentré ensuite par le user lui-même : le problème n'est pas "toute la boucle construction→pop→vide", c'est spécifiquement **la grille vraiment vide** (début de manche, rarement après un très gros clear) — une fois du clutter accumulé, la grille devient tactique, pas ennuyeuse. Comparaison à Candy Crush/Two Dots : ces jeux ne sont jamais vides parce qu'ils rechargent à l'infini — Deep Rows ne peut pas copier ça sans détruire la rareté du deck (pilier délibéré, source de la vraie tension de défaite).

## Pistes explorées et rejetées avant les solutions retenues

Plusieurs axes radicaux évoqués en prenant de la hauteur, chacun avec une raison précise de rejet :
- **Couche de résolution universelle sous les Tags** (tout pattern donne un petit score, même sans Tag équipé) — viderait de son sens le choix stratégique des 4 slots.
- **"Ouverture"** (déverser 8-10 jetons du deck au hasard en début de manche) — sacrifie le deck que le joueur construit délibérément pendant la run.
- **Entity qui joue à chaque tour** (façon vrai Puissance 4 adversarial) — renverse un pilier verrouillé ("l'Entity ne joue pas"), tension avec le sens narratif caché.
- **Entity réactive** (ne réagit qu'aux résolutions du joueur) — rejetée par le user : silencieuse pile pendant la fenêtre qu'on essaie de réparer, puisqu'aucune Partition n'a encore scoré tôt en manche.
- **Pivot Bejeweled/swap-puzzle** (grille pleine dès le départ + mouvements limités) — tue le deck-building et rend les spéciaux obsolètes ; abandonne aussi le geste de drop que le user a lui-même validé comme sain.
- **Pool de 6-7 effets d'ouverture tirés au hasard** — jugé "too much" par le user lui-même, retour à quelque chose de plus simple.

## Ce qui a été implémenté

### Fond marin (grille cabossée, revue)
Quatre jets successifs avant la version retenue (marche aléatoire → tirage indépendant par colonne → pic unique centré → pics multiples variés) — voir [Grille cabossée](../gdd/grille/trous.md) pour le détail de chaque rejet. Version finale : 2-4 pics indépendants par manche, pyramide en escalier (hauteur 1/2/3 à taux fixe 45/35/20%, largeur 1/3/5), ancrés sur une colonne aléatoire, pas forcément centrés (peuvent "sortir du cadre"). Plus 2-4 trous rouges dispersés en plus.

Une tentative de redimensionner la grille en 7×9 a été explorée en détail (calcul précis des collisions UI à résolution fixe 1920×1080) puis **annulée sur demande du user** après playtest du fond marin seul — jugé suffisant sans le redimensionnement.

### Entity-skull en probabilité croissante
Remplace l'intervalle fixe (`ENTITY_DROP_INTERVAL`, comptable au tour près — "je sais qu'un skull va tomber"). Nouveau système : chance qui grimpe de `ENTITY_DROP_INCREMENT` chaque tour depuis le dernier drop, plafonnée naturellement à 100% (pas de règle "forcée" à part). Deux jets de calibrage : 20%+10% (moyenne ~3 tours) jugé trop fréquent au playtest réel ("un skull tous les 2 drops"), retenu à **5%+5%** (moyenne ~5.3 tours, quasiment identique à l'ancien rythme) après simulation Python de plusieurs combinaisons. GRANDE FAIM double l'incrément plutôt que diviser l'ancien intervalle.

### Persistance entre manches
Voir [doc dédié](../gdd/manche/persistance-entre-manches.md). Le bouton qui occupe la case la plus haute de chaque colonne à la fin d'une manche gagnée retombe sur la grille suivante (avant les cases mystère). Règle importante, corrigée en cours de session suite à une remarque du user : **la case occupée la plus haute compte telle quelle, sans creuser en dessous** — si c'est un Rock ou un skull, la colonne ne persiste rien, même avec un bon jeton dessous. Volontairement tactique : couvrir un jeton le protège de la persistance (garde le contrôle du joueur sur son placement plutôt que de le voir retomber au hasard).

**Bug trouvé et corrigé en cours de route** : un jeton persisté redonnait quand même une copie fraîche dans le deck de la manche suivante (double comptage), puisque `DeckManager.build_deck()` régénère toujours une copie de tout le pool possédé sans savoir qu'un exemplaire vient d'être replacé directement. Fix : `build_deck(button_pool, carried_over)` saute une copie par jeton persisté.

**Habillage visuel demandé par le user** : animation d'aspiration (~3 secondes, toutes les colonnes concernées en même temps, juste avant l'écran YOU WIN) puis chute (colonne par colonne, gauche à droite, avant les cases mystère) à la manche suivante — symétrie visuelle pensée pour que le joueur infère la règle sans texte explicite. Attribuable à l'Entity dans l'intention (cohérent avec son rôle déjà établi de seule chose qui agit sur la grille indépendamment du joueur), jamais explicité en jeu.

## Refactor technique notable

`TurnController.start_round()` scindé en deux : la partie qui génère trous/reset modifiers reste synchrone, la suite (cases mystère, contexte, deck) part dans une nouvelle méthode `finish_round_start()` appelée par `GameScene` après l'animation asynchrone des jetons persistés — nécessaire pour que les cases mystère voient les jetons persistés déjà posés (évite de les recouper) tout en gardant l'animation lisible avant de rendre la main au joueur.

## Playtest et validation

Confirmé par le user en fin de session : "chaque starter est maintenant plus rempli et donc de suite plus stratégique." Les trois pièces (fond marin, persistance, Entity imprévisible) attaquent chacune un angle différent sans se chevaucher — pas de sur-complexification identifiée, malgré le nombre de pistes explorées et rejetées en amont.

## Reste ouvert (partie 1)

- **Lisibilité de la persistance** — comment nommer/présenter la règle au joueur sans texte explicite. Pas de réponse trouvée, probablement à revisiter avec la passe DA.
- **Plafond de matière de la persistance** (max 1 jeton/colonne) — jamais testé sur un run complet de 20 manches.
- **Aperçu du deck au shop** (`build_next_round_deck_preview`) — ne reflète pas encore l'exclusion des jetons persistés (mineur, discuté puis clarifié que ce n'est pas un bug : au moment du shop le jeton n'a pas encore été replacé).
- **Fréquence/intensité du fond marin** — premier jet, pas encore éprouvé sur beaucoup de manches.

---

# Partie 2 — Pourquoi les Sortilèges sont oubliables, et chantier "Vague 1/2/3" (25 items)

**Même journée (2026-08-03), deuxième bloc de la session.** Point de départ : le user trouve la plupart de ses Sortilèges plats ("je les prends mais j'oublie à moitié qu'ils existent"). Longue discussion diagnostique puis un gros chantier d'implémentation en trois vagues.

## Le diagnostic : statique vs scalant, pas flat vs rule-changing

Hypothèse de départ (rejetée après vérification) : les Sortilèges "bonus flat au value_sum" seraient plats par nature. En réalité, la bannière de résolution attribue déjà chaque Sortilège individuellement (tilt de carte, session 25) et les valeurs des jetons sont déjà affichées (`DEBUG_SHOW_TOKEN_VALUE`) — la présentation façon Balatro existe déjà.

Le vrai signal, trouvé en comparant la liste citée par le user au catalogue complet : **tous les Sortilèges cités comme oubliables sont des bonus fixes, identiques manche 1 et manche 20.** Aucun des Sortilèges "scaling permanent" (Escalade musicale, Jetons sacrés, Rescapé, Cairn...) n'apparaît dans la liste — alors que ce sont mécaniquement les mêmes ingrédients (bonus flat/mult sur la formule). Confirmé indirectement par Balatro : Greedy/Lusty/Wrathful/Gluttonous Joker (les jumeaux structurels exacts des Tickets X) sont aussi le tier le plus oubliable là-bas — mais leurs Jokers mémorables sont presque toujours ceux qui **grossissent** (retriggers, xMult qui stack), pas juste flat vs mult.

Comparaison au wiki Balatro (Common + Uncommon complets) : trois archétypes mécaniques totalement absents du catalogue Deep Rows —
- **Retrigger** (rejouer une résolution) — rien d'équivalent
- **Assouplissement de règle de match** (Four Fingers, Shortcut) — touche à *ce qui compte comme un match*, donc plutôt du ressort d'une Partition (forme+règle indivisible) que d'un Sortilège, qui n'agit qu'après détection
- **Risque/fragile pour un gros number** — rien d'équivalent, coller à l'axe casino déjà validé

Distinction clarifiée avec le user en cours de route : un Sortilège modifie le **score après détection** ; une variante de règle de match (Ligne trouée, Carré à 3/4) appartient aux **Partitions**, pas aux Sortilèges — sépare proprement le brainstorm en deux listes.

## Organisation en 3 vagues, classées par risque technique

Priorité fixée sur le classement par difficulté d'implémentation plutôt que par thème :
- **Vague 1** (le plus sûr, réutilise des systèmes déjà génériques) : 13 items
- **Vague 2** (nouveaux points d'intégration mais bornés) : 7 items
- **Vague 3** (vraies nouvelles briques d'architecture) : 5 items

Rareté/prix calibrés selon une règle établie en cours de route et réutilisée pour tout le reste : **le prix suit le jumeau structurel le plus proche déjà dans le catalogue, jamais une prime à la difficulté** (ex : 777/9999 payés comme Brelan/Carré poker, pas plus cher parce que plus dur à obtenir — "pas de double peine"). Rareté des Sortilèges/Spéciaux, elle, jugée par pouvoir réel ("OP ou pas"), pas par thème.

## Vague 1 — 13 items

Favoritisme, Bon départ, Fenêtre Longue, Jamais 1 sans 2, Deux étages, Vestige, Décuple Pétard/Quintuple Bombe/Triple Armageddon, Cristal/Diamant, 777/9999.

Point technique le plus lourd : **Deux étages** a demandé de généraliser toute la chaîne de persistance (session "partie 1" ci-dessus) d'un seul jeton par colonne à un layout fixe `GameRules.CARRYOVER_MAX_DEPTH = 2`, constant même sans le Sortilège équipé — pour que l'encodage/décodage entre la fin d'une manche et le début de la suivante ne se désynchronise jamais si le Sortilège est acheté/vendu entre les deux (au shop). A touché `GridManager`, `GameScene`, `DeckManager` restant inchangé par chance (déjà tolérant aux slots vides).

Bug trouvé en cours de route et corrigé : le fond/nom du biome (`_update_zone_display`) n'était mis à jour qu'**après** l'animation de chute des jetons persistés — affichait l'état de la manche précédente pendant ~3 secondes à chaque début de manche. Avancé avant l'await dans `_start_round`.

## Vague 2 — 7 items

Comète, Amplificateur, Pierre de Famille, Pile ou Face, Dernier dernier Souffle (Va-tout), Wedding, Royal Court.

**Va-tout** : le trigger `on_last_breath` existant se déclenche *avant* les explosions et la cascade finale du Dernier Souffle — parier dessus n'aurait pas misé le score réellement final. Câblé comme Souffle Obscur (check direct juste avant le verdict), pas via ce trigger comme prévu initialement. Confirmé plus tard par le user que le flux (ne se déclenche que si la cible n'est pas encore atteinte, jamais un risque sur une manche déjà gagnée) était bien l'intention.

**Pierre de Famille** — révisé après clarification du user : la version livrée convertissait le Rock en vrai jeton (mutation permanente). Le user voulait que **le Rock reste un Rock** (zéro valeur propre, jamais retiré, toujours compté par Cairn/Collectionneur) — juste débloquer le match des autres jetons du groupe. Refait en mutation *temporaire* (le temps du scan qui suit dans `CascadeResolver.resolve`, revert immédiat), avec un correctif en cascade sur la capture de famille pour "Un Pour Tous" (qui aurait pu lire la famille sur le Rock plutôt qu'un vrai jeton du groupe).

## Vague 3 — 5 items

Skull Line 4, Shadow Dance, Black Hole, Siphon, Miroir.

Longue discussion sur les valeurs des trois Partitions signature, résolue en plusieurs passes avec le user (rejet successif de multiplicateurs fixes, d'un calcul "étrange", d'un lien à la profondeur de cascade jugé trop dur à provoquer) :
- **Skull Line 4** : tirage à palier (12/36/120, taux 55/40/5% comme la roulette) **×** nombre de skulls sur la grille — les deux facteurs dynamiques, aucun nombre figé
- **Shadow Dance** : multi = nombre de skulls sur la grille, brut
- **Black Hole** : multi = nombre de trous sur la grille, brut (le user a validé "on teste on verra" plutôt qu'un facteur d'amortissement)

Conséquence découverte en implémentant : les trois utilisent exactement le mécanisme déjà réservé aux Legendary (`sheet_name` codé en dur, multiplicateur dynamique) — reclassées en `is_legendary = true`, prix 20, plutôt que dans le pool normal comme 777/9999/Wedding/Royal Court (qui ont un multiplicateur fixe, eux).

**Black Hole** a nécessité de faire remonter `holes` à travers `SheetMatcher.find_all` et `CascadeResolver._score_group` — jusque-là aucun détecteur n'avait besoin de savoir "quelle case est un vrai trou" plutôt que juste vide.

**Siphon** : gate ajouté préventivement suite à une remarque du user (le joueur pouvait le nourrir indéfiniment en re-droppant dans sa colonne) — plafond fixe de 5 bouchées capturé à la pose, indépendant du remplissage réel.

**Miroir** — limite technique posée franchement au user avant de coder : un vrai "copie n'importe quel Sortilège" demanderait de refactorer ~50 scripts d'effet pour qu'ils sachent sous quel id écrire. Implémenté à la place sur les canaux génériques existants de `RunContext` (rule/global/value_bonus/family/pair/top_row/retrigger/scaling/flat) — ne fait rien face à un Sortilège "passif" (has_spell direct), limitation assumée et documentée. Accompagné d'une UI de réordonnancement des slots par clic-clic (swap), jamais construite avant.

## Bugs trouvés en playtest, corrigés dans la foulée

- **Pile ou Face "ne trigger jamais"** — en fait deux bugs de feedback superposés, pas la logique elle-même : (1) `SpellManager.spell_triggered` (qui fait tilter la carte) ne s'émet que si des mouches bougent, jamais le cas ici ; (2) même corrigé, `sync_sprites()`/`refresh()` ne rafraîchissent jamais le contenu d'un sprite déjà créé. Ajout d'un signal générique `TurnController.dropped_token_mutated` (détecté par diff avant/après sur le jeton posé, pas codé en dur pour un Sortilège précis) qui déclenche `rebuild_sprites()` + le tilt.
- **Amplificateur ne disparaissait jamais** — la première version posait un modifier de cellule générique (comme Cellule Double), système anonyme qui ne sait pas qui l'a posé ni s'il a servi. Refait sur le modèle d'Hypercube (seul autre spécial réactif) : détecté par adjacence à chaque groupe qui score, double son score, puis se retire via le même événement `REMOVE` que le reste du groupe.

## Statut

Les 25 items sont codés et enregistrés dans les catalogues (shop, sheets, specials). **Rien testé en jeu** — pas d'accès à l'éditeur Godot dans cet environnement, comme noté en session 25. Les deux bugs de feedback trouvés (Pile ou Face, Amplificateur) l'ont été via des remontées du user en train de jouer, pas par une vérification de mon côté — à surveiller que d'autres items de ce chantier n'aient pas le même genre de trou (effet réel qui tourne mais invisible/mal intégré au reste du pipeline).

## Reste ouvert (partie 2)

- **Aucun item de ce chantier n'est confirmé fonctionnel en jeu** au-delà des deux bugs déjà trouvés et corrigés — un passage complet en jeu reste à faire, en particulier Black Hole/Skull Line/Shadow Dance (le plus de nouvelle plomberie).
- **Calibrage des trois Legendary skull/hole** — valeurs posées par consensus mais "on teste on verra" assumé par le user, pas de vraies données de run.
- **DA des nouveaux Spéciaux** — Cristal/Diamant/Comète/Amplificateur/Siphon ont leurs assets (déposés par le user en cours de session), Électrique préparé mais pas encore consommé (pas dans ce chantier).
