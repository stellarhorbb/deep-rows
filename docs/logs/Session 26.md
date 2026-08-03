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

## Reste ouvert

- **Lisibilité de la persistance** — comment nommer/présenter la règle au joueur sans texte explicite. Pas de réponse trouvée, probablement à revisiter avec la passe DA.
- **Plafond de matière de la persistance** (max 1 jeton/colonne) — jamais testé sur un run complet de 20 manches.
- **Aperçu du deck au shop** (`build_next_round_deck_preview`) — ne reflète pas encore l'exclusion des jetons persistés (mineur, discuté puis clarifié que ce n'est pas un bug : au moment du shop le jeton n'a pas encore été replacé).
- **Fréquence/intensité du fond marin** — premier jet, pas encore éprouvé sur beaucoup de manches.
