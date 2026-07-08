# Questions ouvertes

Ce qui reste à trancher, par le proto ou par réflexion.

## Gameplay

- **Multiplicateur vertical (`LINE_MULT_VERTICAL`)** — discuté en session 12 comme le levier le plus simple contre le stacking colonne (actuellement x1, jamais nerfé). Reste la tâche de tuning la plus immédiate et la moins chère.
- **Multiplicateur de cascade (`CASCADE_MULTIPLIER_BASE = 2.0`)** — s'est révélé fragile lors du proto swap-sur-plateau-plein de la session 12 (explosion à 100k points en 10 coups dès que la profondeur de cascade augmente). Le family-only + la grille cabossée visent justement à augmenter la fréquence des cascades — à surveiller en priorité au prochain playtest : si les scores partent en vrille dès qu'une cascade de 3-4 niveaux se déclenche, c'est ce multiplicateur qu'il faut baisser (x1.5 ?), pas autre chose.
- **Intensité de la [grille cabossée](../grille/trous.md)** — 5-8 trous/manche, jamais row 0. Premier jet, à retuner au ressenti.
- **Rename des familles** — Bone/Wood/Brass décidé en session 10, jamais appliqué au code (toujours `CORAL/SHELL/RUST/INK`). À faire à un moment, pas bloquant.
- **Retour de la résolution par valeur** — désactivée en session 12 (family-only). Les Partitions/Badge liés à la valeur restent sur le disque, hors catalogue. Pourrait revenir comme contenu rare/Shore plus tard.
- **Taille de la preview du stream** — 3 jetons actuellement. À tester si 2 est plus tendu.
- **Courbe du [score cible](../manche/score-cible.md)** — actuellement linéaire (+30 par manche). À revoir avec les multiplicateurs directionnels et le level up des Partitions qui scalent différemment.
- **Seuils et multiplicateurs du [level up des Partitions](../partitions/level-up.md)** — vocabulaire musical (Pianissimo → Maestro) décidé, valeurs à tuner.
- **Pool de [modifiers de cellules](../grille/modifiers-cellules.md)** — combien de choix offerts à chaque fin de zone ? Quand de nouveaux mods se débloquent via le [Shore](../shore/unlocks.md) ?
- **Ordre des écrans de transition** — fin de manche → récompense de zone → shop → manche suivante ? À formaliser.
- **Cumul multiplicatif des [Badges](../badges/principe.md)** — `set_rule_multiplier` écrase au lieu de cumuler (`run_manager.gd`). À corriger dès qu'un Badge doit stacker avec un autre sur la même rule (ex : Famille Unie + Collectionneur ne se marchent pas dessus aujourd'hui car sur des rules différentes, mais deux Badges sur la même rule s'écraseraient).
- **Forme exacte de l'[Inspecteur de deck](../manche/inspecteur-deck.md)** — modale, panneau latéral, avec ou sans pause ?
- **Effets "Tarot" sur les boutons** (swap avec le voisin, ancrage façon Fantôme, évoqués en session 12) — à trancher d'abord : mutation du pool (comme la Fusion, hors-manche) ou effet de grille en cours de manche (comme Fantôme/Bombe/Marée) ? Portée technique différente selon la réponse.
- **Decks de départ façon Balatro (bonus/malus)** — idée évoquée en session 13 pour la rejouabilité, distincte des grilles spéciales (réservées à la progression du Shore). Le pool de boutons de départ est structuré depuis la session 13 (2× chaque famille/valeur) mais reste fixe, aucun choix du joueur dessus. Vision d'origine "classes" (grille + pack), jamais implémentée — seule la [sélection de Partition](../partitions/principe.md) existe comme vrai choix de départ aujourd'hui.

## Économie

- **[Tickets](../progression/monnaies.md)** — mécanique exacte à formaliser (combien par manche / zone, coût d'accès à une zone, conversion en meta-progression ?).
- **Mouches non dépensées en fin de run** — converties en tickets pour le Shore ? Perdues ?
- **Courbe de prix au shop** — les prix augmentent-ils avec les zones ?
- **Surplus de score** — bonus de mouches ? À tester.
- **Pondération par rareté dans le shop** — pas encore implémentée (voir [Génération de l'offre](../shop/generation-offre.md)), tirage uniforme pour l'instant. Pas urgent tant qu'il n'y a pas de contenu Epic.
- **Prix du shop v2** (packs, Dés à coudre, reroll) — premiers jets posés en session 12, à rééquilibrer avec plus de playtest.

## Univers

Direction validée ([Pitch](../univers/pitch.md), [Ton](../univers/ton.md), [Direction artistique](../univers/direction-artistique.md)). Les questions qui restent :

- **Le titre du jeu** — "Deep Rows" est un placeholder.
- **Le [garçon](../univers/personnages/garcon.md)** — silhouette + acolyte à dessiner.
- **L'[Entity](../univers/personnages/entity.md)** — forme, nom, ton précis.
- **Les zones** — 4 lieux de la descente, de plus en plus étranges. À trouver zone par zone.
- **Le lieu de retour** — remplacer "The Shore" par un nom qui appartient à ce monde.
- **Les packs de [boutons](../jetons/boutons.md)** — compositions concrètes (Polyvalent, Mono-famille, Escalier...) à redesigner.
- **Le catalogue final de [spéciaux](../jetons/specials.md)** — au-delà des 3 du proto, quelle variété viser ?
- **Contenants de packs thématiques** (Bocal, Rouleau, Bulbe des grenouilles...) — mis de côté pour un contenant générique en session 12 (pas de DA avant validation du fun), à ressortir plus tard.

## Technique

- **Hand-drawn pipeline** — évolution du style Licky's (patte + grain) ou rupture plus brute ? À trancher par les premiers essais visuels. Le user a la DA en tête, reste à la matérialiser.
- **Animations de cascade** — niveau de juice pour la demo.
- **Son** — priorité pour le proto ou après validation du fun ?
- **Headless** — le `TurnController` dépend de signals émis par `GridVisual`. À retravailler quand on voudra tourner des manches sans affichage (contournable ponctuellement en instanciant les managers directement hors scène, comme fait pour la vérification de plusieurs features en session 12).

## Liens

- [Décisions tranchées](decisions-tranchees.md)
- [Brainstorms](../../brainstorms/)
