# Structure du run

## Choix de départ

**Implémenté aujourd'hui** : un [écran de sélection de Partition](../partitions/principe.md) au tout début de la run (et après chaque fin de run) — 3 Partitions tirées au hasard dans tout le catalogue, le joueur en choisit 2, gratuites.

**Direction actée en session 19, remplace le point ci-dessus** : ce screen a un défaut structurel — rien n'empêche de recommencer la run jusqu'à tomber sur les 2 Partitions voulues, donc ce n'est pas un vrai choix, juste un filtre RNG déguisé. Remplacé par un **pack de démarrage déterministe**, choisi parmi ceux débloqués au [Shore](../shore/principe.md), fixe pour toute la run (aucun reroll possible) — comparable au choix de deck dans Balatro ou de personnage dans Slay the Spire. Un pack combine jusqu'à trois ingrédients, tous connus avant de s'engager :

1. **Deck retouché (optionnel)** — taille (slim/fat), nombre de rocks, quelques jetons pré-fusionnés à haute valeur. **Jamais une uniformité totale famille ou valeur** : un deck mono-famille rendrait la résolution quasi automatique (le problème que la [grille cabossée](../grille/trous.md) corrige déjà, en pire) ; un deck mono-valeur tuerait des pans entiers du catalogue casino (Minima/Maxima/Suite/Fibonacci/Prime deviendraient invendables). Composition par défaut équilibrée sinon.
2. **Modificateur de règle/économie** — un curseur sur un système existant : slots de hold, taille de grille, mouches de départ, prix du reroll, spéciaux garantis, slots de Badge, taille de preview...
3. **1-2 Partitions fixes** — pas besoin d'être thématiquement liées au modificateur, juste former un ensemble cohérent comme un build.

**Philosophie bonus-first** : l'objectif est de donner envie de tout essayer (complétionniste), pas de trouver "son" archétype préféré — donc majorité de bonus francs, quelques trade-offs équilibrés, aucun pack qui se sent punitif. Interaction propre avec les Badges déjà en place : un modificateur de pack pose une base, un Badge ajoute son bonus par-dessus (même addition simple qu'aujourd'hui) — ex : le pack "Somnambule" (base hold = 0) + Bénédiction (+1) = 1 slot, soit le niveau normal de tout le monde, sans code spécial à écrire.

**Roster figé (session 19)** — 10 packs, séparés en deux groupes :

- **Day-one (4, toujours débloqués, même sur une save neuve)** : Le Simplet (aucun modificateur, Line 4 + Diamond Rainbow), Le Généreux (+2 mouches par manche gagnée, Small T + Fibonacci), Le Prévoyant (+1 slot de hold / preview -1, Suite + Diamond), Le Collectionneur (+1 emplacement de Badge / +2 rocks dans le deck, Square + Prime). Les quatre ne s'appuient que sur des [Partitions génériques](../partitions/catalogue-implemente.md#accès-générique-vs-verrouillé) — un vrai choix dès la toute première run, sans dépendre d'un unlock. Prévoyant et Collectionneur ont reçu une contrepartie après premier playtest (un +1 sec sans rien en face était un choix strictement dominant, pas une identité de build). Paires retravaillées en session 22 pour garantir un vrai écart facile/dur par pack (multiplicateur + type de règle family/casino), voir [Catalogue implémenté](../partitions/catalogue-implemente.md). **Line 3 supprimée du catalogue en session 23** (spam vertical dégénéré au playtest) : Le Simplet perd Line 3 au profit de Line 4 (nerfée ×2→×1.5), Le Prévoyant échange Line 4 contre Suite (nerfée ×2.5→×2) pour garder son écart interne avec Diamond.
- **À débloquer au Shore (6)** : Le Clairvoyant, Le Marchand, Le Dégagé, Le Risque-Tout, Le Fortifié, L'Ermite. Quatre d'entre eux (Dégagé/Risque-Tout/Fortifié/Ermite) servent aussi de **vecteur d'unlock** pour les 5 Partitions verrouillées — débloquer le pack débloque définitivement sa Partition signature dans le pool générique du shop, pour toutes les runs futures. Conditions de déblocage précises (Découverte/biome) pas encore fixées.

Voir [Brainstorm — Packs de démarrage](../../brainstorms/brainstorm-starter-packs.md#roster-final--jour-1-vs-débloqué-session-19) pour le détail complet (modificateurs, discussion anti-copie-Balatro).

La **grille**, elle, sort de ce choix de départ : elle est désormais liée au [biome](#biomes) traversé, pas un choix fait une fois pour tout le run. Voir [Format de la grille](../grille/format.md).

## Dimensions

**Figé en session 18** : `ROUNDS_PER_ZONE = 5` (4 manches + 1 boss), `ZONES_PER_RUN = 4` dans `game_rules.gd` donnent **20 manches par run complet**. Le [score cible](../manche/score-cible.md) a été recalibré sur cette échelle (courbe exponentielle hardcodée dans `GameRules.ROUND_TARGETS`). Le [level up des Partitions](../partitions/level-up.md) (seuils/multiplicateurs des dan au-delà de Maestro) reste à recalibrer avec cette même échelle.

## Biomes

Les 4 zones deviennent des **biomes à forte identité**, traversés dans un **ordre fixe** (jamais aléatoire) — cohérent avec le pilier narratif ["la descente"](../univers/pitch.md) : la zone 1 doit rester familière, la zone finale totalement étrangère, ce qui n'a de sens que si la position dans la séquence est stable d'une run à l'autre. Modèle explicitement cité : Hades (Tartare → Asphodèle → Élysée → Styx, toujours dans cet ordre, mais contenu de chaque salle randomisé à l'intérieur).

**Noms placeholder (session 18)**, purement provisoires en attendant l'univers final — Plage → Forêt → Marais → Rêves, puis Vide pour le mode infini. Déjà câblés en jeu (`GameRules.BIOME_NAMES`, fond pastel par biome).

Chaque biome introduit du contenu débloqué **une seule fois, pour toujours** (toutes les runs suivantes, pas juste celle en cours) — trois niveaux :

1. **Générique** — disponible dès le début de n'importe quelle run, aucun unlock requis
2. **Thématique/biome** — débloqué en atteignant le biome pour la première fois (ex : la zone des araignées introduit un Badge "soie"). Rejoint alors le pool du shop pour le reste de cette run et toutes les suivantes
3. **Achievement/Découverte** — débloqué par un exploit précis en jeu, peu importe le biome (ex : faire 5 cascades d'affilée débloque un jeton spécial rare et puissant). Prolonge le pilier "Découvertes" déjà noté dans [Shore — unlocks](../shore/unlocks.md)

L'identité du biome se porte sur l'artwork, le contenu débloqué (Badges/Partitions/Spéciaux thématiques) et sur sa **grille propre** — pas sur le malus de boss, qui reste volontairement global (voir ci-dessous).

## Boss de zone

Chaque biome se referme sur une **manche boss**, avec une contrainte tirée dans un **pool global et aléatoire** (façon Balatro), pas un pool spécifique au biome — pour garder la surprise "chaque run est différente" tout en laissant l'identité du biome se construire ailleurs. Justification narrative gratuite : l'[Entity](../univers/personnages/entity.md) est persistante sur toute la run et ne joue pas un biome en particulier — le malus de boss, c'est elle qui intervient, d'où qu'elle soit.

Contraintes encore à inventer (pistes en vrac, non tranchées) : une famille qui ne score plus ce tour-là, une Partition équipée désactivée au hasard, une grille avec deux fois plus de trous, un deck sans jetons spéciaux...

## Mode infini

Après le boss de la zone 4, l'écran "you win" propose une **option de continuer** en mode infini (façon Balatro après l'Ante 8) — un biome spécial, minimaliste/abstrait ("Vide", nom provisoire — remplace l'ancien placeholder "Cosmos", lien thématique avec l'univers encore à trouver), qui remplace la fin de la descente par une chute sans fond. Difficulté croissante jusqu'à un game over inévitable.

C'est le terrain où les [dan sans plafond du level up](../partitions/level-up.md#au-delà-de-maestro--les-dan-piste-décidée-session-16) et une courbe de [score cible](../manche/score-cible.md) exponentielle (question ouverte depuis longtemps) trouvent enfin une vraie raison d'être — dans la campagne fixe à durée bornée, ces deux systèmes ne servent presque jamais ; dans un mode qui continue tant que le joueur tient, ils deviennent le cœur du scaling de fin de partie.

## Fin de run — le starter final

**Genre tranché session 23, condition précisée session 24** : pas de true ending façon Hades (paliers narratifs, plusieurs états de fin — contredirait le scope "quelques flags" de la [boucle narrative](../shore/boucle-narrative.md) et le pilier [Ambivalence](../univers/pitch.md#lambivalence)). À la place, façon Cult of the Lamb — accumuler des conditions remplies à travers plusieurs runs pour débloquer une scène finale courte et ambiguë, le jeu continuant normalement après (mode infini, défis, malus — rien ne s'arrête).

Condition retenue, liée à la [lecture profonde des packs de démarrage](../univers/pitch.md#le-sens-caché-privé--jamais-montré-en-jeu) (chaque pack = un trait de personnalité du garçon) : finir une run avec chaque starter débloque progressivement, jusqu'à révéler un **starter final** — celui le plus proche de qui il est, le cœur de sa psyché. Finir une run avec ce starter final propose la scène de fin. Reste ouvert (voir [Questions ouvertes](../meta/questions-ouvertes.md)) : faut-il *gagner* une run avec chaque starter ou juste la *finir*/l'essayer, l'ordre importe-t-il, combien de starters faut-il avant que le final ne se révèle (tous les 10, ou un sous-ensemble) ?

## Arborescence

```
Début de run
  ├── Choix du pack de démarrage (débloqués au Shore)
  │
  ├── Plage    (4 manches + shop entre chaque, boss en 5e manche)
  ├── Forêt
  ├── Marais
  ├── Rêves (boss) → "You win"
  │     └── Option : continuer en mode infini (Vide) → jusqu'au game over
  │
  └── Fin de run → Victoire ou Game Over → The Shore (meta-progression)
```

Entre chaque manche : un passage au [shop](../shop/offre-mixte.md) tenu par les [grenouilles orchestre](../univers/personnages/grenouilles-orchestre.md).

## Courbe de puissance

Le joueur doit sentir une **montée en puissance constante** même si les [scores cibles](../manche/score-cible.md) augmentent :

- **Zone 1** : patterns basiques, scoring simple, découverte
- **Zone 2** : premières [Badges](../badges/principe.md), début des synergies, Partitions qui level up
- **Zone 3** : le build prend forme, cascades régulières
- **Zone 4** : la machine tourne, gros chiffres, combos spectaculaires

Le [score cible](../manche/score-cible.md) monte lui-même en exponentielle (session 18), mais la puissance du joueur doit monter **plus vite encore** grâce aux synergies. Le skill c'est de construire sa propre courbe exponentielle avant que celle de la cible ne rattrape.

## Liens

- [Sources de scaling](sources-scaling.md)
- [Monnaies](monnaies.md)
- [Défaite](defaite.md)
- [Shore](../shore/principe.md)
- [Score cible](../manche/score-cible.md)
