# Les Rocks

Le **scaffold** — jetons sans famille ni valeur qui ne participent à aucun pattern et ne scorent jamais. **4 rocks par défaut** dans chaque deck (`DECK_ROCK_COUNT` dans `game_rules.gd`).

## Pourquoi ils existent

- **Du relief sur la grille** — un rock posé au milieu d'une colonne force des diagonales et des constructions au-dessus
- **Un puzzle de placement** — "où est-ce que je le cale pour qu'il me serve plus tard plutôt que de me gêner ?"
- **De la texture au deck** — piocher un rock change le rythme, oblige à improviser
- **Un terrain pour les Badges** — les rocks sont une dimension dédiée à exploiter (ex : "Récif vivant", session 17 — quand une Partition score, un jeton aléatoire *parmi ceux qui viennent de scorer* échappe à la suppression et devient un rock à la place)

## Comportement

- Tombent par gravité comme n'importe quel jeton
- Ne se résolvent pas, ne scorent pas, **restent sur la grille** pendant toute la manche
- **Au [Dernier Souffle](../manche/dernier-souffle.md), ils explosent** — leurs trous déclenchent une cascade finale

## Exception : Diamond Rock

Les rocks participent à **une seule Partition** : le [Losange Rock](../partitions/catalogue-implemente.md) — 4 rocks disposés autour d'un jeton central (haut/bas/gauche/droite). **Seul le centre est récolté et retiré de la grille — les 4 rocks ne disparaissent jamais.** Ils restent en jeu comme des rocks ordinaires pour le reste de la manche (relief, terrain de Badges, et surtout toujours présents pour exploser au [Dernier Souffle](../manche/dernier-souffle.md) — les détruire à chaque récolte les priverait de ce rôle).

`DECK_ROCK_COUNT` (4) rocks sont régénérés à **chaque manche** (pas une seule fois pour toute la run) — Diamond Rock est donc une occasion par manche, pas par run. En revanche, une fois une récolte faite, la reformer sur les 4 mêmes rocks est quasi impossible dans l'immédiat : le centre se remplit automatiquement à la gravité qui suit (le jeton juste au-dessus retombe dedans), le joueur ne peut pas y redéposer volontairement un nouveau jeton de valeur.

Session 15 : pour éviter qu'un centre à faible valeur ne donne un score misérable (pure loterie sur un coup qui demande déjà un vrai effort de placement), la valeur du centre est augmentée d'un **roll casino entre 1 et 5** (`GameRules.DIAMOND_ROCK_ROLL_MIN/MAX`) avant application du multiplicateur du tag — accompagné d'une petite animation de roulette qui ralentit avant de s'arrêter sur le résultat (`ResolutionBanner.play_roll_announcement`). Premier essai d'une mécanique "roll casino" sur le scoring, volontairement scopée à ce seul pattern pour l'instant — voir [Questions ouvertes](../meta/questions-ouvertes.md).

**Le centre doit être scorable** (`PatternMatcher.find_diamonds`) : si une Entity, un autre Rock ou un trou de la grille cabossée occupe la case centrale, ce n'est pas un match valide — rien ne se passe, les 4 rocks restent des rocks normaux. Comme la gravité garantit que le centre est forcément déjà occupé dès que les 4 rocks sont en place (impossible d'avoir une case vide entre deux jetons posés dans la même colonne), il ne peut jamais "se libérer" tout seul — seule une intervention extérieure (Bombe typiquement) peut changer ce qui occupe cette case. Bug corrigé en session 15 : avant ce garde-fou, un centre non scorable consommait quand même les 4 rocks (et le jeton central lui-même) pour 0 point, sans aucun retour visuel.

Depuis la session 12, la forme losange existe aussi en version **famille** (Family Diamond — 4 jetons de même famille autour d'un centre indifférent, sans rock). Les deux variantes partagent la même détection (`PatternMatcher.find_diamonds`) mais scorent différemment — voir [Scoring](../partitions/scoring.md).

## Liens

- [Boutons](boutons.md)
- [Dernier Souffle](../manche/dernier-souffle.md)
- [Catalogue de partitions](../partitions/catalogue-implemente.md)
