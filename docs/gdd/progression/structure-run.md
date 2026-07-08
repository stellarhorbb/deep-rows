# Structure du run

## Choix de départ

**Implémenté aujourd'hui** : un [écran de sélection de Partition](../partitions/principe.md) au tout début de la run (et après chaque fin de run) — 3 Partitions tirées au hasard dans tout le catalogue, le joueur en choisit 2, gratuites.

**Pas encore implémenté** (vision d'origine, toujours valable comme direction) :
1. **Choix de la [grille](../grille/format.md)** — la "classe" qui définit la forme de jeu. La grille est actuellement fixe (7×7) pour tout le monde.
2. **Choix du pack de [boutons](../jetons/boutons.md)** — la fondation qui définirait le contenu du deck. Le pool de départ est actuellement généré aléatoirement, sans choix du joueur.

Ces deux choix, une fois implémentés, seraient **fixes pour le run**. Tout le reste se construit autour.

## Dimensions

`ROUNDS_PER_ZONE = 3`, `ZONES_PER_RUN = 4` dans `game_rules.gd` → **12 manches par run complet**, ~30-40 min cible.

## Arborescence

```
Début de run
  ├── Choix grille
  ├── Choix pack de boutons
  │
  ├── Zone 1  (3 manches + shop entre chaque)
  ├── Zone 2
  ├── Zone 3
  ├── Zone 4
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
