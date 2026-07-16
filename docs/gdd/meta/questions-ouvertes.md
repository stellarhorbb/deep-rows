# Questions ouvertes

Ce qui reste à trancher, par le proto ou par réflexion.

## Gameplay

- **Multiplicateur de cascade (`CASCADE_MULTIPLIER_BASE = 2.0`)** — s'est révélé fragile lors du proto swap-sur-plateau-plein de la session 12 (explosion à 100k points en 10 coups dès que la profondeur de cascade augmente). Le family-only + la grille cabossée visent justement à augmenter la fréquence des cascades — à surveiller en priorité au prochain playtest : si les scores partent en vrille dès qu'une cascade de 3-4 niveaux se déclenche, c'est ce multiplicateur qu'il faut baisser (x1.5 ?), pas autre chose.
- **Intensité de la [grille cabossée](../grille/trous.md)** — 5-8 trous/manche, jamais row 0. Premier jet, à retuner au ressenti.
- **Taille de la preview du stream** — 3 jetons actuellement. À tester si 2 est plus tendu.
- **Seuils et multiplicateurs du [level up des Partitions](../partitions/level-up.md)** — vocabulaire musical (Pianissimo → Maestro) et valeurs `[1.0, 1.25, 1.5, 1.75, 2.0]` gardés tels quels (session 16). Ce qui reste ouvert : la formule des "dan" au-delà de Maestro (seuil et multiplicateur par palier, génériques pour ne pas dépendre d'un nombre de manches précis) — à trancher maintenant que la [courbe du score cible](../manche/score-cible.md) et la [longueur du run](../progression/structure-run.md#dimensions) (20 manches, figées session 18) sont posées.
- **Contraintes de boss (session 16)** — le pool global aléatoire de malus de boss (voir [Structure du run](../progression/structure-run.md#boss-de-zone)) est décidé dans son principe, mais son contenu reste à inventer : pistes en vrac non tranchées — une famille qui ne score plus ce tour-là, une Partition équipée désactivée au hasard, une grille avec deux fois plus de trous, un deck sans jetons spéciaux...
- **Pool de [modifiers de cellules](../grille/modifiers-cellules.md)** — combien de choix offerts à chaque fin de zone ? Quand de nouveaux mods se débloquent via le [Shore](../shore/unlocks.md) ?
- **Ordre des écrans de transition** — fin de manche → récompense de zone → shop → manche suivante ? À formaliser.
- **Figures / axe casino orphelin (session 18)** — au-delà de Chevalier, une figure (Reine 15, Roi 20) n'a plus aucune Partition casino accessible : pas de voisin à distance 1 pour Suite, Brelan demanderait 3 exemplaires de la même figure (quasi impossible structurellement). Seul l'axe famille reste ouvert. Direction envisagée : un pattern signature "Mariage" (Roi + Reine assemblés, vocabulaire tarot/belote classique) comme débouché casino dédié — non implémenté, voir [Figures](../jetons/boutons.md#figures-arcanes-mineurs).
- **Réordonner les Badges équipés (session 15, précisé session 17)** — le user veut pouvoir réorganiser librement l'ordre de ses Badges dans les slots. Techniquement plus simple qu'avant : la bannière de résolution résout déjà les Badges dans l'ordre de `RunManager.get_equipped_badges()` (session 17, voir [Scoring](../partitions/scoring.md)), donc une UI de réorganisation changerait immédiatement l'ordre d'affichage. **Mais vérifié explicitement en session 17 : le score réel reste order-independent** (décision délibérée, voir [Décisions tranchées](decisions-tranchees.md)) — réordonner resterait donc purement cosmétique/préférence perso tant qu'aucun Badge positionnel (Miroir/Écho, voir brainstorm) ou scoring séquentiel n'existe. Pas de fonction de réordonnancement ni UI drag-and-drop construite pour l'instant.
- **Effets "Tarot" sur les boutons** (swap avec le voisin, ancrage façon Fantôme, évoqués en session 12) — à trancher d'abord : mutation du pool (comme la Fusion, hors-manche) ou effet de grille en cours de manche (comme Fantôme/Bombe/Marée) ? Portée technique différente selon la réponse. À ne pas confondre avec la généralisation de la Fusion en rubrique "Dés à coudre" ci-dessous — celle-ci reste bien côté mutation du pool hors-manche.
- **Généralisation de la Fusion en outils de deck "Dés à coudre" — implémenté (session 16, +Fixer en session 18)** — voir [Brainstorm dédié](../../brainstorms/brainstorm-outils-deck.md) pour le détail complet et [Boutons](../jetons/boutons.md) pour la doc à jour. Pool de 10 actions pondérées par rareté, UX revue en cours de test (actions et cibles affichées ensemble, plus de confirmation séparée). Seul point encore ouvert : le nom final ("Dés à coudre" reste un placeholder hérité de la Fusion seule).
- **Decks de départ façon Balatro (bonus/malus)** — **direction tranchée en session 16** : c'est le pack de boutons qui porte ce rôle (voir [Décisions tranchées](decisions-tranchees.md) et [Structure du run](../progression/structure-run.md#choix-de-départ)), la grille en est explicitement exclue (elle est liée au biome). Reste ouvert : les compositions concrètes des packs eux-mêmes (Polyvalent, Mono-famille, Escalier...), toujours à redesigner (voir Univers ci-dessous), et l'implémentation du choix au lancement d'une run.
- **Choix de spéciaux au départ (session 15)** — en confirmant qu'on garde les 2 Partitions gratuites de départ (le 2e choix sert vraiment de filet, pas un slot mort — retour de playtest), le user propose d'ajouter un choix de jetons spéciaux au démarrage de la run, en parallèle. Techniquement, ça calquerait le même principe que `RunManager.draft_starter_partitions`/`PartitionSelectUI` (tirage de N, le joueur en choisit M) appliqué aux spéciaux plutôt qu'aux Partitions. Reste à trancher : combien tirés, combien choisis, gratuit ou payant, et est-ce que ça a du sens vu que les spéciaux se régénèrent déjà librement au shop (contrairement aux Partitions, limitées aux 4 slots).
- **Tiroir rare/signature du catalogue Partitions** (9999/Jackpot, paires de familles figées) — voir [Catalogue implémenté](../partitions/catalogue-implemente.md#tiers-de-difficulté-session-16). Le reste du catalogue est classé par tier et synchronisé avec la Sheet ; ce tiroir seul reste non implémenté.
- **Balance des 22 nouveaux Badges de session 17** — voir [Badges implémentés](../badges/badges-implementes.md) pour le catalogue complet. Déjà nerfés au playtest : Quatre quart (+5→+1 par pattern de 4), Poker Face (25%→10% de proc). Confirmés sains mais peu testés : Jetons sacrés, Escalade musicale (constante remontée par le user de 0.1 à 0.25 en cours de test), les Badges "tickets-en-vrai-des-points" (Tickets Hivernal/Automnal/Estival/Printanier [ex-Encrée/Rouillée/Nacrée/Coraillée, renommés session 18]/Y'en a pas deux/Sommet/Vingt-trois/Saint Pair/Impair profane) et le lot level-up/deck (Mouche mélomane/Amélioration continue/Gourmand/Économe) — aucun retour de playtest dédié pour l'instant, à surveiller en priorité à la prochaine session de jeu.
- **Généraliser le roll casino (session 15)** — Diamond Rock a reçu un roll 1-5 + animation de roulette pour éviter qu'un coup aussi rare (4 rocks max par run) ne dépende entièrement de la valeur du jeton central (voir [Rocks](../jetons/rocks.md)). Volontairement scopé à ce seul pattern pour l'instant, pas de système générique construit. À revoir si l'essai est concluant en playtest : sur quels autres patterns un roll ferait sens (candidats naturels : autres formes rares/difficiles comme Ring ou Cross) ? Faut-il un vrai système de "roll" réutilisable (plage configurable par tag, cout en mouches pour relancer ?) plutôt que des constantes ad hoc comme `DIAMOND_ROCK_ROLL_MIN/MAX` ?
- **Rehausser encore le score de Diamond Rock, et le faire scaler (session 15)** — playtest avec le bouton refresh (debug) sur l'écran de sélection de Partition : quand le joueur arrive enfin à former un Diamond Rock, la grille est déjà très remplie (c'est mécaniquement lié à la difficulté du placement — il faut du temps pour que 4 rocks + un centre s'alignent). Le score actuel (centre 1-5 + roll 1-5, ×4 — donc 8 à 40) tombe à plat à ce moment-là de la manche. Direction évoquée par le user : viser beaucoup plus haut, un vrai coup rare et unique — réussir un Diamond Rock devrait quasiment suffire à faire passer la manche à lui seul, pas juste être un bon bonus. Il faut un vrai mécanisme de scaling (indexé sur la manche/zone en cours ? sur le score cible lui-même, en pourcentage ?) plutôt qu'un chiffre statique — **la dépendance identifiée en session 15 est levée depuis session 18** : la [courbe du score cible](../manche/score-cible.md) est maintenant figée (`GameRules.ROUND_TARGETS`), donc le scaling de Diamond Rock peut s'indexer dessus sans attendre autre chose.

## Économie

- **[Tickets](../progression/monnaies.md)** — mécanique exacte à formaliser (combien par manche / zone, coût d'accès à une zone, conversion en meta-progression ?).
- **Mouches non dépensées en fin de run** — converties en tickets pour le Shore ? Perdues ?
- **Courbe de prix au shop** — les prix augmentent-ils avec les zones ?
- **Surplus de score** — bonus de mouches ? À tester.
- **Pondération par rareté dans le shop** — implémentée en session 14 (voir [Génération de l'offre](../shop/generation-offre.md)). Poids (10/5/2/1) posés au jugé, à retuner au playtest.
- **Prix du shop v2** (packs, Dés à coudre, reroll) — premiers jets posés en session 12, à rééquilibrer avec plus de playtest.

## Univers

Direction validée ([Pitch](../univers/pitch.md), [Ton](../univers/ton.md), [Direction artistique](../univers/direction-artistique.md)). Les questions qui restent :

- **Le titre du jeu** — "Deep Rows" est un placeholder.
- **Le [garçon](../univers/personnages/garcon.md)** — silhouette + acolyte à dessiner.
- **L'[Entity](../univers/personnages/entity.md)** — forme, nom, ton précis.
- **Les zones / biomes** — 4 lieux de la descente, de plus en plus étranges, traversés dans un ordre fixe (voir [Structure du run](../progression/structure-run.md#biomes)). Noms placeholder posés en session 18 (purement provisoires, déjà câblés en jeu avec un fond pastel par biome) : Plage → Forêt → Marais → Rêves. Reste à trouver l'identité réelle de chacun (artwork, contenu débloqué).
- **Le lieu de retour** — remplacer "The Shore" par un nom qui appartient à ce monde.
- **Nom du mode infini / lien thématique (session 16, renommé session 18)** — "Cosmos" (session 16) puis "Vide" (session 18, placeholder actuel) pour le [biome spécial post-zone 4](../progression/structure-run.md#mode-infini) (minimaliste, abstrait). Reste à trouver un lien thématique réel avec l'univers/l'histoire avant de le documenter comme un vrai nom.
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
