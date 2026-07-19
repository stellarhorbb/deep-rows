# Brainstorm — Packs de démarrage

**Statut** : bac à sable. Rien ici n'est tranché dans le détail (roster exact, noms, valeurs précises). La direction générale, elle, est actée — voir [Décisions tranchées](../gdd/meta/decisions-tranchees.md) et [Structure du run — Choix de départ](../gdd/progression/structure-run.md#choix-de-départ).

Discussion née d'un constat simple (session 19) : l'écran actuel de sélection de Partition (3 tirées au hasard, le joueur en choisit 2) peut être recommencé jusqu'à obtenir le résultat voulu — ce n'est pas un vrai choix, c'est un filtre RNG déguisé. Comparaison avec deux références :

- **Balatro** : tu choisis un deck (Red/Blue/Checkered...), puis t'es lancé. Le deck ne fait presque jamais varier la composition des cartes — il ajuste des règles légères (+1 défausse, +1 main, argent de départ).
- **Slay the Spire** : tu choisis un personnage avec un vrai archétype (deck de départ + relique signature qui raconte son style).

Conclusion : le vrai choix structurant de la run doit être un **pack de démarrage déterministe** (pas de random, pas de reroll possible) — pas un tirage de Partitions qu'on peut recommencer.

## Forme d'un pack

Un pack = jusqu'à trois ingrédients, tous fixes et connus avant de s'engager :

1. **Deck retouché (optionnel)** — jamais une uniformité totale famille/valeur (voir "Pourquoi pas mono-famille/mono-valeur" ci-dessous). Leviers sains : taille du deck (slim/fat), nombre de rocks, quelques jetons pré-fusionnés à haute valeur.
2. **Modificateur de règle/économie** — un curseur sur un système déjà existant : slots de hold, taille de la grille, mouches de départ, prix du reroll, spéciaux garantis en début de deck, slots de Badge, taille de la preview...
3. **1-2 Partitions fixes** — pas besoin d'être thématiquement "liées" au modificateur, juste former un ensemble qui se sent cohérent comme un build.

Remplace entièrement l'écran actuel de draft de Partitions.

## Pourquoi pas mono-famille / mono-valeur

Un deck skewé à 100% vers une seule famille ou une seule valeur casse la mécanique plutôt que de la colorer :

- **Mono-famille + Partition famille** = résolution quasi garantie à chaque tour, ça recrée (en pire, en structurel) le problème que la grille cabossée a été inventée pour corriger en session 12 (la grille se vidait trop facilement, plus de tension).
- **Mono-valeur ("que des 3")** = tue des pans entiers du catalogue casino (Minima/Maxima/Suite/Fibonacci/Prime deviennent structurellement invendables, aucun jeton ne peut jamais qualifier) tout en trivialisant Brelan.

Règle retenue : un pack peut jouer sur la **taille** du deck, son **contenu spécial** (rocks, valeurs hautes ponctuelles), ou une **inclinaison** de distribution — jamais une **uniformité totale** sur famille ou valeur.

## Philosophie bonus-first

Objectif : donner envie de TOUT essayer (complétionniste), pas juste de trouver "son" axe préféré. Ça implique :

- **Majorité de bonus francs**, quelques trade-offs équilibrés (bonus + malus pairés, façon Black Deck de Balatro), très peu de contraintes pures — et même celles-là ne doivent jamais se sentir comme une punition, juste comme une saveur différente.
- Interaction propre avec les Badges déjà en place : un modificateur de pack pose une **base**, un Badge ajoute son bonus **par-dessus** (même addition simple que le système actuel). Exemple concret : le pack "Somnambule" (base hold = 0) + Badge Bénédiction (+1) = 1 slot, soit le niveau normal de tout le monde — Bénédiction ne devient pas un bonus, elle ramène juste à la normale. Aucun code spécial à écrire, l'addition existante suffit.

## V1 — premier jet, trop orienté malus (à ne pas reprendre tel quel)

| Pack           | Deck                          | Modificateur                               | Partitions fixes             | Feel                                 |
| -------------- | ----------------------------- | ------------------------------------------ | ---------------------------- | ------------------------------------ |
| Le Somnambule  | défaut                        | Pas de slot de hold                        | Line 3 + Brelan              | Aucun filet, décisions à vif         |
| Le Bâtisseur   | défaut                        | Rocks ×2                                   | Diamond Rock + Square Family | Grille encombrée, placement patient  |
| Le Joueur      | défaut                        | 3 spéciaux garantis                        | Suite + Line 4               | Tactique dès le premier coup         |
| L'Étroit       | slim                          | Grille -1 colonne                          | Line 5 + Plus                | Chaque coup compte, tension tôt      |
| Le Généreux    | défaut                        | +10 mouches                                | Diamond Family + Fibonacci   | Longueur d'avance au shop            |
| L'Assiégé      | défaut                        | Grille -2 colonnes + Entity plus fréquente | Cross + Suite                | Pression constante                   |
| Le Spéculateur | quelques 8-9-10 pré-fusionnés | défaut                                     | Maxima + Carré               | Accès immédiat au haut de l'échelle  |
| Le Prudent     | fat                           | +1 spécial                                 | Square Rainbow + Minima      | Beaucoup de tentatives, double filet |

Verdict après relecture : 6 malus pour 2 bonus francs, trop orienté hard-mode. Repris en V2.

## V2 — rééquilibré bonus-first

| Pack | Type | Deck / Modificateur | Partitions fixes | Feel |
|---|---|---|---|---|
| Le Généreux | Bonus | +10 mouches de départ | Diamond Family + Fibonacci | Longueur d'avance au 1er shop |
| Le Prévoyant | Bonus | +1 slot de hold (2 total) | Line 4 + Suite | Plus de flexibilité pour composer |
| Le Collectionneur | Bonus | +1 slot de Badge (6 total) | Square Family + Brelan | Build plus large dès le départ |
| Le Clairvoyant | Bonus | Preview à 4 au lieu de 3 | Line 5 + Carré | Anticipe plus loin |
| Le Dégagé | Bonus | -2 rocks (2 au lieu de 4) | Line 4 Rainbow + Plus | Grille plus propre |
| Le Marchand | Bonus | 1er reroll gratuit à chaque visite | Square Rainbow + Minima | Shop plus souple |
| Le Risque-Tout | Trade-off | +1 slot de Badge, mais 0 slot de hold | Brelan + Ring | Build large, aucun filet |
| Le Fortifié | Trade-off | Grille -1 colonne, mais 2 spéciaux garantis | Cross + Diamond Rock | Espace restreint, compensé par des outils |
| L'Ermite | Quirk | Aucun rock dans le deck | T Family + Maxima | Grille "propre" mais jamais de Diamond Rock |

Le Bâtisseur/Somnambule/Assiégé de la V1 restent utilisables en fond de catalogue pour les joueurs qui cherchent un vrai hard-mode (comme les decks Plasma/Nebula de Balatro) — mais pas comme le gros du roster.

## Roster final — jour 1 vs débloqué (session 19)

Parti d'une question annexe mais structurante : combien de Partitions sont accessibles sur une save toute neuve, avant tout unlock ? Réponse posée dans [Catalogue implémenté](../gdd/partitions/catalogue-implemente.md#accès-générique-vs-verrouillé) — 15 des 20 Partitions actives sont **génériques** (tiers Trivial à Medium), 5 sont **verrouillées** (Plus, Maxima, Cross, Ring, Diamond Rock — tiers Difficile à Hors échelle). Ça a immédiatement recoupé le roster de packs ci-dessus : 4 des 9 candidats V2 utilisent une Partition verrouillée dans leurs fixes — ils deviennent naturellement le **vecteur d'unlock** de cette Partition (débloquer le pack débloque aussi, pour toujours, la Partition dans le pool générique du shop — pas de Découverte séparée à inventer). Les 5 autres candidats, eux, n'utilisent que des génériques : ils peuvent être day-one sans paradoxe.

Constat en cours de route : un seul pack day-one (Le Base originel, jamais nommé jusqu'ici) ne suffit pas — une save neuve doit proposer un vrai choix, pas un unique pack imposé. Sélection des day-one guidée par le principe "leviers propres à Deep Rows plutôt qu'économie pure" (voir ci-dessous) : Le Clairvoyant et Le Marchand écartés du jour 1 au profit du Prévoyant et du Collectionneur.

Un ajustement final : Le Collectionneur utilisait Brelan comme Le Simplet (nouveau nom du pack de base) — redondant sur seulement 4 packs day-one, remplacé par Prime.

**Contrepartie ajoutée après premier playtest** — retour du user dès les premiers essais : Prévoyant et Collectionneur, en +1 slot sec sans rien en face, étaient des choix strictement dominants plutôt qu'une identité de build. Chacun gagne une contrepartie sur un levier propre à Deep Rows (jamais l'économie), et volontairement distincte des combos déjà réservés ailleurs dans le roster (0 hold est la contrepartie de Risque-Tout, grille -1 colonne celle de Fortifié) : Prévoyant perd 1 de preview (anticipation contre filet de stockage), Collectionneur gagne 2 rocks dans le deck (build plus large contre grille plus encombrée).

| Pack              | Statut                                         | Modificateur                                   | Partitions fixes        |
| ----------------- | ---------------------------------------------- | ---------------------------------------------- | ----------------------- |
| Le Simplet        | **Day-one**                                    | Aucun (deck/règles par défaut)                 | Line 3 + Brelan         |
| Le Généreux       | **Day-one**                                    | +2 mouches par manche gagnée                   | Diamond + Fibonacci     |
| Le Prévoyant      | **Day-one**                                    | +1 slot de hold, preview -1 (2 au lieu de 3)   | Line 4 + Suite          |
| Le Collectionneur | **Day-one**                                    | +1 emplacement de Badge, +2 rocks dans le deck | Square + Prime          |
| Le Clairvoyant    | À débloquer                                    | Preview à 4                                    | Line 5 + Carré          |
| Le Marchand       | À débloquer                                    | 1er reroll gratuit                             | Square Rainbow + Minima |
| Le Dégagé         | À débloquer — vecteur **Plus**                 | -2 rocks                                       | Line 4 Rainbow + Plus   |
| Le Risque-Tout    | À débloquer — vecteur **Ring**                 | +1 slot de Badge, 0 slot de hold               | Brelan + Ring           |
| Le Fortifié       | À débloquer — vecteur **Cross + Diamond Rock** | Grille -1 colonne, 2 spéciaux garantis         | Cross + Diamond Rock    |
| L'Ermite          | À débloquer — vecteur **Maxima**               | Aucun rock dans le deck                        | T Family + Maxima       |

Reste ouvert : les conditions de déblocage précises (Découverte ou biome) pour les 6 packs à débloquer — voir [Questions ouvertes](../gdd/meta/questions-ouvertes.md).

## Éviter que ça sente "copie Balatro"

Le squelette (choisir une identité de départ → débloquer plus par la suite) n'est pas le problème, c'est un mécanisme partagé par la moitié du genre (Isaac, Hades, StS). Le risque est dans l'**exécution** : des modificateurs secs façon stat-block, c'est très Balatro (aucune histoire derrière ses decks). Trois leviers pour recoller à l'identité Deep Rows :

1. **Habillage narratif** — chaque pack comme un petit objet/fragment d'histoire trouvé par le garçon, pas juste une ligne de règle. Branche sur le pilier "mystères et secrets" déjà posé dans `univers/ton.md`.
2. **Leviers propres à Deep Rows plutôt qu'à l'économie** — préférer rocks/grille/hold/cascades (que Balatro n'a pas) aux leviers économiques purs (mouches, reroll — très Balatro, un jeu fondamentalement économique).
3. **Débloquer par "Découverte" plutôt que par "gagner avec X"** — le modèle "gagner une run avec ce deck débloque Y" est très Balatro/StS/Isaac. `shore/unlocks.md` a déjà une piste différente et antérieure à cette conversation : les Découvertes, des unlocks liés à un exploit précis en jeu plutôt qu'à la victoire avec un pack donné — plus proche du codex de Hades. À privilégier comme vecteur principal, "gagner avec X" pouvant rester un déclencheur secondaire parmi d'autres.

## Piste différée — Stakes façon Balatro

Une fois tout débloqué, une liste de handicaps montants par starter (façon Stakes de Balatro : chaque palier ajoute une contrainte permanente une fois le précédent battu) pour les joueurs hardcore/complétionnistes qui ont fini le tour du catalogue. Évoqué mais explicitement mis de côté pour plus tard — voir [Questions ouvertes](../gdd/meta/questions-ouvertes.md).

## Liens

- [Structure du run — Choix de départ](../gdd/progression/structure-run.md#choix-de-départ)
- [Partitions — principe](../gdd/partitions/principe.md)
- [Shore — unlocks](../gdd/shore/unlocks.md)
- [Décisions tranchées](../gdd/meta/decisions-tranchees.md)
