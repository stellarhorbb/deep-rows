# Structure du run

## Choix de départ

**Implémenté aujourd'hui** : un [écran de sélection de Partition](../partitions/principe.md) au tout début de la run (et après chaque fin de run) — 3 Partitions tirées au hasard dans tout le catalogue, le joueur en choisit 2, gratuites.

**Pas encore implémenté, direction revue en session 16** : le **choix du pack de [boutons](../jetons/boutons.md)** devient LE choix structurant de départ façon "deck" Balatro (Red Deck, Checkered Deck...) — le joueur pioche parmi les packs qu'il a débloqués au Shore (Polyvalent, Mono-famille, Escalier...), fixe pour tout le run une fois choisi. Le pool de départ est aujourd'hui généré aléatoirement, sans choix du joueur — à remplacer par cette sélection.

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

## Arborescence

```
Début de run
  ├── Choix du pack de boutons (débloqués au Shore)
  │
  ├── Plage    (N manches + shop entre chaque, boss en dernière manche)
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

Le score cible monte linéairement, mais la puissance du joueur monte **exponentiellement** grâce aux synergies. Le skill c'est de construire la bonne courbe exponentielle avant que le linéaire ne rattrape.

## Liens

- [Sources de scaling](sources-scaling.md)
- [Monnaies](monnaies.md)
- [Défaite](defaite.md)
- [Shore](../shore/principe.md)
- [Score cible](../manche/score-cible.md)
